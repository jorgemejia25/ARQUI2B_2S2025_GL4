/*
  Ciudad – sensores (Transmetro + Transurbano + SD cruces)
  Serial 115200:
    - Paradas: TM,ARRIVE/LEAVE,<1|2>  |  TU,ARRIVE/LEAVE,<1|2>
    - ETA fijo: TM,ETA_S,FROM=x,TO=y,<seg> | TU,ETA_S,FROM=x,TO=y,<seg>
    - Infracciones: INFRACCION ROJO SDn, cm=...

  Estado periódico (NDJSON):
  {
    "ts":"...", "semaforos":{S1..S10}, "dist_cm":{P1..P6}, "gas_ppm":{Z1,Z2},
    "zumbador":{Z1,Z2}, "sismo":{activo,...}, "panic_buttons":{PB1..PB4},
    "infracciones":[ "S#", ... ], "_protocol_version":"1.1"
  }
*/

#include <Arduino.h>

// ===== Depuración =====
#define DEBUG_STOPS 0
const uint16_t DEBUG_STOPS_MS = 250;

// ---------- Incendios ----------
#define PIN_AO A0
#define PIN_A1 A1
const int HUMO_UMBRAL = 500;

// ---------- Sensores ----------
enum
{
  TM1 = 0,
  TM2 = 1,
  TU3 = 2,
  TU4 = 3,
  SD1 = 4,
  SD2 = 5,
  SD3 = 6,
  SD4 = 7,
  SD5 = 8
};
const uint8_t N_SENSORS = 9;
const uint8_t UNUSED_PIN = 255;

struct UPin
{
  uint8_t trig, echo;
};
const UPin US_PINS[N_SENSORS] = {
    {22, 23}, {24, 25}, {7, 6}, {32, 33}, {46, 47}, {48, 49}, {50, 51}, {52, 53}, {26, 27}};

// ---------- Parámetros ----------
const float THR_STOP_CM = 6.0f;
const uint32_t STABLE_MS = 3000UL;
const unsigned long ECHO_TIMEOUT_US = 20000UL;

// ---------- Estado genérico ----------
bool wasBelow[N_SENSORS] = {0};
bool stableReported[N_SENSORS] = {0};
uint32_t belowStartMs[N_SENSORS] = {0};
float lastCm[N_SENSORS] = {0};
bool stopETAArmed[N_SENSORS] = {0};

// =====================================================
// BUZZERS y BOTONES
// =====================================================
const uint8_t BUZ_TU1_PIN = 36; // BUZ1
const uint8_t BUZ_TU2_PIN = 37; // BUZ2
const uint8_t BUZ3_PIN = 2;     // BUZ3 (también sirena)
const uint8_t BUZ4_PIN = 3;     // BUZ4
const uint16_t BUZZ_MS = 500;

uint32_t buz1Until = 0, buz2Until = 0, buz3Until = 0, buz4Until = 0;

// Variables para sirenas de alerta
bool sirenaActiva = false;
uint32_t sirenaHasta = 0;

// Variables para incendios
bool incendioActivo = false;
uint32_t incendioHasta = 0;
uint32_t incendioLastChange = 0;
bool incendioTonoAlto = true;
const uint32_t INCENDIO_CHANGE_MS = 200; // Cambio cada 200ms
const int INCENDIO_FREQ_LOW = 800;  // Frecuencia baja
const int INCENDIO_FREQ_HIGH = 1200; // Frecuencia alta

int roboFreqs[3] = {100, 300, 600};
int armaFreqs[3] = {200, 500, 800};
const uint32_t ROBO_CHANGE_MS = 500;
const uint32_t ARMA_CHANGE_MS = 300;

int sirenFreqIndex = 0;
int *currentFreqs;
uint32_t currentChangeMs;
uint32_t sirenLastChange = 0;

enum AlertaTipo { NINGUNA, ARMA, ROBO };
AlertaTipo alertaActual = NINGUNA;

bool panicButtonsActiveState[4] = {false, false, false, false};
uint32_t panicButtonsUntil[4] = {0, 0, 0, 0};

inline void buzzPin(uint8_t pin)
{
  uint32_t now = millis();
  if (pin == BUZ_TU1_PIN)
  {
    digitalWrite(BUZ_TU1_PIN, HIGH);
    buz1Until = now + 2000;
    Serial.print("MENSAJECALIFICACION,");
  }
  else if (pin == BUZ_TU2_PIN)
  {
    digitalWrite(BUZ_TU2_PIN, HIGH);
    buz2Until = now + 2000;
  }
  else if (pin == BUZ3_PIN)
  {
    if (!sirenaActiva) // Solo activar si no hay sirena activa
    {
      digitalWrite(BUZ3_PIN, HIGH);
      buz3Until = now + 2000;
    }
  }
  else if (pin == BUZ4_PIN)
  {
    digitalWrite(BUZ4_PIN, HIGH);
    buz4Until = now + 2000;
  }
}
void updateBuzzers()
{
  uint32_t now = millis();
  if (buz1Until && now >= buz1Until)
  {
    digitalWrite(BUZ_TU1_PIN, LOW);
    buz1Until = 0;
  }
  if (buz2Until && now >= buz2Until)
  {
    digitalWrite(BUZ_TU2_PIN, LOW);
    buz2Until = 0;
  }
  if (buz3Until && now >= buz3Until)
  {
    if (!sirenaActiva) // Solo apagar si no hay sirena activa
      digitalWrite(BUZ3_PIN, LOW);
    buz3Until = 0;
  }
  if (buz4Until && now >= buz4Until)
  {
    digitalWrite(BUZ4_PIN, LOW);
    buz4Until = 0;
  }
}

void updateSirena()
{
  if (sirenaActiva)
  {
    uint32_t now = millis();
    if (now - sirenLastChange >= currentChangeMs)
    {
      sirenFreqIndex = (sirenFreqIndex + 1) % 3;
      tone(BUZ3_PIN, currentFreqs[sirenFreqIndex]); // Usar pin 2 para sirena
      sirenLastChange = now;
    }
    if (now >= sirenaHasta)
    {
      noTone(BUZ3_PIN); // Apagar el tono
      sirenaActiva = false;
      alertaActual = NINGUNA;
    }
  }
}

void updateIncendio()
{
  if (incendioActivo)
  {
    uint32_t now = millis();
    if (now - incendioLastChange >= INCENDIO_CHANGE_MS)
    {
      int freq = incendioTonoAlto ? INCENDIO_FREQ_HIGH : INCENDIO_FREQ_LOW;
      tone(BUZ3_PIN, freq); // Usar pin 2 para sonido de incendio
      incendioTonoAlto = !incendioTonoAlto; // Alternar tono
      incendioLastChange = now;
    }
    if (now >= incendioHasta)
    {
      noTone(BUZ3_PIN); // Apagar el tono
      incendioActivo = false;
    }
  }
}

// Botones
const uint8_t BTN_BUZ1_PIN = 38;
const uint8_t BTN_BUZ2_PIN = 39;
const uint8_t BTN_BUZ3_PIN = 4;
const uint8_t BTN_BUZ4_PIN = 5;
const uint16_t BTN_DEBOUNCE_MS = 150;
bool btn1Last = HIGH, btn2Last = HIGH, btn3Last = HIGH, btn4Last = HIGH;
uint32_t btn1ChangeMs = 0, btn2ChangeMs = 0, btn3ChangeMs = 0, btn4ChangeMs = 0;

inline void readButtonsAndTrigger()
{
  uint32_t now = millis();

  bool b1 = digitalRead(BTN_BUZ1_PIN);
  if (b1 != btn1Last)
  {
    btn1Last = b1;
    btn1ChangeMs = now;
  }
  else if (b1 == LOW && (now - btn1ChangeMs) >= BTN_DEBOUNCE_MS)
  {
    panicButtonsActiveState[0] = true;
    panicButtonsUntil[0] = now + 2000;
    buzzPin(BUZ_TU1_PIN);
    btn1ChangeMs = now + 1000;
  }

  bool b2 = digitalRead(BTN_BUZ2_PIN);
  if (b2 != btn2Last)
  {
    btn2Last = b2;
    btn2ChangeMs = now;
  }
  else if (b2 == LOW && (now - btn2ChangeMs) >= BTN_DEBOUNCE_MS)
  {
    panicButtonsActiveState[1] = true;
    panicButtonsUntil[1] = now + 2000;
    buzzPin(BUZ_TU2_PIN);
    btn2ChangeMs = now + 1000;
  }

  bool b3 = digitalRead(BTN_BUZ3_PIN);
  if (b3 != btn3Last)
  {
    btn3Last = b3;
    btn3ChangeMs = now;
  }
  else if (b3 == LOW && (now - btn3ChangeMs) >= BTN_DEBOUNCE_MS)
  {
    panicButtonsActiveState[2] = true;
    panicButtonsUntil[2] = now + 2000;
    buzzPin(BUZ3_PIN);
    btn3ChangeMs = now + 1000;
  }

  bool b4 = digitalRead(BTN_BUZ4_PIN);
  if (b4 != btn4Last)
  {
    btn4Last = b4;
    btn4ChangeMs = now;
  }
  else if (b4 == LOW && (now - btn4ChangeMs) >= BTN_DEBOUNCE_MS)
  {
    panicButtonsActiveState[3] = true;
    panicButtonsUntil[3] = now + 2000;
    buzzPin(BUZ4_PIN);
    btn4ChangeMs = now + 1000;
  }
}

// =====================================================
// Semáforos
// =====================================================
const uint32_t T_GREEN = 10000UL;
const uint32_t T_YELLOW = 2000UL;

enum Phase : uint8_t
{
  P_A_GREEN,
  P_A_YELLOW,
  P_B_GREEN,
  P_B_YELLOW
};
Phase phase = P_A_GREEN;
uint32_t phaseSince = 0;

const uint8_t A_R = 40, A_Y = 7, A_G = 42;
const uint8_t B_R = 43, B_Y = 44, B_G = 45;
const uint8_t A_R2 = 8, A_Y2 = 9, A_G2 = 10;
const uint8_t B_R2 = 11, B_Y2 = 12, B_G2 = 13;

void applyLights()
{
  digitalWrite(A_R, LOW);
  digitalWrite(A_Y, LOW);
  digitalWrite(A_G, LOW);
  digitalWrite(B_R, LOW);
  digitalWrite(B_Y, LOW);
  digitalWrite(B_G, LOW);
  digitalWrite(A_R2, LOW);
  digitalWrite(A_Y2, LOW);
  digitalWrite(A_G2, LOW);
  digitalWrite(B_R2, LOW);
  digitalWrite(B_Y2, LOW);
  digitalWrite(B_G2, LOW);

  switch (phase)
  {
  case P_A_GREEN:
    digitalWrite(A_G, HIGH);
    digitalWrite(A_G2, HIGH);
    digitalWrite(B_R, HIGH);
    digitalWrite(B_R2, HIGH);
    break;
  case P_A_YELLOW:
    digitalWrite(A_Y, HIGH);
    digitalWrite(A_Y2, HIGH);
    digitalWrite(B_R, HIGH);
    digitalWrite(B_R2, HIGH);
    break;
  case P_B_GREEN:
    digitalWrite(B_G, HIGH);
    digitalWrite(B_G2, HIGH);
    digitalWrite(A_R, HIGH);
    digitalWrite(A_R2, HIGH);
    break;
  case P_B_YELLOW:
    digitalWrite(B_Y, HIGH);
    digitalWrite(B_Y2, HIGH);
    digitalWrite(A_R, HIGH);
    digitalWrite(A_R2, HIGH);
    break;
  }
}
void nextPhase()
{
  switch (phase)
  {
  case P_A_GREEN:
    phase = P_A_YELLOW;
    break;
  case P_A_YELLOW:
    phase = P_B_GREEN;
    break;
  case P_B_GREEN:
    phase = P_B_YELLOW;
    break;
  case P_B_YELLOW:
    phase = P_A_GREEN;
    break;
  }
  phaseSince = millis();
  applyLights();
}
void updateTrafficLights()
{
  uint32_t now = millis();
  switch (phase)
  {
  case P_A_GREEN:
  case P_B_GREEN:
    if (now - phaseSince >= T_GREEN)
      nextPhase();
    break;
  case P_A_YELLOW:
  case P_B_YELLOW:
    if (now - phaseSince >= T_YELLOW)
      nextPhase();
    break;
  }
}

// ===== Mapeo de grupos por semáforo (UI S1..S10) =====
#define SEM_A 0
#define SEM_B 1
// S3, S7 y S9 son grupo B; el resto A
const uint8_t S_GROUP[10] = {
    SEM_A, // S1
    SEM_A, // S2
    SEM_B, // S3
    SEM_A, // S4
    SEM_A, // S5
    SEM_A, // S6
    SEM_B, // S7
    SEM_A, // S8
    SEM_B, // S9
    SEM_A  // S10
};

// Estado textual por semáforo usando el mapeo anterior
const char *stateForIndex(int idx)
{
  uint8_t g = S_GROUP[idx];
  if (g == SEM_A)
  {
    if (phase == P_A_GREEN)
      return "VERDE";
    if (phase == P_A_YELLOW)
      return "AMARILLO";
    return "ROJO";
  }
  else
  {
    if (phase == P_B_GREEN)
      return "VERDE";
    if (phase == P_B_YELLOW)
      return "AMARILLO";
    return "ROJO";
  }
}

// =====================================================
// Dirección TU (para SD1/SD3 dinámicos)
// =====================================================
enum TuDir : uint8_t
{
  TU_UNKNOWN = 0,
  TU_1_TO_2 = 12,
  TU_2_TO_1 = 21
};
volatile TuDir tuDir = TU_UNKNOWN;

// =====================================================
// Infracciones SD1..SD5
// =====================================================
const uint8_t SD_GROUP[5] = {SEM_A, SEM_A, SEM_A, SEM_A, SEM_B};
const uint8_t SD_BUZ[5] = {BUZ4_PIN, BUZ_TU2_PIN, BUZ_TU1_PIN, BUZ3_PIN, BUZ_TU1_PIN};

const float SD_VIOL_CM = 10.0f;
const uint8_t SD_REQ = 2;

inline bool isGroupRed(uint8_t g)
{
  return (g == SEM_A) ? (phase == P_B_GREEN || phase == P_B_YELLOW)
                      : (phase == P_A_GREEN || phase == P_A_YELLOW);
}

uint8_t sdConsec[5] = {0, 0, 0, 0, 0};
bool sdAlerted[5] = {false, false, false, false, false};
uint32_t sdAlertedTime[5] = {0, 0, 0, 0, 0};  // Timestamp cuando se detectó la infracción
const uint32_t INFRACTION_HOLD_MS = 5000UL;    // Mantener infracción activa por 5 segundos


// Cambia solamente flutter para que los semaforos del svg solo sean SD y SI en el SVG. Que se enciendan por grupos solamente. Esto en el mapa. Para no complicarnos y que se enciendan agrupados
// Mapeo por dirección
const uint8_t SD_TO_S_DIR21[5] = {1, 3, 5, 7, 9};  // TU 2→1
const uint8_t SD_TO_S_DIR12[5] = {10, 3, 4, 7, 9}; // TU 1→2

inline void processSD(uint8_t idx)
{
  uint8_t id = SD1 + idx;
  float cm = lastCm[id];
  bool red = isGroupRed(SD_GROUP[idx]);
  bool below = (cm < SD_VIOL_CM);

  if (!red)
  {
    sdConsec[idx] = 0;
    sdAlerted[idx] = false;
    return;
  }

  if (below)
  {
    if (sdConsec[idx] < 255)
      sdConsec[idx]++;
    if (!sdAlerted[idx] && sdConsec[idx] >= SD_REQ)
    {
      uint8_t sIdx = (tuDir == TU_2_TO_1)   ? SD_TO_S_DIR21[idx]
                     : (tuDir == TU_1_TO_2) ? SD_TO_S_DIR12[idx]
                                            : SD_TO_S_DIR21[idx];
      Serial.print("INFRACCION ROJO SD");
      Serial.print(idx + 1);
      Serial.print(" -> Semaforo S");
      Serial.print(sIdx);
      Serial.print(", cm=");
      Serial.println(cm, 1);

      buzzPin(SD_BUZ[idx]);
      sdAlerted[idx] = true;
      sdAlertedTime[idx] = millis();  // Guardar timestamp
    }
  }
  else
  {
    sdConsec[idx] = 0;
    // NO resetear sdAlerted inmediatamente, se limpia por timeout
  }
}
inline void clearExpiredInfractions()
{
  // Limpiar infracciones que han expirado después de INFRACTION_HOLD_MS
  uint32_t now = millis();
  for (uint8_t i = 0; i < 5; i++)
  {
    if (sdAlerted[i] && (now - sdAlertedTime[i] >= INFRACTION_HOLD_MS))
    {
      sdAlerted[i] = false;
      sdAlertedTime[i] = 0;
    }
  }
}
inline void checkAllSD()
{
  for (uint8_t i = 0; i < 5; i++)
    processSD(i);
  clearExpiredInfractions();  // Limpiar infracciones expiradas
}

// =====================================================
// SISMO (por sensor piezo en A6) — reintegrado
// =====================================================
#define PIN_EQ A6
const uint16_t EQ_THR_ABS = 40;     // umbral absoluto sobre la base
const uint16_t EQ_THR_DIFF = 18;    // umbral de variación instantánea
const uint32_t EQ_HOLD_MS = 5000UL; // tiempo activo tras disparo

int eq_base = 0, eq_prev = 0;
uint32_t eq_hold_until = 0;
bool eq_forced = false;

uint32_t eq_block_until = 0;
const uint32_t EQ_REARM_MS = 1000; // 1s de bloqueo tras un sismo

void EQ_init()
{
  pinMode(PIN_EQ, INPUT);
  long sum = 0;
  for (int i = 0; i < 50; i++)
  {
    sum += analogRead(PIN_EQ);
    delay(4);
  }
  eq_base = (int)(sum / 50);
  eq_prev = eq_base;
  Serial.print("EQ,BASE,");
  Serial.println(eq_base);
}
inline bool EQ_isActive() { return millis() < eq_hold_until; }
void EQ_releaseOutputsIfEnded()
{
  if (eq_forced && !EQ_isActive())
  {
    digitalWrite(BUZ_TU1_PIN, LOW);
    digitalWrite(BUZ_TU2_PIN, LOW);
    digitalWrite(BUZ3_PIN, LOW);
    digitalWrite(BUZ4_PIN, LOW);
    eq_forced = false;
  }
}
void EQ_poll()
{
  int v = analogRead(PIN_EQ);
  int dv = abs(v - eq_prev);
  eq_prev = v;
  bool trigger = (abs(v - eq_base) >= (int)EQ_THR_ABS) || (dv >= (int)EQ_THR_DIFF);
  if (trigger && !EQ_isActive() && millis() >= eq_block_until)
  {
    eq_hold_until = millis() + EQ_HOLD_MS;
    eq_block_until = eq_hold_until + EQ_REARM_MS; // no rearmar hasta 1s después
  }
}
void EQ_applyOutputs()
{
  if (EQ_isActive())
  {
    digitalWrite(BUZ_TU1_PIN, HIGH);
    digitalWrite(BUZ_TU2_PIN, HIGH);
    digitalWrite(BUZ3_PIN, HIGH);
    digitalWrite(BUZ4_PIN, HIGH);
    eq_forced = true;
  }
}
void EQ_announceEndIfAny()
{
  static bool wasActive = false;
  bool act = EQ_isActive();
  if (wasActive && !act)
    Serial.println("EQ,END");
  wasActive = act;
}

// =====================================================
// STATUS JSON
// =====================================================
uint32_t lastEmitMs = 0;
const uint32_t EMIT_MS = 2000;

void emitStatusJson()
{
  Serial.print('{');

  Serial.print("\"ts\":\"");
  Serial.print(millis());
  Serial.print("\",");

  Serial.print("\"semaforos\":{");
  for (int i = 0; i < 10; i++)
  {
    Serial.print('"');
    Serial.print('S');
    Serial.print(i + 1);
    Serial.print('"');
    Serial.print(':');
    Serial.print('"');
    Serial.print(stateForIndex(i));
    Serial.print('"');
    if (i < 9)
      Serial.print(',');
  }
  Serial.print("},");

  Serial.print("\"dist_cm\":{");
  for (int i = 0; i < 6; i++)
  {
    Serial.print('"');
    Serial.print('P');
    Serial.print(i + 1);
    Serial.print('"');
    Serial.print(':');
    int d = (int)round(lastCm[i]);
    Serial.print(d);
    if (i < 5)
      Serial.print(',');
  }
  Serial.print("},");

  // Leer valores analógicos para detectar humo real
  int analog1 = analogRead(PIN_AO);
  int analog2 = analogRead(PIN_A1);

  // Valores base normales (sin humo)
  int gas1 = 200; // Valor normal base
  int gas2 = 200; // Valor normal base

  // Solo reportar valores altos si realmente hay humo
  if (analog1 >= HUMO_UMBRAL)
  {
    gas1 = map(analog1, HUMO_UMBRAL, 1023, 280, 350);
  }
  if (analog2 >= HUMO_UMBRAL)
  {
    gas2 = map(analog2, HUMO_UMBRAL, 1023, 280, 350);
  }
  Serial.print("\"gas_ppm\":{\"Z1\":");
  Serial.print(gas1);
  Serial.print(",\"Z2\":");
  Serial.print(gas2);
  Serial.print("},");

  Serial.print("\"zumbador\":{\"Z1\":0,\"Z2\":0},");

  // --- sismo real desde EQ ---
  Serial.print("\"sismo\":{");
  Serial.print("\"activo\":");
  Serial.print(EQ_isActive() ? 1 : 0);
  Serial.print(',');
  Serial.print("\"magnitud\":");
  Serial.print(EQ_isActive() ? 5.0 : 0.0, 1);
  Serial.print(',');
  Serial.print("\"origen\":\"");
  Serial.print(EQ_isActive() ? "sensor" : "");
  Serial.print("\"");
  Serial.print("},");

  Serial.print("\"panic_buttons\":{");
  for (int i = 0; i < 4; i++)
  {
    Serial.print("\"PB");
    Serial.print(i + 1);
    Serial.print("\":");
    Serial.print("{\"activo\":");
    Serial.print(panicButtonsActiveState[i] ? 1 : 0);
    Serial.print(",\"ts\":\"");
    Serial.print(millis());
    Serial.print("\",\"id\":\"PB");
    Serial.print(i + 1);
    Serial.print("\"}");
    if (i < 3)
      Serial.print(',');
  }
  Serial.print("},");

  Serial.print("\"infracciones\":[");
  bool first = true;
  for (int sd = 0; sd < 5; sd++)
  {
    if (sdAlerted[sd])
    {
      uint8_t sIdx = (tuDir == TU_2_TO_1)   ? SD_TO_S_DIR21[sd]
                     : (tuDir == TU_1_TO_2) ? SD_TO_S_DIR12[sd]
                                            : SD_TO_S_DIR21[sd];
      if (!first)
        Serial.print(',');
      Serial.print('"');
      Serial.print('S');
      Serial.print(sIdx);
      Serial.print('"');
      first = false;
    }
  }
  Serial.print("],");

  // ETA data
  Serial.print("\"eta\":{");
  bool etaFirst = true;

  // ETA para Transmetro (P3, P4)
  if (stopETAArmed[TM1])
  {
    if (!etaFirst)
      Serial.print(',');
    Serial.print("\"P3\":\"M,ETA_S=30,FROM=Estacion1,TO=P3\"");
    etaFirst = false;
  }
  if (stopETAArmed[TM2])
  {
    if (!etaFirst)
      Serial.print(',');
    Serial.print("\"P4\":\"M,ETA_S=45,FROM=Estacion2,TO=P4\"");
    etaFirst = false;
  }

  // ETA para Transurbano (P1, P2)
  if (stopETAArmed[TU3])
  {
    if (!etaFirst)
      Serial.print(',');
    Serial.print("\"P1\":\"TU,ETA_S=60,FROM=Centro,TO=P1\"");
    etaFirst = false;
  }
  if (stopETAArmed[TU4])
  {
    if (!etaFirst)
      Serial.print(',');
    Serial.print("\"P2\":\"TU,ETA_S=90,FROM=Zona1,TO=P2\"");
    etaFirst = false;
  }

  Serial.print("},");

  Serial.print("\"_protocol_version\":\"1.1\"}");
  Serial.println();
}

// =====================================================
// Ultrasonido
// =====================================================
float readUltrasonicCm(uint8_t id)
{
  const UPin p = US_PINS[id];
  if (p.trig == UNUSED_PIN || p.echo == UNUSED_PIN)
    return 400.0f;
  pinMode(p.trig, OUTPUT);
  digitalWrite(p.trig, LOW);
  delayMicroseconds(2);
  digitalWrite(p.trig, HIGH);
  delayMicroseconds(10);
  digitalWrite(p.trig, LOW);
  pinMode(p.echo, INPUT);
  unsigned long dur = pulseIn(p.echo, HIGH, ECHO_TIMEOUT_US);
  if (dur == 0)
    return 400.0f;
  return dur / 58.0f;
}
inline float thrFor(uint8_t id)
{
  if (id == TM1 || id == TM2 || id == TU3 || id == TU4)
    return THR_STOP_CM;
  return 9999.0f;
}

// =====================================================
// Paradas (ARRIVE/LEAVE) + ETA + dirección TU
// =====================================================
const float TU_SPEED_CM_S = 10.0f;
const uint16_t TU_D12_CM = 105;
const float TM_SPEED_CM_S = 10.0f;
const uint16_t TM_D12_CM = 154;

static inline void publishETA_TU(uint8_t fromStop, uint8_t toStop)
{
  float t_s = (float)TU_D12_CM / max(1.0f, TU_SPEED_CM_S);
  Serial.print("TU,ETA_S,FROM=");
  Serial.print(fromStop);
  Serial.print(",TO=");
  Serial.print(toStop);
  Serial.print(",");
  Serial.println(t_s, 2);
}
static inline void publishETA_TM(uint8_t fromStop, uint8_t toStop)
{
  float t_s = (float)TM_D12_CM / max(1.0f, TM_SPEED_CM_S);
  Serial.print("TM,ETA_S,FROM=");
  Serial.print(fromStop);
  Serial.print(",TO=");
  Serial.print(toStop);
  Serial.print(",");
  Serial.println(t_s, 2);
}
static inline void TM_onArrive(uint8_t stopId)
{
  Serial.print("TM,ARRIVE,");
  Serial.println(stopId == TM1 ? 1 : 2);
}
static inline void TM_onLeave(uint8_t stopId)
{
  uint8_t from = (stopId == TM1) ? 1 : 2;
  uint8_t to = (stopId == TM1) ? 2 : 1;
  Serial.print("TM,LEAVE,");
  Serial.println(from);
  publishETA_TM(from, to);
}
static inline void TU_onArriveStop(uint8_t stopNum)
{
  Serial.print("TU,ARRIVE,");
  Serial.println(stopNum);
}
static inline void TU_onLeaveStop(uint8_t stopNum)
{
  uint8_t from = stopNum;
  uint8_t to = (stopNum == 1) ? 2 : 1;
  Serial.print("TU,LEAVE,");
  Serial.println(from);

  // Fija dirección para SD1/SD3
  tuDir = (from == 2) ? TU_2_TO_1 : TU_1_TO_2;

  publishETA_TU(from, to);
}

// ===== Depuración de paradas =====
#if DEBUG_STOPS
static uint32_t dbgStopTs[4] = {0, 0, 0, 0};
inline void debugStopDistances()
{
  uint32_t now = millis();
  if (now - dbgStopTs[0] > DEBUG_STOPS_MS)
  {
    Serial.print("TM1,CM=");
    Serial.println(lastCm[TM1], 1);
    dbgStopTs[0] = now;
  }
  if (now - dbgStopTs[1] > DEBUG_STOPS_MS)
  {
    Serial.print("TM2,CM=");
    Serial.println(lastCm[TM2], 1);
    dbgStopTs[1] = now;
  }
  if (now - dbgStopTs[2] > DEBUG_STOPS_MS)
  {
    Serial.print("TU3,CM=");
    Serial.println(lastCm[TU3], 1);
    dbgStopTs[2] = now;
  }
  if (now - dbgStopTs[3] > DEBUG_STOPS_MS)
  {
    Serial.print("TU4,CM=");
    Serial.println(lastCm[TU4], 1);
    dbgStopTs[3] = now;
  }
}
#else
inline void debugStopDistances() {}
#endif

// =====================================================
// Setup / Loop
// =====================================================
void setup()
{
  Serial.begin(115200);

  for (int i = 0; i < N_SENSORS; i++)
  {
    if (US_PINS[i].trig == UNUSED_PIN || US_PINS[i].echo == UNUSED_PIN)
      continue;
    pinMode(US_PINS[i].trig, OUTPUT);
    digitalWrite(US_PINS[i].trig, LOW);
    pinMode(US_PINS[i].echo, INPUT);
  }

  pinMode(A_R, OUTPUT);
  pinMode(A_Y, OUTPUT);
  pinMode(A_G, OUTPUT);
  pinMode(B_R, OUTPUT);
  pinMode(B_Y, OUTPUT);
  pinMode(B_G, OUTPUT);
  pinMode(A_R2, OUTPUT);
  pinMode(A_Y2, OUTPUT);
  pinMode(A_G2, OUTPUT);
  pinMode(B_R2, OUTPUT);
  pinMode(B_Y2, OUTPUT);
  pinMode(B_G2, OUTPUT);
  phaseSince = millis();
  applyLights();

  pinMode(BUZ_TU1_PIN, OUTPUT);
  digitalWrite(BUZ_TU1_PIN, LOW);
  pinMode(BUZ_TU2_PIN, OUTPUT);
  digitalWrite(BUZ_TU2_PIN, LOW);
  pinMode(BUZ3_PIN, OUTPUT);
  digitalWrite(BUZ3_PIN, LOW);
  pinMode(BUZ4_PIN, OUTPUT);
  digitalWrite(BUZ4_PIN, LOW);
  pinMode(BTN_BUZ1_PIN, INPUT_PULLUP);
  pinMode(BTN_BUZ2_PIN, INPUT_PULLUP);
  pinMode(BTN_BUZ3_PIN, INPUT_PULLUP);
  pinMode(BTN_BUZ4_PIN, INPUT_PULLUP);

  pinMode(PIN_AO, INPUT);
  pinMode(PIN_A1, INPUT);

  // <<< Sismo >>>
  EQ_init();
}

void loop()
{
  // ====== Sismo: liberar salidas cuando termine ======
  EQ_releaseOutputsIfEnded();

  // Leer comandos serial para alertas
  if (Serial.available())
  {
    String comando = Serial.readStringUntil('\n');
    comando.trim();
    Serial.println("Comando recibido: '" + comando + "'");  // Debug

    // Nuevo formato: ALERTA,<TIPO>,k1=v1,k2=v2,...
    if (comando.startsWith("ALERTA,"))
    {
      // Extraer tipo entre la primera y segunda coma (o toda la cola si no hay más)
      int firstComma = comando.indexOf(',');
      int secondComma = comando.indexOf(',', firstComma + 1);
      String tipo = (secondComma > 0) ? comando.substring(firstComma + 1, secondComma)
                                      : comando.substring(firstComma + 1);
      tipo.trim();

      if (tipo.equalsIgnoreCase("ARMA"))
      {
        alertaActual = ARMA;
        Serial.println("Alerta ARMA recibida");
      }
      else if (tipo.equalsIgnoreCase("ROSTRO"))
      {
        // Activar buzzer 2 por 2s
        uint32_t now = millis();
        digitalWrite(BUZ_TU2_PIN, HIGH);
        buz2Until = now + 2000;
        Serial.println("Alerta ROSTRO recibida (BUZ2)");
      }
      else if (tipo.equalsIgnoreCase("PLACA"))
      {
        // Activar buzzer 1 por 2s
        uint32_t now = millis();
        digitalWrite(BUZ_TU1_PIN, HIGH);
        buz1Until = now + 2000;
        Serial.println("Alerta PLACA recibida (BUZ1)");
      }
    }
    else if (comando == "ALERTA_ARMA")
    {
      // Compatibilidad hacia atrás
      alertaActual = ARMA;
      Serial.println("Activando sirena ARMA");  // Debug
    }
    else if (comando == "ALERTA_ROBO")
    {
      // Compatibilidad hacia atrás (no se usa con la API actual)
      alertaActual = ROBO;
      Serial.println("Activando sirena ROBO");  // Debug
    }
    if (alertaActual != NINGUNA)
    {
      sirenaActiva = true;
      sirenaHasta = millis() + 5000; // 5 segundos
      currentFreqs = (alertaActual == ARMA) ? armaFreqs : roboFreqs;
      currentChangeMs = (alertaActual == ARMA) ? ARMA_CHANGE_MS : ROBO_CHANGE_MS;
      sirenFreqIndex = 0;
      tone(BUZ3_PIN, currentFreqs[0]); // Usar pin 2 para sirena
      sirenLastChange = millis();
    }
  }

  // Botones y timers de zumbadores 1/2
  readButtonsAndTrigger();
  updateBuzzers();
  updateSirena();
  updateIncendio();

  // Desactivar botones de pánico después de 2 segundos
  uint32_t now = millis();
  for (int i = 0; i < 4; i++)
  {
    if (panicButtonsActiveState[i] && now >= panicButtonsUntil[i])
    {
      panicButtonsActiveState[i] = false;
    }
  }

  // —— Sensores de humo + timers en BUZ3/BUZ4, pero con prioridad de sismo ——
  bool incendio1 = (analogRead(PIN_AO) >= HUMO_UMBRAL);
  bool incendio2 = (analogRead(PIN_A1) >= HUMO_UMBRAL);

  // Detectar sismo (piezo)
  EQ_poll();

  if (EQ_isActive())
  {
    EQ_applyOutputs();
  }
  else
  {
    // Al terminar el sismo, esta rutina apaga los 4 una vez (usa eq_forced)
    EQ_releaseOutputsIfEnded();
    
    // Comportamiento de incendios con sonido especial
    if (incendio1 && !sirenaActiva && !incendioActivo)
    {
      // Activar sonido de incendio en pin 2
      incendioActivo = true;
      incendioHasta = millis() + 3000; // 3 segundos de alarma
      incendioLastChange = millis();
      incendioTonoAlto = true;
      tone(BUZ3_PIN, INCENDIO_FREQ_HIGH);
    }
    else if (!incendio1 && !sirenaActiva && !incendioActivo)
    {
      // Comportamiento normal para pin 2 si no hay incendio ni sirena
      digitalWrite(BUZ3_PIN, (millis() < buz3Until) ? HIGH : LOW);
    }
    
    // Pin 4 maneja incendio2 con sonido normal (sin tone)
    digitalWrite(BUZ4_PIN, (incendio2 || (millis() < buz4Until)) ? HIGH : LOW);
  }

  // Lecturas ultrasónicas + ARRIVE/LEAVE
  for (uint8_t id = 0; id < N_SENSORS; id++)
  {
    float cm = readUltrasonicCm(id);
    lastCm[id] = cm;

    float thr = thrFor(id);
    if (thr < 9000.0f)
    {
      bool below = (cm < thr);
      uint32_t now = millis();

      if (!wasBelow[id] && below)
      {
        wasBelow[id] = true;
        stableReported[id] = false;
        belowStartMs[id] = now;
      }

      if (wasBelow[id] && !stableReported[id] && (now - belowStartMs[id] >= STABLE_MS))
      {
        stableReported[id] = true;
        if (id == TM1 || id == TM2)
          TM_onArrive(id);
        else if (id == TU3)
          TU_onArriveStop(1);
        else if (id == TU4)
          TU_onArriveStop(2);
        stopETAArmed[id] = true;
      }

      if (wasBelow[id] && !below)
      {
        wasBelow[id] = false;
        stableReported[id] = false;

        if (id == TM1 || id == TM2)
          TM_onLeave(id);
        else if (id == TU3)
          TU_onLeaveStop(1);
        else if (id == TU4)
          TU_onLeaveStop(2);

        stopETAArmed[id] = false;
      }
    }
  }

  // Infracciones SD
  checkAllSD();

  // Semáforos
  updateTrafficLights();

  // JSON periódico (reporta sismo activo/origen/magnitud)
  if (millis() - lastEmitMs >= EMIT_MS)
  {
    emitStatusJson();
    lastEmitMs = millis();
  }

  // Avisar fin de sismo si terminó
  EQ_announceEndIfAny();

  // Depuración opcional
  debugStopDistances();

  delay(60);
}
