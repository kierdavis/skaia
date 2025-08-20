data "http" "grafana_dashboard" {
  for_each = toset([
    "ceph-application-overview",
    "ceph-cluster-advanced",
    "ceph-cluster",
    "ceph-nvmeof-performance",
    "ceph-nvmeof",
    "cephfs-overview",
    "cephfsdashboard",
    "host-details",
    "hosts-overview",
    "multi-cluster-overview",
    "osd-device-details",
    "osds-overview",
    "pool-detail",
    "pool-overview",
    "radosgw-detail",
    "radosgw-overview",
    "radosgw-sync-overview",
    "rbd-details",
    "rbd-overview",
    "rgw-s3-analytics",
    "smb-overview",
  ])
  url = "https://raw.githubusercontent.com/ceph/ceph/refs/heads/main/monitoring/ceph-mixin/dashboards_out/${each.key}.json"
}

resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name      = "grafana-dashboards"
    namespace = local.namespace
    labels    = { "grafana_dashboard" = "1" }
  }
  # It's not sensitive, but there's no other way to hide the ridicuously large
  # and un-useful diff in `terraform plan` output.
  data = sensitive({
    for name, resp in data.http.grafana_dashboard :
    "rook-ceph-${name}.json" => resp.response_body
  })
}
