"""
Main application entry point
Arduino MQTT Bridge
"""

import time
import signal
import sys
from app.core.config import app_settings, mqtt_settings
from app.core.logging import setup_logging, get_logger
from app.services.serial_service import SerialService
from app.services.mqtt_publisher import MQTTPublisher
from app.services.simulator import ArduinoSimulator
from app.parsers.arduino_parser import ArduinoDataParser

# Setup logging
setup_logging()
logger = get_logger(__name__)


class ArduinoMQTTBridge:
    """Main application class for Arduino MQTT Bridge"""
    
    def __init__(self, simulation_mode: bool = False):
        self.simulation_mode = simulation_mode
        self.running = False
        self.message_count = 0
        
        # Services
        self.serial_service = None if simulation_mode else SerialService()
        self.mqtt_publisher = MQTTPublisher()
        self.simulator = ArduinoSimulator() if simulation_mode else None
        
        # Statistics
        self.start_time = None
        self.errors = 0
    
    def start(self) -> bool:
        """
        Start the bridge application
        
        Returns:
            True if started successfully
        """
        logger.info(f"Starting {app_settings.APP_NAME} v{app_settings.APP_VERSION}")
        logger.info(f"Mode: {'Simulation' if self.simulation_mode else 'Hardware'}")
        
        # Connect to MQTT
        if not self.mqtt_publisher.connect():
            logger.error("Failed to connect to MQTT broker")
            return False
        
        # Wait for MQTT connection
        time.sleep(2)
        
        if not self.mqtt_publisher.is_connected:
            logger.error("MQTT connection not established")
            return False
        
        # Connect to serial if not in simulation mode
        if not self.simulation_mode:
            if not self.serial_service.connect():
                logger.error("Failed to connect to serial port")
                return False
        
        self.running = True
        self.start_time = time.time()
        logger.info("Bridge started successfully")
        return True
    
    def stop(self) -> None:
        """Stop the bridge application"""
        logger.info("Stopping bridge...")
        self.running = False
        
        if self.mqtt_publisher:
            self.mqtt_publisher.disconnect()
        
        if self.serial_service:
            self.serial_service.disconnect()
        
        # Print statistics
        if self.start_time:
            runtime = time.time() - self.start_time
            logger.info(f"Runtime: {runtime:.2f}s")
            logger.info(f"Messages published: {self.message_count}")
            logger.info(f"Errors: {self.errors}")
        
        logger.info("Bridge stopped")
    
    def run(self) -> None:
        """Main run loop"""
        logger.info("Starting main loop...")
        
        try:
            while self.running:
                try:
                    if self.simulation_mode:
                        # Simulation mode
                        arduino_data = self.simulator.generate_data()
                        self._publish_data(arduino_data)
                        time.sleep(app_settings.SIMULATION_INTERVAL)
                    else:
                        # Hardware mode
                        json_str = self.serial_service.read_until_json(timeout=5.0)
                        if json_str:
                            arduino_data = ArduinoDataParser.parse_json(json_str)
                            if arduino_data:
                                self._publish_data(arduino_data)
                        time.sleep(0.1)
                        
                except KeyboardInterrupt:
                    logger.info("Keyboard interrupt received")
                    break
                except Exception as e:
                    logger.error(f"Error in main loop: {e}")
                    self.errors += 1
                    time.sleep(1)
        
        finally:
            self.stop()
    
    def _publish_data(self, arduino_data) -> None:
        """
        Publish Arduino data to MQTT
        
        Args:
            arduino_data: ArduinoData object
        """
        try:
            # Publish main data
            data_dict = arduino_data.to_dict()
            if self.mqtt_publisher.publish(data_dict):
                self.message_count += 1
                logger.debug(f"Published message #{self.message_count}")
            
            # Publish infractions to dedicated topic
            if arduino_data.infractions:
                for infraction in arduino_data.infractions:
                    infraction_data = {
                        "timestamp": time.time(),
                        "alert_type": "INFRACCION",
                        "severity": 4,
                        "signal_id": infraction if isinstance(infraction, str) else infraction.get("signal_id", "unknown"),
                        "signal_color": "red",
                        "origen": f"Infracción semáforo {infraction}"
                    }
                    self.mqtt_publisher.publish_infraction(infraction_data)
                    logger.info(f"Published infraction: {infraction}")
        
        except Exception as e:
            logger.error(f"Error publishing data: {e}")
            self.errors += 1


def signal_handler(sig, frame):
    """Handle SIGINT signal"""
    logger.info("Signal received, shutting down...")
    sys.exit(0)


def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Arduino MQTT Bridge")
    parser.add_argument(
        "--simulate",
        action="store_true",
        help="Run in simulation mode (no hardware required)"
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable debug logging"
    )
    
    args = parser.parse_args()
    
    # Update settings
    if args.debug:
        app_settings.DEBUG = True
        app_settings.LOG_LEVEL = "DEBUG"
        setup_logging()
    
    # Register signal handler
    signal.signal(signal.SIGINT, signal_handler)
    
    # Create and run bridge
    bridge = ArduinoMQTTBridge(simulation_mode=args.simulate)
    
    if bridge.start():
        bridge.run()
    else:
        logger.error("Failed to start bridge")
        sys.exit(1)


if __name__ == "__main__":
    main()

