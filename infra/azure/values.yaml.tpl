# Disable default output (Elasticsearch)
output:
  enabled: false

# Enable and configure CloudWatch Logs output
cloudWatchLogs:
  enabled: true
  region: ${aws_region}
  logGroupName: ${log_group_name}
  autoCreateGroup: true
  roleArn: ${role_arn}
  # You can also use logStreamTemplate to organize logs, e.g., ${kubernetes['namespace_name']}/${kubernetes['pod_name']}
  logStreamTemplate: "${kubernetes['namespace_name']}-${kubernetes['pod_name']}"

# Enable and configure Kinesis Streams output
kinesisStreams:
  enabled: true
  region: ${aws_region}
  stream: ${kinesis_stream_name}
  roleArn: #{role_arn}