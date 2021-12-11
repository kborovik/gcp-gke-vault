/*

GKE Proxy Host DNS records

*/
locals {
  gke_proxy_dns_records = [
    {
      "name" : "gke-proxy-01"
      "address" : "10.128.0.4"
    },
  ]
}

/*

OpenVPN Host DNS records

*/
locals {
  vpn_dns_record = [
    {
      "name" : "openvpn-01"
      "address" : "10.128.0.3"
    },
  ]
}
