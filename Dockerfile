FROM alpine:3.6
RUN apk update && \
    apk upgrade && \
    apk add --update --no-cache \
            libc6-compat \
            openjdk8-jre \
            bash \
            drill \
            coreutils \
            wget && \
     rm -rf /var/cache/apk/*
ENV JAVA_HOME=/usr/lib/jvm/default-jvm \
    KAFKA_VERSION=0.11.0.2

RUN wget  http://mirror.cc.columbia.edu/pub/software/apache/kafka/${KAFKA_VERSION}/kafka_2.11-${KAFKA_VERSION}.tgz -O /tmp/kafka.tgz && \
    mkdir -p /opt && \
    tar -xzf /tmp/kafka.tgz -C /opt && \
    mv /opt/kafka* /opt/kafka && \
    mkdir -p /opt/kafka/logs && \
    ln -sf /dev/stdout /opt/kafka/logs/kafkaServer-gc.log && \
    rm -f /tmp/kafka.tgz

ADD kafka/kafka.sh /etc/init.d/kafka
ADD kafka/kafka-producer-perf-test.sh /opt/kafka/bin/kafka-producer-perf-test.sh
ADD kafka/log4j.properties /opt/kafka/config/log4j.properties
RUN chmod +x /etc/init.d/kafka /opt/kafka/bin/kafka-producer-perf-test.sh

EXPOSE 9092

CMD ["/etc/init.d/kafka"]
