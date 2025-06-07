# Mailcow mit Nginx Reverse Proxy - Ansible Automation

Dieses Ansible Playbook automatisiert die Installation und Konfiguration einer Mailcow-Instanz mit Nginx als Reverse Proxy, inklusive automatischer SSL-Zertifikat-Verwaltung über Let's Encrypt.

## Überblick

Das Setup basiert auf dem Artikel von [wittamore.com](https://wittamore.com/articles/2025/Mailcow-with-Nginx-reverse-proxy.html) und implementiert:

- **Nginx Reverse Proxy** mit SSL-Terminierung
- **Mailcow Dockerized** Setup
- **Let's Encrypt** automatische Zertifikatserstellung
- **Automatische SSL-Synchronisation** zwischen Nginx und Mailcow
- **Security-optimierte Konfiguration**

## Voraussetzungen

### Lokales System
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y ansible git

# CentOS/RHEL/Rocky
sudo dnf install -y ansible git

# macOS
brew install ansible
```

### Zielserver
- Linux Server (Debian/Ubuntu empfohlen)
- Root-Zugriff oder sudo-berechtigt
- Öffentliche IP-Adresse
- Domain zeigt auf Server-IP
- Ports 80, 443, 25, 465, 587, 993, 995 erreichbar

## Installation

### 1. Repository klonen
```bash
git clone <repository-url>
cd mailcow-ansible
```

### 2. Verzeichnisstruktur erstellen
```bash
mkdir -p {inventory,group_vars,templates,vars}
```

### 3. Konfiguration anpassen

**vars.yml erstellen:**
```bash
cp vars.yml.example vars.yml
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
