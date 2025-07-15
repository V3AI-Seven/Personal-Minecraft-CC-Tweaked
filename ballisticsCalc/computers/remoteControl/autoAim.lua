local modem = peripheral.find("modem") or error("No modem found")

while true do
    print("Type fire")
    local input = read()
    if input == "fire" then
        local position = gps.locate()
        if not position then
            print("Failed to get position with GPS")
            goto failed
        end
        local target = {x = position[1], y = position[2], z = position[3]}
        modem.transmit(6505, 6505, {"lock+fire", target.x, target.y, target.z})
        print("Fire command sent")
    else
        print("Invalid command. Type 'fire' to fire the cannon.")
    end
    local event, side, channel, replyChannel, message, distance
    repeat 
        event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
    until channel == 6505
    if type(message) == "string" and message == "fireConfirm" then
        print("Cannon fired successfully!")
    elseif type(message) == "string" and message == "noValidShots" then
        print("No valid shots found. Please try again.")
    elseif type(message) == "string" and message == "fireFailed" then
        print("Fire failed. Please check the cannon and try again.")
    elseif type(message) == "string" and message == "fireReqConfirm" then
        print("Fire request confirmed. Preparing to fire.")
    else
        print("Received unknown message: " .. tostring(message))
    end
    ::failed::
end