# terraform-multi-provider-dns

Define DNS records once, create them in every provider. Ships with Route53 + Cloudflare; adding a provider is one `.tf` file and one variable.

## Usage

```hcl
module "dns" {
  source = "git::ssh://git@github.com/fizz/terraform-multi-provider-dns.git?ref=v0.1"

  domain             = "example.com"
  r53_zone_id        = aws_route53_zone.main.zone_id
  r53_nameservers    = aws_route53_zone.main.name_servers
  cloudflare_zone_id = "abc123"  # omit to skip Cloudflare

  records = {
    mx = {
      name   = ""
      type   = "MX"
      values = ["10 mx1.example.com", "20 mx2.example.com"]
    }
    txt = {
      name   = ""
      type   = "TXT"
      values = ["v=spf1 include:_spf.example.com ~all"]
    }
    dkim = {
      name   = "selector._domainkey"
      type   = "CNAME"
      values = ["selector.example.com.dkim.example.com"]
    }
  }

  alias_records = {
    apex = {
      name            = ""
      types           = ["A", "AAAA"]
      target          = "d1234.cloudfront.net"
      r53_hosted_zone = "Z2FDTNDATAQYW2"  # CloudFront's hosted zone ID
    }
  }
}
```

Set a provider's zone ID to enable it. Leave it `null` (the default) to skip it. Records are defined once in R53-style format; the module translates per-provider:

- **MX**: `"10 mx1.example.com"` stays as-is for R53, splits into `priority` + `content` for Cloudflare
- **TXT**: grouped in one record set for R53, one resource per value for Cloudflare
- **Alias/CNAME flattening**: R53 `alias {}` block for A/AAAA pointing at AWS resources, Cloudflare CNAME with automatic apex flattening
- **NS mirroring**: when both providers are enabled, R53 nameservers are automatically registered in Cloudflare
- **Multi-provider auto-enablement**: the module sets `multi_provider = true` on the Cloudflare zone via `cloudflare_zone_dns_settings`, gated on `local.multi_provider` (both providers active). Without this, Cloudflare silently ignores NS records at the zone apex. Callers don't need to toggle multi-provider DNS in the Cloudflare dashboard or manage a separate resource.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `domain` | `string` | — | Domain name (e.g., `"example.com"`) |
| `r53_zone_id` | `string` | `null` | Route53 hosted zone ID. Set to enable R53. |
| `r53_nameservers` | `list(string)` | `[]` | R53 nameservers for NS mirroring |
| `cloudflare_zone_id` | `string` | `null` | Cloudflare zone ID. Set to enable Cloudflare. |
| `records` | `map(object)` | `{}` | DNS records (see below) |
| `alias_records` | `map(object)` | `{}` | Alias/CNAME-flattened records (see below) |

### `records` object

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `string` | — | `""` for apex, `"sub"` for subdomain |
| `type` | `string` | — | `A`, `AAAA`, `CNAME`, `MX`, `TXT` |
| `values` | `list(string)` | — | R53-style values |
| `ttl` | `number` | `300` | TTL in seconds |
| `proxied` | `bool` | `false` | Cloudflare proxy (ignored by other providers) |

### `alias_records` object

| Field | Type | Description |
|-------|------|-------------|
| `name` | `string` | `""` for apex |
| `types` | `list(string)` | `["A", "AAAA"]` |
| `target` | `string` | Target hostname (e.g., CloudFront domain) |
| `r53_hosted_zone` | `string` | R53 hosted zone ID of the target |

## Outputs

| Name | Description |
|------|-------------|
| `r53_record_fqdns` | Map of record key to FQDN (R53) |
| `r53_alias_fqdns` | Map of alias key to FQDN (R53) |
| `cf_record_ids` | Map of record key to resource ID (Cloudflare) |
| `cf_alias_ids` | Map of alias key to resource ID (Cloudflare) |

## Adding a provider

1. Add a zone ID variable (e.g., `variable "google_managed_zone"`) with `default = null`
2. Create a `google.tf` with resources gated on `var.google_managed_zone != null`
3. Add translation logic to `locals.tf` if the provider's record format differs
4. Add NS mirroring resources to `ns_mirroring.tf` if multi-provider is desired

Existing callers are unaffected — new variables default to `null`.

## Verification

When both providers are enabled, use [dns-parity.sh](https://gist.github.com/fizz/40f49e05f2d4c6de19f85c849b602780) to verify records match across providers:

```bash
R53_ZONE_ID=Z0950556I9HD5G5OCODG \
CFLARE_ZONE_ID=9492bfb2fdbd83a400972d72f14c3b53 \
CFLARE_API_TOKEN=... \
  ./dns-parity.sh
```

Expect no `>>>` diff markers. The script automatically suppresses expected alias/CNAME-flattening equivalence (R53 alias A/AAAA vs. Cloudflare CNAME).

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.0 |
| aws | >= 5.0 |
| cloudflare | >= 5.0 |

## License

Apache 2.0 — see [LICENSE](LICENSE).
