# Definition for TLD ASN (Version 0.1.0)

Status: Draft.


## Introduction

Every **autonomous system** (AS) is identified by a unique ASN,
and each AS may be assigned IP prefixes.

The `asn` TLD aims to provide domain names for AS owners
without requiring domain name registration.


## Gateway Resolver

A gateway resolver is a DNS server which plays as a gateway.
Suppose that we have a gateway resolver `ns1.example.com`.
The gateway resolver makes sure that,
for example, an inbound lookup request for `www.1234.asn.example.com`
will be served with a relayed (and possibly cached) answer for `www.1234.asn`
from a **self-believed quasi-authoritative DNS server** for `1234.asn`.
This responsibility mainly belongs to the domain name owner of `example.com`,
and the operational maintainer of host `ns1.example.com`.
who should deploy some other software for this purpose.

In our terminologies, for this situation, the domain name owner of `example.com`
has made `example.com` a **live suffix** for TLD `asn`.
The domain owner can keep using its favorite domain name resolving service (e.g. Cloudflare, NameCheap),
and only need to configure a NS record for `asn.example.com` to `ns1.example.com`,
the gateway resolver responsible for resolving `*.asn.example.com`.
Every domain name can be configured as a live suffix for specially defined TLDs.


## Simple Example

Suppose that we have a hypothetical autonomous system known as **AS1234**,
where IP prefixes `12.34.56.0/24` and `78.90.0.0/16` belong to it.
The gateway resolver assumes that the first available address of each prefix,
namely `12.34.56.1` and `78.90.0.1`, are perhaps the quasi-authoritative DNS servers for the AS.
As a result, when the gateway resolver receives an inbound lookup request for `1234.asn`,
it may return NS records pointing to `12.34.56.1` and `78.90.0.1`.
In this case, the two IP addresses are the **self-believed quasi-authoritative DNS servers** of `1234.asn`.

Finding the "first available address" in IPv6 prefixes can be more tricky.
The exact behavior for IPv6 will be added in a future version.

We call this **listing mode**.


## More Prefixes

For a larger AS which has hundreds of prefixes,
returning hundreds of NS records is a terrible practice.
The gateway resolver must be selective in this case.

For any AS which has at least 3 IPv4 prefixes or at least 3 IPv6 prefixes,
e.g. AS4134 in real world (which has 681 IPv4 prefixes and 606 IPv6 prefixes),
the gateway resolver shall work in **selective mode**, instead of the simple **listing mode**
(simply returning a list of the first available IP addresses).

In selective mode, the gateway resolver shall detect whether a potential DNS server (in the list as described above)
is really a DNS server by playing with its UDP 53 and TCP 53, expecting NS records for `4134.asn`.
The 20 fastest valid DNS servers are considered the good candidates.

THe gateway resolver shall produce a list of values of NS records from them,
and take the 4 most popular (included by most good candidates) values as the
**self-believed quasi-authoritative DNS servers** of `4134.asn`.
The list of self-believed quasi-authoritative DNS servers for a given AS shall expire in 24 hours
(or another value designated by the maintainer of the gateway resolver).




## Answering

Now the gateway resolver can operate well for AS4134.

This list of **self-believed quasi-authoritative DNS servers** is used in 2 ways:

- Use as the value of NS records of `4134.asn.example.com` in DNS answers.
- Use as the upstream servers to which outbound lookup requests for `*.4134.asn` are sent.



## Afternotes

When a gateway resolver is used in combination with NSPlusD,
we are essentially creating a bridge over the traditional NIC-based Internet.

The client wants `www.1234.asn`.
It gets translated to `www.1234.asn.example.com` by NSPlusD before sending to `ns1.example.com`;
it is important that the maintainer of the NSPlusD instance does not have to specify `ns1.example.com`,
and only needs to maintain a short list of suffixes with the `rewrite` directive.
