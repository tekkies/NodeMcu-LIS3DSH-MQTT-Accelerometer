DEVICE_NAME = node.chipid() .. "-" .. node.flashid()  --Rename to something more meaningful

--Static IP is faster than DHCP but lacks DNS
--cfg =
--  {
--    ip="192.168.0.99",
--    netmask="255.255.255.0",
--    gateway="192.168.0.1"
--  }
--wifi.sta.setip(cfg)
--wifi.sta.connect()

