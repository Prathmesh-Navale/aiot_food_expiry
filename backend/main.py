import joblib
import pandas as pd
import numpy as np
from flask import Flask, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from prophet import Prophet 
from datetime import datetime, timedelta

app = Flask(__name__)
CORS(app)

# ==========================================
# 0. CONFIGURATION & RESOURCES
# ==========================================
import os
MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017/")
DB_NAME = "Food_Inventory"
INVENTORY_COLLECTION = "products"      
SALES_COLLECTION = "SalesHistory"     

print("⏳ Starting AI Server...")

# 1. LOAD AI MODELS (Created by train_model.py)
try:
    model = joblib.load("discount_model2.pkl")
    product_encoder = joblib.load("product_encoder.pkl") # Load the dynamic encoder
    print("✅ AI Model & Encoder loaded successfully.")
except FileNotFoundError:
    print("❌ Critical Error: 'discount_model2.pkl' or 'product_encoder.pkl' not found.")
    print("   Run 'train_model.py' first to generate these files.")
    model = None
    product_encoder = None

# ==========================================
# 1. LOGIC ENGINE: DYNAMIC DISCOUNT STRATEGY
# ==========================================
def calculate_strategy(row):
    """
    Determines the genuine action status and discount percentage
    based on remaining life, turnover rate, and stock pressure.
    """
    days_left = row['remaining_life']
    turnover = row.get('inventory_turnover_rate', 0.5) # Default to 0.5 if missing
    stock = row['current_stock']
    
    # Stock Pressure: Ratio of stock to sales velocity (avoid div by zero)
    # Higher number = We have too much stock for how slow it sells
    stock_pressure = stock / (row.get('sales_volume', 10) + 1)

    # --- TIER 1: CRITICAL (DONATION / LOSS) ---
    if days_left <= 0:
        return "DONATE", 90.0  # Expired
    
    if days_left <= 3:
        # 1-3 days: Sell at massive loss or donate
        return "Critical Clearance", 80.0

    # --- TIER 2: HIGH URGENCY (4 to 30 Days) ---
    if days_left <= 30:
        # If it sells fast, we only need a moderate discount
        if turnover > 0.5:
            return "Flash Sale", 40.0
        # If it sells slow, we need a heavy push
        else:
            return "Heavy Discount", 60.0

    # --- TIER 3: MEDIUM URGENCY (31 to 90 Days) ---
    if days_left <= 90:
        # If we have way too much stock relative to sales
        if stock_pressure > 1.5:
            return "Stock Clearance", 30.0
        # Or just a large raw amount
        elif stock > 50:
            return "Bulk Promo", 20.0

    # --- TIER 4: SAFE ZONE ---
    return "Keep Price", 0.0

# ==========================================
# 2. API ROUTE: DISCOUNT OPTIMIZATION
# ==========================================
# ==========================================
# 2. API ROUTE: DISCOUNT OPTIMIZATION
# ==========================================
@app.route('/api/discounts', methods=['GET'])
def get_discounts():
    try:
        # 1. READ FROM DATABASE
        client = MongoClient(MONGO_URI)
        collection = client[DB_NAME][INVENTORY_COLLECTION]
        data = list(collection.find({}, {"_id": 0}))
        
        if not data:
            return jsonify({"error": "Inventory collection is empty"}), 404
            
        df = pd.DataFrame(data)

        # 2. PREPROCESSING & FEATURE ENGINEERING
        date_cols = ['manufacturing_date', 'expiry_date', 'date_received']
        for col in date_cols:
            if col in df.columns:
                df[col] = pd.to_datetime(df[col])

        # --- FIX STARTS HERE -----------------------------------------
        # SET THIS DATE TO SIMULATE TIME TRAVEL
        # Example: If today is Jan 2026, but you want to test as if it's Jan 2025:
        # SIMULATION_DATE = datetime(2025, 1, 15) 
        
        # For now, we use the System Date, BUT you can uncomment the line below to test:
        current_date_ref = datetime.now() 
        # current_date_ref = datetime(2024, 8, 10) # <--- UNCOMMENT THIS TO FORCE A SPECIFIC DATE

        print(f"DEBUG: Calculating Expiry based on reference date: {current_date_ref}")

        df['remaining_life'] = (df['expiry_date'] - current_date_ref).dt.days
        # -------------------------------------------------------------
        
        # Safe Encoding
        if product_encoder:
            known_classes = set(product_encoder.classes_)
            df['product_name_encoded'] = df['product_name'].apply(
                lambda x: product_encoder.transform([x])[0] if x in known_classes else -1
            )
        else:
            df['product_name_encoded'] = 0

        # 3. APPLY LOGIC STRATEGY
        df[['action_status', 'final_discount_pct']] = df.apply(
            lambda row: pd.Series(calculate_strategy(row)), axis=1
        )

        # 4. CALCULATE FINANCIALS
        df['final_selling_price'] = df['marked_price'] * (1 - df['final_discount_pct'] / 100)

        def estimate_sales(row):
            if row['action_status'] == 'DONATE': return 0
            if row['final_discount_pct'] == 0: return int(row['current_stock'] * 0.1)
            sales_ratio = 0.1 + (row['final_discount_pct'] / 100.0)
            return int(row['current_stock'] * sales_ratio)

        df['sold_after'] = df.apply(estimate_sales, axis=1)
        df['revenue_after'] = df['sold_after'] * df['final_selling_price']
        df['loss_after'] = (df['current_stock'] - df['sold_after']) * df['marked_price']

        # 5. SORT & FORMAT
        df.sort_values(by='final_discount_pct', ascending=False, inplace=True)
        
        result_df = df[[
            'product_name', 'current_stock', 'marked_price', 'remaining_life',
            'action_status', 'final_discount_pct', 'final_selling_price',
            'sold_after', 'revenue_after', 'loss_after'
        ]]

        return jsonify(result_df.to_dict(orient='records'))

    except Exception as e:
        print(f"Server Error: {e}")
        return jsonify({"error": str(e)}), 500

# ==========================================
# 3. API ROUTE: FORECASTING (PRODUCTIVITY)
# ==========================================
@app.route('/api/forecast', methods=['GET'])
def get_forecast():
    try:
        # 1. READ FROM DATABASE
        client = MongoClient(MONGO_URI)
        col = client[DB_NAME][SALES_COLLECTION]
        
        data = list(col.find({}, {"_id": 0}))
        if not data:
            return jsonify({"error": "No SalesHistory data found in MongoDB."}), 404
            
        df = pd.DataFrame(data)
        
        # Check required columns
        if 'product_name' not in df.columns or 'quantity_sold' not in df.columns:
             return jsonify({"error": "SalesHistory missing 'product_name' or 'quantity_sold'."}), 500

        # 2. PROCESS FORECASTS
        results = []
        unique_products = df['product_name'].unique()
        
        # Optimization: Limit to top 10 products if list is huge to prevent timeout
        # In production, use pagination or background workers
        unique_products = unique_products[:10] 

        for product in unique_products:
            # Prepare Data for Prophet
            p_df = df[df['product_name'] == product].copy()
            p_df['ds'] = pd.to_datetime(p_df['date'])
            p_df['y'] = p_df['quantity_sold']
            
            # Skip if not enough data points
            if len(p_df) < 5: 
                continue

            # Train Model (Fast settings)
            m = Prophet(daily_seasonality=False, yearly_seasonality=False, weekly_seasonality=True)
            m.fit(p_df)
            
            # Predict Next 7 Days
            future = m.make_future_dataframe(periods=7)
            forecast = m.predict(future)
            
            # 3. CALCULATE METRICS
            predicted_demand = int(forecast.tail(7)['yhat'].sum())
            
            # Safety Stock Logic (5% buffer)
            recommended_order = int(predicted_demand * 1.05)
            
            # Waste Calculation:
            # Compare AI prediction vs "Naive" Average (Last 30 days)
            # If AI predicts 50, but Average was 80, we saved you buying 30 extra units.
            avg_demand = p_df.tail(30)['y'].mean() * 7 if len(p_df) > 30 else p_df['y'].mean() * 7
            waste_saved = max(0, int(avg_demand - recommended_order))
            
            results.append({
                "product": product,
                "recommended_order": max(0, recommended_order),
                "waste_saved": waste_saved,
                "status": "Optimized"
            })
            
        return jsonify(results)

    except Exception as e:
        print(f"Forecast Error: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)