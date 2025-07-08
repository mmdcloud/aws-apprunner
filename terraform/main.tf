# ECR Module
module "ecr" {
  source               = "./modules/ecr"
  repo_name            = "nodeapp"
  command              = "bash ${path.cwd}/../src/ecr-build-push.sh ${module.ecr.name} ${var.region}"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
  scan_on_push         = false
}

# App Runner role to manage ECR
resource "aws_iam_role" "apprunner_ecr_access_role" {
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
  role       = aws_iam_role.apprunner_ecr_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# App Runner Module
module "app_runner" {
  source                          = "./modules/app_runner"
  service_name                    = "nodeapp-service"
  port                            = "3000"
  auto_deployments_enabled        = true
  auto_scaling_configuration_name = "nodeapp-auto-scaling-config"
  auto_scaling_max_concurrency    = 100
  auto_scaling_max_size           = 25
  auto_scaling_min_size           = 1
  access_role_arn                 = aws_iam_role.apprunner_ecr_access_role.arn
  cpu                             = "1 vCPU"
  memory                          = "2 GB"
  image_identifier                = "${module.ecr.repository_url}:latest"
  image_repository_type           = "ECR"
}