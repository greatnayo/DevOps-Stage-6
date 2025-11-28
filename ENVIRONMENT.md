# Environment Configuration Guide

This document describes the environment configuration for the containerized microservices application.

## Overview

The application uses Docker Compose with environment variables for configuration. Environment variables can be set in multiple ways with the following precedence (highest to lowest):

1. Environment variables set in the shell
2. Environment variables defined in docker-compose.yml
3. Environment variables defined in .env file
4. Default values defined in docker-compose.yml

## Environment Variables

### Frontend Service

| Variable            | Default                 | Description                    |
| ------------------- | ----------------------- | ------------------------------ |
| `PORT`              | `8080`                  | Port for the frontend service  |
| `AUTH_API_ADDRESS`  | `http://auth-api:8081`  | URL for the authentication API |
| `TODOS_API_ADDRESS` | `http://todos-api:8082` | URL for the todos API          |
| `ZIPKIN_URL`        | _(empty)_               | Optional Zipkin tracing URL    |

### Auth API Service

| Variable            | Default                 | Description                      |
| ------------------- | ----------------------- | -------------------------------- |
| `AUTH_API_PORT`     | `8081`                  | Port for the auth API service    |
| `JWT_SECRET`        | `myfancysecret`         | Secret key for JWT token signing |
| `USERS_API_ADDRESS` | `http://users-api:8083` | URL for the users API            |
| `ZIPKIN_URL`        | _(empty)_               | Optional Zipkin tracing URL      |

### Todos API Service

| Variable        | Default         | Description                          |
| --------------- | --------------- | ------------------------------------ |
| `TODO_API_PORT` | `8082`          | Port for the todos API service       |
| `JWT_SECRET`    | `myfancysecret` | Secret key for JWT token validation  |
| `REDIS_HOST`    | `redis-queue`   | Redis server hostname                |
| `REDIS_PORT`    | `6379`          | Redis server port                    |
| `REDIS_CHANNEL` | `log_channel`   | Redis channel for message publishing |
| `ZIPKIN_URL`    | _(empty)_       | Optional Zipkin tracing URL          |

### Users API Service

| Variable      | Default         | Description                         |
| ------------- | --------------- | ----------------------------------- |
| `SERVER_PORT` | `8083`          | Port for the users API service      |
| `JWT_SECRET`  | `myfancysecret` | Secret key for JWT token validation |
| `ZIPKIN_URL`  | _(empty)_       | Optional Zipkin tracing URL         |

### Log Message Processor Service

| Variable        | Default       | Description                           |
| --------------- | ------------- | ------------------------------------- |
| `REDIS_HOST`    | `redis-queue` | Redis server hostname                 |
| `REDIS_PORT`    | `6379`        | Redis server port                     |
| `REDIS_CHANNEL` | `log_channel` | Redis channel for message consumption |
| `ZIPKIN_URL`    | _(empty)_     | Optional Zipkin tracing URL           |

## Service Communication

Services communicate using Docker Compose service names as hostnames:

- `frontend` → `auth-api:8081` for authentication
- `frontend` → `todos-api:8082` for todo operations
- `auth-api` → `users-api:8083` for user data
- `todos-api` → `redis-queue:6379` for message publishing
- `log-message-processor` → `redis-queue:6379` for message consumption

## Configuration Examples

### Basic Usage

Start all services with default configuration:

```bash
docker compose up -d
```

### Override Environment Variables

Override specific variables:

```bash
JWT_SECRET=production_secret docker compose up -d
```

### Custom .env File

Create a custom .env file for different environments:

```bash
# .env.production
JWT_SECRET=production_secret
ZIPKIN_URL=http://zipkin:9411/api/v2/spans
```

Then use it:

```bash
docker compose --env-file .env.production up -d
```

### Development with Zipkin Tracing

Enable distributed tracing:

```bash
ZIPKIN_URL=http://localhost:9411/api/v2/spans docker compose up -d
```

## Validation

Use the provided validation script to check configuration:

```bash
./validate-env.sh
```

This script will:

- Verify all required files exist
- Check environment variable values
- Validate Docker service names are used for internal communication
- Test docker-compose.yml syntax
- Verify all services are defined
- Test environment variable precedence

## Security Considerations

- **JWT_SECRET**: Change the default value in production
- **Environment Files**: Don't commit sensitive values to version control
- **Network Isolation**: Services communicate only within the Docker network
- **Port Exposure**: Only necessary ports are exposed to the host

## Troubleshooting

### Common Issues

1. **Service can't connect to another service**

   - Verify service names match those defined in docker-compose.yml
   - Check that both services are on the same network

2. **Environment variables not taking effect**

   - Check the precedence order
   - Verify .env file syntax (no spaces around =)
   - Restart services after changing environment variables

3. **Redis connection failures**
   - Ensure Redis service is healthy before dependent services start
   - Check REDIS_HOST points to 'redis-queue' service name

### Debug Commands

Check resolved configuration:

```bash
docker compose config
```

View service logs:

```bash
docker compose logs [service-name]
```

Check service health:

```bash
docker compose ps
```
