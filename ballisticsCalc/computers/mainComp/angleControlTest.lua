local cannonInterface = peripheral.wrap("blockReader_0")
local pitchInterface = peripheral.wrap("top")
local yawInterface = peripheral.wrap("back")

local cannonAngleData = {}

pitchInterface.setTargetSpeed(0)
yawInterface.setTargetSpeed(0)

local function pitchControl(targetPitch)
    cannonAngleData.pitch = cannonInterface.getBlockData().CannonPitch
    while targetPitch - cannonAngleData.pitch > 0.1 or targetPitch - cannonAngleData.pitch < -0.1 do
        cannonAngleData.pitch = cannonInterface.getBlockData().CannonPitch
        pitchInterface.setTargetSpeed((5 * (targetPitch - cannonAngleData.pitch)) * -1)
        sleep()
    end
end
local function yawControl(targetYaw)
    cannonAngleData.yaw = cannonInterface.getBlockData().CannonYaw
    while targetYaw - cannonAngleData.yaw > 0.1 or targetYaw - cannonAngleData.yaw < -0.1 do
        cannonAngleData.yaw = cannonInterface.getBlockData().CannonYaw
        yawInterface.setTargetSpeed((5*(targetYaw-cannonAngleData.yaw))*-1)
        sleep()
    end
end

while true do
    print("Enter target pitch")
    local targetPitch = tonumber(read())
    pitchControl(targetPitch)
    print("Enter target yaw")
    local targetYaw = tonumber(read())
    yawControl(targetYaw)
end