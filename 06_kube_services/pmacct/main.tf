terraform {
  required_providers {
    postgresql = {
      source = "cyrilgdn/postgresql"
    }
  }
}

resource "postgresql_role" "dev" {
  bypass_row_level_security = false
  create_database           = false
  create_role               = false
  encrypted_password        = true
  inherit                   = true
  login                     = true
  name                      = "pmacct-dev"
  password                  = sensitive("REDACTED")
  replication               = false
  superuser                 = false
}

resource "postgresql_database" "dev" {
  allow_connections = true
  encoding          = "UTF8"
  is_template       = false
  lc_collate        = "C"
  lc_ctype          = "C"
  name              = "pmacct-dev"
  owner             = postgresql_role.dev.name
}

#terraform {
#  required_providers {
#    http = {
#      source = "hashicorp/http"
#    }
#    kubernetes = {
#      source = "hashicorp/kubernetes"
#    }
#    postgresql = {
#      source = "cyrilgdn/postgresql"
#    }
#  }
#}
#
#resource "postgresql_role" "main" {
#  bypass_row_level_security = false
#  create_database = false
#  create_role = false
#  encrypted_password = true
#  inherit = true
#  login = true
#  name = "pmacct"
#  password = sensitive("REDACTED")
#  replication = false
#  superuser = false
#}
#
#resource "postgresql_database" "main" {
#  allow_connections = true
#  encoding = "UTF8"
#  is_template = false
#  lc_collate = "C"
#  lc_ctype = "C"
#  name = "pmacct"
#  owner = postgresql_role.main.name
#}
#
#locals {
#  psql = <<-EOF
#    exec kubectl run \
#      --attach \
#      --command \
#      --env=PGPASSWORD="$password" \
#      --image=docker.io/library/postgres@sha256:b45d9c4af324e6aedb8efd6ca988f954ec34df6bc942a3dacd26b1a4d5db9fea \
#      --namespace=system \
#      --restart=Never \
#      --rm \
#      --stdin \
#      pmacct-psql \
#      -- \
#      psql \
#      --host=postgresql.system.svc.kube.skaia.cloud \
#      --username="$username" \
#      "$database" \
#      <<<"$script"
#  EOF
#  recreate_acct_table_script = file("recreate-acct-table.sql")
#  recreate_tag_table_script = file("recreate-tag-table.sql")
#}
#
#resource "terraform_data" "acct_table" {
#  provisioner "local-exec" {
#    command = local.psql
#    environment = {
#      username = postgresql_role.main.name
#      password = nonsensitive(postgresql_role.main.password)
#      database = postgresql_database.main.name
#      script = local.recreate_acct_table_script
#    }
#  }
#}
#
#resource "terraform_data" "tag_table" {
#  triggers_replace = local.recreate_tag_table_script
#  provisioner "local-exec" {
#    command = local.psql
#    environment = {
#      username = postgresql_role.main.name
#      password = nonsensitive(postgresql_role.main.password)
#      database = postgresql_database.main.name
#      sql_script = local.recreate_tag_table_script
#    }
#  }
#}
#
#resource "kubernetes_secret" "config" {
#  metadata {
#    name = "pmacctd"
#    namespace = "system"
#    labels    = { "app.kubernetes.io/name" = "pmacctd" }
#  }
#  data = {
#    "pmacctd.conf" = <<-EOF
#      aggregate: src_mac,dst_mac,vlan,src_host,dst_host,proto,src_port,dst_port
#      aggregate_unknown_etype: true
#      daemonize: false
#      pcap_interface: tailscale0
#      plugin_exit_any: true
#      plugins: pgsql
#      propagate_signals: true
#      sql_db: ${postgresql_database.main.name}
#      sql_history: 1m
#      sql_history_roundoff: m
#      sql_host: postgresql.system.svc.kube.skaia.cloud
#      sql_locking_style: row
#      sql_num_protos: true
#      sql_optimize_clauses: true
#      sql_passwd: ${postgresql_role.main.password}
#      sql_refresh_time: 1m
#      sql_table: acct
#      sql_user: ${postgresql_role.main.name}
#      timestamps_rfc3339: true
#    EOF
#  }
#}
#
#resource "kubernetes_daemonset" "main" {
#  depends_on = [terraform_data.tables]
#  wait_for_rollout = false
#  metadata {
#    name      = "pmacctd"
#    namespace = "system"
#    labels    = { "app.kubernetes.io/name" = "pmacctd" }
#  }
#  spec {
#    strategy {
#      type = "RollingUpdate"
#      rolling_update {
#        max_unavailable = "100%"
#      }
#    }
#    selector {
#      match_labels = { "app.kubernetes.io/name" = "pmacctd" }
#    }
#    template {
#      metadata {
#        labels = { "app.kubernetes.io/name" = "pmacctd" }
#        annotations = {
#          "config-hash" = nonsensitive(md5(kubernetes_secret.config.data["pmacctd.conf"]))
#        }
#      }
#      spec {
#        automount_service_account_token  = false
#        dns_policy           = "ClusterFirstWithHostNet"
#        enable_service_links             = false
#        host_network = true
#        restart_policy                   = "Always"
#        termination_grace_period_seconds = 10
#        toleration {
#          effect   = "NoExecute"
#          operator = "Exists"
#        }
#        toleration {
#          effect   = "NoSchedule"
#          operator = "Exists"
#        }
#        volume {
#          name = "config"
#          secret {
#            secret_name = kubernetes_secret.config.metadata[0].name
#          }
#        }
#        container {
#          name  = "main"
#          image = "docker.io/pmacct/pmacctd@sha256:b91625f21574338f69bcfd1e8c607db11eb831bdc446d832cf8f3d933ff06dda"
#          args = ["-f", "/config/pmacctd.conf"]
#          volume_mount {
#            name = "config"
#            mount_path = "/config"
#            read_only = true
#          }
#        }
#      }
#    }
#  }
#}
