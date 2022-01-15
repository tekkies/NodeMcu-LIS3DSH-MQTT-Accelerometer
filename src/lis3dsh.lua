--https://github.com/tekkies/NodeMcu-LIS3DSH-MQTT-Accelerometer
--Firmware: https://drive.google.com/file/d/1bj2EzizW73LsHUNW7XQAOsKIsnVfJMvn/view?usp=sharing
  --adc, bit, file, gpio, mqtt, net, node, rtctime, spi, tmr, uart, wifi, tls, float

dofile("DEVICE-CONFIG.lua");

PANIC_NO_LIS3DH = 4
PANIC_NO_WIFI = 5
PANIC_MQTT_FAIL = 6

CS_X = 0x13
STAT = 0x18
CTRL_REG1 = 0x21
CTRL_REG2 = 0x22
CTRL_REG3 = 0x23
CTRL_REG4 = 0x20
CTRL_REG5 = 0x24
STATUS = 0x27
  STATUS_YDA =  1
OUT_X_L = 0x28
ST2_1 = 0x60
THRS1_2 = 0x77
MASK2_B = 0x79
MASK2_A = 0x7A
SETT2 = 0x7B
OUTS2 = 0x7F

--State
state = nil
epochStartTime = tmr.now()
flashCounter = 0
flashReason = 0
jsonData = '{'
xH = 0xFFFF

function read(address)
  spi.transaction(1, 0, 0, 8, 0x80 + address, 0,0,8)
  return spi.get_miso(1,0,8,1)
end

function write(address, value)
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

function flash(newFlashReason)
    flashReason = newFlashReason
    flashCallback()
end

function flashCallback()
    print1("FLASH " .. flashReason)
    if (((flashCounter % 2) == 0) and (flashCounter < flashReason * 2)) then
        setLed(false)
    else
        setLed(true)
    end
    flashCounter = flashCounter + 1
    if(flashCounter >= (flashReason * 2)+1) then
        flashCounter = 0
        SLEEP_SECONDS = 5*60
        queueState(sleepNow)
        return
    end
    tmr.create():alarm(300, tmr.ALARM_SINGLE, flashCallback)
end

function appendJsonString(key, value)
    appendJsonValue(key, '"'..value..'"')
end

function appendJsonValue(key, value)
    --jsonData = jsonData .. "a"
    if(#jsonData ~= 1) then
        jsonData = jsonData .. ','
    end
    jsonData = jsonData .. '"'  .. key .. '":' .. value .. '' 
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
    dofile("config.lua");
    appendJsonValue("batterymV", adc.readvdd33(0))
    
    if(USE_LED) then
        setLed(true)
    end
    tmr.create():alarm(60 * 1000, tmr.ALARM_SINGLE, sleepNow)
    queueState(initAdc)
end

function initAdc()
    if adc.force_init_mode(adc.INIT_VDD33)
    then
      node.restart()
      return -- don't bother continuing, the restart is scheduled
    end
    queueState(initAccel)
end

function configureWake()
  if(xH ~= 0xFFFF) then
     write(CS_X, xH)
     write(CS_X+1, yH)
     write(CS_X+2, zH)
  end
  write(CTRL_REG3, 0x28) --data ready signal not connected, int active LOW, int signal pulsed, INT1 enabled
  write(CTRL_REG5, 0x00) --2g scale, 800hz filter
  write(THRS1_2, WAKE_SENSITIVITY)
  write(ST2_1, 0x05) --NOP | Any/triggered axis greater than THRS1
  write(ST2_1+1, 0x11) --CONT - trigger interrupt & restart machine
  write(MASK2_B, 0x3C) --YZ
  write(MASK2_A, 0x3C) --YZ
  write(SETT2, 0x19) --Raw input, constant shift, program flow can be modified by STOP and CONT commands
  write(CTRL_REG2, 0x01) --No Hyst, Interrupt 2, SM2 Enable
end

function initAccel()
  spi.setup(1, spi.MASTER, spi.CPOL_HIGH, spi.CPHA_HIGH, 8, 255)
  --Check Accelerometer is present
  whoAmI = read(0x0f)
  print2("Who_AM_I register (expect 3f): " .. string.format("%x", whoAmI))
  if (whoAmI ~= 0x3f) then
    flash(PANIC_NO_LIS3DH)
    return
  end
  wakeReason = read(OUTS2)
  write(CTRL_REG2, 0x00) --disable SM2
  appendJsonString("wakeReason",string.format("0x%02x",wakeReason))
  write(CTRL_REG4,0x00) --Stop sampling
  queueState(waitForWiFi)
end

function readXyz()
    if(bit.isset(read(STATUS), STATUS_YDA)) then
        spi.transaction(1, 0, 0, 8, 0x80 + OUT_X_L, 0,0,48)
        xH = spi.get_miso(1,8,8,1)
        yH = spi.get_miso(1,24,8,1)
        zH = spi.get_miso(1,40,8,1)
        appendJsonValue("x", twosToSigned((spi.get_miso(1,0,8,1)+xH*256))/16384.0)
        appendJsonValue("y", twosToSigned((spi.get_miso(1,16,8,1)+yH*256))/16384.0)
        appendJsonValue("z", twosToSigned((spi.get_miso(1,32,8,1)+zH*256))/16384.0)
        state=postMqtt        
    end
    queueNextState()
end

function waitForWiFi()
  if(epochSeconds() > 20) then
    flash(PANIC_NO_WIFI)
    return
  end
  if(wifi.sta.status() == wifi.STA_GOTIP) then
    write(CTRL_REG4, 0x16) --data rate: 3Hz, No Block data update, YZ
    state=readXyz
    appendJsonValue("rssi", wifi.sta.getrssi())
  end
  queueNextState()
end


function postMqtt()
    mqttClient:connect(MQTT_BROKER, 1883, false, function(client)
      print2("connected")
      appendJsonValue("heap", node.heap())
      appendJsonValue("upTimeMs", tmr.now()/1000)
      jsonData = jsonData .. '}'
      print2(jsonData)
      client:publish("/tekkies.co.uk/NodeMCU/".. DEVICE_NAME .. "/lis3dsh.lua", jsonData, 0, 0, function(client) 
        print2("sent")
        mqttClient:close()
      end)
    end,
    function(client, reason)
      print2("Connection failed reason: " .. reason)
      flash(PANIC_MQTT_FAIL)
    end)
end

function mqttOffline(client)
    queueState(sleepNow)
end

function sleepNow()
    jsonData = "{"
    setLed(false)
    if(SLEEP_SECONDS==0) then
        queueState(init)
    else
        configureWake()
        print2("Starting sleep at " .. tmr.now()/1000 .. "ms")
        local us = SLEEP_SECONDS*1000*1000
        node.dsleep(us, 1, nil)
    end
end

mqttClient = mqtt.Client(MQTT_CLIENTID, 120)
mqttClient:on("offline", mqttOffline)
queueState(init)
