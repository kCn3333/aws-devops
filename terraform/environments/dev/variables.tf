variable "ec2_public_key" {
  description = "Public SSH key content for EC2 Key Pair"
  type        = string
  sensitive   = true
}