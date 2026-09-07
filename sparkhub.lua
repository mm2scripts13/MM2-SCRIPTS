    if getgenv and getgenv().IdenticalMM2Unload then
        pcall(getgenv().IdenticalMM2Unload)
    end

    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local HttpService = game:GetService("HttpService")
    local CoreGui = game:GetService("CoreGui")
    local Lighting = game:GetService("Lighting")
    local TeleportService = game:GetService("TeleportService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TextChatService = game:GetService("TextChatService")

    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    local Config = {
        RoundTimer = true,
        DeathNotifs = true,
        RoleReveals = true,
        AnnounceRoles = false,

        AutoShoot = false,
        SilentAim = false,
        AimPrediction = true,
        PingComp = true,
        SingleShot = false,
        FOVRadius = 160,
        ShowFOV = false,
        AutoEquipGun = true,
        GrabGunAuto = false,
        GunGrabDist = 300,

        KillAura = false,
        AutoKill = false,
        KillMode = "Legit",
        KnifeSilentAim = true,
        AuraRange = 15,
        KillAll = false,
        ShowAuraRing = false,
        AutoEquipKnife = true,
        ProximityKnife = true,
        KnifeProxDist = 18,

        HitboxExpander = false,
        HitboxSize = 10,
        HitboxTransparency = 0.6,

        MurdererAvoid = false,
        SafetyRadius = 40,
        RetreatToLobby = false,
        ProximityAlert = true,
        SprintWhenChased = true,
        FollowMurderer = false,
        FollowDist = 18,

        RoleESP = true,
        ESPBoxes = true,
        ESPNames = true,
        ESPTracers = false,
        ESPDistance = true,
        ESPChams = true,
        ESPDistanceMax = 600,
        GunESP = true,
        CoinESP = true,

        CoinFarm = false,
        FarmSpeed = 28,
        FarmMethod = "Glide",
        SafeCoinFarm = true,
        BagFullStop = true,
        QuickFarm = false,
        CoinBagCap = 40,

        FlingStyle = "Torque",
        FlingPower = 90,

        AutoDrop = false,
        SaveSlot1 = nil,
        SaveSlot2 = nil,

        SpeedEnabled = false,
        SpeedValue = 24,
        JumpEnabled = false,
        JumpValue = 50,
        InfiniteJump = false,
        Noclip = false,
        Fly = false,
        FlySpeed = 35,

        AntiVoid = true,
        AntiFling = true,
        Fullbright = false,
        NoFog = false,
        DisableParticles = false,
        AntiAFK = true,

        AutoPlay = false
    }

    local DefaultConfig = {}
    for k, v in pairs(Config) do
        DefaultConfig[k] = v
    end

    local CONFIG_FILE = "Identical/mm2_config.json"

    local function LoadSavedConfig()
        if isfile and isfile(CONFIG_FILE) then
            local ok, data = pcall(function()
                return HttpService:JSONDecode(readfile(CONFIG_FILE))
            end)
            if ok and type(data) == "table" then
                for k, v in pairs(data) do
                    if Config[k] ~= nil then
                        if type(v) == "table" and (k == "SaveSlot1" or k == "SaveSlot2") then
                            Config[k] = CFrame.new(unpack(v))
                        else
                            Config[k] = v
                        end
                    end
                end
                return true
            end
        end
        return false
    end

    local saveDebounce = false
    local function AutoSaveConfig()
        if not writefile then return end
        if saveDebounce then return end
        saveDebounce = true
        task.delay(0.25, function()
            saveDebounce = false
            pcall(function()
                if makefolder and not isfolder("Identical") then
                    makefolder("Identical")
                end
                local payload = {}
                for k, v in pairs(Config) do
                    if typeof(v) == "CFrame" then
                        payload[k] = {v:GetComponents()}
                    elseif typeof(v) == "EnumItem" then
                        payload[k] = v.Name
                    else
                        payload[k] = v
                    end
                end
                writefile(CONFIG_FILE, HttpService:JSONEncode(payload))
            end)
        end)
    end

    LoadSavedConfig()

    local isSyncingUI = false
    local SyncUIWithConfig = nil
    local ctrls = {}

    local Colors = {
        Background = Color3.fromRGB(13, 11, 20),
        SidebarBg = Color3.fromRGB(11, 9, 17),
        CardBg = Color3.fromRGB(19, 16, 28),
        ControlBg = Color3.fromRGB(26, 22, 38),
        BorderPurple = Color3.fromRGB(88, 48, 145),
        PurplePrimary = Color3.fromRGB(192, 132, 252),
        PurpleAccent = Color3.fromRGB(168, 85, 247),
        PurpleDark = Color3.fromRGB(58, 28, 92),
        PurpleGlow = Color3.fromRGB(147, 51, 234),
        PurpleMuted = Color3.fromRGB(120, 85, 160),
        TextPrimary = Color3.fromRGB(243, 240, 255),
        TextMuted = Color3.fromRGB(140, 130, 165),
        TextSubtle = Color3.fromRGB(95, 88, 118),
        Divider = Color3.fromRGB(35, 30, 52),
        AccentGreen = Color3.fromRGB(52, 211, 153),
        AccentRed = Color3.fromRGB(248, 113, 113),
        AccentBlue = Color3.fromRGB(96, 165, 250),
        AccentYellow = Color3.fromRGB(251, 191, 36)
    }

    local espFolder = CoreGui:FindFirstChild("Identical_MM2_ESP") or LocalPlayer.PlayerGui:FindFirstChild("Identical_MM2_ESP")
    if not espFolder then
        espFolder = Instance.new("Folder")
        espFolder.Name = "Identical_MM2_ESP"
        pcall(function() espFolder.Parent = CoreGui end)
        if not espFolder.Parent then espFolder.Parent = LocalPlayer.PlayerGui end
    end

    local activeConnections = {}
    local trackedESPElements = {}
    local deadPlayersList = {}
    local originalHitboxSizes = {}
    local isFlinging = false

    local function fireTouch(part1, part2)
        if firetouchinterest and part1 and part2 then
            local ft = firetouchinterest
            pcall(ft, part1, part2, true)
            pcall(ft, part1, part2, 0)
            task.wait()
            pcall(ft, part1, part2, false)
            pcall(ft, part1, part2, 1)
        end
    end

    local trackedTracers = {}

    local function clearESPCategory(prefix)
        local toRemove = {}
        for id in pairs(trackedESPElements) do
            if string.sub(id, 1, string.len(prefix)) == prefix then
                table.insert(toRemove, id)
            end
        end
        for _, id in ipairs(toRemove) do
            if trackedESPElements[id] then
                pcall(function() trackedESPElements[id]:Destroy() end)
                trackedESPElements[id] = nil
            end
        end
        local tracersToRemove = {}
        for id in pairs(trackedTracers) do
            if string.sub(id, 1, string.len(prefix)) == prefix then
                table.insert(tracersToRemove, id)
            end
        end
        for _, id in ipairs(tracersToRemove) do
            if trackedTracers[id] then
                pcall(function() trackedTracers[id]:Remove() end)
                trackedTracers[id] = nil
            end
        end
        for _, c in ipairs(espFolder:GetChildren()) do
            if string.sub(c.Name, 1, string.len(prefix)) == prefix then
                pcall(function() c:Destroy() end)
            end
        end
    end

    local function getRootPart(char)
        if not char then return nil end
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChildWhichIsA("BasePart")
    end

    local function getHumanoid(char)
        if not char then return nil end
        return char:FindFirstChildOfClass("Humanoid")
    end

    local function isPlayerAlive(p)
        if not p or not p.Character then return false end
        local hum = getHumanoid(p.Character)
        return hum ~= nil and hum.Health > 0
    end

    local function getPlayerRole(p)
        if not p then return "Innocent" end
        local bp = p:FindFirstChild("Backpack")
        local char = p.Character
        local knife = (bp and bp:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife"))
        local gun = (bp and bp:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun"))
        if knife then
            return "Murderer"
        elseif gun then
            return "Sheriff"
        end
        return "Innocent"
    end

    local function getRolePlayers()
        local murderer = nil
        local sheriff = nil
        local innocents = {}

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and isPlayerAlive(p) then
                local r = getPlayerRole(p)
                if r == "Murderer" then
                    murderer = p
                elseif r == "Sheriff" then
                    sheriff = p
                else
                    table.insert(innocents, p)
                end
            end
        end
        return murderer, sheriff, innocents
    end

    local function getActiveMap()
        for _, c in ipairs(Workspace:GetChildren()) do
            if c:IsA("Model") and not string.find(string.lower(c.Name), "lobby") and not Players:GetPlayerFromCharacter(c) then
                if c:FindFirstChild("Spawns") or c:FindFirstChild("CoinAreas") or c:FindFirstChild("CoinContainer") or c:FindFirstChild("Base") then
                    return c
                end
            end
        end
        return nil
    end

    local function getLobbyModel()
        for _, c in ipairs(Workspace:GetChildren()) do
            if c:IsA("Model") and string.find(string.lower(c.Name), "lobby") then
                return c
            end
        end
        return Workspace:FindFirstChild("SummerLobby") or Workspace:FindFirstChild("Lobby")
    end

    local function getAllActiveCoins()
        local coins = {}
        local seen = {}
        local CollectionService = game:GetService("CollectionService")

        for _, tag in ipairs({"CoinVisual", "Coin"}) do
            for _, v in ipairs(CollectionService:GetTagged(tag)) do
                if v and v.Parent and not v:GetAttribute("Collected") and not v:GetAttribute("Delete") then
                    local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                    if part and not seen[part] and part.Transparency < 0.95 then
                        seen[part] = true
                        table.insert(coins, part)
                    end
                end
            end
        end

        if #coins == 0 then
            local map = getActiveMap()
            if map then
                local container = map:FindFirstChild("CoinAreas") or map:FindFirstChild("CoinContainer") or map:FindFirstChild("Coins")
                if container then
                    for _, c in ipairs(container:GetChildren()) do
                        for _, d in ipairs(c:GetDescendants()) do
                            if (d:GetAttribute("CoinID") or string.find(string.lower(d.Name), "coin")) and d:IsA("BasePart") and not seen[d] and d.Transparency < 0.95 then
                                seen[d] = true
                                table.insert(coins, d)
                            end
                        end
                        if (c:GetAttribute("CoinID") or string.find(string.lower(c.Name), "coin")) and c:IsA("BasePart") and not seen[c] and c.Transparency < 0.95 then
                            seen[c] = true
                            table.insert(coins, c)
                        end
                    end
                end
            end
        end

        return coins
    end

    local function getCurrentCoinCount()
        local pgui = LocalPlayer:FindFirstChild("PlayerGui")
        local mg = pgui and pgui:FindFirstChild("MainGUI")
        local gameUi = mg and mg:FindFirstChild("Game")
        local coinBag = gameUi and gameUi:FindFirstChild("CoinBag")
        if coinBag then
            for _, desc in ipairs(coinBag:GetDescendants()) do
                if desc:IsA("TextLabel") and string.find(desc.Text, "/") then
                    local current = tonumber(string.match(desc.Text, "(%d+)%s*/"))
                    if current then
                        return current
                    end
                end
            end
        end
        return 0
    end

    local function getGunDrop()
        local gd = Workspace:FindFirstChild("GunDrop")
        if gd then return gd end
        local map = getActiveMap()
        if map then
            gd = map:FindFirstChild("GunDrop")
            if gd then return gd end
        end
        for _, c in ipairs(Workspace:GetChildren()) do
            if c.Name == "GunDrop" then
                return c
            end
        end
        return Workspace:FindFirstChild("GunDrop", true)
    end

    local function getGunDropPart(drop)
        if not drop then return nil end
        if drop:IsA("BasePart") then
            return drop
        end
        if drop:IsA("Model") or drop:IsA("Folder") or drop:IsA("Tool") then
            local p = drop:FindFirstChild("GunDrop") or drop:FindFirstChild("Handle") or drop.PrimaryPart or drop:FindFirstChildWhichIsA("BasePart")
            if p and p:IsA("BasePart") then
                return p
            end
            for _, desc in ipairs(drop:GetDescendants()) do
                if desc:IsA("BasePart") then
                    return desc
                end
            end
        end
        return nil
    end

    local function interactWithGunDrop(gunPart, gunObj)
        if not gunPart then return end
        local char = LocalPlayer.Character
        if not char then return end
        local root = getRootPart(char)
        if not root then return end

        local prompt = (gunObj and gunObj:FindFirstChildOfClass("ProximityPrompt"))
            or gunPart:FindFirstChildOfClass("ProximityPrompt")
            or (gunObj and gunObj:FindFirstChildWhichIsA("ProximityPrompt", true))
        if prompt and fireproximityprompt then
            pcall(fireproximityprompt, prompt)
        end

        fireTouch(root, gunPart)
        local rHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
        if rHand then
            fireTouch(rHand, gunPart)
        end
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Identical"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() screenGui.Parent = CoreGui end)
    if not screenGui.Parent then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local uiVisible = true
    local isMinimized = false

    local function SendNotification(title, text, duration)
        duration = duration or 3
        local noteHolder = screenGui:FindFirstChild("NotificationHolder")
        if not noteHolder then
            noteHolder = Instance.new("Frame")
            noteHolder.Name = "NotificationHolder"
            noteHolder.Size = UDim2.new(0, 240, 1, -40)
            noteHolder.Position = UDim2.new(1, -250, 0, 20)
            noteHolder.BackgroundTransparency = 1
            noteHolder.Parent = screenGui

            local noteList = Instance.new("UIListLayout")
            noteList.SortOrder = Enum.SortOrder.LayoutOrder
            noteList.VerticalAlignment = Enum.VerticalAlignment.Bottom
            noteList.Padding = UDim.new(0, 8)
            noteList.Parent = noteHolder
        end

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 56)
        card.BackgroundColor3 = Colors.CardBg
        card.BorderSizePixel = 0
        card.Position = UDim2.new(1, 20, 0, 0)
        card.Parent = noteHolder

        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 6)
        cardCorner.Parent = card

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = Colors.BorderPurple
        cardStroke.Thickness = 1
        cardStroke.Parent = card

        local topBar = Instance.new("Frame")
        topBar.Size = UDim2.new(1, -20, 0, 18)
        topBar.BackgroundTransparency = 1
        topBar.Position = UDim2.new(0, 10, 0, 6)
        topBar.Parent = card

        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(1, -20, 1, 0)
        tLabel.BackgroundTransparency = 1
        tLabel.Font = Enum.Font.GothamBold
        tLabel.Text = title
        tLabel.TextColor3 = Colors.PurplePrimary
        tLabel.TextSize = 13
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.Parent = topBar

        local mLabel = Instance.new("TextLabel")
        mLabel.Size = UDim2.new(1, -20, 0, 26)
        mLabel.Position = UDim2.new(0, 10, 0, 26)
        mLabel.BackgroundTransparency = 1
        mLabel.Font = Enum.Font.Gotham
        mLabel.Text = text
        mLabel.TextColor3 = Colors.TextSubtle
        mLabel.TextSize = 11
        mLabel.TextXAlignment = Enum.TextXAlignment.Left
        mLabel.TextWrapped = true
        mLabel.Parent = card

        task.delay(duration, function()
            TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1,
                Position = card.Position + UDim2.new(1, 20, 0, 0)
            }):Play()
            task.wait(0.35)
            card:Destroy()
        end)
    end

    local ToggleUiVisibility

    local floatingCrescent = Instance.new("ImageButton")
    floatingCrescent.Name = "FloatingCrescent"
    floatingCrescent.Size = UDim2.new(0, 44, 0, 44)
    floatingCrescent.Position = UDim2.new(0, 20, 0, 20)
    floatingCrescent.BackgroundColor3 = Colors.Background
    floatingCrescent.BorderSizePixel = 0
    floatingCrescent.Visible = false
    floatingCrescent.ZIndex = 1000
    floatingCrescent.Parent = screenGui

    local fcCorner = Instance.new("UICorner")
    fcCorner.CornerRadius = UDim.new(1, 0)
    fcCorner.Parent = floatingCrescent

    local fcStroke = Instance.new("UIStroke")
    fcStroke.Color = Colors.PurpleAccent
    fcStroke.Thickness = 1.5
    fcStroke.Parent = floatingCrescent

    local fcIconContainer = Instance.new("Frame")
    fcIconContainer.Name = "Icon"
    fcIconContainer.Size = UDim2.new(0, 24, 0, 24)
    fcIconContainer.Position = UDim2.new(0.5, -12, 0.5, -12)
    fcIconContainer.BackgroundTransparency = 1
    fcIconContainer.ClipsDescendants = true
    fcIconContainer.Parent = floatingCrescent

    local fcOuter = Instance.new("Frame")
    fcOuter.Name = "Outer"
    fcOuter.Size = UDim2.new(0, 24, 0, 24)
    fcOuter.BackgroundColor3 = Colors.PurplePrimary
    fcOuter.BorderSizePixel = 0
    fcOuter.Parent = fcIconContainer

    local fcOuterCorner = Instance.new("UICorner")
    fcOuterCorner.CornerRadius = UDim.new(1, 0)
    fcOuterCorner.Parent = fcOuter

    local fcCutout = Instance.new("Frame")
    fcCutout.Name = "Cutout"
    fcCutout.Size = UDim2.new(0, 20, 0, 20)
    fcCutout.Position = UDim2.new(0, 6, 0, -3)
    fcCutout.BackgroundColor3 = Colors.Background
    fcCutout.BorderSizePixel = 0
    fcCutout.Parent = fcOuter

    local fcCutoutCorner = Instance.new("UICorner")
    fcCutoutCorner.CornerRadius = UDim.new(1, 0)
    fcCutoutCorner.Parent = fcCutout

    local fcDragging = false
    local fcDragInput, fcDragStart, fcStartPos

    floatingCrescent.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            fcDragging = true
            fcDragStart = input.Position
            fcStartPos = floatingCrescent.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    fcDragging = false
                end
            end)
        end
    end)

    floatingCrescent.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            fcDragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == fcDragInput and fcDragging then
            local delta = input.Position - fcDragStart
            floatingCrescent.Position = UDim2.new(fcStartPos.X.Scale, fcStartPos.X.Offset + delta.X, fcStartPos.Y.Scale, fcStartPos.Y.Offset + delta.Y)
        end
    end)

    floatingCrescent.MouseEnter:Connect(function()
        TweenService:Create(floatingCrescent, TweenInfo.new(0.15), {BackgroundColor3 = Colors.PurpleDark}):Play()
        TweenService:Create(fcStroke, TweenInfo.new(0.15), {Color = Colors.PurpleGlow}):Play()
        fcCutout.BackgroundColor3 = Colors.PurpleDark
    end)

    floatingCrescent.MouseLeave:Connect(function()
        TweenService:Create(floatingCrescent, TweenInfo.new(0.15), {BackgroundColor3 = Colors.Background}):Play()
        TweenService:Create(fcStroke, TweenInfo.new(0.15), {Color = Colors.PurpleAccent}):Play()
        fcCutout.BackgroundColor3 = Colors.Background
    end)

    floatingCrescent.MouseButton1Click:Connect(function()
        if ToggleUiVisibility then ToggleUiVisibility() end
    end)

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 690, 0, 470)
    mainFrame.Position = UDim2.new(0.5, -345, 0.5, -235)
    mainFrame.BackgroundColor3 = Colors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = mainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Colors.BorderPurple
    mainStroke.Thickness = 1.5
    mainStroke.Parent = mainFrame

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 38)
    titleBar.BackgroundColor3 = Colors.SidebarBg
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar

    local titleBottomFill = Instance.new("Frame")
    titleBottomFill.Name = "BottomFill"
    titleBottomFill.Size = UDim2.new(1, 0, 0, 10)
    titleBottomFill.Position = UDim2.new(0, 0, 1, -10)
    titleBottomFill.BackgroundColor3 = Colors.SidebarBg
    titleBottomFill.BorderSizePixel = 0
    titleBottomFill.Parent = titleBar

    local titleDiv = Instance.new("Frame")
    titleDiv.Size = UDim2.new(1, 0, 0, 1)
    titleDiv.Position = UDim2.new(0, 0, 1, -1)
    titleDiv.BackgroundColor3 = Colors.Divider
    titleDiv.BorderSizePixel = 0
    titleDiv.Parent = titleBar

    local crescentContainer = Instance.new("Frame")
    crescentContainer.Name = "CrescentIcon"
    crescentContainer.Size = UDim2.new(0, 16, 0, 16)
    crescentContainer.Position = UDim2.new(0, 14, 0.5, -8)
    crescentContainer.BackgroundTransparency = 1
    crescentContainer.ClipsDescendants = true
    crescentContainer.Parent = titleBar

    local crescentOuter = Instance.new("Frame")
    crescentOuter.Name = "Outer"
    crescentOuter.Size = UDim2.new(0, 16, 0, 16)
    crescentOuter.BackgroundColor3 = Colors.PurpleAccent
    crescentOuter.BorderSizePixel = 0
    crescentOuter.Parent = crescentContainer

    local crescentOuterCorner = Instance.new("UICorner")
    crescentOuterCorner.CornerRadius = UDim.new(1, 0)
    crescentOuterCorner.Parent = crescentOuter

    local crescentCutout = Instance.new("Frame")
    crescentCutout.Name = "Cutout"
    crescentCutout.Size = UDim2.new(0, 13, 0, 13)
    crescentCutout.Position = UDim2.new(0, 4, 0, -2)
    crescentCutout.BackgroundColor3 = Colors.SidebarBg
    crescentCutout.BorderSizePixel = 0
    crescentCutout.Parent = crescentOuter

    local crescentCutoutCorner = Instance.new("UICorner")
    crescentCutoutCorner.CornerRadius = UDim.new(1, 0)
    crescentCutoutCorner.Parent = crescentCutout

    local brandTitle = Instance.new("TextLabel")
    brandTitle.Name = "BrandTitle"
    brandTitle.Size = UDim2.new(0, 150, 1, 0)
    brandTitle.Position = UDim2.new(0, 36, 0, 0)
    brandTitle.BackgroundTransparency = 1
    brandTitle.Font = Enum.Font.GothamBold
    brandTitle.Text = "IDENTICAL"
    brandTitle.TextColor3 = Colors.PurplePrimary
    brandTitle.TextSize = 14
    brandTitle.TextXAlignment = Enum.TextXAlignment.Left
    brandTitle.Parent = titleBar

    local gameSubtitle = Instance.new("TextLabel")
    gameSubtitle.Name = "GameSubtitle"
    gameSubtitle.Size = UDim2.new(0, 180, 1, 0)
    gameSubtitle.Position = UDim2.new(0, 118, 0, 0)
    gameSubtitle.BackgroundTransparency = 1
    gameSubtitle.Font = Enum.Font.Gotham
    gameSubtitle.Text = "MURDER MYSTERY 2"
    gameSubtitle.TextColor3 = Colors.PurpleMuted
    gameSubtitle.TextSize = 10
    gameSubtitle.TextXAlignment = Enum.TextXAlignment.Left
    gameSubtitle.Parent = titleBar

    local winControls = Instance.new("Frame")
    winControls.Name = "WindowControls"
    winControls.Size = UDim2.new(0, 60, 1, 0)
    winControls.Position = UDim2.new(1, -66, 0, 0)
    winControls.BackgroundTransparency = 1
    winControls.Parent = titleBar

    local minBtn = Instance.new("TextButton")
    minBtn.Name = "Minimize"
    minBtn.Size = UDim2.new(0, 24, 0, 24)
    minBtn.Position = UDim2.new(0, 0, 0.5, -12)
    minBtn.BackgroundColor3 = Colors.ControlBg
    minBtn.Font = Enum.Font.GothamBold
    minBtn.Text = "[-]"
    minBtn.TextColor3 = Colors.TextMuted
    minBtn.TextSize = 11
    minBtn.BorderSizePixel = 0
    minBtn.Parent = winControls

    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 4)
    minCorner.Parent = minBtn

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(0, 32, 0.5, -12)
    closeBtn.BackgroundColor3 = Colors.ControlBg
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "[X]"
    closeBtn.TextColor3 = Colors.AccentRed
    closeBtn.TextSize = 11
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = winControls

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeBtn

    local dragging = false
    local dragInput, dragStart, startPos

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local bodyFrame = Instance.new("Frame")
    bodyFrame.Name = "Body"
    bodyFrame.Size = UDim2.new(1, 0, 1, -62)
    bodyFrame.Position = UDim2.new(0, 0, 0, 38)
    bodyFrame.BackgroundTransparency = 1
    bodyFrame.Parent = mainFrame

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 140, 1, 0)
    sidebar.BackgroundColor3 = Colors.SidebarBg
    sidebar.BorderSizePixel = 0
    sidebar.Parent = bodyFrame

    local sidebarDiv = Instance.new("Frame")
    sidebarDiv.Size = UDim2.new(0, 1, 1, 0)
    sidebarDiv.Position = UDim2.new(1, -1, 0, 0)
    sidebarDiv.BackgroundColor3 = Colors.Divider
    sidebarDiv.BorderSizePixel = 0
    sidebarDiv.Parent = sidebar

    local searchContainer = Instance.new("Frame")
    searchContainer.Size = UDim2.new(1, -16, 0, 28)
    searchContainer.Position = UDim2.new(0, 8, 0, 8)
    searchContainer.BackgroundColor3 = Colors.ControlBg
    searchContainer.BorderSizePixel = 0
    searchContainer.Parent = sidebar

    local scCorner = Instance.new("UICorner")
    scCorner.CornerRadius = UDim.new(0, 4)
    scCorner.Parent = searchContainer

    local scStroke = Instance.new("UIStroke")
    scStroke.Color = Colors.Divider
    scStroke.Thickness = 1
    scStroke.Parent = searchContainer

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -10, 1, 0)
    searchBox.Position = UDim2.new(0, 6, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Font = Enum.Font.Gotham
    searchBox.PlaceholderText = "Search..."
    searchBox.PlaceholderColor3 = Colors.TextSubtle
    searchBox.Text = ""
    searchBox.TextColor3 = Colors.TextPrimary
    searchBox.TextSize = 11
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchContainer

    local navList = Instance.new("ScrollingFrame")
    navList.Name = "NavList"
    navList.Size = UDim2.new(1, -8, 1, -44)
    navList.Position = UDim2.new(0, 4, 0, 40)
    navList.BackgroundTransparency = 1
    navList.ScrollBarThickness = 0
    navList.CanvasSize = UDim2.new(0, 0, 0, 360)
    navList.Parent = sidebar

    local navLayout = Instance.new("UIListLayout")
    navLayout.SortOrder = Enum.SortOrder.LayoutOrder
    navLayout.Padding = UDim.new(0, 2)
    navLayout.Parent = navList

    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -140, 1, 0)
    contentArea.Position = UDim2.new(0, 140, 0, 0)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = bodyFrame

    local tabFrames = {}
    local navButtons = {}
    local currentTab = "Home"

    local tabNames = {"Home", "Combat", "Visuals", "Farm", "Survival", "Teleports", "Trolling", "Misc"}

    local function createTabContent(name)
        local scroll = Instance.new("ScrollingFrame")
        scroll.Name = "Tab_" .. name
        scroll.Size = UDim2.new(1, -16, 1, -12)
        scroll.Position = UDim2.new(0, 8, 0, 6)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 3
        scroll.ScrollBarImageColor3 = Colors.PurpleDark
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Visible = false
        scroll.Parent = contentArea

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 8)
        layout.Parent = scroll

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 4)
        pad.PaddingBottom = UDim.new(0, 8)
        pad.PaddingLeft = UDim.new(0, 4)
        pad.PaddingRight = UDim.new(0, 8)
        pad.Parent = scroll

        return scroll
    end

    local function switchTab(name)
        currentTab = name
        for tabName, frame in pairs(tabFrames) do
            frame.Visible = (tabName == name)
        end
        for tabName, btn in pairs(navButtons) do
            local isCurrent = (tabName == name)
            local indicator = btn:FindFirstChild("Indicator")
            if indicator then indicator.Visible = isCurrent end
            btn.BackgroundColor3 = isCurrent and Colors.ControlBg or Colors.SidebarBg
            btn.TextColor3 = isCurrent and Colors.PurplePrimary or Colors.TextMuted
        end
    end

    for idx, name in ipairs(tabNames) do
        local tabScroll = createTabContent(name)
        tabFrames[name] = tabScroll

        local btn = Instance.new("TextButton")
        btn.Name = "Nav_" .. name
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Colors.SidebarBg
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamBold
        btn.Text = "  " .. name
        btn.TextColor3 = Colors.TextMuted
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.LayoutOrder = idx
        btn.Parent = navList

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 5)
        bCorner.Parent = btn

        local ind = Instance.new("Frame")
        ind.Name = "Indicator"
        ind.Size = UDim2.new(0, 3, 0, 16)
        ind.Position = UDim2.new(0, 2, 0.5, -8)
        ind.BackgroundColor3 = Colors.PurpleAccent
        ind.BorderSizePixel = 0
        ind.Visible = false
        ind.Parent = btn

        local indCorner = Instance.new("UICorner")
        indCorner.CornerRadius = UDim.new(0, 2)
        indCorner.Parent = ind

        btn.MouseEnter:Connect(function()
            if currentTab ~= name then
                TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.ControlBg, TextColor3 = Colors.TextPrimary}):Play()
            end
        end)

        btn.MouseLeave:Connect(function()
            if currentTab ~= name then
                TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.SidebarBg, TextColor3 = Colors.TextMuted}):Play()
            end
        end)

        btn.MouseButton1Click:Connect(function()
            switchTab(name)
        end)

        navButtons[name] = btn
    end

    local footerBar = Instance.new("Frame")
    footerBar.Name = "FooterBar"
    footerBar.Size = UDim2.new(1, 0, 0, 24)
    footerBar.Position = UDim2.new(0, 0, 1, -24)
    footerBar.BackgroundColor3 = Colors.SidebarBg
    footerBar.BorderSizePixel = 0
    footerBar.Parent = mainFrame

    local footerCorner = Instance.new("UICorner")
    footerCorner.CornerRadius = UDim.new(0, 8)
    footerCorner.Parent = footerBar

    local footerTopFill = Instance.new("Frame")
    footerTopFill.Name = "TopFill"
    footerTopFill.Size = UDim2.new(1, 0, 0, 10)
    footerTopFill.Position = UDim2.new(0, 0, 0, 0)
    footerTopFill.BackgroundColor3 = Colors.SidebarBg
    footerTopFill.BorderSizePixel = 0
    footerTopFill.Parent = footerBar

    local footerDiv = Instance.new("Frame")
    footerDiv.Size = UDim2.new(1, 0, 0, 1)
    footerDiv.BackgroundColor3 = Colors.Divider
    footerDiv.BorderSizePixel = 0
    footerDiv.Parent = footerBar

    local footerBrand = Instance.new("TextLabel")
    footerBrand.Size = UDim2.new(0, 220, 1, 0)
    footerBrand.Position = UDim2.new(0, 12, 0, 0)
    footerBrand.BackgroundTransparency = 1
    footerBrand.Font = Enum.Font.Gotham
    footerBrand.Text = "Identical v1.0 - Murder Mystery 2"
    footerBrand.TextColor3 = Colors.TextMuted
    footerBrand.TextSize = 10
    footerBrand.TextXAlignment = Enum.TextXAlignment.Left
    footerBrand.Parent = footerBar

    local footerKey = Instance.new("TextLabel")
    footerKey.Size = UDim2.new(0, 200, 1, 0)
    footerKey.Position = UDim2.new(1, -212, 0, 0)
    footerKey.BackgroundTransparency = 1
    footerKey.Font = Enum.Font.Gotham
    footerKey.Text = "[L-CTRL] Menu | [END] Stop All"
    footerKey.TextColor3 = Colors.TextMuted
    footerKey.TextSize = 10
    footerKey.TextXAlignment = Enum.TextXAlignment.Right
    footerKey.Parent = footerBar

    local rowSearchIndex = {}

    local function createCategoryHeader(parent, text)
        local hdr = Instance.new("Frame")
        hdr.Size = UDim2.new(1, 0, 0, 22)
        hdr.BackgroundTransparency = 1
        hdr.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.Text = string.upper(text)
        lbl.TextColor3 = Colors.PurplePrimary
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = hdr

        return hdr
    end

    local function createCardGroup(parent)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 0)
        card.AutomaticSize = Enum.AutomaticSize.Y
        card.BackgroundColor3 = Colors.CardBg
        card.BorderSizePixel = 0
        card.Parent = parent

        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 6)
        cCorner.Parent = card

        local cStroke = Instance.new("UIStroke")
        cStroke.Color = Colors.Divider
        cStroke.Thickness = 1
        cStroke.Parent = card

        local cLayout = Instance.new("UIListLayout")
        cLayout.SortOrder = Enum.SortOrder.LayoutOrder
        cLayout.Padding = UDim.new(0, 0)
        cLayout.Parent = card

        return card
    end

    local function createToggleRow(parent, labelText, descText, defaultState, callback, registerSearch)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 44)
        row.BackgroundTransparency = 1
        row.BorderSizePixel = 0
        row.Parent = parent

        local infoContainer = Instance.new("Frame")
        infoContainer.Size = UDim2.new(1, -56, 1, 0)
        infoContainer.Position = UDim2.new(0, 12, 0, 0)
        infoContainer.BackgroundTransparency = 1
        infoContainer.Parent = row

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, 0, 0, 18)
        titleLbl.Position = UDim2.new(0, 0, 0, 6)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.Text = labelText
        titleLbl.TextColor3 = Colors.TextPrimary
        titleLbl.TextSize = 12
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Parent = infoContainer

        local descLbl = Instance.new("TextLabel")
        descLbl.Size = UDim2.new(1, 0, 0, 14)
        descLbl.Position = UDim2.new(0, 0, 0, 24)
        descLbl.BackgroundTransparency = 1
        descLbl.Font = Enum.Font.Gotham
        descLbl.Text = descText
        descLbl.TextColor3 = Colors.TextSubtle
        descLbl.TextSize = 10
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.Parent = infoContainer

        local toggleTrack = Instance.new("TextButton")
        toggleTrack.Size = UDim2.new(0, 36, 0, 18)
        toggleTrack.Position = UDim2.new(1, -48, 0.5, -9)
        toggleTrack.BackgroundColor3 = defaultState and Colors.PurpleAccent or Colors.ControlBg
        toggleTrack.BorderSizePixel = 0
        toggleTrack.Text = ""
        toggleTrack.AutoButtonColor = false
        toggleTrack.Parent = row

        local ttCorner = Instance.new("UICorner")
        ttCorner.CornerRadius = UDim.new(1, 0)
        ttCorner.Parent = toggleTrack

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = defaultState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        knob.BackgroundColor3 = Colors.TextPrimary
        knob.BorderSizePixel = 0
        knob.Parent = toggleTrack

        local kCorner = Instance.new("UICorner")
        kCorner.CornerRadius = UDim.new(1, 0)
        kCorner.Parent = knob

        local div = Instance.new("Frame")
        div.Size = UDim2.new(1, -24, 0, 1)
        div.Position = UDim2.new(0, 12, 1, -1)
        div.BackgroundColor3 = Colors.Divider
        div.BorderSizePixel = 0
        div.Parent = row

        local state = defaultState
        local function SetState(newState)
            state = newState
            TweenService:Create(toggleTrack, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                BackgroundColor3 = state and Colors.PurpleAccent or Colors.ControlBg
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
            }):Play()
            if callback then callback(state) end
            if not isSyncingUI and AutoSaveConfig then AutoSaveConfig() end
        end

        toggleTrack.MouseButton1Click:Connect(function()
            SetState(not state)
        end)

        if registerSearch then
            table.insert(rowSearchIndex, {frame = row, query = string.lower(labelText .. " " .. descText)})
        end

        return {Row = row, SetState = SetState, GetState = function() return state end}
    end

    local function createSliderRow(parent, labelText, descText, minVal, maxVal, defaultVal, isFloat, unit, callback, registerSearch)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 48)
        row.BackgroundTransparency = 1
        row.BorderSizePixel = 0
        row.Parent = parent

        local infoContainer = Instance.new("Frame")
        infoContainer.Size = UDim2.new(0.55, 0, 1, 0)
        infoContainer.Position = UDim2.new(0, 12, 0, 0)
        infoContainer.BackgroundTransparency = 1
        infoContainer.Parent = row

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, 0, 0, 18)
        titleLbl.Position = UDim2.new(0, 0, 0, 8)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.Text = labelText
        titleLbl.TextColor3 = Colors.TextPrimary
        titleLbl.TextSize = 12
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Parent = infoContainer

        local descLbl = Instance.new("TextLabel")
        descLbl.Size = UDim2.new(1, 0, 0, 14)
        descLbl.Position = UDim2.new(0, 0, 0, 26)
        descLbl.BackgroundTransparency = 1
        descLbl.Font = Enum.Font.Gotham
        descLbl.Text = descText
        descLbl.TextColor3 = Colors.TextSubtle
        descLbl.TextSize = 10
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.Parent = infoContainer

        local sliderContainer = Instance.new("Frame")
        sliderContainer.Size = UDim2.new(0.4, 0, 1, 0)
        sliderContainer.Position = UDim2.new(0.58, 0, 0, 0)
        sliderContainer.BackgroundTransparency = 1
        sliderContainer.Parent = row

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(1, -12, 0, 16)
        valLbl.Position = UDim2.new(0, 0, 0, 8)
        valLbl.BackgroundTransparency = 1
        valLbl.Font = Enum.Font.GothamBold
        valLbl.Text = tostring(defaultVal) .. (unit or "")
        valLbl.TextColor3 = Colors.PurplePrimary
        valLbl.TextSize = 11
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Parent = sliderContainer

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -12, 0, 6)
        track.Position = UDim2.new(0, 0, 0, 28)
        track.BackgroundColor3 = Colors.ControlBg
        track.BorderSizePixel = 0
        track.Parent = sliderContainer

        local tCorner = Instance.new("UICorner")
        tCorner.CornerRadius = UDim.new(1, 0)
        tCorner.Parent = track

        local pct = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(pct, 0, 1, 0)
        fill.BackgroundColor3 = Colors.PurpleAccent
        fill.BorderSizePixel = 0
        fill.Parent = track

        local fCorner = Instance.new("UICorner")
        fCorner.CornerRadius = UDim.new(1, 0)
        fCorner.Parent = fill

        local div = Instance.new("Frame")
        div.Size = UDim2.new(1, -24, 0, 1)
        div.Position = UDim2.new(0, 12, 1, -1)
        div.BackgroundColor3 = Colors.Divider
        div.BorderSizePixel = 0
        div.Parent = row

        local curVal = defaultVal
        local sliding = false

        local function updateValueFromX(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            local raw = minVal + rel * (maxVal - minVal)
            curVal = isFloat and math.floor(raw * 100) / 100 or math.floor(raw + 0.5)
            valLbl.Text = tostring(curVal) .. (unit or "")
            if callback then callback(curVal) end
            if not isSyncingUI and AutoSaveConfig then AutoSaveConfig() end
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                sliding = true
                updateValueFromX(input.Position.X)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                sliding = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                updateValueFromX(input.Position.X)
            end
        end)

        local function SetValue(v)
            curVal = math.clamp(v, minVal, maxVal)
            local r = (curVal - minVal) / (maxVal - minVal)
            fill.Size = UDim2.new(r, 0, 1, 0)
            valLbl.Text = tostring(curVal) .. (unit or "")
            if callback then callback(curVal) end
        end

        if registerSearch then
            table.insert(rowSearchIndex, {frame = row, query = string.lower(labelText .. " " .. descText)})
        end

        return {Row = row, SetValue = SetValue, GetValue = function() return curVal end}
    end

    local function createDropdownRow(parent, labelText, descText, options, defaultOption, callback, registerSearch)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 48)
        row.BackgroundTransparency = 1
        row.BorderSizePixel = 0
        row.Parent = parent

        local infoContainer = Instance.new("Frame")
        infoContainer.Size = UDim2.new(0.55, 0, 1, 0)
        infoContainer.Position = UDim2.new(0, 12, 0, 0)
        infoContainer.BackgroundTransparency = 1
        infoContainer.Parent = row

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, 0, 0, 18)
        titleLbl.Position = UDim2.new(0, 0, 0, 8)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.Text = labelText
        titleLbl.TextColor3 = Colors.TextPrimary
        titleLbl.TextSize = 12
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Parent = infoContainer

        local descLbl = Instance.new("TextLabel")
        descLbl.Size = UDim2.new(1, 0, 0, 14)
        descLbl.Position = UDim2.new(0, 0, 0, 26)
        descLbl.BackgroundTransparency = 1
        descLbl.Font = Enum.Font.Gotham
        descLbl.Text = descText
        descLbl.TextColor3 = Colors.TextSubtle
        descLbl.TextSize = 10
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.Parent = infoContainer

        local dropBtn = Instance.new("TextButton")
        dropBtn.Size = UDim2.new(0, 120, 0, 24)
        dropBtn.Position = UDim2.new(1, -132, 0.5, -12)
        dropBtn.BackgroundColor3 = Colors.ControlBg
        dropBtn.BorderSizePixel = 0
        dropBtn.Font = Enum.Font.GothamBold
        dropBtn.Text = tostring(defaultOption) .. " v"
        dropBtn.TextColor3 = Colors.PurplePrimary
        dropBtn.TextSize = 11
        dropBtn.Parent = row

        local dCorner = Instance.new("UICorner")
        dCorner.CornerRadius = UDim.new(0, 4)
        dCorner.Parent = dropBtn

        local dStroke = Instance.new("UIStroke")
        dStroke.Color = Colors.Divider
        dStroke.Thickness = 1
        dStroke.Parent = dropBtn

        local div = Instance.new("Frame")
        div.Size = UDim2.new(1, -24, 0, 1)
        div.Position = UDim2.new(0, 12, 1, -1)
        div.BackgroundColor3 = Colors.Divider
        div.BorderSizePixel = 0
        div.Parent = row

        local selected = defaultOption
        local optIndex = 1
        for i, opt in ipairs(options) do
            if opt == defaultOption then
                optIndex = i
                break
            end
        end

        dropBtn.MouseButton1Click:Connect(function()
            optIndex = optIndex + 1
            if optIndex > #options then optIndex = 1 end
            selected = options[optIndex]
            dropBtn.Text = tostring(selected) .. " v"
            if callback then callback(selected) end
            if not isSyncingUI and AutoSaveConfig then AutoSaveConfig() end
        end)

        local function SetSelected(opt)
            selected = opt
            for i, o in ipairs(options) do
                if o == opt then
                    optIndex = i
                    break
                end
            end
            dropBtn.Text = tostring(selected) .. " v"
            if callback then callback(selected) end
        end

        local function UpdateOptions(newOptions)
            options = newOptions
            optIndex = 1
            if #options > 0 then
                selected = options[1]
                dropBtn.Text = tostring(selected) .. " v"
            end
        end

        if registerSearch then
            table.insert(rowSearchIndex, {frame = row, query = string.lower(labelText .. " " .. descText)})
        end

        return {Row = row, SetSelected = SetSelected, UpdateOptions = UpdateOptions, GetSelected = function() return selected end}
    end

    local function createButtonRow(parent, labelText, btnText, descText, callback, registerSearch)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 44)
        row.BackgroundTransparency = 1
        row.BorderSizePixel = 0
        row.Parent = parent

        local infoContainer = Instance.new("Frame")
        infoContainer.Size = UDim2.new(1, -120, 1, 0)
        infoContainer.Position = UDim2.new(0, 12, 0, 0)
        infoContainer.BackgroundTransparency = 1
        infoContainer.Parent = row

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, 0, 0, 18)
        titleLbl.Position = UDim2.new(0, 0, 0, 6)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.Text = labelText
        titleLbl.TextColor3 = Colors.TextPrimary
        titleLbl.TextSize = 12
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Parent = infoContainer

        local descLbl = Instance.new("TextLabel")
        descLbl.Size = UDim2.new(1, 0, 0, 14)
        descLbl.Position = UDim2.new(0, 0, 0, 24)
        descLbl.BackgroundTransparency = 1
        descLbl.Font = Enum.Font.Gotham
        descLbl.Text = descText
        descLbl.TextColor3 = Colors.TextSubtle
        descLbl.TextSize = 10
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.Parent = infoContainer

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 96, 0, 24)
        btn.Position = UDim2.new(1, -108, 0.5, -12)
        btn.BackgroundColor3 = Colors.PurpleDark
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamBold
        btn.Text = btnText
        btn.TextColor3 = Colors.PurplePrimary
        btn.TextSize = 11
        btn.Parent = row

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 4)
        bCorner.Parent = btn

        local bStroke = Instance.new("UIStroke")
        bStroke.Color = Colors.PurpleAccent
        bStroke.Thickness = 1
        bStroke.Parent = btn

        local div = Instance.new("Frame")
        div.Size = UDim2.new(1, -24, 0, 1)
        div.Position = UDim2.new(0, 12, 1, -1)
        div.BackgroundColor3 = Colors.Divider
        div.BorderSizePixel = 0
        div.Parent = row

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.PurpleGlow, TextColor3 = Colors.TextPrimary}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.PurpleDark, TextColor3 = Colors.PurplePrimary}):Play()
        end)

        btn.MouseButton1Click:Connect(callback)

        if registerSearch then
            table.insert(rowSearchIndex, {frame = row, query = string.lower(labelText .. " " .. descText)})
        end

        return row
    end

    local function createInfoRow(parent, labelText, valueText, registerSearch)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 36)
        row.BackgroundTransparency = 1
        row.BorderSizePixel = 0
        row.Parent = parent

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(0.45, 0, 1, 0)
        titleLbl.Position = UDim2.new(0, 12, 0, 0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.Text = labelText
        titleLbl.TextColor3 = Colors.TextPrimary
        titleLbl.TextSize = 11
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Parent = row

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0.5, 0, 1, 0)
        valLbl.Position = UDim2.new(0.5, -12, 0, 0)
        valLbl.BackgroundTransparency = 1
        valLbl.Font = Enum.Font.Gotham
        valLbl.Text = valueText
        valLbl.TextColor3 = Colors.PurplePrimary
        valLbl.TextSize = 11
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Parent = row

        local div = Instance.new("Frame")
        div.Size = UDim2.new(1, -24, 0, 1)
        div.Position = UDim2.new(0, 12, 1, -1)
        div.BackgroundColor3 = Colors.Divider
        div.BorderSizePixel = 0
        div.Parent = row

        if registerSearch then
            table.insert(rowSearchIndex, {frame = row, query = string.lower(labelText)})
        end

        return {
            Row = row,
            SetValue = function(newVal) valLbl.Text = tostring(newVal) end,
            SetColor = function(newCol) valLbl.TextColor3 = newCol end
        }
    end

    createCategoryHeader(tabFrames.Home, "Round Status & Roles")
    local homeRoundCard = createCardGroup(tabFrames.Home)
    local statusRoundRow = createInfoRow(homeRoundCard, "Round State", "Waiting...", true)
    local timerRoundRow = createInfoRow(homeRoundCard, "Time Remaining", "0:00", true)
    local murdererRow = createInfoRow(homeRoundCard, "Murderer", "Undetected", true)
    local sheriffRow = createInfoRow(homeRoundCard, "Sheriff", "Undetected", true)
    murdererRow.SetColor(Colors.AccentRed)
    sheriffRow.SetColor(Colors.AccentBlue)

    createCategoryHeader(tabFrames.Home, "Quick Actions")
    local homeActionCard = createCardGroup(tabFrames.Home)

    createButtonRow(homeActionCard, "Shoot Murderer", "SHOOT", "Instantly equips gun and shoots murderer", function()
        local murderer = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and isPlayerAlive(p) and getPlayerRole(p) == "Murderer" then
                murderer = p
                break
            end
        end

        local char = LocalPlayer.Character
        local bp = LocalPlayer:FindFirstChild("Backpack")
        local gun = (bp and bp:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun"))
        if not gun then
            SendNotification("Identical", "You do not have the Gun!", 2)
            return
        end
        if not murderer or not murderer.Character then
            SendNotification("Identical", "Murderer not found or deceased!", 2)
            return
        end

        local hum = getHumanoid(char)
        if hum and bp and gun.Parent == bp then
            hum:EquipTool(gun)
            task.wait(0.1)
        end

        local root = getRootPart(char)
        local mRoot = getRootPart(murderer.Character)
        if root and mRoot and gun:FindFirstChild("Shoot") then
            local rayAtt = root:FindFirstChild("GunRaycastAttachment")
            local origin = rayAtt and rayAtt.WorldCFrame or root.CFrame
            local targetCF = CFrame.new(mRoot.Position)
            gun.Shoot:FireServer(origin, targetCF)
            SendNotification("Identical", "Shot fired at Murderer (" .. murderer.Name .. ")!", 2)
        end
    end, true)

    createButtonRow(homeActionCard, "Grab Gun", "GRAB", "Teleports to dropped gun or picks it up", function()
        local drop = getGunDrop()
        local gunPart = getGunDropPart(drop)
        local char = LocalPlayer.Character
        local root = getRootPart(char)
        if not gunPart then
            SendNotification("Identical", "No Gun is currently dropped on map!", 2)
            return
        end
        if root then
            root.CFrame = gunPart.CFrame * CFrame.new(0, 1.5, 0)
            task.wait(0.05)
            interactWithGunDrop(gunPart, drop)
            SendNotification("Identical", "Grabbed dropped gun!", 2)
        end
    end, true)

    createButtonRow(homeActionCard, "Announce Roles", "CHAT", "Announces Murderer & Sheriff in public chat", function()
        local murderer, sheriff = getRolePlayers()
        local msg = "[Identical] "
        if murderer then
            msg = msg .. "Murderer: " .. murderer.Name .. " | "
        else
            msg = msg .. "Murderer: Unknown | "
        end
        if sheriff then
            msg = msg .. "Sheriff: " .. sheriff.Name
        else
            msg = msg .. "Sheriff: Unknown"
        end

        local textChannels = TextChatService:FindFirstChild("TextChannels")
        local rbxGeneral = textChannels and textChannels:FindFirstChild("RBXGeneral")
        if rbxGeneral and rbxGeneral.SendAsync then
            rbxGeneral:SendAsync(msg)
        else
            pcall(function()
                local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                local sayReq = events and events:FindFirstChild("SayMessageRequest")
                if sayReq then
                    sayReq:FireServer(msg, "All")
                end
            end)
        end
        SendNotification("Identical", "Roles announced in chat!", 2)
    end, true)

    createButtonRow(homeActionCard, "Copy Death List", "COPY", "Copies deceased players this round to clipboard", function()
        if #deadPlayersList == 0 then
            SendNotification("Identical", "No recorded deaths yet this round.", 2)
            return
        end
        local text = "MM2 Dead Players: " .. table.concat(deadPlayersList, ", ")
        if setclipboard then
            setclipboard(text)
            SendNotification("Identical", "Death list copied to clipboard!", 2)
        else
            SendNotification("Identical", "Clipboard API not supported.", 2)
        end
    end, true)

    createCategoryHeader(tabFrames.Home, "Configuration Profile")
    local cfgCard = createCardGroup(tabFrames.Home)

    createButtonRow(cfgCard, "Save Configuration", "SAVE", "Writes all current settings to disk", function()
        AutoSaveConfig()
        SendNotification("Identical", "Configuration profile saved to disk!", 2)
    end, true)

    createButtonRow(cfgCard, "Reload Configuration", "LOAD", "Restores saved settings profile from disk", function()
        if LoadSavedConfig() then
            if SyncUIWithConfig then SyncUIWithConfig() end
            SendNotification("Identical", "Configuration profile restored!", 2)
        else
            SendNotification("Identical", "No saved profile found.", 2)
        end
    end, true)

    createButtonRow(cfgCard, "Reset Defaults", "RESET", "Restores all settings to default values", function()
        for k, v in pairs(DefaultConfig) do
            Config[k] = v
        end
        if SyncUIWithConfig then SyncUIWithConfig() end
        AutoSaveConfig()
        SendNotification("Identical", "Settings reset to defaults!", 2)
    end, true)

    createCategoryHeader(tabFrames.Combat, "Sheriff & Gun")
    local gunCard = createCardGroup(tabFrames.Combat)

    ctrls.AutoShoot = createToggleRow(gunCard, "Auto Shoot Murderer", "Automatically fires revolver at Murderer in sight", Config.AutoShoot, function(v)
        Config.AutoShoot = v
    end, true)

    ctrls.SilentAim = createToggleRow(gunCard, "Silent Aim", "Redirects shot raycast directly to target hitbox", Config.SilentAim, function(v)
        Config.SilentAim = v
    end, true)

    ctrls.AimPrediction = createToggleRow(gunCard, "Aim Prediction", "Compensates for target velocity & movement", Config.AimPrediction, function(v)
        Config.AimPrediction = v
    end, true)

    ctrls.PingComp = createToggleRow(gunCard, "Ping Compensation", "Adjusts bullet lead time according to player ping", Config.PingComp, function(v)
        Config.PingComp = v
    end, true)

    ctrls.SingleShot = createToggleRow(gunCard, "Single Shot Lock", "Fires one verified shot and halts until next reset", Config.SingleShot, function(v)
        Config.SingleShot = v
    end, true)

    ctrls.AutoEquipGun = createToggleRow(gunCard, "Auto Equip Gun", "Pulls out revolver when Murderer is within range", Config.AutoEquipGun, function(v)
        Config.AutoEquipGun = v
    end, true)

    ctrls.GrabGunAuto = createToggleRow(gunCard, "Full Gun Grabber", "Automatically collects dropped gun immediately", Config.GrabGunAuto, function(v)
        Config.GrabGunAuto = v
    end, true)

    ctrls.ShowFOV = createToggleRow(gunCard, "Show FOV Circle", "Draws FOV circle on screen for aimbot", Config.ShowFOV, function(v)
        Config.ShowFOV = v
    end, true)

    ctrls.FOVRadius = createSliderRow(gunCard, "FOV Radius", "Radius of aimbot lock target field", 50, 700, Config.FOVRadius, false, " px", function(v)
        Config.FOVRadius = v
    end, true)

    createCategoryHeader(tabFrames.Combat, "Murderer & Knife")
    local knifeCard = createCardGroup(tabFrames.Combat)

    ctrls.KillAura = createToggleRow(knifeCard, "Kill Aura", "Automatically strikes any player inside aura reach", Config.KillAura, function(v)
        Config.KillAura = v
    end, true)

    ctrls.AutoKill = createToggleRow(knifeCard, "Auto Kill Innocents", "Constantly eliminates innocents with knife", Config.AutoKill, function(v)
        Config.AutoKill = v
    end, true)

    ctrls.KillMode = createDropdownRow(knifeCard, "Kill Mode", "Method used for knife strikes", {"Legit", "Blatant", "Throw"}, Config.KillMode, function(v)
        Config.KillMode = v
    end, true)

    ctrls.KnifeSilentAim = createToggleRow(knifeCard, "Knife Silent Aim", "Redirects thrown knives directly into target players", Config.KnifeSilentAim, function(v)
        Config.KnifeSilentAim = v
    end, true)

    ctrls.KillAll = createToggleRow(knifeCard, "Kill All (No Limit)", "Eliminates all remaining living players instantly", Config.KillAll, function(v)
        Config.KillAll = v
    end, true)

    ctrls.AuraRange = createSliderRow(knifeCard, "Aura Range", "Distance threshold for melee knife strikes", 5, 45, Config.AuraRange, false, " studs", function(v)
        Config.AuraRange = v
    end, true)

    ctrls.ShowAuraRing = createToggleRow(knifeCard, "Show Aura Ring", "Draws visual indicator ring around character", Config.ShowAuraRing, function(v)
        Config.ShowAuraRing = v
    end, true)

    ctrls.AutoEquipKnife = createToggleRow(knifeCard, "Auto Equip Knife", "Equips knife automatically when targets in range", Config.AutoEquipKnife, function(v)
        Config.AutoEquipKnife = v
    end, true)

    ctrls.ProximityKnife = createToggleRow(knifeCard, "Proximity Knife", "Pre-emptively draws blade when enemy nears", Config.ProximityKnife, function(v)
        Config.ProximityKnife = v
    end, true)

    createCategoryHeader(tabFrames.Combat, "Hitbox Expansion & Stalker")
    local hitboxCard = createCardGroup(tabFrames.Combat)

    ctrls.HitboxExpander = createToggleRow(hitboxCard, "Hitbox Expander", "Expands player root hitboxes for easy stabs/shots", Config.HitboxExpander, function(v)
        Config.HitboxExpander = v
        if not v then
            for part, sz in pairs(originalHitboxSizes) do
                if part and part.Parent then
                    part.Size = sz
                    part.Transparency = 1
                end
            end
            originalHitboxSizes = {}
        end
    end, true)

    ctrls.HitboxSize = createSliderRow(hitboxCard, "Hitbox Size", "Expanded size multiplier for hitboxes", 4, 30, Config.HitboxSize, false, " studs", function(v)
        Config.HitboxSize = v
    end, true)

    ctrls.FollowMurderer = createToggleRow(hitboxCard, "Murderer Follow", "Maintains safe following position behind Murderer", Config.FollowMurderer, function(v)
        Config.FollowMurderer = v
    end, true)

    ctrls.FollowDist = createSliderRow(hitboxCard, "Follow Offset", "Distance maintained while following Murderer", 8, 40, Config.FollowDist, false, " studs", function(v)
        Config.FollowDist = v
    end, true)

    createCategoryHeader(tabFrames.Visuals, "Full Role ESP")
    local espRoleCard = createCardGroup(tabFrames.Visuals)

    ctrls.RoleESP = createToggleRow(espRoleCard, "Role ESP Enabled", "Master toggle for character role highlights", Config.RoleESP, function(v)
        Config.RoleESP = v
        if not v then clearESPCategory("mm2_") end
    end, true)

    ctrls.ESPChams = createToggleRow(espRoleCard, "Chams (3D Highlight)", "Renders solid 3D glowing color chams", Config.ESPChams, function(v)
        Config.ESPChams = v
        if not v then clearESPCategory("cham_") end
    end, true)

    ctrls.ESPBoxes = createToggleRow(espRoleCard, "Player Boxes", "Draws bounding box around target players", Config.ESPBoxes, function(v)
        Config.ESPBoxes = v
    end, true)

    ctrls.ESPNames = createToggleRow(espRoleCard, "Role Tags & Names", "Displays overhead role tags and player names", Config.ESPNames, function(v)
        Config.ESPNames = v
    end, true)

    ctrls.ESPDistance = createToggleRow(espRoleCard, "Distance Labels", "Displays distance in studs to each player", Config.ESPDistance, function(v)
        Config.ESPDistance = v
    end, true)

    ctrls.ESPTracers = createToggleRow(espRoleCard, "Snapline Tracers", "Draws tracers from under character to targets", Config.ESPTracers, function(v)
        Config.ESPTracers = v
        if not v then
            for _, line in pairs(trackedTracers) do
                if line then line.Visible = false end
            end
        end
    end, true)

    ctrls.ESPDistanceMax = createSliderRow(espRoleCard, "Max ESP Distance", "Maximum render distance for highlights", 50, 1000, Config.ESPDistanceMax, false, " studs", function(v)
        Config.ESPDistanceMax = v
    end, true)

    createCategoryHeader(tabFrames.Visuals, "Item & World Highlights")
    local espItemCard = createCardGroup(tabFrames.Visuals)

    ctrls.GunESP = createToggleRow(espItemCard, "Dropped Gun ESP", "Highlights dropped revolver when Sheriff falls", Config.GunESP, function(v)
        Config.GunESP = v
        if not v then clearESPCategory("gun_") end
    end, true)

    ctrls.CoinESP = createToggleRow(espItemCard, "Coin ESP", "Highlights active coin spawns across map", Config.CoinESP, function(v)
        Config.CoinESP = v
        if not v then clearESPCategory("coin_") end
    end, true)

    createCategoryHeader(tabFrames.Farm, "Coin Farming")
    local farmCard = createCardGroup(tabFrames.Farm)

    ctrls.CoinFarm = createToggleRow(farmCard, "Auto Farm Coins", "Automatically collects all active coins on map", Config.CoinFarm, function(v)
        Config.CoinFarm = v
    end, true)

    ctrls.FarmMethod = createDropdownRow(farmCard, "Movement Method", "Navigation method to reach coin positions", {"Glide", "Tween", "Walk"}, Config.FarmMethod, function(v)
        Config.FarmMethod = v
    end, true)

    ctrls.FarmSpeed = createSliderRow(farmCard, "Farm Speed", "Movement speed while farming coins", 16, 60, Config.FarmSpeed, false, " studs/s", function(v)
        Config.FarmSpeed = v
    end, true)

    ctrls.SafeCoinFarm = createToggleRow(farmCard, "Safe Farming", "Avoids coins within Murderer danger radius", Config.SafeCoinFarm, function(v)
        Config.SafeCoinFarm = v
    end, true)

    ctrls.BagFullStop = createToggleRow(farmCard, "Bag Full Stop", "Halts farming once 40-coin bag limit is met", Config.BagFullStop, function(v)
        Config.BagFullStop = v
    end, true)

    ctrls.QuickFarm = createToggleRow(farmCard, "Quick Mode", "High velocity rapid coin sweep", Config.QuickFarm, function(v)
        Config.QuickFarm = v
    end, true)

    createCategoryHeader(tabFrames.Survival, "Murderer Avoidance & Auto-Play")
    local survCard = createCardGroup(tabFrames.Survival)

    ctrls.MurdererAvoid = createToggleRow(survCard, "Murderer Avoidance", "Automatically maneuvers away from active Murderer", Config.MurdererAvoid, function(v)
        Config.MurdererAvoid = v
    end, true)

    ctrls.SafetyRadius = createSliderRow(survCard, "Safety Radius", "Minimum distance maintained from Murderer", 20, 80, Config.SafetyRadius, false, " studs", function(v)
        Config.SafetyRadius = v
    end, true)

    ctrls.RetreatToLobby = createToggleRow(survCard, "Retreat to Lobby", "Teleports to lobby if Murderer gets too close", Config.RetreatToLobby, function(v)
        Config.RetreatToLobby = v
    end, true)

    ctrls.ProximityAlert = createToggleRow(survCard, "Proximity Alert", "Warns on screen when Murderer approaches", Config.ProximityAlert, function(v)
        Config.ProximityAlert = v
    end, true)

    ctrls.SprintWhenChased = createToggleRow(survCard, "Sprint When Chased", "Increases walk speed when Murderer is near", Config.SprintWhenChased, function(v)
        Config.SprintWhenChased = v
    end, true)

    ctrls.AutoPlay = createToggleRow(survCard, "Role-Based Auto Play", "Automates actions according to assigned role", Config.AutoPlay, function(v)
        Config.AutoPlay = v
    end, true)

    createCategoryHeader(tabFrames.Teleports, "Map & Role Navigation")
    local tpCard = createCardGroup(tabFrames.Teleports)

    createButtonRow(tpCard, "Teleport to Murderer", "GOTO", "Teleports behind the active Murderer", function()
        local murderer = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and isPlayerAlive(p) and getPlayerRole(p) == "Murderer" then
                murderer = p
                break
            end
        end
        local root = getRootPart(LocalPlayer.Character)
        if murderer and murderer.Character and root then
            local mRoot = getRootPart(murderer.Character)
            if mRoot then
                root.CFrame = mRoot.CFrame * CFrame.new(0, 0, 4)
                SendNotification("Identical", "Teleported to Murderer (" .. murderer.Name .. ")", 2)
            end
        else
            SendNotification("Identical", "Murderer not found or deceased.", 2)
        end
    end, true)

    createButtonRow(tpCard, "Teleport to Sheriff", "GOTO", "Teleports next to the active Sheriff", function()
        local sheriff = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and isPlayerAlive(p) and getPlayerRole(p) == "Sheriff" then
                sheriff = p
                break
            end
        end
        local root = getRootPart(LocalPlayer.Character)
        if sheriff and sheriff.Character and root then
            local sRoot = getRootPart(sheriff.Character)
            if sRoot then
                root.CFrame = sRoot.CFrame * CFrame.new(0, 0, 4)
                SendNotification("Identical", "Teleported to Sheriff (" .. sheriff.Name .. ")", 2)
            end
        else
            SendNotification("Identical", "Sheriff not found or deceased.", 2)
        end
    end, true)

    createButtonRow(tpCard, "Teleport to Active Map", "GOTO", "Teleports to match map spawns", function()
        local map = getActiveMap()
        local root = getRootPart(LocalPlayer.Character)
        if map and root then
            local spawns = map:FindFirstChild("Spawns")
            if spawns and #spawns:GetChildren() > 0 then
                local sp = spawns:GetChildren()[1]
                root.CFrame = sp.CFrame * CFrame.new(0, 3, 0)
            else
                local p = map:FindFirstChildWhichIsA("BasePart")
                if p then root.CFrame = p.CFrame * CFrame.new(0, 5, 0) end
            end
            SendNotification("Identical", "Teleported to " .. map.Name, 2)
        else
            SendNotification("Identical", "No active map currently found.", 2)
        end
    end, true)

    createButtonRow(tpCard, "Teleport to Lobby", "GOTO", "Teleports into the lobby safe area", function()
        local lobby = getLobbyModel()
        local root = getRootPart(LocalPlayer.Character)
        if lobby and root then
            local p = lobby:FindFirstChild("Spawns") or lobby:FindFirstChildWhichIsA("BasePart")
            if p then
                local targetPart = p:IsA("Model") and p:GetChildren()[1] or p
                if targetPart then root.CFrame = targetPart.CFrame * CFrame.new(0, 3, 0) end
            end
            SendNotification("Identical", "Teleported to Lobby", 2)
        end
    end, true)

    ctrls.AutoDrop = createToggleRow(tpCard, "Auto Drop at Round Start", "Drops into map immediately when round starts", Config.AutoDrop, function(v)
        Config.AutoDrop = v
    end, true)

    createCategoryHeader(tabFrames.Teleports, "Saved Coordinates")
    local saveCard = createCardGroup(tabFrames.Teleports)

    createButtonRow(saveCard, "Save Location 1", "SAVE 1", "Stores current position in Slot 1", function()
        local root = getRootPart(LocalPlayer.Character)
        if root then
            Config.SaveSlot1 = root.CFrame
            AutoSaveConfig()
            SendNotification("Identical", "Saved Slot 1 position to disk.", 2)
        end
    end, true)

    createButtonRow(saveCard, "Teleport Location 1", "GOTO 1", "Teleports back to Slot 1 position", function()
        local root = getRootPart(LocalPlayer.Character)
        if root and Config.SaveSlot1 then
            root.CFrame = Config.SaveSlot1
            SendNotification("Identical", "Teleported to Slot 1.", 2)
        else
            SendNotification("Identical", "No location saved in Slot 1.", 2)
        end
    end, true)

    createButtonRow(saveCard, "Save Location 2", "SAVE 2", "Stores current position in Slot 2", function()
        local root = getRootPart(LocalPlayer.Character)
        if root then
            Config.SaveSlot2 = root.CFrame
            AutoSaveConfig()
            SendNotification("Identical", "Saved Slot 2 position to disk.", 2)
        end
    end, true)

    createButtonRow(saveCard, "Teleport Location 2", "GOTO 2", "Teleports back to Slot 2 position", function()
        local root = getRootPart(LocalPlayer.Character)
        if root and Config.SaveSlot2 then
            root.CFrame = Config.SaveSlot2
            SendNotification("Identical", "Teleported to Slot 2.", 2)
        else
            SendNotification("Identical", "No location saved in Slot 2.", 2)
        end
    end, true)

    createCategoryHeader(tabFrames.Trolling, "Fling")
    local flingCard = createCardGroup(tabFrames.Trolling)

    local function flingCharacter(targetChar)
        if isFlinging then return end
        local char = LocalPlayer.Character
        local root = getRootPart(char)
        local tRoot = getRootPart(targetChar)
        if not root or not tRoot then return end

        local hum = getHumanoid(char)
        local tHum = getHumanoid(targetChar)
        if not hum or hum.Health <= 0 or not tHum or tHum.Health <= 0 then return end

        isFlinging = true
        local oldCF = root.CFrame

        if sethiddenproperty then
            pcall(sethiddenproperty, LocalPlayer, "SimulationRadius", 10000)
            pcall(sethiddenproperty, LocalPlayer, "MaxSimulationRadius", 10000)
        end
        if setsimulationradius then
            pcall(setsimulationradius, 10000)
        end

        for _, obj in ipairs(root:GetChildren()) do
            if obj:IsA("BodyMover") then
                pcall(function() obj:Destroy() end)
            end
        end

        local bAV = Instance.new("BodyAngularVelocity")
        bAV.Name = "FlingTorque"
        bAV.AngularVelocity = Vector3.new(0, 9e9, 0)
        bAV.MaxTorque = Vector3.new(0, 9e9, 0)
        bAV.P = 9e9
        bAV.Parent = root

        local bV = Instance.new("BodyVelocity")
        bV.Name = "FlingVelocity"
        bV.Velocity = Vector3.new(0, 0, 0)
        bV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bV.Parent = root

        local steppedConn = RunService.Stepped:Connect(function()
            if not char or not root or not root.Parent then return end
            for _, child in ipairs(char:GetDescendants()) do
                if child:IsA("BasePart") then
                    child.CanCollide = false
                end
            end
        end)

        local startTime = tick()
        local duration = 1.5

        while tick() - startTime < duration do
            if not targetChar or not targetChar.Parent or not tRoot or not tRoot.Parent or tHum.Health <= 0 then
                break
            end
            if not char or not char.Parent or not root or not root.Parent or hum.Health <= 0 then
                break
            end

            local style = Config.FlingStyle
            if style == "Velocity" then
                root.CFrame = CFrame.new(tRoot.Position + Vector3.new(0, 1.2, 0))
                root.AssemblyLinearVelocity = Vector3.new(0, 9e9, 0)
                root.AssemblyAngularVelocity = Vector3.new(9e9, 9e9, 9e9)
            elseif style == "Orbit" then
                local angle = (tick() - startTime) * 20
                local off = Vector3.new(math.cos(angle) * 1.5, 0.5, math.sin(angle) * 1.5)
                root.CFrame = CFrame.new(tRoot.Position + off, tRoot.Position)
                root.AssemblyLinearVelocity = Vector3.new(9e9, 9e9, 9e9)
                root.AssemblyAngularVelocity = Vector3.new(9e9, 9e9, 9e9)
            else
                root.CFrame = tRoot.CFrame
                root.AssemblyLinearVelocity = Vector3.new(9e9, 9e9, 9e9)
                root.AssemblyAngularVelocity = Vector3.new(9e9, 9e9, 9e9)
            end

            RunService.Heartbeat:Wait()
        end

        pcall(function() steppedConn:Disconnect() end)
        pcall(function() bAV:Destroy() end)
        pcall(function() bV:Destroy() end)

        if root and root.Parent then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = oldCF
        end

        task.wait(0.15)
        isFlinging = false
    end

    createButtonRow(flingCard, "Fling Murderer", "FLING", "Flings the Murderer across the map", function()
        local murderer = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and isPlayerAlive(p) and getPlayerRole(p) == "Murderer" then
                murderer = p
                break
            end
        end
        if murderer and murderer.Character then
            SendNotification("Identical", "Flinging Murderer (" .. murderer.Name .. ")...", 2)
            task.spawn(flingCharacter, murderer.Character)
        else
            SendNotification("Identical", "Murderer not found or dead.", 2)
        end
    end, true)

    createButtonRow(flingCard, "Fling Sheriff", "FLING", "Flings the Sheriff across the map", function()
        local sheriff = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and isPlayerAlive(p) and getPlayerRole(p) == "Sheriff" then
                sheriff = p
                break
            end
        end
        if sheriff and sheriff.Character then
            SendNotification("Identical", "Flinging Sheriff (" .. sheriff.Name .. ")...", 2)
            task.spawn(flingCharacter, sheriff.Character)
        else
            SendNotification("Identical", "Sheriff not found or dead.", 2)
        end
    end, true)

    ctrls.FlingStyle = createDropdownRow(flingCard, "Fling Style", "Physics technique for flinging targets", {"Torque", "Velocity", "Orbit"}, Config.FlingStyle, function(v)
        Config.FlingStyle = v
    end, true)



    createCategoryHeader(tabFrames.Misc, "Movement & Character")
    local moveCard = createCardGroup(tabFrames.Misc)

    ctrls.SpeedEnabled = createToggleRow(moveCard, "Speed Boost", "Increases player movement speed", Config.SpeedEnabled, function(v)
        Config.SpeedEnabled = v
    end, true)

    ctrls.SpeedValue = createSliderRow(moveCard, "Walk Speed", "Speed value when boost is enabled", 16, 60, Config.SpeedValue, false, "", function(v)
        Config.SpeedValue = v
    end, true)

    ctrls.JumpEnabled = createToggleRow(moveCard, "Safe Jump Boost", "Increases jump power safely", Config.JumpEnabled, function(v)
        Config.JumpEnabled = v
    end, true)

    ctrls.JumpValue = createSliderRow(moveCard, "Jump Power", "Jump power value", 50, 100, Config.JumpValue, false, "", function(v)
        Config.JumpValue = v
    end, true)

    ctrls.InfiniteJump = createToggleRow(moveCard, "Infinite Jump", "Jump continuously mid-air", Config.InfiniteJump, function(v)
        Config.InfiniteJump = v
    end, true)

    ctrls.Noclip = createToggleRow(moveCard, "Noclip", "Walk freely through walls and doors", Config.Noclip, function(v)
        Config.Noclip = v
    end, true)

    createCategoryHeader(tabFrames.Misc, "Environment & Safety")
    local envCard = createCardGroup(tabFrames.Misc)

    ctrls.Fullbright = createToggleRow(envCard, "Fullbright", "Eliminates darkness and shadows", Config.Fullbright, function(v)
        Config.Fullbright = v
        if not v then
            Lighting.Ambient = Color3.fromRGB(128, 128, 128)
            Lighting.Brightness = 1
        end
    end, true)

    ctrls.NoFog = createToggleRow(envCard, "Remove Fog", "Clears distance atmosphere fog", Config.NoFog, function(v)
        Config.NoFog = v
        if not v then Lighting.FogEnd = 1000 end
    end, true)

    ctrls.DisableParticles = createToggleRow(envCard, "Disable Particles (Anti-Lag)", "Improves FPS by disabling particle emitters", Config.DisableParticles, function(v)
        Config.DisableParticles = v
    end, true)

    ctrls.AntiFling = createToggleRow(envCard, "Anti-Fling", "Blocks other players from colliding & flinging you", Config.AntiFling, function(v)
        Config.AntiFling = v
    end, true)

    ctrls.AntiVoid = createToggleRow(envCard, "Anti-Void", "Dynamic floor recovery when flung or falling", Config.AntiVoid, function(v)
        Config.AntiVoid = v
    end, true)

    ctrls.AntiAFK = createToggleRow(envCard, "Anti-AFK", "Prevents Roblox 20-minute idle disconnect", Config.AntiAFK, function(v)
        Config.AntiAFK = v
    end, true)

    createButtonRow(envCard, "Reset Character", "RESET", "Safely respawns your character", function()
        local hum = getHumanoid(LocalPlayer.Character)
        if hum then hum.Health = 0 end
    end, true)

    createCategoryHeader(tabFrames.Misc, "Server Tools")
    local srvCard = createCardGroup(tabFrames.Misc)

    local function queueReinject()
        local qot = (syn and syn.queue_on_teleport) or queue_on_teleport or queueonteleport or (fluxus and fluxus.queue_on_teleport)
        if qot then
            local code = [[
                task.spawn(function()
                    repeat task.wait(0.5) until game:IsLoaded() and game:GetService("Players").LocalPlayer
                    task.wait(1)
                    if isfile and isfile("Identical_MM2.lua") then
                        loadstring(readfile("Identical_MM2.lua"))()
                    elseif isfile and isfile("scripts/mm2.luau") then
                        loadstring(readfile("scripts/mm2.luau"))()
                    elseif isfile and isfile("Identical.lua") then
                        loadstring(readfile("Identical.lua"))()
                    end
                end)
            ]]
            pcall(qot, code)
        end
    end

    createButtonRow(srvCard, "Rejoin Server", "REJOIN", "Rejoins the current MM2 server", function()
        queueReinject()
        SendNotification("Identical", "Rejoining server...", 2)
        task.wait(0.1)
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
    end, true)

    createButtonRow(srvCard, "Server Hop (Random)", "HOP", "Finds and joins a populated public server", function()
        queueReinject()
        SendNotification("Identical", "Searching for active server...", 2)
        local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Desc&excludeFullGames=true&limit=100"
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok and res then
            local data = nil
            pcall(function() data = HttpService:JSONDecode(res) end)
            if data and data.data then
                local validServers = {}
                for _, s in ipairs(data.data) do
                    if s.id ~= game.JobId and type(s.playing) == "number" and type(s.maxPlayers) == "number" and s.playing >= 5 and s.playing < s.maxPlayers then
                        table.insert(validServers, s)
                    end
                end
                if #validServers == 0 then
                    for _, s in ipairs(data.data) do
                        if s.id ~= game.JobId and type(s.playing) == "number" and type(s.maxPlayers) == "number" and s.playing >= 2 and s.playing < s.maxPlayers then
                            table.insert(validServers, s)
                        end
                    end
                end
                if #validServers > 0 then
                    local chosen = validServers[math.random(1, #validServers)]
                    SendNotification("Identical", "Teleporting (" .. chosen.playing .. "/" .. chosen.maxPlayers .. ")...", 3)
                    task.wait(0.1)
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen.id, LocalPlayer)
                    end)
                    return
                end
            end
        end
        SendNotification("Identical", "No alternative servers found.", 2)
    end, true)

    createButtonRow(srvCard, "Server Hop (Low Player)", "LOW POP", "Joins a low player count server for farming", function()
        queueReinject()
        SendNotification("Identical", "Searching for low-pop server...", 2)
        local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok and res then
            local data = nil
            pcall(function() data = HttpService:JSONDecode(res) end)
            if data and data.data then
                local candidates = {}
                for _, s in ipairs(data.data) do
                    if s.id ~= game.JobId and type(s.playing) == "number" and type(s.maxPlayers) == "number" and s.playing >= 2 and s.playing <= 5 then
                        table.insert(candidates, s)
                    end
                end
                if #candidates == 0 then
                    for _, s in ipairs(data.data) do
                        if s.id ~= game.JobId and type(s.playing) == "number" and type(s.maxPlayers) == "number" and s.playing >= 2 and s.playing < s.maxPlayers then
                            table.insert(candidates, s)
                        end
                    end
                end
                if #candidates > 0 then
                    local chosen = candidates[1]
                    SendNotification("Identical", "Joining low-pop (" .. chosen.playing .. "/" .. chosen.maxPlayers .. ")...", 3)
                    task.wait(0.1)
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen.id, LocalPlayer)
                    end)
                    return
                end
            end
        end
        SendNotification("Identical", "No low-population servers found.", 2)
    end, true)

    createButtonRow(srvCard, "Unload Identical", "UNLOAD", "Closes UI and cleans all hooks & ESP", function()
        if getgenv().IdenticalMM2Unload then
            getgenv().IdenticalMM2Unload()
        end
    end, true)

    SyncUIWithConfig = function()
        isSyncingUI = true
        for key, c in pairs(ctrls) do
            if Config[key] ~= nil then
                if c.SetState then
                    c.SetState(Config[key])
                elseif c.SetValue then
                    c.SetValue(Config[key])
                elseif c.SetSelected then
                    c.SetSelected(Config[key])
                end
            end
        end
        isSyncingUI = false
    end

    SyncUIWithConfig()

    switchTab("Home")

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = string.lower(searchBox.Text:gsub("^%s*(.-)%s*$", "%1"))
        for _, item in ipairs(rowSearchIndex) do
            item.frame.Visible = (q == "" or string.find(item.query, q, 1, true) ~= nil)
        end
    end)

    ToggleUiVisibility = function()
        uiVisible = not uiVisible
        mainFrame.Visible = uiVisible
        if floatingCrescent then
            floatingCrescent.Visible = not uiVisible
        end
    end

    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        bodyFrame.Visible = not isMinimized
        footerBar.Visible = not isMinimized
        mainFrame.Size = isMinimized and UDim2.new(0, 690, 0, 38) or UDim2.new(0, 690, 0, 470)
        minBtn.Text = isMinimized and "[+]" or "[-]"
    end)

    closeBtn.MouseButton1Click:Connect(ToggleUiVisibility)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.LeftControl then
            ToggleUiVisibility()
        elseif input.KeyCode == Enum.KeyCode.End then
            Config.KillAura = false
            Config.AutoShoot = false
            Config.CoinFarm = false
            Config.AutoKill = false
            SendNotification("Identical", "EMERGENCY STOP: Features halted.", 2)
        elseif input.KeyCode == Enum.KeyCode.Space and Config.InfiniteJump then
            local hum = getHumanoid(LocalPlayer.Character)
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)

    local function getOrCreateESP(id, adornee, text, color)
        local bb = trackedESPElements[id]
        if not bb or not bb.Parent then
            bb = Instance.new("BillboardGui")
            bb.Name = id
            bb.Size = UDim2.new(0, 140, 0, 40)
            bb.StudsOffset = Vector3.new(0, 2.5, 0)
            bb.AlwaysOnTop = true
            bb.MaxDistance = Config.ESPDistanceMax
            bb.Adornee = adornee
            bb.Parent = espFolder

            local tag = Instance.new("TextLabel")
            tag.Name = "Tag"
            tag.Size = UDim2.new(1, 0, 1, 0)
            tag.BackgroundTransparency = 1
            tag.Font = Enum.Font.GothamBold
            tag.TextSize = 11
            tag.TextColor3 = color
            tag.TextStrokeTransparency = 0.3
            tag.TextStrokeColor3 = Color3.new(0, 0, 0)
            tag.Parent = bb

            trackedESPElements[id] = bb
        end
        bb.Adornee = adornee
        bb.MaxDistance = Config.ESPDistanceMax
        local tag = bb:FindFirstChild("Tag")
        if tag then
            tag.Text = text
            tag.TextColor3 = color
        end
        return bb
    end

    local function getOrCreateCham(id, targetChar, color)
        local hl = trackedESPElements["cham_" .. id]
        if not hl or not hl.Parent then
            hl = Instance.new("Highlight")
            hl.Name = "cham_" .. id
            hl.FillColor = color
            hl.OutlineColor = Colors.TextPrimary
            hl.FillTransparency = 0.45
            hl.OutlineTransparency = 0.1
            hl.Adornee = targetChar
            hl.Parent = espFolder
            trackedESPElements["cham_" .. id] = hl
        end
        hl.Adornee = targetChar
        hl.FillColor = color
        return hl
    end

    local function updateTracer(id, targetPos, color)
        if not Drawing or not Drawing.new then return end
        local line = trackedTracers[id]
        if not line then
            pcall(function()
                line = Drawing.new("Line")
                line.Thickness = 1.5
                line.Transparency = 0.8
                line.Color = color
                trackedTracers[id] = line
            end)
            line = trackedTracers[id]
        end
        if not line then return end
        
        if Config.ESPTracers then
            local targetFeet = targetPos - Vector3.new(0, 2.5, 0)
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetFeet)
            if onScreen then
                local localChar = LocalPlayer.Character
                local localRoot = getRootPart(localChar)
                local fromPos = nil
                
                if localRoot then
                    local feetWorldPos = localRoot.Position - Vector3.new(0, 2.8, 0)
                    local myScreenPos, myOnScreen = Camera:WorldToViewportPoint(feetWorldPos)
                    if myOnScreen then
                        fromPos = Vector2.new(myScreenPos.X, myScreenPos.Y)
                    end
                end
                
                if not fromPos then
                    fromPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                end
                
                line.From = fromPos
                line.To = Vector2.new(screenPos.X, screenPos.Y)
                line.Color = color
                line.Visible = true
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
    
    local function removeTracer(id)
        if trackedTracers[id] then
            pcall(function() trackedTracers[id]:Remove() end)
            trackedTracers[id] = nil
        end
    end

    local function getClosestKnifeTarget()
        local char = LocalPlayer.Character
        local root = getRootPart(char)
        if not root then return nil end

        local mousePos = UserInputService:GetMouseLocation()
        local bestTarget = nil
        local bestDist = math.huge

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and isPlayerAlive(p) and p.Character then
                local tRoot = getRootPart(p.Character)
                if tRoot then
                    local screenPos = Camera:WorldToViewportPoint(tRoot.Position)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if (not Config.ShowFOV or dist <= Config.FOVRadius) and dist < bestDist then
                        bestDist = dist
                        bestTarget = p
                    end
                end
            end
        end

        if not bestTarget then
            local minDist = math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and isPlayerAlive(p) and p.Character then
                    local tRoot = getRootPart(p.Character)
                    if tRoot then
                        local d = (root.Position - tRoot.Position).Magnitude
                        if d < minDist then
                            minDist = d
                            bestTarget = p
                        end
                    end
                end
            end
        end

        return bestTarget
    end

    local silentAimHookActive = true
    if hookmetamethod and getnamecallmethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()

            if silentAimHookActive and not checkcaller() and method == "FireServer" then
                if self.Name == "KnifeThrown" and (Config.KnifeSilentAim or Config.SilentAim) then
                    local args = {...}
                    local target = getClosestKnifeTarget()
                    if target and target.Character then
                        local tRoot = getRootPart(target.Character)
                        if tRoot then
                            local targetPos = tRoot.Position
                            if Config.AimPrediction then
                                local lead = Config.PingComp and 0.16 or 0.12
                                targetPos = targetPos + (tRoot.AssemblyLinearVelocity * lead)
                            end
                            args[2] = CFrame.new(targetPos)
                            if setnamecallmethod then setnamecallmethod("FireServer") end
                            return oldNamecall(self, unpack(args))
                        end
                    end
                elseif self.Name == "Shoot" and Config.SilentAim then
                    local args = {...}
                    local murderer = nil
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and isPlayerAlive(p) and getPlayerRole(p) == "Murderer" then
                            murderer = p
                            break
                        end
                    end
                    if murderer and murderer.Character then
                        local mRoot = getRootPart(murderer.Character)
                        if mRoot then
                            local targetPos = mRoot.Position
                            if Config.AimPrediction then
                                local lead = Config.PingComp and 0.16 or 0.12
                                targetPos = targetPos + (mRoot.AssemblyLinearVelocity * lead)
                            end
                            args[2] = CFrame.new(targetPos)
                            if setnamecallmethod then setnamecallmethod("FireServer") end
                            return oldNamecall(self, unpack(args))
                        end
                    end
                end
            end

            if setnamecallmethod then setnamecallmethod(method) end
            return oldNamecall(self, ...)
        end))
    end

    local lastFarmTick = 0
    local lastShootTick = 0
    local lastKnifeTick = 0
    local lastSafePosition = nil
    local roundStartedFlag = false
    local auraRingPart = nil
    local auraRingGui = nil
    local fovCircle = nil

    if Drawing and Drawing.new then
        pcall(function()
            local d = Drawing
            fovCircle = d.new("Circle")
            fovCircle.Thickness = 1.5
            fovCircle.Color = Colors.PurpleAccent
            fovCircle.Filled = false
            fovCircle.Transparency = 0.8
            fovCircle.Visible = false
        end)
    end

    local function updateAuraRing(root)
        if not Config.ShowAuraRing or not root then
            if auraRingPart then
                auraRingPart.Transparency = 1
                if auraRingGui then auraRingGui.Enabled = false end
            end
            return
        end

        local diameter = Config.AuraRange * 2

        if not auraRingPart or not auraRingPart.Parent then
            auraRingPart = Instance.new("Part")
            auraRingPart.Name = "Identical_AuraRing"
            auraRingPart.Size = Vector3.new(diameter, 0.01, diameter)
            auraRingPart.Anchored = true
            auraRingPart.CanCollide = false
            auraRingPart.CastShadow = false
            auraRingPart.Transparency = 1

            auraRingGui = Instance.new("SurfaceGui")
            auraRingGui.Name = "RingGui"
            auraRingGui.Face = Enum.NormalId.Top
            auraRingGui.AlwaysOnTop = true
            auraRingGui.LightInfluence = 0
            auraRingGui.Adornee = auraRingPart
            auraRingGui.Parent = auraRingPart

            local ringFrame = Instance.new("Frame")
            ringFrame.Name = "Circle"
            ringFrame.Size = UDim2.new(1, 0, 1, 0)
            ringFrame.BackgroundColor3 = Colors.PurpleAccent
            ringFrame.BackgroundTransparency = 0.92
            ringFrame.BorderSizePixel = 0
            ringFrame.Parent = auraRingGui

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = ringFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = Colors.PurpleAccent
            stroke.Thickness = 2.5
            stroke.Transparency = 0.1
            stroke.Parent = ringFrame

            auraRingPart.Parent = Workspace
        end

        if auraRingGui then auraRingGui.Enabled = true end
        auraRingPart.Size = Vector3.new(diameter, 0.01, diameter)
        auraRingPart.CFrame = CFrame.new(root.Position.X, root.Position.Y - 2.85, root.Position.Z)
    end

    local function updateFOVCircle()
        if not fovCircle then return end
        if Config.ShowFOV then
            fovCircle.Visible = true
            fovCircle.Radius = Config.FOVRadius
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        else
            fovCircle.Visible = false
        end
    end

    table.insert(activeConnections, RunService.Stepped:Connect(function()
        if Config.AntiFling and not isFlinging then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    for _, part in ipairs(p.Character:GetChildren()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end
    end))

    table.insert(activeConnections, RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local root = getRootPart(char)
        local hum = getHumanoid(char)
        local now = tick()

        updateAuraRing(root)
        updateFOVCircle()

        if root and hum then
            local vel = root.AssemblyLinearVelocity
            local angVel = root.AssemblyAngularVelocity
            local velMag = vel.Magnitude
            local angMag = angVel.Magnitude

            if not isFlinging and hum.Health > 0 and hum.FloorMaterial ~= Enum.Material.Air and velMag < 75 and angMag < 35 then
                lastSafePosition = root.CFrame
            end

            if not isFlinging and (Config.AntiFling or Config.AntiVoid) and lastSafePosition then
                if velMag > 120 or angMag > 90 then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    root.CFrame = lastSafePosition
                end

                if Config.AntiVoid and (lastSafePosition.Y - root.Position.Y > 30) then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    root.CFrame = lastSafePosition
                end
            end
        end

        if hum then
            if Config.SpeedEnabled then
                if hum.WalkSpeed ~= Config.SpeedValue then hum.WalkSpeed = Config.SpeedValue end
            else
                if hum.WalkSpeed ~= 16 and not Config.CoinFarm then hum.WalkSpeed = 16 end
            end

            if Config.JumpEnabled then
                if hum.JumpPower ~= Config.JumpValue then hum.JumpPower = Config.JumpValue end
            end
        end

        if Config.Noclip and char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                end
            end
        end



        if Config.Fullbright then
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.Brightness = 2
        end

        if Config.NoFog then
            Lighting.FogEnd = 1e6
        end

        local rtp = Workspace:FindFirstChild("RoundTimerPart")
        if rtp and rtp:FindFirstChild("SurfaceGui") then
            local sg = rtp.SurfaceGui
            local cr = sg:FindFirstChild("CurrentRound")
            local tm = sg:FindFirstChild("Timer")
            if cr and tm then
                statusRoundRow.SetValue(cr.Text)
                timerRoundRow.SetValue(tm.Text)
                if cr.Text == "Current Round" and not roundStartedFlag then
                    roundStartedFlag = true
                    if Config.AutoDrop then
                        local map = getActiveMap()
                        if map and root then
                            local p = map:FindFirstChild("Spawns") or map:FindFirstChildWhichIsA("BasePart")
                            if p then
                                local sp = p:IsA("Model") and p:GetChildren()[1] or p
                                if sp then root.CFrame = sp.CFrame * CFrame.new(0, 4, 0) end
                            end
                        end
                    end
                elseif cr.Text ~= "Current Round" then
                    roundStartedFlag = false
                end
            end
        end

        local murderer, sheriff = getRolePlayers()
        murdererRow.SetValue(murderer and (murderer.Name .. (isPlayerAlive(murderer) and "" or " [DEAD]")) or "Undetected")
        sheriffRow.SetValue(sheriff and (sheriff.Name .. (isPlayerAlive(sheriff) and "" or " [DEAD]")) or "Undetected")

        if Config.RoleESP and root then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and isPlayerAlive(p) then
                    local pRoot = getRootPart(p.Character)
                    if pRoot then
                        local dist = math.floor((root.Position - pRoot.Position).Magnitude)
                        if dist <= Config.ESPDistanceMax then
                            local role = getPlayerRole(p)
                            local col = Colors.AccentGreen
                            if role == "Murderer" then
                                col = Colors.AccentRed
                            elseif role == "Sheriff" then
                                col = Colors.AccentBlue
                            end

                            local text = p.Name
                            if Config.ESPNames then
                                text = "[" .. role .. "] " .. p.Name
                            end
                            if Config.ESPDistance then
                                text = text .. " (" .. dist .. "s)"
                            end

                            getOrCreateESP("mm2_" .. p.UserId, pRoot, text, col)
                            if Config.ESPChams then
                                getOrCreateCham(p.UserId, p.Character, col)
                            end
                            updateTracer("mm2_" .. p.UserId, pRoot.Position, col)
                        end
                    end
                else
                    if trackedESPElements["mm2_" .. p.UserId] then
                        trackedESPElements["mm2_" .. p.UserId]:Destroy()
                        trackedESPElements["mm2_" .. p.UserId] = nil
                    end
                    if trackedESPElements["cham_" .. p.UserId] then
                        trackedESPElements["cham_" .. p.UserId]:Destroy()
                        trackedESPElements["cham_" .. p.UserId] = nil
                    end
                    removeTracer("mm2_" .. p.UserId)
                end
            end
        end

        if Config.GunESP and root then
            local drop = getGunDrop()
            local gunPart = getGunDropPart(drop)
            if gunPart then
                local dist = math.floor((root.Position - gunPart.Position).Magnitude)
                if dist <= Config.ESPDistanceMax then
                    getOrCreateESP("gun_drop", gunPart, "[GUN DROP] " .. dist .. "m", Colors.AccentYellow)
                end
            else
                clearESPCategory("gun_")
            end
        end

        if Config.CoinESP and root then
            local coins = getAllActiveCoins()
            for _, coin in ipairs(coins) do
                local dist = math.floor((root.Position - coin.Position).Magnitude)
                if dist <= Config.ESPDistanceMax then
                    getOrCreateESP("coin_" .. coin:GetDebugId(), coin, "Coin", Colors.AccentYellow)
                end
            end
        end

        if Config.GrabGunAuto and root then
            local drop = getGunDrop()
            local gunPart = getGunDropPart(drop)
            if gunPart and (root.Position - gunPart.Position).Magnitude <= Config.GunGrabDist then
                interactWithGunDrop(gunPart, drop)
            end
        end

        if Config.AutoShoot and root and (now - lastShootTick >= 0.5) then
            local bp = LocalPlayer:FindFirstChild("Backpack")
            local gun = (bp and bp:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun"))
            if gun and murderer and murderer.Character and isPlayerAlive(murderer) then
                local mRoot = getRootPart(murderer.Character)
                if mRoot then
                    if hum and bp and gun.Parent == bp then
                        hum:EquipTool(gun)
                    end
                    local rayAtt = root:FindFirstChild("GunRaycastAttachment")
                    local origin = rayAtt and rayAtt.WorldCFrame or root.CFrame
                    local aimPos = mRoot.Position
                    if Config.AimPrediction then
                        aimPos = aimPos + (mRoot.AssemblyLinearVelocity * 0.12)
                    end
                    if gun:FindFirstChild("Shoot") then
                        gun.Shoot:FireServer(origin, CFrame.new(aimPos))
                        lastShootTick = now
                        if Config.SingleShot then Config.AutoShoot = false end
                    end
                end
            end
        end

        if (Config.KillAura or Config.AutoKill) and root and (now - lastKnifeTick >= 0.2) then
            local bp = LocalPlayer:FindFirstChild("Backpack")
            local knife = (bp and bp:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife"))
            if knife then
                if hum and bp and knife.Parent == bp then
                    hum:EquipTool(knife)
                end
                local events = knife:FindFirstChild("Events")
                if events then
                    if Config.KillMode == "Throw" and events:FindFirstChild("KnifeThrown") and knife:FindFirstChild("Handle") then
                        local target = getClosestKnifeTarget()
                        if target and target.Character then
                            local tRoot = getRootPart(target.Character)
                            if tRoot then
                                local d = (root.Position - tRoot.Position).Magnitude
                                if Config.KillAll or d <= Config.AuraRange then
                                    local targetPos = tRoot.Position
                                    if Config.AimPrediction then
                                        local lead = Config.PingComp and 0.16 or 0.12
                                        targetPos = targetPos + (tRoot.AssemblyLinearVelocity * lead)
                                    end
                                    events.KnifeThrown:FireServer(knife.Handle.CFrame, CFrame.new(targetPos))
                                    lastKnifeTick = now
                                end
                            end
                        end
                    elseif events:FindFirstChild("HandleTouched") then
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and isPlayerAlive(p) then
                                local tRoot = getRootPart(p.Character)
                                if tRoot then
                                    local d = (root.Position - tRoot.Position).Magnitude
                                    if Config.KillAll or d <= Config.AuraRange then
                                        events.HandleTouched:FireServer(tRoot)
                                        if events:FindFirstChild("KnifeStabbed") then
                                            events.KnifeStabbed:FireServer()
                                        end
                                        lastKnifeTick = now
                                        if not Config.KillAll then
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        if Config.HitboxExpander then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and isPlayerAlive(p) then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        if not originalHitboxSizes[hrp] then
                            originalHitboxSizes[hrp] = hrp.Size
                        end
                        hrp.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                        hrp.Transparency = Config.HitboxTransparency
                        hrp.CanCollide = false
                    end
                end
            end
        end

        if Config.MurdererAvoid and root and murderer and murderer.Character and isPlayerAlive(murderer) then
            local mRoot = getRootPart(murderer.Character)
            if mRoot then
                local dist = (root.Position - mRoot.Position).Magnitude
                if dist < Config.SafetyRadius then
                    if Config.SprintWhenChased and hum then
                        hum.WalkSpeed = math.max(hum.WalkSpeed, 26)
                    end
                    if Config.RetreatToLobby then
                        local lobby = getLobbyModel()
                        if lobby then
                            local sp = lobby:FindFirstChildWhichIsA("BasePart")
                            if sp then root.CFrame = sp.CFrame * CFrame.new(0, 3, 0) end
                        end
                    else
                        local awayDir = (root.Position - mRoot.Position).Unit
                        root.CFrame = root.CFrame + Vector3.new(awayDir.X * 0.8, 0, awayDir.Z * 0.8)
                    end
                end
            end
        end

        if Config.FollowMurderer and root and murderer and murderer.Character and isPlayerAlive(murderer) then
            local mRoot = getRootPart(murderer.Character)
            if mRoot then
                local targetPos = mRoot.Position - (mRoot.CFrame.LookVector * Config.FollowDist)
                root.CFrame = root.CFrame:Lerp(CFrame.new(targetPos, mRoot.Position), 0.15)
            end
        end

        if Config.CoinFarm and root and (now - lastFarmTick >= 0.05) then
            if Config.BagFullStop and getCurrentCoinCount() >= Config.CoinBagCap then
                Config.CoinFarm = false
                SendNotification("Identical", "Coin bag limit reached! Farming stopped.", 3)
            else
                local coins = getAllActiveCoins()
                local bestCoin = nil
                local bestDist = 1000

                for _, c in ipairs(coins) do
                    local d = (root.Position - c.Position).Magnitude
                    local isSafe = true
                    if Config.SafeCoinFarm and murderer and murderer.Character and isPlayerAlive(murderer) then
                        local mRoot = getRootPart(murderer.Character)
                        if mRoot and (c.Position - mRoot.Position).Magnitude < Config.SafetyRadius then
                            isSafe = false
                        end
                    end
                    if isSafe and d < bestDist then
                        bestDist = d
                        bestCoin = c
                    end
                end

                if bestCoin then
                    if hum then
                        hum.WalkSpeed = Config.FarmSpeed
                    end
                    local targetPos = bestCoin.Position
                    local dist = (root.Position - targetPos).Magnitude

                    for _, part in ipairs(char:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end

                    local speed = Config.QuickFarm and 38 or math.clamp(Config.FarmSpeed, 16, 42)

                    if Config.FarmMethod == "Tween" then
                        local travelTime = math.max(dist / speed, 0.05)
                        local tweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear)
                        local tw = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetPos)})
                        tw:Play()
                        if dist < 7 then
                            fireTouch(root, bestCoin)
                            local rHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
                            if rHand then fireTouch(rHand, bestCoin) end
                        end
                    elseif Config.FarmMethod == "Glide" or Config.QuickFarm then
                        local dir = (targetPos - root.Position)
                        if dir.Magnitude > 0.3 then
                            root.AssemblyLinearVelocity = dir.Unit * speed
                        else
                            root.AssemblyLinearVelocity = Vector3.zero
                        end
                        if dist < 7 then
                            fireTouch(root, bestCoin)
                            local rHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
                            if rHand then fireTouch(rHand, bestCoin) end
                        end
                    else
                        if hum then
                            hum:MoveTo(targetPos)
                            if targetPos.Y > root.Position.Y + 2.0 and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
                                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                            end
                        end
                        if dist < 7 then
                            fireTouch(root, bestCoin)
                            local rHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
                            if rHand then fireTouch(rHand, bestCoin) end
                        end
                    end
                    lastFarmTick = now
                end
            end
        end
    end))

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            p.CharacterAdded:Connect(function(c)
                local h = c:WaitForChild("Humanoid", 5)
                if h then
                    h.Died:Connect(function()
                        table.insert(deadPlayersList, p.Name)
                        if Config.DeathNotifs then
                            local r = getPlayerRole(p)
                            SendNotification("Death Alert", p.Name .. " [" .. r .. "] has died!", 3)
                        end
                    end)
                end
            end)
        end
    end

    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function(c)
            local h = c:WaitForChild("Humanoid", 5)
            if h then
                h.Died:Connect(function()
                    table.insert(deadPlayersList, p.Name)
                    if Config.DeathNotifs then
                        local r = getPlayerRole(p)
                        SendNotification("Death Alert", p.Name .. " [" .. r .. "] has died!", 3)
                    end
                end)
            end
        end)
    end)

    LocalPlayer.Idled:Connect(function()
        if Config.AntiAFK then
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end
    end)

    getgenv().IdenticalMM2Unload = function()
        for _, conn in ipairs(activeConnections) do
            pcall(function() conn:Disconnect() end)
        end
        clearESPCategory("")
        for id in pairs(trackedTracers) do
            pcall(function() trackedTracers[id]:Remove() end)
        end
        silentAimHookActive = false
        if auraRingPart then
            auraRingPart:Destroy()
            auraRingPart = nil
        end
        if fovCircle then
            pcall(function() fovCircle:Remove() end)
            fovCircle = nil
        end
        for part, sz in pairs(originalHitboxSizes) do
            if part and part.Parent then
                part.Size = sz
                part.Transparency = 1
            end
        end
        if screenGui then screenGui:Destroy() end
        getgenv().IdenticalMM2Unload = nil
    end

    SendNotification("Identical", "Loaded! Press Left-CTRL to toggle.", 3)
