# App Runner Service Definition
resource "aws_apprunner_service" "service" {
  service_name = var.service_name
  source_configuration {
    image_repository {
      image_configuration {
        port = var.port
      }
      image_identifier      = var.image_identifier
      image_repository_type = var.image_repository_type
    }
    authentication_configuration {
      access_role_arn = var.access_role_arn
    }
    auto_deployments_enabled = var.auto_deployments_enabled
  }
  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.autoscaling_config.arn
  instance_configuration {
    cpu    = var.cpu
    memory = var.memory
  }  
}

# App Runner Autoscaling configuration
resource "aws_apprunner_auto_scaling_configuration_version" "autoscaling_config" {
  auto_scaling_configuration_name = var.auto_scaling_configuration_name
  max_concurrency                 = var.auto_scaling_max_concurrency
  max_size                        = var.auto_scaling_max_size
  min_size                        = var.auto_scaling_min_size
}

# App Runner Deployment configuration
resource "aws_apprunner_deployment" "deployment" {
  service_arn = aws_apprunner_service.service.arn
}