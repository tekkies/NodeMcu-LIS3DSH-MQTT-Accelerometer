BATTERY_CALIBRATION = 0.02951871658
MQTT_BROKER = "test.mosquitto.org"
MQTT_CLIENTID = "uk.co.tekkies." .. node.chipid()
MQTT_TOPIC = "/tekkies.co.uk/LIS3DSH/" .. node.chipid() .. "-" .. node.flashid()
USE_LED = false
SLEEP_SECONDS = 5*60 --0 = continuous read
WAKE_SENSITIVITY = 64 --0-127
ENABLE_PRINT = true
