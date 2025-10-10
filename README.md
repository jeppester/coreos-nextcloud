# CoreOS Nextcloud Setup

This project sets up a complete Nextcloud instance on Fedora CoreOS with SSL certificates, backups, and dynamic DNS using quadlets.

A big thanks to [Christian Glombek](https://github.com/LorbusChris) for his [quadlet nextcloud setup](https://github.com/LorbusChris/nextcloud-quadlet), without which I wouldn't have been able to get all this working.

## Prerequisites

- [Butane](https://coreos.github.io/butane/getting-started/)
- `virt-install` and KVM/QEMU for virtualization
- Domain name and DNS provider (Cloudflare recommended)
- S3-compatible storage for backups (AWS S3 or compatible service)

## Setup Instructions

### 1. Configure SSH Access

Copy the SSH authorized keys template and add your public keys:

```sh
cp authorized_keys.example authorized_keys
```

Edit `authorized_keys` and add your SSH public keys (one per line).

### 2. Configure Environment Variables

This setup requires several environment configuration files. Copy the example files and configure them according to your needs:

```sh
cp home/core/env/nextcloud.env.example home/core/env/nextcloud.env
cp home/core/env/acme-sh.env.example home/core/env/acme-sh.env
cp home/core/env/backup.env.example home/core/env/backup.env
cp home/core/env/ddns.env.example home/core/env/ddns.env
```

#### Nextcloud Configuration (`home/core/env/nextcloud.env`)

Configure your Nextcloud instance:

```env
NC_ADMIN_PASSWORD=[PASSWORD]
NC_TRUSTED_DOMAINS=[DOMAIN]
NC_TRUSTED_PROXIES=# I've not needed this
NC_DEFAULT_LANGUAGE=da
NC_DEFAULT_PHONE_REGION=DK
NC_DEFAULT_LOCALE=da_DK
NC_DEFAULT_TIMEZONE=Europe/Copenhagen
```

Have a look at [nextcloud-lifecycle.sh](home/core/nextcloud-lifecycle.sh) to see how these are put to use.

#### SSL Certificate Configuration (`home/core/env/acme-sh.env`)

Configure automatic SSL certificate generation using [acme.sh](https://github.com/acmesh-official/acme.sh/wiki/dnsapi)


For instance with Cloudflare:

```env
CF_Token=[CLOUDFLARE API TOKEN]
CF_Zone_ID=[CLOUDFLARE ZONE ID]
CA=letsencrypt
DOMAIN=[DOMAIN]
```

#### Backup Configuration (`home/core/env/backup.env`)

Configure automated backups to S3-compatible storage using [duplicity](https://duplicity.gitlab.io/):

```env
PASSPHRASE=[PASSWORD]
AWS_ACCESS_KEY_ID=[ACCESS KEY ID]
AWS_SECRET_ACCESS_KEY=[SECRET ACCESS KEY]
AWS_REGION=[S3 REGION, e.g.: us-east-1]
AWS_ENDPOINT_URL=[S3 ENDPOINT, e.g.: https://s3.us-east-1.amazonaws.com]
AWS_BUCKET=[BUCKET, e.g.: s3://bucketname]
FULL_IF_OLDER_THAN=1W # Do a full backup every week
REMOVE_OLDER_THAN=30D # Remove backups that are older than 30 days
KEEP_INCS_FOR_FULL_BACKUPS=2 # Keep incremental backups for 2 full backup cycles
VOLUME_SIZE=1024 # Size of backup volumes
```

See the [backup](home/core/backup.sh) and [restore](home/core/restore.sh) scripts for info on how these are used.

#### Dynamic DNS Configuration (`home/core/env/ddns.env`)

Configure automatic DDNS updates using [favonia's cloudflare-ddns tool](https://github.com/favonia/cloudflare-ddns):

```env
CF_API_TOKEN=[CLOUDFLARE API TOKEN]
DOMAINS=[DOMAIN]
PROXIED=false
IP6_PROVIDER=none
UPDATE_CRON=@once # DDNS updates are scheduled through systemd, see [cloudflare-ddns.timer](home/core/.config/systemd/user/cloudflare-ddns.timer)
```

### 3. Generate Ignition Configuration

Create the ignition file from the [Butane](https://coreos.github.io/butane/getting-started/) configuration:

```sh
butane -d . --pretty --strict butane.yaml > main.ign
```

### 4. Create Virtual Machine

Launch the Fedora CoreOS virtual machine:

```sh
virt-install --name=fcos --vcpus=3 --ram=4096 --os-variant=fedora-coreos-stable \
    --import --network=bridge=virbr0 --graphics=none \
    --qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${PWD}/main.ign" \
    --disk=size=95,backing_store=${PWD}/fedora-coreos.qcow2
```

### 4b. Install on bare metal

Note: While I personally prefer to buy old SFF PCs and then using them for self-hosting. Even if that is the end goal, virtual machines are however much easier to use for iterating on the configuration until everything works, so don't jump to bare metal installs until things look good.

I plug the SSD into a USB enclosure, then install Fedora Core OS directly to the drive with:
```sh
sudo coreos-installer install /dev/[DEVICE] \
    --ignition-file main.ign
```

When done the drive can then be installed in the server PC, the final setup will happen automatically when the system boots.

### 5. Set up ports

The server will run:

- Nextcloud on port **8000**
- Collabora Office on **9000**

If the server is directly connected to the internet (for instance if running in a cloud service) you should be able to access the server on these ports. Changing them isn't currently possible without making manual changes to the [envoy configuration](home/core/envoy.yaml). The changes should be fairly simple though.

If the server is running behind a router, port forwarding is needed in order to make it available to the internet.

**One important note before moving on**: If your ISP is using [Carrier-Grade NAT](https://en.wikipedia.org/wiki/Carrier-grade_NAT) it won't be possible to make your server available on the internet. You don't need to pay for a static IP, but you'll need a "real" IP address.

The recommended setup is to:
- Set a static IP-address for the server
- Forward external port 9000 to port 9000 on the server's IP
- Forward external port 433 to port 8000 on the server's IP

I cannot go into details about how to set this up in the router UI as every router has it's own UI.

With these forwards in place, the server should be reachable directly on the set up cloudflare domain, and Collabora office should be working as intended.
