--https://github.com/tekkies/NodeMcu-LIS3DSH-MQTT-Accelerometer
--Firmware: https://drive.google.com/file/d/1bj2EzizW73LsHUNW7XQAOsKIsnVfJMvn/view?usp=sharing
  --adc, bit, file, gpio, mqtt, net, node, rtctime, spi, tmr, uart, wifi, tls, float

dofile("DEVICE-CONFIG.lua");

PANIC_NO_LIS3DH = 4
PANIC_NO_WIFI = 5
PANIC_MQTT_FAIL = 6

CS_X = 0x13
STAT = 0x18
CTRL_REG1 = 0x20
CTRL_REG2 = 0x21
CTRL_REG3 = 0x22
CTRL_REG4 = 0x23
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

REFERENCE = 0x26
INT1_CFG = 0x30
INT1_SRC = 0x31
INT1_THS = 0x32
INT1_DURATION = 0x33



--State
state = nil
epochStartTime = tmr.now()
flashCounter = 0
flashReason = 0
jsonData = '{'

function read(address)
    spi.transaction(1, 0, 0, 8, 0x80 + address, 0,0,8)
    return spi.get_miso(1,0,8,1)
end

function write(address, value)
    --print2(string.format("0x%02x 0x%02x", address, value))
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
    --print1(costlyGetStateName())
    node.task.post(state)
end

function init()
    epochStartTime = tmr.now()
    dofile("config.lua");
    appendJsonValue("batterymV", adc.readvdd33(0))
    
    if(USE_LED) then
        setLed(true)
    end
    queueState(initAccel)
end


function initAccel()
    spi.setup(1, spi.MASTER, spi.CPOL_HIGH, spi.CPHA_HIGH, 8, 255)
    --Check Accelerometer is present
    whoAmI = read(0x0f)
    print2("Who_AM_I register (expect 33): " .. string.format("%x", whoAmI))
    if (whoAmI ~= 0x33) then
        flash(PANIC_NO_LIS3DH)
        return
    end
    --https://drive.google.com/file/d/1Hp1i9k7oCuYCzNk2BPbp-OQtafosQcg2/edit?disco=AAAASojlPu8
    write(CTRL_REG1, 0x27)
    write(CTRL_REG2, 0x09)
    write(CTRL_REG3, 0x40)
    write(CTRL_REG4, 0x00)
    write(CTRL_REG5, 0x08)
    write(INT1_THS, 0x04)
    write(INT1_DURATION, 0x00)
    read(REFERENCE)
    write(INT1_CFG, 0x7F)
    
    
    queueState(trace)
end


function trace()
    local status = read(STATUS)
    local intStatus = read(INT1_SRC)
    if(bit.isset(status, STATUS_YDA)) then
        spi.transaction(1, 0, 0, 8, 0x80 + 0x40 + OUT_X_L, 0,0,48)
        xH = spi.get_miso(1,8,8,1)
        yH = spi.get_miso(1,24,8,1)
        zH = spi.get_miso(1,40,8,1)
        x = twosToSigned((spi.get_miso(1,0,8,1)+xH*256))/16384.0
        y = twosToSigned((spi.get_miso(1,16,8,1)+yH*256))/16384.0
        z = twosToSigned((spi.get_miso(1,32,8,1)+zH*256))/16384.0

        --y = twosToSigned((spi.get_miso(1,0*8,8,1)+spi.get_miso(1,1*8,8,1)*256))/16350.0
        print2(string.format("0x%02x 0x%02x %.2f %.2f %.2f", status, intStatus, x, y, z))

        if (intStatus > 0) then
            print("reset")
            read(REFERENCE)  --reset the reference
        end

        
    end
    
    queueNextState()
end



----------------------------------------
queueState(init)
