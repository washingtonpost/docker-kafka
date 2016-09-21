FROM alpine:3.4
RUN apk update && \
    apk upgrade && \
    apk add --update --no-cache \
            openjdk8-jre \
            bash \
            drill \
            coreutils \
            wget && \
     rm -rf /var/cache/apk/* 
ENV JAVA_HOME=/usr/lib/jvm/default-jvm \
    KAFKA_VERSION=0.10.0.1

RUN wget  http://mirror.cc.columbia.edu/pub/software/apache/kafka/${KAFKA_VERSION}/kafka_2.11-${KAFKA_VERSION}.tgz -O /tmp/kafka.tgz && \
    mkdir /opt && \
    tar -xzf /tmp/kafka.tgz -C /opt && \
    mv /opt/kafka* /opt/kafka && \
    rm -f /tmp/kafka.tgz

ADD kafka/kafka.sh /etc/init.d/kafka
RUN chmod +x /etc/init.d/kafka

EXPOSE 9092

CMD ["/etc/init.d/kafka"]
