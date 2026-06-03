[![OpenWrt](https://img.shields.io/badge/OpenWrt-25.12%20%7C%2024.10-darkgreen.svg)](https://openwrt.org/)
[![GitHub Release](https://img.shields.io/github/v/release/Zerogiven-OpenWRT-Packages/reaction)](https://github.com/Zerogiven-OpenWRT-Packages/reaction/releases)
[![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/Zerogiven-OpenWRT-Packages/reaction/total?color=blue)](https://github.com/Zerogiven-OpenWRT-Packages/reaction/releases)
[![GitHub Issues or Pull Requests](https://img.shields.io/github/issues/Zerogiven-OpenWRT-Packages/reaction)](https://github.com/Zerogiven-OpenWRT-Packages/reaction/issues)

*OpenWRT package for reaction*

# reaction

A lightweight log-monitoring and reaction daemon for OpenWrt.

`reaction` scans program outputs (e.g. SSH or web server logs) for repeated patterns and executes user-defined actions – commonly to block malicious hosts after multiple failed logins.

Compared to traditional tools like *fail2ban*, `reaction` focuses on simplicity, speed, and low resource usage.

[https://reaction.ppom.me](https://reaction.ppom.me)

[https://framagit.org/ppom/reaction](https://framagit.org/ppom/reaction)

## Features

- **Fast and Efficient**: Daemon written in Rust
- **Flexible Configuration**: Configurable via YAML or JSONnet
- **IPv4 and IPv6**: Supports both protocol versions

## Requirements

- OpenWrt 25.12 / 24.10

> **Note:** For OpenWrt 23.05, use reaction v2.2.x releases. Version 2.3.0+ requires a newer Rust toolchain not available in 23.05.

## Installation

### From Package Feed

You can set up this package feed to install and update via your router's package manager:

[https://github.com/Zerogiven-OpenWRT-Packages/package-feed](https://github.com/Zerogiven-OpenWRT-Packages/package-feed)

### From Release Files

Each release ships both `.ipk` (OpenWrt 24.10) and `.apk` (OpenWrt 25.12) artifacts.

**OpenWrt 25.12 (apk):**

```sh
apk add --allow-untrusted ./reaction-*.apk
```

**OpenWrt 24.10 (opkg):**

```sh
opkg install ./reaction_*.ipk
```

Add any plugin packages you need on the same line (see [Plugins](#plugins) below).

### From Source

```sh
git clone https://github.com/Zerogiven-OpenWRT-Packages/reaction.git package/reaction
make menuconfig  # Navigate to: Utilities → reaction (and any plugins you want)
make package/reaction/compile V=s
```

## Plugins

Upstream reaction supports a plugin architecture: each plugin is a separate long-running binary that the daemon spawns and communicates with over a Rust IPC channel ([remoc](https://crates.io/crates/remoc)). Plugins must be explicitly enabled in `/etc/reaction/plugins.jsonnet` before reaction will load them.

This package set ships the daemon plus four plugin packages, each as its own ipk/apk so you only install what you need:

| Package | Purpose | State |
| --- | --- | --- |
| `reaction` | Main daemon. Required. Pulls in init script and example configs. | Stable |
| `reaction-plugin-nftables` | Manage nftables IP sets directly via `libnftables` (FFI). Creates an `inet` table named `reaction`; each filter manages its own set. | Beta |
| `reaction-plugin-ipset` | Manage ipset sets directly via `libipset` (FFI). Upstream measures ~15× faster startup vs shelling out to the `ipset` CLI. | Stable |
<!-- | `reaction-plugin-virtual` | Example/test plugin with no real action. Also enables "second-level" streams – an action feeds another stream, e.g. for escalating bans on repeat offenders. | Alpha | -->
<!-- | `reaction-plugin-cluster` | Synchronise bans across multiple reaction instances over a peer-to-peer mesh. Useful if you run reaction on more than one router. | -->

## Usage

After installation the reaction service starts automatically with two active streams for SSH and LuCI.

**IMPORTANT**: Be aware that after installing you can lock yourself out if you try to login with wrong password more than 10 times. That's the reason why the number is so high by default. Change it for better security.

## Documentation

For complete configuration examples, usage guides, and advanced setup instructions, please refer to the main project resources:

- **Main website:** [https://reaction.ppom.me](https://reaction.ppom.me)
- **Source repository:** [https://framagit.org/ppom/reaction](https://framagit.org/ppom/reaction)
- **Wiki & examples:** [https://reaction.ppom.me/configurations](https://reaction.ppom.me/configurations)
