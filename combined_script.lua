--[[
    Combined Script
    - Universal Aimbot (Exunys © CC0 1.0 Universal)
    - Universal ESP (WA)
    - Auto-Click (by reIax)
]]

-- ============================================================
-- SHARED CACHE & SERVICES
-- ============================================================

local game, workspace = game, workspace
local getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick =
    getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick
local Vector2new, Vector3zero, CFramenew, Color3fromRGB, Color3fromHSV, Drawingnew, TweenInfonew =
    Vector2.new, Vector3.zero, CFrame.new, Color3.fromRGB, Color3.fromHSV, Drawing.new, TweenInfo.new
local getupvalue, mousemoverel, tablefind, tableremove, stringlower, stringsub, mathclamp =
    debug.getupvalue, mousemoverel or (Input and Input.MouseMove),
    table.find, table.remove, string.lower, string.sub, math.clamp

local GameMetatable = getrawmetatable and getrawmetatable(game) or {
    __index    = function(self, i) return self[i] end,
    __newindex = function(self, i, v) self[i] = v end
}
local __index    = GameMetatable.__index
local __newindex = GameMetatable.__newindex
local getrenderproperty = getrenderproperty or __index
local setrenderproperty = setrenderproperty or __newindex
local GetService = __index(game, "GetService")

local RunService       = GetService(game, "RunService")
local UserInputService = GetService(game, "UserInputService")
local TweenService     = GetService(game, "TweenService")
local Players          = GetService(game, "Players")

local LocalPlayer = __index(Players, "LocalPlayer")
local Camera      = __index(workspace, "CurrentCamera")

local FindFirstChild       = __index(game, "FindFirstChild")
local FindFirstChildOfClass = __index(game, "FindFirstChildOfClass")
local GetDescendants       = __index(game, "GetDescendants")
local WorldToViewportPoint = __index(Camera, "WorldToViewportPoint")
local GetPartsObscuringTarget = __index(Camera, "GetPartsObscuringTarget")
local GetMouseLocation     = __index(UserInputService, "GetMouseLocation")
local GetPlayers           = __index(Players, "GetPlayers")

local Connect    = __index(game, "DescendantAdded").Connect
local Disconnect

do
    local tmp = Connect(__index(game, "DescendantAdded"), function() end)
    Disconnect = tmp.Disconnect
    Disconnect(tmp)
end

-- ============================================================
-- AIMBOT
-- ============================================================

local RequiredDistance, Typing, Running, ServiceConnections, Animation, OriginalSensitivity =
    2000, false, false, {}

if getgenv().ExunysDeveloperAimbot and getgenv().ExunysDeveloperAimbot.Exit then
    getgenv().ExunysDeveloperAimbot:Exit()
end

getgenv().ExunysDeveloperAimbot = {
    DeveloperSettings = {
        UpdateMode    = "RenderStepped",
        TeamCheckOption = "TeamColor",
        RainbowSpeed  = 1
    },
    Settings = {
        Enabled            = true,
        TeamCheck          = false,
        AliveCheck         = true,
        WallCheck          = false,
        OffsetToMoveDirection = false,
        OffsetIncrement    = 15,
        Sensitivity        = 0,
        Sensitivity2       = 3.5,
        LockMode           = 1,
        LockPart           = "Head",
        TriggerKey         = Enum.UserInputType.MouseButton2,
        Toggle             = false
    },
    FOVSettings = {
        Enabled          = true,
        Visible          = true,
        Radius           = 90,
        NumSides         = 60,
        Thickness        = 1,
        Transparency     = 1,
        Filled           = false,
        RainbowColor     = false,
        RainbowOutlineColor = false,
        Color            = Color3fromRGB(255, 255, 255),
        OutlineColor     = Color3fromRGB(0, 0, 0),
        LockedColor      = Color3fromRGB(255, 150, 150)
    },
    Blacklisted      = {},
    FOVCircleOutline = Drawingnew("Circle"),
    FOVCircle        = Drawingnew("Circle")
}

local AimbotEnv = getgenv().ExunysDeveloperAimbot
setrenderproperty(AimbotEnv.FOVCircle,        "Visible", false)
setrenderproperty(AimbotEnv.FOVCircleOutline, "Visible", false)

local function FixUsername(String)
    local Result
    for _, v in next, GetPlayers(Players) do
        local Name = __index(v, "Name")
        if stringsub(stringlower(Name), 1, #String) == stringlower(String) then
            Result = Name
        end
    end
    return Result
end

local function GetRainbowColor()
    local s = AimbotEnv.DeveloperSettings.RainbowSpeed
    return Color3fromHSV(tick() % s / s, 1, 1)
end

local function ConvertVector(v)
    return Vector2new(v.X, v.Y)
end

local function CancelLock()
    AimbotEnv.Locked = nil
    setrenderproperty(AimbotEnv.FOVCircle, "Color", AimbotEnv.FOVSettings.Color)
    __newindex(UserInputService, "MouseDeltaSensitivity", OriginalSensitivity)
    if Animation then Animation:Cancel() end
end

local function GetClosestPlayer()
    local S, LP = AimbotEnv.Settings, AimbotEnv.Settings.LockPart
    if not AimbotEnv.Locked then
        RequiredDistance = AimbotEnv.FOVSettings.Enabled and AimbotEnv.FOVSettings.Radius or 2000
        for _, v in next, GetPlayers(Players) do
            local Char = __index(v, "Character")
            local Hum  = Char and FindFirstChildOfClass(Char, "Humanoid")
            if v ~= LocalPlayer
                and not tablefind(AimbotEnv.Blacklisted, __index(v, "Name"))
                and Char and FindFirstChild(Char, LP) and Hum then
                local Pos = __index(Char[LP], "Position")
                local TCO = AimbotEnv.DeveloperSettings.TeamCheckOption
                if S.TeamCheck and __index(v, TCO) == __index(LocalPlayer, TCO) then continue end
                if S.AliveCheck and __index(Hum, "Health") <= 0 then continue end
                if S.WallCheck then
                    local BL = GetDescendants(__index(LocalPlayer, "Character"))
                    for _, p in next, GetDescendants(Char) do BL[#BL+1] = p end
                    if #GetPartsObscuringTarget(Camera, {Pos}, BL) > 0 then continue end
                end
                local Vec, OnScreen = WorldToViewportPoint(Camera, Pos)
                Vec = ConvertVector(Vec)
                local Dist = (GetMouseLocation(UserInputService) - Vec).Magnitude
                if Dist < RequiredDistance and OnScreen then
                    RequiredDistance, AimbotEnv.Locked = Dist, v
                end
            end
        end
    elseif (GetMouseLocation(UserInputService) - ConvertVector(WorldToViewportPoint(Camera,
        __index(__index(__index(AimbotEnv.Locked, "Character"), LP), "Position")))).Magnitude > RequiredDistance then
        CancelLock()
    end
end

local function LoadAimbot()
    OriginalSensitivity = __index(UserInputService, "MouseDeltaSensitivity")
    local S, FC, FCO, FS = AimbotEnv.Settings, AimbotEnv.FOVCircle, AimbotEnv.FOVCircleOutline, AimbotEnv.FOVSettings

    ServiceConnections.RenderSteppedConnection = Connect(__index(RunService, AimbotEnv.DeveloperSettings.UpdateMode), function()
        local OffDir, LP = S.OffsetToMoveDirection, S.LockPart
        if FS.Enabled and S.Enabled then
            for Idx, Val in next, FS do
                if Idx == "Color" then continue end
                if pcall(getrenderproperty, FC, Idx) then
                    setrenderproperty(FC,  Idx, Val)
                    setrenderproperty(FCO, Idx, Val)
                end
            end
            setrenderproperty(FC,  "Color", (AimbotEnv.Locked and FS.LockedColor) or FS.RainbowColor and GetRainbowColor() or FS.Color)
            setrenderproperty(FCO, "Color", FS.RainbowOutlineColor and GetRainbowColor() or FS.OutlineColor)
            setrenderproperty(FCO, "Thickness", FS.Thickness + 1)
            setrenderproperty(FC,  "Position", GetMouseLocation(UserInputService))
            setrenderproperty(FCO, "Position", GetMouseLocation(UserInputService))
        else
            setrenderproperty(FC,  "Visible", false)
            setrenderproperty(FCO, "Visible", false)
        end

        if Running and S.Enabled then
            GetClosestPlayer()
            local Offset = OffDir and
                __index(FindFirstChildOfClass(__index(AimbotEnv.Locked, "Character"), "Humanoid"), "MoveDirection") *
                (mathclamp(S.OffsetIncrement, 1, 30) / 10) or Vector3zero

            if AimbotEnv.Locked then
                local LP3 = __index(__index(AimbotEnv.Locked, "Character")[LP], "Position")
                local LPScreen = WorldToViewportPoint(Camera, LP3 + Offset)
                if S.LockMode == 2 then
                    mousemoverel(
                        (LPScreen.X - GetMouseLocation(UserInputService).X) / S.Sensitivity2,
                        (LPScreen.Y - GetMouseLocation(UserInputService).Y) / S.Sensitivity2
                    )
                else
                    if S.Sensitivity > 0 then
                        Animation = TweenService:Create(Camera, TweenInfonew(S.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                            {CFrame = CFramenew(Camera.CFrame.Position, LP3)})
                        Animation:Play()
                    else
                        __newindex(Camera, "CFrame", CFramenew(Camera.CFrame.Position, LP3 + Offset))
                    end
                    __newindex(UserInputService, "MouseDeltaSensitivity", 0)
                end
                setrenderproperty(FC, "Color", FS.LockedColor)
            end
        end
    end)

    ServiceConnections.InputBeganConnection = Connect(__index(UserInputService, "InputBegan"), function(Input)
        local TK, Tog = S.TriggerKey, S.Toggle
        if Typing then return end
        if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == TK
            or Input.UserInputType == TK then
            if Tog then
                Running = not Running
                if not Running then CancelLock() end
            else
                Running = true
            end
        end
    end)

    ServiceConnections.InputEndedConnection = Connect(__index(UserInputService, "InputEnded"), function(Input)
        local TK, Tog = S.TriggerKey, S.Toggle
        if Tog or Typing then return end
        if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == TK
            or Input.UserInputType == TK then
            Running = false
            CancelLock()
        end
    end)
end

ServiceConnections.TypingStartedConnection = Connect(__index(UserInputService, "TextBoxFocused"), function()
    Typing = true
end)
ServiceConnections.TypingEndedConnection = Connect(__index(UserInputService, "TextBoxFocusReleased"), function()
    Typing = false
end)

function AimbotEnv:Exit()
    assert(self, "AimbotEnv.Exit: Missing self.")
    for _, _ in next, ServiceConnections do
        Disconnect(ServiceConnections[_])
    end
    self.FOVCircle:Remove()
    self.FOVCircleOutline:Remove()
    getgenv().ExunysDeveloperAimbot = nil
end

function AimbotEnv.Restart()
    for _, _ in next, ServiceConnections do
        Disconnect(ServiceConnections[_])
    end
    LoadAimbot()
end

function AimbotEnv:Blacklist(Username)
    assert(self, "AimbotEnv.Blacklist: Missing self.")
    assert(Username, "AimbotEnv.Blacklist: Missing Username.")
    Username = FixUsername(Username)
    assert(Username, "AimbotEnv.Blacklist: User not found.")
    self.Blacklisted[#self.Blacklisted + 1] = Username
end

function AimbotEnv:Whitelist(Username)
    assert(self, "AimbotEnv.Whitelist: Missing self.")
    assert(Username, "AimbotEnv.Whitelist: Missing Username.")
    Username = FixUsername(Username)
    assert(Username, "AimbotEnv.Whitelist: User not found.")
    local Idx = tablefind(self.Blacklisted, Username)
    assert(Idx, "AimbotEnv.Whitelist: User is not blacklisted.")
    tableremove(self.Blacklisted, Idx)
end

function AimbotEnv.GetClosestPlayer()
    GetClosestPlayer()
    local v = AimbotEnv.Locked
    CancelLock()
    return v
end

AimbotEnv.Load = LoadAimbot
setmetatable(AimbotEnv, {__call = LoadAimbot})

-- ============================================================
-- ESP
-- ============================================================

local Fluent           = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager      = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Drawings = { ESP = {}, Skeleton = {} }
local Colors   = {
    Enemy   = Color3.fromRGB(255, 25, 25),
    Ally    = Color3.fromRGB(25, 255, 25),
    Health  = Color3.fromRGB(0, 255, 0),
    Rainbow = nil
}
local Highlights = {}

local ESPSettings = {
    Enabled              = false,
    TeamCheck            = false,
    ShowTeam             = false,
    BoxESP               = false,
    BoxStyle             = "Corner",
    BoxThickness         = 1,
    BoxFillTransparency  = 0.5,
    TracerESP            = false,
    TracerOrigin         = "Bottom",
    TracerThickness      = 1,
    HealthESP            = false,
    HealthStyle          = "Bar",
    HealthTextSuffix     = "HP",
    NameESP              = false,
    TextSize             = 14,
    TextFont             = 2,
    RainbowEnabled       = false,
    RainbowSpeed         = 1,
    RainbowBoxes         = false,
    RainbowTracers       = false,
    RainbowText          = false,
    MaxDistance          = 1000,
    RefreshRate          = 1/144,
    Snaplines            = false,
    ChamsEnabled         = false,
    ChamsOutlineColor    = Color3.fromRGB(255, 255, 255),
    ChamsFillColor       = Color3.fromRGB(255, 0, 0),
    ChamsOccludedColor   = Color3.fromRGB(150, 0, 0),
    ChamsTransparency    = 0.5,
    ChamsOutlineTransparency = 0,
    ChamsOutlineThickness= 0.1,
    SkeletonESP          = false,
    SkeletonColor        = Color3.fromRGB(255, 255, 255),
    SkeletonThickness    = 1.5,
    SkeletonTransparency = 1
}

local function CreateESP(player)
    if player == LocalPlayer then return end
    local box = {
        TopLeft = Drawing.new("Line"), TopRight  = Drawing.new("Line"),
        BottomLeft = Drawing.new("Line"), BottomRight = Drawing.new("Line"),
        Left  = Drawing.new("Line"), Right  = Drawing.new("Line"),
        Top   = Drawing.new("Line"), Bottom = Drawing.new("Line")
    }
    for _, line in pairs(box) do
        line.Visible = false; line.Color = Colors.Enemy
        line.Thickness = ESPSettings.BoxThickness
    end
    local tracer = Drawing.new("Line")
    tracer.Visible = false; tracer.Color = Colors.Enemy; tracer.Thickness = ESPSettings.TracerThickness
    local healthBar = {
        Outline = Drawing.new("Square"), Fill = Drawing.new("Square"), Text = Drawing.new("Text")
    }
    healthBar.Fill.Color   = Colors.Health; healthBar.Fill.Filled   = true
    healthBar.Text.Center  = true;          healthBar.Text.Size     = ESPSettings.TextSize
    healthBar.Text.Color   = Colors.Health; healthBar.Text.Font     = ESPSettings.TextFont
    for _, o in pairs(healthBar) do o.Visible = false end
    local info = { Name = Drawing.new("Text"), Distance = Drawing.new("Text") }
    for _, t in pairs(info) do
        t.Visible = false; t.Center = true; t.Size = ESPSettings.TextSize
        t.Color   = Colors.Enemy; t.Font  = ESPSettings.TextFont; t.Outline = true
    end
    local snapline = Drawing.new("Line")
    snapline.Visible = false; snapline.Color = Colors.Enemy; snapline.Thickness = 1
    local highlight = Instance.new("Highlight")
    highlight.FillColor        = ESPSettings.ChamsFillColor
    highlight.OutlineColor     = ESPSettings.ChamsOutlineColor
    highlight.FillTransparency = ESPSettings.ChamsTransparency
    highlight.OutlineTransparency = ESPSettings.ChamsOutlineTransparency
    highlight.DepthMode        = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled          = ESPSettings.ChamsEnabled
    Highlights[player] = highlight
    local skeleton = {}
    for _, k in ipairs({
        "Head","Neck","UpperSpine","LowerSpine",
        "LeftShoulder","LeftUpperArm","LeftLowerArm","LeftHand",
        "RightShoulder","RightUpperArm","RightLowerArm","RightHand",
        "LeftHip","LeftUpperLeg","LeftLowerLeg","LeftFoot",
        "RightHip","RightUpperLeg","RightLowerLeg","RightFoot"
    }) do
        skeleton[k] = Drawing.new("Line")
        skeleton[k].Visible = false
        skeleton[k].Color   = ESPSettings.SkeletonColor
        skeleton[k].Thickness    = ESPSettings.SkeletonThickness
        skeleton[k].Transparency = ESPSettings.SkeletonTransparency
    end
    Drawings.Skeleton[player] = skeleton
    Drawings.ESP[player] = { Box = box, Tracer = tracer, HealthBar = healthBar, Info = info, Snapline = snapline }
end

local function RemoveESP(player)
    local esp = Drawings.ESP[player]
    if esp then
        for _, o in pairs(esp.Box)       do o:Remove() end
        for _, o in pairs(esp.HealthBar) do o:Remove() end
        for _, o in pairs(esp.Info)      do o:Remove() end
        esp.Tracer:Remove(); esp.Snapline:Remove()
        Drawings.ESP[player] = nil
    end
    local hl = Highlights[player]
    if hl then hl:Destroy(); Highlights[player] = nil end
    local sk = Drawings.Skeleton[player]
    if sk then for _, l in pairs(sk) do l:Remove() end; Drawings.Skeleton[player] = nil end
end

local function GetPlayerColor(player)
    if ESPSettings.RainbowEnabled then
        if ESPSettings.RainbowBoxes   and ESPSettings.BoxESP  then return Colors.Rainbow end
        if ESPSettings.RainbowTracers and ESPSettings.TracerESP then return Colors.Rainbow end
        if ESPSettings.RainbowText    and (ESPSettings.NameESP or ESPSettings.HealthESP) then return Colors.Rainbow end
    end
    return player.Team == LocalPlayer.Team and Colors.Ally or Colors.Enemy
end

local function GetTracerOrigin()
    local o = ESPSettings.TracerOrigin
    if o == "Bottom" then return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
    elseif o == "Top"    then return Vector2.new(Camera.ViewportSize.X/2, 0)
    elseif o == "Mouse"  then return UserInputService:GetMouseLocation()
    else return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) end
end

local function HideAll(esp, player)
    if esp then
        for _, o in pairs(esp.Box)       do o.Visible = false end
        for _, o in pairs(esp.HealthBar) do o.Visible = false end
        for _, o in pairs(esp.Info)      do o.Visible = false end
        esp.Tracer.Visible = false; esp.Snapline.Visible = false
    end
    local sk = Drawings.Skeleton[player]
    if sk then for _, l in pairs(sk) do l.Visible = false end end
end

local function UpdateESP(player)
    if not ESPSettings.Enabled then return end
    local esp = Drawings.ESP[player]
    if not esp then return end
    local char = player.Character
    if not char then HideAll(esp, player); return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then HideAll(esp, player); return end
    local _, onScreen0 = Camera:WorldToViewportPoint(root.Position)
    if not onScreen0 then HideAll(esp, player); return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then HideAll(esp, player); return end
    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
    local dist = (root.Position - Camera.CFrame.Position).Magnitude
    if not onScreen or dist > ESPSettings.MaxDistance then HideAll(esp, player); return end
    if ESPSettings.TeamCheck and player.Team == LocalPlayer.Team and not ESPSettings.ShowTeam then
        HideAll(esp, player); return
    end
    local color = GetPlayerColor(player)
    local size  = char:GetExtentsSize()
    local cf    = root.CFrame
    local top,    top_on    = Camera:WorldToViewportPoint((cf * CFrame.new(0,  size.Y/2, 0)).Position)
    local bottom, bottom_on = Camera:WorldToViewportPoint((cf * CFrame.new(0, -size.Y/2, 0)).Position)
    if not top_on or not bottom_on then for _, o in pairs(esp.Box) do o.Visible = false end return end
    local screenSize = bottom.Y - top.Y
    local boxWidth   = screenSize * 0.65
    local boxPos     = Vector2.new(top.X - boxWidth/2, top.Y)
    local boxSize    = Vector2.new(boxWidth, screenSize)
    for _, o in pairs(esp.Box) do o.Visible = false end
    if ESPSettings.BoxESP then
        local sty = ESPSettings.BoxStyle
        if sty == "Corner" then
            local cs = boxWidth * 0.2
            local corners = {
                {esp.Box.TopLeft,     boxPos,                                       boxPos + Vector2.new(cs,0)},
                {esp.Box.TopRight,    boxPos + Vector2.new(boxSize.X,0),             boxPos + Vector2.new(boxSize.X-cs,0)},
                {esp.Box.BottomLeft,  boxPos + Vector2.new(0,boxSize.Y),             boxPos + Vector2.new(cs,boxSize.Y)},
                {esp.Box.BottomRight, boxPos + Vector2.new(boxSize.X,boxSize.Y),     boxPos + Vector2.new(boxSize.X-cs,boxSize.Y)},
                {esp.Box.Left,        boxPos,                                       boxPos + Vector2.new(0,cs)},
                {esp.Box.Right,       boxPos + Vector2.new(boxSize.X,0),             boxPos + Vector2.new(boxSize.X,cs)},
                {esp.Box.Top,         boxPos + Vector2.new(0,boxSize.Y),             boxPos + Vector2.new(0,boxSize.Y-cs)},
                {esp.Box.Bottom,      boxPos + Vector2.new(boxSize.X,boxSize.Y),     boxPos + Vector2.new(boxSize.X,boxSize.Y-cs)},
            }
            for _, d in ipairs(corners) do
                d[1].From = d[2]; d[1].To = d[3]; d[1].Visible = true
            end
        elseif sty == "Full" then
            local sides = {
                {esp.Box.Left,   boxPos,                       boxPos + Vector2.new(0, boxSize.Y)},
                {esp.Box.Right,  boxPos + Vector2.new(boxSize.X,0), boxPos + Vector2.new(boxSize.X, boxSize.Y)},
                {esp.Box.Top,    boxPos,                       boxPos + Vector2.new(boxSize.X,0)},
                {esp.Box.Bottom, boxPos + Vector2.new(0,boxSize.Y), boxPos + Vector2.new(boxSize.X, boxSize.Y)},
            }
            for _, d in ipairs(sides) do d[1].From = d[2]; d[1].To = d[3]; d[1].Visible = true end
        end
        for _, o in pairs(esp.Box) do
            if o.Visible then o.Color = color; o.Thickness = ESPSettings.BoxThickness end
        end
    end
    if ESPSettings.TracerESP then
        esp.Tracer.From = GetTracerOrigin()
        esp.Tracer.To   = Vector2.new(pos.X, pos.Y)
        esp.Tracer.Color = color; esp.Tracer.Visible = true
    else esp.Tracer.Visible = false end
    if ESPSettings.HealthESP then
        local hp   = humanoid.Health
        local mxhp = humanoid.MaxHealth
        local pct  = hp / mxhp
        local bh   = screenSize * 0.8
        local bw   = 4
        local bp   = Vector2.new(boxPos.X - bw - 2, boxPos.Y + (screenSize - bh)/2)
        esp.HealthBar.Outline.Size     = Vector2.new(bw, bh); esp.HealthBar.Outline.Position = bp; esp.HealthBar.Outline.Visible = true
        esp.HealthBar.Fill.Size        = Vector2.new(bw-2, bh*pct)
        esp.HealthBar.Fill.Position    = Vector2.new(bp.X+1, bp.Y + bh*(1-pct))
        esp.HealthBar.Fill.Color       = Color3.fromRGB(255-(255*pct), 255*pct, 0); esp.HealthBar.Fill.Visible = true
        if ESPSettings.HealthStyle == "Both" or ESPSettings.HealthStyle == "Text" then
            esp.HealthBar.Text.Text     = math.floor(hp) .. ESPSettings.HealthTextSuffix
            esp.HealthBar.Text.Position = Vector2.new(bp.X+bw+2, bp.Y+bh/2); esp.HealthBar.Text.Visible = true
        else esp.HealthBar.Text.Visible = false end
    else for _, o in pairs(esp.HealthBar) do o.Visible = false end end
    if ESPSettings.NameESP then
        esp.Info.Name.Text     = player.DisplayName
        esp.Info.Name.Position = Vector2.new(boxPos.X + boxWidth/2, boxPos.Y - 20)
        esp.Info.Name.Color    = color; esp.Info.Name.Visible = true
    else esp.Info.Name.Visible = false end
    if ESPSettings.Snaplines then
        esp.Snapline.From    = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        esp.Snapline.To      = Vector2.new(pos.X, pos.Y)
        esp.Snapline.Color   = color; esp.Snapline.Visible = true
    else esp.Snapline.Visible = false end
    local hl = Highlights[player]
    if hl then
        if ESPSettings.ChamsEnabled and char then
            hl.Parent             = char
            hl.FillColor          = ESPSettings.ChamsFillColor
            hl.OutlineColor       = ESPSettings.ChamsOutlineColor
            hl.FillTransparency   = ESPSettings.ChamsTransparency
            hl.OutlineTransparency = ESPSettings.ChamsOutlineTransparency
            hl.Enabled = true
        else hl.Enabled = false end
    end
    if ESPSettings.SkeletonESP then
        local function drawBone(from, to, line)
            if not from or not to then line.Visible = false; return end
            local fs, fv = Camera:WorldToViewportPoint(from.CFrame.Position)
            local ts, tv = Camera:WorldToViewportPoint(to.CFrame.Position)
            if not (fv and tv) or fs.Z < 0 or ts.Z < 0 then line.Visible = false; return end
            local sv = Camera.ViewportSize
            if fs.X<0 or fs.X>sv.X or fs.Y<0 or fs.Y>sv.Y or
               ts.X<0 or ts.X>sv.X or ts.Y<0 or ts.Y>sv.Y then line.Visible = false; return end
            line.From  = Vector2.new(fs.X, fs.Y); line.To = Vector2.new(ts.X, ts.Y)
            line.Color = ESPSettings.SkeletonColor; line.Thickness = ESPSettings.SkeletonThickness
            line.Transparency = ESPSettings.SkeletonTransparency; line.Visible = true
        end
        local function fc(n) return char:FindFirstChild(n) end
        local b = {
            Head = fc("Head"),
            UpperTorso  = fc("UpperTorso")  or fc("Torso"),
            LowerTorso  = fc("LowerTorso")  or fc("Torso"),
            LeftUpperArm  = fc("LeftUpperArm")  or fc("Left Arm"),
            LeftLowerArm  = fc("LeftLowerArm")  or fc("Left Arm"),
            LeftHand      = fc("LeftHand")      or fc("Left Arm"),
            RightUpperArm = fc("RightUpperArm") or fc("Right Arm"),
            RightLowerArm = fc("RightLowerArm") or fc("Right Arm"),
            RightHand     = fc("RightHand")     or fc("Right Arm"),
            LeftUpperLeg  = fc("LeftUpperLeg")  or fc("Left Leg"),
            LeftLowerLeg  = fc("LeftLowerLeg")  or fc("Left Leg"),
            LeftFoot      = fc("LeftFoot")      or fc("Left Leg"),
            RightUpperLeg = fc("RightUpperLeg") or fc("Right Leg"),
            RightLowerLeg = fc("RightLowerLeg") or fc("Right Leg"),
            RightFoot     = fc("RightFoot")     or fc("Right Leg"),
        }
        if b.Head and b.UpperTorso then
            local sk = Drawings.Skeleton[player]
            if sk then
                drawBone(b.Head, b.UpperTorso, sk.Head)
                drawBone(b.UpperTorso, b.LowerTorso, sk.UpperSpine)
                drawBone(b.UpperTorso, b.LeftUpperArm,  sk.LeftShoulder)
                drawBone(b.LeftUpperArm, b.LeftLowerArm, sk.LeftUpperArm)
                drawBone(b.LeftLowerArm, b.LeftHand,     sk.LeftLowerArm)
                drawBone(b.UpperTorso, b.RightUpperArm,  sk.RightShoulder)
                drawBone(b.RightUpperArm, b.RightLowerArm, sk.RightUpperArm)
                drawBone(b.RightLowerArm, b.RightHand,     sk.RightLowerArm)
                drawBone(b.LowerTorso, b.LeftUpperLeg,   sk.LeftHip)
                drawBone(b.LeftUpperLeg, b.LeftLowerLeg, sk.LeftUpperLeg)
                drawBone(b.LeftLowerLeg, b.LeftFoot,     sk.LeftLowerLeg)
                drawBone(b.LowerTorso, b.RightUpperLeg,  sk.RightHip)
                drawBone(b.RightUpperLeg, b.RightLowerLeg, sk.RightUpperLeg)
                drawBone(b.RightLowerLeg, b.RightFoot,     sk.RightLowerLeg)
            end
        end
    else
        local sk = Drawings.Skeleton[player]
        if sk then for _, l in pairs(sk) do l.Visible = false end end
    end
end

local function DisableESP()
    for _, p in ipairs(Players:GetPlayers()) do HideAll(Drawings.ESP[p], p) end
end

local function CleanupESP()
    for _, p in ipairs(Players:GetPlayers()) do RemoveESP(p) end
    Drawings.ESP = {}; Drawings.Skeleton = {}; Highlights = {}
end

-- Fluent GUI
local Window = Fluent:CreateWindow({
    Title = "Combined Script", SubTitle = "Aimbot + ESP + AutoClick",
    TabWidth = 160, Size = UDim2.fromOffset(580, 460),
    Acrylic = false, Theme = "Dark", MinimizeKey = Enum.KeyCode.LeftControl
})
local Tabs = {
    Aimbot   = Window:AddTab({ Title = "Aimbot",   Icon = "crosshair" }),
    ESP      = Window:AddTab({ Title = "ESP",      Icon = "eye" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Config   = Window:AddTab({ Title = "Config",   Icon = "save" })
}

-- Aimbot tab
do
    local S = AimbotEnv.Settings
    local AS = Tabs.Aimbot:AddSection("Aimbot Settings")
    AS:AddToggle("AimbotEnabled", { Title = "Enable Aimbot", Default = true }):OnChanged(function()
        S.Enabled = not S.Enabled end)
    AS:AddToggle("AimbotTeamCheck", { Title = "Team Check", Default = false }):OnChanged(function()
        S.TeamCheck = not S.TeamCheck end)
    AS:AddToggle("AimbotToggle", { Title = "Toggle Mode (hold = off, toggle = on)", Default = false }):OnChanged(function()
        S.Toggle = not S.Toggle end)
    AS:AddDropdown("LockMode", { Title = "Lock Mode", Values = {"CFrame","mousemoverel"}, Default = "CFrame" }):OnChanged(function(v)
        S.LockMode = v == "CFrame" and 1 or 2 end)
    AS:AddSlider("Sensitivity", { Title = "Smooth Sensitivity (0=instant)", Default = 0, Min = 0, Max = 1, Rounding = 2 }):OnChanged(function(v)
        S.Sensitivity = v end)
    AS:AddSlider("Sensitivity2", { Title = "mousemoverel Speed", Default = 3.5, Min = 0.5, Max = 10, Rounding = 1 }):OnChanged(function(v)
        S.Sensitivity2 = v end)
    local FOVS = AimbotEnv.FOVSettings
    local FS = Tabs.Aimbot:AddSection("FOV Circle")
    FS:AddToggle("FOVEnabled", { Title = "FOV Circle", Default = true }):OnChanged(function()
        FOVS.Enabled = not FOVS.Enabled end)
    FS:AddSlider("FOVRadius", { Title = "Radius", Default = 90, Min = 10, Max = 500, Rounding = 0 }):OnChanged(function(v)
        FOVS.Radius = v end)
end

-- ESP tab
do
    local MS = Tabs.ESP:AddSection("Main ESP")
    MS:AddToggle("ESPEnabled", { Title = "Enable ESP", Default = false }):OnChanged(function()
        ESPSettings.Enabled = not ESPSettings.Enabled
        if not ESPSettings.Enabled then CleanupESP()
        else for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateESP(p) end end end
    end)
    MS:AddToggle("ESPTeamCheck", { Title = "Team Check", Default = false }):OnChanged(function()
        ESPSettings.TeamCheck = not ESPSettings.TeamCheck end)
    local BS = Tabs.ESP:AddSection("Box ESP")
    BS:AddToggle("BoxESP", { Title = "Box ESP", Default = false }):OnChanged(function()
        ESPSettings.BoxESP = not ESPSettings.BoxESP end)
    BS:AddDropdown("BoxStyle", { Title = "Box Style", Values = {"Corner","Full","ThreeD"}, Default = "Corner" }):OnChanged(function(v)
        ESPSettings.BoxStyle = v end)
    local TS = Tabs.ESP:AddSection("Tracer ESP")
    TS:AddToggle("TracerESP", { Title = "Tracer ESP", Default = false }):OnChanged(function()
        ESPSettings.TracerESP = not ESPSettings.TracerESP end)
    TS:AddDropdown("TracerOrigin", { Title = "Tracer Origin", Values = {"Bottom","Top","Mouse","Center"}, Default = "Bottom" }):OnChanged(function(v)
        ESPSettings.TracerOrigin = v end)
    local CS = Tabs.ESP:AddSection("Chams")
    CS:AddToggle("ChamsEnabled", { Title = "Enable Chams", Default = false }):OnChanged(function()
        ESPSettings.ChamsEnabled = not ESPSettings.ChamsEnabled end)
    CS:AddColorpicker("ChamsFill", { Title = "Fill Color", Default = ESPSettings.ChamsFillColor }):OnChanged(function(v)
        ESPSettings.ChamsFillColor = v end)
    CS:AddColorpicker("ChamsOutline", { Title = "Outline Color", Default = ESPSettings.ChamsOutlineColor }):OnChanged(function(v)
        ESPSettings.ChamsOutlineColor = v end)
    local HS = Tabs.ESP:AddSection("Health ESP")
    HS:AddToggle("HealthESP", { Title = "Health Bar", Default = false }):OnChanged(function()
        ESPSettings.HealthESP = not ESPSettings.HealthESP end)
    HS:AddDropdown("HealthStyle", { Title = "Health Style", Values = {"Bar","Text","Both"}, Default = "Bar" }):OnChanged(function(v)
        ESPSettings.HealthStyle = v end)
    local SKS = Tabs.ESP:AddSection("Skeleton ESP")
    SKS:AddToggle("SkeletonESP", { Title = "Skeleton ESP", Default = false }):OnChanged(function()
        ESPSettings.SkeletonESP = not ESPSettings.SkeletonESP end)
    SKS:AddColorpicker("SkeletonColor", { Title = "Skeleton Color", Default = ESPSettings.SkeletonColor }):OnChanged(function(v)
        ESPSettings.SkeletonColor = v
        for _, p in ipairs(Players:GetPlayers()) do
            local sk = Drawings.Skeleton[p]
            if sk then for _, l in pairs(sk) do l.Color = v end end
        end
    end)
    SKS:AddToggle("NameESP", { Title = "Name ESP", Default = false }):OnChanged(function()
        ESPSettings.NameESP = not ESPSettings.NameESP end)
end

-- Settings tab
do
    local CS = Tabs.Settings:AddSection("Colors")
    CS:AddColorpicker("EnemyColor", { Title = "Enemy Color", Default = Colors.Enemy }):OnChanged(function(v) Colors.Enemy = v end)
    CS:AddColorpicker("AllyColor",  { Title = "Ally Color",  Default = Colors.Ally  }):OnChanged(function(v) Colors.Ally  = v end)
    local ES = Tabs.Settings:AddSection("ESP Settings")
    ES:AddSlider("MaxDist", { Title = "Max Distance", Default = 1000, Min = 100, Max = 5000, Rounding = 0 }):OnChanged(function(v)
        ESPSettings.MaxDistance = v end)
    ES:AddSlider("TextSize", { Title = "Text Size", Default = 14, Min = 10, Max = 24, Rounding = 0 }):OnChanged(function(v)
        ESPSettings.TextSize = v end)
    local EFS = Tabs.Settings:AddSection("Effects")
    EFS:AddToggle("Rainbow", { Title = "Rainbow Mode", Default = false }):OnChanged(function()
        ESPSettings.RainbowEnabled = not ESPSettings.RainbowEnabled end)
    EFS:AddSlider("RainbowSpeed", { Title = "Rainbow Speed", Default = 1, Min = 0.1, Max = 5, Rounding = 1 }):OnChanged(function(v)
        ESPSettings.RainbowSpeed = v end)
end

-- Config tab
do
    SaveManager:SetLibrary(Fluent); InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings(); SaveManager:SetIgnoreIndexes({})
    InterfaceManager:SetFolder("CombinedScript"); SaveManager:SetFolder("CombinedScript/configs")
    InterfaceManager:BuildInterfaceSection(Tabs.Config); SaveManager:BuildConfigSection(Tabs.Config)
    local US = Tabs.Config:AddSection("Unload")
    US:AddButton({ Title = "Unload All", Description = "Remove ESP, aimbot, and auto-click", Callback = function()
        CleanupESP()
        AimbotEnv:Exit()
        Window:Destroy()
    end })
end

-- Rainbow update loop
task.spawn(function()
    while task.wait(0.1) do
        Colors.Rainbow = Color3.fromHSV(tick() * ESPSettings.RainbowSpeed % 1, 1, 1)
    end
end)

-- ESP render loop
local lastESPUpdate = 0
RunService.RenderStepped:Connect(function()
    if not ESPSettings.Enabled then DisableESP(); return end
    local now = tick()
    if now - lastESPUpdate >= ESPSettings.RefreshRate then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                if not Drawings.ESP[p] then CreateESP(p) end
                UpdateESP(p)
            end
        end
        lastESPUpdate = now
    end
end)

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then CreateESP(p) end
end

-- ============================================================
-- AUTO-CLICK
-- ============================================================

local mouse        = LocalPlayer:GetMouse()
local lastTarget   = nil
local canClick     = true
local clickCooldown = 0.2

RunService.RenderStepped:Connect(function()
    if mouse.Target and mouse.Target.Parent:FindFirstChild("Humanoid")
        and mouse.Target.Parent.Name ~= LocalPlayer.Name then
        local target = Players:GetPlayerFromCharacter(mouse.Target.Parent)
        if target and target.Team ~= LocalPlayer.Team then
            if mouse.Target ~= lastTarget then
                canClick = true; lastTarget = mouse.Target
            end
            if canClick then
                mouse1press(); task.wait(clickCooldown); mouse1release()
                canClick = false
            end
        else
            lastTarget = nil
        end
    else
        lastTarget = nil
    end
end)

-- ============================================================
-- INIT
-- ============================================================

LoadAimbot()
Window:SelectTab(1)
Fluent:Notify({ Title = "Combined Script", Content = "Aimbot + ESP + AutoClick loaded!", Duration = 5 })
