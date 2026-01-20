output "AccessRoleToSNS" {
  value       = aws_iam_role.WizAccessRoleToSns.arn
  description = "ARN of the role that Wiz will assume to publish messages to the queue"
}

output "SNSTopicArn" {
  value       = aws_sns_topic.WizIssuesToRemediateSNSTopic.arn
  description = "ARN of the SNS topic where Wiz will publish Response Actions"
}

output "WizRemediationLambda" {
  value       = aws_lambda_function.LambdaFunction.function_name
  description = "The Lambda function that will run the remediation functions"
}

output "WizRemediationQueue" {
  value       = aws_sqs_queue.WizIssuesToRemediateQueue.url
  description = "Remediation SQS Queue URL"
}

output "WizRemediationWorkerId" {
  value       = local.account_id
  description = "Worker AWS Account ID"
}

output "WizRemediationWorkerIAMRole" {
  value       = aws_iam_role.RemediationWorkerRole.name
  description = "Remediation Worker IAM Role"
}

output "WizCustomResponseFunctionsBucketNameOutput" {
  value       = length(aws_s3_bucket.WizRemediationCustomFunctionsBucket) > 0 ? aws_s3_bucket.WizRemediationCustomFunctionsBucket[0].bucket : null
  description = "The name of the S3 bucket where custom response functions are stored"
  depends_on  = [aws_s3_bucket.WizRemediationCustomFunctionsBucket]
}
