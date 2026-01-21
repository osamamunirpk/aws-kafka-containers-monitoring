# CloudWatch Custom Metrics Billing Model - Research Findings

## ✅ **CONFIRMED: Dimensional Combination Billing Model**

Based on official AWS documentation and AWS re:Post responses from AWS support engineers, the billing model is:

**CloudWatch charges for each unique combination of:**
- **Metric name** + **All dimensions** + **Namespace** + **Unit** = 1 billable custom metric

## 📚 **Official Sources**

### AWS re:Post (Official AWS Support)
> "CloudWatch treats each unique combination of dimensions as a separate metric, even if the metrics have the same metric name."

### AWS Support Engineer Response
> "A metric is defined by its namespace, metric name, list of dimensions (with values) and unit, so if you have multiple variations of a different feature in your dimension feature, it counts towards the number of metrics you pay for."

### AWS Pricing Documentation
> "All custom metrics and Detailed Monitoring charges are prorated by the hour and metered only when metrics are sent to CloudWatch. CloudWatch treats each unique combination of dimensions as a separate metric, even if the metrics have the same metric name."

## 🔍 **Practical Examples**

### Example 1: Same Metric, Different Dimensions
```
Metric: kafka.producer.request-rate
Dimensions: InstanceId=i-123, topic=topic-A
= 1 billable metric

Metric: kafka.producer.request-rate  
Dimensions: InstanceId=i-123, topic=topic-B
= 1 additional billable metric (total: 2)
```

### Example 2: Instance Changes Don't Create New Metrics
```
Metric: kafka.producer.request-rate
Dimensions: InstanceId=i-123, ProducerGroupName=KafkaProducer
= 1 billable metric

Metric: kafka.producer.request-rate
Dimensions: InstanceId=i-456, ProducerGroupName=KafkaProducer  
= 1 additional billable metric (total: 2)
```

## 💰 **Cost Impact Analysis**

### What Creates New Billable Metrics:
✅ **Different dimension values** (topic=A vs topic=B)  
✅ **Different instance IDs** (i-123 vs i-456)  
✅ **Different dimension combinations** (adding/removing dimensions)  
✅ **Different namespaces** (CWAgent vs MyApp)  
✅ **Different units** (Count vs Bytes)  

### What Does NOT Create New Metrics:
❌ **Same metric name with identical dimensions**  
❌ **Different metric values** (100 vs 200 for same dimensions)  
❌ **Different timestamps** for same metric+dimensions  

## 🎯 **Key Implications**

### For Our Kafka Solution:
- **Each topic** creates separate billable metrics for topic-specific metrics
- **Each instance** creates separate billable metrics  
- **Each unique dimension combination** is billed separately

### Cost Formula:
```
Total Billable Metrics = 
  (Cluster-level metrics) + 
  (Topic-specific metrics × Number of topics) + 
  (Instance-specific metrics × Number of instances)
```

## 📊 **Verification Methods**

### AWS CLI Check:
```bash
aws cloudwatch list-metrics --namespace CWAgent
# Each unique combination appears as separate metric
```

### Billing Verification:
- CloudWatch console shows each unique combination
- Billing reflects count of unique combinations
- AWS Cost Explorer breaks down by metric count

## ✅ **Conclusion**

**The research confirms**: CloudWatch billing is based on **unique combinations of metric name + all dimensions + namespace + unit**. 

This means:
- **Instance changes DO create new billable metrics**
- **Topic changes DO create new billable metrics**  
- **Any dimension value change creates a new billable metric**

The enterprise cost analysis in our documentation is **accurate** - each dimensional combination is billed separately at $0.30/month per metric.
