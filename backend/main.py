import joblib
import pandas as pd
import numpy as np
from flask import Flask, jsonify, request
from flask_cors import CORS
from pymongo import MongoClient
from prophet import Prophet 
from datetime import datetime, timedelta
import os
import certifi

app = Flask(__name__)
CORS(app)

# ==========================================
# 0. CONFIGURATION & RESOURCES
# ==========================================
# CRITICAL: Default to None so we can warn the user if it's missing
MONGO_URI = os.getenv("MONGO_URI")

if not MONGO_URI:
    print("⚠️ WARNING: MONGO_URI environment variable is missing!")
    print("   Falling back to localhost (This will FAIL on Render cloud).")
    MONGO_URI = "mongodb://localhost:27017/"

DB_NAME = "Food_Inventory"
INVENTORY_COLLECTION = "products"       
SALES_COLLECTION = "SalesHistory"     

print("⏳ Starting AI Server...")

# 1. LOAD AI MODELS
try:
    model = joblib.load("discount_model2.pkl")
    print("✅ AI Model loaded successfully.")
except FileNotFoundError:
    print("⚠️ Warning: 'discount_model2.pkl' not found.")
    print("   The server will run using Rule-Based Logic only.")
    model = None

# ==========================================
# 1. LOGIC ENGINE
# ==========================================
def calculate_strategy(row):
    days_left = row['remaining_life']
    turnover = row.get('inventory_turnover_rate', 0.5) 
    stock = row['current_stock']
    
    sales_vol = row.get('sales_volume', 10)
    if pd.isna(sales_vol): sales_vol = 10
    
    stock_pressure = stock / (sales_vol + 1)

    # --- RULES ---
    if days_left <= 0: return "DONATE", 90.0
    if days_left <= 3: return "Critical Clearance", 80.0

    if days_left <= 30:
        if turnover > 0.5: return "Flash Sale", 40.0
        else: return "Heavy Discount", 60.0

    if days_left <= 90:
        if stock_pressure > 1.5: return "Stock Clearance", 30.0
        elif stock > 50: return "Bulk Promo", 20.0

    return "Keep Price", 0.0

# ==========================================
# 2. API ROUTE: DISCOUNT OPTIMIZATION
# ==========================================
# Added /api/products alias so frontend can use either
@app.route('/api/products', methods=['GET'])
@app.route('/api/discounts', methods=['GET'])
def get_discounts():
    try:
        client = MongoClient(MONGO_URI, tlsCAFile=certifi.where())
        collection = client[DB_NAME][INVENTORY_COLLECTION]
        data = list(collection.find({}, {"_id": 0}))
        
        if not data:
            return jsonify({"error": "Inventory collection is empty"}), 404
            
        df = pd.DataFrame(data)

        # Preprocessing
        date_cols = ['manufacturing_date', 'expiry_date', 'date_received']
        for col in date_cols:
            if col in df.columns:
                df[col] = pd.to_datetime(df[col])

        current_date_ref = datetime.now() 
        df['remaining_life'] = (df['expiry_date'] - current_date_ref).dt.days
        
        # Apply Logic
        df[['action_status', 'final_discount_pct']] = df.apply(
            lambda row: pd.Series(calculate_strategy(row)), axis=1
        )

        # Financials
        df['final_selling_price'] = df['marked_price'] * (1 - df['final_discount_pct'] / 100)

        def estimate_sales(row):
            if row['action_status'] == 'DONATE': return 0
            if row['final_discount_pct'] == 0: return int(row['current_stock'] * 0.1)
            sales_ratio = 0.1 + (row['final_discount_pct'] / 100.0)
            return int(row['current_stock'] * sales_ratio)

        df['sold_after'] = df.apply(estimate_sales, axis=1)
        df['revenue_after'] = df['sold_after'] * df['final_selling_price']
        df['loss_after'] = (df['current_stock'] - df['sold_after']) * df['marked_price']

        # Format
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
# 3. API ROUTE: FORECASTING
# ==========================================
@app.route('/api/forecast', methods=['GET'])
def get_forecast():
    try:
        client = MongoClient(MONGO_URI, tlsCAFile=certifi.where())
        col = client[DB_NAME][SALES_COLLECTION]
        data = list(col.find({}, {"_id": 0}))
        
        if not data:
            return jsonify({"error": "No SalesHistory data found."}), 404
            
        df = pd.DataFrame(data)
        
        if 'product_name' not in df.columns or 'quantity_sold' not in df.columns:
             return jsonify({"error": "SalesHistory missing required columns."}), 500

        results = []
        unique_products = df['product_name'].unique()[:10] 

        for product in unique_products:
            p_df = df[df['product_name'] == product].copy()
            if 'date' not in p_df.columns: continue
                 
            p_df['ds'] = pd.to_datetime(p_df['date'])
            p_df['y'] = p_df['quantity_sold']
            
            if len(p_df) < 5: continue

            m = Prophet(daily_seasonality=False, yearly_seasonality=False, weekly_seasonality=True)
            m.fit(p_df)
            
            future = m.make_future_dataframe(periods=7)
            forecast = m.predict(future)
            
            predicted_demand = int(forecast.tail(7)['yhat'].sum())
            recommended_order = int(predicted_demand * 1.05)
            
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

# ==========================================
# 4. API ROUTE: ADD PRODUCT (POST)
# ==========================================
@app.route('/api/products', methods=['POST'])
def add_product():
    try:
        data = request.json
        if not data:
            return jsonify({"error": "No data provided"}), 400

        if 'date_received' not in data:
            data['date_received'] = datetime.now().isoformat()
            
        client = MongoClient(MONGO_URI)
        collection = client[DB_NAME][INVENTORY_COLLECTION]
        
        result = collection.insert_one(data)
        
        return jsonify({
            "message": "Product added successfully", 
            "id": str(result.inserted_id)
        }), 201
        
    except Exception as e:
        print(f"Error adding product: {e}")
        return jsonify({"error": str(e)}), 500

# ==========================================
# 5. HOMEPAGE
# ==========================================
@app.route('/')
def home():
    return jsonify({
        "status": "Running",
        "message": "AIOT Food Expiry System is Live!",
        "endpoints": [
            "/api/products (GET/POST)",
            "/api/discounts",
            "/api/forecast"
        ]
    })

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 10000))
    app.run(host='0.0.0.0', port=port, debug=True)