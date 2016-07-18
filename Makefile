ZK=mesoscloud/zookeeper
ZK_TAG=3.4.6-ubuntu-14.04

MMASTER=mesos-master-gpu
MSLAVE=mesos-agent-gpu
MESOS_TAG=latest

MARATHON=marathon-gpu
MARATHON_TAG=latest

LOCAL_IP=127.0.0.1

build: pull-zk build-master build-agent build-marathon

run-cluster: run-zookeeper-local run-master-local run-agent-local run-marathon-local

kill-cluster:
	docker rm -f marathon slave-mesos master-mesos zookeeper

run-task:
	curl -X POST -H "Content-type: application/json" "${LOCAL_IP}:8080/v2/apps" -d@gpu-task.json

kill-task:
	curl -X DELETE ${LOCAL_IP}:8080/v2/apps/gpu-task

pull-zk:
	docker pull ${ZK}:${ZK_TAG}

build-master:
	docker build -t ${MMASTER}:${MESOS_TAG} -f Dockerfile.master ./

build-agent:
	docker build -t ${MSLAVE}:${MESOS_TAG} -f Dockerfile.agent ./

build-marathon:
	docker build -t ${MARATHON}:${MARATHON_TAG} -f Dockerfile.marathon ./

run-zookeeper-local:
	docker run -idt \
	-e MYID=1 \
	-e SERVERS=${LOCAL_IP} \
	--name=zookeeper \
	--net=host \
	${ZK}:${ZK_TAG}

run-master-local:
	docker run -idt \
	--net=host \
	--name master-mesos \
	${MMASTER}:${MESOS_TAG} \
	--log_dir=/var/log/mesos \
	--work_dir=/var/lib/mesos \
	--ip=0.0.0.0 \
	--advertise_ip=${LOCAL_IP} \
	--hostname_lookup=false \
	--quorum=1 \
	--zk=zk://${LOCAL_IP}:2181/mesos

run-agent-local:	
	nvidia-docker run -idt \
	--privileged=true \
	--volume /var/run/docker.sock:/var/run/docker.sock:ro \
	--volume /usr/bin/docker:/usr/bin/docker:ro \
	--net=host \
	--name slave-mesos \
	-e GLOG_v=1 \
	${MSLAVE}:${MESOS_TAG} \
	--master=zk://${LOCAL_IP}:2181/mesos \
	--ip=${LOCAL_IP} \
	--hostname_lookup=false \
	--work_dir=/var/run/mesos \
	--log_dir=/var/log/mesos \
	--containerizers=docker,mesos \
	--executor_registration_timeout=300secs \
	--isolation=cgroups/cpu,cgroups/mem,cgroups/devices,gpu/nvidia

run-marathon-local:
	docker run -idt \
	--net=host \
	--name marathon \
	${MARATHON}:${MARATHON_TAG} \
	--zk zk://${LOCAL_IP}:2181/marathon \
	--task_launch_timeout 300000 \
	--master zk://${LOCAL_IP}:2181/mesos \
	--hostname ${LOCAL_IP} \
	--enable_features gpu_resources
