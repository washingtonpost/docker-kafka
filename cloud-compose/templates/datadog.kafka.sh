# datadog.kafka.sh 
cat <<- 'EOF' > /etc/dd-agent/conf.d/kafka.yaml
instances:
    -   host: localhost
        name: kafka
        port: 9999 # This is the JMX port on which Kafka exposes its metrics (usually 9999)
        tools_jar_path: /usr/lib/jvm/java/lib/tools.jar # To be set when process_name_regex is set
        java_bin_path: /usr/lib/jvm/java/bin/java #Optional, should be set if the agent cannot find your java executable


init_config:
    is_jmx: true

    # Metrics collected by this check. You should not have to modify this.
    conf:
        #
        # Aggregate cluster stats
        #
        - include:
            domain: 'kafka.server'
            bean: 'kafka.server:type=BrokerTopicMetrics,name=BytesOutPerSec'
            attribute:
                MeanRate:
                    metric_type: gauge
                    alias: kafka.net.bytes_out
        - include:
            domain: 'kafka.server'
            bean: 'kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec'
            attribute:
                MeanRate:
                    metric_type: gauge
                    alias: kafka.net.bytes_in
        - include:
            domain: 'kafka.server'
            bean: 'kafka.server:type=BrokerTopicMetrics,name=MessagesInPerSec'
            attribute:
                MeanRate:
                    metric_type: gauge
                    alias: kafka.messages_in
        - include:
            domain: 'kafka.server'
            bean: 'kafka.server:type=BrokerTopicMetrics,name=BytesRejectedPerSec'
            attribute:
                MeanRate:
                    metric_type: gauge
                    alias: kafka.net.bytes_rejected

        #
        # Request timings
        #
        - include:
            domain: 'kafka.server'
            bean: 'kafka.server:type=BrokerTopicMetrics,name=FailedFetchRequestsPerSec'
            attribute:
                MeanRate:
                    metric_type: gauge
                    alias: kafka.request.fetch.failed
        - include:
            domain: 'kafka.server'
            bean: 'kafka.server:type=BrokerTopicMetrics,name=FailedProduceRequestsPerSec'
            attribute:
                MeanRate:
                    metric_type: gauge
                    alias: kafka.request.produce.failed
        - include:
            domain: 'kafka.network'
            bean: 'kafka.network:type=RequestMetrics,name=TotalTimeMs,request=Produce'
            attribute:
                Mean:
                    metric_type: gauge
                    alias: kafka.request.produce.time.avg
                99thPercentile:
                    metric_type: gauge
                    alias: kafka.request.produce.time.99percentile
        - include:
            domain: 'kafka.network'
            bean: 'kafka.network:type=RequestMetrics,name=TotalTimeMs,request=Fetch'
            attribute:
                Mean:
                    metric_type: gauge
                    alias: kafka.request.fetch.time.avg
                99thPercentile:
                    metric_type: gauge
                    alias: kafka.request.fetch.time.99percentile
        - include:
            domain: 'kafka.network'
            bean: 'kafka.network:type=RequestMetrics,name=TotalTimeMs,request=UpdateMetadata'
            attribute:
                Mean:
                    metric_type: gauge
                    alias: kafka.request.update_metadata.time.avg
                99thPercentile:
                    metric_type: gauge
                    alias: kafka.request.update_metadata.time.99percentile
        - include:
            domain: 'kafka.network'
            bean: 'kafka.network:type=RequestMetrics,name=TotalTimeMs,request=Metadata'
            attribute:
                Mean:
                    metric_type: gauge
                    alias: kafka.request.metadata.time.avg
                99thPercentile:
                    metric_type: gauge
                    alias: kafka.request.metadata.time.99percentile
        - include:
            domain: 'kafka.network'
            bean: 'kafka.network:type=RequestMetrics,name=TotalTimeMs,request=Offsets'
            attribute:
                Mean:
                    metric_type: gauge
                    alias: kafka.request.offsets.time.avg
                99thPercentile:
                    metric_type: gauge
                    alias: kafka.request.offsets.time.99percentile
        - include:
            domain: 'kafka.server'
            bean: 'kafka.server:type=KafkaRequestHandlerPool,name=RequestHandlerAvgIdlePercent'
            attribute:
                MeanRate:
                    metric_type: gauge
                    alias: kafka.request.handler.avg.idle.pct

        #
        # Replication stats
        #
        - include:
            domain: 'kafka.server'
            bean: 'kafka.server:type=ReplicaManager,name=IsrShrinksPerSec'
            attribute:
                MeanRate:
                    metric_type: gauge
                    alias: kafka.replication.isr_shrinks
        - include:
            domain: 'kafka.server'
            bean: 'kafka.server:type=ReplicaManager,name=IsrExpandsPerSec'
            attribute:
                MeanRate:
                    metric_type: gauge
                    alias: kafka.replication.isr_expands
        - include:            
            domain: 'kafka.server'
            bean: 'kafka.server:type=ReplicaManager,name=UnderReplicatedPartitions'
            attribute:
                Value:
                    metric_type: gauge
                    alias: kafka.replication.under_replicated_partitions
        - include:
            domain: 'kafka.controller'
            bean: 'kafka.controller:type=ControllerStats,name=LeaderElectionRateAndTimeMs'
            attribute:
                MeanRate:
                    metric_type: gauge
                    alias: kafka.replication.leader_elections
        - include:
            domain: 'kafka.controller'
            bean: 'kafka.controller:type=ControllerStats,name=UncleanLeaderElectionsPerSec'
            attribute:
                MeanRate:
                    metric_type: gauge
                    alias: kafka.replication.unclean_leader_elections

        #
        # Log flush stats
        #
        - include:
            domain: 'kafka.log'
            bean: 'kafka.log:type=LogFlushStats,name=LogFlushRateAndTimeMs'
            attribute:
                MeanRate:
                    metric_type: gauge
                    alias: kafka.log.flush_rate
EOF
# datadog.start
sh -c "sed 's/api_key:.*/api_key: {{DATADOG_API_KEY}}/' /etc/dd-agent/datadog.conf.example > /etc/dd-agent/datadog.conf"
service datadog-agent restart
