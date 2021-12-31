--Docs: https://docs.google.com/document/d/1TGW-6SSDxvgoyW24C-6WJ7nk-D5wxFYsAy0LuFRidyY
--Circuit: https://crcit.net/c/bc4837dfeb004d6ab27e804357bb4d59
--Firmware: https://drive.google.com/file/d/1bj2EzizW73LsHUNW7XQAOsKIsnVfJMvn/view?usp=sharing
-- 2021-12-28 adc, bit, file, gpio, mqtt, net, node, rtctime, spi, tmr, uart, wifi, tls

--Config
MQTT_BROKER = "test.mosquitto.org"
MQTT_CLIENTID = "uk.co.tekkies." .. node.chipid()
MQTT_TOPIC = "/tekkies.co.uk/LIS3DSH/" .. node.chipid() .. "-" .. node.flashid()
SLEEP_SECONDS = 1
USE_LED = false


--State
state = nil
accel = 0
batt = 0.0

--Constants

PANIC_NO_LIS3DH = 4
PANIC_NO_WIFI = 5

ACC_REG_OUT_T = 0x0c
ACC_REG_CTRL_REG4 = 0x20
ACC_REG_CTRL_REG5 = 0x24
ACC_REG_STATUS = 0x27
    ACC_REG_STATUS_YDA =  1
ACC_REG_OUT_X_L = 0x28
ACC_REG_OUT_X_H = 0x29
ACC_REG_OUT_Y_L = 0x2A
ACC_REG_OUT_Y_H = 0x2B
ACC_REG_OUT_Z_L = 0x2C
ACC_REG_OUT_Z_H = 0x2D


function readAcc(address)
    spi.transaction(1, 0, 0, 8, 0x80 + address, 0,0,8)
    return spi.get_miso(1,0,8,1)
end

function writeAcc(address, value)
    spi.set_mosi(1, 0, 8, value)
    spi.transaction(1, 0, 0, 8, address, 8,0,0)
end

function costlyGetStateName()
    for key,value in pairs(_G) do
        if(state == value and key ~= "state") then
            return key
        end
    end
end

function twosToSigned(twos)
    if(twos > 0x7fff) then
        return twos - 0x10000
    else
        return twos
    end    
end

function print2(message)
    print("    "..message)
end

function uptimeSeconds()
    return tmr.now()/1000000
end

epochStartTime = tmr.now()
function epochSeconds()
    return (tmr.now() - epochStartTime)/1000000
end

function setLed(ledState)
    if(ledState) then
        gpio.write(4, gpio.LOW)
        gpio.mode(4, gpio.OUTPUT)
    else
        gpio.write(4, gpio.HIGH)
        gpio.mode(4, gpio.INPUT)
    end
end

panicCounter = 0
panicReason = 0
function panic(newPanicReason)
    panicReason = newPanicReason
    panicCallback()
end

function panicCallback()
    print("PANIC " .. panicReason .. " !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    if (((panicCounter % 2) == 0) and (panicCounter < panicReason * 2)) then
        setLed(true)
    else
        setLed(false)
    end
    panicCounter = panicCounter + 1
    if(panicCounter > 20) then
        panicCounter = 0
    end
    tmr.create():alarm(300, tmr.ALARM_SINGLE, panicCallback)
end

function readBatt()
    batt = adc.read(0) * 0.009645
    return batt
end


function isOnBatteryPower()
    return batt > 3.0;
end

function queueState(newState)
    state = newState
    queueNextState()
end

function queueNextState()
    print(costlyGetStateName())
    node.task.post(state)
end

function init()
    epochStartTime = tmr.now()
    if(USE_LED) then
        setLed(true)
    end
    tmr.create():alarm(60 * 1000, tmr.ALARM_SINGLE, sleepNow)
    queueState(initAdc)
end

function initAdc()
    if adc.force_init_mode(adc.INIT_ADC)
    then
      node.restart()
      return -- don't bother continuing, the restart is scheduled
    end
    readBatt()
    queueState(initAccel)
end

function initAccel()
    spi.setup(1, spi.MASTER, spi.CPOL_HIGH, spi.CPHA_HIGH, 8, 255)
    --Check Accelerometer is present
    whoAmI = readAcc(0x0f)
    print2("Who_AM_I register (expect 3f): " .. string.format("%x", whoAmI))
    if (whoAmI ~= 0x3f) then
        panic(PANIC_NO_LIS3DH)
        return
    end
    --Enable Y accelerometer
    writeAcc(ACC_REG_CTRL_REG4, 0x1a) --0x10+0x08+0x02
    --print2("ACC_REG_CTRL_REG4 " .. string.format("%x", readAcc(ACC_REG_CTRL_REG4)))
    queueState(getAccel)
end

function getAccel()
    readBatt()
    if(bit.isset(readAcc(ACC_REG_STATUS), ACC_REG_STATUS_YDA)) then
        accel = twosToSigned((readAcc(ACC_REG_OUT_Y_H) * 256)+readAcc(ACC_REG_OUT_Y_L))/16350.0
        print2(string.format("%x", accel))
        state=waitForWiFi        
    end
    queueNextState()
end

function waitForWiFi()
    if(epochSeconds() > 20) then
        panic(PANIC_NO_WIFI)
        return
    end
    if(wifi.sta.status() == wifi.STA_GOTIP) then
        state=postMqtt     
    end
    queueNextState()
end


function postMqtt()
    mqttClient:connect(MQTT_BROKER, 1883, false, function(client)
      print2("connected")
      topicValue = '{"batt":"'.. string.format("%.2f", batt) .. '","accel":"' .. string.format("%.2f", accel) .. '","heap":"' .. node.heap() .. '","uptime":"' .. uptimeSeconds() .. '"}'
      print2(topicValue)
      client:publish(MQTT_TOPIC, topicValue, 0, 0, function(client) 
        print2("sent")
        mqttClient:close()
      end)
    end,
    function(client, reason)
      print2("Connection failed reason: " .. reason)
      queueState(sleepNow)
    end)
end

function mqttOffline(client)
    queueState(sleepNow)
end

function sleepNow()
    setLed(false)
    --Sleep Accelerometer
    writeAcc(ACC_REG_CTRL_REG4, 0x00)
    if(isOnBatteryPower()) then
        if(SLEEP_SECONDS==0) then
            queueState(init)
        else
            print2("Battery detected, going to sleep...")
            local us = SLEEP_SECONDS*1000*1000
            node.dsleep(us, 1, nil)
        end
    else
        print2("No battery detected, do not sleep")
    end
end

----------------------------------------
mqttClient = mqtt.Client(MQTT_CLIENTID, 120)
mqttClient:on("offline", mqttOffline)
queueState(init)
