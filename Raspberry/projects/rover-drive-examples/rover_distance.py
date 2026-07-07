# rover_distance.py
# Simple rover with distance sensor.
#
# Imports pin assignments from the hal/ package and uses them
# to set up gpiozero devices. All pin numbers come from
# hal/pin_config.py â none are hardcoded here.
# All Pins are "BCM"
#
# Run:  python3 rover_distance.py
#
# Requirements:
# Standard Default - No Specific Requirements yet

# Imports:
import curses
import time
from gpiozero import Device, LED, PWMOutputDevice, DigitalOutputDevice
from gpiozero import DistanceSensor

# ââ Import pin numbers from the HAL package âââââââââââââââââââ
# This is the only place pin numbers enter the program.
# If you rewire the robot, edit hal/pin_config.py â not this file.
from hal.pin_config import (
    STATUS_LED,
    MOTOR_LEFT_ENA,
    MOTOR_LEFT_IN1,
    MOTOR_LEFT_IN2,
    MOTOR_RIGHT_ENB,
    MOTOR_RIGHT_IN3,
    MOTOR_RIGHT_IN4,
    ULTRASONIC_TRIG,
    ULTRASONIC_ECHO,
)

# ââ Set up hardware devices using BCM pins from pin_config.py in /hal âââââââââââ
led    = LED(STATUS_LED)

left_ena  = PWMOutputDevice(MOTOR_LEFT_ENA,  initial_value=0)
left_in1  = DigitalOutputDevice(MOTOR_LEFT_IN1,  initial_value=False)
left_in2  = DigitalOutputDevice(MOTOR_LEFT_IN2,  initial_value=False)

right_enb = PWMOutputDevice(MOTOR_RIGHT_ENB, initial_value=0)
right_in3 = DigitalOutputDevice(MOTOR_RIGHT_IN3, initial_value=False)
right_in4 = DigitalOutputDevice(MOTOR_RIGHT_IN4, initial_value=False)

sensor = DistanceSensor(echo=ULTRASONIC_ECHO, trigger=ULTRASONIC_TRIG)
right_speed = 0.5
left_speed = 0.5

def get_distance(sensor):
    return sensor.distance 

def set_motors(left: float, right: float) -> None:
    """
    Drive both motors.
    left / right: -1.0 (full reverse) to +1.0 (full forward), 0.0 = stop.
    """
    # Left motor
    left_in1.value = left > 0
    left_in2.value = left < 0
    left_ena.value = abs(left)

    # Right motor
    right_in3.value = right > 0
    right_in4.value = right < 0
    right_enb.value = abs(right)

def drive_stop() -> None:
    """Stop both motors."""
    print("stop")
    set_motors(0.0, 0.0)

def drive_left() -> None:
    """drive left."""
    set_motors((left_speed), -(right_speed))

def drive_right() -> None:
    """drive right."""
    set_motors(-(left_speed), (right_speed))

def drive_forward() -> None:
    """drive forwards."""
    print("driving forward")
    set_motors((left_speed), (right_speed))

def drive_backward() -> None:
    """drive backwards."""
    set_motors(-(left_speed), -(right_speed))

def cleanup() -> None:
    """Release all GPIO resources."""
    drive_stop()
    for device in (
        left_ena, left_in1, left_in2,
        right_enb, right_in3, right_in4,
        led, sensor,
    ):
        device.close()


def main():

    while True:
        object_distance = sensor.distance
        print('distance to nearest object is ',object_distance, 'm')
        if object_distance <= 0.98 :
            drive_stop()
            drive_left()
            time.sleep(0.5)
            drive_stop()
        else:
            drive_forward() 
        #time.sleep(0.1)
    cleanup()
    

main()
