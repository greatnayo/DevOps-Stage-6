package com.elgris.usersapi.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.GenericFilterBean;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

@Component
public class JwtAuthenticationFilter extends GenericFilterBean {

    @Value("${jwt.secret}")
    private String jwtSecret;
    
    private boolean debugLogged = false;

    public void doFilter(final ServletRequest req, final ServletResponse res, final FilterChain chain)
            throws IOException, ServletException {

        final HttpServletRequest request = (HttpServletRequest) req;
        final HttpServletResponse response = (HttpServletResponse) res;
        final String requestURI = request.getRequestURI();

        // Skip JWT validation for health endpoint
        if ("/health".equals(requestURI)) {
            chain.doFilter(req, res);
            return;
        }

        final String authHeader = request.getHeader("authorization");

        if ("OPTIONS".equals(request.getMethod())) {
            response.setStatus(HttpServletResponse.SC_OK);

            chain.doFilter(req, res);
        } else {

            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                throw new ServletException("Missing or invalid Authorization header");
            }

            final String token = authHeader.substring(7);

            try {
                // Debug logging (only once)
                if (!debugLogged) {
                    System.out.println("DEBUG: JWT Secret being used: " + jwtSecret);
                    System.out.println("DEBUG: JWT Token received: " + token);
                    debugLogged = true;
                }
                
                final Claims claims = Jwts.parser()
                        .setSigningKey(jwtSecret.getBytes())
                        .parseClaimsJws(token)
                        .getBody();
                request.setAttribute("claims", claims);
                
                System.out.println("DEBUG: JWT token validated successfully, username: " + claims.get("username"));
                
                // Set up Spring Security authentication context
                org.springframework.security.core.Authentication authentication = 
                    new org.springframework.security.authentication.UsernamePasswordAuthenticationToken(
                        claims.get("username"), null, java.util.Collections.emptyList());
                org.springframework.security.core.context.SecurityContextHolder.getContext().setAuthentication(authentication);
            } catch (final SignatureException e) {
                System.out.println("DEBUG: JWT signature validation failed: " + e.getMessage());
                throw new ServletException("Invalid token");
            }

            chain.doFilter(req, res);
        }
    }
}