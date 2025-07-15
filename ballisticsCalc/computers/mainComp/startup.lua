local modem = peripheral.find("modem") or error("No modem found")
local ballisticsFile = require("ballisticsAttempt2")

modem.open(6505)
local target = {}
local cannonPos = {37,150,5}

while true do
    local event, side, channel, replyChannel, message
    repeat 
        event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
    until channel == 6505
    if type(message) == "table" and message[1] == "lock+fire" and channel == 6505 then
        target = {x = message[2], y = message[3], z = message[4]}
        modem.transmit(replyChannel, 6505, "fireReqConfirm")
        ballisticsFile.ballistics(cannonPos, 4, "south", 6, target)
        modem.transmit(replyChannel, 6505, "fireConfirm")
    end
end