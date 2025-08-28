# Placed at the top level rather than in the cloudflared module,
# so that the entire cloudflared module isn't forced to depend on
# the entire prometheus module.
resource "kubectl_manifest" "cloudflared_pod_monitor" {
  depends_on = [module.prometheus]
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PodMonitor"
    metadata = {
      name      = "cloudflared"
      namespace = "system"
      labels    = { "app.kubernetes.io/name" = "cloudflared" }
    }
    spec = {
      selector = {
        matchLabels = { "app.kubernetes.io/name" = "cloudflared" }
      }
      podMetricsEndpoints = [{
        port   = "metrics"
        scheme = "http"
      }]
    }
  })
}
