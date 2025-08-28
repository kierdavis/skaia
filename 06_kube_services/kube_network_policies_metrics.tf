# Placed at the top level rather than in the kube_network_policies module,
# so that the entire kube_network_policies module isn't forced to depend on
# the entire prometheus module.
resource "kubectl_manifest" "kube_network_policies_service_monitor" {
  depends_on = [module.prometheus]
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "kube-network-policies"
      namespace = "system"
      labels    = { "app.kubernetes.io/name" = "kube-network-policies" }
    }
    spec = {
      selector = {
        matchLabels = { "app.kubernetes.io/name" = "kube-network-policies" }
      }
      endpoints = [{
        port   = "metrics"
        scheme = "http"
      }]
      namespaceSelector = {
        matchNames = ["system"]
      }
    }
  })
}
