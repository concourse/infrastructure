# Creates Datadog dashboards for CI and Hush House.
#

module "ci_dashboard" {
  source = "../dashboard"

  datadog_api_key = var.datadog_provider_api_key
  datadog_app_key = var.datadog_provider_app_key

  dashboard_title = "Concourse - CI"

  deployment_tool = "helm"

  concourse_datadog_prefix = "concourse.ci"

  filter_by = {
    concourse_instance = "environment:ci"
    concourse_web      = "kube_deployment:ci-web"
    concourse_worker   = "kube_stateful_set:ci-worker"
  }
}

module "hush_house_dashboard" {
  source = "../dashboard"

  datadog_api_key = var.datadog_provider_api_key
  datadog_app_key = var.datadog_provider_app_key

  dashboard_title = "Concourse - Hush House"

  deployment_tool = "helm"

  concourse_datadog_prefix = "concourse.ci"

  filter_by = {
    concourse_instance = "environment:hush-house"
    concourse_web      = "kube_deployment:hush-house-web"
    concourse_worker   = "kube_stateful_set:workers-worker"
  }
}
