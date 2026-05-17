variable "ec2_public_key" {
  description = "Public SSH key content for EC2 Key Pair"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone:DNS:Edit permission"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for kcn333.com"
  type        = string
}
