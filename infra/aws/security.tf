# Creating IAM User -- Attaching Policies with it and sending its creds to Azure
resource "aws_iam_user" "fluentbit_user" {
  name = "${var.project_name}-fluentbit-user"
}

# Attaching Policy to IAM User
resource "aws_iam_user_policy" "fluentbit_policy" {
    user = aws_iam_user.fluentbit_user.name
    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
        {
            Effect = "Allow",
            Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
            ],
            Resource = "*"
        },
        {
            Effect = "Allow",
            Action = [
            "kinesis:PutRecord",
            "kinesis:PutRecords"
            ],
            Resource = "*"
        }
        ]
    })
}


# Creating Access Key for this user and giving it to Fluentbit
resource "aws_iam_access_key" "fluentbit_keys" {
  user = aws_iam_user.fluentbit_user.name
}