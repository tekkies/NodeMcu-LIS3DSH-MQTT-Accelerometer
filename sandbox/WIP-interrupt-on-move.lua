ACC_REG_OUT_T = 0x0c
ACC_REG_CTRL_REG3 = 0x23
ACC_REG_CTRL_REG4 = 0x20
ACC_REG_CTRL_REG5 = 0x24
ACC_REG_CTRL_REG6 = 0x25
ACC_REG_STATUS = 0x27
    ACC_REG_STATUS_YDA =  1
    ACC_REG_STATUS_XYZDA = 0x80
ACC_REG_OUT_X_L = 0x28
ACC_REG_OUT_X_H = 0x29
ACC_REG_OUT_Y_L = 0x2A
ACC_REG_OUT_Y_H = 0x2B
ACC_REG_OUT_Z_L = 0x2C
ACC_REG_OUT_Z_H = 0x2D

LIS3DSH_CTRL_REG1 = 0x01
LIS3DSH_CTRL_REG3 = 0x48        
LIS3DSH_CTRL_REG4 = 0x67        
LIS3DSH_CTRL_REG5 = 0x00        
LIS3DSH_THRS1_1 = 0x55      
LIS3DSH_ST1_1 = 0x05        
LIS3DSH_ST1_2 = 0x11        
LIS3DSH_MASK1_B = 0xFC      
LIS3DSH_MASK1_A = 0xFC      
LIS3DSH_SETT1 = 0x01        

function twosToSigned(twos)
    if(twos > 0x7fff) then
        return twos - 0x10000
    else
        return twos
    end    
end

function readAcc(address)
    spi.transaction(1, 0, 0, 8, 0x80 + address, 0,0,8)
    return spi.get_miso(1,0,8,1)
end

function writeAcc(address, value)
    spi.set_mosi(1, 0, 8, value)
    spi.transaction(1, 0, 0, 8, address, 8,0,0)
end

function initAccel()
    spi.setup(1, spi.MASTER, spi.CPOL_HIGH, spi.CPHA_HIGH, 8, 255)


    --Check Accelerometer is present
    whoAmI = readAcc(0x0f)
    print("Who_AM_I register (expect 3f): " .. string.format("%x", whoAmI))
    if (whoAmI ~= 0x3f) then
        print("No LIS3DSH detected")
        return
    end
    
    --"Wake-Up" - 9.2 in Application Note
    writeAcc(LIS3DSH_CTRL_REG1, 0x01) --hysteresis: 0, Interrupt Pin: INT1, State-Machin1: Enable
    writeAcc(LIS3DSH_CTRL_REG3, 0x48) Interrupt polarity High, 
    writeAcc(LIS3DSH_CTRL_REG4, 0x67)
    writeAcc(LIS3DSH_CTRL_REG5, 0x00)
    writeAcc(LIS3DSH_THRS1_1, 0x55)
    writeAcc(LIS3DSH_ST1_1, 0x05)
    writeAcc(LIS3DSH_ST1_2, 0x11)
    writeAcc(LIS3DSH_MASK1_B, 0xFC)
    writeAcc(LIS3DSH_MASK1_A, 0xFC)
    writeAcc(LIS3DSH_SETT1, 0x01)    

end


initAccel()

function waitForData()
    --print("Wait...")
    while(not bit.isset(readAcc(ACC_REG_STATUS), ACC_REG_STATUS_XYZDA))
    do
        tmr.wdclr()
    end
end


function readAll()
    xPercent = twosToSigned(((readAcc(ACC_REG_OUT_X_H) * 256)+readAcc(ACC_REG_OUT_X_L)))/163.500
    yPercent = twosToSigned(((readAcc(ACC_REG_OUT_Y_H) * 256)+readAcc(ACC_REG_OUT_Y_L)))/163.500
    zPercent = twosToSigned(((readAcc(ACC_REG_OUT_Z_H) * 256)+readAcc(ACC_REG_OUT_Z_L)))/163.500
end


function printAll()
    --print("Status ".. string.format("0x%02x", readAcc(ACC_REG_STATUS)))
    waitForData()
    readAll()    
    print("X=" .. string.format("%3d", xPercent) .. "% y=" .. string.format("%3d", yPercent) .. "% z=" .. string.format("%3d", zPercent) .. "%")
end

print("Normal")
printAll()




--Sleep Accelerometer
writeAcc(ACC_REG_CTRL_REG4, 0x00)




