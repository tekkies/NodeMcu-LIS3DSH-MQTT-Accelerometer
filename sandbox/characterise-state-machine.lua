--https://github.com/tekkies/NodeMcu-LIS3DSH-MQTT-Accelerometer
--Firmware: https://drive.google.com/file/d/1bj2EzizW73LsHUNW7XQAOsKIsnVfJMvn/view?usp=sharing
  --adc, bit, file, gpio, mqtt, net, node, rtctime, spi, tmr, uart, wifi, tls, float

dofile("DEVICE-CONFIG.lua");


LIS3DSH_STAT = 0x18
LIS3DSH_CTRL_REG1 = 0x21        
LIS3DSH_CTRL_REG3 = 0x23        
LIS3DSH_CTRL_REG4 = 0x20        
LIS3DSH_CTRL_REG5 = 0x24        
LIS3DSH_STATUS = 0x27
    LIS3DSH_STATUS_YDA =  1
LIS3DSH_OUT_Y_L = 0x2A
LIS3DSH_ST1_1 = 0x40        
LIS3DSH_ST1_2 = 0x41        
LIS3DSH_THRS1_1 = 0x57      
LIS3DSH_MASK1_B = 0x59      
LIS3DSH_MASK1_A = 0x5A      
LIS3DSH_SETT1 = 0x5B    




--State
state = nil
epochStartTime = tmr.now()
flashCounter = 0
flashReason = 0
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
    queueState(initAccel)
end

function setupLis3dhInterruptStateMachine()
    --writeLis3dsh(LIS3DSH_CTRL_REG1, 0x01) Interrupt 1
    writeLis3dsh(LIS3DSH_CTRL_REG1, 0x80 + 0x01) --Interrupt 2
    writeLis3dsh(LIS3DSH_CTRL_REG3, 0x28) --data ready signal not connected, interrupt signals active LOW, interrupt signal pulsed, INT1/DRDY signal enabled, vector filter disabled, no soft reset
    writeLis3dsh(LIS3DSH_CTRL_REG4, 0x10 + 0x00 + 0x06) --DISABLE X, enable Y&Z, data rate: 3Hz, Block data update: continuous
    writeLis3dsh(LIS3DSH_CTRL_REG5, 0x00) 
    
    writeLis3dsh(LIS3DSH_THRS1_1, WAKE_SENSITIVITY) --threshold
    
    writeLis3dsh(LIS3DSH_ST1_1, 0x05) --NOP | Any/triggered axis greater than THRS1
    writeLis3dsh(LIS3DSH_ST1_2, 0x11) --Continue
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
        flash(PANIC_NO_LIS3DH)
        return
    end
    setupLis3dhInterruptStateMachine()
    queueState(trace)
end


function trace()
    local status = readLis3dsh(LIS3DSH_STATUS)
    spi.transaction(1, 0, 0, 8, 0x80 + LIS3DSH_OUT_Y_L, 0,0,16)
    y = twosToSigned((spi.get_miso(1,0*8,8,1)+spi.get_miso(1,1*8,8,1)*256))/16350.0


    --string.format("0x%02x", readLis3dsh(LIS3DSH_OUTS1))
    
    print2(string.format("0x%02x %.2f", status, y))
    queueNextState()
end



----------------------------------------
queueState(init)
