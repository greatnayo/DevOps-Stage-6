#!/usr/bin/env python3
import jwt
import requests
import json
import time

# JWT secret from environment (same as in auth-api and users-api)
jwt_secret = "myfancysecret"

# Create a JWT token exactly as the auth-api does in getUserAPIToken method
payload = {
    "username": "admin",
    "scope": "read"
}

# Generate the token using the same algorithm as the Go JWT library
token = jwt.encode(payload, jwt_secret, algorithm="HS256")
print(f"Generated JWT token: {token}")

# Decode to verify
try:
    decoded = jwt.decode(token, jwt_secret, algorithms=["HS256"])
    print(f"Decoded payload: {json.dumps(decoded, indent=2)}")
except Exception as e:
    print(f"Error decoding: {e}")

# Test the users-api with the token
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

print("\nTesting /users/admin endpoint...")
try:
    response = requests.get("http://localhost:8083/users/admin", headers=headers)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Error: {e}")

print("\nTesting /users/ endpoint...")
try:
    response = requests.get("http://localhost:8083/users/", headers=headers)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Error: {e}")