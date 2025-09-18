# Or download directly
> curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.11.0-linux-x86_64.tar.gz

> tar xzvf filebeat-8.11.0-linux-x86_64.tar.gz

> cd filebeat-8.11.0-linux-x86_64/

filebeat.yml
```yaml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - ./logs/*.log                    # For relative paths
    - /home/abdullah/Documents/Abdullah/workspace/HelloGithubActions/logs/*.log    # For absolute paths
  fields:
    service: HelloGithubActions
    environment: development
  fields_under_root: true

# Output to console for testing
output.console:
  pretty: true
  enable: true

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