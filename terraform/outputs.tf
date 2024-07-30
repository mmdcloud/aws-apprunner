output "apprunner_url" {
  value = aws_apprunner_service.nodeapp-service.service_url
}

# output "apprunner_url" {
#   value = var.subdomain_name
# }
