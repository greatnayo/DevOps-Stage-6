#!/bin/sh

# Set default values for environment variables if not provided
export AUTH_API_ADDRESS=${AUTH_API_ADDRESS:-https://nayo.katonytech.com/api/auth}
export TODOS_API_ADDRESS=${TODOS_API_ADDRESS:-https://nayo.katonytech.com/api/todos}

# Create nginx config based on whether ZIPKIN_URL is set
if [ -z "$ZIPKIN_URL" ]; then
    echo "ZIPKIN_URL is empty, creating config without zipkin location block"
    # Create config without zipkin location block - remove from "# Proxy zipkin requests" to the closing brace
    sed '/# Proxy zipkin requests (optional tracing)/,/^        }$/d' /etc/nginx/nginx.conf.template > /tmp/nginx.conf
    envsubst '${AUTH_API_ADDRESS} ${TODOS_API_ADDRESS} ${DOMAIN}' < /tmp/nginx.conf > /etc/nginx/nginx.conf
else
    echo "ZIPKIN_URL is set to: $ZIPKIN_URL"
    # Create config with zipkin location block
    envsubst '${AUTH_API_ADDRESS} ${TODOS_API_ADDRESS} ${ZIPKIN_URL} ${DOMAIN}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
fi

# Start nginx
exec nginx -g 'daemon off;'