# NodeMcu-LIS3DSH-MQTT-Accelerometer

Periodically polls LIS3DSH accelerometer ove SPI and pubishes to MQTT Broker

* Deep sleep between samples
* Battery level sensor
* Written in LUA
* Event-based so kind to WiFi processes
* Runs only once when battery disconnected (i.e. when debugging on USB)
* LED Flash codes for PANIC situations

![MQTT Explorer Chart](doc/MQTT-Explorer-Chart.png)


## ToDo
- [ ] Sleep the LIS3DSH

## Design

### Circuit
![Circuit Diagram](src/Circuit-Diagram-TinyCAD.png)

### Layout

![Stripboard Layout](src/Stripboard-Layout.VeeCAD.png)

Connect 4x AA batteries to J1, + to the top, - to the bottom.


