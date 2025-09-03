"""
Módulo de simulación para generar datos aleatorios del Arduino.
Útil para probar el módulo sin necesidad de hardware físico.
"""

import time
import random
import json
from typing import Dict, Any

# Import relativo o absoluto según el contexto
try:
    from arduino_data_parser import ArduinoDataParser, parse_arduino_json
except ImportError:
    from arduino_data_parser import ArduinoDataParser, parse_arduino_json


class ArduinoSimulator:
    """
    Simulador del Arduino que genera datos JSON aleatorios pero lógicos.
    """
    
    def __init__(self):
        # Estados de simulación
        self.simulation_time = 0
        self.phase = 0  # Fase del semáforo (0-3)
        self.phase_start_time = 0
        
        # Estados de sensores
        self.sensor_states = {
            'TM1': {'below': False, 'stable': False, 'start_time': 0},
            'TM2': {'below': False, 'stable': False, 'start_time': 0},
            'TU3': {'below': False, 'stable': False, 'start_time': 0},
            'TU4': {'below': False, 'stable': False, 'start_time': 0}
        }
        
        # Estados de botones de pánico
        self.panic_button_states = {
            'PB1': {'active': False, 'until': 0},
            'PB2': {'active': False, 'until': 0},
            'PB3': {'active': False, 'until': 0},
            'PB4': {'active': False, 'until': 0}
        }
        
        # Estado del sismo
        self.earthquake_state = {
            'active': False,
            'until': 0,
            'magnitude': 0.0
        }
        
        # Infracciones activas
        self.active_violations = set()
        
        # ETA activos
        self.active_eta = {}
    
    def generate_timestamp(self) -> str:
        """Genera un timestamp simulado."""
        return str(int(self.simulation_time * 1000))
    
    def update_simulation_time(self, delta_time: float):
        """Actualiza el tiempo de simulación."""
        self.simulation_time += delta_time
        
        # Actualizar fase del semáforo cada 10 segundos
        if self.simulation_time - self.phase_start_time >= 10.0:
            self.phase = (self.phase + 1) % 4
            self.phase_start_time = self.simulation_time
    
    def get_traffic_light_state(self, semaphore_id: str) -> str:
        """Obtiene el estado de un semáforo específico."""
        # S1, S2, S4, S5, S6, S8, S10 son grupo A
        # S3, S7, S9 son grupo B
        group_a = ['S1', 'S2', 'S4', 'S5', 'S6', 'S8', 'S10']
        group_b = ['S3', 'S7', 'S9']
        
        if semaphore_id in group_a:
            if self.phase == 0:  # A verde
                return "VERDE"
            elif self.phase == 1:  # A amarillo
                return "AMARILLO"
            else:  # A rojo
                return "ROJO"
        elif semaphore_id in group_b:
            if self.phase == 2:  # B verde
                return "VERDE"
            elif self.phase == 3:  # B amarillo
                return "AMARILLO"
            else:  # B rojo
                return "ROJO"
        else:
            return "ROJO"  # Por defecto
    
    def generate_distance_data(self) -> Dict[str, float]:
        """Genera datos de distancia simulados."""
        distances = {}
        
        # Paradas principales (P1-P6)
        for i in range(1, 7):
            parada_id = f"P{i}"
            
            # Simular vehículos acercándose y alejándose
            if parada_id in ['P1', 'P2', 'P3', 'P4']:
                # Paradas de transporte público - más variación
                if random.random() < 0.3:  # 30% de probabilidad de estar cerca
                    distances[parada_id] = random.uniform(3.0, 15.0)
                else:
                    distances[parada_id] = random.uniform(20.0, 100.0)
            else:
                # Paradas secundarias - menos variación
                distances[parada_id] = random.uniform(30.0, 80.0)
        
        return distances
    
    def generate_gas_data(self) -> Dict[str, int]:
        """Genera datos de sensores de gas simulados."""
        gas_data = {}
        
        # Zona 1 - más probabilidad de gas alto
        if random.random() < 0.2:  # 20% de probabilidad
            gas_data['Z1'] = random.randint(250, 350)
        else:
            gas_data['Z1'] = random.randint(150, 240)
        
        # Zona 2 - menos probabilidad de gas alto
        if random.random() < 0.1:  # 10% de probabilidad
            gas_data['Z2'] = random.randint(250, 300)
        else:
            gas_data['Z2'] = random.randint(160, 230)
        
        return gas_data
    
    def update_earthquake_simulation(self):
        """Actualiza la simulación del sismo."""
        # 5% de probabilidad de activar sismo
        if not self.earthquake_state['active'] and random.random() < 0.05:
            self.earthquake_state['active'] = True
            self.earthquake_state['until'] = self.simulation_time + random.uniform(3.0, 8.0)
            self.earthquake_state['magnitude'] = random.uniform(4.5, 6.5)
        
        # Desactivar sismo si ya pasó el tiempo
        if self.earthquake_state['active'] and self.simulation_time >= self.earthquake_state['until']:
            self.earthquake_state['active'] = False
            self.earthquake_state['magnitude'] = 0.0
    
    def update_panic_buttons_simulation(self):
        """Actualiza la simulación de botones de pánico."""
        for btn_id in self.panic_button_states:
            btn = self.panic_button_states[btn_id]
            
            # 2% de probabilidad de activar botón
            if not btn['active'] and random.random() < 0.02:
                btn['active'] = True
                btn['until'] = self.simulation_time + random.uniform(2.0, 4.0)
            
            # Desactivar botón si ya pasó el tiempo
            if btn['active'] and self.simulation_time >= btn['until']:
                btn['active'] = False
    
    def update_violations_simulation(self):
        """Actualiza la simulación de infracciones."""
        # Limpiar infracciones antiguas
        self.active_violations.clear()
        
        # 15% de probabilidad de tener infracciones
        if random.random() < 0.15:
            # Generar 1-3 infracciones aleatorias
            num_violations = random.randint(1, 3)
            possible_semaphores = ['S2', 'S4', 'S5', 'S8', 'S10']
            
            for _ in range(num_violations):
                semaphore = random.choice(possible_semaphores)
                self.active_violations.add(semaphore)
    
    def update_eta_simulation(self):
        """Actualiza la simulación de ETA."""
        self.active_eta.clear()
        
        # 60% de probabilidad de tener ETAs activos (más realista)
        if random.random() < 0.6:
            # Generar 1-5 ETAs
            num_eta = random.randint(1, 5)
            paradas = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6']
            
            # Nombres más realistas para las zonas
            zonas_tu = ['Centro', 'Zona Norte', 'Zona Sur', 'Zona Este', 'Zona Oeste', 'Universidad', 'Hospital', 'Mall']
            estaciones_tm = ['Estación Central', 'Estación Norte', 'Estación Sur', 'Estación Este', 'Estación Oeste']
            
            for _ in range(num_eta):
                parada = random.choice(paradas)
                if parada not in self.active_eta:
                    # Generar ETA más realista
                    if random.random() < 0.65:  # 65% Transurbano
                        zona = random.choice(zonas_tu)
                        tiempo = random.randint(45, 300)  # 45 segundos a 5 minutos
                        eta_info = f"TU,ETA_S={tiempo},FROM={zona},TO={parada}"
                    else:  # 35% Transmetro
                        estacion = random.choice(estaciones_tm)
                        tiempo = random.randint(30, 180)  # 30 segundos a 3 minutos
                        eta_info = f"M,ETA_S={tiempo},FROM={estacion},TO={parada}"
                    
                    self.active_eta[parada] = eta_info
    
    def generate_json_data(self) -> str:
        """Genera un JSON completo simulado del Arduino."""
        # Actualizar estados de simulación
        self.update_earthquake_simulation()
        self.update_panic_buttons_simulation()
        self.update_violations_simulation()
        self.update_eta_simulation()
        
        # Construir JSON
        data = {
            "ts": self.generate_timestamp(),
            "semaforos": {},
            "dist_cm": self.generate_distance_data(),
            "gas_ppm": self.generate_gas_data(),
            "zumbador": {"Z1": 0, "Z2": 0},
            "sismo": {
                "activo": 1 if self.earthquake_state['active'] else 0,
                "magnitud": self.earthquake_state['magnitude'],
                "origen": "simulacion" if self.earthquake_state['active'] else ""
            },
            "panic_buttons": {},
            "infracciones": list(self.active_violations),
            "eta": self.active_eta,
            "_protocol_version": "1.1"
        }
        
        # Generar estados de semáforos
        for i in range(1, 11):
            semaphore_id = f"S{i}"
            data["semaforos"][semaphore_id] = self.get_traffic_light_state(semaphore_id)
        
        # Generar estados de botones de pánico
        for btn_id, btn_state in self.panic_button_states.items():
            data["panic_buttons"][btn_id] = {
                "activo": 1 if btn_state['active'] else 0,
                "ts": self.generate_timestamp(),
                "id": btn_id
            }
        
        return json.dumps(data, ensure_ascii=False)
    
    def simulate_data_stream(self, interval: float = 2.0, duration: float = 60.0):
        """
        Simula un stream de datos continuo.
        
        Args:
            interval: Intervalo entre datos en segundos
            duration: Duración total de la simulación en segundos
        """
        print(f"Iniciando simulación por {duration} segundos...")
        print(f"Intervalo entre datos: {interval} segundos")
        print("Presiona Ctrl+C para detener\n")
        
        start_time = time.time()
        
        try:
            while time.time() - start_time < duration:
                # Generar y mostrar datos
                json_data = self.generate_json_data()
                print(f"[{time.strftime('%H:%M:%S')}] Datos simulados:")
                print(json_data)
                print("-" * 80)
                
                # Actualizar tiempo de simulación
                self.update_simulation_time(interval)
                
                # Esperar hasta el siguiente intervalo
                time.sleep(interval)
                
        except KeyboardInterrupt:
            print("\nSimulación interrumpida por el usuario")
        
        print("Simulación finalizada")


def main():
    """Función principal para ejecutar la simulación."""
    print("=== Simulador de Arduino ===")
    print("Generando datos aleatorios para pruebas del módulo")
    
    simulator = ArduinoSimulator()
    
    # Ejecutar simulación por 60 segundos
    simulator.simulate_data_stream(interval=2.0, duration=60.0)


if __name__ == "__main__":
    main()
