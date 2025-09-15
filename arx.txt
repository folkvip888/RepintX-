--====================================================
-- RepintX (Obsidian/Linoria) - Event + Game + Create Room + UI Settings
--  Event : Auto Restart @2/2, Auto Hide Rewards UI, Adventure Votes (Endure/Evade)
--           Auto Join: Swarm / Adventure / Expedition (toggle + cooldown)
--  Game  : Auto Retry/Next/Playing votes, AutoPlay bool, Redeem Codes (0.35s),
--           Use Auto Trait Reroll (Gamepass) + Use 3x Game Speed (Gamepass + click)
--  Create Room: Stage/Map/Chapter/Difficulty/FriendOnly + AutoStart
--====================================================

-- libs
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

-- Window/Tabs
local Window = Library:CreateWindow({
    Title = "RepintX",
    Footer = "version: example",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = true,
    AutoShow = true,
})
local Tabs = {
    Game   = Window:AddTab("Game", "gamepad-2"),
    Event  = Window:AddTab("Event", "activity"),
    ["Create Room"] = Window:AddTab("Create Room", "plus-square"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}
local Options, Toggles = Library.Options, Library.Toggles

--====================================================
-- Helpers
--====================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local VIM = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local function safeWaitPath(root, path, timeout)
    local node, t0 = root, os.clock()
    for i, name in ipairs(path) do
        local ok, found = pcall(function() return node:WaitForChild(name, 2) end)
        if not ok or not found then
            repeat
                found = node:FindFirstChild(name)
                if found then break end
                task.wait(0.2)
            until (os.clock() - t0) >= (timeout or 10)
        end
        if not found then return nil, ("missing: %s (idx %d)"):format(name, i) end
        node = found
    end
    return node
end

local function findFirstClickable(container)
    if not container then return nil end
    for _, d in ipairs(container:GetDescendants()) do
        if d.Name == "Click" and (d:IsA("TextButton") or d:IsA("ImageButton")) then return d end
        if d:IsA("TextButton") or d:IsA("ImageButton") then return d end
    end
    if container:IsA("TextButton") or container:IsA("ImageButton") then return container end
    return nil
end

local function clickGuiObject(obj)
    if not obj then return end
    local inset = GuiService:GetGuiInset()
    local center = obj.AbsolutePosition + (obj.AbsoluteSize / 2)
    VIM:SendMouseButtonEvent(center.X, center.Y + inset.Y, 0, true, obj, 0)
    VIM:SendMouseButtonEvent(center.X, center.Y + inset.Y, 0, false, obj, 0)
end

local function clickIfExists(pathParts, timeout)
    local node = safeWaitPath(game, pathParts, timeout or 8)
    if not node then return false end
    local btn = findFirstClickable(node)
    if not btn then return false end
    clickGuiObject(btn)
    return true
end

local function setBoolValueSafely(valObj, bool)
    if not valObj then return end
    pcall(function() if valObj.Value ~= nil then valObj.Value = bool end end)
    pcall(function() if valObj.value ~= nil then valObj.value = bool end end)
end

local function wavesIsTwoOfTwo(wavesLabel)
    local txt = tostring(wavesLabel.Text or "")
    return (txt == "2/2") or (txt:find("2%s*/%s*2") ~= nil)
end

-- vote remotes
local function getVoteRemote(key)
    local ok, r = pcall(function()
        return ReplicatedStorage
            :WaitForChild("Remote")
            :WaitForChild("Server")
            :WaitForChild("OnGame")
            :WaitForChild("Voting")
            :WaitForChild(key)
    end)
    return ok and r or nil
end
local function spamVote(remoteName, duration, interval)
    duration = duration or 5
    interval = interval or 0.25
    local r = getVoteRemote(remoteName)
    if not r then return end
    local t0 = os.clock()
    while (os.clock() - t0) < duration do
        pcall(function() r:FireServer() end)
        task.wait(interval)
    end
end

-- scroll helpers (for Create Room)
local function scrollIntoViewAndClick(sf, target)
    if not (sf and target and sf:IsA("ScrollingFrame")) then return false end
    local function clamp(n, a, b) if n < a then return a elseif n > b then return b else return n end end
    local yInView = (target.AbsolutePosition.Y - sf.AbsolutePosition.Y) + sf.CanvasPosition.Y
    local desired = yInView - (sf.AbsoluteSize.Y * 0.35)
    local maxY = math.max(0, sf.AbsoluteCanvasSize.Y - sf.AbsoluteSize.Y)
    sf.CanvasPosition = Vector2.new(0, clamp(desired, 0, maxY)); task.wait(0.06)
    local btn = findFirstClickable(target)
    if btn then clickGuiObject(btn); return true end
    return false
end
local function scrollClickByName(sf, childName)
    if not (sf and childName) then return false end
    local target = sf:FindFirstChild(childName)
    if not target then
        for _, c in ipairs(sf:GetChildren()) do
            if c.Name and c.Name:lower():find(childName:lower(), 1, true) then target = c; break end
        end
    end
    if not target then return false end
    return scrollIntoViewAndClick(sf, target)
end

--====================================================
-- Stage_Select Support (Story / Ranger / Raids / Infinite)
--====================================================
local STAGE_LIST = { "Story", "Ranger", "Raids", "Infinite" }
local function selectStageMode(mode)
    mode = mode or "Story"
    local node = safeWaitPath(pg, {"PlayRoom","Main","GameStage","Main","Stage_Select", mode}, 3)
    if not node then return false end
    local btn = findFirstClickable(node) or node
    if btn then clickGuiObject(btn); return true end
    return false
end
local function getStageRoots(stage)
    stage = stage or "Story"
    local baseRoot = safeWaitPath(pg, {"PlayRoom","Main","GameStage","Main","Base", stage}, 0.2)
    local selRoot  = safeWaitPath(pg, {"PlayRoom","Main","GameStage","Main","Stage_Select", stage}, 0.2)
    return baseRoot, selRoot
end
local function getMapScrollForStage(stage)
    local baseRoot, selRoot = getStageRoots(stage)
    local function pickSF(root)
        if not root then return nil end
        return root:FindFirstChild("ScrollingFrame") or root:FindFirstChildWhichIsA("ScrollingFrame")
    end
    return pickSF(baseRoot) or pickSF(selRoot)
end
local function getChapterRoot(stage, mapName)
    local root = safeWaitPath(pg, {"PlayRoom","Main","GameStage","Main","Base","Chapter", mapName}, 0.5)
    if root then return root end
    local _, selRoot = getStageRoots(stage)
    if selRoot then
        local ch = selRoot:FindFirstChild("Chapter")
        if ch and ch:FindFirstChild(mapName) then return ch[mapName] end
    end
    local any = safeWaitPath(pg, {"PlayRoom","Main","GameStage","Main"}, 0.2)
    if any then
        local found = any:FindFirstChild("Chapter", true)
        if found and found:FindFirstChild(mapName) then return found[mapName] end
    end
    return nil
end
local function selectMapForStage(stage, mapName)
    local sf = getMapScrollForStage(stage)
    if not sf then return false end
    return scrollClickByName(sf, mapName)
end
local function selectChapterForStage(stage, mapName, chapterNum)
    local chapRoot = getChapterRoot(stage, mapName)
    if not chapRoot then return false end
    local container = chapRoot:FindFirstChild(("%s_Chapter1-10"):format(mapName))
    if container then
        local sf = container:FindFirstChildWhichIsA("ScrollingFrame") or container
        local name = ("%s_Chapter%d"):format(mapName, chapterNum)
        if sf:IsA("ScrollingFrame") then
            return scrollClickByName(sf, name)
        else
            local target = container:FindFirstChild(name)
            if target then
                local btn = findFirstClickable(target)
                if btn then clickGuiObject(btn); return true end
            end
        end
        return false
    else
        local directBtn = chapRoot:FindFirstChild(("%s_Chapter%d"):format(mapName, chapterNum))
        if directBtn then
            local parentSF = chapRoot:FindFirstChildWhichIsA("ScrollingFrame") or chapRoot
            return scrollIntoViewAndClick(parentSF, directBtn)
        end
    end
    return false
end

--====================================================
-- Shared Join Helpers: Swarm / Adventure / Expedition
--====================================================
-- Swarm
local function tryOpenSwarmEventMenu()
    local openBtn = safeWaitPath(pg, {"HUD","MenuFrame","RightSide","Swarm Event"}, 3)
    if openBtn and openBtn.Visible then
        local clickObj = openBtn:FindFirstChild("Click") or openBtn
        pcall(function() clickGuiObject(clickObj) end)
        return true
    end
    return false
end
local function tryPressSwarmEventPlay()
    local playBtn = safeWaitPath(pg, {"Swarm Event","Main","Tabs","Play"}, 3)
    if playBtn and playBtn.Visible then
        local clickable = playBtn:FindFirstChild("Click") or playBtn
        pcall(function() clickGuiObject(clickable) end)
        return true
    end
    return false
end

-- Adventure
local function tryOpenAdventureGamemode()
    local adv = pg:FindFirstChild("Adventure Gamemode") or select(1, safeWaitPath(pg, {"Adventure Gamemode"}, 2))
    if adv and adv:IsA("ScreenGui") then
        pcall(function() adv.Enabled = true end)
        return true
    end
    return false
end
local function tryPressAdventurePlay()
    local btn = safeWaitPath(pg, {"Adventure Gamemode","Main","Base","Button","Play"}, 3)
    if not btn then return false end
    local clickObj = findFirstClickable(btn) or btn
    if clickObj then pcall(function() clickGuiObject(clickObj) end) return true end
    return false
end
local function tryPlayroomStart()
    return clickIfExists({"Players", player.Name, "PlayerGui","PlayRoom","Main","Game_Submit","Button","Start"}, 2.0)
end

-- Expedition
local function tryOpenExpeditionMode()
    local exp = pg:FindFirstChild("Expedition Mode") or select(1, safeWaitPath(pg, {"Expedition Mode"}, 2))
    if exp and exp:IsA("ScreenGui") then
        pcall(function() exp.Enabled = true end)
        return true
    end
    return false
end
local function tryPressExpeditionPlay()
    local btn = safeWaitPath(pg, {"Expedition Mode","Main","Base","Button","Play"}, 3)
    if not btn then return false end
    local clickObj = findFirstClickable(btn) or btn
    if clickObj then pcall(function() clickGuiObject(clickObj) end) return true end
    return false
end

--====================================================
-- ===================== EVENT TAB ===================
--====================================================
-- Auto Restart @ 2/2
local AutoGB = Tabs.Event:AddLeftGroupbox("Auto Restart / Vote")
AutoGB:AddToggle("AutoRestartTwoOfTwo", { Text = "Auto Restart at 2/2", Default = false })
AutoGB:AddSlider("RetryDuration", { Text = "Spam Duration (sec)", Default = 10, Min = 3, Max = 30, Rounding = 0 })
AutoGB:AddSlider("RetryInterval", { Text = "Spam Interval (sec)", Default = 0.25, Min = 0.05, Max = 1.0, Rounding = 2 })
AutoGB:AddLabel("Hotkey"):AddKeyPicker("AutoRestartKey", { Default = "F6", Mode = "Toggle", Text = "Toggle Auto Restart", NoUI = false, SyncToggleState = true })
Options.AutoRestartKey:OnClick(function() Toggles.AutoRestartTwoOfTwo:SetValue(not Toggles.AutoRestartTwoOfTwo.Value) end)

local AutoRestartState = { running = false, token = 0 }
local function startAutoRestartWatcher()
    if AutoRestartState.running then return end
    AutoRestartState.running = true
    AutoRestartState.token += 1
    local myToken = AutoRestartState.token
    task.spawn(function()
        local wavesLabel = safeWaitPath(pg, {"HUD","InGame","Main","TOP","List","Waves","Numbers"}, 15)
        while AutoRestartState.running and (myToken == AutoRestartState.token) do
            if wavesLabel and wavesIsTwoOfTwo(wavesLabel) then
                pcall(function() pg.Settings.Enabled = true end)
                task.wait(0.3)
                local restartClick = safeWaitPath(pg, {"Settings","Main","Base","Space","ScrollingFrame","Restart Match","Click"}, 3)
                if restartClick then clickGuiObject(restartClick) end
                spamVote("VoteRetry", Options.RetryDuration.Value, Options.RetryInterval.Value)
                repeat
                    if not (AutoRestartState.running and myToken == AutoRestartState.token) then break end
                    task.wait(0.75)
                until not wavesIsTwoOfTwo(wavesLabel)
            else
                task.wait(0.35)
            end
        end
        if myToken == AutoRestartState.token then AutoRestartState.running = false end
    end)
end
local function stopAutoRestartWatcher() if not AutoRestartState.running then return end AutoRestartState.token += 1 AutoRestartState.running = false end
Toggles.AutoRestartTwoOfTwo:OnChanged(function(v) if v then startAutoRestartWatcher() else stopAutoRestartWatcher() end end)
if Toggles.AutoRestartTwoOfTwo.Value then startAutoRestartWatcher() end

-- Auto Hide Rewards UI
local AutoHideGB = Tabs.Event:AddRightGroupbox("Auto Hide")
AutoHideGB:AddToggle("AutoHideRewards", { Text = "Auto Hide Rewards UI", Default = false })
local AutoHideState = { running = false, token = 0 }
local function startAutoHideWatcher()
    if AutoHideState.running then return end
    AutoHideState.running = true
    AutoHideState.token += 1
    local myToken = AutoHideState.token
    task.spawn(function()
        local RewardsUI = safeWaitPath(pg, {"RewardsUI"}, 10)
        while AutoHideState.running and (myToken == AutoHideState.token) do
            if RewardsUI and RewardsUI.Enabled == true then pcall(function() RewardsUI.Enabled = false end) end
            task.wait(0.5)
        end
        if myToken == AutoHideState.token then AutoHideState.running = false end
    end)
end
local function stopAutoHideWatcher() if not AutoHideState.running then return end AutoHideState.token += 1 AutoHideState.running = false end
Toggles.AutoHideRewards:OnChanged(function(v) if v then startAutoHideWatcher() else stopAutoHideWatcher() end end)
if Toggles.AutoHideRewards.Value then startAutoHideWatcher() end

-- Adventure Votes
local AdvVoteGB = Tabs.Event:AddLeftGroupbox("Adventure Votes")
AdvVoteGB:AddToggle("AutoVoteEndure", { Text = "Auto Vote: Endure", Default = false })
AdvVoteGB:AddToggle("AutoVoteEvade",  { Text = "Auto Vote: Evade",  Default = false })
local _syncVote = false
local function _setVotePair(endureOn, evadeOn)
    if _syncVote then return end
    _syncVote = true
    if Toggles.AutoVoteEndure then Toggles.AutoVoteEndure:SetValue(endureOn) end
    if Toggles.AutoVoteEvade  then Toggles.AutoVoteEvade:SetValue(evadeOn) end
    _syncVote = false
end
Toggles.AutoVoteEndure:OnChanged(function(v) if v then _setVotePair(true, false) end end)
Toggles.AutoVoteEvade:OnChanged(function(v) if v then _setVotePair(false, true) end end)

local AdvVoteState = { running=false, token=0 }
local function startAdvVoteWatcher()
    if AdvVoteState.running then return end
    AdvVoteState.running = true; AdvVoteState.token += 1
    local myToken = AdvVoteState.token
    task.spawn(function()
        while AdvVoteState.running and (myToken == AdvVoteState.token) do
            local prompt = pg:FindFirstChild("AdventureContinuePrompt")
            if prompt and prompt:IsA("ScreenGui") and prompt.Enabled then
                local side = safeWaitPath(prompt, {"Main","LeftSide","Button"}, 1)
                if side then
                    local choose = Toggles.AutoVoteEndure.Value and "Endure" or (Toggles.AutoVoteEvade.Value and "Evade" or nil)
                    if choose and side:FindFirstChild(choose) then
                        local btn = findFirstClickable(side[choose]) or side[choose]
                        if btn then pcall(function() clickGuiObject(btn) end) end
                    end
                end
                task.wait(0.6)
            else
                task.wait(0.2)
            end
        end
        if myToken == AdvVoteState.token then AdvVoteState.running = false end
    end)
end
local function stopAdvVoteWatcher() if not AdvVoteState.running then return end AdvVoteState.token += 1 AdvVoteState.running=false end
local function _refreshAdvVoteWatcher()
    if (Toggles.AutoVoteEndure.Value or Toggles.AutoVoteEvade.Value) then startAdvVoteWatcher() else stopAdvVoteWatcher() end
end
Toggles.AutoVoteEndure:OnChanged(_refreshAdvVoteWatcher)
Toggles.AutoVoteEvade:OnChanged(_refreshAdvVoteWatcher)
_refreshAdvVoteWatcher()

-- Auto Join Modes (Event)
local JoinGB = Tabs.Event:AddRightGroupbox("Auto Join Modes")
JoinGB:AddToggle("EVT_AutoJoinSwarm",      { Text = "Auto Join: Swarm Event",      Default = false })
JoinGB:AddToggle("EVT_AutoJoinAdventure",  { Text = "Auto Join: Adventure Gamemode",Default = false })
JoinGB:AddToggle("EVT_AutoJoinExpedition", { Text = "Auto Join: Expedition Mode",  Default = false })
JoinGB:AddSlider("EVT_JoinCooldown", { Text = "Join Cooldown (sec)", Default = 3, Min = 1, Max = 15, Rounding = 0 })

local EVT_JoinState = {
    swarm = {running=false, token=0, last=0},
    adv   = {running=false, token=0, last=0},
    exp   = {running=false, token=0, last=0},
}
local function startSwarmJoin()
    local s = EVT_JoinState.swarm
    if s.running then return end
    s.running = true; s.token += 1
    local my = s.token
    task.spawn(function()
        while s.running and (my == s.token) do
            local now = os.clock()
            if now - (s.last or 0) >= (Options.EVT_JoinCooldown.Value or 3) then
                local okOpen = tryOpenSwarmEventMenu(); task.wait(0.2)
                local okPlay = tryPressSwarmEventPlay()
                if okOpen or okPlay then s.last = now end
            end
            task.wait(0.4)
        end
        if my == s.token then s.running = false end
    end)
end
local function stopSwarmJoin() local s=EVT_JoinState.swarm; if not s.running then return end s.token+=1; s.running=false end

local function startAdventureJoin()
    local s = EVT_JoinState.adv
    if s.running then return end
    s.running = true; s.token += 1
    local my = s.token
    task.spawn(function()
        while s.running and (my == s.token) do
            local now = os.clock()
            if now - (s.last or 0) >= (Options.EVT_JoinCooldown.Value or 3) then
                local okOpen = tryOpenAdventureGamemode(); task.wait(0.2)
                local okPlay = tryPressAdventurePlay(); task.wait(0.2)
                if okOpen or okPlay then tryPlayroomStart(); s.last = now end
            end
            task.wait(0.4)
        end
        if my == s.token then s.running = false end
    end)
end
local function stopAdventureJoin() local s=EVT_JoinState.adv; if not s.running then return end s.token+=1; s.running=false end

local function startExpeditionJoin()
    local s = EVT_JoinState.exp
    if s.running then return end
    s.running = true; s.token += 1
    local my = s.token
    task.spawn(function()
        while s.running and (my == s.token) do
            local now = os.clock()
            if now - (s.last or 0) >= (Options.EVT_JoinCooldown.Value or 3) then
                local okOpen = tryOpenExpeditionMode(); task.wait(0.5)
                local okPlay = tryPressExpeditionPlay(); task.wait(0.3)
                tryPlayroomStart()
                if okOpen or okPlay then s.last = now end
            end
            task.wait(0.4)
        end
        if my == s.token then s.running = false end
    end)
end
local function stopExpeditionJoin() local s=EVT_JoinState.exp; if not s.running then return end s.token+=1; s.running=false end

Toggles.EVT_AutoJoinSwarm:OnChanged(function(v) if v then startSwarmJoin() else stopSwarmJoin() end end)
Toggles.EVT_AutoJoinAdventure:OnChanged(function(v) if v then startAdventureJoin() else stopAdventureJoin() end end)
Toggles.EVT_AutoJoinExpedition:OnChanged(function(v) if v then startExpeditionJoin() else stopExpeditionJoin() end end)

--====================================================
-- ====================== GAME TAB ===================
--====================================================
-- Voting
local GameGB = Tabs.Game:AddLeftGroupbox("Voting Remotes")
GameGB:AddToggle("AutoRetry", { Text = "Auto Retry", Default = false })
GameGB:AddToggle("AutoNext",  { Text = "Auto Next",  Default = false })
GameGB:AddToggle("AutoVotePlaying", { Text = "Auto Vote Game", Default = false })
GameGB:AddSlider("GameVoteInterval", { Text = "Remote Interval (sec)", Default = 1.0, Min = 0.1, Max = 5.0, Rounding = 2 })

local VoteState = {
    Retry = {running=false, token=0},
    Next  = {running=false, token=0},
    Play  = {running=false, token=0},
}
local function startVoteLoop(which, remoteName)
    local state = VoteState[which]
    if state.running then return end
    state.running = true; state.token += 1
    local myToken = state.token
    task.spawn(function()
        local r = getVoteRemote(remoteName)
        while state.running and (myToken == state.token) do
            if r then pcall(function() r:FireServer() end) end
            task.wait(Options.GameVoteInterval.Value or 1.0)
        end
        if myToken == state.token then state.running = false end
    end)
end
local function stopVoteLoop(which) local s=VoteState[which]; if not s.running then return end s.token+=1; s.running=false end
Toggles.AutoRetry:OnChanged(function(v) if v then startVoteLoop("Retry","VoteRetry") else stopVoteLoop("Retry") end end)
Toggles.AutoNext:OnChanged(function(v) if v then startVoteLoop("Next","VoteNext") else stopVoteLoop("Next") end end)
Toggles.AutoVotePlaying:OnChanged(function(v) if v then startVoteLoop("Play","VotePlaying") else stopVoteLoop("Play") end end)

-- AutoPlay Bool
local GameRight = Tabs.Game:AddRightGroupbox("AutoPlay & Codes")
GameRight:AddToggle("AutoPlayBool", { Text = "AutoPlay", Default = false })
local function setAutoPlayBool(enabled)
    local node = safeWaitPath(ReplicatedStorage, {"Player_Data", player.Name, "Data", "AutoPlay"}, 10)
    if node then setBoolValueSafely(node, enabled) Library:Notify(("AutoPlay set to %s"):format(tostring(enabled)), 3)
    else Library:Notify("AutoPlay path not found.", 3) end
end
Toggles.AutoPlayBool:OnChanged(function() setAutoPlayBool(Toggles.AutoPlayBool.Value) end)

-- Redeem All Codes (0.35s)
local ALL_CODES = {
    "NewGearMode?!","SneakyUpdate!","First6.7Update!","CyclopsSoulMine!","CelestialMageOp67",
    "FairyPatch67","ReallySorry4Delay","FallPart2!?!","Sorry6.5UpdateIsReal!!!","FairyTalePeak!",
    "Sorry4Delay","FollowUpTheInsta!","SorryForPassiveDelay!","FixPatchSJW!","SoloPeakLeveling!",
    "NewRaidAndEvos?!","IgrisIsMetaAgain!!","SorryForAllTheIssues!","PityOnRanger?!","TYFORTHESUPPORT!?",
    "FallEvent?!","SorryForLate!","NewRangerUnit!","NewCode!?","BerserkUpdate?!","NewDivineTrials!",
    "MinstaGroupOnTop!","Weloveroblox!","Shutdown2!","UpgradeInFieldFix!","DBZUpdate!","NewPortals?!",
    "GTBossEvent!!","SorryForDelayz!","LBreset!","SECRETCODE!","RiftMode!","SAOUpd!","Dungeons!",
    "MinorChanges!","EzSoulFrags","CraftingFix!","SmartRejoin","ChainsawUpd!","GraveyardRaid!",
    "StatBoosters!","S3Battlepass!","SuperSuperSorry!","3xALLMODES!!","YOUTUBEBACK!!","TYBW2!",
    "QOL2!","ARXBLEACH!","Srry4Shutdown","SmallFixs","!BrandonTheBest","!FixBossRushShop","!TYBW",
    "!MattLovesARX2","!RaitoLovesARX","QuickFix!!","MoreFixs","Sorry4AutoTraitRoll","Sorry4EvoUnits",
    "SorryDelay!!!","SummerEvent!","2xWeekEnd!","Sorry4Quest","SorryRaids","RAIDS","BizzareUpdate2!",
    "Sorry4Delays","HBDTanny","JoJo Part 1","NewLobby","Instant Trait","CODEISREAL","ragebait",
    "PortalsFix","UPDATE 1.5","THANKYOU4PATIENCE"
}
GameRight:AddButton("Redeem All Codes", function()
    task.spawn(function()
        local remote = safeWaitPath(ReplicatedStorage, {"Remote","Server","Lobby","Code"}, 10)
        if not remote then Library:Notify("Code Remote not found", 3); return end
        local okCount, failCount = 0, 0
        for _, code in ipairs(ALL_CODES) do
            local args = { [1] = code }
            local ok = pcall(function() remote:FireServer(unpack(args)) end)
            if ok then okCount += 1 else failCount += 1 end
            task.wait(0.35)
        end
        Library:Notify(("Redeem Done! OK:%d Fail:%d"):format(okCount, failCount), 4)
    end)
end)

-- ===== Gamepasses & Speed =====
-- helpers
local function getGamepassNode(passName)
    return safeWaitPath(ReplicatedStorage, {"Player_Data", player.Name, "Gamepass", passName}, 8)
end
local function ensureGamepassTrue(passName)
    local node = getGamepassNode(passName)
    if node then setBoolValueSafely(node, true); return true end
    return false
end
local function press3xSpeed()
    -- ชื่อ child "3x" ต้องใช้ FindFirstChild
    local btnParent = safeWaitPath(game, {"Players", player.Name, "PlayerGui","SetSpeed","GameSpeed","framebase","buttons"}, 3)
    if not btnParent then return false end
    local node = btnParent:FindFirstChild("3x") or btnParent:FindFirstChildWhichIsA("TextButton")
    if not node then return false end
    local btn = findFirstClickable(node) or node
    if btn then clickGuiObject(btn); return true end
    return false
end

-- UI
local GamePassGB = Tabs.Game:AddRightGroupbox("Gamepasses & Speed")
GamePassGB:AddToggle("UseAutoTraitReroll", { Text = "Use Auto Trait Reroll", Default = false })
GamePassGB:AddToggle("Use3xGameSpeed",    { Text = "Use 3x Game Speed",    Default = false })
GamePassGB:AddSlider("GamepassEnforceInterval", { Text = "Enforce Interval (sec)", Default = 5, Min = 1, Max = 30, Rounding = 0 })

-- watchers
local GPState = {
    reroll = { running = false, token = 0 },
    speed  = { running = false, token = 0 },
}
local function startRerollWatcher()
    local s = GPState.reroll
    if s.running then return end
    s.running = true; s.token += 1
    local my = s.token
    task.spawn(function()
        while s.running and (my == s.token) do
            ensureGamepassTrue("Auto Trait Reroll")
            task.wait(Options.GamepassEnforceInterval.Value or 5)
        end
        if my == s.token then s.running = false end
    end)
end
local function stopRerollWatcher() local s=GPState.reroll; if not s.running then return end s.token+=1; s.running=false end

local function startSpeedWatcher()
    local s = GPState.speed
    if s.running then return end
    s.running = true; s.token += 1
    local my = s.token
    task.spawn(function()
        while s.running and (my == s.token) do
            -- ถ้าค่าใน ReplicatedStorage เป็น false/fales ให้เปลี่ยนเป็น true เสมอ
            ensureGamepassTrue("3x Game Speed")
            task.wait(0.5) -- ตามสเปค
            press3xSpeed()
            task.wait(Options.GamepassEnforceInterval.Value or 5)
        end
        if my == s.token then s.running = false end
    end)
end
local function stopSpeedWatcher() local s=GPState.speed; if not s.running then return end s.token+=1; s.running=false end

Toggles.UseAutoTraitReroll:OnChanged(function(v) if v then startRerollWatcher() else stopRerollWatcher() end end)
Toggles.Use3xGameSpeed:OnChanged(function(v) if v then startSpeedWatcher() else stopSpeedWatcher() end end)

--====================================================
-- ==================== CREATE ROOM ==================
-- (เฉพาะตั้งค่าห้อง/สร้าง; Auto Join ย้ายไป Event แล้ว)
--====================================================
local CreateCfg = { Stage="Story", Map="OnePiece", Chapter=1, FriendsOnly=false, AutoStart=false, Difficulty="Normal" }
local MAP_LIST = { "Berserk","BizzareRace","ChainsawMan","DBZ2","JojoPart1","Namek","Naruto","OnePiece","OPM","SAO","SoloLeveling","SoulSociety","TokyoGhoul","DemonSlayer" }

local function getAvailableMaps(stage)
    stage = stage or "Story"
    local maps, seen = {}, {}
    for _, m in ipairs(MAP_LIST) do seen[m]=true; table.insert(maps, m) end
    local sf = getMapScrollForStage(stage)
    if sf then
        for _, child in ipairs(sf:GetChildren()) do
            if child.Name and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
                if not seen[child.Name] then seen[child.Name]=true; table.insert(maps, child.Name) end
            end
        end
    end
    table.sort(maps); return maps
end

local CR_Left  = Tabs["Create Room"]:AddLeftGroupbox("Setup")
local CR_Right = Tabs["Create Room"]:AddRightGroupbox("Actions")

CR_Left:AddDropdown("CR_Stage", { Text = "Stage", Values = STAGE_LIST, Default = CreateCfg.Stage })
Options.CR_Stage:OnChanged(function(v) CreateCfg.Stage = v end)

local function refreshMapDropdown()
    local vals = getAvailableMaps(CreateCfg.Stage)
    if Options.CR_Map and Options.CR_Map.SetValues then
        Options.CR_Map:SetValues(vals)
        local exists = false
        for _, n in ipairs(vals) do if n == CreateCfg.Map then exists = true break end end
        if not exists then
            CreateCfg.Map = vals[1] or "OnePiece"
            if Options.CR_Map.SetValue then Options.CR_Map:SetValue(CreateCfg.Map) end
        end
    end
end
local mapValues = getAvailableMaps(CreateCfg.Stage)
CR_Left:AddDropdown("CR_Map", { Text = "Map", Values = mapValues, Default = CreateCfg.Map })
Options.CR_Map:OnChanged(function(v) CreateCfg.Map = v end)
Options.CR_Stage:OnChanged(function() task.defer(refreshMapDropdown) end)

local chapValues = {}; for i=1,10 do chapValues[i]=tostring(i) end
CR_Left:AddDropdown("CR_Chapter", { Text = "Chapter", Values = chapValues, Default = tostring(CreateCfg.Chapter) })
Options.CR_Chapter:OnChanged(function(v) local n=tonumber(v) or 1 if n<1 then n=1 elseif n>10 then n=10 end CreateCfg.Chapter=n end)

CR_Left:AddDropdown("CR_Diff", { Text = "Difficulty", Values = {"Normal","Hard","Nightmare"}, Default = CreateCfg.Difficulty })
Options.CR_Diff:OnChanged(function(v) CreateCfg.Difficulty = v end)

CR_Left:AddToggle("CR_FriendsOnly", { Text = "Friends Only", Default = CreateCfg.FriendsOnly })
Toggles.CR_FriendsOnly:OnChanged(function(v)
    CreateCfg.FriendsOnly = v
    clickIfExists({"Players", player.Name, "PlayerGui","PlayRoom","Main","GameStage","Main","Base","Misc","FriendOnly"}, 2)
end)
CR_Left:AddToggle("CR_AutoStart", { Text = "Auto Start After Create", Default = CreateCfg.AutoStart })
Toggles.CR_AutoStart:OnChanged(function(v) CreateCfg.AutoStart = v end)

local function doOpenCreatePane()
    clickIfExists({"Players", player.Name, "PlayerGui","HUD","MenuFrame","LeftSide","Frame","PlayRoom"}, 3)
    task.wait(0.15)
    clickIfExists({"Players", player.Name, "PlayerGui","PlayRoom","Main","Button","Create"}, 3)
end
local function selectDifficulty(diffName)
    local path = {"Players", player.Name, "PlayerGui","PlayRoom","Main","GameStage","Main","Base","DifficultyButton", diffName}
    local clicked = clickIfExists(path, 2)
    if not clicked then
        local node = safeWaitPath(game, path, 1)
        if node then local btn = findFirstClickable(node); if btn then clickGuiObject(btn); clicked=true end end
    end
    return clicked
end
local function doCreateRoom()
    doOpenCreatePane(); task.wait(0.15)
    selectStageMode(CreateCfg.Stage);                       task.wait(0.12)
    selectMapForStage(CreateCfg.Stage, CreateCfg.Map);      task.wait(0.12)
    selectChapterForStage(CreateCfg.Stage, CreateCfg.Map, CreateCfg.Chapter); task.wait(0.10)
    selectDifficulty(CreateCfg.Difficulty);                 task.wait(0.06)
    if CreateCfg.FriendsOnly then
        clickIfExists({"Players", player.Name, "PlayerGui","PlayRoom","Main","GameStage","Main","Base","Misc","FriendOnly"}, 1.0)
        task.wait(0.05)
    end
    clickIfExists({"Players", player.Name, "PlayerGui","PlayRoom","Main","GameStage","Main","Base","Button","Create"}, 2.5)
    if CreateCfg.AutoStart then
        task.wait(0.35)
        local okStart = clickIfExists({"Players", player.Name, "PlayerGui","PlayRoom","Main","Game_Submit","Button","Start"}, 2.0)
        if not okStart then Library:Notify("Start button not found (กดเองได้)", 3) end
    end
end
CR_Right:AddButton("Open PlayRoom (Create)", function() doOpenCreatePane() end)
CR_Right:AddButton("Create Room Now", function() task.spawn(doCreateRoom) end)

--====================================================
-- UI Settings / Themes / Saves
--====================================================
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
MenuGroup:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(v) Library.KeybindFrame.Visible = v end })
MenuGroup:AddToggle("ShowCustomCursor", { Text = "Custom Cursor", Default = true, Callback = function(v) Library.ShowCustomCursor = v end })
MenuGroup:AddDropdown("NotificationSide", { Values = { "Left", "Right" }, Default = "Right", Text = "Notification Side", Callback = function(v) Library:SetNotifySide(v) end })
MenuGroup:AddDropdown("DPIDropdown", { Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" }, Default = "100%", Text = "DPI Scale",
    Callback = function(v) local n = tonumber(v:gsub("%%","")); if n then Library:SetDPIScale(n) end end })
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")
SaveManager:SetSubFolder("specific-place")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

Library:OnUnload(function() print("[UI] Unloaded.") end)
