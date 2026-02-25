# =============================================================================
# NS mirroring — cross-provider NS records for multi-provider DNS
# =============================================================================

# Enable multi-provider DNS so Cloudflare serves R53 NS records
resource "cloudflare_zone_dns_settings" "multi_provider" {
  count = local.multi_provider ? 1 : 0

  zone_id        = var.cloudflare_zone_id
  multi_provider = true

  lifecycle {
    ignore_changes = all
  }
}

# Register R53 nameservers in Cloudflare so both providers answer
resource "cloudflare_dns_record" "r53_ns" {
  for_each = local.multi_provider ? { for i, ns in var.r53_nameservers : "ns${i}" => ns } : {}

  zone_id = var.cloudflare_zone_id
  name    = var.domain
  type    = "NS"
  content = each.value
  ttl     = 86400

  depends_on = [cloudflare_zone_dns_settings.multi_provider]
}
