output "instance_id" {
  value = "SRV ID: ${aws_instance.kcn_srv.id}"
}
output "instance_public_ip" {
  value = "Public IP: ${aws_instance.kcn_srv.public_ip}"
}
output "dns" {
  value = "DNS: ${aws_instance.kcn_srv.public_dns}"
}