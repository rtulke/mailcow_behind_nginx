# Inhalt

1. [Mailcow mit Nginx Reverse Proxy](#Mailcow-mit-Nginx-Reverse-Proxy)
2. [Überblick](#Überblick)
3. [Voraussetzungen](#Voraussetzungen)
4. [Aktuelle Paket Repository Quellen Sicherstellen](#Aktuelle-Paket-Repository-Quellen-Sicherstellen)
5. [System aktualisieren und Ansible als auch Git installieren](#System-aktualisieren-und-Ansible-als-auch-Git-installieren)
6. [Output Formats](#output-formats)
7. [Performance Optimization](#performance-optimization)
8. [Advanced Features](#advanced-features)
9. [Troubleshooting](#troubleshooting)
12. [Examples](#examples)
13. [Reference Proxy-Lists](#Reference-Proxy-Lists)

# Mailcow mit Nginx Reverse Proxy

Dieses Ansible Playbook automatisiert die Installation und Konfiguration einer Mailcow-Instanz mit Nginx als Reverse Proxy, inklusive automatischer SSL-Zertifikat-Verwaltung über Let's Encrypt. Wir gehen hier davon aus das ihr ein frisches System habt und Mailcow noch nicht installiert wurde!

## Überblick

- **Nginx Reverse Proxy** mit SSL-Terminierung
- **Mailcow Dockerized** Setup
- **Let's Encrypt** automatische Zertifikatserstellung
- **Automatische SSL-Synchronisation** zwischen Nginx und Mailcow
- **Security-optimierte Konfiguration**

## Voraussetzungen

### Aktuelle Paket Repository Quellen Sicherstellen

- https://wiki.debianforum.de/Sources.list
- https://wiki.debian.org/SourcesList
- https://wiki.ubuntuusers.de/sources.list/

```bash
cat /etc/apt/sources.list
```

**Für Debian 12**
```
## Official Debian Packages (bookworm 12)
deb http://deb.debian.org/debian/ bookworm contrib main non-free non-free-firmware
deb http://deb.debian.org/debian/ bookworm-updates contrib main non-free non-free-firmware
deb http://deb.debian.org/debian/ bookworm-proposed-updates contrib main non-free non-free-firmware
deb http://deb.debian.org/debian/ bookworm-backports contrib main non-free non-free-firmware
deb http://deb.debian.org/debian-security/ bookworm-security contrib main non-free non-free-firmware

## Offical Debian Source Packages (bookworm 12)
# deb-src http://deb.debian.org/debian/ bookworm contrib main non-free non-free-firmware
# deb-src http://deb.debian.org/debian/ bookworm-updates contrib main non-free non-free-firmware
# deb-src http://deb.debian.org/debian/ bookworm-proposed-updates contrib main non-free non-free-firmware
# deb-src http://deb.debian.org/debian/ bookworm-backports contrib main non-free non-free-firmware
# deb-src http://deb.debian.org/debian-security/ bookworm-security contrib main non-free non-free-firmware
```

**Für Ubuntu 22.04**
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
### System aktualisieren und Ansible als auch Git installieren
```bash
# Ubuntu/Debian 
sudo apt update && sudo apt upgrade -y && sudo apt install -y ansible git
```

## Vorbedingungen "Mailcow" Server

- Linux Server (Debian/Ubuntu empfohlen)
- Root-Zugriff oder sudo-berechtigt
- Öffentliche IP-Adresse vorhanden
- Domain z.B. mail.deinedomain.de zeigt auf Server-IP (Öffentliche IP)
- Ports 80, 443, 25, 465, 587, 993, 995 sind von aussen erreichbar

## Installation

Die Installation basiert auf der Standard Installationsanleitung von Mailcow https://docs.mailcow.email/getstarted/install/#start-mailcow

### Standard Installation von Docker und mailcow gemäss Anleitung

#### Docker Installieren (als root)

```bash
su - root
cd /opt
curl -sSL https://get.docker.com/ | CHANNEL=stable sh
systemctl enable --now docker
```

#### mailcow Repository klonen (als root)

```bash
su - root
umask
0022     # <- Verify it is 0022
cd /opt
git clone https://github.com/mailcow/mailcow-dockerized
cd mailcow-dockerized
```

### Installation der Ansible Rolle welche die Installation von Mailcow hinter einem Nginx Proxy übernimmt

Mailcow geht davon aus das man mailcow direkt auf einem eigenen dafür angedachten Mailserver (VM) installiert, das heisst es nicht direkt vorgesehen das man z.B. eigene Webseiten unterhalb des mailcow nginx Container betreibt. Hat man aber nur einen Server/VM zur Verfügung ist es recht umständlich seine eigenen Seiten innerhalb des von mailcow bereitgestellten Nginx Containers zu betreiben. Dieses Setup ist speziell dafür gedacht, das man einen eigenen Nginx Server vor dem mailcow Nginx Container vorschaltet welcher dann die Anfragen entsprechend für Mailcow umeleitet.

#### Setup Mailcow hinter einem Nginx Proxy

```bash
cd /opt
git clone https://github.com/rtulke/mailcow_behind_nginx_proxy.git
```


**vars.yml bearbeiten:**
```yaml
# Deine Domain für den Mailserver
mail_domain_name: "mail.deine-domain.com"

# Admin Email für Let's Encrypt Benachrichtigungen
admin_email: "admin@deine-domain.com"

# Server Details (für Remote Installation)
target_server_ip: "192.168.1.100"
ansible_ssh_user: "root"
ssh_key_path: "~/.ssh/id_rsa"
```

**Inventory anpassen:**
```bash
# inventory/hosts.yml bearbeiten
# IP-Adresse und SSH-Details setzen
```

### 4. Playbook ausführen

**Lokale Installation:**
```bash
ansible-playbook -i inventory/hosts.yml mailcow_setup.yml \
  -e @vars.yml \
  --connection=local
```

**Remote Installation:**
```bash
ansible-playbook -i inventory/hosts.yml mailcow_setup.yml \
  -e @vars.yml
```

**Mit spezifischem SSH-Key:**
```bash
ansible-playbook -i inventory/hosts.yml mailcow_setup.yml \
  -e @vars.yml \
  --private-key=~/.ssh/mailserver_key
```

## Funktionalitäten

### Nginx Reverse Proxy
- **HTTP zu HTTPS Weiterleitung** für alle Anfragen
- **SSL-Terminierung** mit Let's Encrypt Zertifikaten  
- **Security Headers** für verbesserte Sicherheit
- **Proxy zu Mailcow** auf Port 8080
- **Optimierte Performance** Einstellungen

### SSL-Zertifikat Management
- **Automatische Erstellung** von Let's Encrypt Zertifikaten
- **Cron-Job** für Zertifikat-Synchronisation (alle 12 Stunden)
- **Backup-System** für bestehende Zertifikate
- **Validierung** der Zertifikate vor Verwendung

### Mailcow Konfiguration
- **Docker-basierte Installation** 
- **Reverse Proxy Modus** aktiviert
- **SSL-Integration** mit Nginx Zertifikaten
- **Service-Reload** bei Zertifikat-Updates

### Security Features
- **Robuste SSL-Konfiguration** (TLS 1.2/1.3)
- **HSTS Header** für erweiterte Sicherheit
- **Firewall-freundliche** Port-Konfiguration
- **Sichere Dateiberechtigungen**

## Verzeichnisstruktur

```
mailcow-ansible/
├── mailcow_setup.yml          # Haupt-Playbook
├── inventory/
│   └── hosts.yml              # Server-Inventar
├── group_vars/
│   └── mailserver.yml         # Gruppenvariablen
├── templates/
│   ├── nginx_mailcow.conf.j2  # Nginx Konfiguration
│   └── ssl_sync.sh.j2         # SSL Sync Script
├── vars.yml.example           # Beispiel-Variablen
├── vars.yml                   # Deine Variablen (erstellen)
└── README.md                  # Diese Anleitung
```

## Wichtige Pfade auf dem Server

| Komponente | Pfad |
|------------|------|
| Mailcow Installation | `/opt/mailcow-dockerized` |
| Nginx Konfiguration | `/etc/nginx/sites-available/` |
| Let's Encrypt Zertifikate | `/etc/letsencrypt/live/mail.domain.com/` |
| Mailcow SSL Zertifikate | `/opt/mailcow-dockerized/data/assets/ssl/` |
| SSL Sync Script | `/usr/local/bin/ssl_sync.sh` |
| Log Files | `/var/log/ssl_sync.log` |

## Troubleshooting

### SSL-Zertifikat Probleme
```bash
# Manueller Zertifikat-Check
sudo /usr/local/bin/ssl_sync.sh

# Let's Encrypt Status prüfen
sudo certbot certificates

# Nginx Konfiguration testen
sudo nginx -t
```

### Mailcow Status
```bash
cd /opt/mailcow-dockerized
sudo docker-compose ps
sudo docker-compose logs
```

### Logs überprüfen
```bash
# SSL Sync Logs
sudo tail -f /var/log/ssl_sync.log

# Nginx Logs
sudo tail -f /var/log/nginx/error.mail.domain.com.log
sudo tail -f /var/log/nginx/access.mail.domain.com.log
```

### Container neustarten
```bash
cd /opt/mailcow-dockerized
sudo docker-compose restart postfix-mailcow dovecot-mailcow
```

## Erweiterte Konfiguration

### Firewall anpassen
```bash
# UFW Beispiel
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 25/tcp
sudo ufw allow 465/tcp
sudo ufw allow 587/tcp
sudo ufw allow 993/tcp
sudo ufw allow 995/tcp
sudo ufw enable
```

## Sicherheitshinweise

- **SSH-Keys** statt Passwörter verwenden
- **Firewall** konfigurieren und aktivieren
- **Updates** regelmäßig installieren
- **Backups** der Mailcow-Daten erstellen
- **Monitoring** für ungewöhnliche Aktivitäten einrichten

## Support

Bei Problemen:
1. Logs überprüfen (`/var/log/ssl_sync.log`)
2. Ansible Playbook mit `-vvv` für Debug-Modus ausführen
3. Nginx und Docker Service Status prüfen
4. Mailcow Documentation konsultieren
