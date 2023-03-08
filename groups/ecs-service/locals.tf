# Define all hardcoded local variable and local variables looked up from data resources
locals {
  stack_name                  = "developer-site" # this must match the stack name the service deploys into
  name_prefix                 = "${local.stack_name}-${var.environment}"
  service_name                = "applications-developer"
  applications_developer_port = "3000" #default node port required here until prod docker container is built allowing port change via env var

  vpc_id                    = data.terraform_remote_state.networks.outputs.vpc_id
  dev_site_lb_listener_arn  = data.aws_lb_listener.dev-site-lb-listener.arn
  ecs_cluster_id            = data.aws_ecs_cluster.ecs-cluster.id
  task_execution_role_arn   = data.aws_iam_role.ecs-cluster-iam-role.arn

  # create a map of secret name => secret arn to pass into ecs service module
  # using the trimprefix function to remove the prefixed path from the secret name
  secrets_arn_map = {
    for sec in data.aws_ssm_parameter.secret:
      trimprefix(sec.name, "/${local.name_prefix}/") => sec.arn
  }
}
