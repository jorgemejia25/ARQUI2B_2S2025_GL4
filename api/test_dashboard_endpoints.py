#!/usr/bin/env python3
"""
Script para probar los endpoints del dashboard y verificar que devuelven datos correctos
"""

import requests
import json

BASE_URL = "https://arqui2b2s2025gl4-production.up.railway.app/api/v1/data/dashboard"

def test_endpoint(endpoint_name, url):
    """Probar un endpoint específico"""
    print(f"\n🧪 Probando {endpoint_name}...")
    print(f"URL: {url}")
    
    try:
        response = requests.get(url, timeout=10)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Respuesta exitosa")
            print(f"Datos recibidos: {json.dumps(data, indent=2, ensure_ascii=False)}")
            return True
        else:
            print(f"❌ Error: {response.status_code}")
            print(f"Respuesta: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Excepción: {e}")
        return False

def main():
    print("🚀 Probando endpoints del dashboard...")
    
    endpoints = [
        ("Resumen del Dashboard", f"{BASE_URL}/summary"),
        ("Datos de Gas", f"{BASE_URL}/charts/gas"),
        ("Datos Sísmicos", f"{BASE_URL}/charts/seismic"),
    ]
    
    results = []
    for name, url in endpoints:
        success = test_endpoint(name, url)
        results.append((name, success))
    
    print("\n" + "="*50)
    print("RESUMEN DE PRUEBAS:")
    print("="*50)
    
    for name, success in results:
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{name}: {status}")
    
    all_passed = all(success for _, success in results)
    if all_passed:
        print("\n🎉 ¡Todos los endpoints funcionan correctamente!")
    else:
        print("\n⚠️  Algunos endpoints tienen problemas")

if __name__ == "__main__":
    main()
