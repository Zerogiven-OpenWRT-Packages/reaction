# reaction (OpenWRT package)

This package provides the **reaction** daemon for **OpenWRT 23.05** and **24.10**.

`reaction` is a lightweight log-monitoring and reaction daemon.  
It scans program outputs (e.g. SSH or web server logs) for repeated patterns and executes user-defined actions — commonly to block malicious hosts after multiple failed logins.

Compared to traditional tools like *fail2ban*, `reaction` focuses on simplicity, speed, and low resource usage.

## Features

- Fast and efficient daemon written in **Rust**
- Configurable via **YAML** or **JSONnet**
- Supports IPv4 and IPv6 rules
- Works seamlessly with `iptables` / `nftables`
- Ideal for embedded environments such as OpenWRT routers

## Installation

The package installs the `reaction` binary and integrates with **procd** for service management.  
After installation, configuration files are expected under `/etc/reaction`.


## Usage

After installation the reaction service automatically started but by default no jails/streams are activated. In this package there is a sample configuration for dropbear and luci
web interface. To activate them you have to rename the file streams file:

```bash
mv /etc/reaction/__DISABLED__streams.jsonnet /etc/reaction/streams.jsonnet

# restart the service
/etc/init.d/reaction restart
```

## Documentation

For complete configuration examples, usage guides, and advanced setup instructions, please refer to the main project resources:

- **Main website:** [https://reaction.ppom.me](https://reaction.ppom.me)  
- **Source repository:** [https://framagit.org/ppom/reaction](https://framagit.org/ppom/reaction)  
- **Wiki & examples:** [https://reaction.ppom.me/configurations](https://reaction.ppom.me/configurations)

## License

reaction is open-source software — see the original repository for license details.
