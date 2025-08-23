/*
  Ciudad – 14 sensores (Transmetro + Transurbano + TVx)
  Serial 115200: TM/... y TU/... eventos y ETA (s con 2 decimales). Distancias en cm.
*/

#include <Arduino.h>

// ---------- Mapeo de sensores ----------
enum {
  TM1 = 0, TM2 = 1,          // Transmetro (paradas)
  TU1 = 2, TU2 = 3, TU3 = 4, // Transurbano
  TU4 = 5, TU5 = 6, TU6 = 7, TU7 = 8,
  TV2 = 9, TV3 = 10, TV4 = 11, TV5 = 12, TV7 = 13
};

const uint8_t N_SENSORS = 14;
const uint8_t UNUSED_PIN = 255; // marca de pin anulado

// Pines TRIG/ECHO
struct UPin { uint8_t trig, echo; };
const UPin US_PINS[N_SENSORS] = {
  {22,23},   // TM1
  {24,25},   // TM2
  {26,27},   // TU1
  {28,29},   // TU2
  {30,31},   // TU3
  {32,33},   // TU4
  {UNUSED_PIN, UNUSED_PIN}, // TU5 (ANULADO)
  {UNUSED_PIN, UNUSED_PIN}, // TU6 (ANULADO)
  {UNUSED_PIN, UNUSED_PIN}, // TU7 (ANULADO)
  {46,47},   // TV2
  {34,35},   // TV3
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
// CORREDOR (3 / 32.5 / 61 cm)
// =====================================================
const uint8_t  NUM_ZONES = 3;
const float    ZONE_CENTER[NUM_ZONES] = {3.0f, 32.5f, 61.0f}; // 30..35 con half=2.5
const float    ZONE_HALF_WIDTH = 2.5f;
const uint32_t ZONE_STABLE_MS  = 150UL;

struct CorridorState {
  int8_t   zoneActive;              // -1 = fuera
  uint32_t zoneEnterMs;
  bool     zoneReported[NUM_ZONES]; // evita repetir hasta salir
};

CorridorState cor_TM1 = {-1, 0, {0,0,0}};
CorridorState cor_TV3 = {-1, 0, {0,0,0}};
CorridorState cor_TU1 = {-1, 0, {0,0,0}};
CorridorState cor_TU2 = {-1, 0, {0,0,0}};  // TU2 igual que TV3/TU1

// =====================================================
// BUZZERS (no bloqueantes) — en 36 y 37
// =====================================================
const uint8_t BUZ_TU1_PIN = 36;   // buzzer cercano a TU1
const uint8_t BUZ_TU2_PIN = 37;   // buzzer cercano a TU2
const uint16_t BUZZ_MS    = 500;  // duración del beep

uint32_t buz1Until = 0;
uint32_t buz2Until = 0;

inline void buzzTU1() { digitalWrite(BUZ_TU1_PIN, HIGH); buz1Until = millis() + BUZZ_MS; }
inline void buzzTU2() { digitalWrite(BUZ_TU2_PIN, HIGH); buz2Until = millis() + BUZZ_MS; }

void updateBuzzers(){
  uint32_t now = millis();
  if (buz1Until && now >= buz1Until){ digitalWrite(BUZ_TU1_PIN, LOW); buz1Until = 0; }
  if (buz2Until && now >= buz2Until){ digitalWrite(BUZ_TU2_PIN, LOW); buz2Until = 0; }
}

void buzzForZoneHuman(int zoneHuman){
  // 3 o 32 cm -> TU1 ; 61 cm -> TU2
  if (zoneHuman == 61) buzzTU2();
  else                 buzzTU1();
}

// =====================================================
// Botones manuales (4 patas) para activar buzzers
// =====================================================
const uint8_t BTN_BUZ1_PIN = 38;   // Botón que activa buzzer en pin 36 (TU1)
const uint8_t BTN_BUZ2_PIN = 39;   // Botón que activa buzzer en pin 37 (TU2)
const uint16_t BTN_DEBOUNCE_MS = 150;

bool btn1Last = HIGH, btn2Last = HIGH;  // con INPUT_PULLUP: reposo HIGH
uint32_t btn1ChangeMs = 0, btn2ChangeMs = 0;

inline void readButtonsAndTrigger(){
  uint32_t now = millis();

  // --- Botón 1 ---
  bool b1 = digitalRead(BTN_BUZ1_PIN);
  if (b1 != btn1Last){
    btn1Last = b1;
    btn1ChangeMs = now;
  } else {
    if (b1 == LOW && (now - btn1ChangeMs) >= BTN_DEBOUNCE_MS){
      buzzTU1();
      btn1ChangeMs = now + 1000; // evita múltiples beeps mientras está LOW
    }
  }

  // --- Botón 2 ---
  bool b2 = digitalRead(BTN_BUZ2_PIN);
  if (b2 != btn2Last){
    btn2Last = b2;
    btn2ChangeMs = now;
  } else {
    if (b2 == LOW && (now - btn2ChangeMs) >= BTN_DEBOUNCE_MS){
      buzzTU2();
      btn2ChangeMs = now + 1000;
    }
  }
}

// =====================================================
// * NUEVO *  Buzzers 3 y 4 SOLO por botón
// =====================================================
const uint8_t BUZ3_PIN     = 2;   // NUEVO buzzer 3
const uint8_t BUZ4_PIN     = 3;   // NUEVO buzzer 4
const uint8_t BTN_BUZ3_PIN = 4;   // NUEVO botón para buzzer 3
const uint8_t BTN_BUZ4_PIN = 5;   // NUEVO botón para buzzer 4
// Activos SOLO mientras se presiona el botón.

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
  if (id==TM1 || id==TM2 || id==TU1) return THR_STOP_CM;
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
  Serial.println((int)sensorId);
}
void TU_onLeave(uint8_t /sensorId/){ /* sin uso */ }

// POS solo para intermedios que NO son de corredor (NO TV3, NO TU1, NO TU2)
// (TU3/TU4 los tratamos aparte según lo pedido)
void TU_onHoldAt(uint8_t sensorId){
  if (sensorId==TV2 || sensorId==TV4 || sensorId==TV5 || sensorId==TV7) {
    tu_pos_active = sensorId;
    Serial.print("TU,POS,");
    Serial.println(sensorId==TV2 ? 2 :
                   (sensorId==TV4 ? 4 :
                   (sensorId==TV5 ? 5 : 7)));
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

// TM1, TU1, TU2 y TV3 en NONE → TV3 lo maneja el corredor; TM1/TU1/TU2 corredor.
// * IMPORTANTE: TU3 y TU4 en NONE para que NO generen infracciones *
uint8_t semGroup[N_SENSORS] = {
  SEM_NONE, // TM1
  SEM_B,    // TM2
  SEM_NONE, // TU1  (corredor)
  SEM_NONE, // TU2  (corredor)
  SEM_NONE, // TU3  (SIN infracciones)
  SEM_NONE, // TU4  (SIN infracciones)
  SEM_NONE, // TU5 (anulado)
  SEM_NONE, // TU6 (anulado)
  SEM_NONE, // TU7 (anulado)
  SEM_B,    // TV2
  SEM_NONE, // TV3  (corredor especial 32/61)
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
    if (semGroup[id] == SEM_NONE) continue;
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
// Lógica del CORREDOR A
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

// Genérica (TM1, TU1, TU2)
static void handleCorridorA(uint8_t sensorId, CorridorState &st, const char* label){
  float d = lastCm[sensorId];
  int8_t z = zoneForDistance(d);
  resetZoneReportsIfOutsideAll(st, d);

  if (st.zoneActive == -1 && z != -1) {
    st.zoneActive = z;
    st.zoneEnterMs = millis();
  }
  if (st.zoneActive != -1 && !st.zoneReported[st.zoneActive]) {
    if (millis() - st.zoneEnterMs >= ZONE_STABLE_MS) {
      if (isGroupRed_(SEM_A)) {
        int human = (st.zoneActive==0?3 : (st.zoneActive==1?32 : 61));
        Serial.print("Alerta infraccion de transito, ");
        Serial.print(label);
        Serial.print(", ZONA="); Serial.println(human);
        buzzForZoneHuman(human);
        st.zoneReported[st.zoneActive] = true;
      }
    }
  }
  if (st.zoneActive != -1 && z != st.zoneActive) {
    st.zoneActive = (z==-1 ? -1 : z);
    if (st.zoneActive != -1) st.zoneEnterMs = millis();
  }
}

// * ESPECIAL TV3: solo 32 y 61 cm (ignorar 3 cm) *
static void handleCorridorTV3(uint8_t sensorId, CorridorState &st, const char* label){
  float d = lastCm[sensorId];
  int8_t z = zoneForDistance(d);
  if (z == 0) { // zona 3 cm -> ignorar
    resetZoneReportsIfOutsideAll(st, d);
    return;
  }
  resetZoneReportsIfOutsideAll(st, d);

  if (st.zoneActive == -1 && z != -1) {
    st.zoneActive = z;
    st.zoneEnterMs = millis();
  }
  if (st.zoneActive != -1 && !st.zoneReported[st.zoneActive]) {
    if (millis() - st.zoneEnterMs >= ZONE_STABLE_MS) {
      if (isGroupRed_(SEM_A)) {
        int human = (st.zoneActive==1?32:61);
        Serial.print("Alerta infraccion de transito, ");
        Serial.print(label);
        Serial.print(", ZONA="); Serial.println(human);
        buzzForZoneHuman(human);
        st.zoneReported[st.zoneActive] = true;
      }
    }
  }
  if (st.zoneActive != -1 && z != st.zoneActive) {
    st.zoneActive = (z==-1 ? -1 : z);
    if (st.zoneActive != -1) st.zoneEnterMs = millis();
  }
}

static void checkCorridorsA(){
  handleCorridorA (TM1, cor_TM1, "CORREDOR A (TM1)");
  handleCorridorTV3(TV3, cor_TV3, "CORREDOR A (TV3)"); // <- SOLO 32 y 61 cm
  handleCorridorA (TU1, cor_TU1, "CORREDOR A (TU1)");
  handleCorridorA (TU2, cor_TU2, "CORREDOR A (TU2)");
}

// =====================================================
// SENSOR DE SISMO
// =====================================================
#define PIN_EQ A6

// Umbrales y ventana (ajustables)
const uint16_t EQ_THR_ABS  = 40;        // diferencia vs. línea base para disparar
const uint16_t EQ_THR_DIFF = 18;        // cambio instantáneo entre lecturas
const uint32_t EQ_HOLD_MS  = 5000UL;    // 5 s fijos de buzzers encendidos

// Estado interno
int eq_base = 0;              // línea base (promedio al inicio)
int eq_prev = 0;              // última lectura
uint32_t eq_hold_until = 0;   // cuándo termina la ventana activa
bool eq_forced = false;       // si estamos forzando buzzers ON por sismo

// --- Inicialización (llamar en setup) ---
void EQ_init(){
  pinMode(PIN_EQ, INPUT);
  long sum = 0;
  for (int i=0; i<50; i++){ sum += analogRead(PIN_EQ); delay(4); }
  eq_base = (int)(sum/50);
  eq_prev = eq_base;
  Serial.print("EQ,BASE,"); Serial.println(eq_base);
}

// --- Utilidad: ¿sismo activo (en ventana)? ---
inline bool EQ_isActive(){ return millis() < eq_hold_until; }

// --- Si terminó la ventana, libera salidas (llamar al INICIO del loop) ---
void EQ_releaseOutputsIfEnded(){
  if (eq_forced && !EQ_isActive()){
    // Apagar los 4 buzzers que forzamos durante el sismo:
    digitalWrite(BUZ_TU1_PIN, LOW);
    digitalWrite(BUZ_TU2_PIN, LOW);
    digitalWrite(BUZ3_PIN,    LOW);
    digitalWrite(BUZ4_PIN,    LOW);
    eq_forced = false;
  }
}

// --- Muestreo del piezo y disparo de ventana fija de 5 s (llamar en loop) ---
void EQ_poll(){
  int v  = analogRead(PIN_EQ);
  int dv = abs(v - eq_prev);
  eq_prev = v;

  bool trigger = (abs(v - eq_base) >= (int)EQ_THR_ABS) || (dv >= (int)EQ_THR_DIFF);
  // Ventana fija: solo se abre si NO había una activa
  if (trigger && !EQ_isActive()){
    eq_hold_until = millis() + EQ_HOLD_MS;   // 5 s fijos
    Serial.print("EQ,TRIGGER,RAW="); Serial.println(v);
  }
}

// --- Aplicar salidas (al FINAL del loop, tras tu lógica normal) ---
void EQ_applyOutputs(){
  if (EQ_isActive()){
    // Forzar ON todos los buzzers (36, 37, 2, 3)
    digitalWrite(BUZ_TU1_PIN, HIGH);
    digitalWrite(BUZ_TU2_PIN, HIGH);
    digitalWrite(BUZ3_PIN,    HIGH);
    digitalWrite(BUZ4_PIN,    HIGH);
    eq_forced = true;
  }
}

// --- Mensaje de fin (opcional, al FINAL del loop) ---
void EQ_announceEndIfAny(){
  static bool wasActive = false;
  bool act = EQ_isActive();
  if (wasActive && !act) Serial.println("EQ,END");
  wasActive = act;
}


// =====================================================
// Setup / Loop
// =====================================================
void setup() {
  Serial.begin(115200);
  for (int i=0;i<N_SENSORS;i++){
    if (US_PINS[i].trig == UNUSED_PIN || US_PINS[i].echo == UNUSED_PIN) continue; // saltar anulados
    pinMode(US_PINS[i].trig, OUTPUT); digitalWrite(US_PINS[i].trig, LOW);
    pinMode(US_PINS[i].echo, INPUT);
  }

  // Distancias para ETA (solo intermedios vigentes)
  TU_DIST_TO_6[TU3] = 113;
  TU_DIST_TO_6[TU4] = 159;
  TU_DIST_TO_6[TV2] = 141;
  TU_DIST_TO_6[TV4] = 159;
  TU_DIST_TO_6[TV5] = 131;
  TU_DIST_TO_6[TV7] = 180;

  // Semáforos
  pinMode(A_R, OUTPUT); pinMode(A_Y, OUTPUT); pinMode(A_G, OUTPUT);
  pinMode(B_R, OUTPUT); pinMode(B_Y, OUTPUT); pinMode(B_G, OUTPUT);

  // Buzzers (36 y 37)
  pinMode(BUZ_TU1_PIN, OUTPUT); digitalWrite(BUZ_TU1_PIN, LOW);
  pinMode(BUZ_TU2_PIN, OUTPUT); digitalWrite(BUZ_TU2_PIN, LOW);

  // Buzzers 3 y 4
  pinMode(BUZ3_PIN, OUTPUT); digitalWrite(BUZ3_PIN, LOW);
  pinMode(BUZ4_PIN, OUTPUT); digitalWrite(BUZ4_PIN, LOW);

  // Botones (INPUT_PULLUP)
  pinMode(BTN_BUZ1_PIN, INPUT_PULLUP);
  pinMode(BTN_BUZ2_PIN, INPUT_PULLUP);
  pinMode(BTN_BUZ3_PIN, INPUT_PULLUP);
  pinMode(BTN_BUZ4_PIN, INPUT_PULLUP);

  phaseSince = millis();
  applyLights();

  // Sensor de luz
  EQ_init();
}

void loop() {

  // 1) Al INICIO del loop: libera salidas si terminó la ventana del sismo
  EQ_releaseOutputsIfEnded();  

  // --- Botones manuales para buzzers 36/37 con temporizador ---
  readButtonsAndTrigger();

  // --- Buzzer 3 y 4: SOLO mientras el botón está presionado ---
  digitalWrite(BUZ3_PIN, digitalRead(BTN_BUZ3_PIN) == LOW ? HIGH : LOW);
  digitalWrite(BUZ4_PIN, digitalRead(BTN_BUZ4_PIN) == LOW ? HIGH : LOW);

  // 2) Justo después de la gestión de botones: muestrea el piezo y decide ventana
  EQ_poll();                    

  // --- Lecturas y eventos de sensores ---
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

    // estado estable (≥ 3 s)
    if (wasBelow[id] && !stableReported[id] && (now - belowStartMs[id] >= STABLE_MS)){
      stableReported[id] = true;

      if (id==TM1 || id==TM2) {
        TM_onArrive(id);
      }
      else if (id==TU3) {  // * pedido: sin infracciones, mensaje tras 3 s *
        Serial.println("Llego Transurbano a parada 2");
      }
      else if (id==TU4) {  // * pedido: sin infracciones, mensaje tras 3 s *
        Serial.println("Llego Transurbano a parada 1");
      }
      else {
        // Intermedios vigentes (pero no TU3/TU4)
        TU_onHoldAt(id);
      }
    }

    // flanco de subida
    if (wasBelow[id] && !below){
      wasBelow[id] = false;
      stableReported[id] = false;

      if (id==TM1 || id==TM2) TM_onLeave(id);

      // ETA solo para intermedios vigentes (NO TU1, NO TU2, NO TV3, NO anulados)
      if ((id==TU3 || id==TU4 ||
           id==TV2 || id==TV4 || id==TV5 || id==TV7) && tu_pos_active==id){
        uint16_t D = TU_DIST_TO_6[id];
        if (D>0){
          uint8_t fromNum =
            (id==TV2)?2 :
            (id==TU3)?3 :
            (id==TU4||id==TV4)?4 : 7;
          publishETA_TU_from(fromNum, D, 6); // el “6” es simbólico (meta)
        }
        tu_pos_active = -1;
      }
    }
  }

  // Semáforos, buzzers e infracciones
  updateTrafficLights();
  checkRedLightViolation(); // genérico (TU3/TU4 desactivados)
  checkCorridorsA();        // corredor: TM1, TV3(32/61), TU1 y TU2
  updateBuzzers();          // apaga buzzers 36/37 al terminar su tiempo

  EQ_applyOutputs();           
  EQ_announceEndIfAny();        

  delay(60);
}