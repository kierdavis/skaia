terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

resource "kubernetes_config_map" "main" {
  metadata {
    name      = "coredns"
    namespace = "kube-system"
  }
  data = {
    Corefile = <<-EOT
      .:53 {
        errors
        health {
          lameduck 5s
        }
        ready
        log . {
          class error
        }
        prometheus :9153

        forward tail.skaia.cloud 100.100.100.100
        kubernetes kube.skaia.cloud in-addr.arpa ip6.arpa {
          pods insecure
          fallthrough in-addr.arpa ip6.arpa
        }
        forward . /etc/resolv.conf

        cache 30
        loop
        reload
        loadbalance
      }
    EOT
  }
}

#resource "kubernetes_deployment" "main" {
#  wait_for_rollout = false
#  metadata {
#    name      = "coredns"
#    namespace = "system"
#    labels    = { "app.kubernetes.io/name" = "coredns" }
#  }
#  spec {
#    replicas = 2
#    selector {
#      match_labels = { "app.kubernetes.io/name" = "coredns" }
#    }
#    template {
#      metadata {
#        labels = { "app.kubernetes.io/name" = "coredns" }
#        annotations = {
#          "confighash.skaia.cloud/config" = nonsensitive(md5(jsonencode(kubernetes_config_map.main.data)))
#        }
#      }
#      spec {
#        automount_service_account_token  = false
#        dns_policy = "ClusterFirst"
#        enable_service_links             = false
#        priority_class_name = "system-cluster-critical"
#        restart_policy                   = "Always"
#        termination_grace_period_seconds = 30
#        topology_spread_constraint {
#          max_skew = 1
#          topology_key = "topology.rook.io/chassis"
#          when_unsatisfiable = "ScheduleAnyway"
#          label_selector {
#            match_labels = { "app.kubernetes.io/name" = "coredns" }
#          }
#        }
#        container {
#          name  = "main"
#          image = "registry.k8s.io/coredns/coredns@sha256:2169b3b96af988cf69d7dd69efbcc59433eb027320eb185c6110e0850b997870" # v1.11.1 tag
#          args = ["-conf", "/etc/coredns/Corefile"]
#          volume_mount {
#            name = "config"
#            mount_path = "/etc/coredns"
#            read_only = true
#          }
#          port {
#            name = "dns-tcp"
#            container_port = 53
#            protocol = "TCP"
#          }
#          port {
#            name = "dns-udp"
#            container_port = 53
#            protocol = "UDP"
#          }
#          port {
#            name = "metrics"
#            container_port = 9153
#            protocol = "TCP"
#          }
#          security_context {
#            read_only_root_filesystem = true
#          #  capabilities {
#          #    add = ["NET_BIND_SERVICE"]
#          #    drop = ["ALL"]
#          #  }
#          }
#          liveness_probe {
#            http_get {
#              path = "/health"
#              port = 8080
#              scheme = "HTTP"
#            }
#            initial_delay_seconds = 60
#            period_seconds = 10
#            timeout_seconds = 5
#            success_threshold = 1
#            failure_threshold = 5
#          }
#          readiness_probe {
#            http_get {
#              path = "/ready"
#              port = 8181
#              scheme = "HTTP"
#            }
#            period_seconds = 10
#            timeout_seconds = 1
#            success_threshold = 1
#            failure_threshold = 3
#          }
#          resources {
#            requests = {
#              cpu = "100m"
#              memory = "70Mi"
#            }
#            limits = {
#              memory = "170Mi"
#            }
#          }
#        }
#        volume {
#          name = "config"
#          config_map {
#            name = kubernetes_config_map.main.metadata[0].name
#          }
#        }
#      }
#    }
#  }
#}
#
#resource "kubernetes_service" "main" {
#  metadata {
#    name      = "coredns"
#    namespace = "system"
#    labels    = { "app.kubernetes.io/name" = "coredns" }
#  }
#  spec {
#    selector = { "app.kubernetes.io/name" = "coredns" }
#    port {
#      name         = "dns-tcp"
#      port         = 53
#      protocol     = "TCP"
#      target_port  = "dns-tcp"
#    }
#    port {
#      name         = "dns-udp"
#      port         = 53
#      protocol     = "UDP"
#      target_port  = "dns-udp"
#    }
#  }
#}
#
#output "ip" {
#  value = kubernetes_service.main.spec[0].cluster_ip
#}
