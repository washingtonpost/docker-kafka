#!/bin/bash

START_SCRIPT=/opt/kafka/bin/kafka-server-start.sh
PID_FILE=/var/run/kafka.pid

export KAFKA_GC_LOG_OPTS=${KAFKA_GC_LOG_OPTS:-" "}
MISSING_VAR_MESSAGE="must be set"
: ${BROKER_ID:?$MISSING_VAR_MESSAGE}
: ${INSTANCE_IP:?$MISSING_VAR_MESSAGE}

if [ ! -z $ZK_DNS ]; then
  ZOOKEEPER=$(drill ${ZK_DNS} | grep "^${ZK_DNS}." | awk '{ print $5 }' | xargs -I {} echo {}:2181 | paste -s -d',')${ZK_PATH}
fi

: ${ZOOKEEPER:?$MISSING_VAR_MESSAGE}
MAX_MESSAGE_BYTES="${MAX_MESSAGE_BYTES:-10485760}"

cat <<- EOF > /opt/kafka/config/server.properties
num.io.threads=${NUM_IO_THREADS:-8}
num.replica.fetchers=${NUM_REPLICA_FETCHERS:-1}
num.network.threads=${NUM_NETWORK_THREADS:-3}
socket.receive.buffer.bytes=${SOCKET_RECEIVE_BUFFER_BYTES:-1048576}
socket.send.buffer.bytes=${SOCKET_SEND_BUFFER_BYTES:-1048576}

port=${KAKFKA_PORT-9092}
advertised.host.name=${INSTANCE_IP}
log.dirs=${LOG_DIRS:-/data/kafka}
delete.topic.enable=${DELETE_TOPIC_ENABLE:-true}

# Replication configurations
message.max.bytes=${MAX_MESSAGE_BYTES}
replica.fetch.max.bytes=${REPLICA_FETCH_MAX_BYTES:-${MAX_MESSAGE_BYTES}}
log.segment.bytes=${LOG_SEGMENT_BYTES:-1073741824}
replica.lag.time.max.ms=${REPLICA_LAG_TIME_MAX_MS:-60000}
auto.leader.rebalance.enable=${AUTO_LEADER_REBALANCE_ENABLE:-true}
default.replication.factor=${DEFAULT_REPLICATION_FACTOR:-3}

# Log configuration
num.partitions=${NUM_PARTITIONS:-6}
log.retention.hours=${LOG_RETENTION_HOURS:-168}
auto.create.topics.enable=${AUTO_CREATE_TOPICS_ENABLE:-true}

# ZK configuration
zookeeper.session.timeout.ms=${ZOOKEEPER_SESSION_TIMEOUT_MS:-12000}

broker.id=${BROKER_ID}
zookeeper.connect=${ZOOKEEPER}
EOF

if [ ! -z ${LOG_MESSAGE_FORMAT_VERSION} ]; then
cat <<- EOF >> /opt/kafka/config/server.properties
log.message.format.version=${LOG_MESSAGE_FORMAT_VERSION}
EOF
fi

if [ ! -z ${INTER_BROKER_PROTOCOL_VERSION} ]; then
cat <<- EOF >> /opt/kafka/config/server.properties
inter.broker.protocol.version=${INTER_BROKER_PROTOCOL_VERSION}
EOF
fi

if [ ! -z ${AVAILABILITY_ZONE} ]; then
cat <<- EOF >> /opt/kafka/config/server.properties
broker.rack=${AVAILABILITY_ZONE}
EOF
fi

if [ -z ${HEAP_SIZE} ]; then
  MEM_TOTAL=`cat /proc/meminfo | grep MemTotal | sed "s/MemTotal:\s*//" | sed "s/ kB//"`
  HEAP_SIZE=$(expr $MEM_TOTAL / 4096)
  if [ "$HEAP_SIZE" -lt "512" ]; then
    HEAP_SIZE=512
  fi
  if [ "$HEAP_SIZE" -gt "8192" ]; then
    HEAP_SIZE=8192
  fi
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


