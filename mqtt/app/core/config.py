"""
Application configuration management
Centralizes all configuration settings
"""

import os
from typing import Optional
from pydantic_settings import BaseSettings


class SerialSettings(BaseSettings):
    """Serial communication settings"""
    
    PORT: str = "/dev/cu.usbserial-110"
    BAUDRATE: int = 115200
    TIMEOUT: int = 2
    
    class Config:
        env_prefix = "SERIAL_"
        case_sensitive = True


class MQTTSettings(BaseSettings):
    """MQTT broker settings"""
    
    BROKER: str = "localhost"
    PORT: int = 1883
    USERNAME: str = "jorge"
    PASSWORD: str = "34eikykmbd8w5igpjiebialeisx0yu02"
    TOPIC: str = "arduino/data"
    TOPIC_INFRACTIONS: str = "arduino/data/infracciones"
    CLIENT_ID: str = "arduino_mqtt_bridge"
    QOS: int = 1
    RETAIN: bool = False
    
    class Config:
        env_prefix = "MQTT_"
        case_sensitive = True


class ApplicationSettings(BaseSettings):
    """Application settings"""
    
    APP_NAME: str = "Arduino MQTT Bridge"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    # Simulation mode
    SIMULATION_MODE: bool = False
    SIMULATION_INTERVAL: float = 2.0
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# Global settings instances
serial_settings = SerialSettings()
mqtt_settings = MQTTSettings()
app_settings = ApplicationSettings()

