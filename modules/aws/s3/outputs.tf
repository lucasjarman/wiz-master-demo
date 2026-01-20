output "s3_backup_bucket_name" {
  value       = try(aws_s3_bucket.s3["backups"].id, null)
  description = "Name of S3 'backup' bucket."
}

output "s3_state_bucket_name" {
  value       = try(aws_s3_bucket.s3["state"].id, null)
  description = "Name of S3 'state' bucket."
}

output "s3_buckets" {
  value       = aws_s3_bucket.s3
  description = "List of objects created by the module"
}

output "s3_backup_bucket_arn" {
  value       = try(aws_s3_bucket.s3["backup"].arn, null)
  description = "Arn of the 'backup' bucket"
}

output "s3_state_bucket_arn" {
  value       = try(aws_s3_bucket.s3["state"].arn, null)
  description = "Arn of the 'state' bucket"
}
