resource "aws_ecs_service" "applications-developer-ecs-service" {
  name            = "${var.environment}-${local.service_name}"
  cluster         = local.ecs_cluster_id
  task_definition = aws_ecs_task_definition.applications-developer-task-definition.arn
  desired_count   = var.desired_task_count
  load_balancer {
    target_group_arn = aws_lb_target_group.applications-developer-target_group.arn
    container_port   = local.applications_developer_port
    container_name   = "applications-developer"
  }
}

resource "aws_ecs_task_definition" "applications-developer-task-definition" {
  family                = "${var.environment}-${local.service_name}"
  execution_role_arn    = local.task_execution_role_arn
  container_definitions = templatefile(
    "${path.module}/${local.service_name}-task-definition.tmpl",
    merge( # pass in a map of variables required for the service's container definitions template merged with the secrets arn map
      {
        service_name               : local.service_name
        name_prefix                : local.name_prefix
        aws_region                 : var.aws_region
        docker_registry            : var.docker_registry
        required_cpus              : var.required_cpus
        required_memory            : var.required_memory

        # applications developer specific configs
        applications_developer_port    : local.applications_developer_port
        applications_developer_version : var.applications_developer_version
        log_level                      : var.log_level
        cdn_host                       : var.cdn_host
        chs_url                        : var.chs_url
        account_local_url              : var.account_local_url
        dev_specs_url                  : var.dev_specs_url
        piwik_url                      : var.piwik_url
        piwik_site_id                  : var.piwik_site_id
        redirect_uri                   : var.redirect_uri
        cache_pool_size                : var.cache_pool_size
        cache_server                   : var.cache_server
        cookie_domain                  : var.cookie_domain
        cookie_name                    : var.cookie_name
        cookie_secure_only             : var.cookie_secure_only
        default_session_expiration     : var.default_session_expiration
        oauth2_redirect_uri            : var.oauth2_redirect_uri
        oauth2_auth_uri                : var.oauth2_auth_uri
        account_test_url               : var.account_test_url
        account_future_url             : var.account_future_url
        dev_site_url                   : var.dev_site_url
        dev_site_hostname              : var.dev_site_hostname
      },
        local.secrets_arn_map
    )
  )
}

resource "aws_lb_target_group" "applications-developer-target_group" {
  name     = "${var.environment}-${local.service_name}"
  port     = local.applications_developer_port
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  health_check {
    healthy_threshold   = "5"
    unhealthy_threshold = "2"
    interval            = "30"
    matcher             = "302" # no explicit healthcheck in this service yet, change this when added!
    path                = "/manage-applications"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "5"
  }
}

resource "aws_lb_listener_rule" "applications-developer" {
  listener_arn = local.dev_site_lb_listener_arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.applications-developer-target_group.arn
  }
  condition {
    path_pattern {
      values = ["/manage-applications*"]
    }
  }
}
