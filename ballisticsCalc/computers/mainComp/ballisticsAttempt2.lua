function ballistics(cannon, power, direction, length_, target)

    local cannonInterface = peripheral.wrap("blockReader_1")
    local pitchInterface = peripheral.wrap("top")
    local yawInterface = peripheral.wrap("back")
    local modem = peripheral.find("modem") or error("No modem found")

    local speedCap = 64
    local minSpeed = 1
    local aimTolerance = 0.1

    local cannonAngleData = {}

    pitchInterface.setTargetSpeed(0)
    yawInterface.setTargetSpeed(0)

    local function pitchControl(targetPitch)
        cannonAngleData.pitch = cannonInterface.getBlockData().CannonPitch
        while targetPitch - cannonAngleData.pitch > aimTolerance or targetPitch - cannonAngleData.pitch < -aimTolerance do
            cannonAngleData.pitch = cannonInterface.getBlockData().CannonPitch
            local targetSpeed = (10 * (targetPitch - cannonAngleData.pitch)) * -1

            if targetSpeed > speedCap then
                targetSpeed = speedCap
            elseif targetSpeed < -speedCap then
                targetSpeed = -speedCap
            end
            
            -- Ensure speed doesn't drop below minSpeed
            if targetSpeed > 0 and targetSpeed < minSpeed then
                targetSpeed = minSpeed
            elseif targetSpeed < 0 and targetSpeed > -minSpeed then
                targetSpeed = -minSpeed
            end



            --print("Speed: " .. targetSpeed)
            pitchInterface.setTargetSpeed(targetSpeed)
            sleep()
        end
        pitchInterface.setTargetSpeed(0)
    end
    local function yawControl(targetYaw)
        cannonAngleData.yaw = cannonInterface.getBlockData().CannonYaw
        while targetYaw - cannonAngleData.yaw > aimTolerance or targetYaw - cannonAngleData.yaw < -aimTolerance do
            cannonAngleData.yaw = cannonInterface.getBlockData().CannonYaw
            local targetSpeed = (10 * (targetYaw - cannonAngleData.yaw)) * -1

            if targetSpeed > speedCap then
                targetSpeed = speedCap
            elseif targetSpeed < -speedCap then
                targetSpeed = -speedCap
            end
            
            -- Ensure speed doesn't drop below minSpeed
            if targetSpeed > 0 and targetSpeed < minSpeed then
                targetSpeed = minSpeed
            elseif targetSpeed < 0 and targetSpeed > -minSpeed then
                targetSpeed = -minSpeed
            end
            


            --print("Speed: " .. targetSpeed)
            yawInterface.setTargetSpeed(targetSpeed)
            sleep()
        end
        yawInterface.setTargetSpeed(0)
    end
-- BallisticsToTarget.lua
    local math = math

    -- Helper error for out-of-range
    local function OutOfRangeException(msg)
        print(msg or "Out of Range")
        modem.transmit(6505, 6505, "fireFailed")
    end

    -- Equivalent to numpy.linspace
    local function myLinspace(start_, end_, num)
        local answer = {start_}
        local delta = (end_ - start_) / num
        for i = 1, num - 1 do
            table.insert(answer, answer[#answer] + delta)
        end
        table.insert(answer, end_)
        return answer
    end

    -- Simulate projectile flight time in air
    local function timeInAir(y0, y, Vy)
        local t = 0
        local t_below = 999999999

        --print("Initial y0: " .. y0 .. ", target y: " .. y .. ", initial Vy: " .. Vy)

        if y0 <= y then
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
        else
            error("sens must be 1 or -1")
        end
    end

    -- Main function
    function BallisticsToTarget(cannon, target, power, direction, length_)
        -- cannon/target: {x, y, z}
        sleep(0.1) 
        print("Targeting cannon at " .. target.x .. ", " .. target.y .. ", " .. target.z)
        local Dx, Dz = cannon[1] - target.x, cannon[3] - target.z
        local distance = math.sqrt(Dx * Dx + Dz * Dz)
        local initialSpeed = power * 2
        local nbOfIterations = 5

        local yaw
        if Dx ~= 0 then
            yaw = math.atan(Dz / Dx) * 57.2957795131 -- 180/pi
        else
            yaw = 90
        end
        if Dx >= 0 then
            yaw = yaw + 180
        end

        local function tryAllAngles(low, high, nbOfElements)
            local deltaTimes = {}
            for _, triedPitch in ipairs(myLinspace(low, high, nbOfElements)) do
                local triedPitchRad = math.rad(triedPitch)
                local Vw = math.cos(triedPitchRad) * initialSpeed
                local Vy = math.sin(triedPitchRad) * initialSpeed

                local xCoord_2d = length_ * math.cos(triedPitchRad)
                local timeToTarget
                if Vw == 0 then goto continue end
                local expr = 1 - (distance - xCoord_2d) / (100 * Vw)
                if expr <= 0 then goto continue end
                timeToTarget = math.abs(math.log(expr) / (-0.010050335853501))

                local yCoordOfEndBarrel = cannon[2] + math.sin(triedPitchRad) * length_
                local t_below, t_above = timeInAir(yCoordOfEndBarrel, target.y, Vy)
                if t_below < 0 then goto continue end

                local deltaT = math.min(
                    math.abs(timeToTarget - t_below),
                    math.abs(timeToTarget - t_above)
                )
                table.insert(deltaTimes, {deltaT, triedPitch, deltaT + timeToTarget})

                ::continue::
            end
            if #deltaTimes == 0 then
                OutOfRangeException("The target is unreachable with your current cannon configuration!")
                return
            end

            local root1 = getRoot(deltaTimes, 1)
            local root2 = getRoot(deltaTimes, -1)
            return root1, root2
        end

        local function tryAllAnglesUnique(low, high, nbOfElements)
            local deltaTimes = {}
            for _, triedPitch in ipairs(myLinspace(low, high, nbOfElements)) do
                local triedPitchRad = math.rad(triedPitch)
                local Vw = math.cos(triedPitchRad) * initialSpeed
                local Vy = math.sin(triedPitchRad) * initialSpeed

                local xCoord_2d = length_ * math.cos(triedPitchRad)
                local timeToTarget
                if Vw == 0 then goto continue end
                local expr = 1 - (distance - xCoord_2d) / (100 * Vw)
                if expr <= 0 then goto continue end
                timeToTarget = math.abs(math.log(expr) / (-0.010050335853501))

                local yCoordOfEndBarrel = cannon[2] + math.sin(triedPitchRad) * length_
                local t_below, t_above = timeInAir(yCoordOfEndBarrel, target.y, Vy)
                if t_below < 0 then goto continue end

                local deltaT = math.min(
                    math.abs(timeToTarget - t_below),
                    math.abs(timeToTarget - t_above)
                )
                table.insert(deltaTimes, {deltaT, triedPitch, deltaT + timeToTarget})

                ::continue::
            end
            if #deltaTimes == 0 then
                OutOfRangeException("The target is unreachable with your current cannon configuration!")
            end

            -- Find tuple with minimum deltaT
            local minIndex = 1
            for i = 2, #deltaTimes do
                if deltaTimes[i][1] < deltaTimes[minIndex][1] then
                    minIndex = i
                end
            end
            return table.unpack(deltaTimes[minIndex])
        end

        -- Initial brute force search
        local deltaTime1, pitch1, airtime1, deltaTime2, pitch2, airtime2
        local r1, r2 = tryAllAngles(-30, 60, 91)
        deltaTime1, pitch1, airtime1 = r1[1], r1[2], r1[3]
        deltaTime2, pitch2, airtime2 = r2[1], r2[2], r2[3]

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

        -- Direction adjustment
        if direction == "north" then
            yaw = (yaw + 90) % 360
        elseif direction == "west" then
            yaw = (yaw + 180) % 360
        elseif direction == "south" then
            yaw = (yaw + 270) % 360
        elseif direction ~= "east" then
            return "Invalid direction"
        end

        -- Fuze and precision
        local fuzeTime1 = math.floor(airtime1 + (deltaTime1 / 2) - 10)
        local fuzeTime2 = math.floor(airtime2 + (deltaTime2 / 2) - 10)
        local precision1 = math.floor((1 - deltaTime1 / airtime1) * 100 + 0.5)
        local precision2 = math.floor((1 - deltaTime2 / airtime2) * 100 + 0.5)

        return {
            {yaw, pitch1, airtime1, math.floor(airtimeSeconds1 * 100) / 100, fuzeTime1, precision1},
            {yaw, pitch2, airtime2, math.floor(airtimeSeconds2 * 100) / 100, fuzeTime2, precision2}
        }
    end

    local cannonPos = cannon

    --print("Loaded successfully")

    print("")

    print("Loaded cannon data:")
    print("Cannon position: " .. cannonPos[1] .. ", " .. cannonPos[2] .. ", " .. cannonPos[3])
    print("Cannon charges: " .. power)
    print("Cannon direction: " .. direction)
    print("Cannon barrel length: " .. length_)

    print("")

    local targetPos = target



    local ballisticsData = BallisticsToTarget(cannonPos, targetPos, power, direction, length_)
    local validShots = {}

    for i = 1, 2 do
        local pitch = ballisticsData[i][2]
        if pitch ~= "Over 60" and pitch ~= "Under -30" then
            table.insert(validShots, {index = i, precision = ballisticsData[i][6]})
        end
    end

    if #validShots == 0 then
        print("No valid shots found. Input another target")
        modem.transmit(6505, 6505, "noValidShots")
    else
        -- Find the shot with the highest precision
        table.sort(validShots, function(a, b) return a.precision > b.precision end)
        local bestShotIndex = validShots[1].index
        local shot = ballisticsData[bestShotIndex]

        print("Using shot " .. bestShotIndex)
        print("Yaw: " .. shot[1])
        print("Pitch: " .. shot[2])
        print("Airtime: " .. shot[3])
        print("Prescision: " .. shot[6] .. "%")

        pitchControl(shot[2])
        yawControl(shot[1])
        sleep(0.5)
        print("Firing")

        redstone.setOutput("bottom", true)
        sleep(0.1)
        redstone.setOutput("bottom", false)
        modem.transmit(6505, 6505, "fireConfirm")
    end

end
return {ballistics = ballistics}
