resource "cloudflare_zero_trust_tunnel_cloudflared" "jenkins" {
    account_id = var.account_id
    name = "jenkins-tunnel"
}
data "cloudflare_zero_trust_tunnel_cloudflared_token" "jenkins" {
    account_id = var.account_id
    tunnel_id = cloudflare_zero_trust_tunnel_cloudflared.jenkins.id
}
resource "cloudflare_dns_record" "jenkins" {
  zone_id = var.zone_id
  name = "jenkins.uri-labs.com"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.jenkins.id}.cfargotunnel.com"
  type = "CNAME"
  proxied = true
  ttl = 1
}
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "jenkins" {
  tunnel_id = cloudflare_zero_trust_tunnel_cloudflared.jenkins.id
  account_id = var.account_id
  config = {
    ingress = [ 
      {
        hostname = "jenkins.uri-labs.com"
        service = "http://jenkins:8080"
      },
      {
        service = "http_status:404"
      }
    ]
  }
}
resource "cloudflare_zero_trust_access_policy" "jenkins_with_email" {
  account_id = var.account_id
  name = "access to jenkins using email"
  decision = "allow"
  include = [ {
    email_domain = {
      domain = "uri-labs.com"
    }
  } ]
}
resource "cloudflare_zero_trust_access_application" "jenkins" {
  account_id = var.account_id
  type = "self_hosted"
  name = "access to jenkins"
  domain = "jenkins.uri-labs.com"
  policies = [ {
    id = cloudflare_zero_trust_access_policy.jenkins_with_email.id
    precedence = 1
  } ]
}
output "jenkins_tunnel_token" {
  value = data.cloudflare_zero_trust_tunnel_cloudflared_token.jenkins.token
  sensitive = true
}

# resource "cloudflare_dns_record" "example_dns_record" {
#   zone_id = var.zone_id
#   name = "jenkins.uri-labs.com"
#   ttl = 1
#   type = "A"
#   comment = "jenkins server"
#   content = "63.178.59.87"
# }
# resource "cloudflare_ruleset" "waf" {
#   zone_id = var.zone_id
#   name    = "geo"
#   kind    = "zone"
#   phase   = "http_request_firewall_custom"

#   rules = [
#     {
#       action = "block"
#       expression = "(ip.geoip.country in {\"CN\" \"IR\" \"RU\" \"SY\" \"KP\"})"
#       description = "Block countries"
#     }
#   ]
# }