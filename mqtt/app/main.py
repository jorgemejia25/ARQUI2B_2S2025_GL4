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
            
            # Publish infractions to dedicated topic (formato igual al simulador)
            if arduino_data.infractions:
                logger.info(f"Detectadas {len(arduino_data.infractions)} infracciones en el Arduino")
                for infraction in arduino_data.infractions:
                    signal_id = infraction if isinstance(infraction, str) else infraction.get("signal_id", "unknown")
                    infraction_data = {
                        "timestamp": time.time(),
                        "alert_type": "INFRACCION",
                        "severity": 4,
                        "signal_id": signal_id,
                        "signal_color": "red",
                        "origen": f"Infracción semáforo {signal_id}"
                    }
                    
                    # Log visible de la infracción
                    print("\n" + "!"*60)
                    print(f"INFRACCION DETECTADA EN MQTT: Semaforo {signal_id}")
                    print("!"*60 + "\n")
                    
                    if self.mqtt_publisher.publish_infraction(infraction_data):
                        logger.info(f"Published infraction: {signal_id} to topic arduino/data/infracciones")
                    else:
                        logger.error(f"Failed to publish infraction: {signal_id}")
            
            # Publish seismic alerts (formato igual al simulador)
            if arduino_data.seismic_event and arduino_data.seismic_event.active:
                seismic_data = {
                    "timestamp": time.time(),
                    "alert_type": "SISMO",
                    "severity": 4,
                    "seismic_intensity": arduino_data.seismic_event.magnitude,
                    "threshold_g": 2.0,
                    "tiene_sismo": True,
                    "origen": arduino_data.seismic_event.origin or "Sensor sísmico"
                }
                
                # Log visible del sismo
                print("\n" + "~"*60)
                print(f"SISMO DETECTADO: Magnitud {arduino_data.seismic_event.magnitude}")
                print(f"Origen: {seismic_data['origen']}")
                print("~"*60 + "\n")
                
                if self.mqtt_publisher.publish(seismic_data, "arduino/data"):
                    logger.info(f"Published seismic alert: magnitude={arduino_data.seismic_event.magnitude}")
                else:
                    logger.error("Failed to publish seismic alert")
            
            # Publish gas/smoke alerts (formato igual al simulador)
            if arduino_data.gas_sensors:
                for gas_sensor in arduino_data.gas_sensors:
                    if gas_sensor.is_high:
                        gas_alert_data = {
                            "timestamp": time.time(),
                            "alert_type": "GAS",
                            "severity": 3,
                            "gas_ppm": gas_sensor.ppm,
                            "threshold_ppm": 275.0,
                            "zona": gas_sensor.zone,
                            "origen": gas_sensor.zone
                        }
                        
                        # Log visible del gas/humo
                        print("\n" + "#"*60)
                        print(f"ALERTA DE GAS/HUMO: Zona {gas_sensor.zone}")
                        print(f"PPM: {gas_sensor.ppm} (umbral: 275)")
                        print("#"*60 + "\n")
                        
                        if self.mqtt_publisher.publish(gas_alert_data, "arduino/data"):
                            logger.info(f"Published gas alert: zone={gas_sensor.zone}, ppm={gas_sensor.ppm}")
                        else:
                            logger.error(f"Failed to publish gas alert: {gas_sensor.zone}")
            
            # Publish panic button alerts to dedicated topic
            if arduino_data.panic_buttons:
                for panic_button in arduino_data.panic_buttons:
                    if panic_button.active:
                        panic_alert_data = {
                            "timestamp": time.time(),
                            "alert_type": "PANIC_BUTTON",
                            "severity": 5,
                            "button_id": panic_button.button_id,
                            "location": panic_button.location,
                            "origen": f"Botón de pánico {panic_button.id}"
                        }
                        self.mqtt_publisher.publish_panic_alert(panic_alert_data)
                        logger.info(f"Published panic button alert: {panic_button.id} at {panic_button.location}")
        
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