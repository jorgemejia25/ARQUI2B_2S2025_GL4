/*
  Ciudad – sensores (Transmetro + Transurbano + SD cruces)
  Serial 115200:
    - Paradas: TM,ARRIVE/LEAVE,<1|2>  |  TU,ARRIVE/LEAVE,<1|2>
    - ETA fijo: TM,ETA_S,FROM=x,TO=y,<seg> | TU,ETA_S,FROM=x,TO=y,<seg>
    - Infracciones: INFRACCION ROJO SDn, cm=...
*/

#include <Arduino.h>

// ===== Depuración =====
#define DEBUG_STOPS 0           // 0 para apagar depuración de TM1/TM2/TU3/TU4
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

// Pines TRIG/ECHO (AJUSTA SD1..SD4 a tus pines reales si no usas A8..A15)
struct UPin { uint8_t trig, echo; };
const UPin US_PINS[N_SENSORS] = {
  {22,23},   // TM1
  {24,25},   // TM2
  {7,6},   // TU3
  {32,33},   // TU4
  {46, 47},  // SD1  
  {48,49}, // SD2  
  {50,51}, // SD3  
  {52,53}, // SD4 
  {26,27}    // SD5  (confirmado)
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
bool stopETAArmed[N_SENSORS] = {0};   // Se arma al llegar (3s <5 cm) y se consume al salir


// =====================================================
// BUZZERS y BOTONES
// =====================================================
const uint8_t BUZ_TU1_PIN = 36;  // BUZ1
const uint8_t BUZ_TU2_PIN = 37;  // BUZ2
const uint8_t BUZ3_PIN    = 2;   // BUZ3
const uint8_t BUZ4_PIN    = 3;   // BUZ4
const uint16_t BUZZ_MS    = 500;

uint32_t buz1Until = 0, buz2Until = 0, buz3Until = 0, buz4Until = 0;

inline void buzzPin(uint8_t pin){
  if (pin==BUZ_TU1_PIN) { digitalWrite(BUZ_TU1_PIN, HIGH); buz1Until = millis() + BUZZ_MS; }
  else if (pin==BUZ_TU2_PIN) { digitalWrite(BUZ_TU2_PIN, HIGH); buz2Until = millis() + BUZZ_MS; }
  else if (pin==BUZ3_PIN) { buz3Until = millis() + BUZZ_MS; }
  else if (pin==BUZ4_PIN) { buz4Until = millis() + BUZZ_MS; }
}
void updateBuzzers(){
  uint32_t now = millis();
  if (buz1Until && now >= buz1Until){ digitalWrite(BUZ_TU1_PIN, LOW); buz1Until = 0; }
  if (buz2Until && now >= buz2Until){ digitalWrite(BUZ_TU2_PIN, LOW); buz2Until = 0; }
  // BUZ3/BUZ4 se controlan más abajo con OR (botón/incendio/temporizador)
}

// Botones manuales
const uint8_t BTN_BUZ1_PIN = 38;
const uint8_t BTN_BUZ2_PIN = 39;
const uint8_t BTN_BUZ3_PIN = 4;
const uint8_t BTN_BUZ4_PIN = 5;
const uint16_t BTN_DEBOUNCE_MS = 150;
bool btn1Last = HIGH, btn2Last = HIGH;
uint32_t btn1ChangeMs = 0, btn2ChangeMs = 0;
bool btn3Last = HIGH, btn4Last = HIGH;
uint32_t btn3ChangeMs = 0, btn4ChangeMs = 0;


inline void readButtonsAndTrigger(){
  uint32_t now = millis();

  // --- BTN BUZ1 ---
  bool b1 = digitalRead(BTN_BUZ1_PIN);
  if (b1 != btn1Last){ btn1Last = b1; btn1ChangeMs = now; }
  else if (b1 == LOW && (now - btn1ChangeMs) >= BTN_DEBOUNCE_MS){
    Serial.println("BTN,BUZ1,PRESS");
    buzzPin(BUZ_TU1_PIN);
    btn1ChangeMs = now + 1000; // anti-repetición
  }

  // --- BTN BUZ2 ---
  bool b2 = digitalRead(BTN_BUZ2_PIN);
  if (b2 != btn2Last){ btn2Last = b2; btn2ChangeMs = now; }
  else if (b2 == LOW && (now - btn2ChangeMs) >= BTN_DEBOUNCE_MS){
    Serial.println("BTN,BUZ2,PRESS");
    buzzPin(BUZ_TU2_PIN);
    btn2ChangeMs = now + 1000;
  }

  // --- BTN BUZ3 ---
  bool b3 = digitalRead(BTN_BUZ3_PIN);
  if (b3 != btn3Last){ btn3Last = b3; btn3ChangeMs = now; }
  else if (b3 == LOW && (now - btn3ChangeMs) >= BTN_DEBOUNCE_MS){
    Serial.println("BTN,BUZ3,PRESS");
    buzzPin(BUZ3_PIN);           // usa tu mismo pulso temporizado
    btn3ChangeMs = now + 1000;   // anti-repetición
  }

  // --- BTN BUZ4 ---
  bool b4 = digitalRead(BTN_BUZ4_PIN);
  if (b4 != btn4Last){ btn4Last = b4; btn4ChangeMs = now; }
  else if (b4 == LOW && (now - btn4ChangeMs) >= BTN_DEBOUNCE_MS){
    Serial.println("BTN,BUZ4,PRESS");
    buzzPin(BUZ4_PIN);
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
  return 9999.0f; // SDx no usan esta lógica
}

// =====================================================
// Paradas (ARRIVE/LEAVE) + ETA fijo
// =====================================================
// Constantes de ETA fijas
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
  publishETA_TM(from, to);                // ETA fijo al salir
}
static inline void TU_onArriveStop(uint8_t stopNum){
  Serial.print("TU,ARRIVE,"); Serial.println(stopNum);
}
static inline void TU_onLeaveStop(uint8_t stopNum){
  uint8_t from = stopNum;
  uint8_t to   = (stopNum==1)?2:1;
  Serial.print("TU,LEAVE,");  Serial.println(from);
  publishETA_TU(from, to);                // ETA fijo al salir
}

// ===== Depuración de paradas (distancias) =====
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
// Semáforos
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
// Infracciones SD1..SD5
// =====================================================
#define SEM_A 0
#define SEM_B 1

// Grupos: SD1..SD4 -> A ; SD5 -> B
const uint8_t SD_GROUP[5] = { SEM_A, SEM_A, SEM_A, SEM_A, SEM_B };

// Buzzer cercano para cada SD (según tu plano; AJUSTA si cambia)
const uint8_t SD_BUZ[5] = {
  BUZ4_PIN,     // SD1 -> BUZ4
  BUZ_TU2_PIN,  // SD2 -> BUZ2
  BUZ_TU1_PIN,  // SD3 -> BUZ1
  BUZ3_PIN,     // SD4 -> BUZ3
  BUZ_TU1_PIN   // SD5 -> BUZ1
};

const float  SD_VIOL_CM = 10.0f;
const uint8_t SD_REQ    = 2;

inline bool isGroupRed(uint8_t g){
  return (g==SEM_A) ? (phase==P_B_GREEN || phase==P_B_YELLOW)
                    : (phase==P_A_GREEN || phase==P_A_YELLOW);
}

uint8_t sdConsec[5] = {0,0,0,0,0};
bool    sdAlerted[5]= {false,false,false,false,false};

inline void processSD(uint8_t idx){       // idx = 0..4 (SD1..SD5)
  uint8_t id = SD1 + idx;
  float cm = lastCm[id];
  bool red   = isGroupRed(SD_GROUP[idx]);
  bool below = (cm < SD_VIOL_CM);

  // Depuración per-SD
   //static uint32_t t[5];
   //if (millis()-t[idx]>250){ Serial.print("SD");Serial.print(idx+1);Serial.print(",CM=");Serial.println(cm,1); t[idx]=millis(); }

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
  long sum = 0;
  for (int i=0;i<50;i++){ sum += analogRead(PIN_EQ); delay(4); }
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

  EQ_init();
}

void loop() {
  EQ_releaseOutputsIfEnded();
  readButtonsAndTrigger();

  // Incendios + botones BUZ3/BUZ4
  bool incendio1 = (analogRead(PIN_AO) >= HUMO_UMBRAL);
  bool incendio2 = (analogRead(PIN_A1) >= HUMO_UMBRAL);
  digitalWrite(BUZ3_PIN, (incendio1 || (millis() < buz3Until)) ? HIGH : LOW);
  digitalWrite(BUZ4_PIN, (incendio2 || (millis() < buz4Until)) ? HIGH : LOW);


  // Lecturas ultrasónicas
  for (uint8_t id = 0; id < N_SENSORS; id++) {
    float cm = readUltrasonicCm(id);
    lastCm[id] = cm;

    // Solo paradas ARRIVE/LEAVE (TM1/TM2/TU3/TU4)
    float thr = thrFor(id);
    if (thr < 9000.0f) {
      bool below = (cm < thr);
      uint32_t now = millis();

      // Entró bajo umbral
      if (!wasBelow[id] && below) {
        wasBelow[id] = true;
        stableReported[id] = false;
        belowStartMs[id] = now;
      }

      // Llegada válida: ≥3s por debajo de THR_STOP_CM
      if (wasBelow[id] && !stableReported[id] && (now - belowStartMs[id] >= STABLE_MS)) {
        stableReported[id] = true;
        if (id == TM1 || id == TM2) {
          TM_onArrive(id);
        } else if (id == TU3) {
          TU_onArriveStop(1);
        } else if (id == TU4) {
          TU_onArriveStop(2);
        }
        // Armar ETA para dispararlo al irse
        stopETAArmed[id] = true;
      }

      // Salió de la parada (subió por encima del umbral)
      if (wasBelow[id] && !below) {
        wasBelow[id] = false;
        stableReported[id] = false;

        if (id == TM1 || id == TM2) {
          TM_onLeave(id);
        } else if (id == TU3) {
          TU_onLeaveStop(1);
        } else if (id == TU4) {
          TU_onLeaveStop(2);
        }

        // Publicar ETA SOLO si antes hubo llegada válida
        if (stopETAArmed[id]) {
          if (id == TM1 || id == TM2) {
            uint8_t from = (id == TM1) ? 1 : 2;
            uint8_t to   = (id == TM1) ? 2 : 1;
            publishETA_TM(from, to);
          } else if (id == TU3 || id == TU4) {
            uint8_t from = (id == TU3) ? 1 : 2;
            uint8_t to   = (id == TU3) ? 2 : 1;
            publishETA_TU(from, to);
          }
        }
        // Desarmar para no repetir
        stopETAArmed[id] = false;
      }
    }
  }

  // --- Depuración de distancias de TM/TU ---
  debugStopDistances();

  // Infracciones SD1..SD5
  checkAllSD();

  // Semáforos y buzzers
  updateTrafficLights();
  updateBuzzers();

  // Sismo opcional
  EQ_applyOutputs();
  EQ_announceEndIfAny();

  delay(60);
}