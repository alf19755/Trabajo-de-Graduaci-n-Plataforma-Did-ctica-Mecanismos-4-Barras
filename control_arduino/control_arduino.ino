#include <Wire.h>
#include <AS5600.h>
#include <TimerOne.h>


// -------------------------
// CONFIGURACIÓN GENERAL
// -------------------------
#define SERIAL Serial
#define TCAADDR 0x70        // Dirección del multiplexor TCA9548A
#define NUM_SENSORES 5      // Canales: 0=X, 1=Y, 2=Z, 3 (CORREDERA), 4 (4b)
#define EN_PIN 8

// Pines motores (CNC Shield típico)
#define STEP_X 2
#define DIR_X 5
#define STEP_Y 3
#define DIR_Y 6
#define STEP_Z 4
#define DIR_Z 7

const float pasoGrados = 1.8;  // grados por paso (full-step)
int modo = 0;  // 0 = automático (por ángulo), 1 = libre


// Calibración
float relacionMotorSensor[NUM_SENSORES] = {1.0, 1.0, 1.0};
float offsetSensor[NUM_SENSORES] = {0.0, 0.0, 0.0};
bool invertirDir[NUM_SENSORES] = {true, false, true};  // solo Z invertido

const float tolerancia = 0.5;
const float umbral_giro = 0.5;

AMS_5600 ams5600;
float angulos[NUM_SENSORES];
float objetivo[NUM_SENSORES];

bool banderaError[NUM_SENSORES] = {false, false, false};  // Nueva bandera global


// -------------------------
// CONFIGURACIÓN SENSOR DE CORRIENTE
// -------------------------
const int pinACS = A15;        // OUT del ACS712
const float VREF = 5.0;        // Voltaje de referencia del Arduino
const float sensibilidad = 185.0;  // mV/A (ACS712-05B)
const int numMuestras = 50;    // Promedio para reducir ruido

// -------------------------
// FUNCIONES
// -------------------------
void muestrearCorriente() {
  float lecturaProm = 0;
  const int numMuestrasTimer = 10; // menos para que sea rápido
  for (int i = 0; i < numMuestrasTimer; i++) {
    lecturaProm += analogRead(pinACS);
  }
  lecturaProm /= numMuestrasTimer;

  float voltajeSensor = (lecturaProm * VREF) / 1023.0;
  float corriente = (voltajeSensor - (VREF / 2.0)) / (sensibilidad / 1000.0);

  SERIAL.print("I:");
  SERIAL.println(corriente, 3);
}



void tcaselect(uint8_t channel) {
  if (channel > 7) return;
  Wire.beginTransmission(TCAADDR);
  Wire.write(1 << channel);
  Wire.endTransmission();
}

float convertRawAngleToDegrees(word newAngle) {
  return newAngle * 0.087890625;  // 360 / 4096
}

float leerAngulo(uint8_t canal) {
  tcaselect(canal);
  delay(3);
  word raw = ams5600.getRawAngle();
  float grados = convertRawAngleToDegrees(raw);
  if (canal == 1) grados = 360.0 - grados;
  grados -= offsetSensor[canal];
  while (grados < 0) grados += 360.0;
  while (grados >= 360.0) grados -= 360.0;
  return grados;
}

void moverLibre(uint8_t canal, bool sentido, int velocidad) {
  int dirPin, stepPin;
  switch (canal) {
    case 0: dirPin = DIR_X; stepPin = STEP_X; break;
    case 1: dirPin = DIR_Y; stepPin = STEP_Y; break;
    case 2: dirPin = DIR_Z; stepPin = STEP_Z; break;
    default: return;
  }

  if (invertirDir[canal]) sentido = !sentido;
  digitalWrite(dirPin, sentido ? HIGH : LOW);

  // Gira continuamente mientras haya modo libre activo
  digitalWrite(EN_PIN, LOW);
  for (int i = 0; i < 200; i++) {   // 200 pasos por ciclo
    digitalWrite(stepPin, HIGH);
    delayMicroseconds(velocidad);
    digitalWrite(stepPin, LOW);
    delayMicroseconds(velocidad);
  }
}


void moverMotorA(uint8_t canal, float destino, int velocidad) {
  int dirPin, stepPin;
  switch (canal) {
    case 0: dirPin = DIR_X; stepPin = STEP_X; break;
    case 1: dirPin = DIR_Y; stepPin = STEP_Y; break;
    case 2: dirPin = DIR_Z; stepPin = STEP_Z; break;
    default: return;
  }

  const int BURST = 10;
  const unsigned long timeout = 6000;  // 6 segundos máx
  const int maxVueltas = 15;

  banderaError[canal] = false;
  destino = fmod(destino + 360.0, 360.0);
  unsigned long tInicio = millis();
  int vueltas = 0;
  float errorPrev = 9999;

  digitalWrite(EN_PIN, LOW);  //  Asegura que el driver esté activo

  while (true) {
    float actual = leerAngulo(canal);
    float error = fmod((destino - actual + 540.0), 360.0) - 180.0;

    if (fabs(error) <= tolerancia) {
      SERIAL.print("Canal "); SERIAL.print(canal);
      SERIAL.print(" llegó a "); SERIAL.print(actual, 1);
      SERIAL.println("°");
      break;
    }

    // ---- Protección ----
    if (millis() - tInicio > timeout) {
      banderaError[canal] = true;
      SERIAL.print(" Timeout en canal "); SERIAL.println(canal);
      break;
    }

    if (fabs(error - errorPrev) < 0.05) vueltas++;
    else vueltas = 0;
    errorPrev = error;
    if (vueltas > maxVueltas) {
      banderaError[canal] = true;
      SERIAL.print("Giro excesivo en canal "); SERIAL.println(canal);
      break;
    }

    // ---- Movimiento ----
    bool sentido = (error > 0);
    if (invertirDir[canal]) sentido = !sentido;
    digitalWrite(dirPin, sentido ? HIGH : LOW);

    int pasos = abs(error) / pasoGrados;
    if (pasos > BURST) pasos = BURST;

    for (int i = 0; i < pasos; i++) {
      digitalWrite(stepPin, HIGH);
      delayMicroseconds(velocidad);
      digitalWrite(stepPin, LOW);
      delayMicroseconds(velocidad);
    }
  }

  // --- Al terminar, no dejar deshabilitado el driver ---
  if (banderaError[canal]) {
    SERIAL.println(" Motor detenido por seguridad (bandera activada)");
  }

  digitalWrite(EN_PIN, LOW);  //  Rehabilita siempre al final
}
// -------------------------
// SETUP
// -------------------------
void setup() {

  //timer

  // --- Configurar Timer1 para leer corriente cada 100 ms ---
Timer1.initialize(100000);       // 100000 microsegundos = 100 ms
Timer1.attachInterrupt(muestrearCorriente);



  SERIAL.begin(115200);
  Wire.begin();

  pinMode(EN_PIN, OUTPUT);
  digitalWrite(EN_PIN, LOW);

  pinMode(DIR_X, OUTPUT); pinMode(STEP_X, OUTPUT);
  pinMode(DIR_Y, OUTPUT); pinMode(STEP_Y, OUTPUT);
  pinMode(DIR_Z, OUTPUT); pinMode(STEP_Z, OUTPUT);

  SERIAL.println(">>> Sistema AS5600 + TCA9548A + Motores + ACS712 <<<");
  for (uint8_t i = 0; i < NUM_SENSORES; i++) {
    tcaselect(i);
    delay(10);
    if (ams5600.detectMagnet()) {
      SERIAL.print("Canal "); SERIAL.print(i);
      SERIAL.print(": Magneto detectado. Magnitud = ");
      SERIAL.println(ams5600.getMagnitude());
    } else {
      SERIAL.print("Canal "); SERIAL.print(i);
      SERIAL.println(": No se detecta imán");
    }
    angulos[i] = leerAngulo(i);
    objetivo[i] = angulos[i];
  }
  SERIAL.println("-------------------------------------------");
  SERIAL.println("Comandos: X 90 3000 (eje X a 90° con velocidad 3000us)");
}

// -------------------------
// LOOP PRINCIPAL
// -------------------------
void loop() {
  if (SERIAL.available() > 0) {
  String entrada = SERIAL.readStringUntil('\n');
  entrada.trim();
  if (entrada.length() == 0) return;

  // --- Cambiar modo ---
  if (entrada.startsWith("MODE")) {
    entrada.remove(0, 4);
    entrada.trim();
    if (entrada.equalsIgnoreCase("AUTO")) {
      modo = 0;
      SERIAL.println("Modo AUTOMÁTICO activado (movimiento por ángulo)");
    } else if (entrada.equalsIgnoreCase("FREE")) {
      modo = 1;
      SERIAL.println("Modo LIBRE activado (movimiento continuo)");
    } else {
      SERIAL.println("Modo inválido. Usa: MODE AUTO o MODE FREE");
    }
    return;
  }

  // --- Movimiento automático ---
  if (modo == 0) {
    char eje = toupper(entrada.charAt(0));
    int p1 = entrada.indexOf(' ');
    int p2 = entrada.indexOf(' ', p1 + 1);
    float grados = entrada.substring(p1 + 1, p2).toFloat();
    int velocidad = entrada.substring(p2 + 1).toInt();

    uint8_t canal;
    switch (eje) {
      case 'X': canal = 0; break;
      case 'Y': canal = 1; break;
      case 'Z': canal = 2; break;
      default:
        SERIAL.println("Eje inválido (usa X, Y o Z).");
        return;
    }

    objetivo[canal] = grados;
    SERIAL.print("Moviendo eje "); SERIAL.print(eje);
    SERIAL.print(" hacia "); SERIAL.print(grados);
    SERIAL.println("°...");
    moverMotorA(canal, grados, velocidad);
  }

  // --- Movimiento libre ---
  else if (modo == 1) {
    // Ejemplo: MOVE X F 3000
    if (!entrada.startsWith("MOVE")) {
      SERIAL.println("Usa: MOVE <EJE> <F/R> <velocidad>");
      return;
    }
    entrada.remove(0, 4);
    entrada.trim();
    char eje = toupper(entrada.charAt(0));
    int p1 = entrada.indexOf(' ');
    char sentidoChar = toupper(entrada.charAt(p1 + 1));
    int p2 = entrada.indexOf(' ', p1 + 2);
    int velocidad = entrada.substring(p2 + 1).toInt();

    uint8_t canal;
    switch (eje) {
      case 'X': canal = 0; break;
      case 'Y': canal = 1; break;
      case 'Z': canal = 2; break;
      default:
        SERIAL.println("Eje inválido (usa X, Y o Z).");
        return;
    }

    bool sentido = (sentidoChar == 'F');
    SERIAL.print("Girando eje "); SERIAL.print(eje);
    SERIAL.print(sentido ? " adelante" : " atrás");
    SERIAL.print(" con velocidad "); SERIAL.println(velocidad);
    moverLibre(canal, sentido, velocidad);
  }
}


  // --- Lectura de ángulos ---
  SERIAL.print("Angulos: ");
  for (uint8_t i = 0; i < NUM_SENSORES; i++) {
    angulos[i] = leerAngulo(i);
    SERIAL.print(angulos[i], 1);
    SERIAL.print(i < NUM_SENSORES - 1 ? "," : " | ");
  }
delay(150);  // o 200 ms, similar a la frecuencia del timer

 
}