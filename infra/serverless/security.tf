# Creation of IAM Role
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-serverless-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attatching policy with ECS Role
resource "aws_iam_role_policy_attachment" "lambda_execution_policy" {
  role       = aws_iam_role.lambda_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- NEW: Inline Policy for S3 and Kinesis Permissions ---
resource "aws_iam_role_policy" "lambda_additional_permissions" {
  name = "lambda-s3-kinesis-permissions"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # S3 PutObject Permissions
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource = "arn:aws:s3:::${var.bucket_name}/*"
      },

      # Kinesis permissions required for Lambda triggers
      {
        Effect = "Allow",
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListStreams",
          "kinesis:DescribeStreamSummary"
        ],
        Resource = local.kinesis_stream_arn
      }
    ]
  })
}
