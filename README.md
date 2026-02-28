[![OpenWrt](https://img.shields.io/badge/OpenWrt-24.10.x-darkgreen.svg)](https://openwrt.org/)
[![GitHub Release](https://img.shields.io/github/v/release/Zerogiven-OpenWRT-Packages/reaction)](https://github.com/Zerogiven-OpenWRT-Packages/reaction/releases)
[![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/Zerogiven-OpenWRT-Packages/reaction/total?color=blue)](https://github.com/Zerogiven-OpenWRT-Packages/reaction/releases)
[![GitHub Issues or Pull Requests](https://img.shields.io/github/issues/Zerogiven-OpenWRT-Packages/reaction)](https://github.com/Zerogiven-OpenWRT-Packages/reaction/issues)

# reaction

A lightweight log-monitoring and reaction daemon for OpenWrt.

`reaction` scans program outputs (e.g. SSH or web server logs) for repeated patterns and executes user-defined actions – commonly to block malicious hosts after multiple failed logins.

Compared to traditional tools like *fail2ban*, `reaction` focuses on simplicity, speed, and low resource usage.

## Features

- **Fast and Efficient**: Daemon written in Rust
- **Flexible Configuration**: Configurable via YAML or JSONnet
- **IPv4 and IPv6**: Supports both protocol versions
- **Firewall Integration**: Works seamlessly with iptables/nftables and more
- **Embedded Ready**: Ideal for embedded environments such as OpenWrt routers

## Requirements

- OpenWrt 24.10

> **Note:** For OpenWrt 23.05, use reaction v2.2.x releases. Version 2.3.0+ requires a newer Rust toolchain not available in 23.05.

## Installation

### From Package Feed

You can setup this package feed to install and update it with opkg:

[https://github.com/Zerogiven-OpenWRT-Packages/package-feed](https://github.com/Zerogiven-OpenWRT-Packages/package-feed)

### From IPK Package

Download ipk files from release and install them:

```bash
opkg install reaction-*.ipk
```

### From Source

```bash
git clone https://github.com/Zerogiven-OpenWRT-Packages/reaction.git package/reaction
make menuconfig  # Navigate to: Utilities → reaction
make package/reaction/compile V=s
```

## Usage

After installation the reaction service starts automatically with two active streams for SSH and LuCI.

**IMPORTANT**: Be aware that after installing you can lock yourself out if you try to login with wrong password more than 10 times. That's the reason why the number is so high by default. Change it for better security.

## Documentation

For complete configuration examples, usage guides, and advanced setup instructions, please refer to the main project resources:

- **Main website:** [https://reaction.ppom.me](https://reaction.ppom.me)
- **Source repository:** [https://framagit.org/ppom/reaction](https://framagit.org/ppom/reaction)
- **Wiki & examples:** [https://reaction.ppom.me/configurations](https://reaction.ppom.me/configurations)
