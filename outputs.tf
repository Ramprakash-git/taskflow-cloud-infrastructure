output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "alb_sec_grp_id" {
  description = "ID of the alb sec grp"
  value       = aws_security_group.alb.id
}

output "backend_pod_irsa_role_arn" {
  description = "ARN of backend IRSA role"
  value       = aws_iam_role.backend_pod.arn
}

output "backend_cd_role_arn" {
  description = "ARN of github actions role"
  value       = aws_iam_role.github_actions_cdb.arn
}

output "backend_ci_role_arn" {
  description = "ARN of github actions role"
  value       = aws_iam_role.github_actions_cib.arn
}

output "k8s_cd_role_arn" {
  description = "ARN of github actions role"
  value       = aws_iam_role.github_actions_k8s_cd.arn
}

output "eks_cluster_name" {
  description = "Name of EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.taskflow_repo.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.taskflow_repo.name
}

output "frontend_cd_role_arn" {
  description = "Frontend CD IAM role ARN"
  value       = aws_iam_role.github_actions_cdf.arn
}

output "cloudfront_distribution_id" {
  description = "Cloudfront distribution id"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_domain_name" {
  description = "Cloudfront distribution domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "rds_secret_arn" {
  description = "RDS secret ARN"
  value       = aws_db_instance.postgres_db.master_user_secret[0].secret_arn
}

output "cognito_user_pool_id" {
  description = "taskflow-user-pool-id"
  value       = aws_cognito_user_pool.taskflow_users.id
}

output "cognito_app_client_id" {
  description = "taskflow-frontend-client-id"
  value       = aws_cognito_user_pool_client.taskflow_frontend.id
}

output "cluster_autoscaler_role_arn" {
  value = aws_iam_role.cluster_autoscaler.arn
}