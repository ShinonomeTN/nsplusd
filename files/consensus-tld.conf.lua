# TLD "asn"
match "**.asn" {
    rewrite "$1.asn.shinonometn.com $1.asn.neruthes.xyz";
    uptream "cloudflare-dns.com/https 1.1.1.1/tcp 114.114.114.114/tcp @";
}

# TLD "pki"
match "**.pki" {
    rewrite "$1.pki.shinonometn.com $1.pki.neruthes.xyz";
    uptream "cloudflare-dns.com/https 1.1.1.1/tcp 114.114.114.114/tcp @";
}
