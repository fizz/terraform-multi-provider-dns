# =============================================================================
# NS mirroring — cross-provider NS records for multi-provider DNS
# =============================================================================

# Register R53 nameservers in Cloudflare so both providers answer
resource "cloudflare_dns_record" "r53_ns" {
  for_each = local.multi_provider ? toset(var.r53_nameservers) : toset([])

  zone_id = var.cloudflare_zone_id
  name    = var.domain
  type    = "NS"
  content = each.key
  ttl     = 86400
}
