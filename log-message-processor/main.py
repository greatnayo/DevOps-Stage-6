import time
import redis
import os
import json
import random
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler

def log_message(message):
    time_delay = random.randrange(0, 2000)
    time.sleep(time_delay / 1000)
    print('message received after waiting for {}ms: {}'.format(time_delay, message))

# Global variable to track Redis connection health
redis_healthy = False
redis_client_instance = None

class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            # Test Redis connection directly
            try:
                if redis_client_instance:
                    redis_client_instance.ping()
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({"status": "healthy"}).encode())
                else:
                    raise Exception("Redis client not initialized")
            except Exception as e:
                self.send_response(503)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "unhealthy", "error": "Redis connection failed"}).encode())
        else:
            self.send_response(404)
            self.end_headers()

def start_health_server():
    server = HTTPServer(('0.0.0.0', 8080), HealthHandler)
    server.serve_forever()

if __name__ == '__main__':
    redis_host = os.environ['REDIS_HOST']
    redis_port = int(os.environ['REDIS_PORT'])
    redis_channel = os.environ['REDIS_CHANNEL']
    
    # Start health check server in a separate thread
    health_thread = threading.Thread(target=start_health_server, daemon=True)
    health_thread.start()
    print('Health check server started on port 8080')

    try:
        redis_client_instance = redis.Redis(host=redis_host, port=redis_port, db=0)
        pubsub = redis_client_instance.pubsub()
        pubsub.subscribe([redis_channel])
        redis_healthy = True
        print('Connected to Redis successfully')
        
        for item in pubsub.listen():
            try:
                if item['type'] == 'message':
                    message = json.loads(str(item['data'].decode("utf-8")))
                    log_message(message)
            except Exception as e:
                print('Error processing message: {}'.format(e))
                continue
    except Exception as e:
        print('Failed to connect to Redis: {}'.format(e))
        redis_healthy = False
        # Keep the health server running even if Redis fails
        while True:
            time.sleep(10)




