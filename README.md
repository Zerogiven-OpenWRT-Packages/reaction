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

> After installation the reaction service automatically with two active streams for ssh and luci.

**IMPORTANT**: Be aware that after installing you lock out yourself if you try to login with wrong password more than 10 times. Thats the reason why the number is so high by default. Change it for better security.

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
