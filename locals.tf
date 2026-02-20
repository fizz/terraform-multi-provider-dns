locals {
  # =========================================================================
  # R53: uses var.records directly — R53 handles multi-value natively
  # =========================================================================

  # R53: aggregate records by (name, type) — R53 requires one record set per name+type.
  # Multiple record keys with the same name+type get their values merged.
  r53_aggregated = {
    for group_key, records in {
      for key, record in var.records :
      "${record.name}/${record.type}" => record...
    } :
    group_key => {
      name   = records[0].name == "" ? var.domain : "${records[0].name}.${var.domain}"
      type   = records[0].type
      ttl    = max([for r in records : r.ttl]...)
      values = flatten([for r in records : r.values])
    }
  }

  # R53 alias records: one resource per (key, type) pair
  r53_alias_records = merge([
    for key, record in var.alias_records : {
      for type in record.types :
      "${key}_${lower(type)}" => {
        name            = record.name == "" ? var.domain : "${record.name}.${var.domain}"
        type            = type
        target          = record.target
        r53_hosted_zone = record.r53_hosted_zone
      }
    }
  ]...)

  # =========================================================================
  # Cloudflare: flatten to one resource per individual value
  # =========================================================================

  cf_records = merge([
    for key, record in var.records : {
      for idx, value in record.values :
      "${key}_${idx}" => {
        name    = record.name == "" ? var.domain : record.name
        type    = record.type
        ttl     = record.ttl
        proxied = length(regexall("_domainkey", record.name)) > 0 ? false : record.proxied
        # MX: parse "10 mx1.example.com" → priority=10, content="mx1.example.com"
        priority = record.type == "MX" ? tonumber(split(" ", value)[0]) : null
        content  = record.type == "MX" ? trimprefix(value, "${split(" ", value)[0]} ") : value
      }
    }
  ]...)

  # Cloudflare alias records: CNAME flattening (one CNAME per alias key, CF handles apex)
  cf_alias_records = {
    for key, record in var.alias_records :
    key => {
      name   = record.name == "" ? var.domain : record.name
      target = record.target
    }
  }

  # Provider enablement: explicit bool takes precedence, falls back to zone_id null check
  r53_enabled        = coalesce(var.enable_r53, var.r53_zone_id != null)
  cloudflare_enabled = coalesce(var.enable_cloudflare, var.cloudflare_zone_id != null)

  # Multi-provider detection
  multi_provider = local.r53_enabled && local.cloudflare_enabled
}
