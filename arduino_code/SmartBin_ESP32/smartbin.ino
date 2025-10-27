/*
  Corrected and Improved Smart Trash Can Code for ESP32
*/

#include <ESP32Servo.h>

// --- Pin Definitions ---
const int trigPin = 26;
const int echoPin = 25;
const int servoPin = 14;

// --- Configuration Settings ---
// *** IMPORTANT: Change the openAngle to make the lid open! ***
const int openAngle = 100; // The angle when the lid is open (e.g., 90 degrees)
const int closeAngle = 0;   // The angle when the lid is closed

// Distance in cm to trigger the lid opening
const int distanceThreshold = 20;

// --- Global Variables ---
Servo lidServo; // Create a servo object

// Variables for distance calculation
long duration;
float distance;
float averageDistance;
float distanceReadings[3]; // An array to store the last 3 readings

// Function Prototypes (telling the compiler that these functions exist)
float readDistance();

void setup() {
  Serial.begin(9600);
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);

  // Attach the servo ONCE in setup for stability
  lidServo.attach(servoPin);
  
  // Start with the lid closed
  lidServo.write(closeAngle);
  delay(500); // Give the servo a moment to get to the initial position
  Serial.println("Smart Bin Ready.");
}

void loop() {
  // Measure the distance three times to get a stable reading
  for (int i = 0; i < 3; i++) {
    distanceReadings[i] = readDistance();
    delay(20); // Small delay between readings
  }

  // Calculate the average distance
  averageDistance = (distanceReadings[0] + distanceReadings[1] + distanceReadings[2]) / 3;

  // Print the average distance for debugging
  Serial.print("Average Distance: ");
  Serial.print(averageDistance);
  Serial.println(" cm");

  // Control the servo based on the averaged distance
  if (averageDistance <= distanceThreshold && averageDistance > 0) {
    Serial.println("Object Detected! Opening Lid.");
    lidServo.write(openAngle); // Rotate the servo to the open position
    delay(3000); // Keep the lid open for 3 seconds
  } else {
    lidServo.write(closeAngle); // Keep the servo in the closed position
  }

  delay(100); // A short delay in the main loop
}


// --- Functions ---

/*
 * readDistance()
 * Triggers the ultrasonic sensor and returns the measured distance in cm.
 */
float readDistance() {
  // Send a 10-microsecond pulse to trigger the sensor
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  // Measure the time it takes for the echo pulse to return
  duration = pulseIn(echoPin, HIGH);

  // Calculate the distance in centimeters.
  // The formula is (duration * speed_of_sound) / 2
  // 0.0343 cm/µs is the speed of sound.
  distance = duration * 0.0343 / 2;

  return distance;
}
