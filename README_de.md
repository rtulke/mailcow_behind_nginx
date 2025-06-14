# Mailcow hinter einem Nginx

Einrichtung einer Mailcow Container basierten Installation hinter einem Nginx Proxy

- Englische Version: [README.md](README.md)

# Inhaltsverzeichnis

1. [Mailcow hinter einem Nginx Reverse Proxy](#mailcow-hinter-einem-nginx-reverse-proxy)
2. [Vorbedingungen "Mailcow" Server](#vorbedingungen-mailcow-server)
3. [Was wird installiert und konfiguriert?](#was-wird-installiert-und-konfiguriert)
4. [Vorrausetzungen für die Installation](#vorrausetzungen-für-die-installation)
   - [Aktuelle Paket Repository Quellen Sicherstellen](#aktuelle-paket-repository-quellen-sicherstellen)
   - [System aktualisieren und Ansible, Docker-Compose und Git installieren](#system-aktualisieren-und-ansible-docker-compose-und-git-installieren)
5. [Standard Installation von Mailcow](#standard-installation-von-mailcow)
   - [Standard Installation von Docker und mailcow gemäss Anleitung](#standard-installation-von-docker-und-mailcow-gemäss-anleitung)
     - [Aktuelles Docker Installieren (als root)](#aktuelles-docker-installieren-als-root)
     - [mailcow Repository klonen (als root)](#mailcow-repository-klonen-als-root)
6. [Ansible Rolle "Mailcow behind Nginx"](#ansible-rolle-mailcow-behind-nginx)
   - [Funktionalitäten der Ansible Rolle](#funktionalitäten-der-ansible-rolle)
   - [Clonen des "mailcow_behind_nginx" Repositorys](#clonen-des-mailcow_behind_nginx-repositorys)
   - [Ansible Variablen für deinen Server anpassen](#ansible-variablen-für-deinen-server-anpassen)
   - [Ansible Playbook ausführen](#ansible-playbook-ausführen)
7. [Verzeichnisstruktur](#verzeichnisstruktur)
8. [Wichtige Pfade auf dem Server](#wichtige-pfade-auf-dem-server)
9. [Troubleshooting](#troubleshooting)
   - [SSL-Zertifikat Probleme](#ssl-zertifikat-probleme)
   - [Mailcow Status](#mailcow-status)
   - [Logs überprüfen](#logs-überprüfen)
   - [Container neustarten](#container-neustarten)
10. [Erweiterte Firewall Konfiguration](#erweiterte-firewall-konfiguration)
    - [Firewall anpassen (UFW)](#firewall-anpassen-ufw)
    - [Firewall anpassen (iptables)](#firewall-anpassen-iptables)
11. [Sicherheitshinweise](#sicherheitshinweise)
12. [Support](#support)

# Mailcow hinter einem Nginx Reverse Proxy

Dieses Ansible Playbook automatisiert die Installation und Konfiguration einer Mailcow-Instanz mit Nginx als Reverse Proxy, inklusive automatischer SSL-Zertifikat-Verwaltung über Let's Encrypt. Ich gehe in diesem Setup davon aus, das Du ein frisches APT-basiertes System vor Dir hast und Mailcow noch nicht installiert wurde.

Mailcow geht davon aus das man mailcow direkt auf einem eigenen dafür angedachten Mailserver (VM) installiert, das heisst es nicht direkt vorgesehen das man z.B. eigene Webseiten unterhalb des mailcow nginx Container betreibt auch wenn in der Beschreibung dokumentiert ist wie man eigene Seiten unterhalb der Domain mail.deinedomain.de betreiben könnte. 

Möchte man aber weitere Domainen betreiben und hat nur einen Server/VM zur Verfügung, ist es recht umständlich seine eigenen Seiten innerhalb des von mailcow bereitgestellten Nginx Containers diese zu betreiben. Dieses Setup ist speziell dafür gedacht, das man einen eigenen Nginx Server vor dem mailcow Nginx Container vorschaltet welcher dann die Anfragen entsprechend für Mailcow umeleitet. Somit ist es uns dann möglich innerhalb der eigenen Nginx Instanz unsere Domainen oder Webseiten zu betreiben.

## Vorbedingungen "Mailcow" Server

- Linux Server (Debian/Ubuntu empfohlen)
- Root-Zugriff oder sudo-berechtigt
- Öffentliche IP-Adresse vorhanden
- Domain z.B. mail.deinedomain.de zeigt auf Server-IP (Öffentliche IP)
- Ports 80, 443, 25, 465, 587, 993, 995 sind von aussen erreichbar


## Was wird installiert und konfiguriert?

- **Nginx Reverse Proxy** mit SSL-Terminierung
- **Mailcow Dockerized** Setup
- **Let's Encrypt** automatische Zertifikatserstellung
- **Automatische SSL-Synchronisation** zwischen Nginx und Mailcow
- **Security-optimierte Konfiguration**

## Vorrausetzungen für die Installation

Damit für die Installation nötige Vorraussetzungen geschaffen werden solltest Du verifizieren ob die hier im Bsp. angegeben Paketquellen (Debian/Ubuntu) vorhanden sind. Zudem werden wir Ansible, Git und Docker-Compose installieren.

### Aktuelle Paket Repository Quellen Sicherstellen

**Für Debian 12**

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

## Offical Debian Source Packages (bookworm 12)
# deb-src http://deb.debian.org/debian/ bookworm contrib main non-free non-free-firmware
# deb-src http://deb.debian.org/debian/ bookworm-updates contrib main non-free non-free-firmware
# deb-src http://deb.debian.org/debian/ bookworm-proposed-updates contrib main non-free non-free-firmware
# deb-src http://deb.debian.org/debian/ bookworm-backports contrib main non-free non-free-firmware
# deb-src http://deb.debian.org/debian-security/ bookworm-security contrib main non-free non-free-firmware
```

**Für Ubuntu 22.04**

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
*Weiterführende URLs*
- https://wiki.debianforum.de/Sources.list
- https://wiki.debian.org/SourcesList
- https://wiki.ubuntuusers.de/sources.list/


### System aktualisieren und Ansible, Docker-Compose und Git installieren
```bash
# Ubuntu/Debian 
sudo apt update && sudo apt upgrade -y
sudo apt install ansible git -y
sudo apt install docker-compose docker-compose-plugin -y
```

## Standard Installation von Mailcow

Die Installation basiert auf der Standard Installationsanleitung von Mailcow https://docs.mailcow.email/getstarted/install/#start-mailcow

### Standard Installation von Docker und mailcow gemäss Anleitung

Dieser Teil der Installation basiert im wesentlichen auf der originalen Installationsanleitung von Mailcow.

#### Aktuelles Docker Installieren (als root)

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
  0022     # <- Überprüfen ob umask 0022 gesetzt ist
cd /opt
git clone https://github.com/mailcow/mailcow-dockerized
cd mailcow-dockerized
```

## Ansible Rolle "Mailcow behind Nginx"

Die Ansible Rolle wird nun installiert und konfiguriert. Die Ansible Rolle wird die Konfiguration von Mailcow entsprechend anpassen und nginx als Service installieren (kein Container), so das dieser Nginx Service die Anfragen an den Mailcow nginx Container weiterleitet.

### Funktionalitäten der Ansible Rolle

**Nginx Reverse Proxy**
- **HTTP zu HTTPS Weiterleitung** für alle Anfragen
- **SSL-Terminierung** mit Let's Encrypt Zertifikaten  
- **Security Headers** für verbesserte Sicherheit
- **Proxy zu Mailcow** auf Port 8080
- **Optimierte Performance** Einstellungen

**SSL-Zertifikat Management**
- **Automatische Erstellung** von Let's Encrypt Zertifikaten
- **Cron-Job** für Zertifikat-Synchronisation (alle 12 Stunden)
- **Backup-System** für bestehende Zertifikate
- **Validierung** der Zertifikate vor Verwendung

**Mailcow Konfiguration**
- **Docker-basierte Installation** 
- **Reverse Proxy Modus** aktiviert
- **SSL-Integration** mit Nginx Zertifikaten
- **Service-Reload** bei Zertifikat-Updates

**Security Features**
- **Robuste SSL-Konfiguration** (TLS 1.2/1.3)
- **HSTS Header** für erweiterte Sicherheit
- **Firewall-freundliche** Port-Konfiguration
- **Sichere Dateiberechtigungen**

### Clonen des "mailcow_behind_nginx" Repositorys

```bash
cd /opt
git clone https://github.com/rtulke/mailcow_behind_nginx.git
cd mailcow_behind_nginx
```
### Ansible Variablen für deinen Server anpassen

Wir bearbeiten die Datei `/opt/mailcow_behind_nginx/vars.yml`

```bash
nano /opt/mailcow_behind_nginx/vars.yml
```

```yaml
# Deine Domain für den Mailserver
mail_domain_name: "mail.deinedomain.de"

# Admin Email für Let's Encrypt Benachrichtigungen
admin_email: "admin@deinedomain.de"

# Server Details (Nur nötig für Ansible Remote Installation)
target_server_ip: "111.111.111.111"  # (example: mail.deinedomain.de)
ansible_ssh_user: "root"
ssh_key_path: "~/.ssh/id_rsa"
```

**Inventory anpassen:**
```bash
# inventory/hosts.yml bearbeiten
# IP-Adresse und SSH-Details setzen
```

### Ansible Playbook ausführen

**Lokale Installation:**
```bash
ansible-playbook -i inventory/hosts.yml mailcow_setup.yml -e @vars.yml --connection=local
```

**Remote Installation**
```bash
ansible-playbook -i inventory/hosts.yml mailcow_setup.yml -e @vars.yml
```

**Mit spezifischem SSH Key**
```bash
ansible-playbook -i inventory/hosts.yml mailcow_setup.yml -e @vars.yml --private-key=~/.ssh/mailserver_key
```

## Verzeichnisstruktur

```
mailcow-ansible/
├── mailcow_setup.yml            # Haupt-Playbook
├── inventory/
│   └── hosts.yml                # Server-Inventar
├── group_vars/
│   └── mailserver.yml           # Gruppenvariablen
├── templates/
│   ├── nginx_mailcow.conf.j2    # Nginx Konfiguration
│   ├── nginx_http_only.conf.j2  # Nginx HTTP-only für certbot
│   └── ssl_sync.sh.j2           # SSL Sync Script
|   └── iptables-firewall.sh     # Iptables Firewall Script
├── vars.yml.example             # Beispiel-Variablen
├── vars.yml                     # Deine Variablen (erstellen)
└── README.md                    # Diese Anleitung
```

## Wichtige Pfade auf dem Server

| Komponente                | Pfad                                       |
|---------------------------|--------------------------------------------|
| Mailcow Installation      | `/opt/mailcow-dockerized`                  |
| Mailcow Ansible Setup     | `/opt/mailcow_behind_nginx`                |
| Nginx Konfiguration       | `/etc/nginx/sites-available/`              |
| Let's Encrypt Zertifikate | `/etc/letsencrypt/live/mail.domain.com/`   |
| Mailcow SSL Zertifikate   | `/opt/mailcow-dockerized/data/assets/ssl/` |
| SSL Sync Script           | `/usr/local/bin/ssl_sync.sh`               |
| Log Files                 | `/var/log/ssl_sync.log`                    |

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

## Erweiterte Firewall Konfiguration

Wenn Du keine Firewall im Einsatz hast oder verwenden möchtest ist es nicht zwingend nötig diese wie hier zu konfigurieren aber sicherlich sinvoll.

### Firewall anpassen (UFW)
Wenn Du die UFW Firewall verwendest benötigst Du folgenden zusätzliche Rules

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

# ssh rate limiting 6 connection/min. (optional)
sudo ufw delete allow 22/tcp
sudo ufw limit 22/tcp comment 'SSH rate limited'

# check status
sudo ufw status numbered
```

### Firewall anpassen (iptables)
Wenn Du die Netfilter/iptables Firewall verwendest, kannst Du mit dem iptables-firewall.sh Bash Script aus `/opt/mailcow_behind_nginx/templates/iptables-firewall.sh` die Ports festlegen. Zusätzlich zu den bestehenden Ports wird noch ein SSH rate limiting konfiguriert, welches so eingestellt ist, das max. 4 Verbindungen in der Minute erlaubt.

```bash
su - root
cd /opt/mailcow_behind_nginx/
chmod +x iptables-firewall.sh
./iptables-firewall.sh
systemctl enable netfilter-persistent    # persitent fw
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
