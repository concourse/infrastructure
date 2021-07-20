output "tracing_endpoint" {
  value = "metrics.${kubernetes_namespace.main.id}.svc.cluster.local:14250"
}

output "metrics_endpoint" {
  value = "tracing.${kubernetes_namespace.main.id}.svc.cluster.local:9000/receive"
}

