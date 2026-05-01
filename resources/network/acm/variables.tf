
variable "env" {
  description = "the environment for all resources"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "the root domain to issue the certificate for — also generates a wildcard SAN (*.domain)"
  type        = string
  sensitive   = false
}

variable "zone_id" {
  description = "the Route53 hosted zone ID where DNS validation CNAME records will be created"
  type        = string
  sensitive   = false
}
