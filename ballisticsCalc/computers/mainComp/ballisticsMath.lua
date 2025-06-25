
local sin = math.sin
local cos = math.cos
local atan = math.atan
local sqrt = math.sqrt
local pi = math.pi
local log = math.log

local function radians(deg)
    return deg * pi / 180
end

local function myLinspace(startValue, endValue, num)
    local t = {}
    if num == 1 then
        t[1] = startValue
    else
        local step = (endValue - startValue) / (num - 1)
        for i = 1, num do
            t[i] = startValue + (i - 1) * step
        end
    end
    return t
end

local function timeInAir(y0, y, Vy)
    -- Find the air time of the projectile, using recursive sequence.
    local t = 0
    local t_below = 999999999

    if y0 <= y then
        -- If cannon is lower than a target, simulating the way, up to the targets level
        while t < 100000 do
            y0 = y0 + Vy
            Vy = 0.99 * Vy - 0.05
            t = t + 1
            if y0 > y then
                t_below = t - 1
                break
            end
            if Vy < 0 then
                return -1, -1
            end
        end
    end

    while t < 100000 do
        y0 = y0 + Vy
        Vy = 0.99 * Vy - 0.05
        t = t + 1
        if y0 <= y then
            return t_below, t
        end
    end
    return -1, -1
end

local function getFirstElement(array)
    return array[1]
end

local function getRoot(tab, sens)
    if sens == 1 then
        for i = 2, #tab do
            if tab[i-1][1] < tab[i][1] then
                return tab[i-1]
            end
        end
        return tab[#tab]
    elseif sens == -1 then
        for i = #tab-1, 1, -1 do
            if tab[i][1] > tab[i+1][1] then
                return tab[i+1]
            end
        end
        return tab[1]
    end
end

function BallisticsToTarget(cannon, target, power, direction, lenght)
    -- Function that calculates the elevation angle to hit the target with a cannon

    local Dx = cannon[1] - target[1]
    local Dz = cannon[3] - target[3]
    local distance = sqrt(Dx * Dx + Dz * Dz)
    local initialSpeed = power * 2
    local nbOfIterations = 5

    local yaw
    if Dx ~= 0 then
        yaw = atan(Dz / Dx) * 180 / pi
    else
        yaw = 90
    end
    if Dx >= 0 then
        yaw = yaw + 180
    end

    local function tryAllAngles(low, high, nbOfElements)
        local deltaTimes = {}
        for _, triedPitch in ipairs(myLinspace(low, high, nbOfElements)) do
            local triedPitchRad = radians(triedPitch)
            local Vw = cos(triedPitchRad) * initialSpeed
            local Vy = sin(triedPitchRad) * initialSpeed
            local xCoord_2d = lenght * cos(triedPitchRad)
            local ok, timeToTarget = pcall(function()
                return math.abs(
                    log(1 - (distance - xCoord_2d) / (100 * Vw)) / (-0.010050335853501)
                )
            end)
            if not ok or not timeToTarget or timeToTarget ~= timeToTarget then
                -- skip if math error or nan
            else
                local yCoordOfEndBarrel = cannon[2] + sin(triedPitchRad) * lenght
                local t_below, t_above = timeInAir(yCoordOfEndBarrel, target[2], Vy)
                if t_below < 0 then
                    -- skip
                else
                    local deltaT = math.min(
                        math.abs(timeToTarget - t_below),
                        math.abs(timeToTarget - t_above)
                    )
                    table.insert(deltaTimes, {deltaT, triedPitch, deltaT + timeToTarget})
                end
            end
        end
        if #deltaTimes == 0 then
            error("The target is unreachable with your current canon configuration !")
        end
        local dt1, p1, ta1 = table.unpack(getRoot(deltaTimes, 1))
        local dt2, p2, ta2 = table.unpack(getRoot(deltaTimes, -1))
        return {dt1, p1, ta1}, {dt2, p2, ta2}
    end

    local function tryAllAnglesUnique(low, high, nbOfElements)
        local deltaTimes = {}
        for _, triedPitch in ipairs(myLinspace(low, high, nbOfElements)) do
            local triedPitchRad = radians(triedPitch)
            local Vw = cos(triedPitchRad) * initialSpeed
            local Vy = sin(triedPitchRad) * initialSpeed
            local xCoord_2d = lenght * cos(triedPitchRad)
            local ok, timeToTarget = pcall(function()
                return math.abs(
                    log(1 - (distance - xCoord_2d) / (100 * Vw)) / (-0.010050335853501)
                )
            end)
            if not ok or not timeToTarget or timeToTarget ~= timeToTarget then
                -- skip if math error or nan
            else
                local yCoordOfEndBarrel = cannon[2] + sin(triedPitchRad) * lenght
                local t_below, t_above = timeInAir(yCoordOfEndBarrel, target[2], Vy)
                if t_below < 0 then
                    -- skip
                else
                    local deltaT = math.min(
                        math.abs(timeToTarget - t_below),
                        math.abs(timeToTarget - t_above)
                    )
                    table.insert(deltaTimes, {deltaT, triedPitch, deltaT + timeToTarget})
                end
            end
        end
        if #deltaTimes == 0 then
            error("The target is unreachable with your current canon configuration !")
        end
        table.sort(deltaTimes, function(a, b) return a[1] < b[1] end)
        local dt, p, ta = table.unpack(deltaTimes[1])
        return dt, p, ta
    end

    local t1, t2 = tryAllAngles(-30, 60, 91)
    local deltaTime1, pitch1, airtime1 = t1[1], t1[2], t1[3]
    local deltaTime2, pitch2, airtime2 = t2[1], t2[2], t2[3]

    for i = 0, nbOfIterations - 1 do
        deltaTime1, pitch1, airtime1 = tryAllAnglesUnique(pitch1 - 10^(-i), pitch1 + 10^(-i), 21)
        deltaTime2, pitch2, airtime2 = tryAllAnglesUnique(pitch2 - 10^(-i), pitch2 + 10^(-i), 21)
    end

    if pitch1 > 60.5 then
        pitch1 = "Over 60"
    elseif pitch1 < -29.5 then
        pitch1 = "Under -30"
    end

    if pitch2 > 60.5 then
        pitch2 = "Over 60"
    elseif pitch2 < -29.5 then
        pitch2 = "Under -30"
    end

    local airtimeSeconds1 = airtime1 / 20
    local airtimeSeconds2 = airtime2 / 20

    if direction == "north" then
        yaw = (yaw + 90) % 360
    elseif direction == "west" then
        yaw = (yaw + 180) % 360
    elseif direction == "south" then
        yaw = (yaw + 270) % 360
    elseif direction ~= "east" then
        return "Invalid direction"
    end

    local fuzeTime1 = math.floor(airtime1 + (deltaTime1 / 2) - 10)
    local fuzeTime2 = math.floor(airtime2 + (deltaTime2 / 2) - 10)

    local precision1 = math.floor((1 - deltaTime1 / airtime1) * 100)
    local precision2 = math.floor((1 - deltaTime2 / airtime2) * 100)

    return {
        {yaw, pitch1, airtime1, math.floor(airtimeSeconds1*100)/100, fuzeTime1, precision1},
        {yaw, pitch2, airtime2, math.floor(airtimeSeconds2*100)/100, fuzeTime2, precision2}
    }
end

-- CREDITS OF ORIGINAL FORMULAS : @sashafiesta#1978 on Discord
