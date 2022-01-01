--https://github.com/tekkies/NodeMcu-LIS3DSH-MQTT-Accelerometer
--Firmware: https://drive.google.com/file/d/1bj2EzizW73LsHUNW7XQAOsKIsnVfJMvn/view?usp=sharing
  --adc, bit, file, gpio, mqtt, net, node, rtctime, spi, tmr, uart, wifi, tls, float

dofile("config.lua");
dofile("constants.lua");

--State
state = nil
epochStartTime = tmr.now()
panicCounter = 0
panicReason = 0
jsonData = '{'

function readLis3dsh(address)
    spi.transaction(1, 0, 0, 8, 0x80 + address, 0,0,8)
    return spi.get_miso(1,0,8,1)
end

function writeLis3dsh(address, value)
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

function print1(message)
	if(ENABLE_PRINT) then
		print(message)
	end
end

function print2(message)
    print1("    "..message)
end

function uptimeSeconds()
    return tmr.now()/1000000
end

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

function panic(newPanicReason)
    panicReason = newPanicReason
    panicCallback()
end

function panicCallback()
    print1("PANIC " .. panicReason .. " !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
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

function getBatteryVolts()
    local rawBattery = adc.read(0)
    print2("Battery raw=" .. rawBattery)
    return rawBattery * BATTERY_CALIBRATION
end

function appendJsonValue(key, value)
    --jsonData = jsonData .. "a"
    if(#jsonData ~= 1) then
        jsonData = jsonData .. ','
    end
    jsonData = jsonData .. '"'  .. key .. '":"' .. value .. '"' 
end


function isOnBatteryPower()
    return getBatteryVolts() > 1.0;
end

function queueState(newState)
    state = newState
    queueNextState()
end

function queueNextState()
    print1(costlyGetStateName())
    node.task.post(state)
end

function init()
    epochStartTime = tmr.now()
    appendJsonValue("battery", getBatteryVolts())
    
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
    queueState(initAccel)
end

function setupLis3dhInterruptStateMachine()
    writeLis3dsh(LIS3DSH_CTRL_REG1, 0x01) --hysteresis: 0, Interrupt Pin: INT1, State-Machin1: Enable
    writeLis3dsh(LIS3DSH_CTRL_REG3, 0x28) --data ready signal not connected, interrupt signals active LOW, interrupt signal pulsed, INT1/DRDY signal enabled, vector filter disabled, no soft reset
    writeLis3dsh(LIS3DSH_CTRL_REG4, 0x10 + 0x00 + 0x06) --DISABLE X, enable Y&Z, data rate: 3Hz, Block data update: continuous
    writeLis3dsh(LIS3DSH_CTRL_REG5, 0x00) 
    writeLis3dsh(LIS3DSH_THRS1_1, WAKE_SENSITIVITY)
    writeLis3dsh(LIS3DSH_ST1_1, 0x05) --NOP | Any/triggered axis greater than THRS1
    writeLis3dsh(LIS3DSH_ST1_2, 0x11) --Timer 1 | Timer 1
    writeLis3dsh(LIS3DSH_MASK1_B, 0x3C) --YZ
    writeLis3dsh(LIS3DSH_MASK1_A, 0x3C) --YZ
    writeLis3dsh(LIS3DSH_SETT1, 0x01) --Setting of threshold, peak detection and flags for SM1 motion-detection operation.
end


function initAccel()
    spi.setup(1, spi.MASTER, spi.CPOL_HIGH, spi.CPHA_HIGH, 8, 255)
    --Check Accelerometer is present
    whoAmI = readLis3dsh(0x0f)
    print2("Who_AM_I register (expect 3f): " .. string.format("%x", whoAmI))
    if (whoAmI ~= 0x3f) then
        panic(PANIC_NO_LIS3DH)
        return
    end
    if(SLEEP_SECONDS>0) then
        setupLis3dhInterruptStateMachine()
    else
        writeLis3dsh(ACC_REG_CTRL_REG4, 0x10+0x08+0x06) --enable YZ, 3hz
    end
    queueState(readLis3dshXyz)
end

function readLis3dshXyz()
    if(bit.isset(readLis3dsh(ACC_REG_STATUS), ACC_REG_STATUS_YDA)) then
        spi.transaction(1, 0, 0, 8, 0x80 + ACC_REG_OUT_X_L, 0,0,48)
        appendJsonValue("x", twosToSigned((spi.get_miso(1,0*8,8,1)+spi.get_miso(1,1*8,8,1)*256))/16350.0)
        appendJsonValue("y", twosToSigned((spi.get_miso(1,2*8,8,1)+spi.get_miso(1,3*8,8,1)*256))/16350.0)
        appendJsonValue("z", twosToSigned((spi.get_miso(1,4*8,8,1)+spi.get_miso(1,5*8,8,1)*256))/16350.0)
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
      appendJsonValue("heap", node.heap())
      jsonData = jsonData .. '}'
      print2(jsonData)
      client:publish(MQTT_TOPIC, jsonData, 0, 0, function(client) 
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
    jsonData = "{"
    setLed(false)
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
