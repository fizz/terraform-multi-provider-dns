output "r53_record_fqdns" {
  description = "Map of name/type to FQDN for R53 records (aggregated by name+type)"
  value       = { for k, v in aws_route53_record.records : k => v.fqdn }
}

output "r53_alias_fqdns" {
  description = "Map of alias key to FQDN for R53 alias records"
  value       = { for k, v in aws_route53_record.alias : k => v.fqdn }
}

output "cf_record_ids" {
  description = "Map of record key to Cloudflare record ID"
  value       = { for k, v in cloudflare_dns_record.records : k => v.id }
}

output "cf_alias_ids" {
  description = "Map of alias key to Cloudflare record ID"
  value       = { for k, v in cloudflare_dns_record.alias : k => v.id }
}
