-- Gui to Lua
-- Version: 3.2

-- Instances:

local ScreenGui = Instance.new("ScreenGui")
local OpenUI = Instance.new("ImageButton")
local Frame = Instance.new("Frame")
local ClosUI = Instance.new("TextButton")
local TextLabel = Instance.new("TextLabel")
local FrameManu = Instance.new("Frame")
local script1 = Instance.new("TextButton")
local script3 = Instance.new("TextButton")
local script2 = Instance.new("TextButton")

--Properties:

ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

OpenUI.Name = "OpenUI"
OpenUI.Parent = ScreenGui
OpenUI.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
OpenUI.BorderColor3 = Color3.fromRGB(0, 0, 0)
OpenUI.BorderSizePixel = 0
OpenUI.Position = UDim2.new(0.53715837, 0, 0.0438388996, 0)
OpenUI.Size = UDim2.new(0, 65, 0, 54)
OpenUI.Image = "rbxassetid://129743983667514"

Frame.Parent = OpenUI
Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Frame.BackgroundTransparency = 0.350
Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame.BorderSizePixel = 0
Frame.Position = UDim2.new(-3.23022842, 0, 4.64814758, 0)
Frame.Size = UDim2.new(0, 441, 0, 363)
Frame.Visible = false

ClosUI.Name = "ClosUI "
ClosUI.Parent = Frame
ClosUI.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ClosUI.BackgroundTransparency = 1.000
ClosUI.BorderColor3 = Color3.fromRGB(0, 0, 0)
ClosUI.BorderSizePixel = 0
ClosUI.Position = UDim2.new(0.746031761, 0, 0, 0)
ClosUI.Size = UDim2.new(0, 112, 0, 39)
ClosUI.Font = Enum.Font.Bangers
ClosUI.Text = "-"
ClosUI.TextColor3 = Color3.fromRGB(0, 0, 0)
ClosUI.TextSize = 25.000

TextLabel.Name = "หัว"
TextLabel.Parent = Frame
TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.BackgroundTransparency = 1.000
TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextLabel.BorderSizePixel = 0
TextLabel.Size = UDim2.new(0, 329, 0, 39)
TextLabel.Font = Enum.Font.Highway
TextLabel.Text = "Hack Hub 👑"
TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
TextLabel.TextSize = 20.000

FrameManu.Name = "Frame Manu"
FrameManu.Parent = Frame
FrameManu.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FrameManu.BackgroundTransparency = 0.800
FrameManu.BorderColor3 = Color3.fromRGB(0, 0, 0)
FrameManu.BorderSizePixel = 0
FrameManu.Position = UDim2.new(-1.38401717e-07, 0, 0.12672177, 0)
FrameManu.Size = UDim2.new(0, 441, 0, 316)

script1.Name = "script 1"
script1.Parent = FrameManu
script1.BackgroundColor3 = Color3.fromRGB(170, 255, 127)
script1.BackgroundTransparency = 0.850
script1.BorderColor3 = Color3.fromRGB(0, 0, 0)
script1.BorderSizePixel = 0
script1.Position = UDim2.new(2.76803434e-07, 0, 0.0284810122, 0)
script1.Size = UDim2.new(0, 439, 0, 39)
script1.Font = Enum.Font.SourceSans
script1.Text = "Simple Spy"
script1.TextColor3 = Color3.fromRGB(0, 0, 0)
script1.TextSize = 14.000
script1.MouseButton1Click:Connect(function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpySource.lua"))()
end)

script3.Name = "script 3"
script3.Parent = FrameManu
script3.BackgroundColor3 = Color3.fromRGB(170, 255, 127)
script3.BackgroundTransparency = 0.850
script3.BorderColor3 = Color3.fromRGB(0, 0, 0)
script3.BorderSizePixel = 0
script3.Position = UDim2.new(0.00226757373, 0, 0.436708868, 0)
script3.Size = UDim2.new(0, 440, 0, 39)
script3.Font = Enum.Font.SourceSans
script3.Text = "Infinite Yield"
script3.TextColor3 = Color3.fromRGB(0, 0, 0)
script3.TextSize = 14.000
script3.MouseButton1Click:Connect(function()
	loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end)

script2.Name = "script 2"
script2.Parent = FrameManu
script2.BackgroundColor3 = Color3.fromRGB(170, 255, 127)
script2.BackgroundTransparency = 0.850
script2.BorderColor3 = Color3.fromRGB(0, 0, 0)
script2.BorderSizePixel = 0
script2.Position = UDim2.new(0, 0, 0.237341776, 0)
script2.Size = UDim2.new(0, 440, 0, 39)
script2.Font = Enum.Font.SourceSans
script2.Text = "Dex Explorer"
script2.TextColor3 = Color3.fromRGB(0, 0, 0)
script2.TextSize = 14.000
script2.MouseButton1Click:Connect(function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/MITUMAxDev/Tools/refs/heads/main/Dex-Explorer.lua"))()
end)
-- Scripts:

local function YVJDXV_fake_script() -- ClosUI.Script 
	local script = Instance.new('Script', ClosUI)

	function ClosUi  ()
		script.Parent.Parent.Parent.Frame.Visible = false
	end
	
	script.Parent.MouseButton1Click:Connect(ClosUi)
end
coroutine.wrap(YVJDXV_fake_script)()
local function BVSTJZC_fake_script() -- Frame.เลื่อน farm 
	local script = Instance.new('LocalScript', Frame)

	local UserInputService = game:GetService("UserInputService")
	
	local frame = script.Parent
	local dragging
	local dragStart
	local startPos
	
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
	
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	frame.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	
end
coroutine.wrap(BVSTJZC_fake_script)()
local function NDJOIH_fake_script() -- OpenUI.Script 
	local script = Instance.new('Script', OpenUI)

	function OpenUi  ()
		script.Parent.Frame.Visible = true 
	end
	
	script.Parent.MouseButton1Click:Connect(OpenUi)
end
coroutine.wrap(NDJOIH_fake_script)()
local function USVEZTV_fake_script() -- OpenUI.LocalScript 
	local script = Instance.new('LocalScript', OpenUI)

	local UserInputService = game:GetService("UserInputService")
	local button = script.Parent
	
	local dragging
	local dragStart
	local startPos
	
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = button.Position
	
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	button.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	
end
coroutine.wrap(USVEZTV_fake_script)()