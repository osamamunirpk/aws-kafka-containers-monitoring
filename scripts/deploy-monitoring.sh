#!/bin/bash

echo "🚀 DEPLOYING KAFKA MONITORING SOLUTION"
echo "======================================"

# Set variables
REGION=${AWS_REGION:-us-west-2}
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

echo "Region: $REGION"
echo "Instance ID: $INSTANCE_ID"

# 1. Deploy Kafka cluster
echo ""
echo "1. Deploying Kafka cluster..."
cd ../infrastructure/
docker-compose up -d
sleep 30

# 2. Create topics
echo ""
echo "2. Creating monitoring topics..."
docker exec kafka-1 /usr/bin/kafka-topics --create --bootstrap-server localhost:9092 --topic metrics-topic-1 --partitions 3 --replication-factor 3 2>/dev/null || echo "Topic exists"
docker exec kafka-1 /usr/bin/kafka-topics --create --bootstrap-server localhost:9092 --topic dashboard-metrics-test --partitions 3 --replication-factor 3 2>/dev/null || echo "Topic exists"

# 3. Deploy CloudWatch dashboard
echo ""
echo "3. Deploying CloudWatch dashboard..."
aws cloudformation create-stack \
  --stack-name kafka-monitoring-dashboard \
  --template-body file://../dashboards/kafka-dashboard-template.json \
  --region $REGION \
  --parameters ParameterKey=InstanceId,ParameterValue=$INSTANCE_ID

# 4. Setup SNS alerts
echo ""
echo "4. Setting up SNS alerts..."
TOPIC_ARN=$(aws sns create-topic --name kafka-metrics-alerts --region $REGION --query 'TopicArn' --output text)
echo "Topic ARN: $TOPIC_ARN"

# 5. Create CloudWatch alarm
echo ""
echo "5. Creating CloudWatch alarm..."
aws cloudwatch put-metric-alarm \
  --alarm-name "KafkaMetricsMissing" \
  --alarm-description "Alert when Kafka producer metrics missing for 30 minutes" \
  --metric-name "kafka.producer.request-rate" \
  --namespace "CWAgent" \
  --statistic "Average" \
  --period 300 \
  --evaluation-periods 6 \
  --threshold 0 \
  --comparison-operator "LessThanThreshold" \
  --treat-missing-data "breaching" \
  --alarm-actions "$TOPIC_ARN" \
  --dimensions "Name=InstanceId,Value=$INSTANCE_ID" \
  --region $REGION

# 6. Install CloudWatch agent configuration
echo ""
echo "6. Installing CloudWatch agent configuration..."
sudo cp ../configs/cloudwatch-agent-config.json /opt/aws/amazon-cloudwatch-agent/etc/
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-agent-config.json

# 7. Deploy monitoring applications
echo ""
echo "7. Deploying monitoring applications..."
cp ../monitoring/kafka-apps/* ../infrastructure/kafka-apps/
docker exec kafka-1 bash -c 'cd /tmp && javac -cp /usr/share/java/kafka/*:/usr/share/java/cp-base-new/* *.java'

# Start producers with JMX
docker exec -d kafka-1 bash -c 'KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9104 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false" java -cp /tmp:/usr/share/java/kafka/*:/usr/share/java/cp-base-new/* KafkaProducer1 > /tmp/producer1.log 2>&1'

docker exec -d kafka-1 bash -c 'KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9105 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false" java -cp /tmp:/usr/share/java/kafka/*:/usr/share/java/cp-base-new/* KafkaProducer2 > /tmp/producer2.log 2>&1'

# Start consumers with JMX
docker exec -d kafka-1 bash -c 'KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9106 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false" java -cp /tmp:/usr/share/java/kafka/*:/usr/share/java/cp-base-new/* KafkaConsumer1 > /tmp/consumer1.log 2>&1'

docker exec -d kafka-1 bash -c 'KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9107 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false" java -cp /tmp:/usr/share/java/kafka/*:/usr/share/java/cp-base-new/* KafkaConsumer2 > /tmp/consumer2.log 2>&1'

# 8. Deploy watchdog system
echo ""
echo "8. Deploying watchdog system..."
sudo cp ../monitoring/kafka-keepalive.py /tmp/keepalive.py
sudo cp ../monitoring/kafka-keepalive.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable kafka-keepalive
sudo systemctl start kafka-keepalive

# 9. Deploy verification system
echo ""
echo "9. Deploying verification system..."
cp ../scripts/verify-all-widgets.sh /home/ec2-user/
chmod +x /home/ec2-user/verify-all-widgets.sh

echo ""
echo "✅ DEPLOYMENT COMPLETE"
echo "====================="
echo "🔗 Dashboard: https://$REGION.console.aws.amazon.com/cloudwatch/home?region=$REGION#dashboards:name=ApacheKafkaOnEc2-Real"
echo "📧 SNS Topic: $TOPIC_ARN"
echo "🛡️ Watchdog: Active"
echo ""
echo "Next steps:"
echo "1. Subscribe to SNS topic for email alerts"
echo "2. Wait 5 minutes for metrics to populate"
echo "3. Verify dashboard shows data"
