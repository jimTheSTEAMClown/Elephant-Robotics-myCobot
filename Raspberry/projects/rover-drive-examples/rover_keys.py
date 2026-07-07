# rover_keys.py
# Simple rover entry point.
#
# Imports pin assignments from the hal/ package and uses them
# to set up gpiozero devices. All pin numbers come from
# hal/pin_config.py — none are hardcoded here.
# All Pins are "BCM"
#
# Run:  python3 rover_keys.py
#
# Requirements:
# Standard Default - No Specific Requirements yet

# Imports:
import curses
import time
from gpiozero import Device, LED, PWMOutputDevice, DigitalOutputDevice
from gpiozero import DistanceSensor

# ── Import pin numbers from the HAL package ───────────────────
# This is the only place pin numbers enter the program.
# If you rewire the robot, edit hal/pin_config.py — not this file.
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

# ── Set up hardware devices using BCM pins from pin_config.py in /hal ───────────
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
    set_motors(0.0, 0.0)

def drive_left() -> None:
    """Stop both motors."""
    set_motors((left_speed), -(right_speed))

def drive_right() -> None:
    """Stop both motors."""
    set_motors(-(left_speed), (right_speed))

def drive_forward() -> None:
    """Stop both motors."""
    set_motors((left_speed), (right_speed))

def drive_backward() -> None:
    """Stop both motors."""
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


def main(stdscr):
    # Clear screen
    stdscr.clear()
    stdscr.addstr(2, 0, "Welcome... Ready to drive?")
    # Startup blink — 3 flashes to show the program is alive
    for _ in range(3):
        led.on();  time.sleep(0.2)
        led.off(); time.sleep(0.2)
    
    # Clear screen
    stdscr.clear()
    stdscr.nodelay(True)  # Don't block for input
    curses.curs_set(0)  # Hide cursor

    stdscr.addstr(0, 0, "Control the rover: Arrow keys (FWD, LEFT, RIGHT), 'r' (reverse), Space (stop), 'q' (quit)")

    while True:
        key = stdscr.getch()

        if key == curses.KEY_UP:
            stdscr.addstr(2, 0, "Moving forward  ")
            drive_forward()
        elif key == curses.KEY_DOWN:
            stdscr.addstr(2, 0, "Moving backward ")
            drive_backward()
        elif key == curses.KEY_LEFT:
            stdscr.addstr(2, 0, "Turning left   ")
            drive_left()
        elif key == curses.KEY_RIGHT:
            stdscr.addstr(2, 0, "Turning right  ")
            drive_right()
        elif key == ord(' '):
            stdscr.addstr(2, 0, "Stopped         ")
            drive_stop()
        elif key == ord('q'):
            break  # Quit the loop

        stdscr.refresh()
        time.sleep(0.1)
    cleanup()
    stdscr.addstr(2, 0, "Pins are released, Bye  ")

curses.wrapper(main)
