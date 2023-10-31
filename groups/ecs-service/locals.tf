# Define all hardcoded local variable and local variables looked up from data resources
locals {
  stack_name                = "developer-site" # this must match the stack name the service deploys into
  name_prefix               = "${local.stack_name}-${var.environment}"
  service_name              = "applications-developer"
  container_port            = "3000" # default node port required here until prod docker container is built allowing port change via env var
  docker_repo               = "applications.developer.web.ch.gov.uk"
  lb_listener_rule_priority = 5
  lb_listener_paths         = ["/manage-applications*"]
  healthcheck_path          = "/manage-applications"
  healthcheck_matcher       = "302" # no explicit healthcheck in this service yet, change this when added!
  application_subnet_ids    = data.aws_subnets.application.ids

  stack_secrets              = jsondecode(data.vault_generic_secret.secrets.data_json)
  application_subnet_pattern = local.stack_secrets["application_subnet_pattern"]
  
  vpc_name = data.aws_ssm_parameter.secret[format("/%s/%s", local.name_prefix, "vpc-name")].value

  # create a map of secret name => secret arn to pass into ecs service module
  # using the trimprefix function to remove the prefixed path from the secret name
  secrets_arn_map = {
    for sec in data.aws_ssm_parameter.secret :
    trimprefix(sec.name, "/${local.name_prefix}/") => sec.arn
  }

  task_secrets = [
    { "name" : "CHS_DEVELOPER_CLIENT_ID", "valueFrom" : local.secrets_arn_map.web-oauth2-client-id },
    { "name" : "CHS_DEVELOPER_CLIENT_SECRET", "valueFrom" : local.secrets_arn_map.web-oauth2-client-secret },
    { "name" : "COOKIE_SECRET", "valueFrom" : local.secrets_arn_map.web-oauth2-cookie-secret },
    { "name" : "DEVELOPER_OAUTH2_REQUEST_KEY", "valueFrom" : local.secrets_arn_map.web-oauth2-request-key }
  ]

  task_environment = [
    { "name" : "NODE_PORT", "value" : local.container_port },
    { "name" : "LOGLEVEL", "value" : var.log_level },
    { "name" : "CDN_HOST", "value" : "//${var.cdn_host}" },
    { "name" : "CDN_URL_CSS", "value" : "https://${var.cdn_host}/stylesheets/services/applications-developer" },
    { "name" : "CDN_URL_JS", "value" : "https://${var.cdn_host}/javascripts/app/applications-developer" },
    { "name" : "CHS_URL", "value" : var.chs_url },
    { "name" : "ACCOUNT_LOCAL_URL", "value" : var.account_local_url },
    { "name" : "DEVELOPER_SPECS_URL", "value" : var.dev_specs_url },
    { "name" : "PIWIK_URL", "value" : var.piwik_url },
    { "name" : "PIWIK_SITE_ID", "value" : var.piwik_site_id },
    { "name" : "REDIRECT_URI", "value" : var.redirect_uri },
    { "name" : "CACHE_POOL_SIZE", "value" : var.cache_pool_size },
    { "name" : "CACHE_SERVER", "value" : var.cache_server },
    { "name" : "COOKIE_DOMAIN", "value" : var.cookie_domain },
    { "name" : "COOKIE_NAME", "value" : var.cookie_name },
    { "name" : "COOKIE_SECURE_ONLY", "value" : var.cookie_secure_only },
    { "name" : "DEFAULT_SESSION_EXPIRATION", "value" : var.default_session_expiration },
    { "name" : "OAUTH2_REDIRECT_URI", "value" : var.oauth2_redirect_uri },
    { "name" : "OAUTH2_AUTH_URI", "value" : var.oauth2_auth_uri },
    { "name" : "APPLICATIONS_API_URL", "value" : var.account_local_url },
    { "name" : "APPLICATIONS_API_TEST_URL", "value" : var.account_test_url },
    { "name" : "APPLICATIONS_API_FUTURE_URL", "value" : var.account_future_url },
    { "name" : "DEV_HUB_URL", "value" : var.dev_site_url },
    { "name" : "NODE_HOSTNAME", "value" : var.dev_site_hostname }
  ]
}
