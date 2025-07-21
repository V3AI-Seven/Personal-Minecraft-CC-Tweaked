local modem = peripheral.find("modem") or error("No modem found")

modem.transmit(3926, 3926, "reset")