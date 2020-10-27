module "ci_dashboard" {
  source = "./dashboard"

  datadog_api_key = "your datadog api key"
  datadog_app_key = "your datadog app key"

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
  source = "./dashboard"

  datadog_api_key = "your datadog api key"
  datadog_app_key = "your datadog app key"

  dashboard_title = "Concourse - Hush House"

  deployment_tool = "helm"

  concourse_datadog_prefix = "concourse.ci"

  filter_by = {
    concourse_instance = "environment:hush-house"
    concourse_web      = "kube_deployment:hush-house-web"
    concourse_worker   = "kube_stateful_set:workers-worker"
  }
}

module "ci_bosh_dashboard" {
  source = "./dashboard"

  datadog_api_key = "your datadog api key"
  datadog_app_key = "your datadog app key"

  dashboard_title = "Concourse - CI - BOSH"

  deployment_tool = "bosh"

  concourse_datadog_prefix = "concourse.ci"

  filter_by = {
    concourse_instance = "bosh-deployment:concourse-algorithm"
    concourse_web      = "bosh_job:web"
    concourse_worker   = "bosh_job:worker"
  }
}

module "containerd_drills_dashboard" {
  source = "../dashboard"

  datadog_api_key = ""
  datadog_app_key = ""

  dashboard_title = "Concourse - Containerd Drills"

  deployment_tool = "helm"

  concourse_datadog_prefix = "concourse.containerd_drills"

  filter_by = {
    concourse_instance = "environment:containerd_drills"
    concourse_web      = "kube_deployment:containerd-drills-web"
    concourse_worker   = "kube_stateful_set:containerd-drills-worker"
  }
} 

module "guardian_drills_dashboard" {
  source = "../dashboard"

  datadog_api_key = ""
  datadog_app_key = ""

  dashboard_title = "Concourse - Guardian Drills"

  deployment_tool = "helm"

  concourse_datadog_prefix = "concourse.guardian_drills"

  filter_by = {
    concourse_instance = "environment:guardian_drills"
    concourse_web      = "kube_deployment:guardian-drills-web"
    concourse_worker   = "kube_stateful_set:guardian-drills-worker"
  }
} 