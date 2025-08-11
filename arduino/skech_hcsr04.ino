/*
  Ciudad – 9 sensores (Transmetro + Transurbano)
  Serial 115200 (Virtual Terminal): TM/... y TU/... eventos y ETA.
  - ETA se imprime en segundos (s) con 2 decimales.
  - Distancias en cm.
*/

#include <Arduino.h>

// ---------- Mapeo de sensores ----------
enum {
  TM1 = 0, TM2 = 1,          // Transmetro (paradas)
  TU1 = 2, TU2 = 3, TU3 = 4, // Transurbano (TU1 y TU6 son paradas)
  TU4 = 5, TU5 = 6, TU6 = 7, TU7 = 8
};

// Pines TRIG/ECHO para 9 HC-SR04 (ajusta a tu cableado)
struct UPin { uint8_t trig, echo; };
const UPin US_PINS[9] = {
  {22,23}, {24,25},             // TM1, TM2
  {26,27}, {28,29}, {30,31},    // TU1, TU2, TU3
  {32,33}, {34,35}, {36,37}, {38,39}  // TU4, TU5, TU6, TU7
};

// ---------- Parámetros ----------
const float  THR_STOP_CM   = 5.0f;     // en parada (TM1, TM2, TU1, TU6)
const float  THR_ROUTE_CM  = 10.0f;    // presencia en ruta (TU2,3,4,5,7)
const uint32_t STABLE_MS   = 300UL;    // >= 0.3 s (ajusta a 3000UL si quieres 3 s)
const unsigned long ECHO_TIMEOUT_US = 20000UL; // 20 ms

// Velocidades promedio (cm/s) – constantes (sin SPD dinámico)
float v_tm = 12.0f;
float v_tu = 12.0f;

// ---------- Distancias definidas (cm) ----------
const uint16_t TM_DIST_1_TO_2 = 101;
const uint16_t TM_DIST_2_TO_1 = 101;

// Distancia desde TUx hasta TU6 (meta)
uint16_t TU_DIST_TO_6[9] = {0};
const uint16_t TU_RETURN_6_TO_1 = 101;

// ---------- Estado de detección por sensor ----------
bool     wasBelow[9]       = {0};
bool     stableReported[9] = {0};
uint32_t belowStartMs[9]   = {0};

// ---------- Estado por línea ----------
uint32_t tm_depart_ms = 0;   // Transmetro (solo para controlar etapas)
uint16_t tm_planned_cm = 0;
bool     tm_leg_active = false;

uint32_t tu_depart_ms = 0;   // Transurbano (si lo quisieras usar luego)
uint16_t tu_planned_cm = 0;
bool     tu_leg_active = false;

// Para la nueva lógica: recordar en qué TU intermedio quedó posado
int8_t tu_pos_active = -1; // -1 ninguno; 3..7 para TU2..TU7 (excepto TU6 que es parada)

// =====================================================
// Utilidades
// =====================================================
float readUltrasonicCm(uint8_t id) {
  const UPin p = US_PINS[id];
  pinMode(p.trig, OUTPUT);
  digitalWrite(p.trig, LOW); delayMicroseconds(2);
  digitalWrite(p.trig, HIGH); delayMicroseconds(10);
  digitalWrite(p.trig, LOW);

  pinMode(p.echo, INPUT);
  unsigned long dur = pulseIn(p.echo, HIGH, ECHO_TIMEOUT_US);
  if (dur == 0) return 400.0f;
  return dur / 58.0f; // us->cm
}

inline float thrFor(uint8_t id){
  if (id==TM1 || id==TM2 || id==TU1 || id==TU6) return THR_STOP_CM;
  return THR_ROUTE_CM;
}

// ----- ETA en SEGUNDOS -----
void publishETA_TM(uint16_t Dcm, bool to2){
  float t_s = Dcm / max(1.0f, v_tm);
  Serial.print("TM,ETA_S,TO="); Serial.print(to2 ? 2 : 1);
  Serial.print(","); Serial.println(t_s, 2);
}

void publishETA_TU_from(uint8_t from, uint16_t Dcm, uint8_t to){
  float t_s = Dcm / max(1.0f, v_tu);
  Serial.print("TU,ETA_S,FROM="); Serial.print(from);
  Serial.print(",TO="); Serial.print(to);
  Serial.print(","); Serial.println(t_s, 2);
}

// =====================================================
// Eventos TRANS METRO
// =====================================================
void TM_onArrive(uint8_t stopId){
  // cerramos etapa si estaba activa (no calculamos SPD, velocidad constante)
  if (tm_leg_active){ (void)(millis() - tm_depart_ms); tm_leg_active = false; }
  Serial.print("TM,ARRIVE,"); Serial.println(stopId==TM1?1:2);
}

void TM_onLeave(uint8_t stopId){
  Serial.print("TM,LEAVE,"); Serial.println(stopId==TM1?1:2);
  tm_depart_ms = millis();
  if (stopId==TM1){ tm_planned_cm = TM_DIST_1_TO_2; publishETA_TM(tm_planned_cm, true); }
  else            { tm_planned_cm = TM_DIST_2_TO_1; publishETA_TM(tm_planned_cm, false); }
  tm_leg_active = true;
}

// =====================================================
// Eventos TRANS URBANO
// =====================================================
void TU_onArrive(uint8_t sensorId){
  // En TU, sólo informamos llegada a paradas TU1/TU6
  Serial.print("TU,ARRIVE,");
  if      (sensorId==TU1) Serial.println(1);
  else if (sensorId==TU6) Serial.println(6);
  else                    Serial.println((int)sensorId); // debug si quisieras
}

void TU_onLeave(uint8_t sensorId){
  if (sensorId==TU1){
    // Primer ETA directo TU1 -> TU6 (101 cm)
    tu_depart_ms = millis();
    tu_planned_cm = TU_DIST_TO_6[TU1];
    tu_leg_active = true;
    Serial.println("TU,LEAVE,1");
    publishETA_TU_from(1, tu_planned_cm, 6);
  } else if (sensorId==TU6){
    // Retorno TU6 -> TU1 (101 cm)
    tu_depart_ms = millis();
    tu_planned_cm = TU_RETURN_6_TO_1;
    tu_leg_active = true;
    Serial.println("TU,LEAVE,6");
    publishETA_TU_from(6, tu_planned_cm, 1);
  }
}

// Llega y se mantiene en TU2..TU5 o TU7: SOLO reporta POS;
// el ETA se publicará AL SALIR de ese sensor.
void TU_onHoldAt(uint8_t sensorId){
  if (sensorId==TU2 || sensorId==TU3 || sensorId==TU4 || sensorId==TU5 || sensorId==TU7){
    tu_pos_active = sensorId;
    Serial.print("TU,POS,");
    Serial.println(sensorId==TU2?2:
                   sensorId==TU3?3:
                   sensorId==TU4?4:
                   sensorId==TU5?5:7);
  } else if (sensorId==TU6){
    TU_onArrive(TU6);
  } else if (sensorId==TU1){
    TU_onArrive(TU1);
  }
}

// =====================================================
// Setup / Loop
// =====================================================
void setup() {
  Serial.begin(115200);
  for (int i=0;i<9;i++){
    pinMode(US_PINS[i].trig, OUTPUT); digitalWrite(US_PINS[i].trig, LOW);
    pinMode(US_PINS[i].echo, INPUT);
  }

  // Tabla de distancias TUx -> TU6 (cm)
  for (int i=0;i<9;i++) TU_DIST_TO_6[i]=0;
  TU_DIST_TO_6[TU1] = 101;
  TU_DIST_TO_6[TU2] = 141;
  TU_DIST_TO_6[TU3] = 113;
  TU_DIST_TO_6[TU4] = 159;
  TU_DIST_TO_6[TU5] = 131;
  TU_DIST_TO_6[TU7] = 180;
  // TU6 es destino (0)

  // Mensajes iniciales en s (opcionales)
  float eta_tm0_s = TM_DIST_1_TO_2 / max(1.0f, v_tm);
  Serial.print("ETA_TM_INIT_S,"); Serial.println(eta_tm0_s, 2);
  float eta_tu0_s = TU_DIST_TO_6[TU1] / max(1.0f, v_tu);
  Serial.print("ETA_TU_INIT_S,"); Serial.println(eta_tu0_s, 2);
}

void loop() {
  for (uint8_t id=0; id<9; id++){
    float cm = readUltrasonicCm(id);
    float thr = thrFor(id);
    bool below = (cm < thr);
    uint32_t now = millis();

    // Flanco de bajada (entra por debajo)
    if (!wasBelow[id] && below){
      wasBelow[id] = true;
      stableReported[id] = false;
      belowStartMs[id] = now;
    }

    // Permanencia ≥ STABLE_MS -> evento estable
    if (wasBelow[id] && !stableReported[id] && (now - belowStartMs[id] >= STABLE_MS)){
      stableReported[id] = true;
      if (id==TM1 || id==TM2)        TM_onArrive(id);
      else                           TU_onHoldAt(id); // SOLO POS en TU2/3/4/5/7
    }

    // Flanco de subida (sale del umbral)
    if (wasBelow[id] && !below){
      wasBelow[id] = false;
      stableReported[id] = false;

      // TM y TU paradas: inician tramo al salir
      if (id==TM1 || id==TM2)        TM_onLeave(id);
      else if (id==TU1 || id==TU6)   TU_onLeave(id);

      // --- NUEVO: si sale de un TU intermedio y era el activo, ahora publica ETA ---
      if ((id==TU2 || id==TU3 || id==TU4 || id==TU5 || id==TU7) && tu_pos_active==id){
        uint16_t D = TU_DIST_TO_6[id];
        if (D>0){
          uint8_t fromNum = (id==TU2)?2 : (id==TU3)?3 : (id==TU4)?4 : (id==TU5)?5 : 7;
          publishETA_TU_from(fromNum, D, 6);
        }
        tu_pos_active = -1;
      }
    }
  }

  delay(60);
}
