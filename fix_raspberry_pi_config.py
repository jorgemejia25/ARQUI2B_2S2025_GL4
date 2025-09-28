#!/usr/bin/env python3
"""
Script para corregir configuración de Arduino-MQTT en Raspberry Pi
Ajusta automáticamente puertos, configuraciones y crea archivos de entorno
"""

import os
import sys
import json
import subprocess
import shutil
from pathlib import Path

class RaspberryPiConfigFixer:
    def __init__(self):
        self.project_root = Path(__file__).parent
        self.mqtt_dir = self.project_root / "mqtt"
        self.api_dir = self.project_root / "api"
        self.changes_made = []
    
    def detect_arduino_port(self):
        """Detecta automáticamente el puerto del Arduino"""
        possible_ports = ['/dev/ttyUSB0', '/dev/ttyACM0', '/dev/ttyAMA0', '/dev/serial0']
        
        print("🔍 Detectando puerto del Arduino...")
        
        # Verificar puertos existentes
        existing_ports = []
        for port in possible_ports:
            if os.path.exists(port):
                existing_ports.append(port)
                print(f"  ✅ Puerto encontrado: {port}")
        
        if not existing_ports:
            print("  ⚠️ No se encontraron puertos Arduino comunes")
            return '/dev/ttyUSB0'  # Default
        
        # Probar conectividad (requiere permisos)
        for port in existing_ports:
            try:
                # Verificar permisos
                if os.access(port, os.R_OK | os.W_OK):
                    print(f"  ✅ Puerto {port} tiene permisos correctos")
                    return port
                else:
                    print(f"  ⚠️ Puerto {port} sin permisos (ejecutar: sudo usermod -a -G dialout $USER)")
            except Exception as e:
                print(f"  ❌ Error verificando {port}: {e}")
        
        return existing_ports[0] if existing_ports else '/dev/ttyUSB0'
    
    def fix_mqtt_config(self):
        """Corrige configuración MQTT para Raspberry Pi"""
        config_file = self.mqtt_dir / "config.py"
        
        if not config_file.exists():
            print(f"❌ No se encontró {config_file}")
            return False
        
        print(f"🔧 Corrigiendo configuración MQTT...")
        
        # Detectar puerto Arduino
        detected_port = self.detect_arduino_port()
        
        # Leer configuración actual
        with open(config_file, 'r') as f:
            content = f.read()
        
        # Hacer cambios
        original_content = content
        
        # Cambiar puerto
        if '/dev/ttyACM0' in content:
            content = content.replace("'/dev/ttyACM0'", f"'{detected_port}'")
            self.changes_made.append(f"Puerto cambiado a {detected_port}")
        
        # Verificar baudrate
        if '115200' not in content:
            content = content.replace("'baudrate': 9600", "'baudrate': 115200")
            self.changes_made.append("Baudrate cambiado a 115200")
        
        # Guardar si hay cambios
        if content != original_content:
            with open(config_file, 'w') as f:
                f.write(content)
            print(f"  ✅ Configuración actualizada en {config_file}")
            return True
        else:
            print(f"  ℹ️ Configuración ya correcta")
            return False
    
    def create_env_files(self):
        """Crea archivos .env para configuración local de Raspberry Pi"""
        
        # .env para directorio mqtt
        mqtt_env = self.mqtt_dir / ".env"
        mqtt_env_content = """# Configuración MQTT para Raspberry Pi Local
MQTT_BROKER=localhost
MQTT_PORT=1883
MQTT_USERNAME=
MQTT_PASSWORD=
MQTT_TOPIC=arduino/data
"""
        
        if not mqtt_env.exists():
            with open(mqtt_env, 'w') as f:
                f.write(mqtt_env_content)
            print(f"  ✅ Creado {mqtt_env}")
            self.changes_made.append("Archivo .env creado para MQTT")
        else:
            print(f"  ℹ️ Ya existe {mqtt_env}")
        
        # .env para directorio api
        api_env = self.api_dir / ".env"
        api_env_content = """# Configuración API para Raspberry Pi Local
MQTT_BROKER=localhost
MQTT_PORT=1883
MQTT_USERNAME=
MQTT_PASSWORD=
DATABASE_URL=sqlite:///./city_monitoring.db
"""
        
        if not api_env.exists():
            with open(api_env, 'w') as f:
                f.write(api_env_content)
            print(f"  ✅ Creado {api_env}")
            self.changes_made.append("Archivo .env creado para API")
        else:
            print(f"  ℹ️ Ya existe {api_env}")
    
    def create_systemd_services(self):
        """Crea servicios systemd para auto-inicio"""
        
        services_dir = self.project_root / "systemd_services"
        services_dir.mkdir(exist_ok=True)
        
        # Servicio para MQTT
        mqtt_service = services_dir / "arduino-mqtt.service"
        mqtt_service_content = f"""[Unit]
Description=Arduino MQTT Bridge
After=network.target
Wants=network.target

[Service]
Type=simple
User=pi
Group=pi
WorkingDirectory={self.mqtt_dir}
Environment=PATH=/usr/bin:/usr/local/bin
Environment=PYTHONPATH={self.project_root}
ExecStart=/usr/bin/python3 {self.mqtt_dir}/main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
"""
        
        with open(mqtt_service, 'w') as f:
            f.write(mqtt_service_content)
        print(f"  ✅ Servicio MQTT creado: {mqtt_service}")
        
        # Servicio para API
        api_service = services_dir / "city-api.service"
        api_service_content = f"""[Unit]
Description=City Monitoring API
After=network.target
Wants=network.target

[Service]
Type=simple
User=pi
Group=pi
WorkingDirectory={self.api_dir}
Environment=PATH=/usr/bin:/usr/local/bin
Environment=PYTHONPATH={self.project_root}
ExecStart=/usr/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
"""
        
        with open(api_service, 'w') as f:
            f.write(api_service_content)
        print(f"  ✅ Servicio API creado: {api_service}")
        
        # Instrucciones para instalar
        install_script = services_dir / "install_services.sh"
        install_content = f"""#!/bin/bash
# Script para instalar servicios systemd

echo "Instalando servicios systemd..."

# Copiar archivos de servicio
sudo cp {mqtt_service} /etc/systemd/system/
sudo cp {api_service} /etc/systemd/system/

# Recargar systemd
sudo systemctl daemon-reload

# Habilitar servicios
sudo systemctl enable arduino-mqtt.service
sudo systemctl enable city-api.service

echo "Servicios instalados. Para iniciar:"
echo "  sudo systemctl start arduino-mqtt"
echo "  sudo systemctl start city-api"

echo "Para ver logs:"
echo "  sudo journalctl -u arduino-mqtt -f"
echo "  sudo journalctl -u city-api -f"
"""
        
        with open(install_script, 'w') as f:
            f.write(install_content)
        
        # Hacer ejecutable
        os.chmod(install_script, 0o755)
        print(f"  ✅ Script de instalación creado: {install_script}")
        
        self.changes_made.append("Servicios systemd creados")
    
    def check_dependencies(self):
        """Verifica e instala dependencias necesarias"""
        print("📦 Verificando dependencias...")
        
        # Verificar mosquitto (broker MQTT local)
        try:
            result = subprocess.run(['which', 'mosquitto'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                print("  ✅ Mosquitto instalado")
            else:
                print("  ⚠️ Mosquitto no encontrado. Instalar con:")
                print("     sudo apt update && sudo apt install mosquitto mosquitto-clients")
        except Exception as e:
            print(f"  ❌ Error verificando mosquitto: {e}")
        
        # Verificar permisos de usuario para puerto serial
        try:
            import grp
            dialout_group = grp.getgrnam('dialout')
            current_user = os.getenv('USER', 'pi')
            
            if current_user in dialout_group.gr_mem:
                print(f"  ✅ Usuario {current_user} en grupo dialout")
            else:
                print(f"  ⚠️ Usuario {current_user} NO en grupo dialout")
                print(f"     Ejecutar: sudo usermod -a -G dialout {current_user}")
                print("     Luego reiniciar sesión")
        except Exception as e:
            print(f"  ❌ Error verificando permisos: {e}")
    
    def create_startup_script(self):
        """Crea script de inicio manual"""
        startup_script = self.project_root / "start_raspberry_pi.sh"
        
        startup_content = f"""#!/bin/bash
# Script de inicio para Raspberry Pi

echo "🍓 Iniciando sistema de monitoreo en Raspberry Pi..."

# Verificar mosquitto
if ! pgrep -x "mosquitto" > /dev/null; then
    echo "📡 Iniciando broker MQTT local..."
    sudo systemctl start mosquitto
    sleep 2
fi

# Verificar puerto Arduino
ARDUINO_PORT=""
for port in /dev/ttyUSB0 /dev/ttyACM0 /dev/ttyAMA0; do
    if [ -e "$port" ]; then
        echo "🔌 Arduino encontrado en $port"
        ARDUINO_PORT="$port"
        break
    fi
done

if [ -z "$ARDUINO_PORT" ]; then
    echo "❌ No se encontró Arduino. Conectar y reintentar."
    exit 1
fi

# Iniciar API en background
echo "🚀 Iniciando API..."
cd {self.api_dir}
python3 -m uvicorn main:app --host 0.0.0.0 --port 8000 &
API_PID=$!

# Esperar un momento
sleep 3

# Iniciar MQTT bridge
echo "📡 Iniciando bridge MQTT..."
cd {self.mqtt_dir}
python3 main.py

# Cleanup al salir
echo "🛑 Deteniendo servicios..."
kill $API_PID 2>/dev/null
"""
        
        with open(startup_script, 'w') as f:
            f.write(startup_content)
        
        # Hacer ejecutable
        os.chmod(startup_script, 0o755)
        print(f"  ✅ Script de inicio creado: {startup_script}")
        
        self.changes_made.append("Script de inicio creado")
    
    def create_debug_script(self):
        """Crea script de debug específico para Raspberry Pi"""
        debug_script = self.project_root / "debug_raspberry_pi.py"
        
        debug_content = f"""#!/usr/bin/env python3
'''
Script de debug específico para Raspberry Pi
Verifica conexión Arduino, MQTT y envía datos de prueba
'''

import sys
import os
sys.path.append('{self.project_root}')

from test_arduino_mqtt_debug import ArduinoMQTTDebugger

def main():
    print("🍓 DEBUG RASPBERRY PI - Sistema de Monitoreo")
    print("=" * 50)
    
    # Usar configuración local
    import test_arduino_mqtt_debug
    test_arduino_mqtt_debug.MQTT_BROKER = "localhost"
    test_arduino_mqtt_debug.MQTT_PORT = 1883
    
    debugger = ArduinoMQTTDebugger()
    
    print("🔧 Configuración:")
    print(f"   MQTT Broker: localhost:1883")
    print(f"   Puertos Arduino: {test_arduino_mqtt_debug.POSSIBLE_PORTS}")
    print()
    
    # Ejecutar diagnóstico
    success = debugger.run_diagnosis()
    
    if success:
        print("\\n✅ Diagnóstico completado exitosamente")
        print("\\nSi no se detectaron infracciones:")
        print("1. Verificar que Arduino esté enviando datos")
        print("2. Simular infracción acercando objeto a sensor SD")
        print("3. Verificar que semáforos estén en ROJO")
    else:
        print("\\n❌ Diagnóstico falló")
        print("\\nPosibles soluciones:")
        print("1. Verificar conexión USB del Arduino")
        print("2. Instalar broker MQTT: sudo apt install mosquitto")
        print("3. Agregar usuario a grupo dialout: sudo usermod -a -G dialout $USER")

if __name__ == "__main__":
    main()
"""
        
        with open(debug_script, 'w') as f:
            f.write(debug_content)
        
        # Hacer ejecutable
        os.chmod(debug_script, 0o755)
        print(f"  ✅ Script de debug creado: {debug_script}")
        
        self.changes_made.append("Script de debug para Raspberry Pi creado")
    
    def run_fixes(self):
        """Ejecuta todas las correcciones"""
        print("🔧 CORRECTOR DE CONFIGURACIÓN RASPBERRY PI")
        print("=" * 50)
        
        # 1. Corregir configuración MQTT
        self.fix_mqtt_config()
        
        # 2. Crear archivos .env
        print("\n📁 Creando archivos de configuración...")
        self.create_env_files()
        
        # 3. Crear servicios systemd
        print("\n⚙️ Creando servicios systemd...")
        self.create_systemd_services()
        
        # 4. Crear script de inicio
        print("\n🚀 Creando scripts de inicio...")
        self.create_startup_script()
        
        # 5. Crear script de debug
        print("\n🐛 Creando script de debug...")
        self.create_debug_script()
        
        # 6. Verificar dependencias
        print("\n📦 Verificando dependencias...")
        self.check_dependencies()
        
        # Resumen
        print("\n" + "=" * 50)
        print("✅ CORRECCIONES COMPLETADAS")
        print("=" * 50)
        
        if self.changes_made:
            print("Cambios realizados:")
            for change in self.changes_made:
                print(f"  • {change}")
        else:
            print("• No se requirieron cambios")
        
        print("\\n📋 PRÓXIMOS PASOS:")
        print("1. Ejecutar debug: python3 debug_raspberry_pi.py")
        print("2. Si todo funciona, instalar servicios: ./systemd_services/install_services.sh")
        print("3. O iniciar manualmente: ./start_raspberry_pi.sh")
        
        return True

def main():
    """Función principal"""
    if os.getenv('USER') == 'root':
        print("⚠️ No ejecutar como root. Usar usuario normal (pi)")
        return
    
    fixer = RaspberryPiConfigFixer()
    fixer.run_fixes()

if __name__ == "__main__":
    main()
