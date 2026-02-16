variable "domain" {
  description = "The domain name (e.g., fizz.today)"
  type        = string
}

# --- Provider zone IDs (set = enabled, null = disabled) ---

variable "r53_zone_id" {
  description = "Route53 hosted zone ID. Set to enable R53 record creation."
  type        = string
  default     = null
}

variable "enable_r53" {
  description = "Explicitly enable R53 record creation. Use when r53_zone_id is not known until apply."
  type        = bool
  default     = null
}

variable "r53_nameservers" {
  description = "Route53 nameservers to register in other providers for multi-provider DNS"
  type        = list(string)
  default     = []
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID. Set to enable Cloudflare record creation."
  type        = string
  default     = null
}

variable "enable_cloudflare" {
  description = "Explicitly enable Cloudflare record creation. Use when cloudflare_zone_id is not known until apply."
  type        = bool
  default     = null
}

# variable "google_managed_zone" {
#   description = "Google Cloud DNS managed zone name. Set to enable Google DNS record creation."
#   type        = string
#   default     = null
# }

# --- Canonical record definitions ---

variable "records" {
  description = "DNS records to create in all enabled providers. Values use R53 format (e.g., MX: '10 mx1.example.com')."
  type = map(object({
    name    = string        # "" for apex, or subdomain like "fm1._domainkey"
    type    = string        # A, AAAA, CNAME, MX, TXT
    values  = list(string)  # R53-style values: ["10 mx1.example.com"] for MX
    ttl     = optional(number, 300)
    proxied = optional(bool, false) # Cloudflare-specific, ignored by other providers
  }))
  default = {}
}

variable "alias_records" {
  description = "Records using R53 alias / CF CNAME flattening (e.g., CloudFront apex)"
  type = map(object({
    name            = string        # "" for apex
    types           = list(string)  # ["A", "AAAA"]
    target          = string        # e.g., "d1mmj5h2bt0af1.cloudfront.net"
    r53_hosted_zone = string        # e.g., "Z2FDTNDATAQYW2" for CloudFront
  }))
  default = {}
}
