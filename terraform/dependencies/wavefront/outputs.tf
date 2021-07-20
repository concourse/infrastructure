output "tracing_endpoint" {
  value = "tracing.${kubernetes_namespace.main.id}:14250"
}

output "metrics_endpoint" {
  value = "metrics.${kubernetes_namespace.main.id}:9000/receive"
}

