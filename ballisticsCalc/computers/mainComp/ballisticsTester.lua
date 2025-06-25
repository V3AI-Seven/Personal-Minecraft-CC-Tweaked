local ballistics = require("ballisticsMath.lua")

cannonCoord = {}
print("x coord of cannon : ")
table_insert(cannonCoord, tonumber(io.read()))
print("y coord of cannon : ")
table_insert(cannonCoord, tonumber(io.read())+2)
print("z coord of cannon : ")
table_insert(cannonCoord, tonumber(io.read()))


targetCoord = {}
print("x coord of target : ")
table_insert(targetCoord, tonumber(io.read()))
print("y coord of target : ")
table_insert(targetCoord, tonumber(io.read()))
print("z coord of target : ")
table_insert(targetCoord, tonumber(io.read()))

print("Number of powder charges (int) : ")
powderCharges = tonumber(io.read())

print("What is the standart direction of the cannon ? (north, south, east, west)")
directionOfCannon = io.read()

print("What is the RPM of the yaw axis ?")
yawRPM = tonumber(io.read())
print("What is the RPM of the pitch axis ?")
pitchRPM = tonumber(io.read())

print("What is the length of the cannon ? (From the block held by the mount to the tip of the cannon, the held block excluded) ")
cannonLength = tonumber(io.read())

local rt = ballistics.ballistics_to_target(
    cannonCoord,
    targetCoord,
    powderCharges,
    directionOfCannon,
    yawRPM,
    pitchRPM,
    cannonLength
)

print("Yaw is ", rt.yaw)
print("With the yaw axis set at ", yawRPM, " rpm, the cannon must take ", rt.yaw_time, " ticks of turning the yaw axis.")

if rt[1].pitch ~= -1 then
    print("\nHigh shot:")
    print("Pitch is ", rt[1].pitch)
    print("Airtime is", rt[1].airtime, "ticks")
    print("With the pitch axis set at ", pitchRPM, " rpm, the cannon must take ", rt[1].pitch_time, " ticks of turning the pitch axis.")
    print("Precision: ", rt[1].precision)
else
    print("\nHigh shot is impossible")
end

if rt[2].pitch ~= -1 then
    print("\nLow shot:")
    print("Pitch is ", rt[2].pitch)
    print("Airtime is", rt[2].airtime, "ticks")
    print("With the pitch axis set at ", pitchRPM, " rpm, the cannon must take ", rt[2].pitch_time, " ticks of turning the pitch axis.")
    print("Precision: ", rt[2].precision)
else
    print("\nLow shot is impossible")
end