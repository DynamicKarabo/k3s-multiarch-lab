output "instance_id" {
  value = module.arm_node.instance_id
}

output "instance_public_ip" {
  value = module.arm_node.instance_public_ip
}

output "instance_private_ip" {
  value = module.arm_node.instance_private_ip
}

output "ssh_connect" {
  value = module.arm_node.ssh_connect
}

output "vcn_id" {
  value = module.arm_node.vcn_id
}
