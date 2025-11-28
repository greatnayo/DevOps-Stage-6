#!/usr/bin/env python3
import jwt
import requests
import json

# JWT secret from environment
jwt_secret = "myfancysecret"

# Create a JWT token for testing (exactly as auth-api does)
payload = {
    "username": "admin",
    "scope": "read"
}

token = jwt.encode(payload, jwt_secret, algorithm="HS256")
print(f"Generated JWT token: {token}")

# Test the users-api with the token
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

try:
    response = requests.get("http://localhost:8083/users/admin", headers=headers)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Error: {e}")