# NodeMcu-LIS3DSH-MQTT-Accelerometer

Periodically polls LIS3DSH accelerometer ove SPI and pubishes to MQTT Broker

* **Currently only Y and Z Axis** (My X-axis sensor is not working - replacement LIS3DSH on order)
* Deep sleep between timed samples
* Wake on motion by interrupt
* Battery level sensor
* Written in LUA
* Event-based so kind to WiFi processes
* Runs only once when battery disconnected (i.e. when debugging on USB)
* LED Flash codes for PANIC situations (See [src/constants.lua](src/constants.lua))

![MQTT Explorer Chart](doc/MQTT-Explorer-Chart.png)


## ToDo
- [_] Fix the memory leak when running with 0 sleep (workaround: sleep for 1 second)
- [_] Light sensor on LIS3DH ADC

![Stripboard Layout (v1.0)](doc/Assembled-Board.jpg)

## OEM NodeMCU v2.0 

### Circuit
![Circuit Diagram](hardware/OEM-NodeMCU-V2.0/Circuit-Diagram-TinyCAD.png)

### Stripboard Design

![Stripboard Layout](hardware/OEM-NodeMCU-V2.0/Stripboard-Layout.VeeCAD.png)

Connect **4x AA** batteries to J1, + to the top, - to the bottom.


