
variable "env" {
  description = "the environment for all resources"
  type        = string
  sensitive   = true
}

# Toggle: when false, CloudFront uses its built-in *.cloudfront.net cert and accepts plain HTTP.
# Use this during early bootstrap when the domain's NS records haven't propagated yet (so ACM
# can't validate). Flip to true once the cert is issued to enable the custom domain + HTTPS.
variable "use_custom_domain" {
  description = "if true, attaches the custom domain alias + ACM cert + Route53 record and forces HTTPS; if false, uses CloudFront default cert and allows HTTP"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "the domain CloudFront serves traffic on — used as the distribution alias and Route53 record name. Only used when use_custom_domain = true"
  type        = string
  sensitive   = false
  default     = null
}

variable "zone_id" {
  description = "the Route53 hosted zone ID — used to create the apex A alias record pointing to CloudFront. Only used when use_custom_domain = true"
  type        = string
  sensitive   = false
  default     = null
}

variable "certificate_arn" {
  description = "the ARN of the validated ACM certificate — must be in us-east-1 for CloudFront. Only used when use_custom_domain = true"
  type        = string
  sensitive   = true
  default     = null
}

variable "api_gateway_endpoint" {
  description = "the full API Gateway endpoint URL (e.g. https://abc123.execute-api.us-east-1.amazonaws.com) — https:// prefix is stripped internally"
  type        = string
  sensitive   = false
}

variable "s3_bucket_name" {
  description = "the name of the S3 bucket — used in the CloudFront OAC bucket policy"
  type        = string
  sensitive   = false
}

variable "s3_bucket_arn" {
  description = "the ARN of the S3 bucket — used to scope the CloudFront OAC bucket policy to this bucket only"
  type        = string
  sensitive   = false
}

variable "s3_bucket_regional_domain_name" {
  description = "the regional domain name of the S3 bucket (e.g. bucket.s3.us-east-1.amazonaws.com) — used as the S3 origin domain in CloudFront"
  type        = string
  sensitive   = false
}
