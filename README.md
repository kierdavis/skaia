# skaia.cloud

This repo contains the configuration for my home Kubernetes cluster.

## Technology stack

* Kubernetes
* OS: [Talos Linux][talos] (a Linux distro designed solely for running Kubernetes)
  * Notably, Talos offers no shell/SSH access; instead all configuration and observation is done through a REST API.
* Servers: Intel NUCs, Linode compute instances.
* Networking: [tailscale][] (node agent), [headscale][] (control server), [code to glue this into Kubernetes CNI][cni-images].
* Ingress: [Cloudflare Tunnel][cloudflare-tunnel]
* Storage: [rook-ceph][], Backblaze B2
* Cluster services: [prometheus][], [grafana][], [kube-network-policies][], [generic-device-plugin][], [csi-addons][]
* Applications: [jellyfin][], [multiplayer game servers][valheim], [paperless-ngx][], private git server, network filesystems, backups

## Design principles

### IaC / Reproducibility

I've designed it in such a way that any change can be executed by editing a source file in this repo and running `terraform apply`.
In fact the entire setup can be reproducibility brought up using Terraform (sans tasks like imaging bare-metal machines).

Some technologies (Kubernetes, Linode) easily lend themselves to this model; others have required some unconventional solutions such as:

* Linux OS config: [implemented as a shell script that gets run at first boot][becquerel-tf]. Altering the script causes `terraform apply` to re-create the machine from a pristine image and re-run the script.
  * Yeah, I should probably have used `cloud-init` here.
* Docker images: built and pushed via a Terraform provisioner whenever any source file is changed.
  * This has become a puddle of issues with binary reproducibility and limitations of existing tools, and led to me [writing a new image-building toolchain from scratch][stamp].
* Ceph configuration: this is traditionally done imperatively with CLI commands, so I wrapped it up in [an idempotent script][rook-ceph-imperative-config].

### Why [technology]? Wouldn't [different technology] be more efficient / secure / maintainable / cost-effective?

Yes, these are all qualities I strive for when building infrastructure in a professional capacity.

But, this is for my personal use alone. The only criteria are that it's secure _enough_ and that it's fun to work on.

[becquerel-tf]: ./00_becquerel/main.tf
[cloudflare-tunnel]: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/
[cni-images]: ./05_kube_essential/cni_images
[csi-addons]: https://github.com/csi-addons/kubernetes-csi-addons
[generic-device-plugin]: https://github.com/squat/generic-device-plugin
[grafana]: https://grafana.com/
[headscale]: https://headscale.net/
[jellyfin]: https://jellyfin.org/
[kube-network-policies]: https://github.com/kubernetes-sigs/kube-network-policies
[paperless-ngx]: https://paperless-ngx.com/
[prometheus]: https://prometheus.io/
[rook-ceph]: https://rook.io/
[rook-ceph-imperative-config]: ./06_kube_services/rook_ceph/imperative_config_image/crate
[stamp]: https://github.com/kierdavis/stamp
[tailscale]: https://tailscale.com/
[talos]: https://www.talos.dev/
[valheim]: ./07_personal/valheim
