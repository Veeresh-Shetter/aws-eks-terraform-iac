data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/scale_down.py"
  output_path = "${path.module}/scale_down.zip"
}

resource "aws_iam_role" "lambda_finops" {
  name = "${var.project_name}-lambda-finops-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "://amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "eks_scale_policy" {
  name = "${var.project_name}-eks-scale-policy"
  role = aws_iam_role.lambda_finops.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["eks:UpdateNodegroupConfig", "eks:DescribeNodegroup"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function" "eks_scale_down" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-eks-night-scaledown"
  role             = aws_iam_role.lambda_finops.arn
  handler          = "scale_down.handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      CLUSTER_NAME   = var.cluster_name
      NODEGROUP_NAME = var.nodegroup_name
    }
  }
}

resource "aws_cloudwatch_event_rule" "nightly_scaledown" {
  name                = "${var.project_name}-nightly-scaledown"
  description         = "Scale down EKS worker nodes nightly at 11:30 PM IST (18:00 UTC)"
  schedule_expression = "cron(0 18 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.nightly_scaledown.name
  target_id = "ScaleDownEKS"
  arn       = aws_lambda_function.eks_scale_down.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eks_scale_down.function_name
  principal     = "://amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.nightly_scaledown.arn
}
