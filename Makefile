ZK_BASE_IMAGE_REPO=mesoscloud
ZK_BASE_IMAGE=zookeeper
ZK_TAG=3.4.6-ubuntu-14.04

MMASTER=mesos-master-gpu
MSLAVE=mesos-agent-gpu
MESOS_TAG=latest

MARATHON=marathon-gpu
MARATHON_TAG=latest

LOCAL_IP=127.0.0.1

all: pull-zk build-master build-agent build-marathon

pull-zk:
	docker pull ${ZK_BASE_IMAGE_REPO}/${ZK_BASE_IMAGE}:${ZK_TAG}

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
	--volume=/tmp/zookeeper:/tmp/zookeeper \
	--restart=always \
	${REPO}/${ZK_BASE_IMAGE}:${ZK_TAG}

run-master-local:
	docker run -idt \
	--volume /var/lib/mesos:/var/lib/mesos \
	--volume /var/log/mesos:/var/log/mesos \
	--net=host \
	--publish=5050:5050 \
	--publish=5051:5051 \
	--name master-mesos \
	${REPO}/${MMASTER}:${MESOS_TAG} \
        --log_dir=/var/log/mesos \
        --work_dir=/var/lib/mesos \
	--ip=${LOCAL_IP} \
	--quorum=1 \
	--zk=zk://${LOCAL_IP}:2181/mesos 

run-slave-local:	
	docker run -idt \
	--privileged=true \
	--volume /var/run/mesos:/var/run/mesos \
	--volume /var/log/mesos:/var/log/mesos \
	--volume /var/lib/mesos:/var/lib/mesos \
	--volume /var/run/docker.sock:/var/run/docker.sock \
	--net=host \
	--publish=5051:5051 \
	--name slave-mesos \
	-e GLOG_v=1 \
	${REPO}/${MSLAVE}:${MESOS_TAG} \
	--master=zk://${LOCAL_IP}:2181/mesos \
	--ip=${LOCAL_IP} \
	--work_dir=/var/run/mesos \
	--log_dir=/var/log/mesos \
	--containerizers=docker,mesos \
	--executor_registration_timeout=300secs \
	--isolation=cgroups/cpu,cgroups/mem
	#--isolation=cgroups/cpu,cgroups/mem,cgroups/devices,gpu/nvidia
	#--modules=file:///opt/gpu-hook/gpu_module_hook.json \
	#--hooks=org_apache_mesos_gpu_TestHook

run-marathon-local:
	docker run -idt \
	--volume /var/log/marathon:/var/log/marathon \
	--net=host --publish=8080:8080 \
	--name marathon \
	${REPO}/${MARATHON}:${MARATHON_TAG} \
	--zk zk://${LOCAL_IP}:2181/marathon \
	--task_launch_timeout 300000 \
	--master zk://${LOCAL_IP}:2181/mesos \
	--hostname ${LOCAL_IP} \
	--enable_features gpu_resources
