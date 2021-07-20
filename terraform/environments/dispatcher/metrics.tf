module "wavefront" {
  source = "../../dependencies/wavefront"

  prefix   = "concourse"
  hostname = "dispatcher.concourse-ci.org"
  token    = "foo"

  depends_on = [
    module.cluster.node_pools,
  ]
}

module "cluster-metrics" {
  source           = "../../dependencies/cluster-metrics"
  hostname         = "dispatcher.concourse-ci.org"
  metrics_endpoint = module.wavefront.metrics_endpoint

  depends_on = [
    module.cluster.node_pools,
  ]
}
