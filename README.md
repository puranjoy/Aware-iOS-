# Aware

A spatial awareness system for the visually impaired

## AwareApp

An app that takes in user's audio request (commands) and responds to the user's queries. Users can ask what's around them and the app will run object detection algorithm designed using coreML and Vision library, and reads out the object's name.

This app was built using xCode, Swift, coreML, Vision and Speech library for IOS devices.

## SpatialSense

SpatialSense is a companion device to the AwareApp. It consists of a Raspberry Pi Zero W with a peripheral shield. The Pi is connected to an HC-SR04 ultrasonic sensor and a BUZ1 buzzer module.

The purpose of this device is to provide a the visually impaired with a sense of depth in relation to their surroundings. The Pi continuously polls the ultrasonic sensor to determine if the user is close to an obstacle. If they are, the buzzer will produce a beeping noise to alert the individual of the object.

The device is operted using a simple Python script that uses the GPIOzero library.

## Acknowledgments

- Models used from: https://developer.apple.com/machine-learning/models/
