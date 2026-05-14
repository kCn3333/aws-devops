output "instance_id" {
  value = "SRV IDs: ${join(", ", aws_instance.kcn_srv[*].id)}"
}

output "instance_public_ip" {
  value = "Public IPs: ${join(", ", aws_instance.kcn_srv[*].public_ip)}"
}

output "dns" {
  value = "DNS: ${join(", ", aws_instance.kcn_srv[*].public_dns)}"
}