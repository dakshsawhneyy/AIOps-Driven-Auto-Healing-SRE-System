# ----------------------------------------------------
# Disable ALL default outputs, inputs, filters
# ----------------------------------------------------
outputs:
  es:
    enabled: false
  forward:
    enabled: false
  stdout:
    enabled: false

inputs:
  tail:
    enabled: false

filters:
  kubernetes:
    enabled: false

# ----------------------------------------------------
# Force FluentBit to use ONLY your config
# ----------------------------------------------------
config:
  existingConfigMap: ""   # IMPORTANT
  service: |
    [SERVICE]
        Flush        1
        Daemon       Off
        Log_Level    info
        HTTP_Server  On
        HTTP_Listen  0.0.0.0
        HTTP_Port    2020

  inputs: |
    [INPUT]
        Name              tail
        Path              /var/log/containers/*.log
        Tag               kube.*
        Multiline         On
        Parser            docker
        Refresh_Interval  5

  filters: |
    [FILTER]
        Name                kubernetes
        Match               kube.*
        Merge_Log           On
        Keep_Log            On
        K8S-Logging.Parser  On

  outputs: |
    [OUTPUT]
        Name                  cloudwatch_logs
        Match                 *
        region                ${aws_region}
        log_group_name        ${log_group_name}
        log_stream_prefix     aks-
        auto_create_group     true
        aws_access_key_id     $AWS_ACCESS_KEY_ID
        aws_secret_access_key $AWS_SECRET_ACCESS_KEY

    [OUTPUT]
        Name                  kinesis_streams
        Match                 *
        region                ${aws_region}
        stream                ${kinesis_stream_name}
        partition_key         container_name
        append_newline        On
        aws_access_key_id     $AWS_ACCESS_KEY_ID
        aws_secret_access_key $AWS_SECRET_ACCESS_KEY


# ----------------------------------------------------
# AWS Credentials
# ----------------------------------------------------
env:
  - name: AWS_ACCESS_KEY_ID
    valueFrom:
      secretKeyRef:
        name: fluentbit-aws-credentials
        key: AWS_ACCESS_KEY_ID

  - name: AWS_SECRET_ACCESS_KEY
    valueFrom:
      secretKeyRef:
        name: fluentbit-aws-credentials
        key: AWS_SECRET_ACCESS_KEY
