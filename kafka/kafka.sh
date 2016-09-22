#!/bin/bash

START_SCRIPT=/opt/kafka/bin/kafka-server-start.sh
PID_FILE=/var/run/kafka.pid
# Convert the last two octets of the private ip into a broker ip since these will be unique within a VPC with a maximum CIDR of /16
IFS=. read -r a b c d <<< "${INSTANCE_IP}"
[[  $BROKER_ID && ${BROKER_ID-x} ]] || BROKER_ID=$((c * 256 + d))
[[  $REPL_FACTOR && ${REPL_FACTOR-x} ]] || REPL_FACTOR=3

# ***********************************************
# ***********************************************
# chkconfig: 2345 95 05
# source function library
# . /etc/rc.d/init.d/functions
[ -f /etc/default/kafka ] && . /etc/default/kafka
MISSING_VAR_MESSAGE="must be set"
: ${BROKER_ID:?$MISSING_VAR_MESSAGE}
: ${INSTANCE_IP:?$MISSING_VAR_MESSAGE}

if [ ! -z $ZK_DNS ]; then
  ZOOKEEPER=$(drill ${ZK_DNS} | grep "^${ZK_DNS}." | awk '{ print $5 }' | xargs -I {} echo {}:2181 | paste -s -d',')${ZK_PATH}
fi

: ${ZOOKEEPER:?$MISSING_VAR_MESSAGE}
MAX_MESSAGE_BYTES="${MAX_MESSAGE_BYTES:-10485760}"

cat <<- EOF > /opt/kafka/config/server.properties
num.io.threads=16
num.network.threads=8
socket.receive.buffer.bytes=1048576
socket.send.buffer.bytes=1048576

port=9092
log.dirs=/data/kafka
advertised.host.name=${INSTANCE_IP}
delete.topic.enable=true

# Replication configurations
num.replica.fetchers=8
message.max.bytes=${MAX_MESSAGE_BYTES}
replica.fetch.max.bytes=${REPLICA_FETCH_MAX_BYTES:-${MAX_MESSAGE_BYTES}}
log.segment.bytes=${LOG_SEGMENT_BYTES:-1073741824}
replica.lag.time.max.ms=60000
auto.leader.rebalance.enable=true
default.replication.factor=${REPL_FACTOR}

# Log configuration
num.partitions=${NUM_PARTITIONS:-12}
log.retention.hours=${LOG_RETENTION_HOURS:-168}
auto.create.topics.enable=true

# ZK configuration
zookeeper.session.timeout.ms=12000  

broker.id=${BROKER_ID}
zookeeper.connect=${ZOOKEEPER}
EOF

if [ ! -z ${LOG_MESSAGE_FORMAT_VERSION} ]; then
cat <<- EOF >> /opt/kafka/config/server.properties
log.message.format.version=${LOG_MESSAGE_FORMAT_VERSION}
EOF
fi

if [ ! -z ${AVAILABILITY_ZONE} ]; then
cat <<- EOF >> /opt/kafka/config/server.properties
broker.rack=${AVAILABILITY_ZONE}
EOF
fi

MEM_TOTAL=`cat /proc/meminfo | grep MemTotal | sed "s/MemTotal:\s*//" | sed "s/ kB//"`
HEAP_SIZE=$(expr $MEM_TOTAL / 8192)
if [ "$HEAP_SIZE" -lt "512" ]; then
  HEAP_SIZE=512
fi
if [ "$HEAP_SIZE" -gt "4096" ]; then
  HEAP_SIZE=4096
fi

cat <<- EOF > /opt/kafka/bin/kafka-server-start.sh
#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export JMX_PORT=9999

if [ \$# -lt 1 ];
then
  echo "USAGE: \$0 [-daemon] server.properties"
  exit 1
fi
base_dir=\$(dirname \$0)
export KAFKA_LOG4J_OPTS="-Dlog4j.configuration=file:\$base_dir/../config/log4j.properties"
export KAFKA_HEAP_OPTS="-Xms${HEAP_SIZE}M -Xmx${HEAP_SIZE}M"

EXTRA_ARGS="-name kafkaServer -loggc"

COMMAND=\$1
case \$COMMAND in
  -daemon)
    EXTRA_ARGS="-daemon "\$EXTRA_ARGS
    shift
    ;;
  *)
    ;;
esac

exec \$base_dir/kafka-run-class.sh \$EXTRA_ARGS kafka.Kafka \$@
EOF

ARGS="/opt/kafka/config/server.properties" # optional start script arguments

ZK_SERVER=$(echo "${ZOOKEEPER}" | tr ',' '\n' | tr ':' '\n' | tr '/' '\n' | head -n 1)
while ! nc -z ${ZK_SERVER} 2181 >/dev/null 2>&1; do
  echo "waiting for zookeeper ${ZK_SERVER}"
  sleep 2
done

$START_SCRIPT $ARGS


