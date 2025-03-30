resource "helm_release" "operator" {
  name       = "rook-ceph"
  chart      = "rook-ceph"
  repository = "https://charts.rook.io/release"
  version    = local.rook_version
  namespace  = local.namespace
  values = [yamlencode({
    csi = {
      clusterName = "skaia"
      csiAddons   = { enabled = true }
      #enableGrpcMetrics = true
      #enableLiveness = true
      provisionerReplicas = 1
      serviceMonitor = {
        enabled = true
      }
    }
    monitoring = {
      enabled = true
    }
  })]
}

data "kubernetes_resource" "operator_deployment" {
  depends_on  = [helm_release.operator]
  api_version = "apps/v1"
  kind        = "Deployment"
  metadata {
    name      = "rook-ceph-operator"
    namespace = local.namespace
  }
}

locals {
  rook_image = "docker.io/${data.kubernetes_resource.operator_deployment.object.spec.template.spec.containers[0].image}"
}
