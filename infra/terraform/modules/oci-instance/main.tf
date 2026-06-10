# ── OCI Instance Module ──
# Provisions a single compute instance with cloud-init

terraform {
  required_version = ">= 1.5"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.0"
    }
  }
}

# ── Networking ──

resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-vcn"
  cidr_block     = var.vcn_cidr
  dns_label      = lower(replace(replace(var.name_prefix, "-", ""), "_", ""))
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-igw"
  vcn_id         = oci_core_vcn.this.id
  enabled        = true
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-rt-public"
  vcn_id         = oci_core_vcn.this.id

  route_rules {
    network_entity_id = oci_core_internet_gateway.this.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "public" {
  compartment_id    = var.compartment_id
  display_name      = "${var.name_prefix}-subnet-public"
  vcn_id            = oci_core_vcn.this.id
  cidr_block        = var.subnet_cidr
  route_table_id    = oci_core_route_table.public.id
  dns_label         = "public"
  security_list_ids = [oci_core_security_list.this.id]
}

resource "oci_core_security_list" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.name_prefix}-sl"
  vcn_id         = oci_core_vcn.this.id

  # SSH
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = var.server_public_ip != "" ? "${var.server_public_ip}/32" : "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # K3s API server (from Hetzner VPS Tailscale IP)
  ingress_security_rules {
    protocol = "6"
    source   = var.server_public_ip != "" ? "${var.server_public_ip}/32" : "0.0.0.0/0"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  # Kubelet metrics
  ingress_security_rules {
    protocol = "6"
    source   = var.server_public_ip != "" ? "${var.server_public_ip}/32" : "0.0.0.0/0"
    tcp_options {
      min = 10250
      max = 10250
    }
  }

  # Flannel VXLAN (from Tailscale range)
  ingress_security_rules {
    protocol = "17" # UDP
    source   = "100.64.0.0/10"
    udp_options {
      min = 8472
      max = 8472
    }
  }

  # WireGuard / Tailscale
  ingress_security_rules {
    protocol = "17" # UDP
    source   = "0.0.0.0/0"
    udp_options {
      min = 41641
      max = 41641
    }
  }

  # ICMP (ping for debugging)
  ingress_security_rules {
    protocol = "1"
    source   = "0.0.0.0/0"
  }
}

# ── Compute Instance ──

resource "oci_core_instance" "this" {
  compartment_id      = var.compartment_id
  display_name        = "${var.name_prefix}-node"
  availability_domain = var.availability_domain
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_gb
  }

  source_details {
    source_type = "image"
    source_id   = var.image_ocid
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    display_name     = "${var.name_prefix}-vnics"
    hostname_label   = lower(replace(replace(var.name_prefix, "-", ""), "_", ""))
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(var.cloud_init_script)
  }

  preserve_boot_volume = false

  agent_config {
    are_all_plugins_disabled = true
    is_management_disabled   = false
    is_monitoring_disabled   = false
  }

  launch_options {
    is_pv_encryption_in_transit_enabled = true
    network_type                        = "PARAVIRTUALIZED"
  }

  lifecycle {
    ignore_changes = [
      source_details,
      metadata["user_data"],
    ]
  }
}

# ── Block Volume (optional) ──

resource "oci_core_volume" "this" {
  count = var.block_volume_size_gb > 0 ? 1 : 0

  compartment_id      = var.compartment_id
  display_name        = "${var.name_prefix}-block"
  availability_domain = var.availability_domain
  size_in_gbs         = var.block_volume_size_gb
}

resource "oci_core_volume_attachment" "this" {
  count = var.block_volume_size_gb > 0 ? 1 : 0

  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.this.id
  volume_id       = oci_core_volume.this[0].id

  is_read_only = false
  is_shareable = false
}
