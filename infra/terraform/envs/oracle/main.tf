# ── Oracle (af-johannesburg-1) Environment ──
terraform {
  required_version = ">= 1.5"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.0"
    }
  }

  backend "local" {}  # Switch to S3/OSS for team use
}

provider "oci" {
  region = var.region
}

locals {
  cloud_init_script = templatefile("${path.module}/cloud-init.tftpl", {
    k3s_version      = var.k3s_version
    k3s_token        = var.k3s_token
    k3s_server_url   = var.k3s_server_url
    tailscale_auth   = var.tailscale_auth_key
    node_hostname    = "${var.name_prefix}-node"
    flannel_iface    = var.flannel_iface
  })
}

module "arm_node" {
  source = "../../modules/oci-instance"

  compartment_id      = var.compartment_id
  name_prefix         = var.name_prefix
  availability_domain = var.availability_domain
  instance_shape      = var.instance_shape
  instance_ocpus      = var.instance_ocpus
  instance_memory_gb  = var.instance_memory_gb
  image_ocid          = var.image_ocid
  ssh_public_key      = var.ssh_public_key
  cloud_init_script   = local.cloud_init_script
  server_public_ip    = var.server_public_ip
  vcn_cidr            = var.vcn_cidr
  subnet_cidr         = var.subnet_cidr
  block_volume_size_gb = var.block_volume_size_gb
}
