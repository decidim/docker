# Docker images for Decidim 
[![Docker Hub](https://img.shields.io/docker/cloud/build/eaudeweb/scratch?label=Docker%20Hub&style=flat)](https://hub.docker.com/u/decidim)
[![Github Container Registry](https://img.shields.io/docker/cloud/build/eaudeweb/scratch?label=Github%20Container%20Registry&style=flat)](https://github.com/orgs/decidim/packages)


# 5min Tutorial
Run an empty Decidim instance locally in 5min ⏱

## Local dependencies
In order to run this tutorial, you'll need the following local installations:

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

## See the magic

| URL | Description |
|---|---|
| [http://localhost:1080](http://localhost:1080) | ✉️ A Mailcatcher instance, all emails will be sent there |
| [http://localhost:3000](http://localhost:3000) | 🌱 Decidim instance |
| [http://localhost:3000/admin](http://localhost:3000/admin) | Decidim administration, your credentials are `admin@example.org`/`123456` |
| [http://localhost:3000/_queuedjobs](http://localhost:3000/_queuedjobs) | Monitoring Sidekiq jobs (emails and async tasks) |
| [http://localhost:3000/system](http://localhost:3000/system) | Decidim system, your credentials are `admin@example.org`/`123456` |

That's it, you've got your participatory platform!
Before deploying, be sure to read the [good practices](#good-practices).

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

## Run the Decidim with Nginx
```
  docker-compose -f quickstart.yml -f nginx.yml up
```

URLs stays the same… BUT:

- if you create a public/maintenance.html the app will display only the maintenance page.
- if you access an image, you won't see any logs in the rails, because it is served directly
- your app should load faster, even in development

## Eject you decidim instance
You want to publish your instance on github? You can copy all files of the decidim image in your local environment with `docker cp`

```
docker-compose -f quickstart.yml up -d
docker cp decidim:/home/decidim/app ready-to-publish # Wait the command finishes!
cd ready-to-publish && git init
# Follow github to upload this repo to github
```

# Environments configurations

| Env Name | Description | Default |
|---|---|---|
| SECRET_KEY_BASE | 🔐 Secret used to initialize application's key generator | `my-insecure-password` |
| RAILS_MASTER_KEY | 🔐 Used to decrypt credentials file | `my-insecure-password` |
| RAILS_FORCE_SSL | If rails should force SSL | `enabled` |
| RAILS_MAX_THREADS | How many threads rails can use | `5` |
| RAILS_SERVE_STATIC_FILES | If rails should be accountable to serve assets | `false` |
| RAILS_ASSET_HOST | If set, define the assets are loaded from (S3?) | `` |
| SIDEKIQ_CONCURRENCY | Concurrency for sidekiq worker. MUST be <= DATABASE_MAX_POOL_SIZE | `RAILS_MAX_THREADS` |
| DATABASE_MAX_POOL_SIZE | Max pool size for the database. | `RAILS_MAX_THREADS` |
| DATABASE_HOST | Host for the postgres database. | `pg` |
| DATABASE_USERNAME | Database user to connect | `example` |
| DATABASE_PASSWORD | Database user's password to connect | `my-insecure-password` |
| DATABASE_DATABASE | Database name | `decidim` |
| TZ | Timezone used | `Europe/Madrid` |
| CABLE_HOST | Redis host for cable | `host` |
| CABLE_USERNAME | Redis username for cable | `default` |
| CABLE_PASSWORD | 🔐 Redis password for cable | `insecure-password` |
| CABLE_DB | Redis database (should be a numerical) | `0` |
| CABLE_PORT | Redis port | `6379` |
| CACHE_HOST | Redis host for cache | `host` |
| CACHE_USERNAME | Redis username for cache | `default` |
| CACHE_PASSWORD | 🔐 Redis password for cache | `insecure-password` |
| CACHE_DB | Redis database (should be a numerical) | `0` |
| CACHE_PORT | Redis port | `6379` |
| JOB_HOST | Redis host for sidekiq (async tasks) | `redis` |
| JOB_USERNAME | Redis username for Sidekiq | `default` |
| JOB_PASSWORD | 🔐 Redis password for Sidekiq | `insecure-password` |
| JOB_DB | Redis database | `1` |
| SMTP_AUTHENTICATION | How rails should authenticate to SMTP | `plain`, `none` |
| SMTP_USERNAME | Username for SMTP | `my-participatory-plateform@iredmail.org` |
| SMTP_PASSWORD | 🔐 Password for SMTP | `my-insecure-password` |
| SMTP_ADDRESS | SMTP address | smtp.iredmail.org |
| SMTP_DOMAIN | SMTP [HELO Domain](https://www.ibm.com/docs/en/zos/2.2.0?topic=sc-helo-command-identify-domain-name-sending-host-smtp) | `iredmail` |
| SMTP_PORT | SMTP address port | `587` |
| SMTP_STARTTLS_AUTO | If TLS should start automatically | `enabled` |
| SMTP_VERIFY_MODE | How smtp certificates are verified | `none` |
| DECIDIM_SEED | Seed a local organization on startup | `1` |
| RUN_SIDEKIQ | If the container should run sidekiq | `1` |
| RUN_RAILS | If the container should run rails | `1` |

>  🔐: be sure to read the [good practices](#good-practices) ;)


All the `DECIDIM_` variables are also available. [See the documentation on default environments variables](https://github.com/decidim/decidim/blob/v0.27.0/docs/modules/configure/pages/environment_variables.adoc).
Here unsupported environments: 

| Env name | Why it is NOT supported |
| REDIS_URL | Our entrypoint wait on redis host before starting, we need thus to have host,port,username information. See `CACHE_*` `JOB_*` and `CABLE_*` environments. |
| RAILS_LOG_TO_STDOUT | Rails will always log to stdout, and log rotations and backup is handled by the process manager |




# Good Practices

## Choose a 64chars password for redis

> Redis internally stores passwords hashed with SHA256. If you set a password and check the output of ACL LIST or ACL GETUSER, you'll see a long hex string that looks pseudo random. […]
> Using SHA256 provides the ability to avoid storing the password in clear text while still allowing for a very fast AUTH command, which is a very important feature of Redis and is coherent with what clients expect from Redis.
> **However ACL passwords are not really passwords**. They are shared secrets between the server and the client, because the password is not an authentication token used by a human being. […]
> For this reason, slowing down the password authentication, in order to use an algorithm that uses time and space to make password cracking hard, is a very poor choice. What we suggest instead is to **generate strong passwords**, so that nobody will be able to crack it using a dictionary or a brute force attack even if they have the hash […]
> […] 64-byte alphanumerical string […] is long enough to avoid attacks and short enough to be easy to manage[…]
> Source: [_Redis Documentation_. ACL, Redis Access Control List, Key permissions. (visited 08/11/2022)](https://redis.io/docs/management/security/acl/)


## Consider using two redis instances (one for cache, the other one for job)
Sidekiq is used to send emails and do remote tasks. On heavy uses, you can have redis connection issues if use the 
same redis instance for caching and sidekiq. 

* Sidekiq redis should be configured as a persistent store (AOF)
* Cache and Cable redis should be configured as a cache store (RDB)

Read more on configuring redis persistence on the [Redis Documentation](https://redis.io/docs/management/persistence/)
Read more on the issue using [Redis Database on sidekiq:](https://github.com/mperham/sidekiq/wiki/Using-Redis#multiple-redis-instances)

## Don't run decidim with privilegied postgres user
A good practice is to run decidim with unpriviligied user (can not create table, truncate it or alter it). 
A common way to put this in practice is to have CI/CD deployment script (through github actions for example), where: 

- While deploying, deploy a temporary instance (sidecars) with priviliged database access. Migrate the database.
- Once `rails db:migrate:status` gives only `up` migrations, redeploy an instance without priviliged accesses.

**NB** running `rails db:migrate` while a rails application is running is most of the time a bad idea (connection to postgres can hangs). Always check `rails db:migrate:status` after a migraiton, to be sure all migration passed.

# Contribute
See [CONTRIBUTING.md](./CONTRIBUTING.md) for more informations.

# Local development
First of all clone this repository (`git clone git@github.com:decidim/docker.git decidim-docker`), and start playing!

[PR are Welcome](./CONTRIBUTING.md) ❤️ To check your changes, start a local development container, you can use theses docker-compose command:

| Label | Command | Decidim Version |
|---|---|---|
| Decidim 0.27 serving assets | `docker-compose -f quickstart.yml -f quickstart.local-027.yml up` | `0.27.0` | 
| Decidim 0.26 serving assets | `docker-compose -f quickstart.yml -f quickstart.local-026.yml up` | `0.26.3` |

To test newer or older versions of Decidim, please execute `./version.sh` to generate a `versions.csv` displaying the docker args to
apply to your Dockerfile. Here an example of output

| Decidim Version | Decidim Major Version | Decidim minor version | Alpine-friendly Node version | Alpine-friendly Ruby version |
|---|---|---|---|---|
| 0.27.2 | 0 | 27 | 16.9.1 | 3.0.5 |
| 0.26.4 | 0 | 26 | 16.9.1 | 2.7.5 |
| 0.25.2 | 0 | 25 | 16.9.1 | 2.7.5 |
| 0.24.3 | 0 | 24 | 14.16.1 | 2.7.5 |

# License
This repository is under [GNU AFFERO GENERAL PUBLIC LICENSE, V3](./LICENSE).
