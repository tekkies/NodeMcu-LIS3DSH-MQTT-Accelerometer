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
    --Enable accelerometer
    writeAcc(ACC_REG_CTRL_REG4, 0x10+0x08+0x07)
    print("ACC_REG_CTRL_REG4 " .. string.format("%x", readAcc(ACC_REG_CTRL_REG4)))
end


initAccel()

while(not bit.isset(readAcc(ACC_REG_STATUS), ACC_REG_STATUS_YDA))
do
    print(".")
end

print("X:" .. twosToSigned((readAcc(ACC_REG_OUT_X_H) * 256)+readAcc(ACC_REG_OUT_X_L))/16350.0)
print("Y:" .. twosToSigned((readAcc(ACC_REG_OUT_Y_H) * 256)+readAcc(ACC_REG_OUT_Y_L))/16350.0)
print("Z:" .. twosToSigned((readAcc(ACC_REG_OUT_Z_H) * 256)+readAcc(ACC_REG_OUT_Z_L))/16350.0)
