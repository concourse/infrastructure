#####################################################
# DASHBOARDS - SYSTEM STATS - HELM
#####################################################

resource "datadog_dashboard" "concourse_systemstats" {
  count        = var.deployment_tool == "helm" ? 1 : 0
  is_read_only = false
  layout_type  = "ordered"
  notify_list  = []
  title        = "${var.dashboard_title} - System Stats"

  template_variable {
    default = local.environment_label_value
    name    = "environment"
    prefix  = local.environment_label_key
  }
  template_variable {
    default = local.web_label_value
    name    = "web"
    prefix  = local.web_label_key
  }
  template_variable {
    default = local.worker_label_value
    name    = "worker"
    prefix  = local.worker_label_key
  }

  widget {

    group_definition {
      layout_type = "ordered"
      title       = "System Stats"

      widget {

        timeseries_definition {
          show_legend = false
          title       = "Web CPU Usage"

          request {
            display_type = "line"
            q            = "avg:docker.cpu.user{$web} by {pod_name}"

            style {
              line_type  = "solid"
              line_width = "normal"
              palette    = "cool"
            }
          }
          request {
            display_type = "line"
            q            = "avg:docker.cpu.system{$web} by {pod_name}"

            style {
              line_type  = "solid"
              line_width = "normal"
              palette    = "warm"
            }
          }

          yaxis {
            include_zero = true
            max          = "auto"
            min          = "auto"
            scale        = "linear"
          }
        }
      }
      widget {

        timeseries_definition {
          show_legend = false
          title       = "Web Memory Usage"

          request {
            display_type = "line"
            q            = "avg:docker.mem.rss{$web} by {pod_name}"

            style {
              line_type  = "solid"
              line_width = "normal"
              palette    = "cool"
            }
          }
          request {
            display_type = "line"
            q            = "avg:docker.mem.swap{$web} by {pod_name}"

            metadata {
              alias_name = "swap"
              expression = "avg:docker.mem.swap{$web} by {pod_name}"
            }

            style {
              line_type  = "solid"
              line_width = "normal"
              palette    = "warm"
            }
          }
          request {
            display_type = "line"
            q            = "avg:docker.mem.limit{$web} by {pod_name}"

            metadata {
              alias_name = "total"
              expression = "avg:docker.mem.limit{$web} by {pod_name}"
            }

            style {
              line_type  = "dotted"
              line_width = "normal"
              palette    = "warm"
            }
          }

          yaxis {
            include_zero = true
            max          = "auto"
            min          = "auto"
            scale        = "linear"
          }
        }
      }
      widget {

        timeseries_definition {
          show_legend = false
          title       = "Worker CPU Usage"

          request {
            display_type = "line"
            q            = "avg:docker.cpu.user{$worker} by {pod_name}"

            style {
              line_type  = "solid"
              line_width = "normal"
              palette    = "cool"
            }
          }
          request {
            display_type = "line"
            q            = "avg:docker.cpu.system{$worker} by {pod_name}"

            style {
              line_type  = "solid"
              line_width = "normal"
              palette    = "warm"
            }
          }

          yaxis {
            include_zero = true
            max          = "auto"
            min          = "auto"
            scale        = "linear"
          }
        }
      }
      widget {

        timeseries_definition {
          show_legend = false
          title       = "Worker Memory Usage"

          request {
            display_type = "line"
            q            = "avg:docker.mem.rss{$worker} by {pod_name}"

            style {
              line_type  = "solid"
              line_width = "normal"
              palette    = "cool"
            }
          }
          request {
            display_type = "line"
            q            = "avg:docker.mem.limit{$worker} by {pod_name}"

            metadata {
              alias_name = "total"
              expression = "avg:docker.mem.limit{$worker} by {pod_name}"
            }

            style {
              line_type  = "dotted"
              line_width = "normal"
              palette    = "warm"
            }
          }

          yaxis {
            include_zero = true
            max          = "auto"
            min          = "auto"
            scale        = "linear"
          }
        }
      }
      widget {

        timeseries_definition {
          show_legend = false
          title       = "Web Network In"

          request {
            display_type = "line"
            q            = "avg:docker.net.bytes_rcvd{$web} by {pod_name}"

            style {
              line_type  = "solid"
              line_width = "normal"
              palette    = "dog_classic"
            }
          }

          yaxis {
            include_zero = true
            max          = "auto"
            min          = "auto"
            scale        = "linear"
          }
        }
      }
      widget {

        timeseries_definition {
          show_legend = false
          title       = "Web Network Out"

          request {
            display_type = "line"
            q            = "avg:docker.net.bytes_sent{$web} by {pod_name}"

            style {
              line_type  = "solid"
              line_width = "normal"
              palette    = "dog_classic"
            }
          }

          yaxis {
            include_zero = true
            max          = "auto"
            min          = "auto"
            scale        = "linear"
          }
        }
      }
      widget {

        timeseries_definition {
          show_legend = false
          title       = "Load"

          marker {
            display_type = "error dashed"
            value        = "y > 100"
          }

          request {
            display_type = "line"
            q            = "avg:system.load.1{goog-gke-node} by {host}"

            style {
              line_type  = "solid"
              line_width = "normal"
              palette    = "dog_classic"
            }
          }

          yaxis {
            include_zero = true
            max          = "auto"
            min          = "auto"
            scale        = "linear"
          }
        }
      }
    }
  }
}