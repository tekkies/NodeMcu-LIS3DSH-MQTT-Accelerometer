BATTERY_CALIBRATION = 0.02951871658
MQTT_BROKER = "test.mosquitto.org"
MQTT_CLIENTID = "uk.co.tekkies." .. node.chipid()
MQTT_TOPIC = "/tekkies.co.uk/LIS3DSH/" .. node.chipid() .. "-" .. node.flashid()
SLEEP_SECONDS = 10
USE_LED = false
