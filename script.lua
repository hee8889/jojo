local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

--==================================================
--              AUTO EXECUTE SETUP
-- เซฟ script ลง autoexec ให้รันอัตโนมัติทุกครั้ง
--==================================================
local SCRIPT_URL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/" -- เปลี่ยนเป็น URL script จริงของคุณ
local AUTOEXEC_SCRIPT = [[
-- Baramee Hub Auto Execute
loadstring(game:HttpGet("]] .. SCRIPT_URL .. [["))()
]]

pcall(function()
    -- สร้าง autoexec folder ถ้ายังไม่มี
    if not isfolder("autoexec") then
        makefolder("autoexec")
    end
    -- เซฟ script
    writefile("autoexec/BarameeHub.lua", AUTOEXEC_SCRIPT)
    print("✓ Auto Execute ถูกเซฟแล้ว")
end)

local Window = Library:CreateWindow({
    Title            = "Baramee Hub",
    Center           = true,
    AutoShow         = true,
    ShowCustomCursor = true,
    NotifySide       = "Right",
})

local Tabs = {
    General  = Window:AddTab("General",     "user"),
    Combat   = Window:AddTab("Combat",      "sword"),
    Settings = Window:AddTab("UI Settings", "settings"),
}

local GenBox    = Tabs.General:AddLeftGroupbox("General")
local AutoBox   = Tabs.General:AddRightGroupbox("Auto Play")
local CombatBox = Tabs.Combat:AddLeftGroupbox("Combat")
local SkillBox  = Tabs.Combat:AddRightGroupbox("Auto Skill")

local flags = {
    ESP                = false,
    NOCLIP             = false,
    FLY                = false,
    FLYSpeed           = 40,
    RUN                = false,
    RUNSpeed           = 20,
    StickFollow        = false,
    StickDist          = 3,
    AutoAtk            = false,
    AtkDelay           = 5,
    AutoSkill          = false,
    SkillDelay         = 5,
    UseE               = true,
    UseR               = true,
    UseZ               = true,
    UseX               = true,
    UseC               = true,
    AutoNearest        = false,
    NearestDist        = 6,
    NearestAtkDelay    = 5,
    NearestDetectRange = 100,
    AutoPlay           = false,
    AutoPlayDelay      = 1,
}

--==================================================
--                    ESP SYSTEM
--==================================================
local ESPObjects    = {}
local ESPConnection = nil

local function createESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end
    local bb = Instance.new("BillboardGui")
    bb.Name        = "ESP"
    bb.Size        = UDim2.fromOffset(200, 60)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3             = Color3.new(1, 1, 1)
    lbl.TextStrokeTransparency = 0
    lbl.TextScaled             = true
    lbl.Font                   = Enum.Font.SourceSansBold
    lbl.Parent                 = bb
    ESPObjects[player] = { Gui = bb, Label = lbl }
end

local function removeESP(player)
    if ESPObjects[player] then
        ESPObjects[player].Gui:Destroy()
        ESPObjects[player] = nil
    end
end

local function startESP()
    ESPConnection = RunService.RenderStepped:Connect(function()
        for p, d in pairs(ESPObjects) do
            local char = p.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                d.Gui.Parent = hrp
                local dist = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)
                d.Label.Text = p.Name.."\n["..math.floor(hum.Health).."/"..math.floor(hum.MaxHealth).."]\n"..dist.."m"
            else
                d.Gui.Parent = nil
            end
        end
    end)
end

local function stopESP()
    if ESPConnection then ESPConnection:Disconnect(); ESPConnection = nil end
    for p in pairs(ESPObjects) do removeESP(p) end
end

Players.PlayerAdded:Connect(function(p) if flags.ESP then createESP(p) end end)
Players.PlayerRemoving:Connect(removeESP)

task.spawn(function()
    while task.wait() do
        if flags.ESP then
            if not ESPConnection then
                for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
                startESP()
            end
        else stopESP() end
    end
end)

--==================================================
--                    FLY SYSTEM
--==================================================
local Flying = false
local AlignOri, LinVel, FlyAttach
local MoveVec = Vector3.zero
local Ctrl = { F=0, B=0, L=0, R=0, U=0, D=0 }

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.W           then Ctrl.F =  1 end
    if i.KeyCode == Enum.KeyCode.S           then Ctrl.B = -1 end
    if i.KeyCode == Enum.KeyCode.A           then Ctrl.L = -1 end
    if i.KeyCode == Enum.KeyCode.D           then Ctrl.R =  1 end
    if i.KeyCode == Enum.KeyCode.Space       then Ctrl.U =  1 end
    if i.KeyCode == Enum.KeyCode.LeftControl then Ctrl.D = -1 end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.W           then Ctrl.F = 0 end
    if i.KeyCode == Enum.KeyCode.S           then Ctrl.B = 0 end
    if i.KeyCode == Enum.KeyCode.A           then Ctrl.L = 0 end
    if i.KeyCode == Enum.KeyCode.D           then Ctrl.R = 0 end
    if i.KeyCode == Enum.KeyCode.Space       then Ctrl.U = 0 end
    if i.KeyCode == Enum.KeyCode.LeftControl then Ctrl.D = 0 end
end)

local function stopFly()
    Flying = false
    if AlignOri  then AlignOri:Destroy();  AlignOri  = nil end
    if LinVel    then LinVel:Destroy();    LinVel    = nil end
    if FlyAttach then FlyAttach:Destroy(); FlyAttach = nil end
end

local function startFly()
    stopFly()
    local char = LocalPlayer.Character; if not char then return end
    local hrp  = char:WaitForChild("HumanoidRootPart")
    FlyAttach = Instance.new("Attachment"); FlyAttach.Parent = hrp
    AlignOri  = Instance.new("AlignOrientation")
    AlignOri.Attachment0    = FlyAttach
    AlignOri.Mode           = Enum.OrientationAlignmentMode.OneAttachment
    AlignOri.Responsiveness = 15
    AlignOri.MaxTorque      = 30000
    AlignOri.Parent         = hrp
    LinVel            = Instance.new("LinearVelocity")
    LinVel.Attachment0 = FlyAttach
    LinVel.RelativeTo  = Enum.ActuatorRelativeTo.World
    LinVel.MaxForce    = 25000
    LinVel.Parent      = hrp
    Flying = true
end

RunService.RenderStepped:Connect(function()
    if not Flying then return end
    if not flags.FLY then stopFly(); return end
    AlignOri.CFrame = Camera.CFrame
    local dir = Camera.CFrame.LookVector  * (Ctrl.F + Ctrl.B)
              + Camera.CFrame.RightVector * (Ctrl.R + Ctrl.L)
              + Vector3.new(0, Ctrl.U + Ctrl.D, 0)
    MoveVec = MoveVec:Lerp(dir * (flags.FLYSpeed or 40), 0.15)
    LinVel.VectorVelocity = MoveVec
end)

task.spawn(function()
    while task.wait(0.2) do
        if flags.FLY and not Flying then startFly()
        elseif not flags.FLY and Flying then stopFly() end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    stopFly(); task.wait(0.5)
    if flags.FLY then startFly() end
end)

--==================================================
--                 NOCLIP SYSTEM
--==================================================
local NoclipConn, Noclipping = nil, false
local ColCache = {}

local function cacheCol(c)
    ColCache = {}
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then ColCache[p] = p.CanCollide end
    end
end
local function enableNC(c)
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end
local function disableNC()
    for p, v in pairs(ColCache) do
        if p and p.Parent then p.CanCollide = v end
    end
    ColCache = {}
end

local function startNoclip()
    if Noclipping then return end
    local c = LocalPlayer.Character; if not c then return end
    cacheCol(c); enableNC(c); Noclipping = true
    NoclipConn = RunService.Stepped:Connect(function()
        local ch = LocalPlayer.Character; if not ch then return end
        local h  = ch:FindFirstChildOfClass("Humanoid")
        if not h or h.Health <= 0 then return end
        enableNC(ch)
    end)
end

local function stopNoclip()
    Noclipping = false
    if NoclipConn then NoclipConn:Disconnect(); NoclipConn = nil end
    disableNC()
end

task.spawn(function()
    while task.wait() do
        if flags.NOCLIP then if not Noclipping then startNoclip() end
        else if Noclipping then stopNoclip() end end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(c)
    local h = c:WaitForChild("Humanoid"); h.Died:Connect(stopNoclip)
    task.wait(0.5); if flags.NOCLIP then startNoclip() end
end)

--==================================================
--                  RUN SYSTEM
--==================================================
local RunConn, Running = nil, false
local DefSpeed, CurHum = 16, nil

local function applySpeed()
    if CurHum then CurHum.WalkSpeed = flags.RUNSpeed or DefSpeed end
end

local function startRun()
    if Running then return end
    local c = LocalPlayer.Character; if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid"); if not h then return end
    CurHum = h; DefSpeed = h.WalkSpeed; Running = true; applySpeed()
    RunConn = RunService.Stepped:Connect(function()
        if not flags.RUN or h.Health <= 0 then return end
        applySpeed()
    end)
end

local function stopRun()
    Running = false
    if RunConn then RunConn:Disconnect(); RunConn = nil end
    if CurHum then CurHum.WalkSpeed = DefSpeed end
end

task.spawn(function()
    while task.wait() do
        if flags.RUN then if not Running then startRun() end
        else if Running then stopRun() end end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(c)
    local h = c:WaitForChild("Humanoid"); CurHum = h; DefSpeed = h.WalkSpeed
    h.Died:Connect(stopRun); task.wait(0.3)
    if flags.RUN then startRun() end
end)

--==================================================
--              HELPER FUNCTIONS
--==================================================
local function pressKey(keyCode)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyEvent(true,  keyCode, false, game)
        task.wait(0.05)
        vim:SendKeyEvent(false, keyCode, false, game)
    end)
end

local function clickM1()
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(0, 0, 0, true,  game, 0)
        task.wait(0.05)
        vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end

local function pressEnter()
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyEvent(true,  Enum.KeyCode.Return, false, game)
        task.wait(0.05)
        vim:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    end)
end

local function spamAllSkills()
    if flags.UseE then pressKey(Enum.KeyCode.E) end
    if flags.UseR then pressKey(Enum.KeyCode.R) end
    if flags.UseZ then pressKey(Enum.KeyCode.Z) end
    if flags.UseX then pressKey(Enum.KeyCode.X) end
    if flags.UseC then pressKey(Enum.KeyCode.C) end
end

--==================================================
--              COMBAT VARIABLES
--==================================================
local SelectedTarget  = nil
local StickConn       = nil
local AutoAtkActive   = false
local AutoSkillActive = false
local npcList         = {}
local FilterDist      = nil

local function getTargetData()
    if not SelectedTarget then return nil, nil end
    local live = workspace:FindFirstChild("Live"); if not live then return nil, nil end
    local tgt  = live:FindFirstChild(SelectedTarget); if not tgt then return nil, nil end
    return tgt:FindFirstChildOfClass("Humanoid"), tgt:FindFirstChild("HumanoidRootPart")
end

local function isTargetAlive()
    local hum, _ = getTargetData()
    return hum and hum.Health > 0
end

local function getNearestNPC()
    local live = workspace:FindFirstChild("Live"); if not live then return nil end
    local myChar = LocalPlayer.Character; if not myChar then return nil end
    local myHRP  = myChar:FindFirstChild("HumanoidRootPart"); if not myHRP then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, obj in ipairs(live:GetChildren()) do
        if obj:IsA("Model")
            and obj ~= myChar
            and obj.Name ~= LocalPlayer.Name
        then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (myHRP.Position - hrp.Position).Magnitude
                if d < nearestDist and d <= (flags.NearestDetectRange or 100) then
                    nearestDist = d
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

--==================================================
--                   GENERAL UI
--==================================================
GenBox:AddToggle("ESP",    { Text = "ESP",       Default = false, Callback = function(v) flags.ESP    = v end })
GenBox:AddToggle("NOCLIP", { Text = "Noclip",    Default = false, Callback = function(v) flags.NOCLIP = v end })
GenBox:AddToggle("FLY",    { Text = "Fly",       Default = false, Callback = function(v) flags.FLY    = v end })
GenBox:AddSlider("FLYSpeed",  { Text = "Fly Speed", Default = 40,  Min = 10, Max = 1000, Rounding = 0, Callback = function(v) flags.FLYSpeed  = v end })
GenBox:AddToggle("RUN",    { Text = "Speed Run", Default = false, Callback = function(v) flags.RUN    = v end })
GenBox:AddSlider("RUNSpeed",  { Text = "Run Speed", Default = 20,  Min = 10, Max = 1000, Rounding = 0, Callback = function(v) flags.RUNSpeed  = v end })

--==================================================
--                   AUTO PLAY UI
--==================================================
AutoBox:AddToggle("AutoPlay", {
    Text = "🔄 Auto Play Again", Default = false,
    Tooltip = "กด Quick Play และ Play Again อัตโนมัติ",
    Callback = function(v)
        flags.AutoPlay = v
        Library:Notify(v and "Auto Play เปิดแล้ว" or "Auto Play ปิดแล้ว", 2)
    end,
})
AutoBox:AddSlider("AutoPlayDelay", {
    Text = "Delay ก่อนกด (วินาที)", Default = 1, Min = 0, Max = 5, Rounding = 1,
    Callback = function(v) flags.AutoPlayDelay = v end,
})
AutoBox:AddDivider()

-- ปุ่มจัดการ Auto Execute
AutoBox:AddButton({
    Text = "💾 บันทึก Auto Execute",
    Tooltip = "เซฟ script ลง autoexec ให้รันอัตโนมัติทุกครั้งที่เปิด executor",
    Func = function()
        pcall(function()
            if not isfolder("autoexec") then makefolder("autoexec") end
            local scriptContent = 'loadstring(game:HttpGet("https://github.com/hee8889/jojo/blob/main/script.lua"))()'
            writefile("autoexec/BarameeHub.lua", scriptContent)
            Library:Notify("✓ บันทึก Auto Execute แล้ว\nจะรัน script อัตโนมัติทุกครั้ง", 4)
        end)
    end,
})
AutoBox:AddButton({
    Text = "🗑️ ลบ Auto Execute",
    Func = function()
        pcall(function()
            if isfile("autoexec/BarameeHub.lua") then
                delfile("autoexec/BarameeHub.lua")
                Library:Notify("✓ ลบ Auto Execute แล้ว", 3)
            else
                Library:Notify("ไม่พบไฟล์ Auto Execute", 3)
            end
        end)
    end,
})

-- Auto Play Loop
task.spawn(function()
    local pgui = LocalPlayer:WaitForChild("PlayerGui")
    while task.wait(0.5) do
        if not flags.AutoPlay then continue end

        -- กด Quick Play
        local mm = pgui:FindFirstChild("Main Menu")
        if mm and mm.Enabled then
            local buttons = mm:FindFirstChild("Buttons")
            local btn = buttons and buttons:FindFirstChild("Quick Play")
            if btn and btn.Visible then
                task.wait(flags.AutoPlayDelay or 1)
                GuiService.SelectedObject = btn
                task.wait(0.1)
                pressEnter()
                print("✓ กด Quick Play แล้ว")
                Library:Notify("✓ กด Quick Play แล้ว", 2)
                continue
            end
        end

        -- กด Play Again
        local rc = pgui:FindFirstChild("raidcomplete")
        if rc and rc.Enabled then
            local raid = rc:FindFirstChild("raid")
            local btn  = raid and raid:FindFirstChild("retry")
            if btn and btn.Visible then
                task.wait(flags.AutoPlayDelay or 1)
                GuiService.SelectedObject = btn
                task.wait(0.1)
                pressEnter()
                print("✓ กด Play Again แล้ว")
                Library:Notify("✓ กด Play Again แล้ว", 2)
                continue
            end
        end
    end
end)

--==================================================
--                   COMBAT UI
--==================================================
CombatBox:AddSlider("FilterDist", {
    Text = "กรองระยะ (studs, 0 = ทั้งหมด)", Default = 0, Min = 0, Max = 500, Rounding = 0,
    Callback = function(v) FilterDist = v <= 0 and nil or v end,
})

CombatBox:AddDropdown("TargetDrop", {
    Text = "🎯 เลือกเป้าหมาย", Values = { "(กด Refresh ก่อน)" },
    Default = 1, Multi = false, Searchable = true,
    Callback = function(v)
        if v ~= "(กด Refresh ก่อน)" and v ~= "(ไม่พบ NPC)" then
            SelectedTarget = v
            print("🎯 เป้า: " .. v)
        end
    end,
})

local function loadNPCList(maxDist)
    npcList = {}
    local live = workspace:FindFirstChild("Live")
    if not live then Library:Notify("ไม่พบ Live folder!", 3); return end
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    for _, obj in ipairs(live:GetChildren()) do
        if obj:IsA("Model")
            and obj ~= myChar
            and obj.Name ~= LocalPlayer.Name
        then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if maxDist and myHRP and hrp then
                if (myHRP.Position - hrp.Position).Magnitude <= maxDist then
                    table.insert(npcList, obj.Name)
                end
            elseif not maxDist then
                table.insert(npcList, obj.Name)
            end
        end
    end
    local opts = #npcList > 0 and npcList or { "(ไม่พบ NPC)" }
    Options.TargetDrop:SetValues(opts)
    Options.TargetDrop:SetValue(opts[1])
    SelectedTarget = npcList[1] or nil
    Library:Notify("โหลด NPC "..#npcList.." ตัว\nเป้า: "..(SelectedTarget or "ไม่พบ"), 3)
end

CombatBox:AddButton({ Text = "🔄 Refresh รายชื่อ NPC", Func = function() loadNPCList(FilterDist) end })
CombatBox:AddDivider()

CombatBox:AddToggle("StickFollow", { Text = "ติดบนหัวเป้าตลอดเวลา", Default = false, Callback = function(v) flags.StickFollow = v end })
CombatBox:AddSlider("StickDist",   { Text = "ระยะสูงเหนือหัว (studs)", Default = 3, Min = 0, Max = 20, Rounding = 1, Callback = function(v) flags.StickDist = v end })
CombatBox:AddDivider()

CombatBox:AddToggle("AutoAtk", { Text = "Auto Attack (M1 Spam)", Default = false, Callback = function(v) flags.AutoAtk = v end })
CombatBox:AddSlider("AtkDelay", { Text = "M1 Delay (x0.01s)", Default = 5, Min = 1, Max = 50, Rounding = 0, Callback = function(v) flags.AtkDelay = v end })
CombatBox:AddLabel("Toggle Auto Attack"):AddKeyPicker("AutoAtkBind", {
    Default = "RightShift", Mode = "Toggle", Text = "Toggle Auto Attack", NoUI = false,
    Callback = function(v) flags.AutoAtk = v; Toggles.AutoAtk:SetValue(v) end,
})
CombatBox:AddDivider()

CombatBox:AddToggle("AutoNearest", { Text = "⚡ Auto ตีใกล้สุด (All-in-One)", Default = false, Callback = function(v) flags.AutoNearest = v end })
CombatBox:AddSlider("NearestDetectRange", { Text = "ระยะ Detect NPC (studs)", Default = 100, Min = 10, Max = 500, Rounding = 0, Callback = function(v) flags.NearestDetectRange = v end })
CombatBox:AddSlider("NearestDist",        { Text = "ระยะสูงเหนือหัว (studs)", Default = 6,   Min = 1,  Max = 20,  Rounding = 1, Callback = function(v) flags.NearestDist = v end })
CombatBox:AddSlider("NearestAtkDelay",    { Text = "Attack Delay (x0.01s)",    Default = 5,   Min = 1,  Max = 50,  Rounding = 0, Callback = function(v) flags.NearestAtkDelay = v end })

--==================================================
--                   SKILL UI
--==================================================
SkillBox:AddToggle("AutoSkill",  { Text = "Auto Use Skills",          Default = false, Callback = function(v) flags.AutoSkill = v end })
SkillBox:AddSlider("SkillDelay", { Text = "Skill Loop Delay (x0.1s)", Default = 5, Min = 1, Max = 50, Rounding = 0, Callback = function(v) flags.SkillDelay = v end })
SkillBox:AddDivider()
SkillBox:AddToggle("UseE", { Text = "Use E", Default = true, Callback = function(v) flags.UseE = v end })
SkillBox:AddToggle("UseR", { Text = "Use R", Default = true, Callback = function(v) flags.UseR = v end })
SkillBox:AddToggle("UseZ", { Text = "Use Z", Default = true, Callback = function(v) flags.UseZ = v end })
SkillBox:AddToggle("UseX", { Text = "Use X", Default = true, Callback = function(v) flags.UseX = v end })
SkillBox:AddToggle("UseC", { Text = "Use C", Default = true, Callback = function(v) flags.UseC = v end })

--==================================================
--              STICK LOGIC
--==================================================
local function startStick()
    if StickConn then StickConn:Disconnect() end
    StickConn = RunService.Heartbeat:Connect(function()
        if not flags.StickFollow then StickConn:Disconnect(); StickConn = nil; return end
        local _, tHRP = getTargetData(); if not tHRP then return end
        local myChar = LocalPlayer.Character; if not myChar then return end
        local myHRP  = myChar:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
        local abovePos = tHRP.Position + Vector3.new(0, flags.StickDist, 0)
        myHRP.CFrame = CFrame.lookAt(abovePos, tHRP.Position)
    end)
end

local function stopStick()
    if StickConn then StickConn:Disconnect(); StickConn = nil end
end

task.spawn(function()
    while task.wait() do
        if flags.StickFollow then if not StickConn then startStick() end
        else stopStick() end
    end
end)

--==================================================
--         AUTO ATTACK (M1 Spam)
--==================================================
task.spawn(function()
    while task.wait() do
        if flags.AutoAtk then
            if not AutoAtkActive then
                AutoAtkActive = true
                task.spawn(function()
                    while AutoAtkActive and flags.AutoAtk do
                        if not isTargetAlive() then
                            Toggles.AutoAtk:SetValue(false); flags.AutoAtk = false; break
                        end
                        clickM1()
                        task.wait((flags.AtkDelay or 5) * 0.01)
                    end
                    AutoAtkActive = false
                end)
            end
        else AutoAtkActive = false end
    end
end)

--==================================================
--         AUTO SKILL (E R Z X C)
--==================================================
task.spawn(function()
    while task.wait() do
        if flags.AutoSkill then
            if not AutoSkillActive then
                AutoSkillActive = true
                task.spawn(function()
                    while AutoSkillActive and flags.AutoSkill do
                        if not isTargetAlive() then
                            Toggles.AutoSkill:SetValue(false); flags.AutoSkill = false; break
                        end
                        spamAllSkills()
                        task.wait((flags.SkillDelay or 5) * 0.1)
                    end
                    AutoSkillActive = false
                end)
            end
        else AutoSkillActive = false end
    end
end)

--==================================================
--   ⚡ AUTO NEAREST - ติดบนหัวตลอด + Tab + M1 + Skill
--==================================================
RunService.Heartbeat:Connect(function()
    if not flags.AutoNearest then return end
    local tgt = getNearestNPC(); if not tgt then return end
    local tHRP = tgt:FindFirstChild("HumanoidRootPart"); if not tHRP then return end
    local hum  = tgt:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local myChar = LocalPlayer.Character; if not myChar then return end
    local myHRP  = myChar:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
    local abovePos = tHRP.Position + Vector3.new(0, flags.NearestDist, 0)
    myHRP.CFrame = CFrame.lookAt(abovePos, tHRP.Position)
end)

task.spawn(function()
    local tabOpened = false      -- เช็คว่ากด Tab เปิดไปแล้วหรือยัง
    local lastTarget = nil       -- จำเป้าหมายล่าสุด

    while task.wait() do
        if not flags.AutoNearest then
            -- ถ้าปิด AutoNearest และ Tab เปิดอยู่ ให้กด Tab ปิด
            if tabOpened then
                pressKey(Enum.KeyCode.Tab)
                tabOpened = false
                lastTarget = nil
            end
            continue
        end

        local tgt = getNearestNPC()
        local hum = tgt and tgt:FindFirstChildOfClass("Humanoid")
        local alive = tgt and hum and hum.Health > 0

        if alive then
            -- เป้าใหม่หรือยังไม่เคยกด Tab → กด Tab เปิด
            if not tabOpened or lastTarget ~= tgt then
                pressKey(Enum.KeyCode.Tab)
                task.wait(0.1)
                tabOpened = true
                lastTarget = tgt
            end
            -- M1 + Skill
            clickM1()
            spamAllSkills()
            task.wait((flags.NearestAtkDelay or 5) * 0.01)
        else
            -- เป้าตายแล้ว → กด Tab ปิด
            if tabOpened then
                pressKey(Enum.KeyCode.Tab)
                task.wait(0.1)
                tabOpened = false
                lastTarget = nil
            end
            task.wait(0.2)
        end
    end
end)

--==================================================
--                   UI SETTINGS
--==================================================
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(v) Library.KeybindFrame.Visible = v end })
MenuGroup:AddToggle("ShowCustomCursor", { Text = "Custom Cursor", Default = true, Callback = function(v) Library.ShowCustomCursor = v end })
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "End", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton({ Text = "Unload", Func = function() Library:Unload() end })

Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("BarameeHub")
SaveManager:SetFolder("BarameeHub/game")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

-- ✅ โหลด config ที่ mark autoload ไว้ → เปิด toggle ที่เคย save ไว้อัตโนมัติ
SaveManager:LoadAutoloadConfig()

-- ✅ หลังโหลด config แล้ว sync flags ให้ตรงกับ Toggles
task.wait(1)
flags.AutoPlay    = Toggles.AutoPlay    and Toggles.AutoPlay.Value    or false
flags.AutoNearest = Toggles.AutoNearest and Toggles.AutoNearest.Value or false
if flags.AutoPlay    then Library:Notify("✓ Auto Play เปิดอัตโนมัติจาก config", 3) end
if flags.AutoNearest then Library:Notify("✓ Auto Nearest เปิดอัตโนมัติจาก config", 3) end

task.spawn(function()
    task.wait(3)
    loadNPCList(nil)
end)

print("✓ Baramee Hub Loaded!")
