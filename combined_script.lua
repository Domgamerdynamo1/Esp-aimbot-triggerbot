--[[ Combined Script: Auto-Click + ESP + Aimbot ]]

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ── Auto-Click / Aim Assist Settings ──
local ACSettings = {
    Enabled = false,
    HoldClick = true,
    Hotkey = 't',
    HotkeyToggle = true
}

-- ── ESP Settings ──
local ESPColors = {
    Enemy = Color3.fromRGB(255, 25, 25),
    Ally = Color3.fromRGB(25, 255, 25),
    Neutral = Color3.fromRGB(255, 255, 255),
    Selected = Color3.fromRGB(255, 210, 0),
    Health = Color3.fromRGB(0, 255, 0),
    Distance = Color3.fromRGB(200, 200, 200),
    Rainbow = nil
}

local ESPSettings = {
    Enabled = false,
    TeamCheck = false,
    ShowTeam = false,
    VisibilityCheck = true,
    BoxESP = false,
    BoxStyle = "Corner",
    BoxOutline = true,
    BoxFilled = false,
    BoxFillTransparency = 0.5,
    BoxThickness = 1,
    TracerESP = false,
    TracerOrigin = "Bottom",
    TracerStyle = "Line",
    TracerThickness = 1,
    HealthESP = false,
    HealthStyle = "Bar",
    HealthBarSide = "Left",
    HealthTextSuffix = "HP",
    NameESP = false,
    NameMode = "DisplayName",
    ShowDistance = true,
    DistanceUnit = "studs",
    TextSize = 14,
    TextFont = 2,
    RainbowSpeed = 1,
    MaxDistance = 1000,
    RefreshRate = 1/144,
    Snaplines = false,
    SnaplineStyle = "Straight",
    RainbowEnabled = false,
    RainbowBoxes = false,
    RainbowTracers = false,
    RainbowText = false,
    ChamsEnabled = false,
    ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
    ChamsFillColor = Color3.fromRGB(255, 0, 0),
    ChamsOccludedColor = Color3.fromRGB(150, 0, 0),
    ChamsTransparency = 0.5,
    ChamsOutlineTransparency = 0,
    ChamsOutlineThickness = 0.1,
    SkeletonESP = false,
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    SkeletonThickness = 1.5,
    SkeletonTransparency = 1
}

-- ── Aimbot Settings ──
local AimbotSettings = {
    Enabled = false,
    FOVRadius = 100,
    FOVVisible = true,
    FOVColor = Color3.fromRGB(255, 255, 0),
    FOVFilled = false,
    FOVTransparency = 0.6,
    FOVThickness = 1,
    AimKey = Enum.UserInputType.MouseButton2,
    AimOnKeyHold = true
}

-- ── Auto-Click State ──
local ACToggle = (ACSettings.Hotkey ~= '')
local ACCurrentlyPressed = false

-- ── ESP State ──
local Drawings = {
    ESP = {},
    Tracers = {},
    Boxes = {},
    Healthbars = {},
    Names = {},
    Distances = {},
    Snaplines = {},
    Skeleton = {}
}
local Highlights = {}

-- ── Aimbot State ──
local aiming = false
local fovCircle = Drawing.new("Circle")
fovCircle.Radius = AimbotSettings.FOVRadius
fovCircle.Color = AimbotSettings.FOVColor
fovCircle.Thickness = AimbotSettings.FOVThickness
fovCircle.Transparency = AimbotSettings.FOVTransparency
fovCircle.Visible = AimbotSettings.FOVVisible
fovCircle.Filled = AimbotSettings.FOVFilled

-- ═══════════════════════════════════════════════
-- AUTO-CLICK
-- ═══════════════════════════════════════════════

local function UpdateAutoClick()
    if ACToggle and ACSettings.Enabled then
        if Mouse.Target then
            local character = Mouse.Target.Parent
            if character and character:FindFirstChild('Humanoid') then
                local player = Players:GetPlayerFromCharacter(character)
                if player and player.Team ~= LocalPlayer.Team then
                    if ACSettings.HoldClick then
                        if not ACCurrentlyPressed then
                            ACCurrentlyPressed = true
                            mouse1press()
                        end
                    else
                        mouse1click()
                    end
                else
                    if ACSettings.HoldClick then
                        ACCurrentlyPressed = false
                        mouse1release()
                    end
                end
            end
        end
    elseif ACCurrentlyPressed then
        ACCurrentlyPressed = false
        mouse1release()
    end
end

Mouse.KeyDown:Connect(function(key)
    local k = key:lower()
    if k == ACSettings.Hotkey:lower() then
        if ACSettings.HotkeyToggle then
            ACToggle = not ACToggle
        else
            ACToggle = true
        end
    end
end)

Mouse.KeyUp:Connect(function(key)
    local k = key:lower()
    if not ACSettings.HotkeyToggle and k == ACSettings.Hotkey:lower() then
        ACToggle = false
    end
end)

-- ═══════════════════════════════════════════════
-- ESP
-- ═══════════════════════════════════════════════

local function CreateESP(player)
    if player == LocalPlayer then return end

    local box = {
        TopLeft = Drawing.new("Line"),
        TopRight = Drawing.new("Line"),
        BottomLeft = Drawing.new("Line"),
        BottomRight = Drawing.new("Line"),
        Left = Drawing.new("Line"),
        Right = Drawing.new("Line"),
        Top = Drawing.new("Line"),
        Bottom = Drawing.new("Line")
    }
    for _, line in pairs(box) do
        line.Visible = false
        line.Color = ESPColors.Enemy
        line.Thickness = ESPSettings.BoxThickness
    end

    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = ESPColors.Enemy
    tracer.Thickness = ESPSettings.TracerThickness

    local healthBar = {
        Outline = Drawing.new("Square"),
        Fill = Drawing.new("Square"),
        Text = Drawing.new("Text")
    }
    for _, obj in pairs(healthBar) do
        obj.Visible = false
        if obj == healthBar.Fill then
            obj.Color = ESPColors.Health
            obj.Filled = true
        elseif obj == healthBar.Text then
            obj.Center = true
            obj.Size = ESPSettings.TextSize
            obj.Color = ESPColors.Health
            obj.Font = ESPSettings.TextFont
        end
    end

    local info = {
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text")
    }
    for _, text in pairs(info) do
        text.Visible = false
        text.Center = true
        text.Size = ESPSettings.TextSize
        text.Color = ESPColors.Enemy
        text.Font = ESPSettings.TextFont
        text.Outline = true
    end

    local snapline = Drawing.new("Line")
    snapline.Visible = false
    snapline.Color = ESPColors.Enemy
    snapline.Thickness = 1

    local highlight = Instance.new("Highlight")
    highlight.FillColor = ESPSettings.ChamsFillColor
    highlight.OutlineColor = ESPSettings.ChamsOutlineColor
    highlight.FillTransparency = ESPSettings.ChamsTransparency
    highlight.OutlineTransparency = ESPSettings.ChamsOutlineTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = ESPSettings.ChamsEnabled
    Highlights[player] = highlight

    local skeleton = {
        Head = Drawing.new("Line"),
        Neck = Drawing.new("Line"),
        UpperSpine = Drawing.new("Line"),
        LowerSpine = Drawing.new("Line"),
        LeftShoulder = Drawing.new("Line"),
        LeftUpperArm = Drawing.new("Line"),
        LeftLowerArm = Drawing.new("Line"),
        LeftHand = Drawing.new("Line"),
        RightShoulder = Drawing.new("Line"),
        RightUpperArm = Drawing.new("Line"),
        RightLowerArm = Drawing.new("Line"),
        RightHand = Drawing.new("Line"),
        LeftHip = Drawing.new("Line"),
        LeftUpperLeg = Drawing.new("Line"),
        LeftLowerLeg = Drawing.new("Line"),
        LeftFoot = Drawing.new("Line"),
        RightHip = Drawing.new("Line"),
        RightUpperLeg = Drawing.new("Line"),
        RightLowerLeg = Drawing.new("Line"),
        RightFoot = Drawing.new("Line")
    }
    for _, line in pairs(skeleton) do
        line.Visible = false
        line.Color = ESPSettings.SkeletonColor
        line.Thickness = ESPSettings.SkeletonThickness
        line.Transparency = ESPSettings.SkeletonTransparency
    end
    Drawings.Skeleton[player] = skeleton

    Drawings.ESP[player] = {
        Box = box,
        Tracer = tracer,
        HealthBar = healthBar,
        Info = info,
        Snapline = snapline
    }
end

local function RemoveESP(player)
    local esp = Drawings.ESP[player]
    if esp then
        for _, obj in pairs(esp.Box) do obj:Remove() end
        esp.Tracer:Remove()
        for _, obj in pairs(esp.HealthBar) do obj:Remove() end
        for _, obj in pairs(esp.Info) do obj:Remove() end
        esp.Snapline:Remove()
        Drawings.ESP[player] = nil
    end
    local hl = Highlights[player]
    if hl then hl:Destroy(); Highlights[player] = nil end
    local sk = Drawings.Skeleton[player]
    if sk then
        for _, line in pairs(sk) do line:Remove() end
        Drawings.Skeleton[player] = nil
    end
end

local function GetPlayerColor(player)
    if ESPSettings.RainbowEnabled then
        if ESPSettings.RainbowBoxes and ESPSettings.BoxESP then return ESPColors.Rainbow end
        if ESPSettings.RainbowTracers and ESPSettings.TracerESP then return ESPColors.Rainbow end
        if ESPSettings.RainbowText and (ESPSettings.NameESP or ESPSettings.HealthESP) then return ESPColors.Rainbow end
    end
    return player.Team == LocalPlayer.Team and ESPColors.Ally or ESPColors.Enemy
end

local function GetTracerOrigin()
    local o = ESPSettings.TracerOrigin
    if o == "Bottom" then
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
    elseif o == "Top" then
        return Vector2.new(Camera.ViewportSize.X/2, 0)
    elseif o == "Mouse" then
        return UserInputService:GetMouseLocation()
    else
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
end

local function UpdateESP(player)
    if not ESPSettings.Enabled then return end

    local esp = Drawings.ESP[player]
    if not esp then return end

    local function hideAll()
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        local sk = Drawings.Skeleton[player]
        if sk then for _, l in pairs(sk) do l.Visible = false end end
    end

    local character = player.Character
    if not character then hideAll(); return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then hideAll(); return end

    local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    if not onScreen then hideAll(); return end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then hideAll(); return end

    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    if distance > ESPSettings.MaxDistance then hideAll(); return end

    if ESPSettings.TeamCheck and player.Team == LocalPlayer.Team and not ESPSettings.ShowTeam then
        hideAll(); return
    end

    local color = GetPlayerColor(player)
    local size = character:GetExtentsSize()
    local cf = rootPart.CFrame

    local top, top_onscreen = Camera:WorldToViewportPoint(cf * CFrame.new(0, size.Y/2, 0).Position)
    local bottom, bottom_onscreen = Camera:WorldToViewportPoint(cf * CFrame.new(0, -size.Y/2, 0).Position)
    if not top_onscreen or not bottom_onscreen then hideAll(); return end

    local screenSize = bottom.Y - top.Y
    local boxWidth = screenSize * 0.65
    local boxPosition = Vector2.new(top.X - boxWidth/2, top.Y)
    local boxSize = Vector2.new(boxWidth, screenSize)

    for _, obj in pairs(esp.Box) do obj.Visible = false end

    if ESPSettings.BoxESP then
        if ESPSettings.BoxStyle == "ThreeD" then
            local front = {
                TL = Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2)).Position),
                TR = Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2)).Position),
                BL = Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2)).Position),
                BR = Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2)).Position)
            }
            local back = {
                TL = Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2)).Position),
                TR = Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, size.Y/2, size.Z/2)).Position),
                BL = Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2)).Position),
                BR = Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2)).Position)
            }
            if not (front.TL.Z > 0 and front.TR.Z > 0 and front.BL.Z > 0 and front.BR.Z > 0 and
                   back.TL.Z > 0 and back.TR.Z > 0 and back.BL.Z > 0 and back.BR.Z > 0) then
                for _, obj in pairs(esp.Box) do obj.Visible = false end; return
            end
            local function toV2(v3) return Vector2.new(v3.X, v3.Y) end
            front.TL, front.TR = toV2(front.TL), toV2(front.TR)
            front.BL, front.BR = toV2(front.BL), toV2(front.BR)
            back.TL, back.TR = toV2(back.TL), toV2(back.TR)
            back.BL, back.BR = toV2(back.BL), toV2(back.BR)

            esp.Box.TopLeft.From = front.TL; esp.Box.TopLeft.To = front.TR; esp.Box.TopLeft.Visible = true
            esp.Box.TopRight.From = front.TR; esp.Box.TopRight.To = front.BR; esp.Box.TopRight.Visible = true
            esp.Box.BottomLeft.From = front.BL; esp.Box.BottomLeft.To = front.BR; esp.Box.BottomLeft.Visible = true
            esp.Box.BottomRight.From = front.TL; esp.Box.BottomRight.To = front.BL; esp.Box.BottomRight.Visible = true
            esp.Box.Left.From = back.TL; esp.Box.Left.To = back.TR; esp.Box.Left.Visible = true
            esp.Box.Right.From = back.TR; esp.Box.Right.To = back.BR; esp.Box.Right.Visible = true
            esp.Box.Top.From = back.BL; esp.Box.Top.To = back.BR; esp.Box.Top.Visible = true
            esp.Box.Bottom.From = back.TL; esp.Box.Bottom.To = back.BL; esp.Box.Bottom.Visible = true

            local connectors = {
                Drawing.new("Line"), Drawing.new("Line"),
                Drawing.new("Line"), Drawing.new("Line")
            }
            local connPoints = {{front.TL, back.TL}, {front.TR, back.TR}, {front.BL, back.BL}, {front.BR, back.BR}}
            for i, ln in ipairs(connectors) do
                ln.From = connPoints[i][1]; ln.To = connPoints[i][2]
                ln.Color = color; ln.Thickness = ESPSettings.BoxThickness; ln.Visible = true
            end
            task.spawn(function() task.wait(); for _, ln in ipairs(connectors) do ln:Remove() end end)
        elseif ESPSettings.BoxStyle == "Corner" then
            local cs = boxWidth * 0.2
            esp.Box.TopLeft.From = boxPosition; esp.Box.TopLeft.To = boxPosition + Vector2.new(cs, 0); esp.Box.TopLeft.Visible = true
            esp.Box.TopRight.From = boxPosition + Vector2.new(boxSize.X, 0); esp.Box.TopRight.To = boxPosition + Vector2.new(boxSize.X - cs, 0); esp.Box.TopRight.Visible = true
            esp.Box.BottomLeft.From = boxPosition + Vector2.new(0, boxSize.Y); esp.Box.BottomLeft.To = boxPosition + Vector2.new(cs, boxSize.Y); esp.Box.BottomLeft.Visible = true
            esp.Box.BottomRight.From = boxPosition + Vector2.new(boxSize.X, boxSize.Y); esp.Box.BottomRight.To = boxPosition + Vector2.new(boxSize.X - cs, boxSize.Y); esp.Box.BottomRight.Visible = true
            esp.Box.Left.From = boxPosition; esp.Box.Left.To = boxPosition + Vector2.new(0, cs); esp.Box.Left.Visible = true
            esp.Box.Right.From = boxPosition + Vector2.new(boxSize.X, 0); esp.Box.Right.To = boxPosition + Vector2.new(boxSize.X, cs); esp.Box.Right.Visible = true
            esp.Box.Top.From = boxPosition + Vector2.new(0, boxSize.Y); esp.Box.Top.To = boxPosition + Vector2.new(0, boxSize.Y - cs); esp.Box.Top.Visible = true
            esp.Box.Bottom.From = boxPosition + Vector2.new(boxSize.X, boxSize.Y); esp.Box.Bottom.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y - cs); esp.Box.Bottom.Visible = true
        else
            esp.Box.Left.From = boxPosition; esp.Box.Left.To = boxPosition + Vector2.new(0, boxSize.Y); esp.Box.Left.Visible = true
            esp.Box.Right.From = boxPosition + Vector2.new(boxSize.X, 0); esp.Box.Right.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y); esp.Box.Right.Visible = true
            esp.Box.Top.From = boxPosition; esp.Box.Top.To = boxPosition + Vector2.new(boxSize.X, 0); esp.Box.Top.Visible = true
            esp.Box.Bottom.From = boxPosition + Vector2.new(0, boxSize.Y); esp.Box.Bottom.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y); esp.Box.Bottom.Visible = true
        end
        for _, obj in pairs(esp.Box) do
            if obj.Visible then obj.Color = color; obj.Thickness = ESPSettings.BoxThickness end
        end
    end

    if ESPSettings.TracerESP then
        esp.Tracer.From = GetTracerOrigin()
        esp.Tracer.To = Vector2.new(pos.X, pos.Y)
        esp.Tracer.Color = color; esp.Tracer.Visible = true
    else esp.Tracer.Visible = false end

    if ESPSettings.HealthESP then
        local health = humanoid.Health; local maxHealth = humanoid.MaxHealth
        local hp = health / maxHealth
        local bh = screenSize * 0.8; local bw = 4
        local barPos = Vector2.new(boxPosition.X - bw - 2, boxPosition.Y + (screenSize - bh)/2)
        esp.HealthBar.Outline.Size = Vector2.new(bw, bh)
        esp.HealthBar.Outline.Position = barPos; esp.HealthBar.Outline.Visible = true
        esp.HealthBar.Fill.Size = Vector2.new(bw - 2, bh * hp)
        esp.HealthBar.Fill.Position = Vector2.new(barPos.X + 1, barPos.Y + bh * (1 - hp))
        esp.HealthBar.Fill.Color = Color3.fromRGB(255 - (255 * hp), 255 * hp, 0)
        esp.HealthBar.Fill.Visible = true
        if ESPSettings.HealthStyle == "Both" or ESPSettings.HealthStyle == "Text" then
            esp.HealthBar.Text.Text = math.floor(health) .. ESPSettings.HealthTextSuffix
            esp.HealthBar.Text.Position = Vector2.new(barPos.X + bw + 2, barPos.Y + bh/2)
            esp.HealthBar.Text.Visible = true
        else esp.HealthBar.Text.Visible = false end
    else
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
    end

    if ESPSettings.NameESP then
        esp.Info.Name.Text = player.DisplayName
        esp.Info.Name.Position = Vector2.new(boxPosition.X + boxWidth/2, boxPosition.Y - 20)
        esp.Info.Name.Color = color; esp.Info.Name.Visible = true
    else esp.Info.Name.Visible = false end

    if ESPSettings.Snaplines then
        esp.Snapline.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        esp.Snapline.To = Vector2.new(pos.X, pos.Y)
        esp.Snapline.Color = color; esp.Snapline.Visible = true
    else esp.Snapline.Visible = false end

    local hl = Highlights[player]
    if hl then
        if ESPSettings.ChamsEnabled and character then
            hl.Parent = character; hl.FillColor = ESPSettings.ChamsFillColor
            hl.OutlineColor = ESPSettings.ChamsOutlineColor
            hl.FillTransparency = ESPSettings.ChamsTransparency
            hl.OutlineTransparency = ESPSettings.ChamsOutlineTransparency; hl.Enabled = true
        else hl.Enabled = false end
    end

    if ESPSettings.SkeletonESP then
        local function getBones(ch)
            if not ch then return nil end
            return {
                Head = ch:FindFirstChild("Head"),
                UpperTorso = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso"),
                LowerTorso = ch:FindFirstChild("LowerTorso") or ch:FindFirstChild("Torso"),
                LeftUpperArm = ch:FindFirstChild("LeftUpperArm") or ch:FindFirstChild("Left Arm"),
                LeftLowerArm = ch:FindFirstChild("LeftLowerArm") or ch:FindFirstChild("Left Arm"),
                LeftHand = ch:FindFirstChild("LeftHand") or ch:FindFirstChild("Left Arm"),
                RightUpperArm = ch:FindFirstChild("RightUpperArm") or ch:FindFirstChild("Right Arm"),
                RightLowerArm = ch:FindFirstChild("RightLowerArm") or ch:FindFirstChild("Right Arm"),
                RightHand = ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm"),
                LeftUpperLeg = ch:FindFirstChild("LeftUpperLeg") or ch:FindFirstChild("Left Leg"),
                LeftLowerLeg = ch:FindFirstChild("LeftLowerLeg") or ch:FindFirstChild("Left Leg"),
                LeftFoot = ch:FindFirstChild("LeftFoot") or ch:FindFirstChild("Left Leg"),
                RightUpperLeg = ch:FindFirstChild("RightUpperLeg") or ch:FindFirstChild("Right Leg"),
                RightLowerLeg = ch:FindFirstChild("RightLowerLeg") or ch:FindFirstChild("Right Leg"),
                RightFoot = ch:FindFirstChild("RightFoot") or ch:FindFirstChild("Right Leg")
            }
        end
        local function drawBone(from, to, line)
            if not from or not to then line.Visible = false; return end
            local fp = (from.CFrame * CFrame.new(0,0,0)).Position
            local tp = (to.CFrame * CFrame.new(0,0,0)).Position
            local fs, fv = Camera:WorldToViewportPoint(fp)
            local ts, tv = Camera:WorldToViewportPoint(tp)
            if not (fv and tv) or fs.Z < 0 or ts.Z < 0 then line.Visible = false; return end
            local sb = Camera.ViewportSize
            if fs.X < 0 or fs.X > sb.X or fs.Y < 0 or fs.Y > sb.Y or
               ts.X < 0 or ts.X > sb.X or ts.Y < 0 or ts.Y > sb.Y then line.Visible = false; return end
            line.From = Vector2.new(fs.X, fs.Y); line.To = Vector2.new(ts.X, ts.Y)
            line.Color = ESPSettings.SkeletonColor; line.Thickness = ESPSettings.SkeletonThickness
            line.Transparency = ESPSettings.SkeletonTransparency; line.Visible = true
        end
        local bones = getBones(character)
        if bones then
            local sk = Drawings.Skeleton[player]
            if sk then
                drawBone(bones.Head, bones.UpperTorso, sk.Head)
                drawBone(bones.UpperTorso, bones.LowerTorso, sk.UpperSpine)
                drawBone(bones.UpperTorso, bones.LeftUpperArm, sk.LeftShoulder)
                drawBone(bones.LeftUpperArm, bones.LeftLowerArm, sk.LeftUpperArm)
                drawBone(bones.LeftLowerArm, bones.LeftHand, sk.LeftLowerArm)
                drawBone(bones.UpperTorso, bones.RightUpperArm, sk.RightShoulder)
                drawBone(bones.RightUpperArm, bones.RightLowerArm, sk.RightUpperArm)
                drawBone(bones.RightLowerArm, bones.RightHand, sk.RightLowerArm)
                drawBone(bones.LowerTorso, bones.LeftUpperLeg, sk.LeftHip)
                drawBone(bones.LeftUpperLeg, bones.LeftLowerLeg, sk.LeftUpperLeg)
                drawBone(bones.LeftLowerLeg, bones.LeftFoot, sk.LeftLowerLeg)
                drawBone(bones.LowerTorso, bones.RightUpperLeg, sk.RightHip)
                drawBone(bones.RightUpperLeg, bones.RightLowerLeg, sk.RightUpperLeg)
                drawBone(bones.RightLowerLeg, bones.RightFoot, sk.RightLowerLeg)
            end
        end
    else
        local sk = Drawings.Skeleton[player]
        if sk then for _, l in pairs(sk) do l.Visible = false end end
    end
end

local function CleanupESP()
    for _, player in ipairs(Players:GetPlayers()) do RemoveESP(player) end
    Drawings.ESP = {}; Drawings.Skeleton = {}; Highlights = {}
end

-- ═══════════════════════════════════════════════
-- AIMBOT
-- ═══════════════════════════════════════════════

local function GetClosestTarget()
    local closest = nil; local shortest = math.huge
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            local head = v.Character:FindFirstChild("Head")
            if head then
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local distFromCenter = (Vector2.new(sp.X, sp.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    local myHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
                    local dist3D = myHead and (head.Position - myHead.Position).Magnitude or math.huge
                    if distFromCenter <= fovCircle.Radius and dist3D < shortest then
                        shortest = dist3D; closest = head
                    end
                end
            end
        end
    end
    return closest
end

-- ═══════════════════════════════════════════════
-- FLUENT UI
-- ═══════════════════════════════════════════════

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "WA Universal Hub",
    SubTitle = "by WA",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 520),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Aimbot = Window:AddTab({ Title = "Aimbot", Icon = "crosshair" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "swords" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Config = Window:AddTab({ Title = "Config", Icon = "save" })
}

-- ── ESP Tab ──
do
    local MainSection = Tabs.ESP:AddSection("Main ESP")
    local tglEnabled = MainSection:AddToggle("ESPEnabled", { Title = "Enable ESP", Default = false })
    tglEnabled:OnChanged(function() ESPSettings.Enabled = tglEnabled.Value
        if not ESPSettings.Enabled then CleanupESP()
        else for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateESP(p) end end end
    end)
    local tglTeamCheck = MainSection:AddToggle("ESPTeamCheck", { Title = "Team Check", Default = false })
    tglTeamCheck:OnChanged(function() ESPSettings.TeamCheck = tglTeamCheck.Value end)
    local tglShowTeam = MainSection:AddToggle("ESPShowTeam", { Title = "Show Team", Default = false })
    tglShowTeam:OnChanged(function() ESPSettings.ShowTeam = tglShowTeam.Value end)

    local BoxSection = Tabs.ESP:AddSection("Box ESP")
    local tglBox = BoxSection:AddToggle("BoxESP", { Title = "Box ESP", Default = false })
    tglBox:OnChanged(function() ESPSettings.BoxESP = tglBox.Value end)
    local ddBoxStyle = BoxSection:AddDropdown("BoxStyle", { Title = "Box Style", Values = {"Corner", "Full", "ThreeD"}, Default = "Corner" })
    ddBoxStyle:OnChanged(function(v) ESPSettings.BoxStyle = v end)

    local TracerSection = Tabs.ESP:AddSection("Tracer ESP")
    local tglTracer = TracerSection:AddToggle("TracerESP", { Title = "Tracer ESP", Default = false })
    tglTracer:OnChanged(function() ESPSettings.TracerESP = tglTracer.Value end)
    local ddOrigin = TracerSection:AddDropdown("TracerOrigin", { Title = "Tracer Origin", Values = {"Bottom", "Top", "Mouse", "Center"}, Default = "Bottom" })
    ddOrigin:OnChanged(function(v) ESPSettings.TracerOrigin = v end)

    local HealthSection = Tabs.ESP:AddSection("Health ESP")
    local tglHP = HealthSection:AddToggle("HealthESP", { Title = "Health Bar", Default = false })
    tglHP:OnChanged(function() ESPSettings.HealthESP = tglHP.Value end)
    local ddHPStyle = HealthSection:AddDropdown("HealthStyle", { Title = "Health Style", Values = {"Bar", "Text", "Both"}, Default = "Bar" })
    ddHPStyle:OnChanged(function(v) ESPSettings.HealthStyle = v end)

    local SkeletonSection = Tabs.ESP:AddSection("Skeleton ESP")
    local tglSkel = SkeletonSection:AddToggle("SkeletonESP", { Title = "Skeleton ESP", Default = false })
    tglSkel:OnChanged(function() ESPSettings.SkeletonESP = tglSkel.Value end)
    local cpSkelColor = SkeletonSection:AddColorpicker("SkeletonColor", { Title = "Skeleton Color", Default = ESPSettings.SkeletonColor })
    cpSkelColor:OnChanged(function(v) ESPSettings.SkeletonColor = v
        for _, p in ipairs(Players:GetPlayers()) do local sk = Drawings.Skeleton[p]; if sk then for _, l in pairs(sk) do l.Color = v end end end
    end)
    local slSkelThick = SkeletonSection:AddSlider("SkeletonThickness", { Title = "Line Thickness", Default = 1, Min = 1, Max = 3, Rounding = 1 })
    slSkelThick:OnChanged(function(v) ESPSettings.SkeletonThickness = v
        for _, p in ipairs(Players:GetPlayers()) do local sk = Drawings.Skeleton[p]; if sk then for _, l in pairs(sk) do l.Thickness = v end end end
    end)
    local slSkelTrans = SkeletonSection:AddSlider("SkeletonTransparency", { Title = "Transparency", Default = 1, Min = 0, Max = 1, Rounding = 2 })
    slSkelTrans:OnChanged(function(v) ESPSettings.SkeletonTransparency = v
        for _, p in ipairs(Players:GetPlayers()) do local sk = Drawings.Skeleton[p]; if sk then for _, l in pairs(sk) do l.Transparency = v end end end
    end)

    local ChamsSection = Tabs.ESP:AddSection("Chams")
    local tglChams = ChamsSection:AddToggle("ChamsEnabled", { Title = "Enable Chams", Default = false })
    tglChams:OnChanged(function() ESPSettings.ChamsEnabled = tglChams.Value end)
    local cpFill = ChamsSection:AddColorpicker("ChamsFill", { Title = "Fill Color", Default = ESPSettings.ChamsFillColor })
    cpFill:OnChanged(function(v) ESPSettings.ChamsFillColor = v end)
    local cpOcc = ChamsSection:AddColorpicker("ChamsOccluded", { Title = "Occluded Color", Default = ESPSettings.ChamsOccludedColor })
    cpOcc:OnChanged(function(v) ESPSettings.ChamsOccludedColor = v end)
    local cpOutline = ChamsSection:AddColorpicker("ChamsOutline", { Title = "Outline Color", Default = ESPSettings.ChamsOutlineColor })
    cpOutline:OnChanged(function(v) ESPSettings.ChamsOutlineColor = v end)
    local slFillTrans = ChamsSection:AddSlider("ChamsFillTrans", { Title = "Fill Transparency", Default = 0.5, Min = 0, Max = 1, Rounding = 2 })
    slFillTrans:OnChanged(function(v) ESPSettings.ChamsTransparency = v end)
    local slOutlineTrans = ChamsSection:AddSlider("ChamsOutlineTrans", { Title = "Outline Transparency", Default = 0, Min = 0, Max = 1, Rounding = 2 })
    slOutlineTrans:OnChanged(function(v) ESPSettings.ChamsOutlineTransparency = v end)
    local slOutlineThick = ChamsSection:AddSlider("ChamsOutlineThick", { Title = "Outline Thickness", Default = 0.1, Min = 0, Max = 1, Rounding = 2 })
    slOutlineThick:OnChanged(function(v) ESPSettings.ChamsOutlineThickness = v end)
end

-- ── Aimbot Tab ──
do
    local MainSection = Tabs.Aimbot:AddSection("Aimbot")
    local tglAim = MainSection:AddToggle("AimbotEnabled", { Title = "Enable Aimbot", Default = false })
    tglAim:OnChanged(function() AimbotSettings.Enabled = tglAim.Value end)
    local slFOV = MainSection:AddSlider("AimbotFOV", { Title = "FOV Radius", Default = 100, Min = 10, Max = 500, Rounding = 0 })
    slFOV:OnChanged(function(v) AimbotSettings.FOVRadius = v; fovCircle.Radius = v end)
    local tglFOVVis = MainSection:AddToggle("FOVVisible", { Title = "Show FOV Circle", Default = true })
    tglFOVVis:OnChanged(function() AimbotSettings.FOVVisible = tglFOVVis.Value; fovCircle.Visible = AimbotSettings.FOVVisible end)
    local cpFOV = MainSection:AddColorpicker("FOVColor", { Title = "FOV Color", Default = AimbotSettings.FOVColor })
    cpFOV:OnChanged(function(v) AimbotSettings.FOVColor = v; fovCircle.Color = v end)
    local slFOVTrans = MainSection:AddSlider("FOVTransparency", { Title = "FOV Transparency", Default = 0.6, Min = 0, Max = 1, Rounding = 2 })
    slFOVTrans:OnChanged(function(v) AimbotSettings.FOVTransparency = v; fovCircle.Transparency = v end)
    local tglFOVFill = MainSection:AddToggle("FOVFilled", { Title = "FOV Filled", Default = false })
    tglFOVFill:OnChanged(function() AimbotSettings.FOVFilled = tglFOVFill.Value; fovCircle.Filled = AimbotSettings.FOVFilled end)
    local slFOVThick = MainSection:AddSlider("FOVThickness", { Title = "FOV Thickness", Default = 1, Min = 1, Max = 5, Rounding = 1 })
    slFOVThick:OnChanged(function(v) AimbotSettings.FOVThickness = v; fovCircle.Thickness = v end)

    local KeySection = Tabs.Aimbot:AddSection("Key Bindings")
    local ddAimKey = KeySection:AddDropdown("AimKey", { Title = "Aim Key", Values = {"MouseButton2", "MouseButton1", "LeftControl", "LeftShift"}, Default = "MouseButton2" })
    ddAimKey:OnChanged(function(v) AimbotSettings.AimKey = Enum.UserInputType[v] or Enum.KeyCode[v] end)
end

-- ── Combat / Auto-Click Tab ──
do
    local MainSection = Tabs.Combat:AddSection("Auto Click")
    local tglAC = MainSection:AddToggle("ACEnabled", { Title = "Enable Auto Click", Default = false })
    tglAC:OnChanged(function() ACSettings.Enabled = tglAC.Value
        if not ACSettings.Enabled and ACCurrentlyPressed then
            ACCurrentlyPressed = false; mouse1release()
        end
    end)
    local tglHold = MainSection:AddToggle("ACHoldClick", { Title = "Hold Click (hold mouse1)", Default = true })
    tglHold:OnChanged(function() ACSettings.HoldClick = tglHold.Value end)
    local tbHotkey = MainSection:AddInput("ACHotkey", { Title = "Hotkey (leave blank for always on)", Default = "t", Placeholder = "t" })
    tbHotkey:OnChanged(function(v) ACSettings.Hotkey = v end)
    local tglToggle = MainSection:AddToggle("ACToggleMode", { Title = "Toggle on press", Default = true })
    tglToggle:OnChanged(function() ACSettings.HotkeyToggle = tglToggle.Value end)
end

-- ── Settings Tab ──
do
    local ColorsSection = Tabs.Settings:AddSection("Colors")
    local cpEnemy = ColorsSection:AddColorpicker("EnemyColor", { Title = "ESP Enemy Color", Default = ESPColors.Enemy })
    cpEnemy:OnChanged(function(v) ESPColors.Enemy = v end)
    local cpAlly = ColorsSection:AddColorpicker("AllyColor", { Title = "ESP Ally Color", Default = ESPColors.Ally })
    cpAlly:OnChanged(function(v) ESPColors.Ally = v end)
    local cpHealth = ColorsSection:AddColorpicker("HealthColor", { Title = "Health Bar Color", Default = ESPColors.Health })
    cpHealth:OnChanged(function(v) ESPColors.Health = v end)

    local BoxSettings = Tabs.Settings:AddSection("Box Settings")
    local slBoxThick = BoxSettings:AddSlider("BoxThickness", { Title = "Box Thickness", Default = 1, Min = 1, Max = 5, Rounding = 1 })
    slBoxThick:OnChanged(function(v) ESPSettings.BoxThickness = v end)
    local slBoxTrans = BoxSettings:AddSlider("BoxTransparency", { Title = "Box Transparency", Default = 1, Min = 0, Max = 1, Rounding = 2 })
    slBoxTrans:OnChanged(function(v) ESPSettings.BoxFillTransparency = v end)

    local ESPSect = Tabs.Settings:AddSection("ESP Settings")
    local slMaxDist = ESPSect:AddSlider("MaxDistance", { Title = "Max Distance", Default = 1000, Min = 100, Max = 5000, Rounding = 0 })
    slMaxDist:OnChanged(function(v) ESPSettings.MaxDistance = v end)
    local slTextSize = ESPSect:AddSlider("TextSize", { Title = "Text Size", Default = 14, Min = 10, Max = 24, Rounding = 0 })
    slTextSize:OnChanged(function(v) ESPSettings.TextSize = v end)

    local EffectsSection = Tabs.Settings:AddSection("Effects")
    local tglRainbow = EffectsSection:AddToggle("RainbowEnabled", { Title = "Rainbow Mode", Default = false })
    tglRainbow:OnChanged(function() ESPSettings.RainbowEnabled = tglRainbow.Value end)
    local slRainbowSpeed = EffectsSection:AddSlider("RainbowSpeed", { Title = "Rainbow Speed", Default = 1, Min = 0.1, Max = 5, Rounding = 1 })
    slRainbowSpeed:OnChanged(function(v) ESPSettings.RainbowSpeed = v end)
    local ddRainbow = EffectsSection:AddDropdown("RainbowParts", { Title = "Rainbow Parts", Values = {"All", "Box Only", "Tracers Only", "Text Only"}, Default = "All" })
    ddRainbow:OnChanged(function(v)
        ESPSettings.RainbowBoxes = (v == "All" or v == "Box Only")
        ESPSettings.RainbowTracers = (v == "All" or v == "Tracers Only")
        ESPSettings.RainbowText = (v == "All" or v == "Text Only")
    end)

    local PerfSection = Tabs.Settings:AddSection("Performance")
    local slRefresh = PerfSection:AddSlider("RefreshRate", { Title = "Refresh Rate", Default = 144, Min = 1, Max = 144, Rounding = 0 })
    slRefresh:OnChanged(function(v) ESPSettings.RefreshRate = 1/v end)

    local SnaplineSection = Tabs.Settings:AddSection("Snaplines")
    local tglSnap = SnaplineSection:AddToggle("Snaplines", { Title = "Enable Snaplines", Default = false })
    tglSnap:OnChanged(function() ESPSettings.Snaplines = tglSnap.Value end)
end

-- ── Config Tab ──
do
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    InterfaceManager:SetFolder("WAUniversalHub")
    SaveManager:SetFolder("WAUniversalHub/configs")
    InterfaceManager:BuildInterfaceSection(Tabs.Config)
    SaveManager:BuildConfigSection(Tabs.Config)

    local UnloadSection = Tabs.Config:AddSection("Unload")
    UnloadSection:AddButton({
        Title = "Unload All",
        Description = "Completely remove the script",
        Callback = function()
            CleanupESP()
            for _, conn in pairs(getconnections(RunService.RenderStepped)) do conn:Disable() end
            Window:Destroy()
            for k, v in pairs(getfenv(1)) do getfenv(1)[k] = nil end
        end
    })
end

task.spawn(function()
    while task.wait(0.1) do
        ESPColors.Rainbow = Color3.fromHSV(tick() * ESPSettings.RainbowSpeed % 1, 1, 1)
    end
end)

-- ═══════════════════════════════════════════════
-- MAIN LOOPS
-- ═══════════════════════════════════════════════

local lastUpdate = 0
RunService.RenderStepped:Connect(function()
    if ESPSettings.Enabled then
        local currentTime = tick()
        if currentTime - lastUpdate >= ESPSettings.RefreshRate then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    if not Drawings.ESP[p] then CreateESP(p) end
                    UpdateESP(p)
                end
            end
            lastUpdate = currentTime
        end
    end
end)

RunService.RenderStepped:Connect(UpdateAutoClick)

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    if AimbotSettings.Enabled and aiming then
        local target = GetClosestTarget()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == AimbotSettings.AimKey or input.KeyCode == AimbotSettings.AimKey then
        aiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == AimbotSettings.AimKey or input.KeyCode == AimbotSettings.AimKey then
        aiming = false
    end
end)

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then CreateESP(p) end
end

Window:SelectTab(1)

Fluent:Notify({
    Title = "WA Universal Hub",
    Content = "Loaded successfully!",
    Duration = 5
})
