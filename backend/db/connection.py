from pymongo import MongoClient
import os
from dotenv import load_dotenv

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")
client = MongoClient(MONGO_URI)
# Use lowercase database name to match existing MongoDB instance
db = client["lastbench"]

print("MongoDB connected")
