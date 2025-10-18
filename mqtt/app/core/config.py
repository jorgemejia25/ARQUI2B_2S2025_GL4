"""
MQTT Bridge configuration management
Centralizes all configuration settings for the Arduino MQTT Bridge
"""

import os
from typing import List
from pydantic_settings import BaseSettings


class AppSettings(BaseSettings):
    """Application settings for the MQTT Bridge"""
    
    # Application Configuration
    APP_NAME: str = "Arduino MQTT Bridge"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    
    # Simulation Configuration
    SIMULATION_INTERVAL: float = 2.0  # Seconds between simulation messages
    
    # Serial Configuration
    SERIAL_PORT: str = "/dev/ttyACM0"  # Default Arduino port
    SERIAL_BAUDRATE: int = 115200
    SERIAL_TIMEOUT: float = 1.0
    
    # Logging Configuration
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


class MQTTSettings(BaseSettings):
    """MQTT-specific settings"""
    
    # MQTT Broker Configuration
    BROKER: str = "test.mosquitto.org"
    PORT: int = 1883
    USERNAME: str = ""
    PASSWORD: str = ""
    
    # MQTT Topics
    TOPIC: str = "arduino/data"
    TOPIC_INFRACTIONS: str = "arduino/data/infracciones"
    
    # MQTT Connection Settings
    KEEPALIVE: int = 60
    CONNECT_TIMEOUT: int = 10
    CLIENT_ID: str = "arduino_bridge"
    
    # Message Settings
    QOS: int = 1
    RETAIN: bool = False
    
    class Config:
        env_file = ".env"
        case_sensitive = True


class SerialSettings(BaseSettings):
    """Serial communication settings"""
    
    # Serial Port Configuration
    SERIAL_PORT: str = "/dev/ttyACM0"
    SERIAL_BAUDRATE: int = 115200
    SERIAL_TIMEOUT: float = 1.0
    
    # Data Processing Settings
    JSON_TIMEOUT: float = 5.0
    BUFFER_SIZE: int = 1024
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# Global settings instances
app_settings = AppSettings()
mqtt_settings = MQTTSettings()
serial_settings = SerialSettings()