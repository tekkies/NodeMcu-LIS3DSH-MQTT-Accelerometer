# NodeMcu-LIS3DSH-MQTT-Accelerometer

Periodically polls LIS3DSH accelerometer ove SPI and pubishes to MQTT Broker

* **Currently only Y and Z Axis** (My X-axis sensor is not working - replacement LIS3DSH on order)
* **Deep sleep** between timed samples
* **Wake** on motion by **interrupt**
* Battery level sensor
* Written in LUA
* Event-based so **kind to WiFi processes**
* Runs only once when battery disconnected (i.e. when debugging on USB)
* LED Flash codes for PANIC situations (See [src/constants.lua](src/constants.lua))

![MQTT Explorer Chart](doc/MQTT-Explorer-Chart.png)


## ToDo
- [ ] ESP-12E version with 30μA deep-sleep current
- [ ] Fix the memory leak when running with 0 sleep (workaround: sleep for 1 second)
- [ ] Light sensor on LIS3DH ADC

![Stripboard Layout (v1.0)](doc/Assembled-Board.jpg)

## NodeMCU v2

### Circuit
![Circuit Diagram](hardware/NodeMCU-V2/Circuit-Diagram-TinyCAD.png)

### Stripboard Design

![Stripboard Layout](hardware/NodeMCU-V2/Stripboard-Layout.VeeCAD.png)

Connect **4x AA** batteries to J1, + to the top, - to the bottom.

## Tips

## First Time NodeMCU?

See my [Getting Started](https://gist.github.com/tekkies/1f49c744080a6ece0effd3dc23099825) guide

### Firmware

You will need appropriate firmware installed on the NodeMCU. See comments at the top of [lis3dsh.lua](src/lis3dsh.lua) for a download link.

### WiFi Connection

See [Setting up Wifi (DHCP)](https://gist.github.com/tekkies/1f49c744080a6ece0effd3dc23099825#setting-up-wifi-dhcp)