module "ci_dashboard" {
  source = "../dashboardpromtelegraf"

  datadog_api_key = var.datadog_provider_api_key
  datadog_app_key = var.datadog_provider_app_key

  dashboard_title = "Concourse - CI - Test"

  deployment_tool = "helm"

  concourse_datadog_prefix = "concourse.ci"

  filter_by = {
    concourse_instance = "environment:ci-test"
    concourse_web      = "kube_deployment:ci-web"
    concourse_worker   = "kube_stateful_set:ci-worker"
  }
}
