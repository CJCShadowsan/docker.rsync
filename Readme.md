# Simple rsync container based on alpine

A simple rsync server/client Docker image to easily rsync data within Docker volumes

## Simple Usage

Get files from remote server within a `docker volume`:

    $ docker run --rm -v blobstorage:/data/ cjcshadowsan/rsync \
             rsync -avzx --numeric-ids user@remote.server.domain.or.ip:/var/local/blobs/ /data/

Get files from `remote server` to a `data container`:

    $ docker run -d --name data -v /data busybox
    $ docker run --rm --volumes-from=data cjcshadowsan/rsync \
             rsync -avz user@remote.server.domain.or.ip:/var/local/blobs/ /data/

Get files from `local server mounted in container` to a `remote server`:

    $ docker run -d --name data -v /data.you want to mount busybox
    $ docker run --net=host --rm --volumes-from=data cjcshadowsan/rsync \
             rsync -azrP user@remote.server.domain.or.ip:/var/local/blobs/ /data/

## Helper Script

A simple helper script that runs these commands is here, and if you alias it back to bash_aliases you can just run simple arguments to it like so:

    $ echo "rsync=/path/to/docker/rsync" >> ~/.bash_aliases
    $ rsync <command args - remember client and server are special args!>
    
## Advanced Usage

### Client setup

Start client to pack and sync every night:

    $ docker run --name=rsync_client -v client_vol_to_sync:/data \
                 -e CRON_TASK_1="0 1 * * * /data/pack-db.sh" \
                 -e CRON_TASK_2="0 3 * * * rsync -e 'ssh -p 2222' -aqx --numeric-ids root@foo.bar.com:/data/ /data/" \
             eeacms/rsync client

Copy the client SSH public key printed found in console

### SSH key persistence

To use the same generated keys on docker container re-creation, you need to persist the key directory ( `/root/.ssh` ) in a Docker volume. On first start the keys will be created, and then, on all subsequent starts they will be re-used.

For example, you can use a volume called `ssh-key` like this:

    $ docker run --name=rsync_client -v ssh-key:/root/.ssh -v client_vol_to_sync:/data
             eeacms/rsync client

### Server setup

Start server on `foo.bar.com`

    # docker run --name=rsync_server -d -p 2222:22 -v server_vol_to_sync:/data \
                 -e SSH_AUTH_KEY_1="<SSH KEY FROM rsync_client>" \
                 -e SSH_AUTH_KEY_n="<SSH KEY FROM rsync_client_n>" \
             eeacms/rsync server

### Verify that it works

Add `test` file on server:

    $ docker exec -it rsync_server sh
      $ touch /data/test

Bring the `file` on client:

    $ docker exec -it rsync_client sh
      $ rsync -e 'ssh -p 2222' -avz root@foo.bar.com:/data/ /data/
      $ ls -l /data/
      
### Rsync data between containers in Rancher

0. Request TCP access to port 2222 to an accessible server of environment of the new installation from the source container host server.

1. Start **rsync client** on host from where do you want to migrate data (ex. production). 

    Infrastructures -> Hosts ->  Add Container
    * Select image: eeacms/rsync
    * Command: sh
    * Volumes -> Volumes from: Select source container

2. Open logs from container, copy the ssh key from the message

2. Start **rsync server** on host from where do you want to migrate data (ex. devel). The destination container should be temporarily moved to an accessible server ( if it's not on one ) .

    Infrastructures -> Hosts ->  Add Container
    * Select image: eeacms/rsync
    * Port map -> +(add) : 2222:22
    * Command: server
    * Add environment variable: SSH_AUTH_KEY="<SSH-KEY-FROM-R-CLIENT-ABOVE>"
    * Volumes -> Volumes from: Select destination container


3. Within **rsync client** container from step 1 run:

  ```
    $ rsync -e 'ssh -p 2222' -avz <SOURCE_DUMP_LOCATION> root@<TARGET_HOST_IP_ON_DEVEL>:<DESTINATION_LOCATION>
  ```
  
4. The rsync servers can be deleted, and the destination container can be moved back ( if needed )
