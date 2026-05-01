
locals {
  # Strip the https:// prefix — CloudFront origin domain_name must be a bare hostname
  api_gateway_domain = trimprefix(var.api_gateway_endpoint, "https://")
}

# OAC — lets CloudFront authenticate to S3 without making the bucket public
resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = var.env == "prod" ? "car-agent-s3-oac-prod" : "car-agent-s3-oac-dev"
  description                       = "OAC allowing CloudFront to read from the car-agent S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Bucket policy — scoped to this specific CloudFront distribution via SourceArn condition
resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = var.s3_bucket_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${var.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "${aws_cloudfront_distribution.main.arn}"
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  comment             = var.env == "prod" ? "car-agent-distribution-prod" : "car-agent-distribution-dev"
  aliases             = [var.domain_name]
  default_root_object = "index.html"

  # PriceClass_100 = US, Canada, Europe edge locations only — cheapest tier
  price_class = "PriceClass_100"

  # Origin 1: API Gateway — handles all backend routes
  origin {
    origin_id   = "api_gateway"
    domain_name = local.api_gateway_domain

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Origin 2: S3 — serves the static frontend via OAC (no public bucket access needed)
  origin {
    origin_id                = "s3_origin"
    domain_name              = var.s3_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  # /auth/* → API Gateway, no caching (auth tokens must never be cached)
  ordered_cache_behavior {
    path_pattern   = "/auth/*"
    target_origin_id       = "api_gateway"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    # CachingDisabled managed policy
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    # AllViewerExceptHostHeader — forwards Authorization, Content-Type, etc. but not Host
    # (API Gateway rejects requests where Host doesn't match its own domain)
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  # /invoke → API Gateway, no caching (agent responses are always dynamic)
  ordered_cache_behavior {
    path_pattern           = "/invoke"
    target_origin_id       = "api_gateway"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  # /* (default) → S3, cached — serves the static frontend assets
  default_cache_behavior {
    target_origin_id       = "s3_origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    # CachingOptimized managed policy
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["SE"] # Only allow traffic from Sweden — helps mitigate abuse and reduces costs
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# Route53 A alias record — points the apex domain at the CloudFront distribution
resource "aws_route53_record" "cloudfront_alias" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}
