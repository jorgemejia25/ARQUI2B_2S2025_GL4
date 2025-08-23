/*
  Ciudad – sensores (Transmetro + Transurbano + SD cruces)
  Serial 115200:
    Eventos (texto):
      - Paradas: TM,ARRIVE/LEAVE,<1|2>  |  TU,ARRIVE/LEAVE,<1|2>
      - ETA fijo: TM,ETA_S,FROM=x,TO=y,<seg> | TU,ETA_S,FROM=x,TO=y,<seg>
      - Infracciones: INFRACCION ROJO SDn, cm=...
      - Botones: BTN,BUZx,PRESS
    Estado periódico (NDJSON puro):
      - { "ts": "...", "semaforos": {...}, "dist_cm": {...}, "gas_ppm": {...}, "zumbador": {...},
          "sismo": {...}, "panic_buttons": {...}, "infracciones": [...], "_protocol_version":"1.0" }
*/

#include <Arduino.h>

// ===== Depuración =====
#define DEBUG_STOPS 0
const uint16_t DEBUG_STOPS_MS = 250;

// ---------- Incendios ----------
#define PIN_AO  A0
#define PIN_A1  A1
const int HUMO_UMBRAL = 500;

// ---------- Sensores ----------
enum {
  TM1 = 0, TM2 = 1,       // Paradas Transmetro
  TU3 = 2, TU4 = 3,       // Paradas Transurbano
  SD1 = 4, SD2 = 5, SD3 = 6, SD4 = 7, SD5 = 8   // Cruces (infracciones)
};
const uint8_t N_SENSORS = 9;
const uint8_t UNUSED_PIN = 255;

struct UPin { uint8_t trig, echo; };
const UPin US_PINS[N_SENSORS] = {
  {22,23},   // TM1
  {24,25},   // TM2
  {7,6},     // TU3
  {32,33},   // TU4
  {46,47},   // SD1
  {48,49},   // SD2
  {50,51},   // SD3
  {52,53},   // SD4
  {26,27}    // SD5
};

// ---------- Parámetros ----------
const float  THR_STOP_CM   = 6.0f;
const uint32_t STABLE_MS   = 3000UL;
const unsigned long ECHO_TIMEOUT_US = 20000UL;

// ---------- Estado genérico ----------
bool     wasBelow[N_SENSORS]       = {0};
bool     stableReported[N_SENSORS] = {0};
uint32_t belowStartMs[N_SENSORS]   = {0};
float    lastCm[N_SENSORS]         = {0};
bool     stopETAArmed[N_SENSORS]   = {0}; // disponible si decides mover ETA al loop

// =====================================================
// BUZZERS y BOTONES
// =====================================================
const uint8_t BUZ_TU1_PIN = 36;  // BUZ1
const uint8_t BUZ_TU2_PIN = 37;  // BUZ2
const uint8_t BUZ3_PIN    = 2;   // BUZ3
const uint8_t BUZ4_PIN    = 3;   // BUZ4
const uint16_t BUZZ_MS    = 500;

uint32_t buz1Until = 0, buz2Until = 0, buz3Until = 0, buz4Until = 0;

const uint8_t BTN_BUZ1_PIN = 38;
const uint8_t BTN_BUZ2_PIN = 39;
const uint8_t BTN_BUZ3_PIN = 4;
const uint8_t BTN_BUZ4_PIN = 5;
const uint16_t BTN_DEBOUNCE_MS = 150;
bool btn1Last = HIGH, btn2Last = HIGH, btn3Last = HIGH, btn4Last = HIGH;
uint32_t btn1ChangeMs = 0, btn2ChangeMs = 0, btn3ChangeMs = 0, btn4ChangeMs = 0;

// Estado “activo” para reflejarlo en STATUS (~3 s)
bool buttonsActive[4] = {false,false,false,false};
uint32_t buttonsUntil[4] = {0,0,0,0};

inline void buzzPin(uint8_t pin){
  uint32_t now = millis();
  if (pin==BUZ_TU1_PIN) { digitalWrite(BUZ_TU1_PIN, HIGH); buz1Until = now + BUZZ_MS; }
  else if (pin==BUZ_TU2_PIN) { digitalWrite(BUZ_TU2_PIN, HIGH); buz2Until = now + BUZZ_MS; }
  else if (pin==BUZ3_PIN) { buz3Until = now + BUZZ_MS; }
  else if (pin==BUZ4_PIN) { buz4Until = now + BUZZ_MS; }
}
void updateBuzzers(){
  uint32_t now = millis();
  if (buz1Until && now >= buz1Until){ digitalWrite(BUZ_TU1_PIN, LOW); buz1Until = 0; }
  if (buz2Until && now >= buz2Until){ digitalWrite(BUZ_TU2_PIN, LOW); buz2Until = 0; }
  // BUZ3/BUZ4 se mezclan con alarmas de incendio más abajo
}

inline void markButtonActive(uint8_t idx){
  buttonsActive[idx] = true;
  buttonsUntil[idx] = millis() + 3000; // visible 3 s
}

inline void readButtonsAndTrigger(){
  uint32_t now = millis();

  bool b1 = digitalRead(BTN_BUZ1_PIN);
  if (b1 != btn1Last){ btn1Last = b1; btn1ChangeMs = now; }
  else if (b1 == LOW && (now - btn1ChangeMs) >= BTN_DEBOUNCE_MS){
    Serial.println("BTN,BUZ1,PRESS");
    buzzPin(BUZ_TU1_PIN);
    markButtonActive(0);
    btn1ChangeMs = now + 1000;
  }

  bool b2 = digitalRead(BTN_BUZ2_PIN);
  if (b2 != btn2Last){ btn2Last = b2; btn2ChangeMs = now; }
  else if (b2 == LOW && (now - btn2ChangeMs) >= BTN_DEBOUNCE_MS){
    Serial.println("BTN,BUZ2,PRESS");
    buzzPin(BUZ_TU2_PIN);
    markButtonActive(1);
    btn2ChangeMs = now + 1000;
  }

  bool b3 = digitalRead(BTN_BUZ3_PIN);
  if (b3 != btn3Last){ btn3Last = b3; btn3ChangeMs = now; }
  else if (b3 == LOW && (now - btn3ChangeMs) >= BTN_DEBOUNCE_MS){
    Serial.println("BTN,BUZ3,PRESS");
    buzzPin(BUZ3_PIN);
    markButtonActive(2);
    btn3ChangeMs = now + 1000;
  }

  bool b4 = digitalRead(BTN_BUZ4_PIN);
  if (b4 != btn4Last){ btn4Last = b4; btn4ChangeMs = now; }
  else if (b4 == LOW && (now - btn4ChangeMs) >= BTN_DEBOUNCE_MS){
    Serial.println("BTN,BUZ4,PRESS");
    buzzPin(BUZ4_PIN);
    markButtonActive(3);
    btn4ChangeMs = now + 1000;
  }
}

// =====================================================
// Ultrasonido
// =====================================================
float readUltrasonicCm(uint8_t id) {
  const UPin p = US_PINS[id];
  if (p.trig == UNUSED_PIN || p.echo == UNUSED_PIN) return 400.0f;
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
  if (id==TM1 || id==TM2 || id==TU3 || id==TU4) return THR_STOP_CM;
  return 9999.0f;
}

// =====================================================
// Paradas (ARRIVE/LEAVE) + ETA fijo
// =====================================================
const float    TU_SPEED_CM_S = 10.0f;
const uint16_t TU_D12_CM     = 105;   // 1 <-> 2
const float    TM_SPEED_CM_S = 10.0f;
const uint16_t TM_D12_CM     = 154;   // 1 <-> 2

static inline void publishETA_TU(uint8_t fromStop, uint8_t toStop){
  float t_s = (float)TU_D12_CM / max(1.0f, TU_SPEED_CM_S);
  Serial.print("TU,ETA_S,FROM="); Serial.print(fromStop);
  Serial.print(",TO="); Serial.print(toStop);
  Serial.print(","); Serial.println(t_s, 2);
}
static inline void publishETA_TM(uint8_t fromStop, uint8_t toStop){
  float t_s = (float)TM_D12_CM / max(1.0f, TM_SPEED_CM_S);
  Serial.print("TM,ETA_S,FROM="); Serial.print(fromStop);
  Serial.print(",TO="); Serial.print(toStop);
  Serial.print(","); Serial.println(t_s, 2);
}
static inline void TM_onArrive(uint8_t stopId){
  Serial.print("TM,ARRIVE,"); Serial.println(stopId==TM1?1:2);
}
static inline void TM_onLeave(uint8_t stopId){
  uint8_t from = (stopId==TM1)?1:2;
  uint8_t to   = (stopId==TM1)?2:1;
  Serial.print("TM,LEAVE,");  Serial.println(from);
  publishETA_TM(from, to); // si prefieres mover ETA al loop, comenta esta línea
}
static inline void TU_onArriveStop(uint8_t stopNum){
  Serial.print("TU,ARRIVE,"); Serial.println(stopNum);
}
static inline void TU_onLeaveStop(uint8_t stopNum){
  uint8_t from = stopNum;
  uint8_t to   = (stopNum==1)?2:1;
  Serial.print("TU,LEAVE,");  Serial.println(from);
  publishETA_TU(from, to);
}

// ===== Depuración de paradas =====
#if DEBUG_STOPS
static uint32_t dbgStopTs[4] = {0,0,0,0};
inline void debugStopDistances(){
  uint32_t now = millis();
  if (now - dbgStopTs[0] > DEBUG_STOPS_MS){ Serial.print("TM1,CM="); Serial.println(lastCm[TM1],1); dbgStopTs[0]=now; }
  if (now - dbgStopTs[1] > DEBUG_STOPS_MS){ Serial.print("TM2,CM="); Serial.println(lastCm[TM2],1); dbgStopTs[1]=now; }
  if (now - dbgStopTs[2] > DEBUG_STOPS_MS){ Serial.print("TU3,CM="); Serial.println(lastCm[TU3],1); dbgStopTs[2]=now; }
  if (now - dbgStopTs[3] > DEBUG_STOPS_MS){ Serial.print("TU4,CM="); Serial.println(lastCm[TU4],1); dbgStopTs[3]=now; }
}
#else
inline void debugStopDistances() {}
#endif

// =====================================================
// Semáforos (salidas físicas)
// =====================================================
const uint8_t A_R = 40, A_Y = 7, A_G = 42;
const uint8_t B_R = 43, B_Y = 44, B_G = 45;
const uint8_t A_R2 = 8,  A_Y2 = 9,  A_G2 = 10;
const uint8_t B_R2 = 11, B_Y2 = 12, B_G2 = 13;

const uint32_t T_GREEN  = 10000UL;
const uint32_t T_YELLOW = 2000UL;

enum Phase : uint8_t { P_A_GREEN, P_A_YELLOW, P_B_GREEN, P_B_YELLOW };
Phase phase = P_A_GREEN;
uint32_t phaseSince = 0;

void applyLights(){
  // HARDWARE físico
  digitalWrite(A_R, LOW);  digitalWrite(A_Y, LOW);  digitalWrite(A_G, LOW);
  digitalWrite(B_R, LOW);  digitalWrite(B_Y, LOW);  digitalWrite(B_G, LOW);
  digitalWrite(A_R2, LOW); digitalWrite(A_Y2, LOW); digitalWrite(A_G2, LOW);
  digitalWrite(B_R2, LOW); digitalWrite(B_Y2, LOW); digitalWrite(B_G2, LOW);

  switch (phase){
    case P_A_GREEN:  digitalWrite(A_G, HIGH);  digitalWrite(A_G2, HIGH);  digitalWrite(B_R, HIGH);  digitalWrite(B_R2, HIGH); break;
    case P_A_YELLOW: digitalWrite(A_Y, HIGH);  digitalWrite(A_Y2, HIGH);  digitalWrite(B_R, HIGH);  digitalWrite(B_R2, HIGH); break;
    case P_B_GREEN:  digitalWrite(B_G, HIGH);  digitalWrite(B_G2, HIGH);  digitalWrite(A_R, HIGH);  digitalWrite(A_R2, HIGH); break;
    case P_B_YELLOW: digitalWrite(B_Y, HIGH);  digitalWrite(B_Y2, HIGH);  digitalWrite(A_R, HIGH);  digitalWrite(A_R2, HIGH); break;
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
// Grupos lógicos A/B para UI (S1..S10) — SOLO afecta lo reportado a la UI/JSON
// =====================================================
#define SEM_A 0
#define SEM_B 1

// Mapeo solicitado: S3, S6 y S7 -> grupo B; los demás -> grupo A
const uint8_t S_GROUP[10] = {
  SEM_A,  // S1
  SEM_A,  // S2
  SEM_B,  // S3
  SEM_A,  // S4
  SEM_A,  // S5
  SEM_B,  // S6
  SEM_B,  // S7
  SEM_A,  // S8
  SEM_A,  // S9
  SEM_A   // S10
};

// Devuelve "VERDE"/"AMARILLO"/"ROJO" para S1..S10 según la fase y el grupo S_GROUP
const char* stateForIndex(int idx){
  if (idx < 0 || idx >= 10) return "ROJO";   // seguridad
  bool esA = (S_GROUP[idx] == SEM_A);
  switch (phase){
    case P_A_GREEN:   return esA ? "VERDE"    : "ROJO";
    case P_A_YELLOW:  return esA ? "AMARILLO" : "ROJO";
    case P_B_GREEN:   return esA ? "ROJO"     : "VERDE";
    case P_B_YELLOW:  return esA ? "ROJO"     : "AMARILLO";
  }
  return "ROJO";
}

// =====================================================
// Infracciones SD1..SD5
// =====================================================
const uint8_t SD_GROUP[5] = { SEM_A, SEM_A, SEM_A, SEM_A, SEM_B };
const uint8_t SD_BUZ[5] = { BUZ4_PIN, BUZ_TU2_PIN, BUZ_TU1_PIN, BUZ3_PIN, BUZ_TU1_PIN };
const float  SD_VIOL_CM = 10.0f;
const uint8_t SD_REQ    = 2;

inline bool isGroupRed(uint8_t g){
  return (g==SEM_A) ? (phase==P_B_GREEN || phase==P_B_YELLOW)
                    : (phase==P_A_GREEN || phase==P_A_YELLOW);
}

uint8_t sdConsec[5] = {0,0,0,0,0};
bool    sdAlerted[5]= {false,false,false,false,false};

inline void processSD(uint8_t idx){ // idx = 0..4 (SD1..SD5)
  uint8_t id = SD1 + idx;
  float cm = lastCm[id];
  bool red   = isGroupRed(SD_GROUP[idx]);
  bool below = (cm < SD_VIOL_CM);

  if (!red){ sdConsec[idx]=0; sdAlerted[idx]=false; return; }

  if (below){
    if (sdConsec[idx] < 255) sdConsec[idx]++;
    if (!sdAlerted[idx] && sdConsec[idx] >= SD_REQ){
      Serial.print("INFRACCION ROJO SD"); Serial.print(idx+1);
      Serial.print(", cm="); Serial.println(cm,1);
      buzzPin(SD_BUZ[idx]);
      sdAlerted[idx] = true;
    }
  } else {
    sdConsec[idx]=0;
    sdAlerted[idx]=false;
  }
}
inline void checkAllSD(){ for (uint8_t i=0;i<5;i++) processSD(i); }

// --- Mapeo de infracciones SD -> caras S que se notifican al UI
// Índices SD: 0..4  =>  SD1..SD5
// S se expresan 1..10 (como los espera Processing en "S#")
const uint8_t SD_TO_S_1[5] = {
  10, // SD1 -> S10
   7, // SD2 -> S7
   2, // SD3 -> S2
   6, // SD4 -> S6
   1  // SD5 -> S1
};
const uint8_t SD_TO_S_2[5] = {
   9, // SD1 -> S9
   0, // SD2 -> (sin segundo)
   4, // SD3 -> S4
   0, // SD4 -> (sin segundo)
   3  // SD5 -> S3
};
// Nota: si el segundo es 0, significa que ese SD solo mapea a una S.

// =====================================================
// SISMO (piezo en A6) - opcional
// =====================================================
#define PIN_EQ A6
const uint16_t EQ_THR_ABS  = 40;
const uint16_t EQ_THR_DIFF = 18;
const uint32_t EQ_HOLD_MS  = 5000UL;

int eq_base = 0, eq_prev = 0;
uint32_t eq_hold_until = 0;
bool eq_forced = false;

void EQ_init(){
  pinMode(PIN_EQ, INPUT);
  long sum = 0; for (int i=0;i<50;i++){ sum += analogRead(PIN_EQ); delay(4); }
  eq_base = (int)(sum/50);
  eq_prev = eq_base;
  Serial.print("EQ,BASE,"); Serial.println(eq_base);
}
inline bool EQ_isActive(){ return millis() < eq_hold_until; }
void EQ_releaseOutputsIfEnded(){
  if (eq_forced && !EQ_isActive()){
    digitalWrite(BUZ_TU1_PIN, LOW);
    digitalWrite(BUZ_TU2_PIN, LOW);
    digitalWrite(BUZ3_PIN, LOW);
    digitalWrite(BUZ4_PIN, LOW);
    eq_forced = false;
  }
}
void EQ_poll(){
  int v  = analogRead(PIN_EQ);
  int dv = abs(v - eq_prev);
  eq_prev = v;
  bool trigger = (abs(v - eq_base) >= (int)EQ_THR_ABS) || (dv >= (int)EQ_THR_DIFF);
  if (trigger && !EQ_isActive()){
    eq_hold_until = millis() + EQ_HOLD_MS;
  }
}
void EQ_applyOutputs(){
  if (EQ_isActive()){
    digitalWrite(BUZ_TU1_PIN, HIGH);
    digitalWrite(BUZ_TU2_PIN, HIGH);
    digitalWrite(BUZ3_PIN, HIGH);
    digitalWrite(BUZ4_PIN, HIGH);
    eq_forced = true;
  }
}
void EQ_announceEndIfAny(){
  static bool wasActive = false;
  bool act = EQ_isActive();
  if (wasActive && !act) Serial.println("EQ,END");
  wasActive = act;
}

// =====================================================
// STATUS JSON para Processing (JSON puro)
// =====================================================
uint32_t lastEmitMs = 0;
const uint32_t EMIT_MS = 1000; // cada 1 s (ajusta a gusto)

void emitStatusJson(){
  Serial.print('{');

  // ts
  Serial.print("\"ts\":\""); Serial.print(millis()); Serial.print("\",");

  // semáforos S1..S10 (texto) usando el mapeo S_GROUP
  Serial.print("\"semaforos\":{");
  for (int i=0;i<10;i++){
    Serial.print('"'); Serial.print('S'); Serial.print(i+1); Serial.print('"'); Serial.print(':');
    Serial.print('"'); Serial.print(stateForIndex(i)); Serial.print('"');
    if (i<9) Serial.print(',');
  }
  Serial.print("},");

  // dist_cm P1..P6 (entero redondeado) -> TM1, TM2, TU3, TU4, SD1, SD2
  Serial.print("\"dist_cm\":{");
  for (int i=0;i<6;i++){
    Serial.print('"'); Serial.print('P'); Serial.print(i+1); Serial.print('"'); Serial.print(':');
    int d = (int)round(lastCm[i]); // lastCm[0..5]
    Serial.print(d);
    if (i<5) Serial.print(',');
  }
  Serial.print("},");

  // gas_ppm (desde A0/A1)
  int a0 = analogRead(PIN_AO);
  int a1 = analogRead(PIN_A1);
  int gas1 = map(constrain(a0,0,1023),0,1023,150,300);
  int gas2 = map(constrain(a1,0,1023),0,1023,150,300);
  Serial.print("\"gas_ppm\":{");
  Serial.print("\"Z1\":"); Serial.print(gas1); Serial.print(',');
  Serial.print("\"Z2\":"); Serial.print(gas2); Serial.print("},");

  // zumbador (placeholders)
  Serial.print("\"zumbador\":{");
  Serial.print("\"Z1\":0,\"Z2\":0},");  // puedes reflejar HIGH/LOW reales

  // sismo
  Serial.print("\"sismo\":{");
  Serial.print("\"activo\":"); Serial.print(EQ_isActive()?1:0); Serial.print(',');
  Serial.print("\"magnitud\":0.0,\"origen\":\"\"},");

  // panic_buttons PB1..PB4 (1 si presionado hace <=3s)
  Serial.print("\"panic_buttons\":{");
  for (int i=0;i<4;i++){
    Serial.print('"'); Serial.print('P'); Serial.print('B'); Serial.print(i+1); Serial.print('"'); Serial.print(':');
    Serial.print('{');
    Serial.print("\"activo\":"); Serial.print(buttonsActive[i]?1:0); Serial.print(',');
    Serial.print("\"ts\":\""); Serial.print(millis()); Serial.print("\",");
    Serial.print("\"id\":\"PB"); Serial.print(i+1); Serial.print("\"");
    Serial.print('}');
    if (i<3) Serial.print(',');
  }
  Serial.print("},");

  // infracciones: publica S# según infracción SD# y el mapeo pedido
  Serial.print("\"infracciones\":[");
  bool first = true;
  for (int sd = 0; sd < 5; sd++) {           // sd = 0..4 => SD1..SD5
    if (sdAlerted[sd]) {                      // ya detectado en processSD
      uint8_t sA = SD_TO_S_1[sd];
      uint8_t sB = SD_TO_S_2[sd];
      if (sA >= 1 && sA <= 10) {
        if (!first) Serial.print(',');
        Serial.print('"'); Serial.print('S'); Serial.print(sA); Serial.print('"');
        first = false;
      }
      if (sB >= 1 && sB <= 10) {
        if (!first) Serial.print(',');
        Serial.print('"'); Serial.print('S'); Serial.print(sB); Serial.print('"');
        first = false;
      }
    }
  }
  Serial.print("],");

  // versión de protocolo
  Serial.print("\"_protocol_version\":\"1.0\"}");

  Serial.println();
}

// =====================================================
// Setup / Loop
// =====================================================
void setup() {
  Serial.begin(115200);
  for (int i=0;i<N_SENSORS;i++){
    if (US_PINS[i].trig == UNUSED_PIN || US_PINS[i].echo == UNUSED_PIN) continue;
    pinMode(US_PINS[i].trig, OUTPUT); digitalWrite(US_PINS[i].trig, LOW);
    pinMode(US_PINS[i].echo, INPUT);
  }

  // Semáforos
  pinMode(A_R, OUTPUT); pinMode(A_Y, OUTPUT); pinMode(A_G, OUTPUT);
  pinMode(B_R, OUTPUT); pinMode(B_Y, OUTPUT); pinMode(B_G, OUTPUT);
  pinMode(A_R2, OUTPUT); pinMode(A_Y2, OUTPUT); pinMode(A_G2, OUTPUT);
  pinMode(B_R2, OUTPUT); pinMode(B_Y2, OUTPUT); pinMode(B_G2, OUTPUT);
  phaseSince = millis(); applyLights();

  // Buzzers y botones
  pinMode(BUZ_TU1_PIN, OUTPUT); digitalWrite(BUZ_TU1_PIN, LOW);
  pinMode(BUZ_TU2_PIN, OUTPUT); digitalWrite(BUZ_TU2_PIN, LOW);
  pinMode(BUZ3_PIN, OUTPUT);    digitalWrite(BUZ3_PIN, LOW);
  pinMode(BUZ4_PIN, OUTPUT);    digitalWrite(BUZ4_PIN, LOW);
  pinMode(BTN_BUZ1_PIN, INPUT_PULLUP);
  pinMode(BTN_BUZ2_PIN, INPUT_PULLUP);
  pinMode(BTN_BUZ3_PIN, INPUT_PULLUP);
  pinMode(BTN_BUZ4_PIN, INPUT_PULLUP);

  // Incendios
  pinMode(PIN_AO, INPUT);
  pinMode(PIN_A1, INPUT);

  // Sismo
  EQ_init();
}

void loop() {
  // Expirar “activo” de botones
  for (int i=0;i<4;i++) if (buttonsActive[i] && millis() >= buttonsUntil[i]) buttonsActive[i]=false;

  // Botones / zumbadores
  readButtonsAndTrigger();
  updateBuzzers();

  // Incendios + mezcla con BUZ3/BUZ4
  bool incendio1 = (analogRead(PIN_AO) >= HUMO_UMBRAL);
  bool incendio2 = (analogRead(PIN_A1) >= HUMO_UMBRAL);
  digitalWrite(BUZ3_PIN, (incendio1 || (millis() < buz3Until)) ? HIGH : LOW);
  digitalWrite(BUZ4_PIN, (incendio2 || (millis() < buz4Until)) ? HIGH : LOW);

  // Lecturas ultrasónicas + ARRIVE/LEAVE
  for (uint8_t id = 0; id < N_SENSORS; id++) {
    float cm = readUltrasonicCm(id);
    lastCm[id] = cm;

    float thr = thrFor(id);
    if (thr < 9000.0f) {
      bool below = (cm < thr);
      uint32_t now = millis();

      if (!wasBelow[id] && below) {
        wasBelow[id] = true;
        stableReported[id] = false;
        belowStartMs[id] = now;
      }

      if (wasBelow[id] && !stableReported[id] && (now - belowStartMs[id] >= STABLE_MS)) {
        stableReported[id] = true;
        if (id == TM1 || id == TM2) TM_onArrive(id);
        else if (id == TU3)          TU_onArriveStop(1);
        else if (id == TU4)          TU_onArriveStop(2);
        stopETAArmed[id] = true; // si mueves ETA al loop, úsalo
      }

      if (wasBelow[id] && !below) {
        wasBelow[id] = false;
        stableReported[id] = false;

        if (id == TM1 || id == TM2) TM_onLeave(id);
        else if (id == TU3)          TU_onLeaveStop(1);
        else if (id == TU4)          TU_onLeaveStop(2);

        stopETAArmed[id] = false;
      }
    }
  }

  // Depuración (opcional)
  debugStopDistances();

  // Infracciones SD1..SD5
  checkAllSD();

  // Semáforos
  updateTrafficLights();

  // Sismo
  EQ_applyOutputs();
  EQ_announceEndIfAny();
  EQ_poll();

  // STATUS JSON periódico (compatible con tu readSerial() que exige '{' al inicio)
  if (millis() - lastEmitMs >= EMIT_MS) {
    emitStatusJson();
    lastEmitMs = millis();
  }

  delay(60);
} 

