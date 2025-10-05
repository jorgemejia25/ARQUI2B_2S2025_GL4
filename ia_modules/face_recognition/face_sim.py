import os, time, glob, csv, argparse
from pathlib import Path
from typing import List, Dict, Tuple
import numpy as np
import cv2
import face_recognition

# ------------------------ Utilidades ------------------------ #
def imread_any(path: str):
    # Soporta rutas con UTF-8 en Windows
    data = np.fromfile(path, dtype=np.uint8)
    img = cv2.imdecode(data, cv2.IMREAD_COLOR)
    return img

def load_images(folder: str) -> List[np.ndarray]:
    exts = ("*.jpg", "*.jpeg", "*.png", "*.bmp")
    paths = []
    for e in exts:
        paths.extend(glob.glob(os.path.join(folder, e)))
    imgs = []
    for p in paths:
        img = imread_any(p)
        if img is not None:
            imgs.append(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
    return imgs

def compute_face_encodings(img: np.ndarray, model: str = "hog") -> List[np.ndarray]:
    boxes = face_recognition.face_locations(img, model=model)
    return face_recognition.face_encodings(img, boxes)

def normalize(v: np.ndarray) -> np.ndarray:
    n = np.linalg.norm(v) + 1e-12
    return v / n

def average_embedding(embs: List[np.ndarray]) -> np.ndarray:
    if len(embs) == 0:
        return None
    m = np.mean(np.stack(embs, axis=0), axis=0)
    return normalize(m)

# -------------------- Carga Blacklist (plantillas) -------------------- #
def load_blacklist(gallery_dir: str, detect_model: str) -> Tuple[Dict[str, np.ndarray], Dict[str, int]]:
    """
    Devuelve:
      - templates: {persona -> embedding_promedio_normalizado}
      - counts:    {persona -> #muestras válidas}
    """
    templates: Dict[str, np.ndarray] = {}
    counts: Dict[str, int] = {}
    subdirs = sorted([d for d in os.listdir(gallery_dir)
                      if os.path.isdir(os.path.join(gallery_dir, d))])
    if not subdirs:
        print(f"[BLACKLIST] No se encontraron carpetas en {gallery_dir}")
    for person in subdirs:
        folder = os.path.join(gallery_dir, person)
        imgs = load_images(folder)
        per_embs = []
        for img in imgs:
            encs = compute_face_encodings(img, model=detect_model)
            if len(encs) > 0:
                per_embs.append(encs[0])  # suponemos 1 rostro por imagen
        avg = average_embedding(per_embs)
        if avg is not None:
            templates[person] = avg.astype(np.float32)
            counts[person] = len(per_embs)
            print(f"[BLACKLIST] {person}: {len(per_embs)} muestras → OK")
        else:
            print(f"[BLACKLIST] {person}: SIN muestras válidas (revisa imágenes)")
    if not templates:
        print("[BLACKLIST] Vacía: sin embeddings cargados.")
    return templates, counts

# ------------------------ Comparación ------------------------ #
def rank_by_distance(e: np.ndarray, templates: Dict[str, np.ndarray]) -> List[Tuple[str, float]]:
    # e y plantillas normalizados → L2 ~ coseno
    e = normalize(e)
    items = []
    for name, c in templates.items():
        d = float(np.linalg.norm(e - c))
        items.append((name, d))
    items.sort(key=lambda x: x[1])
    return items

def decide_match(sorted_dists: List[Tuple[str, float]], T: float, margin: float) -> Tuple[str, float, float]:
    """
    sorted_dists: [(name, d1), (name2, d2), ...] ordenado ascendente por distancia
    Retorna: (etiqueta, d1, d2)  con etiqueta="DESCONOCIDO" si falla criterios
    Regla: d1 < T y (d2 - d1) >= margin
    """
    if not sorted_dists:
        return "DESCONOCIDO", 9.99, 9.99
    name1, d1 = sorted_dists[0]
    name2, d2 = (("—", 9.99) if len(sorted_dists) < 2 else sorted_dists[1])
    if d1 < T and (d2 - d1) >= margin:
        return name1, d1, d2
    return "DESCONOCIDO", d1, d2

# ---------------------- Guardado de eventos ---------------------- #
def ensure_events_dir(base="events"):
    Path(base).mkdir(parents=True, exist_ok=True)
    csv_path = Path(base) / "events.csv"
    if not csv_path.exists():
        with open(csv_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(["timestamp", "label", "d_best", "d_second", "file"])
    return str(csv_path)

def save_event_snapshot(frame_bgr: np.ndarray, label: str, d1: float, d2: float, base="events") -> None:
    ensure_events_dir(base)
    ts = int(time.time())
    fname = f"{ts}_{label.replace(' ', '_')}_{d1:.3f}.jpg"
    path = str(Path(base) / fname)
    cv2.imwrite(path, frame_bgr)
    with open(Path(base) / "events.csv", "a", newline="", encoding="utf-8") as f:
        csv.writer(f).writerow([ts, label, f"{d1:.4f}", f"{d2:.4f}", fname])

# ------------------------ Suavizado temporal ------------------------ #
class TemporalVoter:
    """
    N-de-M: guarda últimas M decisiones (labels) y aprueba cuando
    una etiqueta alcanza N apariciones.
    """
    def __init__(self, M: int = 5, N: int = 3):
        self.M = M
        self.N = N
        self.buffer: List[str] = []

    def vote(self, label: str) -> Tuple[bool, str]:
        self.buffer.append(label)
        if len(self.buffer) > self.M:
            self.buffer.pop(0)
        # cuenta por etiqueta
        uniq = set(self.buffer)
        best_label, best_count = None, 0
        for lb in uniq:
            c = self.buffer.count(lb)
            if c > best_count:
                best_label, best_count = lb, c
        confirmed = (best_label is not None) and (best_count >= self.N) and (best_label != "DESCONOCIDO")
        return confirmed, best_label if confirmed else label

# --------------------------- Main loop --------------------------- #
class ThreadedCapture:
    """Lectura de cámara en hilo separado para reducir latencia y desacoplar captura de procesamiento."""
    def __init__(self, cap: cv2.VideoCapture):
        import threading
        self.cap = cap
        self.latest = None
        self.ok = False
        self.stopped = False
        self.lock = threading.Lock()
        self.th = threading.Thread(target=self._loop, daemon=True)

    def start(self):
        self.th.start()
        return self

    def _loop(self):
        import time as _t
        while not self.stopped:
            ok, frame = self.cap.read()
            if not ok:
                self.ok = False
                _t.sleep(0.005)
                continue
            with self.lock:
                self.latest = frame
                self.ok = True
            # Pequeño respiro para no monopolizar CPU
            _t.sleep(0.0001)

    def read(self):
        with self.lock:
            return (self.ok, None if self.latest is None else self.latest.copy())

    def stop(self):
        self.stopped = True
        try:
            self.th.join(timeout=0.5)
        except Exception:
            pass

def run(
    gallery_dir: str = "./gallery",
    camera_index: int = 0,
    detect_model: str = "hog",
    downscale: float = 0.75,
    threshold: float = 0.50,
    margin: float = 0.05,
    detect_every_n: int = 3,
    cooldown_s: int = 8,
    use_temporal_voting: bool = True,
    M: int = 5, N: int = 3,
    save_events: bool = True,
    fps: int = 30,
    width: int = None,
    height: int = None,
    upsample: int = 0,
    skip_draw: bool = False,
):
    templates, counts = load_blacklist(gallery_dir, detect_model)
    if not templates:
        print("⚠️  Blacklist vacía. Agrega carpetas e imágenes a 'gallery/'.")
    last_report: Dict[str, float] = {}

    cap = cv2.VideoCapture(camera_index)
    if not cap.isOpened():
        print("❌ No se pudo abrir la cámara.")
        return
    # Intentar configurar FPS de la cámara
    try:
        cap.set(cv2.CAP_PROP_FPS, float(fps))
    except Exception:
        pass
    # Reducir latencia del búfer
    try:
        cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
    except Exception:
        pass
    # Forzar MJPG si está disponible (suele mejorar throughput en webcams)
    try:
        fourcc = cv2.VideoWriter_fourcc(*"MJPG")
        cap.set(cv2.CAP_PROP_FOURCC, fourcc)
    except Exception:
        pass
    # Ajustar resolución si se especifica
    if width is not None:
        try:
            cap.set(cv2.CAP_PROP_FRAME_WIDTH, float(width))
        except Exception:
            pass
    if height is not None:
        try:
            cap.set(cv2.CAP_PROP_FRAME_HEIGHT, float(height))
        except Exception:
            pass

    voter = TemporalVoter(M=M, N=N)
    print("[INFO] Presiona ESC para salir.")
    frame_id = 0

    # Iniciar lectura en hilo para reducir latencia
    cam = ThreadedCapture(cap).start()
    # Warmup: esperar a primer frame válido (útil en macOS por permisos/latencia)
    import time as _t
    warm_ok = False
    for _ in range(100):  # ~5s máximo
        ok_w, _frame_w = cam.read()
        if ok_w and _frame_w is not None:
            warm_ok = True
            break
        _t.sleep(0.05)
    if not warm_ok:
        print("⚠️ Esperando acceso a la cámara... revisa permisos y que el índice sea correcto.")

    fail_count = 0
    while True:
        ok, frame_bgr_full = cam.read()
        if not ok or frame_bgr_full is None:
            fail_count += 1
            if fail_count % 30 == 0:
                print("❌ Frame no disponible (reintentando)...")
            if fail_count > 300:  # ~10s con 30 avisos
                print("❌ Frame no disponible de forma persistente. Abortando.")
                break
            _t.sleep(0.03)
            continue
        else:
            fail_count = 0

        # Downscale para acelerar
        if downscale != 1.0:
            frame_bgr = cv2.resize(frame_bgr_full, None, fx=downscale, fy=downscale, interpolation=cv2.INTER_LINEAR)
        else:
            frame_bgr = frame_bgr_full

        rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)

        # Detección: permite saltar frames para mejorar FPS si detect_every_n > 1
        do_detect = (detect_every_n <= 1) or (frame_id % detect_every_n == 0)
        if do_detect:
            # upsample=0 acelera mucho HOG; subir a 1 ayuda si rostros pequeños
            boxes = face_recognition.face_locations(
                rgb,
                number_of_times_to_upsample=int(max(0, upsample)),
                model=detect_model,
            )
            encs = face_recognition.face_encodings(rgb, boxes)
        else:
            boxes, encs = [], []

        labels_shown = []
        for (top, right, bottom, left), enc in zip(boxes, encs):
            enc = normalize(enc)
            ranked = rank_by_distance(enc, templates) if templates else []
            label, d1, d2 = decide_match(ranked, T=threshold, margin=margin)

            # Suavizado temporal
            final_label = label
            if use_temporal_voting:
                confirmed, voted = voter.vote(label)
                final_label = voted if confirmed else label

            # Dibujo opcional
            is_match = (final_label != "DESCONOCIDO")
            if not skip_draw:
                color = (0, 200, 80) if is_match else (70, 70, 220)
                cv2.rectangle(frame_bgr, (left, top), (right, bottom), color, 2)
                tag = f"{final_label}  d1={d1:.2f}  thr={threshold}  Δ={max(0.0, (d2-d1)):.2f}"
                cv2.putText(frame_bgr, tag, (left, max(top-10, 15)),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.55, color, 2)

            # Cooldown y guardado de evento (solo si match)
            if is_match and save_events:
                now = time.time()
                if final_label not in last_report or (now - last_report[final_label]) > cooldown_s:
                    # Guardamos snapshot del rostro recortado (o del frame con caja)
                    y1, y2 = max(0, top-10), min(frame_bgr.shape[0], bottom+10)
                    x1, x2 = max(0, left-10), min(frame_bgr.shape[1], right+10)
                    crop = frame_bgr[y1:y2, x1:x2].copy()
                    save_event_snapshot(crop, final_label, d1, d2, base="events")
                    last_report[final_label] = now
                    # Marcador visual
                    cv2.circle(frame_bgr, (left, top), 6, (0, 255, 255), -1)

            labels_shown.append(final_label)

        # Mostrar tamaño original en la ventana
        shown = frame_bgr
        if downscale != 1.0:
            shown = cv2.resize(frame_bgr, (frame_bgr_full.shape[1], frame_bgr_full.shape[0]))
        if not skip_draw:
            cv2.imshow("FaceSim (Blacklist, Webcam)", shown)

        frame_id += 1
        if (cv2.waitKey(1) & 0xFF) == 27:  # ESC
            break

    cam.stop()
    cap.release()
    cv2.destroyAllWindows()

# ----------------------------- CLI ----------------------------- #
def parse_args():
    p = argparse.ArgumentParser(description="Simulador de reconocimiento con webcam + blacklist (sin DB/MQTT)")
    p.add_argument("--gallery", default="./gallery", help="Carpeta con subcarpetas por persona")
    p.add_argument("--camera", type=int, default=0, help="Índice de cámara (0 por defecto)")
    p.add_argument("--detect_model", choices=["hog", "cnn"], default="hog", help="Detector: hog (CPU) o cnn (GPU)")
    p.add_argument("--downscale", type=float, default=0.75, help="Factor de reducción para acelerar (1.0 = sin reducción)")
    p.add_argument("--threshold", type=float, default=0.50, help="Umbral L2 para match (más bajo = más estricto)")
    p.add_argument("--margin", type=float, default=0.05, help="Margen vs segundo mejor (anti-confusión)")
    p.add_argument("--detect_every_n", type=int, default=3, help="(Opcional) Detectar 1 de cada N frames")
    p.add_argument("--cooldown", type=int, default=8, help="Segundos mínimos entre eventos por persona")
    p.add_argument("--no_temporal", action="store_true", help="Desactivar votación temporal N-de-M")
    p.add_argument("--M", type=int, default=5, help="Ventana temporal (M)")
    p.add_argument("--N", type=int, default=3, help="Votos mínimos para confirmar (N)")
    p.add_argument("--no_save", action="store_true", help="No guardar snapshots de eventos")
    p.add_argument("--fps", type=int, default=30, help="Intentar configurar FPS de la cámara")
    p.add_argument("--width", type=int, default=None, help="Ancho deseado de captura (p.ej. 640)")
    p.add_argument("--height", type=int, default=None, help="Alto deseado de captura (p.ej. 480)")
    p.add_argument("--upsample", type=int, default=0, help="Veces de upsample en detección (0 acelera)")
    p.add_argument("--skip_draw", action="store_true", help="No dibujar ni mostrar ventana para maximizar FPS")
    return p.parse_args()

if __name__ == "__main__":
    # Deprecated: delegate to package CLI ensuring module path
    import sys, os
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    if repo_root not in sys.path:
        sys.path.insert(0, repo_root)
    from ia_modules.face_recognition.cli import main as cli_main  # type: ignore
    cli_main()