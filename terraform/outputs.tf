output "apprunner_domain" {
  value = aws_apprunner_service.nodeapp-service.service_url
}
