output "contact_list_name" {
  description = "the SES contact list name — passed to Lambdas as SES_CONTACT_LIST_NAME"
  value       = aws_sesv2_contact_list.main.contact_list_name
  sensitive   = false
}

output "contact_list_arn" {
  description = "the SES contact list ARN — used to scope IAM permissions"
  value       = aws_sesv2_contact_list.main.arn
  sensitive   = false
}

output "domain_identity_arn" {
  description = "the SES domain identity ARN — used to scope IAM send permissions"
  value       = aws_sesv2_email_identity.domain.arn
  sensitive   = false
}
