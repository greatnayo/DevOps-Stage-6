# Implementation Plan

- [x] 1. Update environment configuration for Traefik and domain setup

  - Add Traefik-specific environment variables to .env file
  - Configure domain, ACME email, and Let's Encrypt environment settings
  - Add EC2 and security configuration variables
  - _Requirements: 7.1, 7.2, 8.3_

- [x] 2. Add Traefik service to Docker Compose configuration

  - Add Traefik service definition to docker-compose.yml
  - Configure Traefik ports (80, 443, 8080) and volume mounts
  - Set up Docker socket access and certificate storage volume
  - Configure Traefik environment variables and restart policy
  - _Requirements: 3.1, 3.2, 6.1, 6.2_

- [x] 3. Configure Traefik static configuration via environment variables

  - Set up API and dashboard configuration
  - Configure Let's Encrypt certificate resolver with ACME settings
  - Set up Docker provider for automatic service discovery
  - Configure entry points for HTTP and HTTPS traffic
  - _Requirements: 3.1, 3.3, 5.1, 6.3_

- [x] 4. Add Traefik labels to frontend service for root domain routing

  - Add Traefik enable label to frontend service
  - Configure router rule for root domain access
  - Set up TLS certificate resolver for HTTPS
  - Configure load balancer to target frontend port 80
  - _Requirements: 1.1, 1.2, 2.4_

- [x] 5. Add Traefik labels to auth-api service for /api/auth routing

  - Add Traefik enable label to auth-api service
  - Configure router rule for /api/auth path prefix
  - Set up path stripping middleware to remove /api/auth prefix
  - Configure TLS certificate resolver and load balancer port
  - _Requirements: 2.1, 2.4, 4.4_

- [x] 6. Add Traefik labels to todos-api service for /api/todos routing

  - Add Traefik enable label to todos-api service
  - Configure router rule for /api/todos path prefix
  - Set up path stripping middleware to remove /api/todos prefix
  - Configure TLS certificate resolver and load balancer port
  - _Requirements: 2.2, 2.4, 4.5_

- [x] 7. Add Traefik labels to users-api service for /api/users routing

  - Add Traefik enable label to users-api service
  - Configure router rule for /api/users path prefix
  - Set up path stripping middleware to remove /api/users prefix
  - Configure TLS certificate resolver and load balancer port
  - _Requirements: 2.3, 2.4, 4.6_

- [ ] 8. Configure HTTP to HTTPS redirection middleware

  - Create global HTTP to HTTPS redirect middleware
  - Apply redirect middleware to all HTTP routers
  - Configure redirect scheme and permanent redirect status
  - Test redirection works for all endpoints
  - _Requirements: 1.2, 1.3_

- [x] 9. Remove direct port mappings from backend services

  - Remove port mappings from auth-api, todos-api, and users-api services
  - Keep internal service ports for container communication
  - Update service dependencies and health checks
  - Ensure services remain accessible via Traefik only
  - _Requirements: 3.2, 8.1_

- [x] 10. Update frontend API endpoint configuration for domain-based routing

  - Modify frontend environment variables to use domain-based API URLs
  - Update AUTH_API_ADDRESS to use https://[domain]/api/auth
  - Update TODOS_API_ADDRESS to use https://[domain]/api/todos
  - Test frontend can communicate with APIs through Traefik
  - _Requirements: 2.1, 2.2, 2.3_

- [x] 11. Add certificate storage volume to Docker Compose

  - Create traefik-certs volume in docker-compose.yml
  - Mount volume to /letsencrypt in Traefik container
  - Configure proper volume permissions and persistence
  - Test certificate storage survives container restarts
  - _Requirements: 6.1, 6.2, 6.3_

- [ ] 12. Configure Traefik dashboard access with security

  - Add Traefik dashboard router configuration
  - Set up dashboard access on /dashboard path
  - Configure TLS for dashboard access
  - Add basic authentication middleware for dashboard security
  - _Requirements: 5.1, 5.2, 5.5_

- [ ] 13. Add health checks and monitoring configuration

  - Configure Traefik health check endpoint
  - Add health check labels to Traefik service
  - Set up service health monitoring in Traefik
  - Configure proper startup dependencies with health conditions
  - _Requirements: 3.4, 5.3, 8.5_

- [ ] 14. Create EC2 deployment documentation and scripts

  - Create deployment script for EC2 instance setup
  - Document security group configuration requirements
  - Create DNS configuration guide for freedns.afraid.org
  - Add troubleshooting guide for common deployment issues
  - _Requirements: 8.1, 8.2, 8.3, 8.5_

- [ ] 15. Test complete HTTPS setup with Let's Encrypt staging

  - Configure Let's Encrypt staging environment for testing
  - Test certificate provisioning and SSL termination
  - Verify all routes work correctly with HTTPS
  - Test HTTP to HTTPS redirection functionality
  - _Requirements: 1.3, 1.4, 7.3, 9.3_

- [ ] 16. Implement error handling and custom error pages

  - Configure custom error pages for common HTTP errors
  - Set up proper error handling for service unavailability
  - Configure Traefik error logging and monitoring
  - Test error responses for various failure scenarios
  - _Requirements: 9.1, 9.2, 9.4, 9.5_

- [ ] 17. Add production Let's Encrypt configuration

  - Create production environment configuration
  - Switch from staging to production Let's Encrypt servers
  - Configure rate limiting and certificate renewal settings
  - Test production certificate provisioning
  - _Requirements: 1.3, 1.4, 6.4, 7.4_

- [ ] 18. Test end-to-end application functionality through Traefik
  - Test complete user login flow through HTTPS domain
  - Verify TODO dashboard access after login
  - Test all API endpoints return expected responses
  - Validate authentication and authorization work correctly
  - Test application performance and response times
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_
