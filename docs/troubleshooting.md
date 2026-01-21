# Troubleshooting Guide

## Common Issues and Solutions

### Dashboard Shows Empty Widgets

**Symptoms**: Some or all dashboard widgets show "No data available"

**Diagnosis**:
```bash
# Run the verification script
./scripts/verify-all-widgets.sh

# Check CloudWatch Agent status
sudo systemctl status amazon-cloudwatch-agent

# Check watchdog status
sudo systemctl status kafka-keepalive
```

**Solutions**:
1. **Restart CloudWatch Agent**:
   ```bash
   sudo systemctl restart amazon-cloudwatch-agent
   ```

2. **Restart Watchdog**:
   ```bash
   sudo systemctl restart kafka-keepalive
   ```

3. **Manual metric injection**:
   ```bash
   python3 /tmp/keepalive.py
   ```

### Kafka Cluster Not Starting

**Symptoms**: Docker containers exit or fail to start

**Diagnosis**:
```bash
# Check container status
docker ps -a

# Check logs
docker logs kafka-1
docker logs kafka-2
docker logs kafka-3
```

**Solutions**:
1. **Clean restart**:
   ```bash
   cd infrastructure/
   docker-compose down
   docker-compose up -d
   ```

2. **Check disk space**:
   ```bash
   df -h
   ```

3. **Check port conflicts**:
   ```bash
   netstat -tulpn | grep -E '909[2-4]'
   ```

### JMX Connection Issues

**Symptoms**: Metrics not being collected from JMX endpoints

**Diagnosis**:
```bash
# Test JMX connectivity
telnet localhost 9999
telnet localhost 9104

# Check JMX configuration
docker exec kafka-1 env | grep JMX
```

**Solutions**:
1. **Restart applications with JMX**:
   ```bash
   ./scripts/deploy-monitoring.sh
   ```

2. **Verify JMX ports are open**:
   ```bash
   netstat -tulpn | grep -E '99[0-9][0-9]'
   ```

### SNS Alerts Not Working

**Symptoms**: No email notifications for missing metrics

**Diagnosis**:
```bash
# Check SNS topic exists
aws sns list-topics --region us-west-2

# Check CloudWatch alarms
aws cloudwatch describe-alarms --region us-west-2
```

**Solutions**:
1. **Subscribe to SNS topic**:
   ```bash
   TOPIC_ARN=$(aws sns list-topics --query 'Topics[?contains(TopicArn,`kafka-metrics-alerts`)].TopicArn' --output text)
   aws sns subscribe --topic-arn $TOPIC_ARN --protocol email --notification-endpoint your-email@example.com
   ```

2. **Confirm subscription**:
   Check your email and confirm the subscription

### High CPU/Memory Usage

**Symptoms**: System performance degradation

**Diagnosis**:
```bash
# Check system resources
top
htop
free -h
```

**Solutions**:
1. **Adjust JVM heap sizes**:
   Edit `infrastructure/docker-compose.yml` and modify `KAFKA_HEAP_OPTS`

2. **Reduce metric collection frequency**:
   Edit `configs/cloudwatch-agent-config.json` and increase `metrics_collection_interval`

3. **Scale down producers/consumers**:
   Modify the watchdog to run fewer applications

## Log Locations

- **Kafka logs**: `docker logs kafka-1`
- **Producer logs**: `docker exec kafka-1 cat /tmp/producer1.log`
- **Consumer logs**: `docker exec kafka-1 cat /tmp/consumer1.log`
- **Watchdog logs**: `sudo journalctl -u kafka-keepalive -f`
- **CloudWatch Agent logs**: `/opt/aws/amazon-cloudwatch-agent/logs/`

## Performance Tuning

### For High Throughput
- Increase `batch.size` and `linger.ms` in producers
- Increase `fetch.min.bytes` in consumers
- Adjust JVM heap sizes based on load

### For Low Latency
- Decrease `linger.ms` to 0
- Set `acks=1` instead of `acks=all`
- Increase number of partitions

### For Reliability
- Use `acks=all`
- Set `min.insync.replicas=2`
- Enable idempotent producers

## Monitoring Best Practices

1. **Set up proper alerting thresholds**
2. **Monitor disk usage** for Kafka logs
3. **Track consumer lag** to prevent backlog
4. **Monitor JVM garbage collection**
5. **Set up log rotation** for application logs
