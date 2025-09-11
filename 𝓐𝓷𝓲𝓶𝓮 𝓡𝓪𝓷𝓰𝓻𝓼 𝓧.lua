--=====================================================
-- =============  LOAD & CREATE WINDOW  ===============
--=====================================================
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/x2zu/OPEN-SOURCE-UI-ROBLOX/refs/heads/main/X2ZU%20UI%20ROBLOX%20OPEN%20SOURCE/DummyUi-leak-by-x2zu/fetching-main/Tools/Framework.luau"
))()

local Window = Library:Window({
    Title = "Auto UI",
    Desc = "AutoPlay | Upgrade | Speed | Vote | PlayerOnly | Webhooks",
    Icon = 105059922903197,
    Theme = "Dark",
    Config = { Keybind = Enum.KeyCode.LeftControl, Size = UDim2.new(0, 540, 0, 440) },
    CloseUIButton = { Enabled = true, Text = "Close" }
})

do -- optional sidebar line
    local SidebarLine = Instance.new("Frame")
    SidebarLine.Size = UDim2.new(0, 1, 1, 0)
    SidebarLine.Position = UDim2.new(0, 140, 0, 0)
    SidebarLine.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    SidebarLine.BorderSizePixel = 0
    SidebarLine.ZIndex = 5
    SidebarLine.Name = "SidebarLine"
    SidebarLine.Parent = game:GetService("CoreGui")
end

--=====================================================
-- ==================  SHARED REFS  ===================
--=====================================================
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Remotes
local Rmt       = RS:WaitForChild("Remote")
local R_Server  = Rmt:WaitForChild("Server")
local R_OnGame  = R_Server:WaitForChild("OnGame")
local R_Voting  = R_OnGame:WaitForChild("Voting")
local R_Units   = R_Server:WaitForChild("Units")

--=====================================================
-- ==================  HELPERS  =======================
--=====================================================
local function safeFind(root, pathArray)
    local cur = root
    for _, name in ipairs(pathArray) do
        cur = cur and cur:FindFirstChild(name)
        if not cur then return nil end
    end
    return cur
end

local function safeText(inst)
    if not inst then return "N/A" end
    local ok, txt = pcall(function() return inst.Text end)
    if ok and typeof(txt) == "string" and txt ~= "" then return txt end
    return "N/A"
end

local function getDamage()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if not ls then return "N/A" end
    local stat = ls:FindFirstChild("Total Damage") or ls:FindFirstChild("Damage") or ls:FindFirstChild("TotalDamage")
    if not stat then return "N/A" end
    return tostring(stat.Value)
end

-- หา container ของ Rewards (รองรับทั้ง Rewards.ItemsList / Rewards ตรง ๆ / ItemsList ใต้ LeftSide)
local function findRewardsContainer(leftSide)
    if not leftSide then return nil end
    local rewards = leftSide:FindFirstChild("Rewards")
    if rewards then
        return rewards:FindFirstChild("ItemsList") or rewards
    end
    return leftSide:FindFirstChild("ItemsList")
end

-- ข้าม layout/ตกแต่ง
local IGNORE_NAME  = { UICorner = true, UIGridLayout = true, UIListLayout = true }
local IGNORE_CLASS = { UIGridLayout = true, UIListLayout = true }

-- รวมรายการรางวัล (ไม่เอา UICorner/UIGridLayout)
local function collectRewards(container)
    if not container then return "N/A" end
    local out = {}
    for _, child in ipairs(container:GetChildren()) do
        if not IGNORE_NAME[child.Name] and not IGNORE_CLASS[child.ClassName] then
            local label = child:IsA("TextLabel") and child or child:FindFirstChildWhichIsA("TextLabel", true)
            local nameText = (label and label.Text and label.Text ~= "") and label.Text or child.Name
            local amountObj = child:FindFirstChild("Amount") or child:FindFirstChild("Qty") or child:FindFirstChild("Count")
            local amountText = amountObj and (amountObj.Text or amountObj.Value)
            table.insert(out, amountText and (nameText .. " x" .. tostring(amountText)) or nameText)
        end
    end
    return (#out > 0) and table.concat(out, "\n") or "N/A"
end

local function isWinText(txt)
    txt = tostring(txt or ""):upper():match("^%s*(.-)%s*$")
    return txt == "~ WON" or txt:find("WON", 1, true) ~= nil
end

--=====================================================
-- =================  WEBHOOK LOGIC  ==================
--=====================================================
local WEBHOOK_URL = "" -- ตั้งค่าได้จาก Textbox แท็บ Webhooks

-- ส่งข้อมูลจริงตอนชนะ
local function sendWebhook()
    if WEBHOOK_URL == "" then
        warn("[Webhook] กรุณาใส่ Webhook URL ในแท็บ Webhooks ก่อน")
        return
    end

    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    local rewardsUI = pg:FindFirstChild("RewardsUI")
    if not rewardsUI then return end
    local leftSide = safeFind(rewardsUI, {"Main","LeftSide"})
    if not leftSide then return end

    local totalTime  = leftSide:FindFirstChild("TotalTime")
    local chapter    = leftSide:FindFirstChild("Chapter")
    local mode       = leftSide:FindFirstChild("Mode")
    local difficulty = leftSide:FindFirstChild("Difficulty")
    local world      = leftSide:FindFirstChild("World")
    local itemsCont  = findRewardsContainer(leftSide)

    local payload = {
        username = "RepintX",
        avatar_url = "https://cdn.discordapp.com/attachments/1412823986869637272/1415317557522595921/ChatGPT_Image_10_.._2568_19_15_59.png?ex=68c36d71&is=68c21bf1&hm=a2d31f80d9561c349ccbb8370ff7d24e0a82f2d0cb0539aa5dea8af321e19a89&",
        embeds = {{
            author = {
                name = "𝓐𝓷𝓲𝓶𝓮 𝓡𝓪𝓷𝓰𝓻𝓼 𝓧",
                icon_url = "https://media.discordapp.net/attachments/1412823986869637272/1415631453253013575/1000.png?ex=68c3e907&is=68c29787&hm=5194ace4e402964aefd1136c17331ac774194fc14cd9e032f6d5e744961a1550&=&format=webp&quality=lossless"
            },
            title = "ʏᴏᴜʀ ᴡɪɴ",
            color = 5432368,
            thumbnail = {
                url = "https://cdn.discordapp.com/attachments/1412823986869637272/1415317557522595921/ChatGPT_Image_10_.._2568_19_15_59.png?ex=68c36d71&is=68c21bf1&hm=a2d31f80d9561c349ccbb8370ff7d24e0a82f2d0cb0539aa5dea8af321e19a89&"
            },
            image = {
                url = "https://cdn.discordapp.com/attachments/1413105342253895861/1415628308611076126/noFilter.png?ex=68c3e619&is=68c29499&hm=855bccc9c6d8ac2749d1a726191c82c38e2a6c1807fbec57b986f1afabf1a1a6&"
            },
            fields = {
                { name = "NAME",       value = LocalPlayer.Name,             inline = true },
                { name = "Damage",     value = getDamage(),                  inline = true },
                { name = "Time",       value = safeText(totalTime),          inline = true },
                { name = "Chapter",    value = safeText(chapter),            inline = true },
                { name = "Mode",       value = safeText(mode),               inline = true },
                { name = "Difficulty", value = safeText(difficulty),         inline = true },
                { name = "World",      value = safeText(world),              inline = true },
                { name = "Rewards",    value = collectRewards(itemsCont),    inline = false },
            }
        }}
    }

    local body = HttpService:JSONEncode(payload)
    local req = (http_request or request or (syn and syn.request) or (fluxus and fluxus.request))
    if req then
        req({ Url = WEBHOOK_URL, Method = "POST",
              Headers = { ["Content-Type"] = "application/json" }, Body = body })
    else
        pcall(function()
            HttpService:PostAsync(WEBHOOK_URL, body, Enum.HttpContentType.ApplicationJson)
        end)
    end
end

-- ส่ง payload ทดสอบ (ตามตัวอย่าง)
local function sendWebhookTest()
    if WEBHOOK_URL == "" then
        warn("[Webhook] กรุณาใส่ Webhook URL ในแท็บ Webhooks ก่อน")
        return
    end
    local payload = {
        username = "PeintX",
        avatar_url = "https://cdn.discordapp.com/attachments/1412823986869637272/1415317557522595921/ChatGPT_Image_10_.._2568_19_15_59.png?ex=68c36d71&is=68c21bf1&hm=a2d31f80d9561c349ccbb8370ff7d24e0a82f2d0cb0539aa5dea8af321e19a89&",
        embeds = {{
            color = 15733389,
            description = "```\nพร้อมใช้งาน 🟢  \n```",
            image = {
                url = "https://media.discordapp.net/attachments/1413105342253895861/1415628308611076126/noFilter.png?ex=68c3e619&is=68c29499&hm=855bccc9c6d8ac2749d1a726191c82c38e2a6c1807fbec57b986f1afabf1a1a6&=&format=webp&quality=lossless"
            },
            author = {
                name = "Test",
                icon_url = "https://cdn.discordapp.com/attachments/1412823986869637272/1415631453253013575/1000.png?ex=68c3e907&is=68c29787&hm=5194ace4e402964aefd1136c17331ac774194fc14cd9e032f6d5e744961a1550&"
            }
        }}
    }
    local body = HttpService:JSONEncode(payload)
    local req = (http_request or request or (syn and syn.request) or (fluxus and fluxus.request))
    if req then
        req({ Url = WEBHOOK_URL, Method = "POST",
              Headers = { ["Content-Type"] = "application/json" }, Body = body })
    else
        pcall(function()
            HttpService:PostAsync(WEBHOOK_URL, body, Enum.HttpContentType.ApplicationJson)
        end)
    end
end

--=====================================================
-- ===================  TAB: AUTO  ====================
--=====================================================
local AutoTab = Window:Tab({Title = "Auto", Icon = "zap"})
AutoTab:Section({Title = "Core Automation"})

-- AutoPlay (toggle via same remote)
AutoTab:Toggle({
    Title = "AutoPlay",
    Desc = "เปิดคือเริ่มออโต้เพลย์ / ปิดคือหยุด (กดแล้ว Toggle)",
    Value = false,
    Callback = function(state)
        R_Units:WaitForChild("AutoPlay"):FireServer()
        print(state and "✅ AutoPlay Enabled" or "❌ AutoPlay Disabled")
    end
})

-- Auto Upgrade Units
do
    local running, thread = false, nil
    AutoTab:Toggle({
        Title = "Auto Upgrade Units",
        Desc = "อัปเกรดทุกตัวใน UnitsFolder ทุก 5 วินาที",
        Value = false,
        Callback = function(state)
            running = state
            if running and not thread then
                thread = task.spawn(function()
                    local unitsFolder = LocalPlayer:WaitForChild("UnitsFolder")
                    while running do
                        for _, unit in ipairs(unitsFolder:GetChildren()) do
                            if typeof(unit) == "Instance" then
                                R_Units:WaitForChild("Upgrade"):FireServer(unit)
                                task.wait(0.1)
                            end
                        end
                        task.wait(5)
                    end
                    thread = nil
                end)
            else
                thread = nil
            end
        end
    })
end

-- Speed tier dropdown + auto use
local selectedSpeedTier = 1
AutoTab:Dropdown({
    Title = "Speed Gamepass Tier",
    List = {"1","2","3"},
    Value = "1",
    Callback = function(choice) selectedSpeedTier = tonumber(choice) or 1 end
})

do
    local running, thread = false, nil
    AutoTab:Toggle({
        Title = "Auto Use Speed Gamepass",
        Desc = "เรียก Remote.SpeedGamepass(tier) ทุก 5 วิ",
        Value = false,
        Callback = function(state)
            running = state
            if running and not thread then
                thread = task.spawn(function()
                    while running do
                        Rmt:WaitForChild("SpeedGamepass"):FireServer(selectedSpeedTier)
                        task.wait(5)
                    end
                    thread = nil
                end)
            else
                thread = nil
            end
        end
    })
end

-- Auto Vote Start
do
    local running, thread = false, nil
    AutoTab:Toggle({
        Title = "Auto Vote Start Game",
        Desc = "โหวตเริ่มเกมทุก ๆ 5 วินาที",
        Value = false,
        Callback = function(state)
            running = state
            if running and not thread then
                thread = task.spawn(function()
                    local VotePlaying = R_Voting:WaitForChild("VotePlaying")
                    while running do
                        VotePlaying:FireServer()
                        task.wait(5)
                    end
                    thread = nil
                end)
            else
                thread = nil
            end
        end
    })
end

--=====================================================
-- ==============  TAB: SETTING MAP  ==================
--=====================================================
local SettingTab = Window:Tab({Title = "Setting Map", Icon = "map"})
SettingTab:Section({Title = "Vote Options"})

-- Auto Next
do
    local running, thread = false, nil
    SettingTab:Toggle({
        Title = "Auto Vote Next",
        Desc = "โหวตไปด่านถัดไปอัตโนมัติ",
        Value = false,
        Callback = function(state)
            running = state
            if running and not thread then
                thread = task.spawn(function()
                    local VoteNext = R_Voting:WaitForChild("VoteNext")
                    while running do
                        VoteNext:FireServer()
                        task.wait(5)
                    end
                    thread = nil
                end)
            else
                thread = nil
            end
        end
    })
end

-- Auto Replay
do
    local running, thread = false, nil
    SettingTab:Toggle({
        Title = "Auto Replay",
        Desc = "เล่นแมพเดิมอัตโนมัติ",
        Value = false,
        Callback = function(state)
            running = state
            if running and not thread then
                thread = task.spawn(function()
                    local VoteRetry = R_Voting:WaitForChild("VoteRetry")
                    while running do
                        VoteRetry:FireServer()
                        task.wait(5)
                    end
                    thread = nil
                end)
            else
                thread = nil
            end
        end
    })
end

-- Auto Leave
do
    local running, thread = false, nil
    SettingTab:Toggle({
        Title = "Auto Leave",
        Desc = "โหวตออกจากรอบอัตโนมัติ",
        Value = false,
        Callback = function(state)
            running = state
            if running and not thread then
                thread = task.spawn(function()
                    local VoteLeave = R_Voting:WaitForChild("VoteLeave")
                    while running do
                        VoteLeave:FireServer()
                        task.wait(5)
                    end
                    thread = nil
                end)
            else
                thread = nil
            end
        end
    })
end

-- Player Only (ถ้ามีคนอื่นเข้ามา → Rejoin)
SettingTab:Section({Title = "Server Control"})
do
    local running, thread = false, nil
    SettingTab:Toggle({
        Title = "Player Only",
        Desc = "อยู่คนเดียวเท่านั้น—ถ้ามีผู้เล่นอื่นเข้ามา จะ Rejoin เกมใหม่",
        Value = false,
        Callback = function(state)
            running = state
            if running and not thread then
                thread = task.spawn(function()
                    while running do
                        if #Players:GetPlayers() > 1 then
                            warn("👥 พบผู้เล่นอื่น → Rejoining...")
                            task.wait(1)
                            TeleportService:Teleport(game.PlaceId, LocalPlayer)
                            break
                        end
                        task.wait(3)
                    end
                    thread = nil
                end)
            else
                thread = nil
            end
        end
    })
end

--=====================================================
-- =================  TAB: WEBHOOKS  ==================
--=====================================================
local WebTab = Window:Tab({Title = "Webhooks", Icon = "link"})
WebTab:Section({Title = "Discord Webhooks"})

-- Textbox ใส่ URL
WebTab:Textbox({
    Title = "Webhook URL",
    Desc = "พิมพ์ลิงก์ Discord Webhook ของคุณ",
    Placeholder = "https://discord.com/api/webhooks/...",
    Value = WEBHOOK_URL,
    ClearTextOnFocus = false,
    Callback = function(text)
        WEBHOOK_URL = text or ""
        print("✅ ตั้งค่า Webhook URL:", WEBHOOK_URL)
    end
})

-- ปุ่มทดสอบส่งตาม JSON ตัวอย่าง
WebTab:Button({
    Title = "Test Send Webhook",
    Desc = "ส่งข้อความทดสอบไปยัง Discord",
    Callback = function()
        sendWebhookTest()
    end
})

-- Auto ส่งเมื่อ WIN (~ WON) — ส่งทุกครั้งที่ชนะ (จับ RewardsUI ทุกจบรอบ)
do
    local enabled, thread = false, nil

    WebTab:Toggle({
        Title = "Auto Webhook on WIN (~ WON)",
        Desc = "เมื่อชนะจะส่งข้อมูลอัตโนมัติ ทุกครั้งที่จบรอบ",
        Value = false,
        Callback = function(state)
            enabled = state
            if enabled and not thread then
                thread = task.spawn(function()
                    while enabled do
                        -- รอ RewardsUI ของรอบนี้โผล่
                        local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
                        local rewardsUI = pg:WaitForChild("RewardsUI", 180)
                        if not (enabled and rewardsUI) then
                            task.wait(1)
                            continue
                        end

                        local leftSide = safeFind(rewardsUI, {"Main","LeftSide"})
                        local gameStatus = leftSide and leftSide:FindFirstChild("GameStatus") or nil
                        if not gameStatus then
                            -- ถ้าไม่มี component ที่ต้องใช้ รอรอบถัดไป
                            rewardsUI.AncestryChanged:Wait()
                            continue
                        end

                        local sentForThisRound = false
                        local function checkWin()
                            if enabled and not sentForThisRound and isWinText(gameStatus.Text) then
                                sentForThisRound = true
                                sendWebhook()
                            end
                        end

                        -- เช็คทันที + ฟังการเปลี่ยนแปลง
                        checkWin()
                        local conn = gameStatus:GetPropertyChangedSignal("Text"):Connect(checkWin)

                        -- รอจน RewardsUI ปิด (จบรอบ) แล้ววนใหม่
                        rewardsUI.AncestryChanged:Wait()
                        if conn then conn:Disconnect() end
                    end
                    thread = nil
                end)
            elseif (not enabled) and thread then
                -- ปิดระบบ: loop จะจบหลังรอบปัจจุบัน
                thread = nil
            end
        end
    })
end
