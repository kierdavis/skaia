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
      csiCephFSPluginResource = yamlencode([
        {
          name = "csi-cephfsplugin"
          resource = {
            requests = { cpu = "1m", memory = "70Mi" }
            limits   = { memory = "200Mi" }
          }
        },
        {
          name = "driver-registrar"
          resource = {
            requests = { cpu = "1m", memory = "8Mi" }
            limits   = { memory = "50Mi" }
          }
        },
      ])
      csiCephFSProvisionerResource = yamlencode([
        {
          name = "csi-addons"
          resource = {
            requests = { cpu = "1m", memory = "15Mi" }
            limits   = { memory = "50Mi" }
          }
        },
        {
          name = "csi-attacher"
          resource = {
            requests = { cpu = "1m", memory = "15Mi" }
            limits   = { memory = "50Mi" }
          }
        },
        {
          name = "csi-cephfsplugin"
          resource = {
            requests = { cpu = "1m", memory = "20Mi" }
            limits   = { memory = "50Mi" }
          }
        },
        {
          name = "csi-provisioner"
          resource = {
            requests = { cpu = "1m", memory = "15Mi" }
            limits   = { memory = "50Mi" }
          }
        },
        {
          name = "csi-resizer"
          resource = {
            requests = { cpu = "1m", memory = "15Mi" }
            limits   = { memory = "50Mi" }
          }
        },
        {
          name = "csi-snapshotter"
          resource = {
            requests = { cpu = "3m", memory = "15Mi" }
            limits   = { memory = "50Mi" }
          }
        },
      ])
      csiRBDPluginResource = yamlencode([
        {
          name = "csi-addons"
          resource = {
            requests = { cpu = "1m", memory = "10Mi" }
            limits   = { memory = "50Mi" }
          }
        },
        {
          name = "csi-rbdplugin"
          resource = {
            requests = { cpu = "1m", memory = "60Mi" }
            limits   = { memory = "200Mi" }
          }
        },
        {
          name = "driver-registrar"
          resource = {
            requests = { cpu = "1m", memory = "8Mi" }
            limits   = { memory = "50Mi" }
          }
        },
      ])
      csiRBDProvisionerResource = yamlencode([
        {
          name = "csi-addons"
          resource = {
            requests = { cpu = "1m", memory = "15Mi" }
            limits   = { memory = "50Mi" }
          }
        },
        {
          name = "csi-attacher"
          resource = {
            requests = { cpu = "1m", memory = "15Mi" }
            limits   = { memory = "50Mi" }
          }
        },
        {
          name = "csi-provisioner"
          resource = {
            requests = { cpu = "1m", memory = "15Mi" }
            limits   = { memory = "50Mi" }
          }
        },
        {
          name = "csi-resizer"
          resource = {
            requests = { cpu = "1m", memory = "15Mi" }
            limits   = { memory = "50Mi" }
          }
        },
        {
          name = "csi-rbdplugin"
          resource = {
            requests = { cpu = "1m", memory = "50Mi" }
            limits   = { memory = "100Mi" }
          }
        },
        {
          name = "csi-snapshotter"
          resource = {
            requests = { cpu = "3m", memory = "15Mi" }
            limits   = { memory = "50Mi" }
          }
        },
      ])
    }
    monitoring = {
      enabled = true
    }
    resources = {
      requests = { cpu = "150m", memory = "100Mi" }
      limits   = { memory = "300Mi" }
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
  rook_image = data.kubernetes_resource.operator_deployment.object.spec.template.spec.containers[0].image
}
