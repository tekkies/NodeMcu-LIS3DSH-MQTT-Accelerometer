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
        panic(PANIC_NO_LIS3DH)
        return
    end


    --reset
    --local ctrlReg3 = readAcc(ACC_REG_CTRL_REG3)
    --print("ACC_REG_CTRL_REG3 " .. string.format("%x", readAcc(ctrlReg3)))
    --writeAcc(ACC_REG_CTRL_REG3, bit.bor(ctrlReg3 + 0x01))
    
    --Enable accelerometer
    writeAcc(ACC_REG_CTRL_REG4, 0x10+0x08+0x07)
    print("ACC_REG_CTRL_REG4 " .. string.format("0x%02x", readAcc(ACC_REG_CTRL_REG4)))
    print("ACC_REG_CTRL_REG5 " .. string.format("0x%02x", readAcc(ACC_REG_CTRL_REG5)))
    print("ACC_REG_CTRL_REG6 " .. string.format("0x%02x", readAcc(ACC_REG_CTRL_REG6)))
    

end


initAccel()


function waitForData()
    print("Wait...")
    while(not bit.isset(readAcc(ACC_REG_STATUS), ACC_REG_STATUS_XYZDA))
    do
    end
end


writeAcc(ACC_REG_CTRL_REG5, 0x00)
print("Status ".. string.format("0x%02x", readAcc(ACC_REG_STATUS)))
waitForData()
print("Status ".. string.format("0x%02x", readAcc(ACC_REG_STATUS)))
print("X " .. string.format("0x%04x", (readAcc(ACC_REG_OUT_X_H) * 256)+readAcc(ACC_REG_OUT_X_L)))
print("X " .. twosToSigned((readAcc(ACC_REG_OUT_X_H) * 256)+readAcc(ACC_REG_OUT_X_L))/16350.0)
print("Y " .. twosToSigned((readAcc(ACC_REG_OUT_Y_H) * 256)+readAcc(ACC_REG_OUT_Y_L))/16350.0)
print("Z " .. twosToSigned((readAcc(ACC_REG_OUT_Z_H) * 256)+readAcc(ACC_REG_OUT_Z_L))/16350.0)

writeAcc(ACC_REG_CTRL_REG5, 0x00)
print("Status ".. string.format("0x%02x", readAcc(ACC_REG_STATUS)))
waitForData()
print("Status ".. string.format("0x%02x", readAcc(ACC_REG_STATUS)))
print("X " .. string.format("0x%04x", (readAcc(ACC_REG_OUT_X_H) * 256)+readAcc(ACC_REG_OUT_X_L)))
print("X " .. twosToSigned((readAcc(ACC_REG_OUT_X_H) * 256)+readAcc(ACC_REG_OUT_X_L))/16350.0)
print("Y " .. twosToSigned((readAcc(ACC_REG_OUT_Y_H) * 256)+readAcc(ACC_REG_OUT_Y_L))/16350.0)
print("Z " .. twosToSigned((readAcc(ACC_REG_OUT_Z_H) * 256)+readAcc(ACC_REG_OUT_Z_L))/16350.0)


writeAcc(ACC_REG_CTRL_REG5, 0x04)
print("Status ".. string.format("0x%02x", readAcc(ACC_REG_STATUS)))
waitForData()
print("Status ".. string.format("0x%02x", readAcc(ACC_REG_STATUS)))
print("X " .. string.format("0x%04x", (readAcc(ACC_REG_OUT_X_H) * 256)+readAcc(ACC_REG_OUT_X_L)))
print("X " .. twosToSigned((readAcc(ACC_REG_OUT_X_H) * 256)+readAcc(ACC_REG_OUT_X_L))/16350.0)
print("Y " .. twosToSigned((readAcc(ACC_REG_OUT_Y_H) * 256)+readAcc(ACC_REG_OUT_Y_L))/16350.0)
print("Z " .. twosToSigned((readAcc(ACC_REG_OUT_Z_H) * 256)+readAcc(ACC_REG_OUT_Z_L))/16350.0)

writeAcc(ACC_REG_CTRL_REG5, 0x04)
print("Status ".. string.format("0x%02x", readAcc(ACC_REG_STATUS)))
waitForData()
print("Status ".. string.format("0x%02x", readAcc(ACC_REG_STATUS)))
print("X " .. string.format("0x%04x", (readAcc(ACC_REG_OUT_X_H) * 256)+readAcc(ACC_REG_OUT_X_L)))
print("X " .. twosToSigned((readAcc(ACC_REG_OUT_X_H) * 256)+readAcc(ACC_REG_OUT_X_L))/16350.0)
print("Y " .. twosToSigned((readAcc(ACC_REG_OUT_Y_H) * 256)+readAcc(ACC_REG_OUT_Y_L))/16350.0)
print("Z " .. twosToSigned((readAcc(ACC_REG_OUT_Z_H) * 256)+readAcc(ACC_REG_OUT_Z_L))/16350.0)

--List all registers again
--[[for reg=0x0c, 0x77, 1
do
    print(string.format("0x%02x",reg) .. " " .. string.format("0x%02x",readAcc(reg)) )
end--]]



--Clean Up
--self-Test
writeAcc(ACC_REG_CTRL_REG5, 0x00) 
--Sleep Accelerometer
writeAcc(ACC_REG_CTRL_REG4, 0x00)




