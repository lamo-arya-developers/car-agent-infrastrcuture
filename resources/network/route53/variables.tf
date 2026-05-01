
variable "env" {
  description = "the environment for all resources"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "the root domain name of the existing Route53 hosted zone (e.g. bilkopshjalpen.se)"
  type        = string
  sensitive   = false
}
