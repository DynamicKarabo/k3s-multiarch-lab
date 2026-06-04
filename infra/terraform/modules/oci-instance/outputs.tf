output "instance_id" {
  description = "Instance OCID"
  value       = oci_core_instance.this.id
}

output "instance_public_ip" {
  description = "Public IP of the instance"
  value       = oci_core_instance.this.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the instance"
  value       = oci_core_instance.this.private_ip
}

output "vcn_id" {
  description = "VCN OCID"
  value       = oci_core_vcn.this.id
}

output "subnet_id" {
  description = "Public subnet OCID"
  value       = oci_core_subnet.public.id
}

output "block_volume_id" {
  description = "Block volume OCID (empty if not created)"
  value       = var.block_volume_size_gb > 0 ? oci_core_volume.this[0].id : ""
}

output "ssh_connect" {
  description = "SSH command to connect"
  value       = "ssh -i ~/.ssh/id_ed25519 ubuntu@${oci_core_instance.this.public_ip}"
}
