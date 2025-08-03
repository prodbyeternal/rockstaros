# rockstaros
RockStar OS - Tool for Red Star OS 3.0 ≪붉은별≫

<img src=https://github.com/prodbyeternal/rockstaros/blob/main/header.png?raw=true></img>

RockstarOS is a utility designed for an already **modified Red Star OS 3.0** — specifically one that has:
- A swapped (custom) Linux kernel
- The **Nix** package manager pre-installed

This utility installs **[Bedrock Linux](https://bedrocklinux.org/)** on top of Red Star OS and applies all necessary tweaks to ensure Bedrock boots properly.  
It also makes it easier to integrate **multiple package managers** into Red Star OS, breaking free from its original restrictions.

---

## ⚠️ You Must Be Root

> **Warning**  
> You must run the installer as **root**.  
> Failure to do so will result in the installation not working as expected.  
> In other words: *`rootsetting and su` is your friend.*

---

## Installation

```bash
git clone https://github.com/yourusername/rockstaros.git
cd rockstaros
sudo ./rockstar.sh

