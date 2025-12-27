# reaction

A lightweight log-monitoring and reaction daemon for OpenWrt.

[![OpenWrt 23.05](https://img.shields.io/badge/OpenWrt-23.05.x-green.svg)](https://openwrt.org/)
[![OpenWrt 24.10](https://img.shields.io/badge/OpenWrt-24.10.x-green.svg)](https://openwrt.org/)

`reaction` scans program outputs (e.g. SSH or web server logs) for repeated patterns and executes user-defined actions – commonly to block malicious hosts after multiple failed logins.

Compared to traditional tools like *fail2ban*, `reaction` focuses on simplicity, speed, and low resource usage.

## Features

- **Fast and Efficient**: Daemon written in Rust
- **Flexible Configuration**: Configurable via YAML or JSONnet
- **IPv4 and IPv6**: Supports both protocol versions
- **Firewall Integration**: Works seamlessly with iptables/nftables and more
- **Embedded Ready**: Ideal for embedded environments such as OpenWrt routers

## Requirements

- OpenWrt 23.05.x or 24.10.x
- Supported architecture: x86_64, arm_cortex-a7, arm_cortex-a9, aarch64_cortex-a53, aarch64_cortex-a72

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

## License

reaction is open-source software – see the [original repository](https://framagit.org/ppom/reaction) for license details.
