/*
  Ciudad – 14 sensores (Transmetro + Transurbano + TVx)
  Serial 115200: TM/... y TU/... eventos y ETA (s con 2 decimales). Distancias en cm.
*/

#include <Arduino.h>

// ================== CONFIG BÁSICA ==================
const uint8_t UNUSED_PIN = 255;  // marcador de pin no usado (anulado)

// ---------- Mapeo de sensores ----------
enum {
  TM1 = 0, TM2 = 1,          // Transmetro (paradas)
  TU1 = 2, TU2 = 3, TU3 = 4, // Transurbano
  TU4 = 5, TU5 = 6, TU6 = 7, TU7 = 8,
  TV2 = 9, TV3 = 10, TV4 = 11, TV5 = 12, TV7 = 13
};

const uint8_t N_SENSORS = 14;

// Pines TRIG/ECHO (TV3 movido a 34/35; TU5 anulado)
struct UPin { uint8_t trig, echo; };
const UPin US_PINS[N_SENSORS] = {
  {22,23},   // TM1
  {24,25},   // TM2
  {26,27},   // TU1
  {28,29},   // TU2
  {30,31},   // TU3
  {32,33},   // TU4
  {UNUSED_PIN, UNUSED_PIN}, // TU5 (ANULADO)
  {36,37},   // TU6
  {38,39},   // TU7
  {46,47},   // TV2
  {34,35},   // TV3  <-- ahora en 34/35
  {50,51},   // TV4
  {52,53},   // TV5
  {6,7}      // TV7
};

// ---------- Parámetros ----------
const float  THR_STOP_CM   = 10.0f;
const float  THR_ROUTE_CM  = 10.0f;
const uint32_t STABLE_MS   = 3000UL;
const unsigned long ECHO_TIMEOUT_US = 20000UL;

// Velocidades promedio (cm/s)
float v_tm = 12.0f;
float v_tu = 12.0f;

// ---------- Distancias definidas (cm) ----------
const uint16_t TM_DIST_1_TO_2 = 101;
const uint16_t TM_DIST_2_TO_1 = 101;
uint16_t TU_DIST_TO_6[N_SENSORS] = {0};
const uint16_t TU_RETURN_6_TO_1 = 101;

// ---------- Estado de detección ----------
bool     wasBelow[N_SENSORS]       = {0};
bool     stableReported[N_SENSORS] = {0};
uint32_t belowStartMs[N_SENSORS]   = {0};
float    lastCm[N_SENSORS]         = {0};

// ---------- Estado por línea ----------
uint32_t tm_depart_ms = 0;
uint16_t tm_planned_cm = 0;
bool     tm_leg_active = false;

uint32_t tu_depart_ms = 0;
uint16_t tu_planned_cm = 0;
bool     tu_leg_active = false;
int8_t   tu_pos_active = -1;

// =====================================================
// CORREDOR (3 / 32.5 / 61 cm) — define ANTES de funciones
// =====================================================
const uint8_t  NUM_ZONES = 3;
const float    ZONE_CENTER[NUM_ZONES] = {3.0f, 32.5f, 61.0f}; // centro 32.5 → cubre 30..35 con half=2.5
const float    ZONE_HALF_WIDTH = 2.5f; // ±2.5 cm (30..35 cm en la zona central)
const uint32_t ZONE_STABLE_MS  = 150UL;

struct CorridorState {
  int8_t   zoneActive;              // -1 = fuera
  uint32_t zoneEnterMs;
  bool     zoneReported[NUM_ZONES]; // evita repetir hasta salir
};

// Estados de corredores (A en rojo)
CorridorState cor_TM1 = {-1, 0, {0,0,0}};
CorridorState cor_TV3 = {-1, 0, {0,0,0}};
CorridorState cor_TU1 = {-1, 0, {0,0,0}};
CorridorState cor_TU2 = {-1, 0, {0,0,0}};  // TU2 igual que TV3/TU1

// =====================================================
// Utilidades
// =====================================================
float readUltrasonicCm(uint8_t id) {
  const UPin p = US_PINS[id];
  if (p.trig == UNUSED_PIN || p.echo == UNUSED_PIN) return 400.0f;  // anulado

  pinMode(p.trig, OUTPUT);
  digitalWrite(p.trig, LOW); delayMicroseconds(2);
  digitalWrite(p.trig, HIGH); delayMicroseconds(10);
  digitalWrite(p.trig, LOW);

  pinMode(p.echo, INPUT);
  unsigned long dur = pulseIn(p.echo, HIGH, ECHO_TIMEOUT_US);
  if (dur == 0) return 400.0f;
  return dur / 58.0f;
}

inline float thrFor(uint8_t id){
  if (id==TM1 || id==TM2 || id==TU1 || id==TU6) return THR_STOP_CM;
  return THR_ROUTE_CM;
}

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
  Serial.print("TU,ARRIVE,");
  if      (sensorId==TU6) Serial.println(6);       // mantenemos TU6
  else                    Serial.println((int)sensorId);
}
void TU_onLeave(uint8_t sensorId){
  if (sensorId==TU6){
    tu_depart_ms = millis();
    tu_planned_cm = TU_RETURN_6_TO_1;
    tu_leg_active = true;
    Serial.println("TU,LEAVE,6");
    publishETA_TU_from(6, tu_planned_cm, 1);
  }
}

// POS solo para intermedios que NO son de corredor (NO TV3, NO TU1, NO TU2)
void TU_onHoldAt(uint8_t sensorId){
  if (sensorId==TU3 || sensorId==TU4 || sensorId==TU5 || sensorId==TU7 ||
      sensorId==TV2 || sensorId==TV4 || sensorId==TV5 || sensorId==TV7) {
    tu_pos_active = sensorId;
    Serial.print("TU,POS,");
    Serial.println(sensorId==TV2 ? 2 :
                   sensorId==TU3 ? 3 :
                   sensorId==TU4||sensorId==TV4 ? 4 :
                   sensorId==TU5||sensorId==TV5 ? 5 : 7);
  }
  else if (sensorId==TU6) {
    TU_onArrive(TU6);
  }
}

// =====================================================
// SEMÁFOROS
// =====================================================
const uint8_t A_R = 40, A_Y = 41, A_G = 42;
const uint8_t B_R = 43, B_Y = 44, B_G = 45;

const uint32_t T_GREEN  = 10000UL;
const uint32_t T_YELLOW = 2000UL;

enum Phase : uint8_t { P_A_GREEN, P_A_YELLOW, P_B_GREEN, P_B_YELLOW };
Phase phase = P_A_GREEN;
uint32_t phaseSince = 0;

void applyLights(){
  digitalWrite(A_R, LOW); digitalWrite(A_Y, LOW); digitalWrite(A_G, LOW);
  digitalWrite(B_R, LOW); digitalWrite(B_Y, LOW); digitalWrite(B_G, LOW);
  switch(phase){
    case P_A_GREEN:  digitalWrite(A_G, HIGH); digitalWrite(B_R, HIGH); break;
    case P_A_YELLOW: digitalWrite(A_Y, HIGH); digitalWrite(B_R, HIGH); break;
    case P_B_GREEN:  digitalWrite(B_G, HIGH); digitalWrite(A_R, HIGH); break;
    case P_B_YELLOW: digitalWrite(B_Y, HIGH); digitalWrite(A_R, HIGH); break;
  }
}
void nextPhase(){
  switch(phase){
    case P_A_GREEN:  phase = P_A_YELLOW; break;
    case P_A_YELLOW: phase = P_B_GREEN;  break;
    case P_B_GREEN:  phase = P_B_YELLOW; break;
    case P_B_YELLOW: phase = P_A_GREEN;  break;
  }
  phaseSince = millis(); applyLights();
}
void updateTrafficLights(){
  uint32_t now = millis();
  switch(phase){
    case P_A_GREEN:
    case P_B_GREEN:  if (now - phaseSince >= T_GREEN)  nextPhase(); break;
    case P_A_YELLOW:
    case P_B_YELLOW: if (now - phaseSince >= T_YELLOW) nextPhase(); break;
  }
}

// =====================================================
// INFRACCIÓN EN ROJO (genérico)
// =====================================================
#define SEM_A   0
#define SEM_B   1
#define SEM_NONE 2

// TM1, TU1, TU2 y TV3 en NONE → los maneja el corredor.
// TV2 lo dejo en B (según tu mapeo).
uint8_t semGroup[N_SENSORS] = {
  SEM_NONE, // TM1
  SEM_B,    // TM2
  SEM_NONE, // TU1  (corredor)
  SEM_NONE, // TU2  (corredor)
  SEM_NONE, // TU3  (si quieres volver a genérico, cámbialo)
  SEM_NONE, // TU4  (ídem)
  SEM_B,    // TU5  (anulado, no afectará)
  SEM_B,    // TU6
  SEM_B,    // TU7
  SEM_B,    // TV2
  SEM_NONE, // TV3  (corredor)
  SEM_B,    // TV4
  SEM_B,    // TV5
  SEM_B     // TV7
};

const char* nameOf(uint8_t id){
  switch(id){
    case TM1: return "TM1"; case TM2: return "TM2";
    case TU1: return "TU1"; case TU2: return "TU2"; case TU3: return "TU3";
    case TU4: return "TU4"; case TU5: return "TU5"; case TU6: return "TU6"; case TU7: return "TU7";
    case TV2: return "TV2"; case TV3: return "TV3"; case TV4: return "TV4"; case TV5: return "TV5"; case TV7: return "TV7";
    default:  return "?";
  }
}
bool isGroupRed_(uint8_t g){
  if (g == SEM_A) return (phase==P_B_GREEN || phase==P_B_YELLOW);
  if (g == SEM_B) return (phase==P_A_GREEN || phase==P_A_YELLOW);
  return false;
}
bool prevBelowSnap_violation[N_SENSORS] = {0};
void checkRedLightViolation(){
  for (uint8_t id=0; id<N_SENSORS; id++){
    if (semGroup[id] == SEM_NONE) continue; // TM1, TU1, TU2, TV3 excluidos
    bool nowBelow  = wasBelow[id];
    bool prevBelow = prevBelowSnap_violation[id];
    if (!prevBelow && nowBelow){
      if (isGroupRed_(semGroup[id])){
        Serial.print("Alerta infraccion de transito, SENSOR=");
        Serial.println(nameOf(id));
      }
    }
    prevBelowSnap_violation[id] = nowBelow;
  }
}

// =====================================================
// Lógica del CORREDOR (A en rojo): TM1, TV3, TU1, TU2
// =====================================================
static int8_t zoneForDistance(float cm){
  for (uint8_t i=0;i<NUM_ZONES;i++){
    if (cm >= (ZONE_CENTER[i]-ZONE_HALF_WIDTH) && cm <= (ZONE_CENTER[i]+ZONE_HALF_WIDTH))
      return (int8_t)i;
  }
  return -1;
}
static void resetZoneReportsIfOutsideAll(CorridorState &st, float cm){
  if (zoneForDistance(cm) == -1){
    for (uint8_t i=0;i<NUM_ZONES;i++) st.zoneReported[i]=false;
  }
}
static void handleCorridorA(uint8_t sensorId, CorridorState &st, const char* label){
  float d = lastCm[sensorId];
  int8_t z = zoneForDistance(d);
  resetZoneReportsIfOutsideAll(st, d);

  // entrar a zona
  if (st.zoneActive == -1 && z != -1) {
    st.zoneActive = z;
    st.zoneEnterMs = millis();
  }
  // confirmar y reportar
  if (st.zoneActive != -1 && !st.zoneReported[st.zoneActive]) {
    if (millis() - st.zoneEnterMs >= ZONE_STABLE_MS) {
      if (isGroupRed_(SEM_A)) {
        int human = (st.zoneActive==0?3 : (st.zoneActive==1?32 : 61));
        Serial.print("Alerta infraccion de transito, ");
        Serial.print(label);
        Serial.print(", ZONA="); Serial.println(human);
        st.zoneReported[st.zoneActive] = true;
      }
    }
  }
  // salir / saltar
  if (st.zoneActive != -1 && z != st.zoneActive) {
    st.zoneActive = (z==-1 ? -1 : z);
    if (st.zoneActive != -1) st.zoneEnterMs = millis();
  }
}
static void checkCorridorsA(){
  handleCorridorA(TM1, cor_TM1, "CORREDOR A (TM1)");
  handleCorridorA(TV3, cor_TV3, "CORREDOR A (TV3)");
  handleCorridorA(TU1, cor_TU1, "CORREDOR A (TU1)");
  handleCorridorA(TU2, cor_TU2, "CORREDOR A (TU2)");
}

// =====================================================
// Setup / Loop
// =====================================================
void setup() {
  Serial.begin(115200);
  for (int i=0;i<N_SENSORS;i++){
    if (US_PINS[i].trig == UNUSED_PIN || US_PINS[i].echo == UNUSED_PIN) continue; // saltar TU5
    pinMode(US_PINS[i].trig, OUTPUT); digitalWrite(US_PINS[i].trig, LOW);
    pinMode(US_PINS[i].echo, INPUT);
  }
  // Distancias para ETA (solo para intermedios que participan)
  TU_DIST_TO_6[TU3] = 113;
  TU_DIST_TO_6[TU4] = 159;
  TU_DIST_TO_6[TU5] = 131;  // no se usa, pero no molesta
  TU_DIST_TO_6[TU7] = 180;
  TU_DIST_TO_6[TV2] = 141;
  TU_DIST_TO_6[TV4] = 159;
  TU_DIST_TO_6[TV5] = 131;
  TU_DIST_TO_6[TV7] = 180;

  pinMode(A_R, OUTPUT); pinMode(A_Y, OUTPUT); pinMode(A_G, OUTPUT);
  pinMode(B_R, OUTPUT); pinMode(B_Y, OUTPUT); pinMode(B_G, OUTPUT);
  phaseSince = millis();
  applyLights();
}

void loop() {
  // Lecturas y eventos
  for (uint8_t id=0; id<N_SENSORS; id++){
    float cm = readUltrasonicCm(id);
    lastCm[id] = cm;

    float thr = thrFor(id);
    bool below = (cm < thr);
    uint32_t now = millis();

    // flanco de bajada
    if (!wasBelow[id] && below){
      wasBelow[id] = true;
      stableReported[id] = false;
      belowStartMs[id] = now;
    }

    // estado estable
    if (wasBelow[id] && !stableReported[id] && (now - belowStartMs[id] >= STABLE_MS)){
      stableReported[id] = true;
      if (id==TM1 || id==TM2) TM_onArrive(id);
      else                    TU_onHoldAt(id); // intermedios (excluye TU1, TU2 y TV3)
    }

    // flanco de subida
    if (wasBelow[id] && !below){
      wasBelow[id] = false;
      stableReported[id] = false;

      if (id==TM1 || id==TM2) TM_onLeave(id);
      else if (id==TU6)       TU_onLeave(id);

      // ETA solo para intermedios que sí participan (NO TU1, NO TU2, NO TV3)
      if ((id==TU3 || id==TU4 || id==TU5 || id==TU7 ||
           id==TV2 || id==TV4 || id==TV5 || id==TV7) && tu_pos_active==id){
        uint16_t D = TU_DIST_TO_6[id];
        if (D>0){
          uint8_t fromNum =
            (id==TV2)?2 :
            (id==TU3)?3 :
            (id==TU4||id==TV4)?4 :
            (id==TU5||id==TV5)?5 : 7;
          publishETA_TU_from(fromNum, D, 6);
        }
        tu_pos_active = -1;
      }
    }
  }

  // Semáforos e infracciones
  updateTrafficLights();
  checkRedLightViolation(); // genérico (TM1/TU1/TU2/TV3 excluidos)
  checkCorridorsA();        // corredor: TM1, TV3, TU1 y TU2

  delay(60);
}