data "vault_generic_secret" "stack_secrets" {
  path = "applications/${var.aws_profile}/${var.environment}/${local.stack_name}-stack"
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [local.vpc_name]
  }
}

data "aws_ecs_cluster" "ecs-cluster" {
  cluster_name = "${local.name_prefix}-cluster"
}
data "aws_iam_role" "ecs-cluster-iam-role" {
  name = "${local.name_prefix}-ecs-task-execution-role"
}

data "aws_lb" "dev-site-lb" {
  name = "dev-site-${var.environment}-lb"
}
data "aws_lb_listener" "dev-site-lb-listener" {
  load_balancer_arn = data.aws_lb.dev-site-lb.arn
  port              = 443
}

data "vault_generic_secret" "secrets" {
  path = "applications/${var.aws_profile}/${var.environment}/${local.stack_name}-stack"
}

#Get application subnet IDs
data "aws_subnets" "application" {
  filter {
    name   = "tag:Name"
    values = [local.application_subnet_pattern]
  }
}

# retrieve all secrets for this stack using the stack path
data "aws_ssm_parameters_by_path" "secrets" {
  path = "/${local.name_prefix}"
}
# create a list of secrets names to retrieve them in a nicer format and lookup each secret by name
data "aws_ssm_parameter" "secret" {
  for_each = toset(data.aws_ssm_parameters_by_path.secrets.names)
  name     = each.key
}
