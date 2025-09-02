package com.cm.hellogithubactions.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api")
public class HealthController {

    private static final Logger logger = LoggerFactory.getLogger(HealthController.class);

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health(HttpServletRequest request) {
        String correlationId = UUID.randomUUID().toString();
        MDC.put("correlationId", correlationId);
        MDC.put("endpoint", "/api/health");
        MDC.put("method", "GET");
        MDC.put("clientIp", getClientIp(request));

        logger.info("Health check requested");

        try {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "UP");
            response.put("timestamp", LocalDateTime.now());
            response.put("correlationId", correlationId);

            logger.info("Health check completed successfully");
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            logger.error("Health check failed", e);
            return ResponseEntity.internalServerError().build();
        } finally {
            MDC.clear();
        }
    }

    @GetMapping("/hello")
    public ResponseEntity<Map<String, Object>> hello(
            @RequestParam(value = "name", defaultValue = "World") String name,
            HttpServletRequest request) {

        String correlationId = UUID.randomUUID().toString();
        MDC.put("correlationId", correlationId);
        MDC.put("endpoint", "/api/hello");
        MDC.put("method", "GET");
        MDC.put("clientIp", getClientIp(request));
        MDC.put("requestParam.name", name);

        logger.info("Hello request received for name: {}", name);

        try {
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Hello, " + name + "!");
            response.put("timestamp", LocalDateTime.now());
            response.put("correlationId", correlationId);

            logger.info("Hello request processed successfully");
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            logger.error("Hello request failed", e);
            return ResponseEntity.internalServerError().build();
        } finally {
            MDC.clear();
        }
    }

    @PostMapping("/log-test")
    public ResponseEntity<Map<String, Object>> logTest(
            @RequestBody Map<String, Object> payload,
            HttpServletRequest request) {

        String correlationId = UUID.randomUUID().toString();
        MDC.put("correlationId", correlationId);
        MDC.put("endpoint", "/api/log-test");
        MDC.put("method", "POST");
        MDC.put("clientIp", getClientIp(request));

        logger.info("Log test endpoint called with payload size: {}", payload.size());

        try {
            // Demonstrate different log levels
            logger.trace("TRACE: Processing log test request");
            logger.debug("DEBUG: Payload received: {}", payload);
            logger.info("INFO: Log test processing started");
            logger.warn("WARN: This is a test warning message");

            // Simulate potential error condition
            if (payload.containsKey("simulateError") &&
                Boolean.TRUE.equals(payload.get("simulateError"))) {
                logger.error("ERROR: Simulated error condition triggered");
                throw new RuntimeException("Simulated error for testing");
            }

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Log test completed");
            response.put("correlationId", correlationId);
            response.put("logLevelsGenerated", new String[]{"TRACE", "DEBUG", "INFO", "WARN"});
            response.put("timestamp", LocalDateTime.now());

            logger.info("Log test completed successfully");
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            logger.error("Log test failed with exception", e);

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Log test failed");
            errorResponse.put("message", e.getMessage());
            errorResponse.put("correlationId", correlationId);
            errorResponse.put("timestamp", LocalDateTime.now());

            return ResponseEntity.internalServerError().body(errorResponse);
        } finally {
            MDC.clear();
        }
    }

    private String getClientIp(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }

        String xRealIp = request.getHeader("X-Real-IP");
        if (xRealIp != null && !xRealIp.isEmpty()) {
            return xRealIp;
        }

        return request.getRemoteAddr();
    }
}