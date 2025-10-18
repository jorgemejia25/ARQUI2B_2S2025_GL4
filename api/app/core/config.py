"""
Application configuration management
Centralizes all configuration settings using environment variables
"""

import os
from typing import List
from pydantic_settings import BaseSettings
from pydantic import validator


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""
    
    # API Configuration
    APP_NAME: str = "Traffic Security System API"
    APP_VERSION: str = "1.0.0"
    API_V1_PREFIX: str = "/api/v1"
    DEBUG: bool = False
    
    # Server Configuration
    SERVER_HOST: str = "0.0.0.0"
    SERVER_PORT: int = 8001
    
    # Database Configuration
    DATABASE_PATH: str = "./seguridad_trafico.db"
    
    # MQTT Configuration
    MQTT_BROKER: str = "test.mosquitto.org"
    MQTT_PORT: int = 1883
    MQTT_USERNAME: str = ""
    MQTT_PASSWORD: str = ""
    MQTT_TOPICS: List[str] = [
        "arduino/data",
        "arduino/data/infracciones"
    ]
    
    # Serial (Arduino) Configuration
    SERIAL_PORT: str = "/dev/ttyACM0"
    SERIAL_BAUDRATE: int = 115200
    SERIAL_TIMEOUT: float = 5.0
    
    # Logging Configuration
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    # CORS Configuration
    CORS_ORIGINS: List[str] = ["*"]
    CORS_CREDENTIALS: bool = True
    CORS_METHODS: List[str] = ["*"]
    CORS_HEADERS: List[str] = ["*"]
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# Global settings instance
settings = Settings()


