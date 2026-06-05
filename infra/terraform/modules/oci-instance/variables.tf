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
  description = "OCI availability domain (e.g., WmRs:AF-JOHANNESBURG-1-AD-1)"
  type        = string
}

variable "instance_shape" {
  description = "Compute shape"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs"
  type        = number
  default     = 4
}

variable "instance_memory_gb" {
  description = "Memory in GB"
  type        = number
  default     = 24
}

variable "image_ocid" {
  description = "Image OCID (Ubuntu 24.04 ARM)"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
  sensitive   = true
}

variable "cloud_init_script" {
  description = "Cloud-init user_data script content (plaintext, will be base64-encoded)"
  type        = string
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

variable "server_public_ip" {
  description = "Hetzner VPS public IP (for security list restrictions). Leave blank for 0.0.0.0/0"
  type        = string
  default     = ""
}

variable "block_volume_size_gb" {
  description = "Additional block volume size in GB (0 to skip)"
  type        = number
  default     = 0
}
