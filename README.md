# mailcow behind nginx

Setup Mailcow Container based installation behind a Nginx Proxy

German Version
- [README_de.md](README_de.md)


# Table of Contents

1. [Mailcow behind an Nginx Reverse Proxy](#mailcow-behind-an-nginx-reverse-proxy)
2. [Prerequisites "Mailcow" Server](#prerequisites-mailcow-server)
3. [What will be installed and configured?](#what-will-be-installed-and-configured)
4. [Prerequisites for Installation](#prerequisites-for-installation)
   - [Ensure Current Package Repository Sources](#ensure-current-package-repository-sources)
   - [Update System and Install Ansible, Docker-Compose and Git](#update-system-and-install-ansible-docker-compose-and-git)
5. [Standard Mailcow Installation](#standard-mailcow-installation)
   - [Standard Installation of Docker and Mailcow According to Guide](#standard-installation-of-docker-and-mailcow-according-to-guide)
     - [Install Current Docker (as root)](#install-current-docker-as-root)
     - [Clone mailcow Repository (as root)](#clone-mailcow-repository-as-root)
6. [Ansible Role "Mailcow behind Nginx"](#ansible-role-mailcow-behind-nginx)
   - [Functionalities of the Ansible Role](#functionalities-of-the-ansible-role)
   - [Clone the "mailcow_behind_nginx" Repository](#clone-the-mailcow_behind_nginx-repository)
   - [Adapt Ansible Variables for Your Server](#adapt-ansible-variables-for-your-server)
   - [Execute Ansible Playbook](#execute-ansible-playbook)
7. [Directory Structure](#directory-structure)
8. [Important Paths on the Server](#important-paths-on-the-server)
9. [Troubleshooting](#troubleshooting)
   - [SSL Certificate Problems](#ssl-certificate-problems)
   - [Mailcow Status](#mailcow-status)
   - [Check Logs](#check-logs)
   - [Restart Containers](#restart-containers)
10. [Advanced Firewall Configuration](#advanced-firewall-configuration)
    - [Adapt Firewall (UFW)](#adapt-firewall-ufw)
    - [Adapt Firewall (iptables)](#adapt-firewall-iptables)
11. [Security Notes](#security-notes)
12. [Support](#support)

# Mailcow behind an Nginx Reverse Proxy

This Ansible Playbook automates the installation and configuration of a Mailcow instance with Nginx as a reverse proxy, including automatic SSL certificate management via Let's Encrypt. I assume in this setup that you have a fresh APT-based system in front of you and Mailcow has not yet been installed.

Mailcow assumes that you install mailcow directly on its own dedicated mail server (VM), which means it's not directly intended to run your own websites under the mailcow nginx container, even though the documentation describes how you could run your own sites under the domain mail.yourdomain.com.

However, if you want to operate additional domains and only have one server/VM available, it's quite cumbersome to operate your own sites within the nginx container provided by mailcow. This setup is specifically designed to put your own Nginx server in front of the mailcow Nginx container, which then redirects requests accordingly for Mailcow. This makes it possible for us to operate our domains or websites within our own Nginx instance.

## Prerequisites "Mailcow" Server

- Linux Server (Debian/Ubuntu recommended)
- Root access or sudo privileges
- Public IP address available
- Domain e.g. mail.yourdomain.com points to server IP (Public IP)
- Ports 80, 443, 25, 465, 587, 993, 995 are accessible from outside

## What will be installed and configured?

- **Nginx Reverse Proxy** with SSL termination
- **Mailcow Dockerized** Setup
- **Let's Encrypt** automatic certificate creation
- **Automatic SSL synchronization** between Nginx and Mailcow
- **Security-optimized configuration**

## Prerequisites for Installation

To create the necessary prerequisites for the installation, you should verify whether the package sources (Debian/Ubuntu) given here as examples are available. Additionally, we will install Ansible, Git and Docker-Compose.

### Ensure Current Package Repository Sources

**For Debian 12**

```bash
cat /etc/apt/sources.list
```

```
## Official Debian Packages (bookworm 12)
deb http://deb.debian.org/debian/ bookworm contrib main non-free non-free-firmware
deb http://deb.debian.org/debian/ bookworm-updates contrib main non-free non-free-firmware
deb http://deb.debian.org/debian/ bookworm-proposed-updates contrib main non-free non-free-firmware
deb http://deb.debian.org/debian/ bookworm-backports contrib main non-free non-free-firmware
deb http://deb.debian.org/debian-security/ bookworm-security contrib main non-free non-free-firmware

## Official Debian Source Packages (bookworm 12)
# deb-src http://deb.debian.org/debian/ bookworm contrib main non-free non-free-firmware
# deb-src http://deb.debian.org/debian/ bookworm-updates contrib main non-free non-free-firmware
# deb-src http://deb.debian.org/debian/ bookworm-proposed-updates contrib main non-free non-free-firmware
# deb-src http://deb.debian.org/debian/ bookworm-backports contrib main non-free non-free-firmware
# deb-src http://deb.debian.org/debian-security/ bookworm-security contrib main non-free non-free-firmware
```

**For Ubuntu 22.04**

```bash
cat /etc/apt/sources.list
```

```
## Official Ubuntu Packages (jammy 22.04)
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse
deb http://archive.canonical.com/ubuntu/ jammy partner

## Official Ubuntu Sources Packages (jammy 22.04)
# deb-src http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
# deb-src http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
# deb-src http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
# deb-src http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse
# deb-src http://archive.canonical.com/ubuntu/ jammy partner
```
*Further URLs*
- https://wiki.debianforum.de/Sources.list
- https://wiki.debian.org/SourcesList
- https://wiki.ubuntuusers.de/sources.list/

### Update System and Install Ansible, Docker-Compose and Git
```bash
# Ubuntu/Debian 
sudo apt update && sudo apt upgrade -y
sudo apt install ansible git -y
sudo apt install docker-compose docker-compose-plugin -y
```

## Standard Mailcow Installation

The installation is based on the standard installation guide from Mailcow https://docs.mailcow.email/getstarted/install/#start-mailcow

### Standard Installation of Docker and Mailcow According to Guide

This part of the installation is essentially based on the original installation guide from Mailcow.

#### Install Current Docker (as root)

```bash
su - root
cd /opt
curl -sSL https://get.docker.com/ | CHANNEL=stable sh
systemctl enable --now docker
```

#### Clone mailcow Repository (as root)

```bash
su - root
umask 
  0022     # <- Check if umask 0022 is set
cd /opt
git clone https://github.com/mailcow/mailcow-dockerized
cd mailcow-dockerized
```

## Ansible Role "Mailcow behind Nginx"

The Ansible role will now be installed and configured. The Ansible role will adjust the configuration of Mailcow accordingly and install nginx as a service (not a container), so that this Nginx service forwards requests to the Mailcow nginx container.

### Functionalities of the Ansible Role

**Nginx Reverse Proxy**
- **HTTP to HTTPS redirection** for all requests
- **SSL termination** with Let's Encrypt certificates  
- **Security headers** for improved security
- **Proxy to Mailcow** on port 8080
- **Optimized performance** settings

**SSL Certificate Management**
- **Automatic creation** of Let's Encrypt certificates
- **Cron job** for certificate synchronization (every 12 hours)
- **Backup system** for existing certificates
- **Validation** of certificates before use

**Mailcow Configuration**
- **Docker-based installation** 
- **Reverse proxy mode** activated
- **SSL integration** with Nginx certificates
- **Service reload** on certificate updates

**Security Features**
- **Robust SSL configuration** (TLS 1.2/1.3)
- **HSTS headers** for enhanced security
- **Firewall-friendly** port configuration
- **Secure file permissions**

### Clone the "mailcow_behind_nginx" Repository

```bash
cd /opt
git clone https://github.com/rtulke/mailcow_behind_nginx.git
cd mailcow_behind_nginx
```

### Adapt Ansible Variables for Your Server

We edit the file `/opt/mailcow_behind_nginx/vars.yml`

```bash
nano /opt/mailcow_behind_nginx/vars.yml
```

```yaml
# Your domain for the mail server
mail_domain_name: "mail.yourdomain.com"

# Admin email for Let's Encrypt notifications
admin_email: "admin@yourdomain.com"

# Server details (only needed for Ansible remote installation)
target_server_ip: "111.111.111.111"  # (example: mail.yourdomain.com)
ansible_ssh_user: "root"
ssh_key_path: "~/.ssh/id_rsa"
```

**Adapt inventory:**
```bash
# Edit inventory/hosts.yml
# Set IP address and SSH details
```

### Execute Ansible Playbook

**Local installation:**
```bash
ansible-playbook -i inventory/hosts.yml mailcow_setup.yml -e @vars.yml --connection=local
```

**Remote installation:**
```bash
ansible-playbook -i inventory/hosts.yml mailcow_setup.yml -e @vars.yml
```

**With specific SSH key:**
```bash
ansible-playbook -i inventory/hosts.yml mailcow_setup.yml -e @vars.yml --private-key=~/.ssh/mailserver_key
```

## Directory Structure

```
mailcow-ansible/
├── mailcow_setup.yml          # Main playbook
├── inventory/
│   └── hosts.yml              # Server inventory
├── group_vars/
│   └── mailserver.yml         # Group variables
├── templates/
│   ├── nginx_mailcow.conf.j2  # Nginx configuration
│   └── ssl_sync.sh.j2         # SSL sync script
|   └── iptables-firewall.sh   # Iptables Firewall Script
├── vars.yml.example           # Example variables
├── vars.yml                   # Your variables (create)
└── README.md                  # This guide
```

## Important Paths on the Server

| Component                  | Path                                       |
|----------------------------|--------------------------------------------|
| Mailcow Installation       | `/opt/mailcow-dockerized`                  |
| Mailcow Ansible Setup      | `/opt/mailcow_behind_nginx`                |
| Nginx Configuration        | `/etc/nginx/sites-available/`              |
| Let's Encrypt Certificates | `/etc/letsencrypt/live/mail.domain.com/`   |
| Mailcow SSL Certificates   | `/opt/mailcow-dockerized/data/assets/ssl/` |
| SSL Sync Script            | `/usr/local/bin/ssl_sync.sh`               |
| Log Files                  | `/var/log/ssl_sync.log`                    |

## Troubleshooting

### SSL Certificate Problems
```bash
# Manual certificate check
sudo /usr/local/bin/ssl_sync.sh

# Check Let's Encrypt status
sudo certbot certificates

# Test Nginx configuration
sudo nginx -t
```

### Mailcow Status
```bash
cd /opt/mailcow-dockerized
sudo docker-compose ps
sudo docker-compose logs
```

### Check Logs
```bash
# SSL sync logs
sudo tail -f /var/log/ssl_sync.log

# Nginx logs
sudo tail -f /var/log/nginx/error.mail.domain.com.log
sudo tail -f /var/log/nginx/access.mail.domain.com.log
```

### Restart Containers
```bash
cd /opt/mailcow-dockerized
sudo docker-compose restart postfix-mailcow dovecot-mailcow
```

## Advanced Firewall Configuration

If you don't have a firewall in use or want to use one, it's not absolutely necessary to configure it as shown here, but it's certainly advisable.

### Adapt Firewall (UFW)
If you use the UFW firewall, you need the following additional rules

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 25/tcp
sudo ufw allow 465/tcp
sudo ufw allow 587/tcp
sudo ufw allow 993/tcp
sudo ufw allow 995/tcp
sudo ufw enable
sudo systemctl enable ufw

# SSH rate limiting 6 connections/min. (optional)
sudo ufw delete allow 22/tcp
sudo ufw limit 22/tcp comment 'SSH rate limited'

# Check status
sudo ufw status numbered
```

### Adapt Firewall (iptables)
If you use the Netfilter/iptables firewall, you can set the ports with the iptables-firewall.sh bash script from `/opt/mailcow_behind_nginx/templates/iptables-firewall.sh`. In addition to the existing ports, SSH rate limiting is also configured, which is set to allow a maximum of 4 connections per minute.

```bash
su - root
cd /opt/mailcow_behind_nginx/
chmod +x iptables-firewall.sh
./iptables-firewall.sh
systemctl enable netfilter-persistent    # Persistent firewall
```

## Security Notes

- Use **SSH keys** instead of passwords
- Configure and activate **firewall**
- Install **updates** regularly
- Create **backups** of Mailcow data
- Set up **monitoring** for unusual activities

## Support

In case of problems:
1. Check logs (`/var/log/ssl_sync.log`)
2. Run Ansible Playbook with `-vvv` for debug mode
3. Check Nginx and Docker service status
4. Consult Mailcow documentation
