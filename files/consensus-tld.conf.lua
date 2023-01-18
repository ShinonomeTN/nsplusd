# TLD "asn"
match "**.asn" {
    rewrite "$1.asn-nic.shinonometn.com";
    uptream "1.1.1.1/https 1.1.1.1/tcp 114.114.114.114/tcp @";
}

# TLD "pki"
match "**.pki" {
    rewrite "$1.pki-nic.shinonometn.com";
    uptream "1.1.1.1/https 1.1.1.1/tcp 114.114.114.114/tcp @";
}
