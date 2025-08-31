# Log Analysis Specification

## Overview
This document outlines the log analysis requirements for the HelloGithubActions Spring Boot application deployed on Kubernetes using the ELK Stack (Elasticsearch, Logstash/Filebeat, Kibana).

## Architecture
```
Spring Boot App → Filebeat → Elasticsearch → Kibana
```

## 1. Application Logging Requirements

### 1.1 Log Format
- **Format**: Structured JSON logging
- **Timestamp**: ISO 8601 format with timezone
- **Log Levels**: ERROR, WARN, INFO, DEBUG, TRACE
- **Required Fields**:
  - `timestamp`
  - `level`
  - `logger`
  - `message`
  - `thread`
  - `mdc` (Mapped Diagnostic Context)

### 1.2 Spring Boot Configuration
- Enable actuator endpoints for log level management
- Configure logback-spring.xml for JSON output
- Add correlation ID for request tracing
- Include application metadata (version, environment)

### 1.3 Log Categories
- **Application Logs**: Business logic, errors, performance
- **Access Logs**: HTTP requests/responses
- **Security Logs**: Authentication, authorization events
- **System Logs**: JVM metrics, garbage collection

## 2. Filebeat Configuration Requirements

### 2.1 Collection Strategy
- Deploy as DaemonSet on Kubernetes
- Collect from `/var/log/containers/*.log`
- Parse multiline Java stack traces
- Add Kubernetes metadata (pod, namespace, labels)

### 2.2 Processing
- **Multiline Pattern**: Java exception handling
- **Processors**:
  - `add_kubernetes_metadata`
  - `drop_event` for health check noise
  - `decode_json_fields` for JSON logs

### 2.3 Output Configuration
- Elasticsearch cluster endpoint
- Index naming: `hellogithubactions-{+yyyy.MM.dd}`
- Template management enabled
- Retry and backoff configuration

## 3. Elasticsearch Requirements

### 3.1 Index Management
- **Index Pattern**: `hellogithubactions-*`
- **Retention Policy**: 30 days for application logs
- **Shards**: 1 primary, 1 replica for small deployment
- **Refresh Interval**: 5s for near real-time search

### 3.2 Mapping Requirements
```json
{
  "mappings": {
    "properties": {
      "@timestamp": { "type": "date" },
      "level": { "type": "keyword" },
      "logger": { "type": "keyword" },
      "message": { "type": "text", "analyzer": "standard" },
      "thread": { "type": "keyword" },
      "kubernetes": {
        "properties": {
          "pod": { "type": "keyword" },
          "namespace": { "type": "keyword" },
          "container": { "type": "keyword" }
        }
      },
      "mdc": {
        "properties": {
          "correlationId": { "type": "keyword" },
          "userId": { "type": "keyword" }
        }
      }
    }
  }
}
```

### 3.3 Performance Requirements
- **Query Response**: < 2s for dashboard queries
- **Indexing Rate**: Support 1000 logs/second
- **Storage**: 10GB initial allocation
- **Memory**: 2GB heap size minimum

## 4. Kibana Dashboard Requirements

### 4.1 Overview Dashboard
- **Time Range**: Last 24 hours default
- **Visualizations**:
  - Log volume over time (line chart)
  - Log levels distribution (pie chart)
  - Top error messages (data table)
  - Response time percentiles (histogram)

### 4.2 Application Monitoring Dashboard
- **Metrics**:
  - Request count by endpoint
  - Error rate percentage
  - Average response time
  - JVM memory usage trends

### 4.3 Error Analysis Dashboard
- **Components**:
  - Recent errors timeline
  - Error stack trace viewer
  - Affected pods/containers
  - Error correlation analysis

### 4.4 Security Dashboard
- **Monitoring**:
  - Failed authentication attempts
  - Unusual access patterns
  - Security-related log events
  - Geographic access distribution

## 5. Kubernetes Deployment Requirements

### 5.1 Filebeat DaemonSet
- **Resources**:
  - CPU: 100m request, 200m limit
  - Memory: 100Mi request, 200Mi limit
- **Volumes**: Access to `/var/log/containers`
- **Service Account**: Read access to Kubernetes API

### 5.2 Elasticsearch StatefulSet
- **Resources**:
  - CPU: 500m request, 1000m limit
  - Memory: 2Gi request, 4Gi limit
- **Storage**: 20Gi persistent volume
- **Replicas**: 1 for development, 3 for production

### 5.3 Kibana Deployment
- **Resources**:
  - CPU: 200m request, 500m limit
  - Memory: 1Gi request, 2Gi limit
- **Service**: LoadBalancer or Ingress for external access

## 6. Monitoring and Alerting

### 6.1 Health Checks
- Elasticsearch cluster health
- Filebeat data flow status
- Index size and growth monitoring
- Query performance metrics

### 6.2 Alerts Configuration
- **Critical**: Elasticsearch cluster red status
- **Warning**: High error rate (>5% in 5 minutes)
- **Info**: Disk usage >80%
- **Error**: Log ingestion stopped

### 6.3 Retention and Cleanup
- Automated index lifecycle management
- Archive old indices to cold storage
- Delete indices older than retention policy

## 7. Security Requirements

### 7.1 Authentication
- Kibana authentication via LDAP/OAuth
- Role-based access control (RBAC)
- Separate read/write permissions

### 7.2 Network Security
- TLS encryption for all communications
- Network policies to restrict access
- VPN access for external users

### 7.3 Data Privacy
- Log sanitization for sensitive data
- PII masking in application logs
- Audit trail for log access

## 8. Performance Benchmarks

### 8.1 Ingestion Performance
- Target: 1000 logs/second sustained
- Peak: 5000 logs/second for 10 minutes
- Latency: <100ms from application to Elasticsearch

### 8.2 Search Performance
- Dashboard load time: <3 seconds
- Complex queries: <5 seconds
- Real-time search: <1 second

## 9. Disaster Recovery

### 9.1 Backup Strategy
- Daily Elasticsearch snapshots
- Configuration backups (Kibana dashboards)
- Cross-region replication for production

### 9.2 Recovery Procedures
- Point-in-time recovery capability
- Automated failover procedures
- Data integrity validation

## 10. Implementation Timeline

### Phase 1: Basic Setup (Week 1)
- Deploy ELK stack on Kubernetes
- Configure basic Filebeat collection
- Create initial Kibana dashboards

### Phase 2: Enhancement (Week 2)
- Implement structured logging in Spring Boot
- Add correlation IDs and MDC
- Create advanced dashboards

### Phase 3: Production Readiness (Week 3)
- Configure alerting and monitoring
- Implement security measures
- Performance tuning and testing

### Phase 4: Operations (Ongoing)
- Monitor and maintain system
- Regular dashboard updates
- Capacity planning and scaling