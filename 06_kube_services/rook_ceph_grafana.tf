# This resource depends on the grafana provider, which depends on
# module.prometheus, so this resource can't live in the prometheus module.
# module.prometheus itself depends on module.rook_ceph, so this resource
# can't live in module.rook_ceph either.

locals {
  ceph_dashboard_grafana_username = "ceph-dashboard"
}

# The ceph dashboard is only capable of authenticating to the grafana API
# using basic auth, not token auth, so we have to use a grafana_user here,
# not a grafana_service_account.
resource "grafana_user" "ceph_dashboard" {
  # Completely bogus email address - it's just a user ID.
  email    = "ceph@uid.skaia.cloud"
  password = var.ceph_dashboard_grafana_password
  is_admin = false
  login    = local.ceph_dashboard_grafana_username
  name     = "ceph dashboard"
}
