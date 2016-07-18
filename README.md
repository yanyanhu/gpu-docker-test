# GPU Docker Containerizer Testing on Mesos/Marathon

## Prerequisite

* Make sure your testing machine has docker installed and your docker binary path is `/usr/bin/docker`.
* Make sure your testing machine has at least 1 Nvidia GPU(s) with driver version `>352.39`. 
* Make sure your testing machine has `nvidia-docker-plugin` installed and running:
```
root@ubuntu-x86-gpu:~/liyubo/liyubobj/gpu-docker-test# ps -elf | grep nvidia-docker-plugin
5 S root      2646     1  0  80   0 - 16441 poll_s 04:32 pts/1    00:00:00 sudo -b nohup nvidia-docker-plugin
4 S root      2647  2646  0  80   0 - 8507711 ep_pol 04:32 pts/1  00:00:00 nvidia-docker-plugin
```
* Make sure `curl` and `make` commands available in your testing machine.

## Testing Mesos/Marathon with GPU

* Pull/Build zookeeper/Mesos/Marathon images

```
make build
```

* Setup clusters

```
make run-cluster
```

* Run GPU enabled jobs

**Run a task with 1 GPU request**

```
make run-task
```

**Check GPU exposed in the docker container**
```
root@ubuntu-x86-gpu:~/liyubo/liyubobj/gpu-docker-test# docker ps
CONTAINER ID        IMAGE                                     COMMAND                  CREATED             STATUS              PORTS               NAMES
e1cf4079e8eb        ubuntu:14.04                              "/bin/sh -c 'sleep 60"   4 seconds ago       Up 3 seconds                            mesos-6f8045ce-5f36-4556-883d-ba40d342f2e1-S0.966001b8-e2e3-4e1e-bd3f-1eeca200d887 
......
```

```
root@ubuntu-x86-gpu:~/liyubo/liyubobj/gpu-docker-test# docker inspect e1cf4079e8eb
[
......
    "HostConfig": {
......
        "Devices": [
            {
                "PathOnHost": "/dev/nvidiactl",
                "PathInContainer": "/dev/nvidiactl",
                "CgroupPermissions": "rwm"
            },
            {
                "PathOnHost": "/dev/nvidia-uvm",
                "PathInContainer": "/dev/nvidia-uvm",
                "CgroupPermissions": "rwm"
            },
            {
                "PathOnHost": "/dev/nvidia0",
                "PathInContainer": "/dev/nvidia0",
                "CgroupPermissions": "rwm"
            }
        ], 
......
    },
......
]
```
In current, we can not run `nvidia-smi` directly in the docker container because GPU driver volume injection has not been implemented for docker container. Will update once it is completed.

**Kill task**
```
make kill-task
```

* Shutdown cluster
```
make kill-cluster
```
