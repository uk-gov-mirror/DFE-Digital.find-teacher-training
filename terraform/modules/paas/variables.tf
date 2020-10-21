variable cf_api_url {}

variable cf_user {}

variable cf_user_password {}

variable cf_sso_passcode {}

variable app_environment {}

variable app_docker_image {}

variable web_app_instances { default = 1 }

variable web_app_memory { default = 512 }

variable logstash_url {}

variable app_environment_variables { type = map }

locals {
  web_app_name          = "find-${var.app_environment}"
  web_app_start_command = "bundle exec rails server -b 0.0.0.0"
  logging_service_name  = "find-logit-${var.app_environment}"
  service_gov_uk_host_names = {
    qa      = "qa"
    staging = "staging"
    prod    = "www2"
  }
  web_app_routes = [cloudfoundry_route.web_app_service_gov_uk_route.id,
  cloudfoundry_route.web_app_cloudapps_digital_route.id]
}
