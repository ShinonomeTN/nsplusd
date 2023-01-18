# NS+D


## Introduction

**NSPlusD** (can be spelled as "nsplusd" informally) is a DNS reverse proxy
(or "recursive DNS resolver", a traditional term which was not quite favored by the initial developers of this software)
with the following key features:

- Accept DNS queries over UDP 53, TCP 53, and DNS over HTTPS. And perhaps more in future.
- Rewrite the domain name in a DNS query by configuring rewrite rules.
- Contact different upstream DNS servers according to the configured rules.

NSPlusD is a lightweight gateway for DNS which allows the instance owners to play with
customized DNS magics without impairing traditional DNS capabilities or
completely migrating to a full-feature DNS solution suite
(which handles everything in DNS in a systemd fashion).


## Config

### Location

Upon startup, this software will read all files in `$ROOTFS_PREFIX/etc/nsplusd/conf.d/` and concatenate them,
expecting to see a valid config.

### Syntax Basics

Here is an example config:

```
#v1
# First line '#v1' is like a shebang, for indicating config syntax version.
# It may be helpful if we want to adopt another config syntax in future.
# Lines starting with a hash mark are treated as comments.
# All strings must be quoted with <">.

### Simple case:
match "*.asn" {
    rewrite "$1.asndns.example.com";
}

### Complex case: big org public DDNS for internal use;
### each host has many address (along with cursed routing tables) like...
### alice.wan.ddns              =   66.66.77.77/24
### alice.lan.ddns              =   192.168.77.77/24
### alice.tinc-asia.ddns        =   10.254.77.77/24
### alice.tinc-global.ddns      =   10.127.77.77/15
### alice.zerotier-asia.ddns    =   10.253.77.77/24
### alice.zerotier-global.ddns  =   10.0.77.77/15
### ... where a machine can be reached via 4 routes,
### but the big org wish to anonymize hosts, and prefer authoritative DDNS over ARP magics or Zeroconf.
match "*.*.ddns" {
    # $1 is hostname and $2 is subnet indicator (lan/vpn1/vpn2)
    rewrite(sha256hex_b12("$1@$2") + ".ddns.example.com"));
}
```

This config syntax (excluding the comments aspect) is actually Lua script,
and may be interpreted with Lua.
And hence you can use certain functions to do sophisticated transforms onto the requested domain names when rewriting.

NSPlusD expects to see **blocks** (like the `match` block above)
and **apex directives** (directives which are not located inside any block).

Directives include local directives (only allowed in blocks), apex directives (only allowed out of blocks),
and flexible directives (allowed in blocks and out of blocks).

### Blocks

NSPlusD finds all blocks in the config and parse them.

Like how we write `location / { ... }` in Nginx config, the block here (e.g. `match`) are very similar.
The slight difference is that we have no need to create a hierarchy (e.g. `http -> server -> 'location /'`) here.

The atomic elements inside a block are called "directives".

All blocks are captive. When a request is captured by a block, later blocks will be ignored.

If an incoming request is not captured by any block ("walking through the pipelines with nothing happening"),
the default lookup behavior will be used (to be described in a later section).

#### match

You can use the `match` block to capture an incoming query by the domain name with wildcard matching with asterisk (`*`).
A **matching term** can have up to 8 asterisks,
which will then be accessible in the block as `$1` to `$8`.

An asterisk matches non-greedily and cannot span across dots.
If you require greedy matching
(e.g. match something like `1.2.3.4` in requested domain name `1.2.3.4.reverse-dns.example.com`),
use double asterisks (`**`) as the wildcard symbol (`**.reverse-dns.example.com`).

#### match_from

Similar to `match`, but the string after it is interpreted as the path of a file
which contains a newline-delimited, hash-commented list of matching terms (not quoted).
If the requested domain name is matched by any term inside the file,
this block will be used to determine how NSPlusD should serve this request.

If the path starts with `/`, it is interpreted as an absolute path.
Otherwise, it is interpreted as a relative path under `$ROOTFS_PREFIX/etc/nsplusd/lists.d`.

### Flexible Directives

A locally declared flexible directive (in a block) can override its globally set value.

#### upstream_timeout

Declare that how long can NSPlusD wait for an upstream answer before returning a timeout answer
to the original client.

### Local Directives

#### rewrite

When a rewrite happens, the current request is marked "dirty".
When a block exits, if the request is dirty, NSPlusD will start over to try finding a capturing block.
But rest assured, only up to 8 (or env `MAX_REWRITES`) rewrites can happen for any particular request.

#### upstream

If no `upstream` directive is used in a block,
NSPlusD will use the default **upstream lookup behavior**.

Additionally, a magic word `@` is allowed as a valid upstream indicator.
It means that, when all given upstream servers go timeout, NSPlusD can fallback to the default upstream discovery mechanism.

#### upstream_from

The effect is similar to the `upstream` directive.

The reading behavior is similar to the `match_from` block.
This directive reads a file from the given path (absolute or relative to `$ROOTFS_PREFIX/etc/nsplusd/upstreams.d`)
and interprets the content as a newline-delimited, hash-commented list of **upstream indicators**.

### Apex Directives

#### accept

Specify a whitespace-delimited list of accepting protocols along with the comma-delimited list of listening ports for the protocol;
two sections of a record are connected by slash.
If the ports are omitted, the default ports for the protocol will be listened.

| Protocol | Default Ports |
| -------- | ------------- |
| `udp`    | 53            |
| `tcp`    | 53            |
| `https`  | 443           |
| `tls`    | 853           |

Example: `accept "udp/53,20053 tcp/53,20053 https/443,2096 tls/853,20853";`.

Default: `accept "udp/53 tcp/53 https/443 tls/853";`.

#### max_rewrites

Set how many recursive rewrites can happen for a particular incoming request.

Example: `max_rewrites "16";`.

#### default_upstreams

Specify a whitespace-delimited list of **upstream indicators** for **upstream lookup behavior**.
If not set, the default upstream discovery mechanism will be used in upstream lookup behavior.

Example: `default_upstreams "1.1.1.1 www.cloudflare-dns.com/https";`.

#### default_protocol

Set the default protocol for the indicated upstream servers which are not accompanied by protocol information in the **upstream indicator**.

Can be `udp` or `tcp`.

Example: `default_protocol "udp"`.

Default: `default_protocol "tcp"`.

### Functions

Functions can only be used in directives.

#### sha256hex_b12

Calculate the SHA-256 hash of the input string,
then serialize to lowercase hexadecimal representation,
then get the initial 12 characters.

### Miscellaneous

#### Upstream Indicator

An **upstream indicator** is a string which consists of two sections: hostname (required) and protocol (optional).

In a single upstream indicator, the hostname can be domain name or IP address (v4 and v6),
and the protocol can be `udp`, `tcp`, or `https`.

If the protocol field is omitted (e.g. `1.1.1.1`), the default protocol is `tcp`, which can be overrode by
or apex directive ``.
But the acceptable values for it are only `tcp` and `udp`.

If the protocol is specified, the two sections should be connected;
two sections of a record are onnected a slash (`/`),
and the upstream indicator should look like `1.1.1.1/tcp`.

You may notice that a newline-delimited list of upstream indicators (with the protocol section omitted)
looks very compatible with `resolf.conf`.
This is the intended design, so that any `resolv.conf` file can be interpreted as a list of upstream indicators.



#### Upstream Lookup Behavior

NSPlusD is not an iterative resolver, and hence never does the iteration from root domains (e.g. `com.`).
NSPlusD is only a recursive resolver, so it only relays the upstream answers with TTL-respecting caches.

If the request is captured by any block which declares a local upstream policy through the `upstream` directive
or the `upstream_from` directive,
the locally selected list of **upstream indicators** will be used.

Otherwise, NSPlusD continues to the following default behavior to determine what **upstream indicators** should be used.

#### Default Upstream Discovery Mechanism

Unless instructed by the instance owner in the config via apex directive `default_upstreams`,
NSPlusD will try to formulate a whitespace-delimited list of **upstream indicators** according to the following workflow:

- If env `DEFAULT_UPSTREAMS` is present, use the list.
- If file `$ROOTFS_PREFIX/etc/nsplusd/resolv.conf` exists, use the list.
- If file `/etc/resolv.conf` exists, exclude all addresses which mean the current host itself;
    then, if any address remains, use the remaining addresses as a list.

Other spacing characters (e.g. newline and tab) are treated equivalent to whitespace here,
like how we do `for word in $(cat list); do`
in shell scripts without caring how the list is actually quasiwhitespace-delimited.

Now NSPlusD has a list of upstream servers to try among.
Appearing earlier in the list means having a higher priority.
Suppose that 4 upstream indicators are found, the 4 upstream servers (to be called Upstream A/B/C/D)
are respectively assign `priority` from 4 to 1,
within the local scope of the current outbound lookup,
from the 1st to the 4th.

NSPlusD immediately initiates 4 DNS queries in their respective protocols at the same time (annotated as "T+0ms").
And a priority-based waiting mechanism is employed here.
The higher the priority, the longer NSPlusD can wait for its answer.
For example, if the flexible directive `upstream_timeout "500";` is 
even if Upstream D returns the first answer at 5ms since start (annotated as "T+5ms"),
NSPlusD will still wait for the answer from Upstream A/B/C.

If Upstream A unfortunately go timeout, at T+501ms, NSPlusD will stop the waiting for Upstream A,
and will try using the answer from Upstream B;
if it also go timeout, NSPlusD will try Upstream C, then finally Upstream D.
If all the 4 upstream servers go timeout, NSPlusD will return a timeout answer.

If Upstream A returned the answer before timeout, e.g. at T+409ms,
NSPlusD will immediate return the answer to the original client.




## Real-World Scenarios

### Circumventing DNS Pollution

Work with projects like GFWList to use specific upstream servers for the listed domain name matching terms.

### Consensus-Based TLD Definitions

See the `/tld-def` directories for definitions and `/files/consensus-tld.conf.lua` for config example.





## Notes & Warnings

- Although it is accepted that, any modern software, particularly this one, should support UTF-8 without pain,
    dealing with IDN in your text editors (especially when you use some TUI editor over SSH)
    may perhaps be a less comfortable experience (especially when working with Unicode codepoints from RTL writing systems).
    Therefore it might be better if you do the punny code conversion before feeding into the config via a text editor.



## Extra Notes

- We wish that every instance owner can respect the consensus-based TLD definitions which are collected in this repository in `/tld-def`.
    The rules necessary to support those TLDs are shipped with this software as default config.
    Although technically not mandatory, some of them are the reasons why this project was proposed at the first place.




## Copyright

Copyright (c) 2023 Catten Linger, Neruthes, and other contributors.

The license for software source code remains to be determined.

The documentation files in this repository (all `.md` files, including this `README.md`)
are released with GNU FDL 1.3 (`GFDL-1.3-only`).

