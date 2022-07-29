#!/usr/bin/env bash

sudo docker run -it --name=rsync-docker --privileged --rm \
  --network=host \
  -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
  -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
  -v $(pwd):/data \
ghcr.io/cjcshadowsan/docker.rsync:master "$@"
