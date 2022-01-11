DEVICE_NAME = node.chipid() .. "-" .. node.flashid()  --Rename to something more meaningful

--Static IP is faster than DHCP
--wifi.sta.setip(
--    {
--    ip = "192.168.0.99",
--    netmask = "255.255.255.0",
--    gateway = "192.168.0.1"
--    }
--)

