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



## Installation

// TODO

### Build From Source
### Install Prebuilt Artifacts



## Configuration

See [DOCUMENTATION/Config.md](DOCUMENTATION/Config.md).



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

- See [/DOCUMENTATION_PDF_LINKS.md](DOCUMENTATION_PDF_LINKS.md) for links of converted PDF artifacts for Markdown documents.
- We wish that every instance owner can respect the consensus-based TLD definitions which are collected in this repository in `/tld-def`.
    The rules necessary to support those TLDs are shipped with this software as default config.
    Although technically not mandatory, some of them are the reasons why this project was proposed at the first place.




## Copyright

Copyright (c) 2023 Catten Linger, Neruthes, and other contributors.

The license for software source code remains to be determined.

The documentation files in this repository (all `.md` files, including this `README.md`)
are released with GNU FDL 1.3 (`GFDL-1.3-only`).

