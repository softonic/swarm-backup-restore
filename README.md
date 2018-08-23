# DEPRECATED
This is not maintained anymore, as it's based in DAB files, which is something deprecated for Swarm clusters.

# Swarm Backup and Restore System
[![](https://images.microbadger.com/badges/image/softonic/swarm-backup-restore.svg)](https://microbadger.com/images/softonic/swarm-backup-restore "Get your own image badge on microbadger.com") [![](https://images.microbadger.com/badges/version/softonic/swarm-backup-restore.svg)](https://microbadger.com/images/softonic/swarm-backup-restore "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/commit/softonic/swarm-backup-restore.svg)](https://microbadger.com/images/softonic/swarm-backup-restore "Get your own commit badge on microbadger.com")

This project allows you to get scheduled backups from you swarm cluster and restore them.

It uses [whaleprint](https://github.com/mantika/whaleprint) to export data from a cluster and restore it so it has the same limitations.

## How it Works
The container should be scheduled to be executed like a cron with the  `--restart-delay` and `--restart-max-attempts` options.

Every time the container is executed it will export all the cluster services in [DAB files](https://github.com/docker/docker/blob/master/experimental/docker-stacks-and-bundles.md) and these will be uploaded to the configured S3. That file is a snapshot of current services running in our cluster and their configurations, so we can restore that services in any moment.

## Requirements
* Docker >=1.13

## Limitations
* It doesn't work with services that use mount volumes.
* It doesn't work properly with services that doesn't use stack because when they are recreated they have "services" prefixed to the service name so it can provoke errors.
* It doesn't backup the secrets.

## How to run the service

### Backup
The service needs to be deployed in a node with access to the docker socket (unix or tcp).

Example:
```
docker \
    service create --name docker-swarm-backup \
      --limit-memory 70m \
      --limit-cpu 0.5 \
      --container-label com.docker.stack.namespace=swarm-management \
      --label com.docker.stack.namespace=swarm-management \
      --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
      --restart-delay 3600s \
      --restart-max-attempts 87600 \
      -e BUCKET=my_bucket \
      -e REGION=s3-eu-west-1 \
      -e NAMESPACE=backup \
      -e AWS_ACCESS_KEY_SECRET=aws-access-key \
      -e AWS_KEY_ID_SECRET=aws-key-id \
      -e IGNORE_STACKS=stack1,stack2,stack3 \
      --secret aws-access-key \
      --secret aws-key-id \
      softonic/swarm-backup-restore
```

### Restore
This should be executed when you want to restore the cluster. Due to the usage of secret, we need to create service, but this service should be removed after it did its work to avoid an infinite cluster restore (every hour in the example).

```
docker \
    service create --name docker-swarm-restore \
      --limit-memory 70m \
      --limit-cpu 0.5 \
      --container-label com.docker.stack.namespace=swarm-management \
      --label com.docker.stack.namespace=swarm-management \
      --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
      --restart-delay 3600s \
      --restart-max-attempts 87600 \
      -e BUCKET=my_bucket \
      -e REGION=s3-eu-west-1 \
      -e NAMESPACE=backup \
      -e AWS_ACCESS_KEY_SECRET=aws-access-key \
      -e AWS_KEY_ID_SECRET=aws-key-id \
      -e IGNORE_STACKS=stack1,stack2,stack3 \
      --secret aws-access-key \
      --secret aws-key-id \
      softonic/swarm-backup-restore /app/restore.sh "URL_WITH_BACKUP"
docker service rm docker-swarm-restore
```

## How to build the image
```
docker build \
  --build-arg version=$(git describe —tags) \
  --build-arg commit_hash=$(git rev-parse HEAD) \
  --build-arg vcs_url=$(git config --get remote.origin.url) \
  --build-arg vcs_branch=$(git rev-parse --abbrev-ref HEAD) \
  --build-arg build_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  -t softonic/swarm-backup-restore:$(git describe —tags) . 
```

## How to execute it in development
First of all you need to modify the `docker-compose.yml` and set the right environment variables. After that you just need to run the following commands.
```
docker-compose up -d
docker-compose exec backup bash
```
From here you can execute the shell script `backup.sh`.


# TODO
* Review errors in restore related with networks.
* Improve restore to pass the object as argument instead of the signed url.
