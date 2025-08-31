package com.cm.hellogithubactions;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextRefreshedEvent;

@SpringBootApplication
public class HelloGithubActionsApplication implements ApplicationListener<ContextRefreshedEvent> {
    
    private static final Logger logger = LoggerFactory.getLogger(HelloGithubActionsApplication.class);
    
    public static void main(String[] args) {
        logger.info("Starting HelloGithubActions application...");
        
        try {
            SpringApplication.run(HelloGithubActionsApplication.class, args);
            logger.info("HelloGithubActions application started successfully");
        } catch (Exception e) {
            logger.error("Failed to start HelloGithubActions application", e);
            System.exit(1);
        }
    }
    
    @Override
    public void onApplicationEvent(ContextRefreshedEvent event) {
        MDC.put("event", "application_ready");
        logger.info("Application context refreshed. System is ready to serve requests");
        MDC.clear();
    }
}
