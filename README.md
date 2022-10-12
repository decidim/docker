# Docker images for Decidim 
[![Docker Hub](https://img.shields.io/docker/cloud/build/eaudeweb/scratch?label=Docker%20Hub&style=flat)](https://hub.docker.com/u/decidim)
[![Github Container Registry](https://img.shields.io/docker/cloud/build/eaudeweb/scratch?label=Github%20Container%20Registry&style=flat)](https://github.com/orgs/decidim/packages)


# 5min Tutorial
Run an empty decidim instance locally in 5min ⏱

## Local dependancies
You need to run this tutorial the following local installations:

* bash
* [docker](https://docs.docker.com/get-docker/)
  * If you haven't the desktop version of docker, you need to install [docker-compose](https://docs.docker.com/compose/install/) as well.

And now, check you have all of this in your terminal:
```
bash --version
docker --version # should be 20.*
docker-compose --version # 1.29.* is fine
```

## Get the docker-compose
In an empty directory, download the [quickstart](https://raw.githubusercontent.com/decidim/docker/master/quickstart.yml) docker-compose.

```
mkdir my-participatory-platform
cd my-participatory-platform
curl https://raw.githubusercontent.com/decidim/docker/master/quickstart.yml > quickstart.yml
```

## Run the docker-compose

```
docker-compose -f quickstart.yml up
```

## See the magics

| URL | Description |
|---|---|
| [http://localhost:1080](http://localhost:1080) | ✉️ A Mailcatcher instance, all emails will be send there |
| [http://localhost:3000](http://localhost:3000) | 🌱 Decidim instance |
| [http://localhost:3000/admin](http://localhost:3000/admin) | Decidim administration, your credentials are `admin@example.org`/`123456` |
| [http://localhost:3000/system](http://localhost:3000/system) | Decidim system, your credentials are `admin@example.org`/`123456` |
| [http://localhost:3000/system](http://localhost:3000/_queues) | Sidekiq monitor, login with your decidim system credentials |

That's it, you've got your participatory plateform!
Before deploying, be sure to read the good practices.

# Reverse proxy

After doing the 5min Tutorial, you may wonder how to setup a reverse-proxy in front of your rails application to improve
security and performance. 

## Download the nginx.yml docker-compose
In your platform directory, download the [nginx](https://raw.githubusercontent.com/decidim/docker/master/nginx.yml) docker-compose and [nginx.conf](https://raw.githubusercontent.com/decidim/docker/master/nginx.conf) configuration

```
mkdir my-participatory-platform
cd my-participatory-platform
curl https://raw.githubusercontent.com/decidim/docker/master/nginx.yml > nginx.yml
curl https://raw.githubusercontent.com/decidim/docker/master/nginx.conf > nginx.conf
```

## Run the decidim with Nginx
```
  docker-compose -f quickstart.yml -f nginx.yml up
```

Urls stays the same… BUT:

- if you create a public/maintenance.html the app will display only the maintenance page.
- if you access an image, you won't see any logs in the rails, because it is served directly
- your app should load faster, even in development

# Environments configurations

| Env Name | Description | Default |
|---|---|---|
| SECRET_KEY_BASE | 🔐 Secret used to initialized application's key generator | `my-insecure-password` |
| RAILS_MASTER_KEY | 🔐 Used to decrypt credentials file | `my-insecure-password` |
| RAILS_FORCE_SSL | If rails should force SSL | `enabled` |
| RAILS_SERVE_STATIC_FILES | If rails should be accountable to serve assets | `false` |
| DATABASE_HOST | Host for the postgres database. | `pg` |
| DATABASE_USERNAME | Database user to connect | `example` |
| DATABASE_PASSWORD | Database user's password to connect | `my-insecure-password` |
| DATABASE_DATABASE | Database name | `decidim` |
| TZ | Timezone used | `Europe/Madrid` |
| CACHE_HOST | Redis host for cache | `host` |
| CACHE_USERNAME | Redis username for cache | `default` |
| CACHE_PASSWORD | 🔐 Redis password for cache | `insecure-password` |
| CACHE_DB | Redis database (should be a numerical) | `0` |
| CACHE_PORT | Redis port | `6379` |
| JOB_HOST | Redis host for sidekiq (async tasks) | `redis` |
| JOB_USERNAME | Redis username for sidekiq | `default` |
| JOB_PASSWORD | 🔐 Redis password for sidekiq | `insecure-password` |
| JOB_DB | Redis database | `1` |
| DECIDIM_DEFAULT_LOCALE | Default locale for decidim | `fr` |
| DECIDIM_AVAILABLE_LOCALES | Available locales for decidim | `en,pt-BR` |
| DECIDIM_CURRENCY_UNIT | Unit for the instance | `CHF` |
| DECIDIM_LOG_LEVEL | Log level for instance | `warn` |
| SMTP_AUTHENTICATION | How rails should authenticate to SMTP | `plain`, `none` |
| SMTP_USERNAME | Username for SMTP | `my-participatory-plateform@iredmail.org` |
| SMTP_PASSWORD | 🔐 Password for SMTP | `my-insecure-password` |
| SMTP_ADDRESS | SMTP address | smtp.iredmail.org |
| SMTP_DOMAIN | SMTP [HELO Domain](https://www.ibm.com/docs/en/zos/2.2.0?topic=sc-helo-command-identify-domain-name-sending-host-smtp) | `iredmail` |
| SMTP_PORT | SMTP address port | `587` |
| SMTP_STARTTLS_AUTO | If TLS should start automatically | `enabled` |
| SMTP_VERIFY_MODE | How smtp certificates are verificated | `none` |


> 🔐: be sure to read the good practices ;)




# Good Practices

## Choose a 64chars password for redis
TODO: summary [this](https://redis.io/docs/manual/security/acl/#how-passwords-are-stored-internally)

## Consider using two redis instances (one for cache, the other one for job)
TODO: summary [this](https://github.com/mperham/sidekiq/wiki/Using-Redis#multiple-redis-instances)

## Don't run decidim with privilegied postgres user
