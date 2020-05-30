from gpiozero import DistanceSensor, Buzzer
from time import sleep

MIN_DISTANCE = 0.1
MAX_DISTANCE = 0.6

MIN_BEEP_DELAY = 0.01
MAX_BEEP_DELAY = 0.5
BEEP_DURATION = 0.001

TRIGGER = 14
ECHO = 15
SPEAKER = 22

ultrasonic = DistanceSensor(ECHO, TRIGGER)
speaker = Buzzer(SPEAKER)

speaker.off()

def calc_beep_delay(distance):
	rate = (MAX_BEEP_DELAY - MIN_BEEP_DELAY) / (MAX_DISTANCE - MIN_DISTANCE)
	rate = (rate * (distance - MIN_DISTANCE)) + MIN_BEEP_DELAY
	return rate

def speaker_beep(rate):
	speaker.on()
	sleep(BEEP_DURATION)
	speaker.off()
	sleep(rate)

while True:
	distance = ultrasonic.distance
	print "Distance:", distance, "m"

	if distance < MAX_DISTANCE:
		speaker_beep(calc_beep_delay(distance))

	sleep(0.01)
