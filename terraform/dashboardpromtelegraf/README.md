## Terraform Module for creating Datadog dashboards for a Concourse deployment

This module uses [Terraform Datadog provider](https://www.terraform.io/docs/providers/datadog/index.html) to interact with the `dashboard_resource` supported by Datadog. It creates two separate dashboards: 
1. A dashboard that displays a set of graphs/widgets to allow for observing how Concourse is behaving and performing.
1. A system statistics dashboard that displays metrics from the base system your Concourse is deployed on. It slightly varies depending on the tool used to deploy Concourse (either `bosh` or `helm`).

### Module Inputs

In order to create dashboards with this module, one or more variables should be set.

* `datadog_api_url`: *Optional.* Datadog API url. Default to the Datadog US api: https://api.datadoghq.com. _e.g._ https://api.datadoghq.eu 
* `datadog_api_key`: *Required.* Datadog API key.
* `datadog_app_key`: *Required.* Datadog APP key.
* `dashboard_title`: *Required.* Title of the dashboards.
* `concourse_datadog_prefix`: *Optional.* Set this variable in case your Concourse metrics were configured with a prefix. It corresponds to the value of the environment variable `CONCOURSE_DATADOG_PREFIX` (see default values for the [helm chart](https://github.com/concourse/concourse-chart/blob/884df7e220610ec6d47d1f23a04a6e674e50cd9b/values.yaml#L624) and the [bosh release](https://github.com/concourse/concourse-bosh-release/blob/63049535771972979e1e6c1912f6b599d043c0ac/jobs/web/spec#L1122)). _e.g._ "concourse.ci"
* `deployment_tool`: *Required.* Tool utilized to deploy Concourse (either `bosh` or `helm`).
* `filter_by`: *Required.* This variable is a map of strings which is expected to be set with three keys: 

    * `concourse_instance` - tag used to identify metrics that your Concourse instance emits. It corresponds to the value of the environment variable: `CONCOURSE_METRICS_ATTRIBUTE` (see default values for the [helm chart](https://github.com/concourse/concourse-chart/blob/884df7e220610ec6d47d1f23a04a6e674e50cd9b/values.yaml#L597) and the [bosh release](https://github.com/concourse/concourse-bosh-release/blob/428d67675f01748a6b3b96f9ffc1a2ef30d72c67/jobs/web/templates/bpm.yml.erb#L22). _e.g._ "environment:hush-house"
    * `concourse_web` - tag used to filter metrics collected from containers/vms in the Web deployment. See Datadog Agent documentation about [tagging](https://docs.datadoghq.com/agent/docker/?tab=standard#tagging) and Datadog [collector code](https://github.com/DataDog/datadog-agent/blob/d3ee653192284cf83004d4100907b6c0d818545c/pkg/tagger/collectors/kubelet_extract.go#L118) for clarification. _e.g._ kube_deployment:{DEPLOYMENT_NAME}-web.
    * `concourse_worker` - tag used to filter metrics collected from containers/vms in the Worker deployment. See Datadog Agent documentation about [tagging](https://docs.datadoghq.com/agent/docker/?tab=standard#tagging) and Datadog [collector code](https://github.com/DataDog/datadog-agent/blob/d3ee653192284cf83004d4100907b6c0d818545c/pkg/tagger/collectors/kubelet_extract.go#L124) for clarification. _e.g._ kube_stateful_set:{DEPLOYMENT_NAME}-worker.

        _P.S._ Refer to [examples/main.tf](./examples/main.tf) for an example on how to set those variables.

### Module Outputs

This module has two output variables:

* `url`: Url to access the dashboard for Concourse.
* `system_stats_url`: Url to access the system statistics dashboard for Concourse.

### Usage

Once the `dashboard` module is called from your Terraform root module as [our example](./examples/main.tf) illustrates, you can run the following commands to create the dashboards:

```shell script
terraform init
terraform apply
