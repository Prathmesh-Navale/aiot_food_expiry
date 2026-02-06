import pandas as pd
import os
import joblib
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error
from pymongo import MongoClient

# ==========================================
# 1. LOAD DATA FROM MONGODB
# ==========================================
print("⏳ Connecting to MongoDB...")

# Get the cloud URI from Render's environment variables
# If running locally, it falls back to localhost
MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017/")
DB_NAME = "Food_Inventory"
COLLECTION_NAME = "products"

# Debugging: Check if we are using the cloud URI or Localhost
if "localhost" in MONGO_URI:
    print("⚠️ WARNING: Using Localhost. This will FAIL on Render unless you have a local DB.")
else:
    print("✅ Using Cloud Database Connection.")

try:
    # Connect
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000) # 5s timeout
    db = client[DB_NAME]
    collection = db[COLLECTION_NAME]

    # Check connection by forcing a server call
    client.server_info()
    
    # Fetch Data (Exclude _id to keep DataFrame clean)
    data = list(collection.find({}, {"_id": 0}))
    
    # Convert to DataFrame
    df = pd.DataFrame(data)
    
    if df.empty:
        # We raise SystemExit to force the build to fail if there is no data
        raise SystemExit("❌ Error: MongoDB collection is empty! Cannot train model.")
        
    print(f"✅ Loaded {len(df)} records from MongoDB.")

except Exception as e:
    print(f"❌ Database Connection Error: {e}")
    # This ensures Render knows the build failed
    raise SystemExit(1) 

# ==========================================
# 2. PREPROCESSING
# ==========================================

# Select features
features = [
    "marked_price",
    "total_shelf_life",
    "remaining_life",
    "max_stock",
    "current_stock",
    "product_name"
]

# Ensure these columns actually exist in the DB data
try:
    X = df[features].copy()
    y = df["discount_percent"]
except KeyError as e:
    print(f"❌ Error: Missing column in MongoDB data: {e}")
    raise SystemExit(1)

# Label encode product name
le = LabelEncoder()
X["product_name"] = le.fit_transform(X["product_name"])

# --- CRITICAL FIX: SAVE THE ENCODER ---
# Your main.py needs this file to decode product names later!
joblib.dump(le, "product_encoder.pkl")
print("💾 Encoder saved as 'product_encoder.pkl'")

# ==========================================
# 3. TRAINING
# ==========================================

# Train-test split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Train model
print("⏳ Training RandomForest Model...")
model = RandomForestRegressor(n_estimators=200, random_state=42)
model.fit(X_train, y_train)

# Predict
y_pred = model.predict(X_test)

# Evaluation
mae = mean_absolute_error(y_test, y_pred)
print("✅ Training Complete.")
print("📊 Mean Absolute Error:", mae)

# ==========================================
# 4. SAVE MODEL
# ==========================================
joblib.dump(model, "discount_model2.pkl")
print("💾 Model saved as 'discount_model2.pkl'")