variable "env" {
  description = "the environment for all SES resources"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "the domain to register as a sending identity in SES (punycode form)"
  type        = string
  sensitive   = false
}

variable "zone_id" {
  description = "Route53 hosted zone ID — used to create DKIM CNAME verification records"
  type        = string
  sensitive   = true
}
