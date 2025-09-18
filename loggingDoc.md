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