# Swarm Backup and Restore System
This system allow you to get scheduled backups from you swarm cluster and restore it.

This project uses [whaleprint](https://github.com/mantika/whaleprint) to export data fom cluster and restore it.

## Requirements
* Docker >=1.13

## How to run the service

The service needs to be deployed in a node with access to the docker socket (unix or tcp).

Example:
```
docker \
    service create --name docker-swarm-backup \
      --limit-memory 20m \
      --limit-cpu 0.5 \
      --container-label com.docker.stack.namespace=swarm-management \
      --label com.docker.stack.namespace=swarm-management \
      --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
      --restart-delay 3600s \
      --restart-max-attempts 87600 \
      -e BUCKET=my_bucket
      -e REGION=s3-eu-west-1
      -e AWS_ACCESS_KEY_SECRET=aws-access-key
      -e AWS_KEY_ID_SECRET=aws-key-id
      -e IGNORE_STACKS=stack1,stack2,stack3
      --secret aws-access-key \
      --secret aws-key-id \
      softonic/swarm-backup-restore
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