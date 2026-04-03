-- 🤫 SILENT AIM WALLBANG + AUTO REJOIN SI NADIE SE MUEVE (muertes cuentan como actividad)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local remote = ReplicatedStorage
    :WaitForChild("SystemResources")
    :WaitForChild("BufferCache")
    :WaitForChild("RequestActionSync")

getgenv().SILENT_AIM = true

local MOVE_DISTANCE = 5 -- studs mínimos
local CHECK_TIME = 10 -- segundos

local function getCharacter(plr)
    return plr.Character or plr.CharacterAdded:Wait()
end

local function getRoot(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- 🔥 jugador más cercano sin importar paredes
local function getClosestPlayer()
    local myChar = getCharacter(LocalPlayer)
    local myRoot = getRoot(myChar)
    if not myRoot then return nil end

    local closest = nil
    local shortest = math.huge

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChild("Humanoid")
            local head = plr.Character:FindFirstChild("Head")
            local root = getRoot(plr.Character)

            if hum and hum.Health > 0 and head and root then
                local dist = (root.Position - myRoot.Position).Magnitude

                if dist < shortest then
                    shortest = dist
                    closest = plr
                end
            end
        end
    end

    return closest
end

local function fireSilentShot()
    if not getgenv().SILENT_AIM then return end

    local myChar = getCharacter(LocalPlayer)
    local myRoot = getRoot(myChar)
    local target = getClosestPlayer()

    if not myRoot or not target then return end

    local head = target.Character:FindFirstChild("Head")
    local hum = target.Character:FindFirstChild("Humanoid")
    if not head or not hum then return end

    local origin = myRoot.Position
    local hitPos = head.Position
    local dir = (hitPos - origin).Unit

    remote:FireServer({
        direction = dir,
        hitPosition = hitPos,
        origin = origin,
        IsHeadshot = true,
        hitHumanoid = hum,
        hitInstance = head
    })
end

-- 🔥 loop silent aim
task.spawn(function()
    while true do
        task.wait(0.6)
        fireSilentShot()
    end
end)

-- 📍 guardar posiciones iniciales
local lastPositions = {}

local function savePositions()
    for _, plr in pairs(Players:GetPlayers()) do
        local char = plr.Character
        local root = getRoot(char)

        if root then
            lastPositions[plr] = root.Position
        end
    end
end

savePositions()

-- 🔄 detector de movimiento global
task.spawn(function()
    while true do
        task.wait(CHECK_TIME)

        local activityDetected = false

        for _, plr in pairs(Players:GetPlayers()) do
            local char = plr.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local root = getRoot(char)

            -- si el jugador murió, contar como actividad
            if hum and hum.Health <= 0 then
                activityDetected = true
            elseif root then
                local oldPos = lastPositions[plr]
                if oldPos then
                    local moved = (root.Position - oldPos).Magnitude
                    if moved >= MOVE_DISTANCE then
                        activityDetected = true
                    end
                end
                lastPositions[plr] = root.Position
            end
        end

        if not activityDetected then
            TeleportService:Teleport(PlaceId, LocalPlayer)
        end
    end
end)
