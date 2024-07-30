# Creating a Elastic Container Repository
resource "aws_ecr_repository" "nodeapp" {
  name                 = "nodeapp"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = false
  }
}

# Bash script to build the docker image and push it to ECR
resource "null_resource" "push_to_ecr" {
  provisioner "local-exec" {
    command = "bash ${path.cwd}/../ecr-build-push.sh ${aws_ecr_repository.nodeapp.name} ${var.region}"
  }
}

# App Runner role to manage ECR
resource "aws_iam_role" "apprunner-ecr-access-role" {
  name               = "apprunner-ecr-access-role"
  assume_role_policy = <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "build.apprunner.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
    }
    EOF
}

# AppRunnerECRAccess policy attachment 
resource "aws_iam_role_policy_attachment" "apprunner-ecr-access-role-policy-attachment" {
  role       = aws_iam_role.apprunner-ecr-access-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# App Runner Service Definition
resource "aws_apprunner_service" "nodeapp-service" {
  service_name = "nodeapp-service"
  source_configuration {
    image_repository {
      image_configuration {
        port = "3000"
      }
      image_identifier      = "${aws_ecr_repository.nodeapp.repository_url}:latest"
      image_repository_type = "ECR"
    }
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner-ecr-access-role.arn
    }
    auto_deployments_enabled = true
  }
  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.nodeapp.arn
  instance_configuration {
    cpu    = "1 vCPU"
    memory = "2 GB"
  }
  depends_on = [null_resource.push_to_ecr]
}

# App Runner Autoscaling configuration
resource "aws_apprunner_auto_scaling_configuration_version" "nodeapp" {
  auto_scaling_configuration_name = "nodeapp"
  max_concurrency                 = 100
  max_size                        = 25
  min_size                        = 1
}

# App Runner Deployment configuration
resource "aws_apprunner_deployment" "nodeapp-deployment" {
  service_arn = aws_apprunner_service.nodeapp-service.arn
}

# # Route 53 Zone Configuration 
# resource "aws_route53_zone" "route53_zone" {
#   name          = var.domain_name
#   force_destroy = true
# }

# # Route 53 Health Check
# resource "aws_route53_health_check" "health_check" {
#   fqdn              = aws_apprunner_service.nodeapp-service.service_url
#   port              = 80
#   type              = "HTTP"
#   resource_path     = "/"
#   failure_threshold = "5"
#   request_interval  = "30"

#   tags = {
#     Name = "health-check"
#   }
# }

# # Route 53 Record Configuration 
# resource "aws_route53_record" "route53_record" {
#   zone_id         = aws_route53_zone.route53_zone.zone_id
#   set_identifier  = "apprunner"
#   name            = var.subdomain_name
#   type            = "CNAME"
#   health_check_id = aws_route53_health_check.health_check.id
#   ttl             = 300
#   records         = ["${aws_apprunner_service.nodeapp-service.service_url}"]
# }

# # AWS Certificate Manager
# resource "aws_acm_certificate" "domain-certificate" {
#   domain_name       = var.domain_name
#   validation_method = "DNS"
#   lifecycle {
#     create_before_destroy = true
#   }
# }
