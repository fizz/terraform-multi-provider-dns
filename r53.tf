# =============================================================================
# Route53 — only creates resources when r53_zone_id is set
# =============================================================================

resource "aws_route53_record" "records" {
  for_each = local.r53_enabled ? var.records : {}

  zone_id = var.r53_zone_id
  name    = local.r53_record_name[each.key]
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.values
}

resource "aws_route53_record" "alias" {
  for_each = local.r53_enabled ? local.r53_alias_records : {}

  zone_id = var.r53_zone_id
  name    = each.value.name
  type    = each.value.type

  alias {
    name                   = each.value.target
    zone_id                = each.value.r53_hosted_zone
    evaluate_target_health = false
  }
}
