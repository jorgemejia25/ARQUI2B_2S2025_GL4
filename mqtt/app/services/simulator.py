"""
Arduino simulator service
Generates simulated Arduino data for testing without hardware
"""

import time
import random
from typing import Dict, Any
from app.models.arduino_data import ArduinoData, GasSensor, PanicButton, ETAInfo, SeismicEvent
from app.core.logging import get_logger

logger = get_logger(__name__)


class ArduinoSimulator:
    """Simulates Arduino sensor data"""
    
    def __init__(self):
        self.simulation_time = 0.0
        self.phase = 0
        self.phase_start_time = 0.0
    
    def generate_data(self) -> ArduinoData:
        """
        Generate simulated Arduino data
        
        Returns:
            ArduinoData object with simulated values
        """
        # Update simulation time
        self.simulation_time += 2.0
        
        # Update traffic light phase every 10 seconds
        if self.simulation_time - self.phase_start_time >= 10.0:
            self.phase = (self.phase + 1) % 4
            self.phase_start_time = self.simulation_time
        
        # Generate traffic lights
        traffic_lights = {}
        for i in range(1, 11):
            semaphore_id = f"S{i}"
            traffic_lights[semaphore_id] = self._get_traffic_light_state(semaphore_id)
        
        # Generate distances
        distances = {}
        for i in range(1, 7):
            distances[f"P{i}"] = random.uniform(10.0, 100.0)
        
        # Generate gas sensors
        gas_sensors = [
            GasSensor(
                zone="Z1",
                ppm=random.randint(150, 250),
                is_high=False
            ),
            GasSensor(
                zone="Z2",
                ppm=random.randint(150, 250),
                is_high=False
            )
        ]
        
        # Generate panic buttons (usually inactive)
        panic_buttons = [
            PanicButton(
                id=f"PB{i}",
                active=False,
                button_id=str(i),
                location=f"Parada {i}"
            )
            for i in range(1, 5)
        ]
        
        # Generate ETA info (60% probability)
        eta_info = []
        if random.random() < 0.6:
            num_eta = random.randint(1, 3)
            for _ in range(num_eta):
                parada = random.choice(["P1", "P2", "P3", "P4"])
                if random.random() < 0.65:
                    transport_type = "Transurbano"
                    origin = random.choice(["Centro", "Zona Norte", "Universidad"])
                else:
                    transport_type = "Transmetro"
                    origin = random.choice(["Estación Central", "Estación Norte"])
                
                tiempo = random.randint(30, 300)
                eta_info.append(ETAInfo(
                    stop=parada,
                    transport_type=transport_type,
                    time_seconds=tiempo,
                    origin=origin,
                    info=f"{'TU' if transport_type == 'Transurbano' else 'M'},ETA_S={tiempo},FROM={origin},TO={parada}"
                ))
        
        return ArduinoData(
            timestamp=str(int(self.simulation_time * 1000)),
            traffic_lights=traffic_lights,
            distances=distances,
            gas_sensors=gas_sensors,
            panic_buttons=panic_buttons,
            eta_info=eta_info,
            infractions=[],
            seismic_event=None,
            has_earthquake=False
        )
    
    def _get_traffic_light_state(self, semaphore_id: str) -> str:
        """Get traffic light state based on phase"""
        group_a = ['S1', 'S2', 'S4', 'S5', 'S6', 'S8', 'S10']
        group_b = ['S3', 'S7', 'S9']
        
        if semaphore_id in group_a:
            if self.phase == 0:
                return "VERDE"
            elif self.phase == 1:
                return "AMARILLO"
            else:
                return "ROJO"
        elif semaphore_id in group_b:
            if self.phase == 2:
                return "VERDE"
            elif self.phase == 3:
                return "AMARILLO"
            else:
                return "ROJO"
        return "ROJO"







