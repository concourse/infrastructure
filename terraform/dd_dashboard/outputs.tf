#################################
# OUTPUTS
#################################

output "ci_dashboard_url" {
  value = module.ci_dashboard.url
}

output "ci_dashboard_system_stats_url" {
  value = module.ci_dashboard.system_stats_url
}

output "hh_dashboard_url" {
  value = module.hush_house_dashboard.url
}

output "hh_dashboard_system_stats_url" {
  value = module.hush_house_dashboard.system_stats_url
}
