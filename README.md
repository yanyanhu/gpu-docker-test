## Testing dockerfiles and scripts for GPU support on Mesos/Marathon

# Prerequisite

* Make sure your testing machine has docker installed and your docker binary path is `/usr/bin/docker`.
* Make sure your testing machine has at least 1 Nvidia GPU(s) with driver version `>352.39`. 
* Make sure your testing machine has `nvidia-docker-plugin` installed.

# Testing Mesos/Marathon with GPU

* Pull/Build zookeeper/Mesos/Marathon images

```
make build
```

* Setup clusters

```
make start-cluster
```

* Run GPU enabled jobs

```
make run-job
```
