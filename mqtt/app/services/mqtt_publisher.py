"""
MQTT publishing service
Handles publishing data to MQTT broker
"""

import json
import paho.mqtt.client as mqtt
from typing import Dict, Any, Optional
from app.core.config import mqtt_settings
from app.core.logging import get_logger

logger = get_logger(__name__)


class MQTTPublisher:
    """Service for publishing data to MQTT broker"""
    
    def __init__(self):
        self.broker = mqtt_settings.BROKER
        self.port = mqtt_settings.PORT
        self.username = mqtt_settings.USERNAME
        self.password = mqtt_settings.PASSWORD
        self.client_id = mqtt_settings.CLIENT_ID
        self.topic = mqtt_settings.TOPIC
        self.topic_infractions = mqtt_settings.TOPIC_INFRACTIONS
        self.qos = mqtt_settings.QOS
        self.retain = mqtt_settings.RETAIN
        
        self.client: Optional[mqtt.Client] = None
        self.is_connected = False
        self.message_count = 0
    
    def connect(self) -> bool:
        """
        Connect to MQTT broker
        
        Returns:
            True if connection successful, False otherwise
        """
        try:
            self.client = mqtt.Client(client_id=self.client_id)
            
            # Set callbacks
            self.client.on_connect = self._on_connect
            self.client.on_disconnect = self._on_disconnect
            self.client.on_publish = self._on_publish
            
            # Set credentials if provided
            if self.username and self.password:
                self.client.username_pw_set(self.username, self.password)
                logger.info(f"MQTT authentication configured: {self.username}")
            
            # Connect to broker
            self.client.connect(self.broker, self.port, 60)
            self.client.loop_start()
            
            logger.info(f"Connecting to MQTT broker: {self.broker}:{self.port}")
            return True
            
        except Exception as e:
            logger.error(f"MQTT connection error: {e}")
            self.is_connected = False
            return False
    
    def disconnect(self) -> None:
        """Disconnect from MQTT broker"""
        if self.client:
            self.client.loop_stop()
            self.client.disconnect()
            self.is_connected = False
            logger.info("MQTT connection closed")
    
    def publish(self, data: Dict[str, Any], topic: Optional[str] = None) -> bool:
        """
        Publish data to MQTT broker
        
        Args:
            data: Dictionary to publish as JSON
            topic: Topic to publish to (default: main topic)
            
        Returns:
            True if successful, False otherwise
        """
        if not self.is_connected or not self.client:
            logger.warning("Attempting to publish to disconnected MQTT broker")
            return False
        
        try:
            topic_to_use = topic or self.topic
            payload = json.dumps(data, ensure_ascii=False)
            
            result = self.client.publish(
                topic_to_use,
                payload,
                qos=self.qos,
                retain=self.retain
            )
            
            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                self.message_count += 1
                logger.debug(f"Published to {topic_to_use}: {len(payload)} bytes")
                return True
            else:
                logger.error(f"Publish failed with code: {result.rc}")
                return False
                
        except Exception as e:
            logger.error(f"Publish error: {e}")
            return False
    
    def publish_infraction(self, infraction_data: Dict[str, Any]) -> bool:
        """
        Publish infraction to dedicated topic
        
        Args:
            infraction_data: Infraction data dictionary
            
        Returns:
            True if successful, False otherwise
        """
        return self.publish(infraction_data, self.topic_infractions)
    
    def _on_connect(self, client, userdata, flags, rc):
        """Callback when connected to broker"""
        if rc == 0:
            self.is_connected = True
            logger.info(f"Connected to MQTT broker: {self.broker}:{self.port}")
        else:
            self.is_connected = False
            logger.error(f"Connection failed with code: {rc}")
    
    def _on_disconnect(self, client, userdata, rc):
        """Callback when disconnected from broker"""
        self.is_connected = False
        if rc != 0:
            logger.warning(f"Unexpected disconnection: code={rc}")
        else:
            logger.info("Disconnected from MQTT broker")
    
    def _on_publish(self, client, userdata, mid):
        """Callback when message is published"""
        logger.debug(f"Message published: mid={mid}")
    
    def get_stats(self) -> Dict[str, Any]:
        """Get publishing statistics"""
        return {
            "connected": self.is_connected,
            "broker": f"{self.broker}:{self.port}",
            "messages_published": self.message_count,
            "topic": self.topic
        }
    
    def __enter__(self):
        """Context manager entry"""
        self.connect()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        self.disconnect()







