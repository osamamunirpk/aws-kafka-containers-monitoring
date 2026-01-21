# Kafka Monitoring Solution - Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    AWS EC2 Instance                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Kafka Broker  │  │   Kafka Broker  │  │   Kafka Broker  │  │
│  │    (Port 9092)  │  │    (Port 9093)  │  │    (Port 9094)  │  │
│  │   JMX: 9999     │  │   JMX: 9998     │  │   JMX: 9997     │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│           │                     │                     │         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │  Producer App   │  │  Producer App   │  │  Consumer App   │  │
│  │   JMX: 9104     │  │   JMX: 9105     │  │   JMX: 9106     │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│           │                     │                     │         │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │              CloudWatch Agent                              │  │
│  │         (Collects JMX Metrics via JolokiaAgent)           │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                              │                                   │
└──────────────────────────────┼───────────────────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │   AWS CloudWatch    │
                    │    (CWAgent NS)     │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  CloudWatch         │
                    │  Dashboard          │
                    │  (30 Widgets)       │
                    └─────────────────────┘
```

## Component Details

### Kafka Cluster
- **3-node cluster** running in Docker containers
- **JMX enabled** on each broker for metric collection
- **Topics**: `metrics-topic-1`, `dashboard-metrics-test`
- **Replication factor**: 3 for high availability

### Monitoring Applications
- **2 Producer applications** generating continuous traffic
- **2 Consumer applications** processing messages
- **JMX ports**: 9104-9107 for application-level metrics

### CloudWatch Integration
- **CloudWatch Agent** configured for JMX metric collection
- **30 different metrics** covering all dashboard widgets
- **Real-time collection** every 60 seconds
- **Custom namespace**: `CWAgent`

### Watchdog System
- **Autonomous monitoring** of all components
- **Auto-restart** capabilities for failed services
- **Metric injection** to ensure dashboard completeness
- **SNS alerting** for missing metrics (30+ minutes)

## Metric Categories

### Producer Metrics (6)
- Request/Response rates
- Latency measurements
- Record send rates
- Error rates
- Throughput (bytes/sec)

### Consumer Metrics (5)
- Fetch rates
- Consumption rates
- Lag measurements
- Throughput tracking

### JVM Metrics (10)
- Memory usage (heap/non-heap)
- Garbage collection stats
- Thread counts
- Class loading metrics

### Kafka Cluster Metrics (9)
- Partition health
- Leader elections
- Network I/O
- Request processing
- Purgatory sizes

## Deployment Flow

1. **Infrastructure**: Docker Compose deploys Kafka cluster
2. **Applications**: Java producers/consumers with JMX
3. **Monitoring**: CloudWatch Agent configuration
4. **Dashboard**: CloudFormation template deployment
5. **Watchdog**: Systemd service for autonomous operation
6. **Verification**: Automated testing of all 30 metrics
