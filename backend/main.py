import joblib
import pandas as pd
import numpy as np
from flask import Flask, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from prophet import Prophet 
from datetime import datetime, timedelta
import os

app = Flask(__name__)
CORS(app)

# ==========================================
# 0. CONFIGURATION & RESOURCES
# ==========================================
MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017/")
DB_NAME = "Food_Inventory"
INVENTORY_COLLECTION = "products"       
SALES_COLLECTION = "SalesHistory"     

print("⏳ Starting AI Server...")

# 1. LOAD AI MODELS
# We attempt to load the model, but if it's missing, we log it and continue.
# The current logic uses 'calculate_strategy' (rules), so the ML model is optional for now.
try:
    model = joblib.load("discount_model2.pkl")
    print("✅ AI Model loaded successfully.")
except FileNotFoundError:
    print("⚠️ Warning: 'discount_model2.pkl' not found.")
    print("   The server will run using Rule-Based Logic only.")
    model = None

# ==========================================
# 1. LOGIC ENGINE: DYNAMIC DISCOUNT STRATEGY
# ==========================================
def calculate_strategy(row):
    """
    Determines the genuine action status and discount percentage
    based on remaining life, turnover rate, and stock pressure.
    """
    days_left = row['remaining_life']
    # Default turnover to 0.5 if missing
    turnover = row.get('inventory_turnover_rate', 0.5) 
    stock = row['current_stock']
    
    # Stock Pressure: Ratio of stock to sales velocity (avoid div by zero)
    # Higher number = We have too much stock for how slow it sells
    sales_vol = row.get('sales_volume', 10)
    if pd.isna(sales_vol): sales_vol = 10
    
    stock_pressure = stock / (sales_vol + 1)

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

        # --- DATE CALCULATION ---
        # Using system time for calculation
        current_date_ref = datetime.now() 
        # current_date_ref = datetime(2024, 8, 10) # Uncomment to simulate a specific date

        print(f"DEBUG: Calculating Expiry based on reference date: {current_date_ref}")

        df['remaining_life'] = (df['expiry_date'] - current_date_ref).dt.days
        
        # 3. APPLY LOGIC STRATEGY
        # We use the rule-based function defined above. 
        # This does NOT require the product_encoder.
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
        
        # Optimization: Limit to top 10 products to prevent timeout
        unique_products = unique_products[:10] 

        for product in unique_products:
            # Prepare Data for Prophet
            p_df = df[df['product_name'] == product].copy()
            # Ensure date column exists and is datetime
            if 'date' not in p_df.columns:
                 continue
                 
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
            
            # Waste Calculation
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
    # Use the PORT environment variable if available (Render sets this)
    port = int(os.environ.get("PORT", 10000))
    app.run(host='0.0.0.0', port=port, debug=True)