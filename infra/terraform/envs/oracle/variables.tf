variable "region" {
  description = "OCI region"
  type        = string
  default     = "af-johannesburg-1"
}

variable "compartment_id" {
  description = "OCI compartment OCID"
  type        = string
}

variable "name_prefix" {
  description = "Resource name prefix"
  type        = string
  default     = "k3s-arm"
}

variable "availability_domain" {
  description = "OCI availability domain"
  type        = string
  default     = "WmRs:AF-JOHANNESBURG-1-AD-1"
}

variable "instance_shape" {
  description = "Compute shape"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs (max 4 for always-free)"
  type        = number
  default     = 4
}

variable "instance_memory_gb" {
  description = "Memory in GB (max 24 for always-free)"
  type        = number
  default     = 24
}

variable "image_ocid" {
  description = "Ubuntu 24.04 Minimal ARM image OCID for af-johannesburg-1"
  type        = string
  default     = "ocid1.image.oc1.af-johannesburg-1.aaaaaaaa7iyv4gag33b3tnp2cqezqqjsmjrl4gjhvc45zoyzhkrpr4w56rra"
}

variable "ssh_public_key" {
  description = "SSH public key content (not path)"
  type        = string
  sensitive   = true
}

variable "k3s_version" {
  description = "K3s version to install"
  type        = string
  default     = "v1.32.3+k3s1"
}

variable "k3s_token" {
  description = "K3s cluster token (from server node)"
  type        = string
  sensitive   = true
}

variable "k3s_server_url" {
  description = "K3s server URL (e.g., https://10.0.0.1:6443)"
  type        = string
}

variable "tailscale_auth_key" {
  description = "Tailscale pre-authentication key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "server_public_ip" {
  description = "Hetzner VPS public IP (for security list restriction)"
  type        = string
  default     = "178.105.76.236"
}

variable "flannel_iface" {
  description = "Flannel overlay interface"
  type        = string
  default     = "tailscale0"
}

variable "vcn_cidr" {
  description = "VCN CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Public subnet CIDR block"
  type        = string
  default     = "10.0.1.0/24"
}

variable "block_volume_size_gb" {
  description = "Additional block storage in GB (0 = skip)"
  type        = number
  default     = 0
}
