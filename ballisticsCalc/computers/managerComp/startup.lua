local controlComp = peripheral.wrap("computer_1")
local modem = peripheral.find("modem") or error("No modem found")

modem.open(3926)

while true do
    local event, side, channel, replyChannel, message
    repeat 
        event, side, channel, replyChannel, message = os.pullEvent("modem_message")
    until channel == 3926
    if message == "reset" then
        controlComp.reboot()
    end
end