local ballisticsFile = require("ballisticsMath")

local cannonData = {}

print("Enter x of cannon mount")
cannonData.x = tonumber(read())
print("Enter y of cannon mount")
cannonData.y = tonumber(read())
print("Enter z of cannon mount")
cannonData.z = tonumber(read())
print("Enter cannon starting cardinal direction (north, south, east, west)")
cannonData.direction = read()
print("Enter number of charges")
cannonData.charges = tonumber(read())
print("Enter cannon length")
cannonData.length = tonumber(read())

while true do
    ballisticsFile.ballistics(cannonData)
end