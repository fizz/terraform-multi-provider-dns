# =============================================================================
# Cloudflare — only creates resources when cloudflare_zone_id is set
# =============================================================================

resource "cloudflare_dns_record" "records" {
  for_each = local.cloudflare_enabled ? local.cf_records : {}

  zone_id  = var.cloudflare_zone_id
  name     = each.value.name
  type     = each.value.type
  content  = each.value.content
  ttl      = each.value.proxied ? 1 : each.value.ttl
  proxied  = each.value.proxied
  priority = each.value.priority
}

# Alias records use CNAME flattening — CF handles apex CNAME transparently
resource "cloudflare_dns_record" "alias" {
  for_each = local.cloudflare_enabled ? local.cf_alias_records : {}

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  type    = "CNAME"
  content = each.value.target
  ttl     = 300
  proxied = false
}
