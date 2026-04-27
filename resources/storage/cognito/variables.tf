
variable "env" {
  description = "the environment for all resources"
  type = string
  sensitive = true
}

variable "google_client_id" {
  description = "this is the Google client ID"
  type      = string
  sensitive = true
}
variable "google_client_secret" {
  description = "this is the Google client secret"
  type      = string
  sensitive = true
}

#variable "facebook_app_id" {     --- NOT NECESSARY FOR MVP, COMMENTING OUT FOR NOW ---
#  description = "this is the Facebook app ID"
#  type      = string
#  sensitive = true
#}
#variable "facebook_app_secret" { --- NOT NECESSARY FOR MVP, COMMENTING OUT FOR NOW ---
#  description = "this is the Facebook app secret"
#  type      = string
#  sensitive = true
#}
