import argparse
from ia_modules.face_recognition.infrastructure.camera import ThreadedCapture
from ia_modules.face_recognition.infrastructure.detector import FaceRecognitionDetector
from ia_modules.face_recognition.usecases.run_recognition import build_templates, run_loop


def parse_args():
    p = argparse.ArgumentParser(description="Face recognition CLI (clean architecture)")
    p.add_argument("--gallery", default="./gallery")
    p.add_argument("--camera", type=int, default=0)
    p.add_argument("--fps", type=int, default=30)
    p.add_argument("--width", type=int, default=640)
    p.add_argument("--height", type=int, default=480)
    p.add_argument("--detect_model", choices=["hog", "cnn"], default="hog")
    p.add_argument("--upsample", type=int, default=0)
    p.add_argument("--downscale", type=float, default=0.75)
    p.add_argument("--threshold", type=float, default=0.50)
    p.add_argument("--margin", type=float, default=0.05)
    p.add_argument("--detect_every_n", type=int, default=3)
    p.add_argument("--cooldown", type=int, default=8)
    p.add_argument("--window_size", type=int, default=5)
    p.add_argument("--min_votes", type=int, default=3)
    p.add_argument("--no_save", action="store_true")
    p.add_argument("--skip_draw", action="store_true")
    return p.parse_args()


def main():
    args = parse_args()
    detector = FaceRecognitionDetector(model=args.detect_model, upsample=args.upsample)
    templates, counts = build_templates(args.gallery, detector)
    cam = ThreadedCapture(index=args.camera, fps=args.fps, width=args.width, height=args.height).start()
    try:
        run_loop(
            cam=cam,
            detector=detector,
            templates=templates,
            threshold=args.threshold,
            margin=args.margin,
            detect_every_n=args.detect_every_n,
            cooldown_s=args.cooldown,
            use_temporal_voting=True,
            window_size=args.window_size,
            min_votes=args.min_votes,
            downscale=args.downscale,
            save_events=not args.no_save,
            skip_draw=args.skip_draw,
        )
    finally:
        cam.stop()


if __name__ == "__main__":
    main()


