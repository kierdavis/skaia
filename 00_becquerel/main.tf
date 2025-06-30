terraform {
  backend "local" {
    path = "/net/skaia/tfstate/skaia/00_becquerel.tfstate"
  }
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    linode = {
      source = "linode/linode"
    }
    remote = {
      source = "tenstad/remote"
    }
    time = {
      source = "hashicorp/time"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

locals {
  headscale_version = "0.23.0"
  headscale_sha256  = "d9193dad4b070b9b3f6d54c8f14366952944b6e917672c0bc1dfd8f5491287a7"

  globals = yamldecode(file("${path.module}/../globals.yaml"))

  headscale_config = {
    acme_email = var.lets_encrypt_email
    acme_url   = "https://acme-v02.api.letsencrypt.org/directory"
    database = {
      type   = "sqlite"
      sqlite = { path = "/var/lib/headscale/db.sqlite" }
    }
    derp = {
      server = { private_key_path = "/var/lib/headscale/private.key" }
      urls   = ["https://controlplane.tailscale.com/derpmap/default"]
    }
    disable_check_updates = true
    dns = {
      base_domain = "tail.skaia.cloud"
      magic_dns   = true
      nameservers = {
        global = ["1.1.1.1", "1.0.0.1"]
      }
    }
    listen_addr = "0.0.0.0:443"
    noise       = { private_key_path = "/var/lib/headscale/noise.key" }
    policy = {
      mode = "file"
      path = "/etc/headscale/acls.json"
    }
    prefixes = {
      v4 = local.globals.headscale.net.ipv4
      v6 = local.globals.headscale.net.ipv6
    }
    server_url                     = "https://headscale.skaia.cloud/"
    tls_letsencrypt_cache_dir      = "/var/lib/headscale/acme"
    tls_letsencrypt_challenge_type = "TLS-ALPN-01"
    tls_letsencrypt_hostname       = "headscale.skaia.cloud"
  }

  headscale_acls = {
    groups = {
      "group:system" = ["skaia"]
      "group:admins" = ["kier"]
      # Not sure if this is a headscale bug, but using a username in the
      # src/dst of an ACL doesn't seem to have any effect. Need to create
      # a group.
      "group:kier" = ["kier"]
    }
    acls = [
      # Allow communications within the cluster, and allow group:admins to connect to anything in the cluster.
      {
        action = "accept"
        src = [
          "group:system",
          "group:admins",
          local.globals.kubernetes.pod_net.ipv4,
          local.globals.kubernetes.pod_net.ipv6,
          local.globals.kubernetes.svc_net.ipv4,
          local.globals.kubernetes.svc_net.ipv6,
        ]
        dst = [
          "group:system:*",
          "${local.globals.kubernetes.pod_net.ipv4}:*",
          "${local.globals.kubernetes.pod_net.ipv6}:*",
          "${local.globals.kubernetes.svc_net.ipv4}:*",
          "${local.globals.kubernetes.svc_net.ipv6}:*",
        ]
      },
      # Allow communications between users' personal devices.
      { action = "accept", src = ["group:kier"], dst = ["group:kier:*"] },
    ]
    autoApprovers = {
      routes = {
        "${local.globals.kubernetes.pod_net.ipv4}" = ["group:system"]
        "${local.globals.kubernetes.pod_net.ipv6}" = ["group:system"]
        "${local.globals.kubernetes.svc_net.ipv4}" = ["group:system"]
        "${local.globals.kubernetes.svc_net.ipv6}" = ["group:system"]
      }
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}

provider "linode" {
  token = var.linode_token
}

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "linode_instance" "main" {
  label      = "becquerel"
  region     = "gb-lon"
  type       = "g6-nanode-1"
  private_ip = false
}

resource "linode_stackscript" "main" {
  label       = "becquerel"
  description = "Configure becquerel"
  images      = ["linode/rocky9"]
  is_public   = false
  script      = <<-EOS
    #!/bin/bash
    set -o errexit -o nounset -o pipefail -o xtrace
    exec >/var/log/stackscript.log 2>&1

    hostnamectl hostname becquerel

    # There's a firewall at the Linode layer.
    systemctl stop firewalld
    systemctl disable firewalld

    mkdir -p /persistent
    echo /dev/sdc /persistent ext4 defaults 0 2 >> /etc/fstab
    systemctl daemon-reload
    mount /persistent

    mkdir -p /persistent/ssh
    for x in ssh_host_{ecdsa,ed25519,rsa}_key; do
      if [[ ! -e /persistent/ssh/$x ]]; then
        mv /etc/ssh/$x /persistent/ssh/$x
      fi
      rm -f /etc/ssh/$x
      ln -sfT /persistent/ssh/$x /etc/ssh/$x
      chmod 0600 /persistent/ssh/$x /etc/ssh/$x
      ssh-keygen -y -f /etc/ssh/$x > /etc/ssh/$x.pub
    done
    systemctl restart sshd

    mkdir -p /persistent/headscale
    ln -sfT /persistent/headscale /var/lib/headscale
    useradd --create-home --home-dir /var/lib/headscale/ --system --user-group --shell /usr/sbin/nologin headscale
    chown -R headscale:headscale /var/lib/headscale/

    pushd /bin
    curl --silent --show-error --fail --location \
      --output headscale \
      https://github.com/juanfont/headscale/releases/download/v${local.headscale_version}/headscale_${local.headscale_version}_linux_amd64
    sha256sum --check <<<"${local.headscale_sha256}  headscale"
    chmod +x headscale
    popd

    mkdir -p /var/run/headscale
    chown headscale:headscale /var/run/headscale

    mkdir -p /etc/headscale
    base64 -d >/etc/headscale/config.yaml <<<"${base64encode(yamlencode(local.headscale_config))}"
    base64 -d >${local.headscale_config.policy.path} <<<"${base64encode(jsonencode(local.headscale_acls))}"

    cat >/etc/systemd/system/headscale.service <<EOF
    [Unit]
    Description=Headscale
    After=network-online.target
    Requires=network-online.target
    [Service]
    Type=exec
    ExecStart=/bin/headscale serve
    User=headscale
    Group=headscale
    Restart=always
    RestartSec=2
    NoNewPrivileges=yes
    PrivateTmp=yes
    ProtectSystem=strict
    ProtectHome=yes
    WorkingDirectory=/var/lib/headscale
    ReadWritePaths=/var/lib/headscale /var/run/headscale
    AmbientCapabilities=CAP_NET_BIND_SERVICE
    RuntimeDirectory=headscale
    TimeoutStopSec=5
    [Install]
    WantedBy=multi-user.target
    EOF
    systemctl daemon-reload
    systemctl enable headscale.service
    systemctl start headscale.service
    sleep 2

    useradd --create-home --system --user-group terraform
    mkdir -p /home/terraform/.ssh
    echo '${trimspace(tls_private_key.ssh.public_key_openssh)}' > /home/terraform/.ssh/authorized_keys
    chown -R terraform:terraform /home/terraform

    if [[ ! -e /persistent/terraform_api_key ]]; then
      headscale apikeys create --expiration 100y > /persistent/terraform_api_key
    fi
    chown root:terraform /persistent/terraform_api_key
    chmod 0640 /persistent/terraform_api_key

    echo ok
  EOS
}

locals {
  # All in MiB
  total_size      = linode_instance.main.specs[0].disk
  os_size         = 10 * 1024
  swap_size       = 1024
  persistent_size = local.total_size - local.os_size - local.swap_size
}

resource "linode_instance_disk" "os" {
  label           = "os"
  linode_id       = linode_instance.main.id
  size            = local.os_size
  image           = "linode/rocky9"
  stackscript_id  = linode_stackscript.main.id
  authorized_keys = var.authorized_ssh_public_keys
  lifecycle {
    replace_triggered_by = [linode_stackscript.main.script]
  }
}

resource "linode_instance_disk" "swap" {
  label      = "swap"
  linode_id  = linode_instance.main.id
  size       = local.swap_size
  filesystem = "swap"
}

resource "linode_instance_disk" "persistent" {
  label      = "persistent"
  linode_id  = linode_instance.main.id
  size       = local.persistent_size
  filesystem = "ext4"
}

resource "linode_instance_config" "main" {
  label       = "main"
  linode_id   = linode_instance.main.id
  root_device = "/dev/sda"
  booted      = true
  device {
    device_name = "sda"
    disk_id     = linode_instance_disk.os.id
  }
  device {
    device_name = "sdb"
    disk_id     = linode_instance_disk.swap.id
  }
  device {
    device_name = "sdc"
    disk_id     = linode_instance_disk.persistent.id
  }
}

resource "linode_firewall" "main" {
  label           = "becquerel"
  linodes         = [linode_instance.main.id]
  disabled        = false
  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"
  inbound {
    label    = "ping"
    action   = "ACCEPT"
    protocol = "ICMP"
    ipv4     = toset(["0.0.0.0/0"])
    ipv6     = toset(["::0/0"])
  }
  inbound {
    label    = "ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = var.authorized_ssh_ipv4_nets
    ipv6     = var.authorized_ssh_ipv6_nets
  }
  inbound {
    label    = "headscale"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = toset(["0.0.0.0/0"])
    ipv6     = toset(["::0/0"])
  }
}

resource "cloudflare_record" "main" {
  zone_id = var.cloudflare_zone_id
  name    = "becquerel"
  type    = "A"
  value   = linode_instance.main.ip_address
  proxied = false
}

resource "cloudflare_record" "headscale" {
  zone_id = var.cloudflare_zone_id
  name    = "headscale"
  type    = "CNAME"
  value   = "${cloudflare_record.main.name}.skaia.cloud"
  proxied = false
}

resource "time_sleep" "boot" {
  create_duration = "30s"
  lifecycle {
    replace_triggered_by = [linode_instance_config.main]
  }
}

data "remote_file" "api_key" {
  path = "/persistent/terraform_api_key"
  conn {
    host        = linode_instance.main.ip_address
    user        = "terraform"
    private_key = tls_private_key.ssh.private_key_openssh
    timeout     = 3000 # ms
  }
  depends_on = [time_sleep.boot]
}

output "headscale" {
  value = {
    endpoint = "https://${cloudflare_record.headscale.name}.skaia.cloud/"
    api_key  = trimspace(sensitive(data.remote_file.api_key.content))
  }
  sensitive = true
}
