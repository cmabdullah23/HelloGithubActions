# Or download directly
> curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.11.0-linux-x86_64.tar.gz

> tar xzvf filebeat-8.11.0-linux-x86_64.tar.gz

> cd filebeat-8.11.0-linux-x86_64/

filebeat.yml
```yaml
# ==============================================================================
# INPUT CONFIGURATION
# ==============================================================================
filebeat.inputs:
- type: log                                    # Monitor log files
  enabled: true                               # Activate this input
  paths:
    - ./logs/*.log                    # Relative path - all .log files in logs directory
    - /home/abdullah/Documents/Abdullah/workspace/HelloGithubActions/logs/*.log    # Absolute path example (replace with actual path)
  # Multiline handling for Java stack traces
  multiline.pattern: '^[0-9]{4}-[0-9]{2}-[0-9]{2}' # Regex: lines starting with YYYY-MM-DD
  multiline.negate: true                     # Lines matching pattern START new events
  multiline.match: after                    # Non-matching lines come AFTER matching lines
  # Field enrichment - adds metadata to every log entry
  fields:
    service: HelloGithubActions # Service identifier
    environment: development    # Environment tag (dev/staging/prod)
  fields_under_root: true       # Place custom fields at root level of JSON

# ==============================================================================
# OUTPUT CONFIGURATION
# ==============================================================================

# Primary output: Console (for development/testing)
#output.console:
#  pretty: true                              # Format JSON output for readability
#  enable: true                              # Explicitly enable console output

# File output - saves processed logs to local files
output.file:
  path: "./filebeat-output"               # Output directory
  filename: filebeat-output.json          # Base filename
  rotate_every_kb: 10000                  # Create new file every 10MB
  number_of_files: 3                      # Keep maximum 3 files (rotate/delete old ones)

# Elasticsearch output - sends logs to Elasticsearch cluster
output.elasticsearch:
  hosts: ["localhost:9200"]               # Elasticsearch server(s)
  index: "local-app-logs-%{+yyyy.MM.dd}"  # Daily index pattern (e.g., local-app-logs-2025.09.18)
#    Additional ES options:
  username: "elastic"                   # Authentication
  password: "your-password"
  protocol: "https"                     # For secure connections
  bulk_max_size: 1600                   # Batch size for efficiency

logging.level: info
```

# Test the configuration file
./filebeat test config

# Run Filebeat in foreground with console output
./filebeat -e -c filebeat.yml

# Run with debug logging
./filebeat -e -c filebeat.yml -d "*"

# Start Filebeat in background
./filebeat -c filebeat.yml &

# Or using nohup for persistent running
nohup ./filebeat -c filebeat.yml > filebeat.out 2>&1 &

# Check if it's running
ps aux | grep filebeat

# Stop it
pkill filebeat
filebeat.yml
```yaml
# ==============================================================================
# INPUT CONFIGURATION
# ==============================================================================
filebeat.inputs:
- type: log                                    # Monitor log files
  enabled: true                               # Activate this input
  paths:
    - ./logs/*.log                    # Relative path - all .log files in logs directory
    - /home/abdullah/Documents/Abdullah/workspace/HelloGithubActions/logs/*.log    # Absolute path example (replace with actual path)
  # Multiline handling for Java stack traces
  multiline.pattern: '^[0-9]{4}-[0-9]{2}-[0-9]{2}' # Regex: lines starting with YYYY-MM-DD
  multiline.negate: true                     # Lines matching pattern START new events
  multiline.match: after                    # Non-matching lines come AFTER matching lines
  # Field enrichment - adds metadata to every log entry
  fields:
    app_name: HelloGithubActions      # Changed from 'service' to 'app_name'
    env: development                  # Changed from 'environment' to 'env'
  fields_under_root: true       # Place custom fields at root level of JSON

# ==============================================================================
# OUTPUT CONFIGURATION
# ==============================================================================

# Primary output: Console (for development/testing)
#output.console:
#  pretty: true                              # Format JSON output for readability
#  enable: true                              # Explicitly enable console output

# File output - saves processed logs to local files
#output.file:
#  path: "./filebeat-output"               # Output directory
#  filename: filebeat-output.json          # Base filename
#  rotate_every_kb: 10000                  # Create new file every 10MB
#  number_of_files: 3                      # Keep maximum 3 files (rotate/delete old ones)

# ==============================================================================
# TEMPLATE CONFIGURATION (Must be at root level)
# ==============================================================================
setup.template.name: "local-app-logs"
setup.template.pattern: "local-app-logs-*"
setup.template.settings:
  index.number_of_shards: 1
  index.number_of_replicas: 0
  index.refresh_interval: "5s"

# Index Lifecycle Management
setup.ilm.enabled: false

# Elasticsearch output - sends logs to Elasticsearch cluster
output.elasticsearch:
  hosts: ["localhost:9200"]               # Elasticsearch server(s)
  index: "local-app-logs-%{+yyyy.MM.dd}"  # Daily index pattern (e.g., local-app-logs-2025.09.18)
#    Additional ES options:
  # Authentication (for local dev, these are optional)
  # username: "elastic"                         # Uncomment if auth enabled
  # password: "your-password"                   # Uncomment if auth enabled
  # Connection settings
  protocol: "http"                              # Use http for local (https for production)
  timeout: 90
  max_retries: 3
  backoff.init: 1s
  backoff.max: 60s

logging.level: info
```