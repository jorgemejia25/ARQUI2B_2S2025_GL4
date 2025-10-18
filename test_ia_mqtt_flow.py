#!/usr/bin/env python3
"""
Test script to verify IA events flow through MQTT to Serial Bridge
"""

import json
import time
import requests
from datetime import datetime

API_BASE = "http://localhost:8001/api/v1"

def test_weapon_detection():
    """Test weapon detection event"""
    print("\n" + "="*70)
    print("TESTING WEAPON DETECTION EVENT")
    print("="*70)
    
    payload = {
        "name": "knife",
        "distance": 45.5,
        "camera_location": "Main Camera"
    }
    
    print(f"Sending to API: {json.dumps(payload, indent=2)}")
    
    try:
        response = requests.post(
            f"{API_BASE}/weapon-detections",
            json=payload,
            timeout=5
        )
        print(f"Response status: {response.status_code}")
        print(f"Response body: {response.json()}")
        return response.status_code == 201
    except Exception as e:
        print(f"ERROR: {e}")
        return False


def test_blacklist_detection():
    """Test blacklist detection event"""
    print("\n" + "="*70)
    print("TESTING BLACKLIST DETECTION EVENT")
    print("="*70)
    
    payload = {
        "person_name": "JORGE_MEJIA",
        "confidence": 0.85,
        "distance": 50.0,
        "camera_location": "Main Camera"
    }
    
    print(f"Sending to API: {json.dumps(payload, indent=2)}")
    
    try:
        response = requests.post(
            f"{API_BASE}/blacklist-events",
            json=payload,
            timeout=5
        )
        print(f"Response status: {response.status_code}")
        print(f"Response body: {response.json()}")
        return response.status_code == 201
    except Exception as e:
        print(f"ERROR: {e}")
        return False


def test_plate_detection():
    """Test plate detection event"""
    print("\n" + "="*70)
    print("TESTING PLATE DETECTION EVENT")
    print("="*70)
    
    payload = {
        "plate_text": "ABC123",
        "confidence": 0.92,
        "camera_location": "Entrada Principal",
        "image_base64": "test_image_data"
    }
    
    print(f"Sending to API: {json.dumps(payload, indent=2)}")
    
    try:
        response = requests.post(
            f"{API_BASE}/plate-events",
            json=payload,
            timeout=5
        )
        print(f"Response status: {response.status_code}")
        print(f"Response body: {response.json()}")
        return response.status_code == 201
    except Exception as e:
        print(f"ERROR: {e}")
        return False


def main():
    """Run all tests"""
    print("="*70)
    print("IA EVENTS TO MQTT FLOW TEST")
    print("="*70)
    print(f"Timestamp: {datetime.now()}")
    print("="*70)
    print("\nMake sure the following services are running:")
    print("  1. API (python api/run.py)")
    print("  2. MQTT Serial Bridge (python mqtt_serial_bridge/run.py)")
    print("="*70)
    
    input("\nPress ENTER to start tests...")
    
    results = []
    
    # Test weapon detection
    results.append(("Weapon Detection", test_weapon_detection()))
    time.sleep(1)
    
    # Test blacklist detection
    results.append(("Blacklist Detection", test_blacklist_detection()))
    time.sleep(1)
    
    # Test plate detection
    results.append(("Plate Detection", test_plate_detection()))
    
    # Print summary
    print("\n" + "="*70)
    print("TEST SUMMARY")
    print("="*70)
    for test_name, success in results:
        status = "PASS" if success else "FAIL"
        print(f"{test_name}: {status}")
    print("="*70)
    
    print("\nCheck the MQTT Serial Bridge console for:")
    print("  - 'Received MQTT message from arduino/commands/...'")
    print("  - '[SIMULATION] Serial command would be sent: ALERTA,...'")
    print("="*70)


if __name__ == "__main__":
    main()


