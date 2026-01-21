#!/bin/bash

echo "🔍 COMPLETE DASHBOARD WIDGET VERIFICATION - ALL 19 METRICS"
echo "=========================================================="
echo ""

# ALL 19 dashboard metrics that need to be tested
declare -a metrics=(
    # Producer metrics (6)
    "kafka.producer.request-rate|ProducerGroupName=KafkaProducer,client-id=dashboard-java-producer"
    "kafka.producer.response-rate|ProducerGroupName=KafkaProducer,client-id=dashboard-java-producer"
    "kafka.producer.request-latency-avg|ProducerGroupName=KafkaProducer,client-id=dashboard-java-producer"
    "kafka.producer.record-send-rate|ProducerGroupName=KafkaProducer,client-id=dashboard-java-producer,topic=dashboard-metrics-test"
    "kafka.producer.record-error-rate|ProducerGroupName=KafkaProducer,client-id=dashboard-java-producer,topic=dashboard-metrics-test"
    "kafka.producer.byte-rate|ProducerGroupName=KafkaProducer,client-id=dashboard-java-producer,topic=dashboard-metrics-test"
    # Consumer metrics (5)
    "kafka.consumer.fetch-rate|ConsumerGroupName=KafkaConsumer,client-id=dashboard-java-consumer"
    "kafka.consumer.total.bytes-consumed-rate|ConsumerGroupName=KafkaConsumer,client-id=dashboard-java-consumer"
    "kafka.consumer.records-consumed-rate|ConsumerGroupName=KafkaConsumer,client-id=dashboard-java-consumer,topic=dashboard-metrics-test"
    "kafka.consumer.bytes-consumed-rate|ConsumerGroupName=KafkaConsumer,client-id=dashboard-java-consumer,topic=dashboard-metrics-test"
    "kafka.consumer.records-lag-max|ConsumerGroupName=KafkaConsumer,client-id=dashboard-java-consumer"
    # JVM metrics (10) - TEST BOTH ProcessGroupName VALUES
    "jvm.classes.loaded|ProcessGroupName=kafka-cluster"
    "jvm.gc.collections.count|ProcessGroupName=kafka-cluster,name=G1 Young Generation"
    "jvm.gc.collections.count|ProcessGroupName=KafkaClusterName,name=G1 Young Generation"
    "jvm.gc.collections.elapsed|ProcessGroupName=kafka-cluster,name=G1 Young Generation"
    "jvm.gc.collections.elapsed|ProcessGroupName=KafkaClusterName,name=G1 Young Generation"
    "jvm.memory.heap.committed|ProcessGroupName=kafka-cluster"
    "jvm.memory.heap.max|ProcessGroupName=kafka-cluster"
    "jvm.memory.heap.used|ProcessGroupName=kafka-cluster"
    "jvm.memory.nonheap.committed|ProcessGroupName=kafka-cluster"
    "jvm.memory.nonheap.max|ProcessGroupName=kafka-cluster"
    "jvm.memory.nonheap.used|ProcessGroupName=kafka-cluster"
    "jvm.threads.count|ProcessGroupName=kafka-cluster"
    # Kafka broker/cluster metrics (8)
    "kafka.isr.operation.count|ClusterName=kafka-cluster,operation=expand"
    "kafka.leader.election.rate|ClusterName=kafka-cluster"
    "kafka.network.io|ClusterName=kafka-cluster,state=in"
    "kafka.partition.offline|ClusterName=kafka-cluster"
    "kafka.partition.under_replicated|ClusterName=kafka-cluster"
    "kafka.purgatory.size|ClusterName=kafka-cluster,type=produce"
    "kafka.request.count|ClusterName=kafka-cluster,type=produce"
    "kafka.request.failed|ClusterName=kafka-cluster,type=produce"
    "kafka.request.time.avg|ClusterName=kafka-cluster,type=produce"
)

working_count=0
total_count=${#metrics[@]}
failed_metrics=()

echo "Testing ALL ${total_count} dashboard metrics (including GC with both ProcessGroupNames):"
echo "============================================="

for metric_info in "${metrics[@]}"; do
    metric_name=$(echo "$metric_info" | cut -d'|' -f1)
    dimensions=$(echo "$metric_info" | cut -d'|' -f2)
    
    # Convert dimensions to AWS CLI format
    aws_dims="Name=InstanceId,Value=i-0a57073bf1538948b"
    IFS=',' read -ra DIMS <<< "$dimensions"
    for dim in "${DIMS[@]}"; do
        key=$(echo "$dim" | cut -d'=' -f1)
        value=$(echo "$dim" | cut -d'=' -f2)
        aws_dims="$aws_dims Name=$key,Value=$value"
    done
    
    # Test metric
    result=$(aws cloudwatch get-metric-statistics \
        --namespace "CWAgent" \
        --metric-name "$metric_name" \
        --dimensions $aws_dims \
        --start-time "$(date -u -d '15 minutes ago' +%Y-%m-%dT%H:%M:%S)" \
        --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
        --period 300 \
        --statistics Average \
        --region us-west-2 \
        --query 'Datapoints[0].Average' \
        --output text 2>/dev/null)
    
    if [[ "$result" != "None" && "$result" != "" ]]; then
        echo "✅ $metric_name: $result"
        working_count=$((working_count + 1))
    else
        echo "❌ $metric_name: NO DATA"
        failed_metrics+=("$metric_name")
    fi
done

echo ""
echo "🎯 COMPLETE VERIFICATION RESULTS:"
echo "================================="
echo "✅ Working metrics: $working_count/$total_count"
echo "📊 Success rate: $(( working_count * 100 / total_count ))%"

if [ ${#failed_metrics[@]} -gt 0 ]; then
    echo ""
    echo "❌ FAILED METRICS:"
    for failed in "${failed_metrics[@]}"; do
        echo "   - $failed"
    done
    echo ""
    echo "🚨 VERIFICATION FAILED - NOT ALL WIDGETS HAVE DATA"
    exit 1
else
    echo ""
    echo "🎉 VERIFICATION PASSED - ALL WIDGETS HAVE DATA"
    exit 0
fi
