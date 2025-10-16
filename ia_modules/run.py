"""
AI Modules System - Main Runner
Coordinates multiple AI modules with shared camera access
"""
import os
import sys

# Ensure native backends see our env vars. If we haven't set the ready flag,
# set the common vars and re-exec the Python process so C/C++ libraries start
# with these variables already set. This prevents repeated NNPACK warnings.
if os.environ.get("__IA_ENV_READY") != "1":
    os.environ.setdefault("GLOG_minloglevel", "3")
    os.environ.setdefault("CAFFE2_LOG_LEVEL", "3")
    os.environ.setdefault("TORCH_CPP_LOG_LEVEL", "ERROR")
    os.environ.setdefault("CLOG_LOG_LEVEL", "3")
    os.environ.setdefault("NNPACK_LOG_LEVEL", "3")
    os.environ.setdefault("OMP_NUM_THREADS", "1")
    os.environ["__IA_ENV_READY"] = "1"
    # Re-exec Python with the same argv to ensure native libs pick up env
    os.execve(sys.executable, [sys.executable] + sys.argv, os.environ)

import argparse
import cv2
import signal
import time
from typing import Optional

class _OnceNNPACKFilter:
    """Intercept stderr to print NNPACK warning only once"""
    def __init__(self, stream):
        self._stream = stream
        self._printed_nnpack = False
    def write(self, s):
        try:
            if "Could not initialize NNPACK!" in s:
                if self._printed_nnpack:
                    return
                self._printed_nnpack = True
        except Exception:
            pass
        return self._stream.write(s)
    def flush(self):
        return self._stream.flush()
    def __getattr__(self, name):
        return getattr(self._stream, name)

# Install filter early
sys.stderr = _OnceNNPACKFilter(sys.stderr)

from core import SharedCamera, ModuleManager
from modules import FaceRecognitionModule, PlateDetectionModule
from modules import FaceRecognitionModule, WeaponDetectionModule

# PARA LA DETECCION DE PLACAS CUANDO HAYA INFRACCION
import threading
from fastapi import FastAPI, Request
import uvicorn
import asyncio
from core.trigger_state import capture_next_plate


def start_trigger_server():
    app = FastAPI()

    @app.post("/api/deteccion")
    async def trigger_detection(request: Request):
        from core import trigger_state
        data = await request.json()
        tipo_evento = data.get("tipo_evento")
        ubicacion = data.get("ubicacion", "Entrada Principal")

        if tipo_evento == "infraccion_detectada":
            trigger_state.capture_next_plate = True
            trigger_state.last_location = ubicacion 
            print(f"[Trigger] Infracción detectada en {ubicacion} → activando detección de placa.")
            return {"status": "ok", "message": f"Trigger recibido para {ubicacion}"}
        return {"status": "ignored"}


    config = uvicorn.Config(app, host="0.0.0.0", port=5001, log_level="warning")
    server = uvicorn.Server(config)
    asyncio.run(server.serve())

# Lanzar el servidor en segundo plano al iniciar el sistema
def launch_trigger_thread():
    thread = threading.Thread(target=start_trigger_server, daemon=True)
    thread.start()
    print("[Trigger] Servidor de detección iniciado en puerto 5001")


class AISystem:
    """Main AI system coordinator"""
    
    def __init__(self, args):
        self.args = args
        self.camera: Optional[SharedCamera] = None
        self.manager: Optional[ModuleManager] = None
        self.running = False
        self.show_display = True
        self.selected_module = None
        
        # Setup signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self._handle_shutdown)
        signal.signal(signal.SIGTERM, self._handle_shutdown)
    
    def _handle_shutdown(self, signum, frame):
        """Handle shutdown signals"""
        print(f"\n[System] Received shutdown signal ({signum})")
        self.stop()
        sys.exit(0)
    
    def start(self) -> bool:
        """Initialize and start the AI system"""
        print("="*70)
        print("AI MODULES SYSTEM")
        print("="*70)
        print("Select which module to run:")
        print("  1) Face Recognition")
        print("  2) Plate Detection")
        print("  3) Weapons Detection")
        choice = input("Enter choice (1, 2 or 3): ").strip()

        if choice == "1":
            self.selected_module = "face_recognition"
        elif choice == "2":
            self.selected_module = "plate_detection"
        elif choice == "3":
            self.selected_module = "weapons_detection"
        else:
            print("Invalid option. Exiting.")
            return False
        
        # Initialize camera
        self.camera = SharedCamera(
            camera_id=self.args.camera,
            fps=self.args.fps,
            width=self.args.width,
            height=self.args.height
        )
        
        if not self.camera.start():
            print("[System] Failed to start camera")
            return False
        
        # Initialize module manager
        self.manager = ModuleManager(self.camera)
        
        # Select which module to load
        if self.selected_module == "face_recognition":
            if not self._setup_face_recognition():
                print("[System] Failed to setup face recognition")
                return False
        elif self.selected_module == "plate_detection":
            if not self._setup_plate_detection():
                print("[System] Failed to setup plate detection")
                return False
        # Add face recognition module (don't abort if it fails)
        if not self._setup_face_recognition():
            print("[System] Warning: Failed to setup face recognition, continuing without it")

        # Add weapon detection module (YOLO)
        if not self._setup_weapon_detection():
            print("[System] Warning: Failed to setup weapon detection, continuing without it")
        
        # Print status
        self.manager.print_status()
        
        self.running = True
        print("[System] System ready!")
        print("[System] Controls: ESC=quit | S=status | D=toggle display")
        
        return True
    
    def _setup_face_recognition(self) -> bool:
        """Setup face recognition module"""
        config = {
            "gallery_dir": "gallery",
            "api_url": "http://localhost:8001/api/v1/blacklist-events",
            "threshold": self.args.threshold,
            "detect_every": self.args.detect_every,
            "cooldown": self.args.cooldown,
            "camera_location": str(self.args.camera)
        }
        
        face_module = FaceRecognitionModule(config)
        return self.manager.add_module(face_module)

    def _setup_weapon_detection(self) -> bool:
        """Setup weapon detection (YOLOv8) module"""
        # Try to use trained weights if present; otherwise fallback happens inside module
        config = {
            "weights_path": "models/weapons/best.pt",  # preferred relative location
            "api_url": "http://localhost:8001/api/v1/weapon-detections",
            "cooldown": 5,  # seconds
            "camera_location": str(self.args.camera),
            "conf": self.args.yolo_conf,
            "imgsz": self.args.yolo_imgsz,
            "detect_every": self.args.yolo_detect_every,
            "gap": self.args.yolo_gap,
            "update_interval": self.args.yolo_update_interval,
            "real_width_cm": self.args.yolo_real_width_cm,
            "assume_first_dist_cm": self.args.yolo_assume_first_dist_cm,
        }
        weapon_module = WeaponDetectionModule(config)
        return self.manager.add_module(weapon_module)
    
    def _setup_plate_detection(self) -> bool:
        """Setup plate detection module"""
        config = {
            "api_url": "http://localhost:8001/api/v1/plate-events",
            "confidence_threshold": 0.45,
            "camera_location": str(self.args.camera),
            "events_dir": "events",
            "cooldown": 6
        }

        plate_module = PlateDetectionModule(config)
        return self.manager.add_module(plate_module)
    
    def run(self):
        """Main processing loop"""
        frame_id = 0
        window_name = (
            "AI Modules System - Face Recognition"
            if self.selected_module == "face_recognition"
            else "AI Modules System - Plate Detection"
            if self.selected_module == "plate_detection"
            else "AI Modules System - Weapons Detection"
        )
        
        while self.running:
            # Read frame from camera
            ret, frame = self.camera.read()
            
            if not ret or frame is None:
                time.sleep(0.01)
                continue
            
            # Process frame through all modules
            results = self.manager.process_frame(frame, frame_id)
            
            # Draw results if display enabled
            if self.show_display:
                display_frame = self.manager.draw_results(frame, results)
                cv2.imshow(window_name, display_frame)
            
            # Handle keyboard input
            key = cv2.waitKey(1) & 0xFF
            
            if key == 27:  # ESC
                break
            elif key == ord('s') or key == ord('S'):
                self.manager.print_status()
            elif key == ord('d') or key == ord('D'):
                self.show_display = not self.show_display
                if not self.show_display:
                    cv2.destroyAllWindows()
                print(f"[System] Display: {'ON' if self.show_display else 'OFF'}")
            
            frame_id += 1
        
        self.stop()
    
    def stop(self):
        """Stop the AI system"""
        if not self.running:
            return
        
        print("[System] Shutting down...")
        self.running = False
        
        if self.manager:
            self.manager.shutdown_all()
        
        if self.camera:
            self.camera.stop()
        
        cv2.destroyAllWindows()
        print("[System] Shutdown complete")


def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description="AI Modules System - Modular AI Processing Framework",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Run with defaults
  python -m ia_modules.run
  
  # Custom threshold and cooldown
  python -m ia_modules.run --threshold 0.45 --cooldown 5
  
  # Use different camera
  python -m ia_modules.run --camera 1
        """
    )
    
    # Camera settings
    camera_group = parser.add_argument_group('Camera Settings')
    camera_group.add_argument('--camera', type=int, default=0,
                             help='Camera device ID (default: 0)')
    camera_group.add_argument('--fps', type=int, default=30,
                             help='Target FPS (default: 30)')
    camera_group.add_argument('--width', type=int, default=640,
                             help='Frame width (default: 640)')
    camera_group.add_argument('--height', type=int, default=480)
    
    # Face recognition settings
    face_group = parser.add_argument_group('Face Recognition Settings')
    face_group.add_argument('--threshold', type=float, default=0.50,
                           help='Recognition threshold (default: 0.50)')
    face_group.add_argument('--cooldown', type=int, default=8,
                           help='Cooldown between detections in seconds (default: 8)')
    face_group.add_argument('--detect-every', type=int, default=3,
                           help='Process every N frames (default: 3)')
    
    # Weapon detection (YOLO) settings
    yolo_group = parser.add_argument_group('Weapon Detection (YOLO) Settings')
    yolo_group.add_argument('--yolo-conf', type=float, default=0.25,
                            help='YOLO confidence threshold (default: 0.25)')
    yolo_group.add_argument('--yolo-imgsz', type=int, default=416,
                            help='YOLO image size (default: 416)')
    yolo_group.add_argument('--yolo-detect-every', type=int, default=1,
                            help='Process every N frames for YOLO (default: 1)')
    yolo_group.add_argument('--yolo-gap', type=int, default=3,
                            help='Frames without detection before marking class absent (default: 3)')
    yolo_group.add_argument('--yolo-update-interval', type=float, default=2.0,
                            help='Seconds between TOP prints (default: 2.0)')
    yolo_group.add_argument('--yolo-real-width-cm', type=float, default=None,
                            help='Real object width in cm (for distance in cm)')
    yolo_group.add_argument('--yolo-assume-first-dist-cm', type=float, default=None,
                            help='Assume first occurrence is at this distance (cm) to auto-calibrate per class')

    return parser.parse_args()


def main():
    """Main entry point"""
    try:
        args = parse_arguments()

        launch_trigger_thread()
        
        # Create and start system
        system = AISystem(args)

        time.sleep(2)
        print("[Trigger] Servidor de detección listo para recibir eventos.")


        if not system.start():
            print("[Main] Failed to start system")
            return 1
        
        # Run main loop
        system.run()
        
        return 0
        
    except KeyboardInterrupt:
        print("\n[Main] Interrupted by user")
        return 0
    except Exception as e:
        print(f"[Main] Fatal error: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
