# Decidim Installation Guide 🗳️

This guide will help you install Decidim on your own server, even with minimal technical knowledge. We'll walk through everything from setting up a server to launching your democracy platform.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Create a Server](#step-1-create-a-server)
3. [Step 2: Connect to Your Server](#step-2-connect-to-your-server)
4. [Step 3: Configure DNS](#step-3-configure-dns)
5. [Step 4: Install Decidim](#step-4-install-decidim)
6. [Step 5: Configure Email (SMTP)](#step-5-configure-email-smtp)
7. [Step 6: Security & Firewall Setup](#step-6-security--firewall-setup)
8. [Step 7: Complete Setup](#step-7-complete-setup)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before you start, you'll need:

- **A domain name** (like `example.org`) - you can buy one from any domain registrar
- **Patience** - the installation takes about 20-30 minutes

### Server Requirements

**Minimum specifications:**
- **RAM**: 2GB minimum (4GB+ recommended for production)
- **Storage**: 20GB+
- **OS**: Ubuntu 24.04 (required)

**Recommended providers:**
- **Hetzner** - Used in this guide
- **Here Maps** - For geolocation features
- **SMTP Email Provider** - For sending emails (Gmail, Scaleway, Rapidmail, etc.)

---

## Step 1: Create a Server

We recommend using Hetzner for affordable, reliable hosting. Here's how to set up a server:

### 1.1 Create a Hetzner Account

1. Go to [hetzner.com](https://hetzner.com)
2. Click "Register" and create an account

This process might take some time until Hetzner verifies your account.

### 1.2 Create a New Server

1. Log into your Hetzner account
2. Click "Servers" → "Create Server"
3. **Server Location**: Choose a location near your users
4. **Server Type**:
   - Click "Shared" (cheaper option, perfect for small organizations)
   - Choose "CAX21"
5. **Image**: Select **Ubuntu 24.04** (important! or a newer LTS if available)
6. **SSH Key** (Recommended):
   - Create SSH key if you don't have one
   - If unsure, skip this and use password
7. **Server Name**: Give it a name like "decidim-server"
8. Click "Create & Buy Now"

**How to create an SSH key (if needed)**:

If you don't have an SSH key, create one on your local machine:

  ```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
  ```

This will generate a public/private key pair. Copy the contents of `~/.ssh/id_rsa.pub` and paste it into Hetzner's SSH key field.

### 1.3 Wait for Server to be Ready

Your server will be ready in 1-2 minutes. You'll see:
- Server IP address (e.g., `123.45.67.89`)
- Root password (if you chose password instead of SSH key)

**Save this information! You'll need it immediately.**

---

## Step 2: Connect to Your Server

### Option A: Using SSH Key (More Secure)

If you created an SSH key:
1. Open your terminal (Terminal on Mac, PowerShell on Windows)
2. Type: `ssh root@YOUR_SERVER_IP`
3. Replace `YOUR_SERVER_IP` with your actual IP address

### Option B: Using Password (Easier)

1. Open your terminal (Terminal on Mac, PowerShell on Windows)
2. Type: `ssh root@YOUR_SERVER_IP`
3. When prompted for password, paste the root password from Hetzner
4. It won't show characters while typing - that's normal!

**First time only**: You'll see a warning about "authenticity of host can't be established". Type `yes` and press Enter.

---

## Step 3: Configure DNS

Before installing Decidim, you need to point your domain to your server.

### 3.1 Find Your Server's IP Address

If you lost it, you can find it in the Hetzner dashboard for that server.

### 3.2 Update DNS Settings

Go to where you bought your domain (Namecheap, GoDaddy, etc.) and add these DNS records:

| Type | Host/Name | Value | TTL |
|------|-----------|-------|-----|
| A | @ | YOUR_SERVER_IP | auto |
| CNAME | www | @ | auto |

**Example**: If your server IP is `123.45.67.89` and your domain is `example.org` and you want the platform to be accessible in `decidim.example.org`, you would set:
- A record: `decidim.example.org` → `123.45.67.89`

### 3.3 Wait for DNS Propagation

DNS changes take 5-30 minutes to work worldwide. You can check if it's ready:
```bash
ping decidim.example.org
```

---

## Step 4: Install Decidim

Now for the main installation! Run these commands one by one on your server.

### 4.1 Download and Run the Installer

```bash
curl -fsSL https://decidim.org/install | bash
```

### 4.2 Follow the Prompts

The installer will ask for:

**Instance Information:**
- **Organization Name**: e.g., "City Hall Democracy Platform"
- **Domain**: e.g., `decidim.example.org` (must match your DNS setup)

**Database Configuration:**
- **Local Database** (Recommended): PostgreSQL with auto-generated credentials
- **External Database**: Only if you have your own database server

**Important Database Notes:**
- The installer creates a secure database user with random password
- Database URL is stored in `/opt/decidim/.env` file
- For production, consider regular backups of PostgreSQL

**File Storage:**
- **Local Storage** (Default): Perfect for most users
- **S3 Storage**: Only if you use Amazon S3

**Configuration Files Generated:**
- `.env`: Contains all your configuration (database, SMTP, secrets)
- `docker-compose.yml`: Defines services and networks
- **Important**: Never commit `.env` to version control - it contains passwords!

**Email Configuration** (Step 5 covers this in detail)

**SSL Certificate**: The installer will automatically set up free SSL certificates

---

## Step 5: Configure Email (SMTP)

Email is crucial for user notifications and password resets. You'll need an SMTP provider.

### 5.1 Choose an Email Provider

**Free Options**
- [Gmail SMTP](https://support.google.com/a/answer/176600) (500 emails/day limit)

**Paid Options**
- [Scaleway](https://www.scaleway.com/en/transactional-email-tem/)
- [Mailgun](https://mailgun.com)

### 5.2 Get SMTP Settings

Each provider will give you:
- **SMTP Server**: e.g., `smtp.sendgrid.net`
- **Port**: e.g., `587`
- **Username**: Your email or API key
- **Password**: Your password or API key
- **From Address**: e.g., `noreply@decidim.example.org`

### 5.3 Configure SMTP during Installation

When the installer asks for email settings, enter:
- **SMTP Host**: Your provider's SMTP server
- **SMTP Port**: 587 (most common)
- **SMTP Username**: Your SMTP username
- **SMTP Password**: Your SMTP password
- **From Email**: noreply@decidim.example.org
- **From Name**: Your Organization Name

---

## Step 6: Security & Firewall Setup

### 6.1 Firewall Configuration

The installer will configure firewall rules automatically. You can check the status:

```bash
# Check firewall status
sudo ufw status

# Allow SSH (don't lock yourself out!)
sudo ufw allow ssh

# Enable firewall if not already active
sudo ufw enable
```

### 6.2 SSL Certificate (Automatic)

The installer uses Traefik to handle SSL certificates automatically through Let's Encrypt:
- **Automatic renewal**: Certificates renew themselves
- **No manual intervention needed**
- **HTTPS enforced**: All traffic redirected to secure connections

If you experience SSL issues:
- Ensure your domain correctly points to the server IP
- Wait 5-10 minutes for DNS propagation
- Check that ports 80 and 443 are accessible from the internet

### 6.3 Security Best Practices

Based on the traditional Decidim setup experience:

1. **Never expose database**: Use firewalls and network segmentation
2. **Keep software updated**: Run updates regularly
3. **Use strong passwords**: For admin users and database
4. **Monitor logs**: Check for suspicious activity
5. **Backup regularly**: Database and configuration files

### 6.3 Email Domain Authentication

For better email deliverability, configure these DNS records (advanced):

- **SPF Record**: `v=spf1 include:_spf.google.com ~all` (if using Gmail)
- **DKIM**: Generate keys from your email provider
- **DMARC**: `v=DMARC1; p=quarantine; rua=mailto:dmarc@decidim.example.org`

## Step 7: Complete Setup

### 7.1 Create System Administrator

During installation, you'll be prompted to create a system admin:
- **Email**: Use your admin email
- **Password**: The installer will auto-generate a secure password
- **Save the password!** You'll need it to log in

### 7.2 Access Your Decidim Instance

1. Open your web browser
2. Go to `https://decidim.example.org/system`
3. Log in with:
   - Email: Your system admin email
   - Password: The password shown during installation

### 7.3 Configure Your Organization

Once logged in, you'll need to:
1. Set up your organization details
2. Create your first participatory space
3. Configure user registration settings

### 7.4 Background Jobs & Maintenance

The Docker setup includes automatic background job processing using Sidekiq. Here's what's running:

**Background Processing**:
- Sidekiq handles email sending and other background tasks
- Automatically restarts if it crashes
- Monitored and managed through Docker Compose

**To manually check Sidekiq jobs:**
```bash
# Check Sidekiq status
docker compose logs worker

# Restart Sidekiq if needed
docker compose restart sidekiq
```

---

## 🔧 Useful Commands

### Managing Your Decidim Instance

```bash
# Go to the Decidim directory
cd /opt/decidim

# View live logs
docker compose logs -f

# Stop Decidim
docker compose down

# Start Decidim
docker compose up -d

# Restart services
docker compose restart

# Check service status
docker compose ps
```

### Updating Decidim

```bash
cd /opt/decidim
git pull
docker compose pull
docker compose up -d
```

---

## Troubleshooting

### Common Issues

**"Connection refused" when connecting to server:**
- Wait 2-3 minutes after server creation
- Check that you're using the correct IP address
- Try `ping YOUR_SERVER_IP` first

**DNS not working:**
- Wait at least 30 minutes after changing DNS records
- Use `dig example.org` to check DNS
- Make sure A records point to your server IP
- Check records

**Email not sending:**
- Double-check SMTP settings in `/opt/decidim/.env`
- Verify your firewall allows port 587 outbound
- Check with your email provider about authentication
- **Gmail issues**: May need "App Password" if 2FA enabled
- Check for IPv6 conflicts (installer handles this automatically)

**Installation fails:**
- Run `./install.sh` again
- Check the error message carefully
- Check available disk space
- Verify internet connection

**Performance issues on low-memory servers:**
- **Memory optimization**: Consider upgrading to 4GB RAM for production
- **Monitor memory**: `free -h` to check usage
- **Check Docker resource limits**: `docker stats`

**SSL Certificate problems:**
- Domain must resolve to server IP before certificate issuance
- Port 80 and 443 must be accessible from internet
- Check Traefik logs: `docker compose logs traefik`
- Wait 5-10 minutes for certificate issuance

### Getting Help

- **Documentation**: [docs.decidim.org](https://docs.decidim.org)
- **Installation Issues**: [GitHub Issues](https://github.com/decidim/docker/issues)
- **Community**: [Decidim Community Forum](https://meta.decidim.org)
- **Alternative Installation**: [Platoniq Manual Guide](https://platoniq.github.io/decidim-install/) (comprehensive traditional setup)

## 🎯 Advanced Configuration Options

### Geolocation & Maps

For mapping features (meeting locations, proposals with addresses):

1. **Get HERE Maps API Key**:
   - Register at [HERE Developer Portal](https://developer.here.com/)
   - Create free account and get API credentials

2. **Configure in Decidim**:
   ```bash
   # Edit environment file
   nano /opt/decidim/.env
   # Add:
   # MAPS_API_KEY=your-here-api-key
   # MAPS_PROVIDER=here
   ```

3. **Restart services**:
   ```bash
   docker compose restart
   ```

### Important Files

After installation, your configuration is stored in:
- `/opt/decidim/.env` - **All your settings** (database, email, secrets) 🔐
- `/opt/decidim/docker-compose.yml` - Service definitions
- `/opt/decidim/storage/` - Persistent data (database, uploads, logs)

**🚨 Security Warning**:
- **Never commit `.env` to version control**
- **Keep backup of `.env` file in secure location**
- **Contains database passwords, SMTP credentials, and secret keys**

### Log Locations

For troubleshooting, check these logs:
```bash
# Application logs
docker compose logs -f decidim

# Database logs
docker compose logs -f db

# All services
docker compose logs -f
```

---

## 🎉 Congratulations!

You now have a fully functional Decidim instance running on your own server!

Your democracy platform is ready to:
- Accept user registrations
- Host discussions and debates
- Run participatory budgeting processes
- Enable collaborative decision-making

Remember to:
- Regularly update your server (`apt update && apt upgrade`)
- Back up your data
- Monitor your email deliverability
- Engage with your community!

Happy democracy building! 🗳️✨
