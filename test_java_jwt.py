#!/usr/bin/env python3
import subprocess
import tempfile
import os

# Create a simple Java program to generate JWT token using the same library as users-api
java_code = '''
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import java.util.HashMap;
import java.util.Map;

public class JwtTest {
    public static void main(String[] args) {
        String secret = "myfancysecret";
        
        Map<String, Object> claims = new HashMap<>();
        claims.put("username", "admin");
        claims.put("scope", "read");
        
        String token = Jwts.builder()
            .setClaims(claims)
            .signWith(SignatureAlgorithm.HS256, secret.getBytes())
            .compact();
            
        System.out.println("Generated JWT token: " + token);
    }
}
'''

# Write the Java code to a temporary file
with tempfile.NamedTemporaryFile(mode='w', suffix='.java', delete=False) as f:
    f.write(java_code)
    java_file = f.name

try:
    # We would need to compile and run this Java code, but it requires the JWT library
    # Let's use a different approach instead
    print("Java JWT test would require setting up the classpath with the JWT library")
    print("Let's try a different approach...")
finally:
    os.unlink(java_file)