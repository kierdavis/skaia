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
              ttl 30
          }
          forward . /etc/resolv.conf {
             max_concurrent 1000
          }
          cache 30 {
             disable success kube.skaia.cloud
             disable denial kube.skaia.cloud
          }
          loop
          reload
          loadbalance
      }
    EOT
  }
}
