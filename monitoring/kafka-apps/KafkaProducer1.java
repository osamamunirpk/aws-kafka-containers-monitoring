import org.apache.kafka.clients.producer.*;
import org.apache.kafka.common.serialization.StringSerializer;
import java.util.Properties;
import java.util.Random;

public class KafkaProducer1 {
    public static void main(String[] args) {
        Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(ProducerConfig.CLIENT_ID_CONFIG, "dashboard-java-producer");
        props.put(ProducerConfig.ACKS_CONFIG, "all");
        props.put(ProducerConfig.RETRIES_CONFIG, 3);
        props.put(ProducerConfig.BATCH_SIZE_CONFIG, 16384);
        props.put(ProducerConfig.LINGER_MS_CONFIG, 1);
        props.put(ProducerConfig.BUFFER_MEMORY_CONFIG, 33554432);

        Producer<String, String> producer = new KafkaProducer<>(props);
        Random random = new Random();
        
        System.out.println("Starting KafkaProducer1 with JMX monitoring...");
        
        try {
            while (true) {
                for (int i = 0; i < 10; i++) {
                    String key = "key-" + random.nextInt(1000);
                    String value = "message-" + System.currentTimeMillis() + "-" + random.nextInt(10000);
                    
                    ProducerRecord<String, String> record = new ProducerRecord<>("dashboard-metrics-test", key, value);
                    
                    producer.send(record, (metadata, exception) -> {
                        if (exception != null) {
                            System.err.println("Error sending message: " + exception.getMessage());
                        }
                    });
                }
                
                Thread.sleep(1000); // Send 10 messages per second
            }
        } catch (Exception e) {
            System.err.println("Producer error: " + e.getMessage());
        } finally {
            producer.close();
        }
    }
}
