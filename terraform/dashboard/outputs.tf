#################################
# OUTPUTS
#################################

output "url" {
  description = "Url to access the dashboard for Concourse"
  value       = "${local.datadog_app_url}/dashboard/${datadog_dashboard.concourse.id}"
}

output "system_stats_url" {
  description = "Url to access the system statistics dashboard for Concourse"
  value       = var.deployment_tool == "helm" ? "${local.datadog_app_url}/dashboard/${datadog_dashboard.concourse_systemstats[0].id}" : "${local.datadog_app_url}/dashboard/${datadog_dashboard.concourse_systemstats_bosh[0].id}"
}

#################################
# LOCALS
#################################

locals {
  datadog_app_url = replace(var.datadog_api_url, "api", "app")
}