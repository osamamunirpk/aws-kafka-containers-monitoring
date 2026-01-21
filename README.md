# AWS Kafka Container Monitoring Solution

A comprehensive monitoring solution for **Apache Kafka running in Docker containers** on AWS EC2 with CloudWatch integration, automated dashboards, and intelligent alerting.

## 🐳 Container-Based Architecture

This solution monitors **Kafka clusters running in Docker containers**, not traditional EC2-based Kafka installations. Key features:

- **3-node Kafka cluster** deployed via Docker Compose
- **JMX monitoring** from containerized Kafka brokers  
- **Containerized producer/consumer applications** with metrics
- **CloudWatch Agent** collecting metrics from Docker containers
- **Container health monitoring** and auto-restart capabilities

## Overview

This solution provides enterprise-grade monitoring for **containerized Kafka clusters** with:
- **Real-time CloudWatch Dashboard** with 30+ metrics
- **Automated Metric Collection** from JMX endpoints in containers
- **Intelligent Alerting** with email notifications
- **Container orchestration** and health management
- **Self-Healing Watchdog** with 5-minute recovery cycles
- **Generic Dashboard Design** that adapts to any Kafka deployment

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Kafka Cluster │    │  Metric Collector │    │   CloudWatch    │
│                 │───▶│                  │───▶│                 │
│ • Brokers       │    │ • JMX Scraping   │    │ • Metrics       │
│ • Producers     │    │ • Data Transform │    │ • Alarms        │
│ • Consumers     │    │ • Batch Sending  │    │ • Dashboard     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │    Watchdog      │    │  SNS Alerts     │
                       │                  │    │                 │
                       │ • Health Checks  │    │ • Email Notify  │
                       │ • Auto Recovery  │    │ • 30min Timeout │
                       │ • 5min Cycles    │    │ • Auto Recovery │
                       └──────────────────┘    └─────────────────┘
```

## Features

### 📊 Comprehensive Monitoring
- **30+ Kafka Metrics**: Broker, producer, consumer, and JVM metrics
- **Real-time Dashboard**: Interactive CloudWatch dashboard with drill-down capabilities
- **Generic Design**: Automatically discovers and monitors any Kafka deployment
- **Historical Data**: Metric retention and trending analysis

### 🔧 Automated Operations
- **Self-Healing**: Automatic restart of failed components
- **Continuous Collection**: 24/7 metric gathering with fault tolerance
- **Smart Recovery**: Intelligent failure detection and remediation
- **Zero Maintenance**: Fully autonomous operation

### 🚨 Intelligent Alerting
- **Email Notifications**: Instant alerts for metric gaps > 30 minutes
- **CloudWatch Alarms**: Integrated alarm system with SNS
- **Escalation Logic**: Progressive alerting with auto-recovery attempts
- **Customizable Thresholds**: Configurable alert conditions

### 🛡️ Enterprise Reliability
- **5-Minute Recovery**: Maximum downtime before auto-restart
- **Verification Hooks**: Continuous validation of metric flow
- **Redundant Systems**: Multiple collection methods for reliability
- **Audit Trail**: Complete logging of all operations

## Quick Start

### Prerequisites
- AWS EC2 instance with CloudWatch agent
- Docker and Docker Compose
- Kafka cluster (containerized or native)
- AWS CLI configured with appropriate permissions

### 1. Deploy Kafka Cluster
```bash
# Deploy the monitoring-ready Kafka cluster
cd infrastructure/
docker-compose up -d
```

### 2. Configure CloudWatch Agent
```bash
# Install and configure CloudWatch agent
sudo ./scripts/setup-cloudwatch-agent.sh
```

### 3. Deploy Monitoring Stack
```bash
# Deploy dashboard and metric collection
./scripts/deploy-monitoring.sh
```

### 4. Configure Alerts
```bash
# Setup email notifications
./scripts/setup-alerts.sh your-email@domain.com
```

### 5. Start Watchdog
```bash
# Enable self-healing monitoring
sudo systemctl enable kafka-keepalive
sudo systemctl start kafka-keepalive
```

## Dashboard Metrics

### Kafka Broker Metrics
- `kafka.leader.election.rate` - Leader election frequency
- `kafka.network.io` - Network throughput (in/out)
- `kafka.request.time.avg` - Average request processing time
- `kafka.request.count` - Total request count
- `kafka.request.failed` - Failed request count
- `kafka.purgatory.size` - Request purgatory size
- `kafka.partition.under_replicated` - Under-replicated partitions
- `kafka.partition.offline` - Offline partitions
- `kafka.isr.operation.count` - ISR operations

### Producer Metrics
- `kafka.producer.request-rate` - Producer request rate
- `kafka.producer.response-rate` - Producer response rate
- `kafka.producer.request-latency-avg` - Average request latency
- `kafka.producer.record-send-rate` - Record send rate
- `kafka.producer.record-error-rate` - Record error rate
- `kafka.producer.byte-rate` - Byte throughput rate

### Consumer Metrics
- `kafka.consumer.fetch-rate` - Consumer fetch rate
- `kafka.consumer.total.bytes-consumed-rate` - Total bytes consumed
- `kafka.consumer.records-consumed-rate` - Records consumed rate
- `kafka.consumer.bytes-consumed-rate` - Bytes consumed rate
- `kafka.consumer.records-lag-max` - Maximum consumer lag

### JVM Metrics
- `jvm.memory.heap.used/max/committed` - Heap memory usage
- `jvm.memory.nonheap.used/max/committed` - Non-heap memory
- `jvm.threads.count` - Active thread count
- `jvm.classes.loaded` - Loaded class count
- `jvm.gc.collections.count/elapsed` - Garbage collection stats

## Configuration

### Environment Variables
```bash
# AWS Configuration
AWS_REGION=us-west-2
INSTANCE_ID=i-xxxxxxxxx

# Kafka Configuration
KAFKA_CLUSTER_NAME=kafka-cluster
KAFKA_BOOTSTRAP_SERVERS=localhost:9092

# Monitoring Configuration
METRIC_COLLECTION_INTERVAL=60
WATCHDOG_CHECK_INTERVAL=300
ALERT_THRESHOLD_MINUTES=30
```

### CloudWatch Agent Configuration
The solution uses a comprehensive CloudWatch agent configuration that collects:
- JMX metrics from Kafka brokers, producers, and consumers
- System metrics (CPU, memory, disk, network)
- Custom application metrics
- Log aggregation and analysis

### Dashboard Configuration
The CloudWatch dashboard is designed to be:
- **Generic**: Works with any Kafka deployment
- **Scalable**: Automatically adapts to cluster size
- **Interactive**: Drill-down capabilities and time range selection
- **Customizable**: Easy to modify and extend

## Monitoring and Alerting

### Health Checks
The watchdog system performs comprehensive health checks:
```bash
# Kafka cluster connectivity
# Metric collection processes
# CloudWatch agent status
# Dashboard data freshness
# Alert system functionality
```

### Alert Conditions
- **Metric Gap**: No data for 30+ minutes
- **Process Failure**: Critical component down
- **Cluster Unavailable**: Kafka cluster unreachable
- **High Error Rate**: Excessive failures detected

### Recovery Actions
- **Process Restart**: Automatic restart of failed components
- **Metric Re-injection**: Force metric collection restart
- **Cluster Recovery**: Kafka cluster restart if needed
- **Alert Escalation**: Email notifications with recovery status

## Troubleshooting

### Common Issues

**Dashboard shows no data:**
```bash
# Check metric collection
./scripts/verify-metrics.sh

# Restart metric collection
sudo systemctl restart kafka-keepalive
```

**Alerts not working:**
```bash
# Verify SNS subscription
aws sns list-subscriptions-by-topic --topic-arn <topic-arn>

# Test alert system
./scripts/test-alerts.sh
```

**Watchdog not running:**
```bash
# Check service status
sudo systemctl status kafka-keepalive

# View logs
sudo journalctl -u kafka-keepalive -f
```

### Log Locations
- Watchdog logs: `/tmp/keepalive.log`
- Metric collection: `/tmp/metric_sender.log`
- CloudWatch agent: `/opt/aws/amazon-cloudwatch-agent/logs/`
- Kafka applications: `/tmp/producer*.log`, `/tmp/consumer*.log`

## Architecture Decisions

### Why CloudWatch?
- Native AWS integration
- Scalable metric storage
- Built-in alerting capabilities
- Cost-effective for AWS workloads

### Why Generic Dashboard?
- Works with any Kafka deployment
- No hardcoded cluster names
- Automatic metric discovery
- Future-proof design

### Why Watchdog System?
- Ensures 24/7 operation
- Automatic failure recovery
- Minimal manual intervention
- Enterprise reliability

## Performance Considerations

### Metric Collection Overhead
- **CPU Impact**: < 2% on typical EC2 instances
- **Memory Usage**: ~50MB for metric collection processes
- **Network**: ~1KB/minute per metric to CloudWatch
- **Storage**: Minimal local storage requirements

### Scaling Guidelines
- **Small Clusters** (1-3 brokers): Default configuration
- **Medium Clusters** (4-10 brokers): Increase collection intervals
- **Large Clusters** (10+ brokers): Consider metric sampling

## Security

### IAM Permissions Required
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics",
                "cloudwatch:PutDashboard",
                "cloudwatch:GetDashboard",
                "sns:Publish",
                "ssm:GetParameter",
                "ssm:PutParameter"
            ],
            "Resource": "*"
        }
    ]
}
```

### Network Security
- JMX ports secured to localhost only
- CloudWatch agent uses HTTPS
- No external network access required

## Contributing

### Development Setup
```bash
# Clone repository
git clone <repository-url>
cd kafka-monitoring-solution

# Install dependencies
./scripts/install-dependencies.sh

# Run tests
./scripts/run-tests.sh
```

### Testing
- Unit tests for metric collection logic
- Integration tests for CloudWatch integration
- End-to-end dashboard validation
- Alert system testing

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review log files for error messages
3. Verify AWS permissions and configuration
4. Test individual components using provided scripts

## Changelog

### v1.0.0
- Initial release with comprehensive Kafka monitoring
- Generic dashboard with 30+ metrics
- Automated alerting and recovery
- Self-healing watchdog system
- Complete documentation and deployment scripts
