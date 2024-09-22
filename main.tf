# Tell terraform to use the provider and select a version.
terraform {
    required_providers {
        hcloud = {
            source = "hetznercloud/hcloud"
            version = "~> 1.45"
        }
    }
}

# using the -var="hcloud_token=..." CLI option
variable "hcloud_token" {
    type = string
    sensitive = true
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
    token = var.hcloud_token
}

# Create a network
resource "hcloud_network" "nixos_network" {
    name = "NixOS-Network"
    ip_range = "10.0.0.0/16"
}

# Create a sub-network
resource "hcloud_network_subnet" "nixos_subnet" {
    type = "cloud"
    network_id = hcloud_network.nixos_network.id
    ip_range = "10.0.1.0/24"
    network_zone = "eu-central"
}

# Create NixOS Server
resource "hcloud_server" "nixos_server" {
    name        = "NixOS-Server"
    image       = "ubuntu-22.04"
    server_type = "cx11"
    location    = "fsn1"
    user_data = file("user_data.sh")

    labels = {
        "env" = "test"
        "os" = "nixos"
    }

    public_net {
        ipv4_enabled = true
        ipv6_enabled = true
    }

    network {
        network_id = hcloud_network.nixos_network.id
        ip = "10.0.1.10"
    }

    depends_on = [
        hcloud_network_subnet.nixos_subnet
    ]
}

output "server_ipv4" {
    value = hcloud_server.nixos_server.ipv4_address
    description = "The IPv4 address of the NixOS Server"
}

output "server_ipv6" {
    value = hcloud_server.nixos_server.ipv6_address
    description = "The IPv6 address of the NixOS Server"
}

output "next_steps" {
    value = <<EOT

Next steps:
1. Wait for a few minutes to allow the NixOS installation to complete.
2. SSH into the NixOS server:
   ssh root@${hcloud_server.nixos_server.ipv4_address}

Remember that the server starts as Ubuntu and then converts to NixOS.
The conversion process may take a few minutes to complete.
EOT
    description = "Instructions for next steps after Terraform apply"
}
