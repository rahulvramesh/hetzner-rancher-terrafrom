
variable "hcloud_token" {
    default = "hRQHsu2smxOJbcL3JBPZLJVNPOywIdiX4XnZLog61xYO7PyBwNVrMo6KG6MTN3Nt"
}

provider "hcloud" {
  token = "${var.hcloud_token}"
}

resource "hcloud_ssh_key" "default" {
  name       = "main ssh key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}


resource "hcloud_server" "master_node" {
  name        = "master-rancher"
  image       = "ubuntu-18.04"
  server_type = "cx21"
  ssh_keys    = ["${hcloud_ssh_key.default.name}"]

  user_data     = <<EOT
#cloud-config
# vim: syntax=yaml
#

manage_etc_hosts: true
package_update: true
package_upgrade: true
package_reboot_if_required: true

locale: "en_US.UTF-8"
timezone: "Asia/Jakarta"

write_files:
    - path: "/etc/docker/daemon.json"
      owner: "root:root"
      content: |
        {
          "labels": [ "os=linux", "arch=arm64" ],
          "experimental": true
        }
runcmd:
  - [ systemctl, restart, avahi-daemon ]
  - [ systemctl, restart, docker ]
  - [docker, swarm, init ]
  - [
      docker, service, create,
      "--detach=false",
      "--name", "portainer",
      "--publish", "9000:9000",
      "--mount", "type=volume,src=portainer_data,dst=/data",
      "--mount", "type=bind,src=//var/run/docker.sock,dst=/var/run/docker.sock",
      "portainer/portainer", "-H", "unix:///var/run/docker.sock", "--no-auth"
    ]
  EOT
}

output "ipv4" {
  value = "${hcloud_server.master_node.ipv4_address}"
}
