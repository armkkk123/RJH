-- ICON: https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json -

local Twen = game:GetService('TweenService');
local Input = game:GetService('UserInputService');
local TextServ = game:GetService('TextService');
local LocalPlayer = game:GetService('Players').LocalPlayer;
local CoreGui = (gethui and gethui()) or game:FindFirstChild('CoreGui') or LocalPlayer.PlayerGui;
local Icons = (function()
	local p,c = pcall(function()
		local Http = game:HttpGetAsync('https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json');

		local Decode = game:GetService('HttpService'):JSONDecode(Http);

		return Decode['icon'];
	end);

	if p then return c end;

	return nil;
end)() or {};

local ElBlurSource = function()
	local GuiSystem = {}
	local RunService = game:GetService('RunService');
	local CurrentCamera = workspace.CurrentCamera or workspace:FindFirstChildOfClass('Camera'); -- [FIX] nil safety

	function GuiSystem:Hash()
		return string.reverse(string.gsub(game:GetService('HttpService'):GenerateGUID(false),'..',function(aa)
			return string.reverse(aa)
		end))
	end

	local function Hiter(planePos, planeNormal, rayOrigin, rayDirection)
		local n = planeNormal
		local d = rayDirection
		local v = rayOrigin - planePos

		local num = (n.x*v.x) + (n.y*v.y) + (n.z*v.z)
		local den = (n.x*d.x) + (n.y*d.y) + (n.z*d.z)
		if math.abs(den) < 1e-10 then -- [FIX] Division by zero guard
			return rayOrigin, 0;
		end
		local a = -num / den

		return rayOrigin + (a * rayDirection), a;
	end;

	function GuiSystem.new(frame,NoAutoBackground)
		local Part = Instance.new('Part',workspace);
		local DepthOfField = Instance.new('DepthOfFieldEffect',game:GetService('Lighting'));
		local SurfaceGui = Instance.new('SurfaceGui',Part);
		local BlockMesh = Instance.new("BlockMesh");

		BlockMesh.Parent = Part;

		Part.Material = Enum.Material.Glass;
		Part.Transparency = 1;
		Part.Reflectance = 1;
		Part.CastShadow = false;
		Part.Anchored = true;
		Part.CanCollide = false;
		Part.CanQuery = false;
		Part.CollisionGroup = GuiSystem:Hash();
		Part.Size = Vector3.new(1, 1, 1) * 0.01;
		Part.Color = Color3.fromRGB(0,0,0);

		Twen:Create(Part,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{
			Transparency = 0.8;
		}):Play()

		DepthOfField.Enabled = true;
		DepthOfField.FarIntensity = 1;
		DepthOfField.FocusDistance = 0;
		DepthOfField.InFocusRadius = 500;
		DepthOfField.NearIntensity = 1;

		SurfaceGui.AlwaysOnTop = true;
		SurfaceGui.Adornee = Part;
		SurfaceGui.Active = true;
		SurfaceGui.Face = Enum.NormalId.Front;
		SurfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;

		DepthOfField.Name = GuiSystem:Hash();
		Part.Name = GuiSystem:Hash();
		SurfaceGui.Name = GuiSystem:Hash();

		local C4 = {
			Update = nil,
			Collection = SurfaceGui,
			Enabled = true,
			Instances = {
				BlockMesh = BlockMesh,
				Part = Part,
				DepthOfField = DepthOfField,
				SurfaceGui = SurfaceGui,
			},
			Signal = nil
		};

		local Update = function()
			-- [FIX] Guard: ถ้า camera หรือ frame ถูกทำลาย ให้หยุดทำงาน
			if not CurrentCamera or not CurrentCamera.Parent then
				CurrentCamera = workspace.CurrentCamera or workspace:FindFirstChildOfClass('Camera')
				if not CurrentCamera then return end
			end
			if not frame or not frame.Parent then return end

			if not C4.Enabled then
				pcall(function() Twen:Create(Part,TweenInfo.new(1,Enum.EasingStyle.Quint),{
					Transparency = 1;
				}):Play() end)

			end;

			pcall(function() Twen:Create(Part,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{
				Transparency = 0.8;
			}):Play() end)

			local corner0 = frame.AbsolutePosition;
			local corner1 = corner0 + frame.AbsoluteSize;

			local ray0 = CurrentCamera.ScreenPointToRay(CurrentCamera,corner0.X, corner0.Y, 1);
			local ray1 = CurrentCamera.ScreenPointToRay(CurrentCamera,corner1.X, corner1.Y, 1);

			local planeOrigin = CurrentCamera.CFrame.Position + CurrentCamera.CFrame.LookVector * (0.05 - CurrentCamera.NearPlaneZ);

			local planeNormal = CurrentCamera.CFrame.LookVector;

			local pos0 = Hiter(planeOrigin, planeNormal, ray0.Origin, ray0.Direction);
			local pos1 = Hiter(planeOrigin, planeNormal, ray1.Origin, ray1.Direction);

			pos0 = CurrentCamera.CFrame:PointToObjectSpace(pos0);
			pos1 = CurrentCamera.CFrame:PointToObjectSpace(pos1);

			local size   = pos1 - pos0;
			local center = (pos0 + pos1) / 2;

			BlockMesh.Offset = center
			BlockMesh.Scale  = size / 0.0101;
			Part.CFrame = CurrentCamera.CFrame;

			if not NoAutoBackground then

				local _,updatec = pcall(function()
					local userSettings = UserSettings():GetService("UserGameSettings")
					local qualityLevel = userSettings.SavedQualityLevel.Value

					if qualityLevel < 8 then
						Twen:Create(frame,TweenInfo.new(1),{
							BackgroundTransparency = 0
						}):Play()
					else
						Twen:Create(frame,TweenInfo.new(1),{
							BackgroundTransparency = 0.4
						}):Play()
					end;
				end)

			end
		end

		C4.Update = Update;
		C4.Signal = RunService.RenderStepped:Connect(Update);

		pcall(function()
			C4.Signal2 = CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(function()
				Part.CFrame = CurrentCamera.CFrame;
			end);
		end)

		C4.Destroy = function()
			pcall(function() C4.Signal:Disconnect() end); -- [FIX] Safe disconnect
			pcall(function() C4.Signal2:Disconnect() end); -- [FIX] Signal2 อาจไม่มีถ้า pcall ตอนสร้าง fail
			C4.Update = function()

			end;

			pcall(function() Twen:Create(Part,TweenInfo.new(1),{
				Transparency = 1
			}):Play() end); -- [FIX] Part อาจถูก Destroy ไปแล้ว

			pcall(function() DepthOfField:Destroy() end);
			pcall(function() Part:Destroy() end)
		end;

		return C4;
	end;

	return GuiSystem
end;

local ElBlurSource = ElBlurSource();
local Config = function(data,default)
	data = data or {};

	for i,v in next,default do
		data[i] = data[i] or v;
	end;

	return data;
end;

local Library = {};

Library['.'] = '1';
Library['FetchIcon'] = "https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json";

pcall(function()
	Library['Icons'] = game:GetService('HttpService'):JSONDecode(game:HttpGetAsync(Library.FetchIcon))['icons'];
end)

function Library.GradientImage(E, Color)
	local GLImage = Instance.new("ImageLabel")
	local upd = tick();
	local nextU , Speed , speedy , SIZ = 4 , 5 , -5 , 0.8;
	local nextmain = UDim2.new();
	local rng = Random.new(math.random(10,100000) + math.random(100, 1000) + math.sqrt(tick()));
	local int = 1;
	local TPL = 0.55;

	GLImage.Name = "GLImage"
	GLImage.Parent = E
	GLImage.AnchorPoint = Vector2.new(0.5, 0.5)
	GLImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	GLImage.BackgroundTransparency = 1.000
	GLImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	GLImage.BorderSizePixel = 0
	GLImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	GLImage.Size = UDim2.new(0.800000012, 0, 0.800000012, 0)
	GLImage.SizeConstraint = Enum.SizeConstraint.RelativeYY
	GLImage.ZIndex = E.ZIndex - 1;
	GLImage.Image = "rbxassetid://867619398"
	GLImage.ImageColor3 = Color or Color3.fromRGB(0, 195, 255)
	GLImage.ImageTransparency = 1;

	local str = 'GL_EFFECT_'..tostring(tick());
	game:GetService('RunService'):BindToRenderStep(str,45,function()
		-- [FIX] Guard: ถ้า parent ถูกทำลาย ให้ยกเลิก RenderStep นี้เพื่อป้องกัน Memory Leak
		if not GLImage or not GLImage.Parent then
			pcall(function() game:GetService('RunService'):UnbindFromRenderStep(str) end)
			return
		end

		if (tick() - upd) > nextU then
			nextU = rng:NextNumber(1.1,2.5)
			Speed = rng:NextNumber(-6,6)
			speedy = rng:NextNumber(-6,6)
			TPL = rng:NextNumber(0.2,0.8)
			SIZ = rng:NextNumber(0.6,0.9);
			upd = tick();
			int = 1
		else
			speedy = speedy + rng:NextNumber(-0.1,0.1);
			Speed = Speed + rng:NextNumber(-0.1,0.1);

		end;

		nextmain = nextmain:Lerp(UDim2.new(0.5 + (Speed / 24),0,0.5 + (speedy / 24),0) , .025)
		int = int + 0.1

		pcall(function() Twen:Create(GLImage,TweenInfo.new(1),{
			Rotation = GLImage.Rotation + Speed,
			Position = nextmain,
			Size = UDim2.fromScale(SIZ,SIZ),
			ImageTransparency = TPL
		}):Play() end)
	end)

	return str
end;

local Theme = {
	GRID = 8,
	Padding = {
		Small  = UDim.new(0, 8),
		Medium = UDim.new(0, 12),
		Large  = UDim.new(0, 16),
	},
	Colors = {
		Background = Color3.fromRGB(20,20,20),
		Accent     = Color3.fromRGB(255,125,0),
		Text       = Color3.new(1,1,1),
		Stroke     = Color3.fromRGB(100,100,100),
	},
	Transparency = {
		Panel = 0.4,
		Header = 0.5,
		Button = 0.75,
	},
	Fonts = {
		Title   = Enum.Font.GothamBold,
		Body    = Enum.Font.Gotham,
		Mono    = Enum.Font.Code,
	}
}

local function gridScale(value) return math.floor(value / Theme.GRID) * Theme.GRID end

function Library.new(config)
	local isMobile = game:GetService("UserInputService").TouchEnabled and not game:GetService("UserInputService").KeyboardEnabled
	local camera = workspace.CurrentCamera
	local defaultSize = UDim2.new(0, 580, 0, 600)

	if isMobile and camera then
		defaultSize = UDim2.new(0, gridScale(camera.ViewportSize.X * 0.86), 0, gridScale(camera.ViewportSize.Y * 0.86))
	end

	config = Config(config,{
		Title = "UI Library",
		Description = "discord.gg/BH6pE7jesa",
		Keybind = Enum.KeyCode.LeftControl,
		Logo = "rbxassetid://108548419189473",
		Size = defaultSize
	});

	-- Convert user config size to grid scale
	config.Size = UDim2.new(0, gridScale(config.Size.X.Offset), 0, gridScale(config.Size.Y.Offset))

	local TweenInfo1 = TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut);
	local TweenInfo2 = TweenInfo.new(0.7,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut);

	local WindowTable = {};
	local ScreenGui = Instance.new("ScreenGui")
	local MainFrame = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local MainDropShadow = Instance.new("ImageLabel")
	local Headers = Instance.new("Frame")
	local Logo = Instance.new("ImageLabel")
	local UICorner_2 = Instance.new("UICorner")
	local Title = Instance.new("TextLabel")
	local UIGradient = Instance.new("UIGradient")
	local Description = Instance.new("TextLabel")
	local UIGradient_2 = Instance.new("UIGradient")
	local BlockFrame1 = Instance.new("Frame")
	local UICorner_3 = Instance.new("UICorner")
	local UIGradient_3 = Instance.new("UIGradient")
	local BlockFrame3 = Instance.new("Frame")
	local UICorner_4 = Instance.new("UICorner")
	local UIGradient_4 = Instance.new("UIGradient")
	local BlockFrame2 = Instance.new("Frame")
	local UICorner_5 = Instance.new("UICorner")
	local UIGradient_5 = Instance.new("UIGradient")
	local TabButtonFrame = Instance.new("Frame")
	local UICorner_6 = Instance.new("UICorner")
	local TabButtons = Instance.new("ScrollingFrame")
	local UIListLayout = Instance.new("UIListLayout")
	local MainTabFrame = Instance.new("Frame")
	local UICorner_7 = Instance.new("UICorner")
	local InputFrame = Instance.new("Frame")

	WindowTable.Tabs = {};
	WindowTable.Dropdown = {};
	WindowTable.WindowToggle = true;
	WindowTable.SavedIconPosition = UDim2.new(0.15, 0, 0.15, 0);
	WindowTable.Keybind = config.Keybind;
	WindowTable.ToggleButton = nil

	-- Drag Logic for MainFrame and other elements
	local dragging = false
	local dragInput
	local dragStart
	local startPos
	local isDraggingUI = false

	local function hookDrag(element)
		element.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				-- Prevent dragging the whole UI when interacting with inner components (sliders, etc)
				if WindowTable.WindowToggle and element == MainFrame then
					local relY = (input.Position.Y - MainFrame.AbsolutePosition.Y) / MainFrame.AbsoluteSize.Y
					if relY > 0.15 then return end -- Ignore drag if clicked below the top 15% header area
				end

				dragging = true
				isDraggingUI = false
				dragStart = input.Position
				startPos = MainFrame.Position

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)

		element.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
				if dragging and (input.Position - dragStart).Magnitude > 5 then
					isDraggingUI = true
				end
			end
		end)
	end

	hookDrag(MainFrame)

	local function updateDrag(input)
		local delta = input.Position - dragStart
		local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		MainFrame.Position = newPos
		if not WindowTable.WindowToggle then
			WindowTable.SavedIconPosition = newPos
		end
	end

	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			updateDrag(input)
		end
	end)

	local ImageButton = Instance.new("ImageButton")

	ImageButton.Parent = MainFrame
	ImageButton.AnchorPoint = Vector2.new(1, 0)
	ImageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ImageButton.BackgroundTransparency = 1.000
	ImageButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ImageButton.BorderSizePixel = 0
	ImageButton.Position = UDim2.new(1, -60, 0.01, 0) -- ขยับปุ่มย่อไปซ้าย
	ImageButton.Size = UDim2.new(0.0850000009, 0, 0.0850000009, 0)
	ImageButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
	ImageButton.ZIndex = 50
	ImageButton.Image = "rbxassetid://10734953073" -- ไอคอนลูกศรหดลงแบบไร้พื้นหลัง 100%
	ImageButton.ImageTransparency = 1

	local HomeIcon = Instance.new("ImageLabel")
	HomeIcon.Parent = ImageButton
	HomeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	HomeIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	HomeIcon.BorderColor3 = Color3.fromRGB(0, 0, 0)
	HomeIcon.BorderSizePixel = 0
	HomeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	HomeIcon.Size = UDim2.new(0.7,0,0.7,0)
	HomeIcon.ZIndex = 49
	HomeIcon.Image = "rbxassetid://7733993211"
	HomeIcon.ScaleType = Enum.ScaleType.Fit
	HomeIcon.ImageTransparency = 1;
	HomeIcon.BackgroundTransparency = 1;

	local CloseBtn = Instance.new("ImageButton")
	CloseBtn.Parent = MainFrame
	CloseBtn.AnchorPoint = Vector2.new(1, 0)
	CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	CloseBtn.BackgroundTransparency = 1.000
	CloseBtn.BorderSizePixel = 0
	-- วางปุ่มปิดไว้ขวาสุดริมสุด
	CloseBtn.Position = UDim2.new(1, -15, 0.01, 0)
	CloseBtn.Size = UDim2.new(0.085, 0, 0.085, 0)
	CloseBtn.SizeConstraint = Enum.SizeConstraint.RelativeYY
	CloseBtn.ZIndex = 50
	CloseBtn.Image = "rbxassetid://10002398990" -- ไอคอนกากบาท X ของเดิม
	CloseBtn.ImageColor3 = Color3.fromRGB(240, 50, 50) -- สีแดงให้โดดเด่นว่าเป็นปุ่มปิด
	CloseBtn.ImageTransparency = 0.3

	CloseBtn.MouseButton1Click:Connect(function()
		if WindowTable.ElBlurUI and WindowTable.ElBlurUI.Destroy then
			pcall(function() WindowTable.ElBlurUI.Destroy() end)
		end
		ScreenGui:Destroy()
	end)

	local function Update()
		if WindowTable.WindowToggle then
			MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
			MainFrame.BackgroundTransparency = 0.4
			MainFrame.Size = config.Size

			MainDropShadow.ImageTransparency = 0.6
			WindowTable.ElBlurUI.Enabled = true

			BlockFrame1.BackgroundTransparency = 1
			BlockFrame2.BackgroundTransparency = 0.5
			BlockFrame3.BackgroundTransparency = 1

			Title.Position = UDim2.new(0, 175, 0, 12)
			Title.AnchorPoint = Vector2.new(0, 0)
			Title.TextXAlignment = Enum.TextXAlignment.Left
			Title.Visible = true
			if MainFrame:FindFirstChild("ProfileFrame") then MainFrame.ProfileFrame.Visible = true end

			Description.Position = UDim2.new(0, 175, 0, 36)
			Description.AnchorPoint = Vector2.new(0, 0)
			Description.TextXAlignment = Enum.TextXAlignment.Left
			Description.Visible = true

			TabButtonFrame.Position = UDim2.new(0.5, 0, 0, 80)
			TabButtonFrame.Size = UDim2.new(0.92, 0, 0, 32)
			TabButtonFrame.AnchorPoint = Vector2.new(0.5, 0)
			TabButtonFrame.Visible = true

			MainTabFrame.Position = UDim2.new(0.5, 0, 0, 120)
			MainTabFrame.Size = UDim2.new(1, -16, 1, -135)
			MainTabFrame.AnchorPoint = Vector2.new(0.5, 0)
			MainTabFrame.Visible = true

			ImageButton.Position = UDim2.new(1, -60, 0.01, 0)
			ImageButton.Size = UDim2.new(0.085, 0, 0.085, 0)
			ImageButton.ImageTransparency = 0.5
			ImageButton.AnchorPoint = Vector2.new(1, 0)
			ImageButton.Image = "rbxassetid://10734953073"

			HomeIcon.ImageTransparency = 1

			CloseBtn.ImageTransparency = 0.3
			CloseBtn.Position = UDim2.new(1, -15, 0.01, 0)
			CloseBtn.Visible = true

			UICorner.CornerRadius = UDim.new(0, 7)

		else
			WindowTable.ElBlurUI.Enabled = false
			pcall(function() WindowTable.ElBlurUI.Update() end)

			MainFrame.Position = WindowTable.SavedIconPosition
			MainFrame.BackgroundTransparency = 1
			MainFrame.Size = UDim2.new(0, 50, 0, 50)

			MainDropShadow.ImageTransparency = 1

			-- Hide inner frames instantly to prevent overlapping in minimized state
			TabButtonFrame.Visible = false
			MainTabFrame.Visible = false
			Description.Visible = false
			Title.Visible = false
			if MainFrame:FindFirstChild("ProfileFrame") then MainFrame.ProfileFrame.Visible = false end
			BlockFrame1.BackgroundTransparency = 1
			BlockFrame2.BackgroundTransparency = 1
			BlockFrame3.BackgroundTransparency = 1

			UICorner.CornerRadius = UDim.new(1, 0)

			ImageButton.Image = "rbxassetid://100436300703369"
			ImageButton.Position = UDim2.new(0.5, 0, 0.5, 0)
			ImageButton.Size = UDim2.new(1.3, 0, 1.3, 0)
			ImageButton.ImageTransparency = 0
			ImageButton.AnchorPoint = Vector2.new(0.5, 0.5)

			CloseBtn.ImageTransparency = 1
			CloseBtn.Visible = false

			HomeIcon.ImageTransparency = 1
		end

		WindowTable.Dropdown:Close()
		if WindowTable.ToggleButton then
			WindowTable.ToggleButton();
		end;

		task.delay(1,WindowTable.ElBlurUI.Update)
	end;

	Twen:Create(ImageButton,TweenInfo1,{
		ImageTransparency = 0.5
	}):Play()

	hookDrag(ImageButton)

	ImageButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if not isDraggingUI then
				WindowTable.WindowToggle = not WindowTable.WindowToggle
				Update()
			end
		end
	end)

	Input.InputBegan:Connect(function(io)
		if io.KeyCode == WindowTable.Keybind then
			WindowTable.WindowToggle = not WindowTable.WindowToggle
			Update()
		end
	end)

	ScreenGui.Parent = CoreGui;
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
	ScreenGui.ResetOnSpawn = false;
	ScreenGui.IgnoreGuiInset = true;
	ScreenGui.Name = "RobloxGameGui";

	-- ============================================================
	-- [[ 🎬 RUAJAD HUB — CINEMATIC LOADING SEQUENCE ]]
	-- ============================================================
	local LoadingDone = false
	local LoadScreen = Instance.new("Frame")
	LoadScreen.Name = "LoadScreen"
	LoadScreen.Parent = ScreenGui
	LoadScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	LoadScreen.BackgroundTransparency = 0
	LoadScreen.Size = UDim2.new(1, 0, 1, 0)
	LoadScreen.ZIndex = 500
	LoadScreen.ClipsDescendants = true

	-- ▂▂▂ CINEMATIC LETTERBOX BARS ▂▂▂
	local TopBar = Instance.new("Frame")
	TopBar.Parent = LoadScreen
	TopBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	TopBar.Size = UDim2.new(1, 0, 0.12, 0)
	TopBar.Position = UDim2.new(0, 0, -0.12, 0)
	TopBar.ZIndex = 520
	TopBar.BorderSizePixel = 0

	local BottomBar = Instance.new("Frame")
	BottomBar.Parent = LoadScreen
	BottomBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	BottomBar.Size = UDim2.new(1, 0, 0.12, 0)
	BottomBar.Position = UDim2.new(0, 0, 1, 0)
	BottomBar.ZIndex = 520
	BottomBar.BorderSizePixel = 0

	-- ▂▂▂ BACKGROUND GRADIENT ▂▂▂
	local BgGrad = Instance.new("UIGradient")
	BgGrad.Parent = LoadScreen
	BgGrad.Rotation = 135
	BgGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 0, 18)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(4, 2, 8)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
	})

	-- ▂▂▂ SCAN LINES ▂▂▂
	local ScanLines = Instance.new("Frame")
	ScanLines.Parent = LoadScreen
	ScanLines.BackgroundTransparency = 1
	ScanLines.Size = UDim2.new(1, 0, 1, 0)
	ScanLines.ZIndex = 510
	for i = 0, 60 do
		local line = Instance.new("Frame")
		line.Parent = ScanLines
		line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		line.BackgroundTransparency = 0.96
		line.BorderSizePixel = 0
		line.Size = UDim2.new(1, 0, 0, 1)
		line.Position = UDim2.new(0, 0, 0, i * 12)
		line.ZIndex = 510
	end

	-- ▂▂▂ PIXAR TEXT: RUAJADHUB (3-Wave Premium Animation) ▂▂▂
	local PixarTextContainer = Instance.new("Frame")
	PixarTextContainer.Parent = LoadScreen
	PixarTextContainer.BackgroundTransparency = 1
	PixarTextContainer.Size = UDim2.new(1, 0, 1, 0)
	PixarTextContainer.ZIndex = 535

	local fullWord = "RUAJADHUB"
	local letterW = 46
	local letterH = 80
	local totalW = #fullWord * letterW
	local originX = -totalW / 2

	-- Wave groups: "left" = from left, "right" = from right, "drop" = from top
	local waveMap = {
		[1] = "left",  -- R
		[2] = "left",  -- U
		[3] = "left",  -- A
		[4] = "drop_tl", -- J (top-left corner)
		[5] = "drop_tc", -- A (top-center)
		[6] = "drop_tr", -- D (top-right corner)
		[7] = "right", -- H
		[8] = "right", -- U
		[9] = "right", -- B
	}

	local Letters = {}
	for i = 1, #fullWord do
		local ch = fullWord:sub(i, i)
		local wave = waveMap[i]
		local finalXOff = originX + (i - 1) * letterW + letterW / 2

		local lbl = Instance.new("TextLabel")
		lbl.Name = "Letter_" .. ch .. i
		lbl.Parent = PixarTextContainer
		lbl.AnchorPoint = Vector2.new(0.5, 0.5)
		lbl.Size = UDim2.new(0, letterW, 0, letterH)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBlack
		lbl.Text = ch
		lbl.TextScaled = true
		lbl.ZIndex = 536
		lbl.TextTransparency = 1

		if wave == "left" then
			lbl.Position = UDim2.new(0.5, finalXOff - 700, 0.5, math.random(-15, 15))
			lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			lbl.Rotation = math.random(-35, -15)
		elseif wave == "right" then
			lbl.Position = UDim2.new(0.5, finalXOff + 700, 0.5, math.random(-15, 15))
			lbl.TextColor3 = Color3.fromHex("#c542cb")
			lbl.Rotation = math.random(15, 35)
		elseif wave == "drop_tl" then
			lbl.Position = UDim2.new(0.15, 0, -0.15, 0)
			lbl.TextColor3 = Color3.fromHex("#e06fff")
			lbl.Rotation = -45
		elseif wave == "drop_tc" then
			lbl.Position = UDim2.new(0.5, 0, -0.2, 0)
			lbl.TextColor3 = Color3.fromHex("#f985ff")
			lbl.Rotation = 0
		elseif wave == "drop_tr" then
			lbl.Position = UDim2.new(0.85, 0, -0.15, 0)
			lbl.TextColor3 = Color3.fromHex("#e06fff")
			lbl.Rotation = 45
		end

		Letters[i] = { label = lbl, finalX = finalXOff, wave = wave }
	end

	local GlowBehind = Instance.new("ImageLabel")
	GlowBehind.Parent = PixarTextContainer
	GlowBehind.AnchorPoint = Vector2.new(0.5, 0.5)
	GlowBehind.Position = UDim2.new(0.5, 0, 0.5, 0)
	GlowBehind.Size = UDim2.new(0, 0, 0, 0)
	GlowBehind.BackgroundTransparency = 1
	GlowBehind.Image = "rbxassetid://6015897843"
	GlowBehind.ImageColor3 = Color3.fromHex("#ff6bff")
	GlowBehind.ImageTransparency = 1
	GlowBehind.ZIndex = 534

	-- ▂▂▂ WHITE FLASH ▂▂▂
	local WhiteFlash = Instance.new("Frame")
	WhiteFlash.Parent = LoadScreen
	WhiteFlash.BackgroundColor3 = Color3.new(1, 1, 1)
	WhiteFlash.BackgroundTransparency = 1
	WhiteFlash.Size = UDim2.new(1, 0, 1, 0)
	WhiteFlash.ZIndex = 530

	-- ▂▂▂ GLITCH BAR ▂▂▂
	local GlitchBar = Instance.new("Frame")
	GlitchBar.Parent = LoadScreen
	GlitchBar.BackgroundColor3 = Color3.fromHex("#f985ff")
	GlitchBar.BackgroundTransparency = 1
	GlitchBar.Size = UDim2.new(1, 0, 0, 2)
	GlitchBar.Position = UDim2.new(0, 0, 0.5, 0)
	GlitchBar.ZIndex = 515
	GlitchBar.BorderSizePixel = 0

	-- ▂▂▂ PARTICLES ▂▂▂
	local Particles = {}
	for i = 1, 25 do
		local dot = Instance.new("Frame")
		dot.Parent = LoadScreen
		dot.BackgroundColor3 = Color3.fromHex(i % 3 == 0 and "#f985ff" or (i % 3 == 1 and "#ffffff" or "#c542cb"))
		dot.BackgroundTransparency = 1
		dot.Size = UDim2.new(0, math.random(2, 5), 0, math.random(2, 5))
		dot.Position = UDim2.new(math.random() * 0.8 + 0.1, 0, math.random() * 0.6 + 0.2, 0)
		dot.ZIndex = 504
		dot.BorderSizePixel = 0
		Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
		table.insert(Particles, dot)
	end

	-- ════════════════════════════════════════════
	-- ▶▶▶ PURE ANIMATION ENGINE ▶▶▶
	-- ════════════════════════════════════════════
	task.spawn(function()
		local ok, err = pcall(function()
		local TI = TweenInfo.new

		-- ═══ PHASE 1: LETTERBOX SLIDE IN (0.0s) ═══
		Twen:Create(TopBar, TI(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
		Twen:Create(BottomBar, TI(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0.88, 0)}):Play()
		task.wait(0.4)

		-- ═══ PHASE 2: GLITCH SPARKS (0.4s) ═══
		for _ = 1, 3 do
			GlitchBar.BackgroundTransparency = math.random() * 0.3 + 0.2
			GlitchBar.Position = UDim2.new(0, 0, math.random() * 0.6 + 0.2, 0)
			GlitchBar.Size = UDim2.new(1, 0, 0, math.random(1, 4))
			task.wait(0.04)
			GlitchBar.BackgroundTransparency = 1
			task.wait(0.06)
		end

		-- ═══ PHASE 3A: WAVE 1 — RUA (left) + HUB (right) staggered ═══
		local wave1Left  = {1, 2, 3}  -- R, U, A
		local wave1Right = {7, 8, 9}  -- H, U, B
		local wave2Drop  = {4, 5, 6}  -- J, A, D

		-- Floating particles (start early)
		task.spawn(function()
			for _, dot in ipairs(Particles) do
				task.spawn(function()
					task.wait(math.random() * 0.8)
					Twen:Create(dot, TI(0.3, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.3}):Play()
					while not LoadingDone do
						local dur = math.random() * 1.5 + 1
						Twen:Create(dot, TI(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
							Position = UDim2.new(math.random() * 0.8 + 0.1, 0, math.random() * 0.6 + 0.15, 0),
							BackgroundTransparency = math.random() * 0.4 + 0.2
						}):Play()
						task.wait(dur)
					end
				end)
			end
		end)

		-- Wave 1: R U A slide in from left, staggered
		for order, idx in ipairs(wave1Left) do
			local data = Letters[idx]
			task.delay((order - 1) * 0.1, function()
				Twen:Create(data.label, TI(0.15, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
				Twen:Create(data.label, TI(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Position = UDim2.new(0.5, data.finalX, 0.5, 0),
					Rotation = math.random(-6, -2)
				}):Play()
			end)
		end

		-- Wave 1: H U B slide in from right, staggered (reverse order: B first, then U, H)
		for order, idx in ipairs(wave1Right) do
			local data = Letters[idx]
			local reverseOrder = #wave1Right - (order - 1)
			task.delay((reverseOrder - 1) * 0.1, function()
				Twen:Create(data.label, TI(0.15, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
				Twen:Create(data.label, TI(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Position = UDim2.new(0.5, data.finalX, 0.5, 0),
					Rotation = math.random(2, 6)
				}):Play()
			end)
		end

		task.wait(1.0) -- Wait for Wave 1 to settle (RUA___HUB with gap)

		-- ═══ PHASE 3B: WAVE 2 — J A D drop from top corners/center ═══
		-- Mini flash to signal incoming letters
		Twen:Create(WhiteFlash, TI(0.04), {BackgroundTransparency = 0.75}):Play()
		task.wait(0.05)
		Twen:Create(WhiteFlash, TI(0.1, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()

		-- J drops from top-left
		local jData = Letters[4]
		Twen:Create(jData.label, TI(0.12, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
		Twen:Create(jData.label, TI(0.55, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, jData.finalX, 0.5, 0),
			Rotation = 0
		}):Play()

		-- D drops from top-right (slight delay)
		task.delay(0.08, function()
			local dData = Letters[6]
			Twen:Create(dData.label, TI(0.12, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
			Twen:Create(dData.label, TI(0.55, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, dData.finalX, 0.5, 0),
				Rotation = 0
			}):Play()
		end)

		-- A drops from top-center (last, completing the word)
		task.delay(0.18, function()
			local aData = Letters[5]
			Twen:Create(aData.label, TI(0.12, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
			Twen:Create(aData.label, TI(0.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, aData.finalX, 0.5, 0),
				Rotation = 0
			}):Play()
		end)

		task.wait(0.9) -- Wait for JAD to land

		-- ═══ PHASE 4: SNAP & GLOW — All letters align perfectly ═══
		for _, data in ipairs(Letters) do
			Twen:Create(data.label, TI(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, data.finalX, 0.5, 0),
				Rotation = 0
			}):Play()
			-- All letters transition to unified white glow
			Twen:Create(data.label, TI(0.3, Enum.EasingStyle.Quint), {
				TextColor3 = Color3.fromRGB(255, 255, 255)
			}):Play()
		end

		-- Collision flash + glow
		Twen:Create(WhiteFlash, TI(0.05), {BackgroundTransparency = 0.5}):Play()
		Twen:Create(GlowBehind, TI(0.5, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 700, 0, 700), ImageTransparency = 0.35}):Play()
		task.wait(0.06)
		Twen:Create(WhiteFlash, TI(0.2, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()

		-- Recolor to final branding: RUAJAD = white, HUB = purple
		task.wait(0.15)
		for i = 7, 9 do
			Twen:Create(Letters[i].label, TI(0.4, Enum.EasingStyle.Quint), {
				TextColor3 = Color3.fromHex("#c542cb")
			}):Play()
		end

		-- Brief pause to read "RUAJADHUB"
		task.wait(0.7)

		-- ═══ PHASE 5: ZOOM EXPLODE & GUI POP ═══
		LoadingDone = true

		-- Each letter explodes outward from center
		for _, data in ipairs(Letters) do
			local spreadX = data.finalX * 4
			Twen:Create(data.label, TI(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, spreadX, 0.5, 0),
				Size = UDim2.new(0, letterW * 4, 0, letterH * 4),
				TextTransparency = 1
			}):Play()
		end

		Twen:Create(GlowBehind, TI(0.5, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 1500, 0, 1500), ImageTransparency = 1}):Play()

		-- Kill particles
		for _, dot in ipairs(Particles) do
			Twen:Create(dot, TI(0.25, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
		end

		task.wait(0.4)

		-- ★★★ WHITE FLASH — THE MONEY SHOT ★★★
		Twen:Create(WhiteFlash, TI(0.06), {BackgroundTransparency = 0}):Play()
		task.wait(0.08)
		Twen:Create(WhiteFlash, TI(0.6, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()

		-- Letterbox bars retreat
		Twen:Create(TopBar, TI(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(0, 0, -0.12, 0)}):Play()
		Twen:Create(BottomBar, TI(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(0, 0, 1, 0)}):Play()

		-- Final fade
		task.wait(0.15)
		Twen:Create(LoadScreen, TI(0.4, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
		task.wait(0.5)
		LoadScreen:Destroy()
		end) -- end pcall
		if not ok then warn("[RUAJAD HUB] Loading error: " .. tostring(err)) end
	end)
	-- ============================================================

	MainFrame.Name = "MainFrame"
	MainFrame.Parent = ScreenGui
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	MainFrame.BackgroundTransparency = 1
	MainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MainFrame.BorderSizePixel = 0

	local MainGradient = Instance.new("UIGradient")
	MainGradient.Parent = MainFrame
	MainGradient.Rotation = 90
	MainGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#f985ff")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#c542cb"))
	})
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.Size = UDim2.fromOffset(config.Size.X.Offset,config.Size.Y.Offset)
	MainFrame.Active = true;
	MainFrame.ClipsDescendants = true;

	WindowTable.AddEffect = function(color)
		Library.GradientImage(MainFrame,color)
	end

	Twen:Create(MainFrame,TweenInfo1,{BackgroundTransparency = 0.4,Size = config.Size}):Play();

	WindowTable.ElBlurUI = ElBlurSource.new(MainFrame);

	UICorner.CornerRadius = UDim.new(0, 6)
	UICorner.Parent = MainFrame

	-- [DeepSeek] UIStroke: เส้นขอบบางๆ สร้างมิติแบบ Premium Hacker
	local MainStroke = Instance.new("UIStroke")
	MainStroke.Parent = MainFrame
	MainStroke.Color = Color3.fromRGB(100, 100, 100)
	MainStroke.Thickness = 1.5
	MainStroke.Transparency = 0.7

	-- [DeepSeek] UIAspectRatioConstraint: ป้องกัน UI บิดเบี้ยวบนหน้าจอที่ scale ต่างกัน
	local MainAspectRatio = Instance.new("UIAspectRatioConstraint")
	MainAspectRatio.Parent = MainFrame
	MainAspectRatio.AspectRatio = config.Size.X.Offset / config.Size.Y.Offset
	MainAspectRatio.DominantAxis = Enum.DominantAxis.Width
	MainAspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize

	MainDropShadow.Name = "MainDropShadow"
	MainDropShadow.Parent = MainFrame
	MainDropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	MainDropShadow.BackgroundTransparency = 1.000
	MainDropShadow.BorderSizePixel = 0
	MainDropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainDropShadow.Size = UDim2.new(1, 47, 1, 47)
	MainDropShadow.ZIndex = 0
	MainDropShadow.Image = "rbxassetid://6015897843"
	MainDropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	MainDropShadow.ImageTransparency = 1
	MainDropShadow.ScaleType = Enum.ScaleType.Slice
	MainDropShadow.SliceCenter = Rect.new(49, 49, 450, 450)
	MainDropShadow.Rotation = 0.0001;

	Twen:Create(MainDropShadow,TweenInfo2,{ImageTransparency = 0.6}):Play();

	local ProfileFrame = Instance.new("Frame")
	local AvatarImage = Instance.new("ImageLabel")
	local AvatarMask = Instance.new("UICorner")
	local NameText = Instance.new("TextLabel")
	local NameGreeting = Instance.new("TextLabel")
	
	ProfileFrame.Name = "ProfileFrame"
	ProfileFrame.Parent = MainFrame
	ProfileFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ProfileFrame.BackgroundTransparency = 1.000
	ProfileFrame.Position = UDim2.new(0, 12, 0, 8)
	ProfileFrame.Size = UDim2.new(0, 55, 0, 55)
	
	AvatarImage.Name = "AvatarImage"
	AvatarImage.Parent = ProfileFrame
	AvatarImage.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	AvatarImage.BackgroundTransparency = 0.5
	AvatarImage.Size = UDim2.new(0, 45, 0, 45)
	AvatarImage.Position = UDim2.new(0.5, 0, 0, 0)
	AvatarImage.AnchorPoint = Vector2.new(0.5, 0)
	AvatarMask.CornerRadius = UDim.new(1, 0)
	AvatarMask.Parent = AvatarImage
	task.spawn(function()
		pcall(function()
			AvatarImage.Image = game:GetService("Players"):GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		end)
	end)
	
	NameText.Name = "NameText"
	NameText.Parent = ProfileFrame
	NameText.BackgroundTransparency = 1.000
	NameText.Position = UDim2.new(0, 0, 0, 47)
	NameText.Size = UDim2.new(1, 0, 0, 8)
	NameText.Font = Theme.Fonts.Body
	NameText.Text = LocalPlayer.DisplayName
	NameText.TextColor3 = Theme.Colors.Text
	NameText.TextTransparency = 0.1
	NameText.TextSize = 10.000
	NameText.TextXAlignment = Enum.TextXAlignment.Center
	NameText.TextTruncate = Enum.TextTruncate.AtEnd
    
	NameGreeting.Name = "NameGreeting"
	NameGreeting.Parent = ProfileFrame
	NameGreeting.BackgroundTransparency = 1.000
	NameGreeting.Position = UDim2.new(0, 0, 0, 54)
	NameGreeting.Size = UDim2.new(1, 0, 0, 8)
	NameGreeting.Font = Theme.Fonts.Body
	NameGreeting.Text = "@" .. LocalPlayer.Name
	NameGreeting.TextColor3 = Theme.Colors.Text
	NameGreeting.TextTransparency = 0.4
	NameGreeting.TextSize = 9.000
	NameGreeting.TextXAlignment = Enum.TextXAlignment.Center
	NameGreeting.TextTruncate = Enum.TextTruncate.AtEnd

	Title.Name = "Title"
	Title.Parent = MainFrame
	Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Title.BackgroundTransparency = 1.000
	Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Title.BorderSizePixel = 0
	Title.Position = UDim2.new(0, 175, 0, 12)
	Title.Size = UDim2.new(1, -250, 0, 24)
	Title.Font = Theme.Fonts.Title
	Title.Text = config.Title
	Title.TextColor3 = Theme.Colors.Text
	Title.TextScaled = false
	Title.TextSize = 15.000
	Title.TextWrapped = true
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.TextTransparency = 1;

	Twen:Create(Title,TweenInfo2,{TextTransparency = 0}):Play();

	UIGradient.Rotation = 90
	UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.75, 0.27), NumberSequenceKeypoint.new(1.00, 1.00)}
	UIGradient.Parent = Title

	Description.Name = "Description"
	Description.Parent = MainFrame
	Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Description.BackgroundTransparency = 1.000
	Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Description.BorderSizePixel = 0
	Description.Position = UDim2.new(0, 175, 0, 36)
	Description.Size = UDim2.new(1, -250, 0, 28)
	Description.Font = Theme.Fonts.Body
	Description.Text = config.Description
	Description.TextColor3 = Theme.Colors.Text
	Description.TextScaled = false
	Description.TextSize = 14
	Description.TextTransparency = 1
	Description.TextWrapped = true
	Description.TextXAlignment = Enum.TextXAlignment.Left
	Twen:Create(Description,TweenInfo2,{TextTransparency = 0.4}):Play();

	UIGradient_2.Rotation = 90
	UIGradient_2.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.75, 0.27), NumberSequenceKeypoint.new(1.00, 1.00)}
	UIGradient_2.Parent = Description

	BlockFrame1.Name = "BlockFrame1"
	BlockFrame1.Parent = MainFrame
	BlockFrame1.AnchorPoint = Vector2.new(0, 0.5)
	BlockFrame1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	BlockFrame1.BackgroundTransparency = 1
	BlockFrame1.BorderColor3 = Color3.fromRGB(0, 0, 0)
	BlockFrame1.BorderSizePixel = 0
	BlockFrame1.Position = UDim2.new(0, 0, 0, 0)
	BlockFrame1.Size = UDim2.new(0, 0, 0, 0)
	BlockFrame1.ZIndex = 3
	Twen:Create(BlockFrame1,TweenInfo2,{BackgroundTransparency = 0.8}):Play();

	UICorner_3.CornerRadius = UDim.new(0.5, 0)
	UICorner_3.Parent = BlockFrame1

	UIGradient_3.Rotation = 90
	UIGradient_3.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(0.05, 0.00), NumberSequenceKeypoint.new(0.96, 0.00), NumberSequenceKeypoint.new(1.00, 1.00)}
	UIGradient_3.Parent = BlockFrame1

	BlockFrame3.Name = "BlockFrame3"
	BlockFrame3.Parent = MainFrame
	BlockFrame3.AnchorPoint = Vector2.new(0, 0.5)
	BlockFrame3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	BlockFrame3.BackgroundTransparency = 1
	BlockFrame3.BorderColor3 = Color3.fromRGB(0, 0, 0)
	BlockFrame3.BorderSizePixel = 0
	BlockFrame3.Position = UDim2.new(0, 0, 0, 0)
	BlockFrame3.Size = UDim2.new(0, 0, 0, 0)
	BlockFrame3.ZIndex = 3
	Twen:Create(BlockFrame3,TweenInfo2,{BackgroundTransparency = 0.8}):Play();

	UICorner_4.CornerRadius = UDim.new(0.5, 0)
	UICorner_4.Parent = BlockFrame3

	UIGradient_4.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.98, 0.00), NumberSequenceKeypoint.new(1.00, 1.00)}
	UIGradient_4.Parent = BlockFrame3

	BlockFrame2.Name = "BlockFrame2"
	BlockFrame2.Parent = MainFrame
	BlockFrame2.AnchorPoint = Vector2.new(0.5, 0)
	BlockFrame2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	BlockFrame2.BackgroundTransparency = 1
	BlockFrame2.BorderColor3 = Color3.fromRGB(0, 0, 0)
	BlockFrame2.BorderSizePixel = 0
	BlockFrame2.Position = UDim2.new(0.5, 0, 0, 110)
	BlockFrame2.Size = UDim2.new(0.96, 0, 0, 1)
	BlockFrame2.ZIndex = 3
	Twen:Create(BlockFrame2,TweenInfo2,{BackgroundTransparency = 0.8}):Play();

	UICorner_5.CornerRadius = UDim.new(0.5, 0)
	UICorner_5.Parent = BlockFrame2

	UIGradient_5.Rotation = -180
	UIGradient_5.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.98, 0.00), NumberSequenceKeypoint.new(1.00, 1.00)}
	UIGradient_5.Parent = BlockFrame2

	TabButtonFrame.Name = "TabButtonFrame"
	TabButtonFrame.Parent = MainFrame
	TabButtonFrame.AnchorPoint = Vector2.new(0, 0)
	TabButtonFrame.BackgroundColor3 = Theme.Colors.Background
	TabButtonFrame.BackgroundTransparency = 1
	TabButtonFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabButtonFrame.BorderSizePixel = 0
	TabButtonFrame.ClipsDescendants = true
	TabButtonFrame.Position = UDim2.new(0.5, 0, 0, 75) 
	TabButtonFrame.Size = UDim2.new(0.92, 0, 0, 32)
	TabButtonFrame.AnchorPoint = Vector2.new(0.5, 0) 
	Twen:Create(TabButtonFrame,TweenInfo2,{BackgroundTransparency = 0.5}):Play();

	UICorner_6.CornerRadius = UDim.new(0, 4) 
	UICorner_6.Parent = TabButtonFrame

	TabButtons.Name = "TabButtons"
	TabButtons.Parent = TabButtonFrame
	TabButtons.Active = true
	TabButtons.AnchorPoint = Vector2.new(0.5, 0.5)
	TabButtons.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TabButtons.BackgroundTransparency = 1.000
	TabButtons.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabButtons.BorderSizePixel = 0
	TabButtons.ClipsDescendants = false
	TabButtons.Position = UDim2.new(0.5, 0, 0.5, 0)
	TabButtons.Size = UDim2.new(1, 0, 1, 0)
	TabButtons.ScrollBarThickness = 2 
	TabButtons.ScrollBarImageColor3 = Theme.Colors.Stroke
	TabButtons.ScrollBarImageTransparency = 0.5
	TabButtons.ScrollingDirection = Enum.ScrollingDirection.X

	local TabBtnPadding = Instance.new("UIPadding")
	TabBtnPadding.Parent = TabButtons
	TabBtnPadding.PaddingLeft = Theme.Padding.Small
	TabBtnPadding.PaddingRight = Theme.Padding.Small
	TabBtnPadding.PaddingTop = UDim.new(0, 2)
	TabBtnPadding.PaddingBottom = UDim.new(0, 2)
	TabButtons.AutomaticCanvasSize = Enum.AutomaticSize.X
	TabButtons.CanvasSize = UDim2.new(0, 0, 0, 0)
	UIListLayout.Parent = TabButtons
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Padding = Theme.Padding.Small 

	MainTabFrame.Name = "MainTabFrame"
	MainTabFrame.Parent = MainFrame
	MainTabFrame.AnchorPoint = Vector2.new(0.5, 0)
	MainTabFrame.BackgroundColor3 = Theme.Colors.Background
	MainTabFrame.BackgroundTransparency = 1
	MainTabFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MainTabFrame.BorderSizePixel = 0
	MainTabFrame.ClipsDescendants = true
	MainTabFrame.Position = UDim2.new(0.5, 0, 0, 120) 
	MainTabFrame.AnchorPoint = Vector2.new(0.5, 0)
	MainTabFrame.Size = UDim2.new(1, -16, 1, -135)
	Twen:Create(MainTabFrame,TweenInfo2,{BackgroundTransparency = Theme.Transparency.Panel}):Play();

	UICorner_7.CornerRadius = UDim.new(0, 6) 
	UICorner_7.Parent = MainTabFrame

	InputFrame.Name = "InputFrame"
	InputFrame.Parent = MainFrame
	InputFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	InputFrame.BackgroundTransparency = 1.000
	InputFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	InputFrame.BorderSizePixel = 0
	InputFrame.Position = UDim2.new(0, 0, 3.86494179e-08, 0)
	InputFrame.Size = UDim2.new(1, 0, 0.121327251, 0)
	InputFrame.ZIndex = 15;

	task.spawn(function()
		local Locked = nil;
		local Looped = false;

		local DropdownFrame = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local MiniDropShadow = Instance.new("ImageLabel")
		local UIStroke = Instance.new("UIStroke")
		local ValueId = Instance.new("TextLabel")
		local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		local ScrollingFrame = Instance.new("ScrollingFrame")
		local UIListLayout = Instance.new("UIListLayout")
		local Block = Instance.new("Frame")
		local BlockFrame3 = Instance.new("Frame")
		local UICorner_2 = Instance.new("UICorner")
		local UIGradient = Instance.new("UIGradient")

		DropdownFrame.Name = "DropdownFrame"
		DropdownFrame.Parent = ScreenGui
		DropdownFrame.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
		DropdownFrame.BackgroundTransparency = 0.500
		DropdownFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		DropdownFrame.BorderSizePixel = 0
		DropdownFrame.Position = UDim2.new(0, 289, 0, 213)
		DropdownFrame.Size = UDim2.new(0, 150, 0, 145)
		DropdownFrame.ZIndex = 100
		DropdownFrame.Visible = false;

		UICorner.CornerRadius = UDim.new(0, 4)
		UICorner.Parent = DropdownFrame

		MiniDropShadow.Name = "MiniDropShadow"
		MiniDropShadow.Parent = DropdownFrame
		MiniDropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
		MiniDropShadow.BackgroundTransparency = 1.000
		MiniDropShadow.BorderSizePixel = 0
		MiniDropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
		MiniDropShadow.Size = UDim2.new(1, 47, 1, 47)
		MiniDropShadow.ZIndex = 99
		MiniDropShadow.Image = "rbxassetid://6015897843"
		MiniDropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
		MiniDropShadow.ImageTransparency = 0.600
		MiniDropShadow.ScaleType = Enum.ScaleType.Slice
		MiniDropShadow.SliceCenter = Rect.new(49, 49, 450, 450)

		UIStroke.Transparency = 0.900
		UIStroke.Color = Color3.fromRGB(255, 255, 255)
		UIStroke.Parent = DropdownFrame

		ValueId.Name = "ValueId"
		ValueId.Parent = DropdownFrame
		ValueId.AnchorPoint = Vector2.new(0.5, 0)
		ValueId.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ValueId.BackgroundTransparency = 1.000
		ValueId.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ValueId.BorderSizePixel = 0
		ValueId.Position = UDim2.new(0.5, 0, 0, 0)
		ValueId.Size = UDim2.new(0.970000029, 0, 0.5, 0)
		ValueId.ZIndex = 101
		ValueId.Font = Enum.Font.GothamBold
		ValueId.Text = "NONE"
		ValueId.TextColor3 = Color3.fromRGB(255, 255, 255)
		ValueId.TextScaled = false
		ValueId.TextSize = 20.000
		ValueId.TextTransparency = 0.350
		ValueId.TextWrapped = true
		ValueId.TextXAlignment = Enum.TextXAlignment.Right

		UIAspectRatioConstraint.Parent = ValueId
		UIAspectRatioConstraint.AspectRatio = 15.000
		UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

		ScrollingFrame.Parent = DropdownFrame
		ScrollingFrame.Active = true
		ScrollingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		ScrollingFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ScrollingFrame.BackgroundTransparency = 1.000
		ScrollingFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ScrollingFrame.BorderSizePixel = 0
		ScrollingFrame.Position = UDim2.new(0.5, 0, 0.555985212, 0)
		ScrollingFrame.Size = UDim2.new(0.949999988, 0, 0.888029099, 0)
		ScrollingFrame.ZIndex = 102
		ScrollingFrame.BottomImage = ""
		ScrollingFrame.ScrollBarThickness = 1
		ScrollingFrame.TopImage = ""

		UIListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			ScrollingFrame.CanvasSize = UDim2.fromOffset(0,UIListLayout.AbsoluteContentSize.Y)
		end)

		UIListLayout.Parent = ScrollingFrame
		UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.Padding = UDim.new(0, 4)

		Block.Name = "Block"
		Block.Parent = ScrollingFrame
		Block.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Block.BackgroundTransparency = 1.000
		Block.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Block.BorderSizePixel = 0

		BlockFrame3.Name = "BlockFrame3"
		BlockFrame3.Parent = DropdownFrame
		BlockFrame3.AnchorPoint = Vector2.new(0, 0.5)
		BlockFrame3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		BlockFrame3.BackgroundTransparency = 0.800
		BlockFrame3.BorderColor3 = Color3.fromRGB(0, 0, 0)
		BlockFrame3.BorderSizePixel = 0
		BlockFrame3.Position = UDim2.new(0, 0, 0.0799999982, 0)
		BlockFrame3.Size = UDim2.new(1, 0, 0, 1)
		BlockFrame3.ZIndex = 102

		UICorner_2.CornerRadius = UDim.new(0.5, 0)
		UICorner_2.Parent = BlockFrame3

		UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(0.03, 0.00), NumberSequenceKeypoint.new(0.98, 0.00), NumberSequenceKeypoint.new(1.00, 1.00)}
		UIGradient.Parent = BlockFrame3

		local GetSelector = function(title,value)
			local Selector = Instance.new("Frame")
			local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
			local UICorner = Instance.new("UICorner")
			local Title = Instance.new("TextLabel")
			local UIGradient = Instance.new("UIGradient")
			local Frame = Instance.new("Frame")
			local UICorner_2 = Instance.new("UICorner")
			local UIGradient_2 = Instance.new("UIGradient")
			local Button = Instance.new("TextButton")
			local UIStroke = Instance.new("UIStroke")

			Selector.Name = "Selector"
			Selector.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			Selector.BackgroundTransparency = 0.750
			Selector.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Selector.BorderSizePixel = 0
			Selector.ClipsDescendants = true
			Selector.Size = UDim2.new(0.970000029, 0, 0.5, 0)
			Selector.ZIndex = 103
			Selector.Parent = ScrollingFrame
			UIAspectRatioConstraint.Parent = Selector
			UIAspectRatioConstraint.AspectRatio = 11.000
			UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

			UICorner.CornerRadius = UDim.new(0, 3)
			UICorner.Parent = Selector

			Title.Name = "Title"
			Title.Parent = Selector
			Title.AnchorPoint = Vector2.new(0, 0.5)
			Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Title.BackgroundTransparency = 1.000
			Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Title.BorderSizePixel = 0
			Title.Position = UDim2.new(0.0250000004, 0, 0.5, 0)
			Title.Size = UDim2.new(1, 0, 0.5, 0)
			Title.ZIndex = 104
			Title.Font = Enum.Font.GothamBold
			Title.Text = title
			Title.TextColor3 = Color3.fromRGB(255, 255, 255)
			Title.TextScaled = false
			Title.TextSize = 14.000
			Title.TextWrapped = true
			Title.TextXAlignment = Enum.TextXAlignment.Left

			UIGradient.Rotation = 90
			UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
			UIGradient.Parent = Title

			Frame.Parent = Selector
			Frame.AnchorPoint = Vector2.new(1, 0.5)
			Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Frame.BackgroundTransparency = 0.600
			Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Frame.BorderSizePixel = 0
			Frame.Position = UDim2.new(1.02499998, 0, 0.5, 0)
			Frame.Size = UDim2.new(0.0549999997, 0, 0.699999988, 0)
			Frame.ZIndex = 104

			UICorner_2.CornerRadius = UDim.new(0, 3)
			UICorner_2.Parent = Frame

			UIGradient_2.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
			UIGradient_2.Parent = Frame

			Button.Name = "Button"
			Button.Parent = Selector
			Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Button.BackgroundTransparency = 1.000
			Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Button.BorderSizePixel = 0
			Button.Size = UDim2.new(1, 0, 1, 0)
			Button.ZIndex = 105
			Button.Font = Enum.Font.GothamBold
			Button.Text = ""
			Button.TextColor3 = Color3.fromRGB(0, 0, 0)
			Button.TextSize = 20.000
			Button.TextTransparency = 1.000

			UIStroke.Transparency = 0.900
			UIStroke.Color = Color3.fromRGB(255, 255, 255)
			UIStroke.Parent = Selector;

			local caller = function(a)
				if a then
					Twen:Create(Frame,TweenInfo.new(0.1),{
						Position = UDim2.new(1.02499998, 0, 0.5, 0)
					}):Play()
					Twen:Create(Title,TweenInfo.new(0.1),{
						TextTransparency = 0
					}):Play()
					if MainFrame:FindFirstChild("ProfileFrame") then MainFrame.ProfileFrame.Visible = true end

				else
					Twen:Create(Frame,TweenInfo.new(0.1),{
						Position = UDim2.new(1.12499998, 0, 0.5, 0)
					}):Play()
					Twen:Create(Title,TweenInfo.new(0.1),{
						TextTransparency = 0.25
					}):Play()
				end
			end;

			caller(value)

			return {
				effect = caller,
				button = Button,
				delete = function()
					Selector:Destroy()
				end,
			}
		end;

		local MouseInFrame = false;
		local MouseInMyFrame = false;

		local target_conns = {}
		function WindowTable.Dropdown:Setup(target_frame)
			Locked = target_frame
			MouseInFrame = true
			for _, v in pairs(target_conns) do v:Disconnect() end
			target_conns = {}
			table.insert(target_conns, target_frame.Parent.MouseEnter:Connect(function()
				MouseInFrame = true
			end))
			table.insert(target_conns, target_frame.Parent.MouseLeave:Connect(function()
				MouseInFrame = false
			end))
		end;

		local LastOpenTime = 0;
		function WindowTable.Dropdown:Open(args,defauklt,callback, isMulti)
			LastOpenTime = tick();
			Looped = true;

			if type(defauklt) == "table" then
				local str = table.concat(defauklt, ", ")
				ValueId.Text = str ~= "" and str or "NONE"
			else
				ValueId.Text = tostring(defauklt)
			end
			Twen:Create(DropdownFrame,TweenInfo.new(0.3),{
				BackgroundTransparency = 0.1;
			}):Play()

			Twen:Create(MiniDropShadow,TweenInfo.new(0.3),{
				ImageTransparency = 0.6;
			}):Play()

			Twen:Create(ValueId,TweenInfo.new(0.3),{
				TextTransparency = 0.350;
			}):Play()

			Twen:Create(ScrollingFrame,TweenInfo.new(0.3),{
				ScrollBarImageTransparency = 0.5;
			}):Play()

			Twen:Create(BlockFrame3,TweenInfo.new(0.3),{
				BackgroundTransparency = 0.8;
			}):Play()

			Twen:Create(UIStroke,TweenInfo.new(0.3),{
				Transparency = 0.9;
			}):Play()

			for i,v in pairs(ScrollingFrame:GetChildren()) do
				if v ~= Block then
					if v:IsA('Frame') then
						v:Destroy();
					end;
				end;
			end;

			local list = {};

			for i,v in pairs(args) do
				local butt
				if isMulti and type(defauklt) == "table" then
					butt = GetSelector(tostring(v), table.find(defauklt, v) ~= nil)
				else
					butt = GetSelector(tostring(v),v == defauklt)
				end

				butt.button.MouseButton1Click:Connect(function()
					if isMulti and type(defauklt) == "table" then
						local foundIdx = table.find(defauklt, v)
						if foundIdx then
							table.remove(defauklt, foundIdx)
							butt.effect(false)
						else
							table.insert(defauklt, v)
							butt.effect(true)
						end
						local concatStr = table.concat(defauklt, ", ")
						ValueId.Text = concatStr ~= "" and concatStr or "NONE"
						callback(defauklt)
					else
						for i,s in ipairs(list) do
							if s[1] == v then
								s[2].effect(true);
							else
								s[2].effect(false);
							end;
						end;
						ValueId.Text = tostring(v);
						callback(v);
					end
				end)

				table.insert(list,{v,butt})
			end;
		end;

		function WindowTable.Dropdown:Close(args)
			Looped = false;
			Twen:Create(UIStroke,TweenInfo.new(0.3),{
				Transparency = 1;
			}):Play()
			Twen:Create(DropdownFrame,TweenInfo.new(0.3),{
				BackgroundTransparency = 1;
			}):Play()

			Twen:Create(MiniDropShadow,TweenInfo.new(0.3),{
				ImageTransparency = 1;
			}):Play()

			Twen:Create(ValueId,TweenInfo.new(0.3),{
				TextTransparency = 1;
			}):Play()

			Twen:Create(ScrollingFrame,TweenInfo.new(0.3),{
				ScrollBarImageTransparency = 1;
			}):Play()

			Twen:Create(BlockFrame3,TweenInfo.new(0.3),{
				BackgroundTransparency = 1;
			}):Play()

			for i,v in pairs(ScrollingFrame:GetChildren()) do
				if v ~= Block then
					if v:IsA('Frame') then
						v:Destroy();
					end;
				end;
			end;
		end;

		DropdownFrame.MouseEnter:Connect(function()
			MouseInMyFrame = true
		end)
		DropdownFrame.MouseLeave:Connect(function()
			MouseInMyFrame = false
		end)

		Input.InputBegan:Connect(function(keycode)
			if keycode.UserInputType == Enum.UserInputType.MouseButton1 or keycode.UserInputType == Enum.UserInputType.Touch then
				if tick() - LastOpenTime > 0.1 then -- ถ้าผ่านไปเกิน 0.1 วินาทีแล้วค่อยยอมให้สั่งปิด
					if not MouseInFrame and not MouseInMyFrame then
						WindowTable.Dropdown:Close();
					end;
				end;
			end;
		end)

		game:GetService('RunService'):BindToRenderStep('__LIBRARY__',20,function()
			WindowTable.Dropdown.Value = Looped
			if Looped then
				-- [FIX] Guard: Locked อาจถูก Destroy ไปแล้วในระหว่างเปิด Dropdown
				if not Locked or not Locked.Parent then
					Looped = false
					return
				end
				DropdownFrame.Visible = true;

				pcall(function()
					Twen:Create(DropdownFrame,TweenInfo.new(0.15),{
						Position = UDim2.fromOffset(Locked.AbsolutePosition.X + 5,Locked.AbsolutePosition.Y + (DropdownFrame.AbsoluteSize.Y / 1.5)),
						Size = UDim2.fromOffset(Locked.AbsoluteSize.X, 280)
					}):Play()
				end)

			else
				if Locked and Locked.Parent then -- [FIX] nil/destroyed guard
					DropdownFrame.Size = DropdownFrame.Size:Lerp(UDim2.fromOffset(Locked.AbsoluteSize.X,0),.2);
					DropdownFrame.Position = DropdownFrame.Position:Lerp(UDim2.fromOffset(Locked.AbsolutePosition.X,Locked.AbsolutePosition.Y+DropdownFrame.AbsoluteSize.Y),.1);
				else
					DropdownFrame.Size = DropdownFrame.Size:Lerp(UDim2.fromOffset(0,0),.1);
					DropdownFrame.Position = DropdownFrame.Position:Lerp(UDim2.fromOffset(0,0),.1);
				end;

				if DropdownFrame.Size.Y.Offset == 0 then
					DropdownFrame.Visible = false;
				end;
			end;
		end);
	end)

	function WindowTable:NewTab(cfg)
		cfg = Config(cfg,{
			Title = "Example",
			Description = "Tab: "..tostring(#WindowTable.Tabs + 1),
			Icon = "rbxassetid://7733964640"
		});

		local TabTable = {};
		local TabButton = Instance.new("Frame")
		local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		local UICorner = Instance.new("UICorner")
		local Icon = Instance.new("ImageLabel")
		local UICorner_2 = Instance.new("UICorner")
		local UIGradient = Instance.new("UIGradient")
		local Title = Instance.new("TextLabel")
		local UIGradient_2 = Instance.new("UIGradient")
		local Description = Instance.new("TextLabel")
		local UIGradient_3 = Instance.new("UIGradient")
		local Frame = Instance.new("Frame")
		local UICorner_3 = Instance.new("UICorner")
		local UIGradient_4 = Instance.new("UIGradient")
		local Button = Instance.new("TextButton")

		TabButton.Name = "TabButton"
		TabButton.Parent = TabButtons
		TabButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		TabButton.BackgroundTransparency = 1
		TabButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TabButton.BorderSizePixel = 0
		TabButton.ClipsDescendants = true
		
		local hasIcon = cfg.Icon and cfg.Icon ~= "" and cfg.Icon ~= "none"
		local TextService = game:GetService("TextService")
		local titleBounds = TextService:GetTextSize(cfg.Title, 13, Enum.Font.GothamBold, Vector2.new(9999, 9999))
		local desiredWidth = math.max(90, titleBounds.X + (hasIcon and 50 or 30)) 
		
		TabButton.Size = UDim2.new(0, desiredWidth, 0.9, 0)
		TabButton.ZIndex = 5
		Twen:Create(TabButton,TweenInfo2,{BackgroundTransparency = 0.750}):Play();

		UICorner.CornerRadius = UDim.new(0, 3)
		UICorner.Parent = TabButton
		
		local ContentGroup = Instance.new("Frame")
		ContentGroup.Name = "ContentGroup"
		ContentGroup.Parent = TabButton
		ContentGroup.BackgroundTransparency = 1
		ContentGroup.Size = UDim2.new(1, 0, 1, 0)
		ContentGroup.ZIndex = 6
		
		local ContentLayout = Instance.new("UIListLayout")
		ContentLayout.Parent = ContentGroup
		ContentLayout.FillDirection = Enum.FillDirection.Horizontal
		ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ContentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ContentLayout.Padding = UDim.new(0, 6)

		Icon.Name = "Icon"
		Icon.Parent = ContentGroup
		Icon.AnchorPoint = Vector2.new(0, 0.5)
		Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Icon.BackgroundTransparency = 1.000
		Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Icon.BorderSizePixel = 0
		Icon.Size = UDim2.new(0, 16, 0, 16)
		Icon.LayoutOrder = 1
		Icon.ZIndex = 6
		if hasIcon then
			Icon.Image = Icons[cfg.Icon] or cfg.Icon
			Icon.ImageTransparency = 0
			Twen:Create(Icon,TweenInfo2,{ImageTransparency = 0}):Play();
		else
			Icon.ImageTransparency = 1
			Icon.Size = UDim2.new(0, 0, 0, 0)
			ContentLayout.Padding = UDim.new(0, 0)
		end

		UICorner_2.CornerRadius = UDim.new(0, 3)
		UICorner_2.Parent = Icon

		UIGradient.Rotation = 90
		UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.75, 0.27), NumberSequenceKeypoint.new(1.00, 1.00)}
		UIGradient.Parent = Icon

		Title.Name = "Title"
		Title.Parent = ContentGroup
		Title.AnchorPoint = Vector2.new(0, 0.5)
		Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Title.BackgroundTransparency = 1.000
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BorderSizePixel = 0
		Title.Size = UDim2.new(0, titleBounds.X + 4, 1, 0) -- Added a bit more padding
		Title.LayoutOrder = 2
		Title.Font = Enum.Font.GothamBold
		Title.Text = cfg.Title
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.TextScaled = false
		Title.TextSize = 13
		Title.TextTruncate = Enum.TextTruncate.AtEnd
		Title.TextWrapped = false -- Prevents accidental wrapping that might offset text
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.TextTransparency = 1;

		
		UIGradient_2.Rotation = 90
		UIGradient_2.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
		UIGradient_2.Parent = Title

		Description.Name = "Description"
		Description.Parent = TabButton
		Description.AnchorPoint = Vector2.new(0, 0.5)
		Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Description.BackgroundTransparency = 1.000
		Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Description.BorderSizePixel = 0
		Description.Visible = false
		Description.Position = UDim2.new(0.200000003, 0, 0.699999988, 0)
		Description.Size = UDim2.new(1, 0, 0.300000012, 0)
		Description.Font = Enum.Font.GothamBold
		Description.Text = cfg.Description
		Description.TextColor3 = Color3.fromRGB(255, 255, 255)
		Description.TextScaled = false
		Description.TextSize = 8.000
		Description.TextTransparency = 1
		Description.TextWrapped = true
		Description.TextXAlignment = Enum.TextXAlignment.Left

		UIGradient_3.Rotation = 90
		UIGradient_3.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
		UIGradient_3.Parent = Description

		Frame.Parent = TabButton
		Frame.AnchorPoint = Vector2.new(0.5, 1)
		Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Frame.BackgroundTransparency = 1
		Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Frame.BorderSizePixel = 0
		Frame.Position = UDim2.new(0.5, 0, 1.25, 0)
		Frame.Size = UDim2.new(0.8, 0, 0.08, 0)
		Frame.ZIndex = 6
		Twen:Create(Frame,TweenInfo2,{BackgroundTransparency = 0.1}):Play();

		UICorner_3.CornerRadius = UDim.new(0, 3)
		UICorner_3.Parent = Frame

		Button.Name = "Button"
		Button.Parent = TabButton
		Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Button.BackgroundTransparency = 1.000
		Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Button.BorderSizePixel = 0
		Button.Size = UDim2.new(1, 0, 1, 0)
		Button.ZIndex = 15
		Button.Font = Enum.Font.GothamBold
		Button.Text = ""
		Button.TextColor3 = Color3.fromRGB(0, 0, 0)
		Button.TextSize = 20.000
		Button.TextTransparency = 1.000

		local Init = Instance.new("Frame")
		local ContentFrame = Instance.new("ScrollingFrame")
		local UIListLayout = Instance.new("UIListLayout")

		Init.Name = "Init"
		Init.Parent = MainTabFrame
		Init.AnchorPoint = Vector2.new(0.5, 0.5)
		Init.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Init.BackgroundTransparency = 1.000
		Init.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Init.BorderSizePixel = 0
		Init.Position = UDim2.new(0.5, 0, 0.5, 0)
		Init.Size = UDim2.new(0.980000019, 0, 0.980000019, 0)
		Init.ZIndex = 4

		ContentFrame.Name = "ContentFrame"
		ContentFrame.Parent = Init
		ContentFrame.Active = true
		ContentFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		ContentFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ContentFrame.BackgroundTransparency = 1.000
		ContentFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ContentFrame.BorderSizePixel = 0
		ContentFrame.ClipsDescendants = false
		ContentFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		ContentFrame.Size = UDim2.new(1, 0, 1, 0)
		ContentFrame.ScrollBarThickness = 4
		ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
		ContentFrame.ScrollBarImageTransparency = 0.4
		ContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		UIListLayout.Parent = ContentFrame
		UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.Padding = UDim.new(0, 4)

		local ContentPadding = Instance.new("UIPadding")
		ContentPadding.Parent = ContentFrame
		ContentPadding.PaddingLeft = UDim.new(0, 3)
		ContentPadding.PaddingRight = UDim.new(0, 3)
		ContentPadding.PaddingTop = UDim.new(0, 3)
		ContentPadding.PaddingBottom = UDim.new(0, 5)

		WindowTable.MainContent = ContentFrame

		local onFunction = function(value)
			if value then
				Init.Visible = true;

				Twen:Create(Icon,TweenInfo.new(0.55,Enum.EasingStyle.Quint),{
					ImageTransparency = 0.1
				}):Play();

				Twen:Create(Title,TweenInfo.new(0.5,Enum.EasingStyle.Quint),{
					TextTransparency = 0
				}):Play();

				Twen:Create(Description,TweenInfo.new(0.4,Enum.EasingStyle.Quint),{
					TextTransparency = 0.100
				}):Play();

				Twen:Create(Frame,TweenInfo.new(0.55,Enum.EasingStyle.Quint),{
					Position = UDim2.new(0.5, 0, 1, 0)
				}):Play();
			else
				Init.Visible = false;

				Twen:Create(Icon,TweenInfo.new(0.55,Enum.EasingStyle.Quint),{
					ImageTransparency = 0.25
				}):Play();

				Twen:Create(Title,TweenInfo.new(0.4,Enum.EasingStyle.Quint),{
					TextTransparency = 0.25
				}):Play();

				Twen:Create(Description,TweenInfo.new(0.5,Enum.EasingStyle.Quint),{
					TextTransparency = 0.250
				}):Play();

				Twen:Create(Frame,TweenInfo.new(0.55,Enum.EasingStyle.Quint),{
					Position = UDim2.new(0.5, 0, 1.2, 0)
				}):Play();
			end;
		end;

		if WindowTable.Tabs[1] then
			onFunction(false);
		else
			onFunction(true);
		end;

		table.insert(WindowTable.Tabs,{
			Id = Init,
			onFunction = onFunction,
		})

		Button.MouseButton1Click:Connect(function()
			for i,v in ipairs(WindowTable.Tabs) do
				if v.Id == Init then
					v.onFunction(true);
				else
					v.onFunction(false);
				end;
			end;
		end)

		function TabTable:NewSection(c_o_n_f_i_g)
			c_o_n_f_i_g = Config(c_o_n_f_i_g,{
				Position = "Left",
				Title = "Section",
				Icon = 'rbxassetid://7733964640'
			});

			local SectionTable = {};
			local Section = Instance.new("Frame")
			local UICorner = Instance.new("UICorner")
			local Header = Instance.new("Frame")
			local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
			local UICorner_2 = Instance.new("UICorner")
			local Icon = Instance.new("ImageLabel")
			local UICorner_3 = Instance.new("UICorner")
			local UIGradient = Instance.new("UIGradient")
			local BlockFrame = Instance.new("Frame")
			local UICorner_4 = Instance.new("UICorner")
			local UIGradient_2 = Instance.new("UIGradient")
			local Title = Instance.new("TextLabel")
			local UIGradient_3 = Instance.new("UIGradient")
			local SectionAutoUI = Instance.new("UIListLayout")
			local UIStroke = Instance.new("UIStroke")
			local UIGradient_4 = Instance.new("UIGradient")

			Section.Name = "Section"
			Section.Parent = ContentFrame;
			Section.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			Section.BackgroundTransparency = 1
			Section.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Section.BorderSizePixel = 0
			Section.Size = UDim2.new(0.92, 0, 0, 200)
			Section.ClipsDescendants = true;
			Twen:Create(Section,TweenInfo1,{BackgroundTransparency = 0.75}):Play();

			UICorner.CornerRadius = UDim.new(0, 3)
			UICorner.Parent = Section

			Header.Name = "Header"
			Header.Parent = Section
			Header.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			Header.BackgroundTransparency = 0.900
			Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Header.BorderSizePixel = 0
			Header.Size = UDim2.new(1, 0, 0.5, 0)
			Twen:Create(Header,TweenInfo2,{BackgroundTransparency = 0.9}):Play();

			UIAspectRatioConstraint.Parent = Header
			UIAspectRatioConstraint.AspectRatio = 18.000
			UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

			UICorner_2.CornerRadius = UDim.new(0, 3)
			UICorner_2.Parent = Header

			Icon.Name = "Icon"
			Icon.Parent = Header
			Icon.AnchorPoint = Vector2.new(0.5, 0.5)
			Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Icon.BackgroundTransparency = 1.000
			Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Icon.BorderSizePixel = 0
			Icon.Position = UDim2.new(0.0649999976, 0, 0.5, 0)
			Icon.Size = UDim2.new(0.600000024, 0, 0.600000024, 0)
			Icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
			Icon.ZIndex = 6
			Icon.Image = Icons[c_o_n_f_i_g.Icon] or c_o_n_f_i_g.Icon;
			Icon.ImageTransparency = 1
			Twen:Create(Icon,TweenInfo2,{ImageTransparency = 0.1}):Play();

			UICorner_3.CornerRadius = UDim.new(0, 3)
			UICorner_3.Parent = Icon

			UIGradient.Rotation = 90
			UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.75, 0.27), NumberSequenceKeypoint.new(1.00, 1.00)}
			UIGradient.Parent = Icon

			BlockFrame.Name = "BlockFrame"
			BlockFrame.Parent = Header
			BlockFrame.AnchorPoint = Vector2.new(0.5, 1)
			BlockFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			BlockFrame.BackgroundTransparency = 1
			BlockFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
			BlockFrame.BorderSizePixel = 0
			BlockFrame.Position = UDim2.new(0.5, 0, 1, 0)
			BlockFrame.Size = UDim2.new(1, 0, 0, 1)
			BlockFrame.ZIndex = 3
			Twen:Create(BlockFrame,TweenInfo2,{BackgroundTransparency = 0.8}):Play();

			UICorner.CornerRadius = UDim.new(0, 3)
			UICorner.Parent = Section

			Header.Name = "Header"
			Header.Parent = Section
			Header.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			Header.BackgroundTransparency = 0.900
			Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Header.BorderSizePixel = 0
			Header.Size = UDim2.new(1, 0, 0.5, 0)
			Twen:Create(Header,TweenInfo2,{BackgroundTransparency = 0.9}):Play();

			UIAspectRatioConstraint.Parent = Header
			UIAspectRatioConstraint.AspectRatio = 8.000
			UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

			UICorner_2.CornerRadius = UDim.new(0, 3)
			UICorner_2.Parent = Header

			Icon.Name = "Icon"
			Icon.Parent = Header
			Icon.AnchorPoint = Vector2.new(0.5, 0.5)
			Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Icon.BackgroundTransparency = 1.000
			Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Icon.BorderSizePixel = 0
			Icon.Position = UDim2.new(0.0649999976, 0, 0.5, 0)
			Icon.Size = UDim2.new(0.600000024, 0, 0.600000024, 0)
			Icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
			Icon.ZIndex = 6
			Icon.Image = Icons[c_o_n_f_i_g.Icon] or c_o_n_f_i_g.Icon;
			Icon.ImageTransparency = 1
			Twen:Create(Icon,TweenInfo2,{ImageTransparency = 0.1}):Play();

			UICorner_3.CornerRadius = UDim.new(0, 3)
			UICorner_3.Parent = Icon

			UIGradient.Rotation = 90
			UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.75, 0.27), NumberSequenceKeypoint.new(1.00, 1.00)}
			UIGradient.Parent = Icon

			BlockFrame.Name = "BlockFrame"
			BlockFrame.Parent = Header
			BlockFrame.AnchorPoint = Vector2.new(0.5, 1)
			BlockFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			BlockFrame.BackgroundTransparency = 1
			BlockFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
			BlockFrame.BorderSizePixel = 0
			BlockFrame.Position = UDim2.new(0.5, 0, 1, 0)
			BlockFrame.Size = UDim2.new(1, 0, 0, 1)
			BlockFrame.ZIndex = 3
			Twen:Create(BlockFrame,TweenInfo2,{BackgroundTransparency = 0.8}):Play();

			UICorner_4.CornerRadius = UDim.new(0.5, 0)
			UICorner_4.Parent = BlockFrame

			UIGradient_2.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(0.10, 0.00), NumberSequenceKeypoint.new(0.90, 0.00), NumberSequenceKeypoint.new(1.00, 1.00)}
			UIGradient_2.Parent = BlockFrame

			Title.Name = "Title"
			Title.Parent = Header
			Title.AnchorPoint = Vector2.new(0, 0.5)
			Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Title.BackgroundTransparency = 1.000
			Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Title.BorderSizePixel = 0
			Title.Position = UDim2.new(0.125, 0, 0.449999988, 0)
			Title.Size = UDim2.new(1, 0, 0.5, 0)
			Title.Font = Enum.Font.GothamBold
			Title.Text = c_o_n_f_i_g.Title
			Title.TextColor3 = Color3.fromRGB(255, 255, 255)
			Title.TextScaled = false
			Title.TextSize = 13
			Title.TextTruncate = Enum.TextTruncate.AtEnd
			Title.TextWrapped = true
			Title.TextXAlignment = Enum.TextXAlignment.Left
			Title.TextTransparency = 1

			
			Twen:Create(Title,TweenInfo2,{TextTransparency = 0}):Play();

			UIGradient_3.Rotation = 90
			UIGradient_3.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
			UIGradient_3.Parent = Title

			SectionAutoUI.Name = "SectionAutoUI"
			SectionAutoUI.Parent = Section
			SectionAutoUI.HorizontalAlignment = Enum.HorizontalAlignment.Center
			SectionAutoUI.SortOrder = Enum.SortOrder.LayoutOrder
			SectionAutoUI.Padding = UDim.new(0, 8)

			SectionAutoUI:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
				Twen:Create(Section,TweenInfo.new(0.1),{
					Size = UDim2.new(0.98,0,0,math.max(SectionAutoUI.AbsoluteContentSize.Y,50) + (SectionAutoUI.Padding.Offset * 1.12) + 8);
				}):Play()
			end)
			
			-- Initial resize to fix padding glitch on first open
			task.spawn(function()
				task.wait(0.1)
				Twen:Create(Section,TweenInfo.new(0.1),{
					Size = UDim2.new(0.98,0,0,math.max(SectionAutoUI.AbsoluteContentSize.Y,50) + (SectionAutoUI.Padding.Offset * 1.12) + 8);
				}):Play()
			end)

			UIStroke.Transparency = 1
			UIStroke.Color = Color3.fromRGB(255, 255, 255)
			UIStroke.Parent = Section
			Twen:Create(UIStroke,TweenInfo1,{Transparency = 0.9}):Play();

			UIGradient_4.Rotation = 90
			UIGradient_4.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.17, 1.00), NumberSequenceKeypoint.new(0.82, 1.00), NumberSequenceKeypoint.new(1.00, 0.00)}
			UIGradient_4.Parent = UIStroke

			function SectionTable:NewToggle(toggle)
				toggle = Config(toggle,{
					Title = "Toggle",
					Default = false,
					Callback = function() end;
				});

				local FunctionToggle = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local TextInt = Instance.new("TextLabel")
				local UIGradient = Instance.new("UIGradient")
				local Button = Instance.new("TextButton")
				local UIStroke = Instance.new("UIStroke")
				local System = Instance.new("Frame")
				local UICorner = Instance.new("UICorner")
				local UIStroke_2 = Instance.new("UIStroke")
				local Icon = Instance.new("Frame")
				local UICorner_2 = Instance.new("UICorner")
				local UICorner_3 = Instance.new("UICorner")

				FunctionToggle.Name = "FunctionToggle"
				FunctionToggle.Parent = Section
				FunctionToggle.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				FunctionToggle.BackgroundTransparency = 1
				FunctionToggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
				FunctionToggle.BorderSizePixel = 0
				FunctionToggle.Size = UDim2.new(0.949999988, 0, 0.5, 0)
				FunctionToggle.ZIndex = 17
				Twen:Create(FunctionToggle,TweenInfo1,{BackgroundTransparency = 0.8}):Play();

				UIAspectRatioConstraint.Parent = FunctionToggle
				UIAspectRatioConstraint.AspectRatio = 12.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				TextInt.Name = "TextInt"
				TextInt.Parent = FunctionToggle
				TextInt.AnchorPoint = Vector2.new(0.5, 0.5)
				TextInt.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.BackgroundTransparency = 1.000
				TextInt.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TextInt.BorderSizePixel = 0
				TextInt.AnchorPoint = Vector2.new(0, 0.5)
				TextInt.Position = UDim2.new(0.025, 0, 0.5, 0)
				TextInt.Size = UDim2.new(0.82, 0, 0.479999989, 0)
				TextInt.ZIndex = 18
				TextInt.Font = Enum.Font.GothamBold
				TextInt.Text = toggle.Title
				TextInt.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.TextScaled = false
				TextInt.TextSize = 13
				TextInt.TextTruncate = Enum.TextTruncate.AtEnd
				TextInt.TextTransparency = 0.250
				TextInt.TextWrapped = true
				TextInt.TextXAlignment = Enum.TextXAlignment.Left

				
				UIGradient.Rotation = 90
				UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient.Parent = TextInt

				Button.Name = "Button"
				Button.Parent = FunctionToggle
				Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Button.BackgroundTransparency = 1.000
				Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Button.BorderSizePixel = 0
				Button.Size = UDim2.new(1, 0, 1, 0)
				Button.ZIndex = 15
				Button.Font = Enum.Font.GothamBold
				Button.Text = ""
				Button.TextColor3 = Color3.fromRGB(0, 0, 0)
				Button.TextSize = 20.000
				Button.TextTransparency = 1.000

				UIStroke.Transparency = 0.950
				UIStroke.Color = Color3.fromRGB(255, 255, 255)
				UIStroke.Parent = FunctionToggle

				System.Name = "System"
				System.Parent = FunctionToggle
				System.AnchorPoint = Vector2.new(1, 0.5)
				System.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				System.BackgroundTransparency = 1.000
				System.BorderColor3 = Color3.fromRGB(0, 0, 0)
				System.BorderSizePixel = 0
				System.Position = UDim2.new(0.975000024, 0, 0.5, 0)
				System.Size = UDim2.new(0.155000001, 0, 0.600000024, 0)
				System.ZIndex = 18

				UICorner.CornerRadius = UDim.new(0.5, 0)
				UICorner.Parent = System

				UIStroke_2.Transparency = 0.850
				UIStroke_2.Color = Color3.fromRGB(255, 255, 255)
				UIStroke_2.Parent = System

				Icon.Name = "Icon"
				Icon.Parent = System
				Icon.AnchorPoint = Vector2.new(0.5, 0.5)
				Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Icon.BackgroundTransparency = 0.500
				Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Icon.BorderSizePixel = 0
				Icon.Position = UDim2.new(0.25, 0, 0.5, 0)
				Icon.Size = UDim2.new(1, 0, 1, 0)
				Icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
				Icon.ZIndex = 17

				UICorner_2.CornerRadius = UDim.new(1, 0)
				UICorner_2.Parent = Icon

				UICorner_3.CornerRadius = UDim.new(0, 2)
				UICorner_3.Parent = FunctionToggle

				local function OnChange(value)
					if value then

						Twen:Create(TextInt,TweenInfo.new(0.15,Enum.EasingStyle.Quint),{
							TextTransparency = 0.02
						}):Play()

						Twen:Create(Icon,TweenInfo.new(0.15,Enum.EasingStyle.Quint),{
							Position = UDim2.new(0.75, 0, 0.5, 0),
							BackgroundTransparency = 0.4
						}):Play()
					else
						Twen:Create(Icon,TweenInfo.new(0.15,Enum.EasingStyle.Quint),{
							Position = UDim2.new(0.25, 0, 0.5, 0),
							BackgroundTransparency = 0.500
						}):Play()

						Twen:Create(TextInt,TweenInfo.new(0.15,Enum.EasingStyle.Quint),{
							TextTransparency = 0.25
						}):Play()
					end;
				end;

				OnChange(toggle.Default);

				Button.MouseButton1Click:Connect(function()
					toggle.Default = not toggle.Default;
					OnChange(toggle.Default);
					task.spawn(toggle.Callback,toggle.Default)
				end)

				return {
					Value = function(a, b)
						local newindex = b ~= nil and b or a
						toggle.Default = newindex;
						OnChange(toggle.Default);
						task.spawn(toggle.Callback,toggle.Default)
					end,
					Visible = function(a, b)
						local newindx = b ~= nil and b or a
						FunctionToggle.Visible = newindx
					end,
				};
			end;

			function SectionTable:NewTitle(lrm)
				local FunctionTitle = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local TextInt = Instance.new("TextLabel")
				local UIGradient = Instance.new("UIGradient")
				local UICorner = Instance.new("UICorner")

				FunctionTitle.Name = "FunctionTitle"
				FunctionTitle.Parent = Section
				FunctionTitle.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				FunctionTitle.BackgroundTransparency = 0.800
				FunctionTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
				FunctionTitle.BorderSizePixel = 0
				FunctionTitle.Size = UDim2.new(0.949999988, 0, 0.5, 0)
				FunctionTitle.ZIndex = 17

				UIAspectRatioConstraint.Parent = FunctionTitle
				UIAspectRatioConstraint.AspectRatio = 8.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				TextInt.Name = "TextInt"
				TextInt.Parent = FunctionTitle
				TextInt.AnchorPoint = Vector2.new(0.5, 0.5)
				TextInt.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.BackgroundTransparency = 1.000
				TextInt.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TextInt.BorderSizePixel = 0
				TextInt.Position = UDim2.new(0.5, 0, 0.5, 0)
				TextInt.Size = UDim2.new(0.949999988, 0, 0.600000024, 0)
				TextInt.ZIndex = 18
				TextInt.Font = Enum.Font.GothamBold
				TextInt.Text = lrm
				TextInt.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.TextScaled = false
				TextInt.TextSize = 13
				TextInt.TextTruncate = Enum.TextTruncate.AtEnd
				TextInt.TextTransparency = 1
				TextInt.TextWrapped = true
				TextInt.TextXAlignment = Enum.TextXAlignment.Left

				
				Twen:Create(TextInt,TweenInfo1,{TextTransparency = 0.25}):Play();

				UIGradient.Rotation = 90
				UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient.Parent = TextInt

				UICorner.CornerRadius = UDim.new(0, 2)
				UICorner.Parent = FunctionTitle

				return {
					Visible = function(a, b)
						local newindx = b ~= nil and b or a
						FunctionTitle.Visible = newindx
					end,
					Set = function(a, b)
						local val = b ~= nil and b or a
						TextInt.Text = tostring(val)
					end,
				};
			end;

			function SectionTable:NewButton(cfg)
				cfg = Config(cfg,{
					Title = "Button",
					Callback = function() end;
				});

				local FunctionButton = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local UICorner = Instance.new("UICorner")
				local DropShadow = Instance.new("ImageLabel")
				local TextInt = Instance.new("TextLabel")
				local UIGradient = Instance.new("UIGradient")
				local Button = Instance.new("TextButton")
				local UIStroke = Instance.new("UIStroke")

				FunctionButton.Name = "FunctionButton"
				FunctionButton.Parent = Section
				FunctionButton.BackgroundColor3 = Color3.fromRGB(71, 71, 71)
				FunctionButton.BackgroundTransparency = 1
				FunctionButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
				FunctionButton.BorderSizePixel = 0
				FunctionButton.Size = UDim2.new(0.949999988, 0, 0.5, 0)
				FunctionButton.ZIndex = 17
				Twen:Create(FunctionButton,TweenInfo1,{
					BackgroundTransparency = 0.750,
					Size = UDim2.new(0.949999988, 0, 0.5, 0)
				}):Play();

				UIAspectRatioConstraint.Parent = FunctionButton
				UIAspectRatioConstraint.AspectRatio = 11.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				Twen:Create(UIAspectRatioConstraint,TweenInfo1,{
					AspectRatio = 8.0
				}):Play();

				UICorner.CornerRadius = UDim.new(0, 2)
				UICorner.Parent = FunctionButton

				DropShadow.Name = "DropShadow"
				DropShadow.Parent = FunctionButton
				DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
				DropShadow.BackgroundTransparency = 1.000
				DropShadow.BorderSizePixel = 0
				DropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
				DropShadow.Size = UDim2.new(1, 20, 1, 20)
				DropShadow.ZIndex = 16
				DropShadow.Image = "rbxassetid://6015897843"
				DropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
				DropShadow.ImageTransparency = 0.600
				DropShadow.ScaleType = Enum.ScaleType.Slice
				DropShadow.SliceCenter = Rect.new(49, 49, 450, 450)

				TextInt.Name = "TextInt"
				TextInt.Parent = FunctionButton
				TextInt.AnchorPoint = Vector2.new(0.5, 0.5)
				TextInt.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.BackgroundTransparency = 1.000
				TextInt.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TextInt.BorderSizePixel = 0
				TextInt.Position = UDim2.new(0.5, 0, 0.5, 0)
				TextInt.Size = UDim2.new(1, 0, 0.479999989, 0)
				TextInt.ZIndex = 18
				TextInt.Font = Enum.Font.GothamBold
				TextInt.Text = cfg.Title
				TextInt.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.TextScaled = false
				TextInt.TextSize = 13
				TextInt.TextTruncate = Enum.TextTruncate.AtEnd
				TextInt.TextWrapped = true
				TextInt.TextTransparency = 0.25;

				
				UIGradient.Rotation = 90
				UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient.Parent = TextInt

				Button.Name = "Button"
				Button.Parent = FunctionButton
				Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Button.BackgroundTransparency = 1.000
				Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Button.BorderSizePixel = 0
				Button.Size = UDim2.new(1, 0, 1, 0)
				Button.ZIndex = 15
				Button.Font = Enum.Font.GothamBold
				Button.Text = ""
				Button.TextColor3 = Color3.fromRGB(0, 0, 0)
				Button.TextSize = 20.000
				Button.TextTransparency = 1.000

				UIStroke.Transparency = 0.920
				UIStroke.Color = Color3.fromRGB(255, 255, 255)
				UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				UIStroke.Parent = FunctionButton

				Button.MouseEnter:Connect(function()
					Twen:Create(DropShadow,TweenInfo.new(0.2),{
						ImageTransparency = 0.35
					}):Play()

					Twen:Create(TextInt,TweenInfo.new(0.2),{
						TextTransparency = 0
					}):Play()
				end)

				Button.MouseLeave:Connect(function()
					Twen:Create(DropShadow,TweenInfo.new(0.2),{
						ImageTransparency = 0.600
					}):Play()

					Twen:Create(TextInt,TweenInfo.new(0.2),{
						TextTransparency = 0.25
					}):Play()
				end)

				Button.MouseButton1Click:Connect(function()
					task.spawn(cfg.Callback);
				end)

				return {
					Visible = function(a, b)
						local newindx = b ~= nil and b or a
						FunctionButton.Visible = newindx
					end,
					Fire = cfg.Callback
				};
			end;

			function SectionTable:NewKeybind(ctfx)
				ctfx = Config(ctfx,{
					Title = "Keybind",
					Callback = function() end,
					Default = Enum.KeyCode.E,

				});

				local BindEvent = Instance.new('BindableEvent',Section);
				local FunctionKeybind = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local TextInt = Instance.new("TextLabel")
				local UIGradient = Instance.new("UIGradient")
				local Button = Instance.new("TextButton")
				local UIStroke = Instance.new("UIStroke")
				local System = Instance.new("Frame")
				local UICorner = Instance.new("UICorner")
				local UIStroke_2 = Instance.new("UIStroke")
				local Bindkey = Instance.new("TextLabel")
				local UICorner_2 = Instance.new("UICorner")
				BindEvent.Name = tostring(ctfx.Title)
				FunctionKeybind.Name = "FunctionKeybind"
				FunctionKeybind.Parent = Section
				FunctionKeybind.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				FunctionKeybind.BackgroundTransparency = 0.800
				FunctionKeybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
				FunctionKeybind.BorderSizePixel = 0
				FunctionKeybind.Size = UDim2.new(0.949999988, 0, 0.5, 0)
				FunctionKeybind.ZIndex = 17

				UIAspectRatioConstraint.Parent = FunctionKeybind
				UIAspectRatioConstraint.AspectRatio = 11.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				TextInt.Name = "TextInt"
				TextInt.Parent = FunctionKeybind
				TextInt.AnchorPoint = Vector2.new(0.5, 0.5)
				TextInt.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.BackgroundTransparency = 1.000
				TextInt.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TextInt.BorderSizePixel = 0
				TextInt.Position = UDim2.new(0.5, 0, 0.5, 0)
				TextInt.Size = UDim2.new(0.949999988, 0, 0.479999989, 0)
				TextInt.ZIndex = 18
				TextInt.Font = Enum.Font.GothamBold
				TextInt.Text = ctfx.Title
				TextInt.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.TextScaled = false
				TextInt.TextSize = 20.000
				TextInt.TextTransparency = 0.250
				TextInt.TextWrapped = true
				TextInt.TextXAlignment = Enum.TextXAlignment.Left

				UIGradient.Rotation = 90
				UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient.Parent = TextInt

				Button.Name = "Button"
				Button.Parent = FunctionKeybind
				Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Button.BackgroundTransparency = 1.000
				Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Button.BorderSizePixel = 0
				Button.Size = UDim2.new(1, 0, 1, 0)
				Button.ZIndex = 15
				Button.Font = Enum.Font.GothamBold
				Button.Text = ""
				Button.TextColor3 = Color3.fromRGB(0, 0, 0)
				Button.TextSize = 20.000
				Button.TextTransparency = 1.000

				UIStroke.Transparency = 0.950
				UIStroke.Color = Color3.fromRGB(255, 255, 255)
				UIStroke.Parent = FunctionKeybind

				System.Name = "System"
				System.Parent = FunctionKeybind
				System.AnchorPoint = Vector2.new(1, 0.5)
				System.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				System.BackgroundTransparency = 1.000
				System.BorderColor3 = Color3.fromRGB(0, 0, 0)
				System.BorderSizePixel = 0
				System.Position = UDim2.new(0.975000024, 0, 0.5, 0)
				System.Size = UDim2.new(0, 50, 0.600000024, 0)
				System.ZIndex = 18

				UICorner.CornerRadius = UDim.new(0.349999994, 0)
				UICorner.Parent = System

				UIStroke_2.Transparency = 0.950
				UIStroke_2.Color = Color3.fromRGB(255, 255, 255)
				UIStroke_2.Parent = System

				Bindkey.Name = "Bindkey"
				Bindkey.Parent = System
				Bindkey.AnchorPoint = Vector2.new(0.5, 0.5)
				Bindkey.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Bindkey.BackgroundTransparency = 1.000
				Bindkey.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Bindkey.BorderSizePixel = 0
				Bindkey.Position = UDim2.new(0.5, 0, 0.5, 0)
				Bindkey.Size = UDim2.new(1, 0, 0.649999976, 0)
				Bindkey.Font = Enum.Font.GothamBold
				Bindkey.Text = Input:GetStringForKeyCode(ctfx.Default) or ctfx.Default.Name;
				Bindkey.TextColor3 = Color3.fromRGB(255, 255, 255)
				Bindkey.TextScaled = false
				Bindkey.TextSize = 20.000
				Bindkey.TextTransparency = 0.100
				Bindkey.TextWrapped = true

				UICorner_2.CornerRadius = UDim.new(0, 2)
				UICorner_2.Parent = FunctionKeybind

				local IsWIP = false;
				local function UpdateUI(new)
					Bindkey.Text = (typeof(new) == 'string' and new) or new.Name;

					local size = TextServ:GetTextSize(Bindkey.Text,Bindkey.TextSize,Bindkey.Font,Vector2.new(math.huge,math.huge));

					Twen:Create(System,TweenInfo.new(0.2),{
						Size = UDim2.new(0, size.X + 2, 0.600000024, 0)
					}):Play()
				end;

				UpdateUI(ctfx.Default)

				Button.MouseButton1Click:Connect(function()
					if IsWIP then return end;

					IsWIP = true;

					Twen:Create(TextInt,TweenInfo.new(0.1),{
						TextTransparency = 0
					}):Play();

					local Signal = Input.InputBegan:Connect(function(key)
						if key.KeyCode then
							if key.KeyCode ~= Enum.KeyCode.Unknown then
								BindEvent:Fire(key.KeyCode);
							end;
						end;
					end)

					UpdateUI('...')
					local Bind = BindEvent.Event:Wait();
					Twen:Create(TextInt,TweenInfo.new(0.1),{
						TextTransparency = 0.250
					}):Play();
					Signal:Disconnect()
					UpdateUI(Bind)

					IsWIP = false;
					ctfx.Callback(Bind);

				end)

				return {
					Visible = function(a, b)
						local newindx = b ~= nil and b or a
						FunctionKeybind.Visible = newindx
					end,
					Value = function(a, b)
						local lrm = b ~= nil and b or a
						TFrame.Size = UDim2.new((lrm / slider.Max), 0, 1, 0)

						slider.Callback(lrm);
					end,
					Set = function(a, b)
						local lrm = b ~= nil and b or a
						TFrame.Size = UDim2.new((lrm / slider.Max), 0, 1, 0)
                        ValueText.Text = tostring(lrm)..'/'..tostring(slider.Max)
						slider.Callback(lrm);
					end,};
			end;

			function SectionTable:NewLabel(conf)
				conf = Config(conf,{
					Title = "Label",
				})
				local FunctionLabel = Instance.new("Frame")
				local TextInt = Instance.new("TextLabel")

				FunctionLabel.Name = "FunctionLabel"
				FunctionLabel.Parent = Section
				FunctionLabel.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				FunctionLabel.BackgroundTransparency = 1
				FunctionLabel.Size = UDim2.new(0.949999988, 0, 0, 0)
				FunctionLabel.AutomaticSize = Enum.AutomaticSize.Y

				TextInt.Name = "TextInt"
				TextInt.Parent = FunctionLabel
				TextInt.AnchorPoint = Vector2.new(0, 0)
				TextInt.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.BackgroundTransparency = 1.000
				TextInt.Position = UDim2.new(0.025, 0, 0, 0)
				TextInt.Size = UDim2.new(0.95, 0, 0, 0)
				TextInt.AutomaticSize = Enum.AutomaticSize.Y
				TextInt.Font = Enum.Font.GothamBold
				TextInt.Text = conf.Title
				TextInt.TextColor3 = Color3.fromRGB(200, 200, 200)
				TextInt.TextScaled = false
				TextInt.TextSize = 13
				TextInt.TextTruncate = Enum.TextTruncate.None
				TextInt.TextTransparency = 0.200
				TextInt.TextWrapped = true
				TextInt.TextXAlignment = Enum.TextXAlignment.Left

				
				return {
					Visible = function(a, b)
						local newindx = b ~= nil and b or a
						FunctionLabel.Visible = newindx
					end,
					Set = function(a, b)
						local val = b ~= nil and b or a
						TextInt.Text = tostring(val)
					end,
				};
			end;

			function SectionTable:NewImage(conf)
				conf = Config(conf,{
					Title = "Image",
					Default = "rbxassetid://10002398990",
					Resolution = 2.0
				})
				local FunctionImage = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local ImageLabel = Instance.new("ImageLabel")
				local UICorner = Instance.new("UICorner")
				local UIStroke = Instance.new("UIStroke")

				FunctionImage.Name = "FunctionImage"
				FunctionImage.Parent = Section
				FunctionImage.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				FunctionImage.BackgroundTransparency = 0.8
				FunctionImage.Size = UDim2.new(0.949999988, 0, 0.5, 0)

				UICorner.CornerRadius = UDim.new(0, 4)
				UICorner.Parent = FunctionImage
				UIStroke.Transparency = 0.950
				UIStroke.Color = Color3.fromRGB(255, 255, 255)
				UIStroke.Parent = FunctionImage

				UIAspectRatioConstraint.Parent = FunctionImage
				UIAspectRatioConstraint.AspectRatio = conf.Resolution
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				ImageLabel.Name = "Image"
				ImageLabel.Parent = FunctionImage
				ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
				ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				ImageLabel.BackgroundTransparency = 1.000
				ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
				ImageLabel.Size = UDim2.new(0.95, 0, 0.9, 0)
				ImageLabel.Image = conf.Default
				ImageLabel.ScaleType = Enum.ScaleType.Fit

				local UICorner2 = Instance.new("UICorner")
				UICorner2.CornerRadius = UDim.new(0, 4)
				UICorner2.Parent = ImageLabel

				return {
					Visible = function(a, b)
						local newindx = b ~= nil and b or a
						FunctionImage.Visible = newindx
					end,
					Set = function(a, b)
						local id = b ~= nil and b or a
						ImageLabel.Image = id
					end,
				};
			end;

			function SectionTable:NewSlider(slider)
				slider = Config(slider,{
					Title = "Slider",
					Min = 0,
					Max = 100,
					Default = 50,
					Callback = function()

					end,
				});

				local FunctionSlider = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local TextInt = Instance.new("TextLabel")
				local UIGradient = Instance.new("UIGradient")
				local UIStroke = Instance.new("UIStroke")
				local UICorner = Instance.new("UICorner")
				local ValueText = Instance.new("TextLabel")
				local UIGradient_2 = Instance.new("UIGradient")
				local MFrame = Instance.new("Frame")
				local UICorner_2 = Instance.new("UICorner")
				local TFrame = Instance.new("Frame")
				local UICorner_3 = Instance.new("UICorner")
				local UIStroke_2 = Instance.new("UIStroke")

				FunctionSlider.Name = "FunctionSlider"
				FunctionSlider.Parent = Section
				FunctionSlider.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				FunctionSlider.BackgroundTransparency = 0.800
				FunctionSlider.BorderColor3 = Color3.fromRGB(0, 0, 0)
				FunctionSlider.BorderSizePixel = 0
				FunctionSlider.Size = UDim2.new(0.949999988, 0, 0.5, 0)
				FunctionSlider.ZIndex = 17

				UIAspectRatioConstraint.Parent = FunctionSlider
				UIAspectRatioConstraint.AspectRatio = 9.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				TextInt.Name = "TextInt"
				TextInt.Parent = FunctionSlider
				TextInt.AnchorPoint = Vector2.new(0.5, 0.5)
				TextInt.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.BackgroundTransparency = 1.000
				TextInt.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TextInt.BorderSizePixel = 0
				TextInt.Position = UDim2.new(0.5, 0, 0.25, 0)
				TextInt.Size = UDim2.new(0.95, 0, 0.35, 0)
				TextInt.ZIndex = 18
				TextInt.Font = Enum.Font.GothamBold
				TextInt.Text = slider.Title
				TextInt.TextColor3 = Color3.fromRGB(240, 240, 240)
				TextInt.TextScaled = false
				TextInt.TextSize = 14
				TextInt.TextTruncate = Enum.TextTruncate.AtEnd
				TextInt.TextTransparency = 0.250
				TextInt.TextWrapped = true
				TextInt.TextXAlignment = Enum.TextXAlignment.Left

				
				UIGradient.Rotation = 90
				UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient.Parent = TextInt

				UIStroke.Transparency = 0.950
				UIStroke.Color = Color3.fromRGB(255, 255, 255)
				UIStroke.Parent = FunctionSlider

				UICorner.CornerRadius = UDim.new(0, 2)
				UICorner.Parent = FunctionSlider

				ValueText.Name = "ValueText"
				ValueText.Parent = FunctionSlider
				ValueText.AnchorPoint = Vector2.new(0.5, 0.5)
				ValueText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				ValueText.BackgroundTransparency = 1.000
				ValueText.BorderColor3 = Color3.fromRGB(0, 0, 0)
				ValueText.BorderSizePixel = 0
				ValueText.Position = UDim2.new(0.5, 0, 0.25, 0)
				ValueText.Size = UDim2.new(0.95, 0, 0.35, 0)
				ValueText.ZIndex = 18
				ValueText.Font = Enum.Font.GothamBold
				ValueText.Text = tostring(slider.Default)..'/'..tostring(slider.Max)
				ValueText.TextColor3 = Color3.fromRGB(240, 240, 240)
				ValueText.TextScaled = false
				ValueText.TextSize = 14
				ValueText.TextTransparency = 0.100
				ValueText.TextWrapped = true
				ValueText.TextXAlignment = Enum.TextXAlignment.Right

				UIGradient_2.Rotation = 90
				UIGradient_2.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient_2.Parent = ValueText

				MFrame.Name = "MFrame"
				MFrame.Parent = FunctionSlider
				MFrame.AnchorPoint = Vector2.new(0.5, 0.5)
				MFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				MFrame.BackgroundTransparency = 0.800
				MFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
				MFrame.BorderSizePixel = 0
				MFrame.ClipsDescendants = true
				MFrame.Position = UDim2.new(0.5, 0, 0.75, 0)
				MFrame.Size = UDim2.new(0.949999988, 0, 0.289999992, 0)
				MFrame.ZIndex = 18

				UICorner_2.CornerRadius = UDim.new(0, 2)
				UICorner_2.Parent = MFrame

				TFrame.Name = "TFrame"
				TFrame.Parent = MFrame
				TFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TFrame.BackgroundTransparency = 0.500
				TFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TFrame.BorderSizePixel = 0
				TFrame.Size = UDim2.new((slider.Default / slider.Max), 0, 1, 0)
				TFrame.ZIndex = 17

				UICorner_3.CornerRadius = UDim.new(0, 2)
				UICorner_3.Parent = TFrame

				UIStroke_2.Transparency = 0.975
				UIStroke_2.Color = Color3.fromRGB(255, 255, 255)
				UIStroke_2.Parent = MFrame

				local Holding = false

				local function update(Input)
					local SizeScale = math.clamp((((Input.Position.X) - MFrame.AbsolutePosition.X) / MFrame.AbsoluteSize.X), 0, 1)
					local Main = ((slider.Max - slider.Min) * SizeScale) + slider.Min;
					local Value = math.round(Main)
					local Size = UDim2.fromScale(SizeScale, 1)
					ValueText.Text = tostring(Value)..'/'..tostring(slider.Max)
					Twen:Create(TFrame,TweenInfo.new(0.1),{Size = Size}):Play()
					slider.Callback(Value);
				end

				MFrame.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						Holding = true
						update(Input)
						Twen:Create(TextInt,TweenInfo.new(0.1),{
							TextTransparency = 0
						}):Play()
					end
				end)

				MFrame.InputEnded:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						Holding = false
						Twen:Create(TextInt,TweenInfo.new(0.1),{
							TextTransparency = 0.3
						}):Play()
					end
				end)

				Input.InputChanged:Connect(function(Input)
					if Holding then
						if (Input.UserInputType==Enum.UserInputType.MouseMovement or Input.UserInputType==Enum.UserInputType.Touch)  then
							update(Input)
						end
					end
				end)

				return {
					Visible = function(a, b)
						local newindx = b ~= nil and b or a
						FunctionSlider.Visible = newindx
					end,
					Value = function(a, b)
						local lrm = b ~= nil and b or a
						TFrame.Size = UDim2.new((lrm / slider.Max), 0, 1, 0)

						slider.Callback(lrm);
					end,
					Set = function(a, b)
						local lrm = b ~= nil and b or a
						TFrame.Size = UDim2.new((lrm / slider.Max), 0, 1, 0)
                        ValueText.Text = tostring(lrm)..'/'..tostring(slider.Max)
						slider.Callback(lrm);
					end,};
			end;

			function SectionTable:NewDropdown(drop)
				drop = Config(drop,{
					Title = "Dropdown",
					Data = {'One','Two','Three','Four'},
					Default = 'Two',
					MultipleOptions = false,
					Callback = function(a)

					end,
				});

				local FunctionDropdown = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local TextInt = Instance.new("TextLabel")
				local UIGradient = Instance.new("UIGradient")
				local UIStroke = Instance.new("UIStroke")
				local UICorner = Instance.new("UICorner")
				local MFrame = Instance.new("Frame")
				local UICorner_2 = Instance.new("UICorner")
				local UIStroke_2 = Instance.new("UIStroke")
				local ValueText = Instance.new("TextLabel")
				local UIGradient_2 = Instance.new("UIGradient")
				local Button = Instance.new("TextButton")

				FunctionDropdown.Name = "FunctionDropdown"
				FunctionDropdown.Parent = Section
				FunctionDropdown.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				FunctionDropdown.BackgroundTransparency = 0.800
				FunctionDropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
				FunctionDropdown.BorderSizePixel = 0
				FunctionDropdown.Size = UDim2.new(0.949999988, 0, 0.5, 0)
				FunctionDropdown.ZIndex = 17

				UIAspectRatioConstraint.Parent = FunctionDropdown
				UIAspectRatioConstraint.AspectRatio = 10.500
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				TextInt.Name = "TextInt"
				TextInt.Parent = FunctionDropdown
				TextInt.AnchorPoint = Vector2.new(0.5, 0.5)
				TextInt.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.BackgroundTransparency = 1.000
				TextInt.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TextInt.BorderSizePixel = 0
				TextInt.Position = UDim2.new(0.5, 0, 0.25, 0)
				TextInt.Size = UDim2.new(0.95, 0, 0.40, 0)
				TextInt.ZIndex = 18
				TextInt.Font = Enum.Font.GothamBold
				TextInt.Text = drop.Title
				TextInt.TextColor3 = Color3.fromRGB(240, 240, 240)
				TextInt.TextScaled = false
				TextInt.TextSize = 14
				TextInt.TextTruncate = Enum.TextTruncate.AtEnd
				TextInt.TextTransparency = 0.250
				TextInt.TextWrapped = true
				TextInt.TextXAlignment = Enum.TextXAlignment.Left

				
				UIGradient.Rotation = 90
				UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient.Parent = TextInt

				UIStroke.Transparency = 0.950
				UIStroke.Color = Color3.fromRGB(255, 255, 255)
				UIStroke.Parent = FunctionDropdown

				UICorner.CornerRadius = UDim.new(0, 2)
				UICorner.Parent = FunctionDropdown

				MFrame.Name = "MFrame"
				MFrame.Parent = FunctionDropdown
				MFrame.AnchorPoint = Vector2.new(0.5, 0.5)
				MFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				MFrame.BackgroundTransparency = 0.800
				MFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
				MFrame.BorderSizePixel = 0
				MFrame.ClipsDescendants = true
				MFrame.Position = UDim2.new(0.5, 0, 0.72, 0)
				MFrame.Size = UDim2.new(0.95, 0, 0.40, 0)
				MFrame.ZIndex = 18

				UICorner_2.CornerRadius = UDim.new(0, 2)
				UICorner_2.Parent = MFrame

				UIStroke_2.Transparency = 0.975
				UIStroke_2.Color = Color3.fromRGB(255, 255, 255)
				UIStroke_2.Parent = MFrame

				ValueText.Name = "ValueText"
				ValueText.Parent = MFrame
				ValueText.AnchorPoint = Vector2.new(0.5, 0.5)
				ValueText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				ValueText.BackgroundTransparency = 1.000
				ValueText.BorderColor3 = Color3.fromRGB(0, 0, 0)
				ValueText.BorderSizePixel = 0
				ValueText.Position = UDim2.new(0.5, 0, 0.5, 0)
				ValueText.Size = UDim2.new(0.95, 0, 0.8, 0)
				ValueText.ZIndex = 18
				ValueText.Font = Enum.Font.GothamBold
				if type(drop.Default) == "table" then
					local str = table.concat(drop.Default, ", ")
					ValueText.Text = str ~= "" and str or "NONE"
				else
					ValueText.Text = drop.Default or "NONE"
				end
				ValueText.TextColor3 = Color3.fromRGB(255, 255, 255)
				ValueText.TextScaled = false
				ValueText.TextSize = 14
				ValueText.TextTransparency = 0.100
				ValueText.TextWrapped = true

				MFrame.MouseEnter:Connect(function()
					Twen:Create(ValueText,TweenInfo.new(0.3),{
						TextTransparency = 0.1
					}):Play()
				end)

				MFrame.MouseLeave:Connect(function()
					Twen:Create(ValueText,TweenInfo.new(0.3),{
						TextTransparency = 0.100
					}):Play()
				end)

				UIGradient_2.Rotation = 90
				UIGradient_2.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient_2.Parent = ValueText

				Button.Name = "Button"
				Button.Parent = FunctionDropdown
				Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Button.BackgroundTransparency = 1.000
				Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Button.BorderSizePixel = 0
				Button.Size = UDim2.new(1, 0, 1, 0)
				Button.ZIndex = 25
				Button.Font = Enum.Font.GothamBold
				Button.Text = ""
				Button.TextColor3 = Color3.fromRGB(0, 0, 0)
				Button.TextSize = 20.000
				Button.TextTransparency = 1.000

				local Updater = function(value)
					drop.Default = value;
					if type(value) == "table" then
						local str = table.concat(value, ", ")
						ValueText.Text = str ~= "" and str or "NONE"
					else
						ValueText.Text = tostring(value);
					end
					drop.Callback(value);
				end;

				Button.MouseButton1Click:Connect(function()
					WindowTable.Dropdown:Setup(MFrame)

					WindowTable.Dropdown:Open(drop.Data,drop.Default,Updater, drop.MultipleOptions)
				end)

				return {
					Visible = function(a, b)
						local newindx = b ~= nil and b or a
						FunctionDropdown.Visible = newindx
					end,
					Value = function(a, b)
						local value = b ~= nil and b or a
						Updater(value)
					end,
					Open = function(_, _)
						WindowTable.Dropdown:Setup(MFrame)

						WindowTable.Dropdown:Open(drop.Data,drop.Default,Updater, drop.MultipleOptions)
					end,

					Close = function(_, _)
						WindowTable.Dropdown:Close();
					end,
					Clear = function(_)
						drop.Data = {}
					end,
					Refresh = function(a, b)
						local val = b ~= nil and b or a
						drop.Data = val
					end,
					Set = function(a, b)
						local val = b ~= nil and b or a
                        Updater(val)
					end
				};
			end;

			function SectionTable:NewTextbox(conf)
				conf = Config(conf,{
					Title = "Textbox",
					Default = '',
					FileType = "",
					Callback = function(a)

					end,
				})

				local FunctionTextbox = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local TextInt = Instance.new("TextLabel")
				local UIGradient = Instance.new("UIGradient")
				local UIStroke = Instance.new("UIStroke")
				local UICorner = Instance.new("UICorner")
				local MFrame = Instance.new("Frame")
				local UICorner_2 = Instance.new("UICorner")
				local UIStroke_2 = Instance.new("UIStroke")
				local FileType = Instance.new("TextLabel")
				local UIGradient_2 = Instance.new("UIGradient")
				local TextBox = Instance.new("TextBox")
				local Button = Instance.new("TextButton")

				FunctionTextbox.Name = "FunctionTextbox"
				FunctionTextbox.Parent = Section
				FunctionTextbox.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
				FunctionTextbox.BackgroundTransparency = 0.800
				FunctionTextbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
				FunctionTextbox.BorderSizePixel = 0
				FunctionTextbox.Size = UDim2.new(0.949999988, 0, 0.5, 0)
				FunctionTextbox.ZIndex = 17

				UIAspectRatioConstraint.Parent = FunctionTextbox
				UIAspectRatioConstraint.AspectRatio = 5.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				TextInt.Name = "TextInt"
				TextInt.Parent = FunctionTextbox
				TextInt.AnchorPoint = Vector2.new(0.5, 0.5)
				TextInt.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.BackgroundTransparency = 1.000
				TextInt.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TextInt.BorderSizePixel = 0
				TextInt.Position = UDim2.new(0.5, 0, 0.200000003, 0)
				TextInt.Size = UDim2.new(0.949999988, 0, 0.319999993, 0)
				TextInt.ZIndex = 18
				TextInt.Font = Enum.Font.GothamBold
				TextInt.Text = conf.Title
				TextInt.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextInt.TextScaled = false
				TextInt.TextSize = 20.000
				TextInt.TextTransparency = 0.250
				TextInt.TextWrapped = true
				TextInt.TextXAlignment = Enum.TextXAlignment.Left

				UIGradient.Rotation = 90
				UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient.Parent = TextInt

				UIStroke.Transparency = 0.950
				UIStroke.Color = Color3.fromRGB(255, 255, 255)
				UIStroke.Parent = FunctionTextbox

				UICorner.CornerRadius = UDim.new(0, 2)
				UICorner.Parent = FunctionTextbox

				MFrame.Name = "MFrame"
				MFrame.Parent = FunctionTextbox
				MFrame.AnchorPoint = Vector2.new(0.5, 0.5)
				MFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				MFrame.BackgroundTransparency = 0.800
				MFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
				MFrame.BorderSizePixel = 0
				MFrame.ClipsDescendants = true
				MFrame.Position = UDim2.new(0.5, 0, 0.699999988, 0)
				MFrame.Size = UDim2.new(0.949999988, 0, 0.375, 0)
				MFrame.ZIndex = 18

				UICorner_2.CornerRadius = UDim.new(0, 2)
				UICorner_2.Parent = MFrame

				UIStroke_2.Transparency = 0.975
				UIStroke_2.Color = Color3.fromRGB(255, 255, 255)
				UIStroke_2.Parent = MFrame

				FileType.Name = "FileType"
				FileType.Parent = MFrame
				FileType.AnchorPoint = Vector2.new(0.5, 0.5)
				FileType.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				FileType.BackgroundTransparency = 1.000
				FileType.BorderColor3 = Color3.fromRGB(0, 0, 0)
				FileType.BorderSizePixel = 0
				FileType.Position = UDim2.new(0.5, 0, 0.5, 0)
				FileType.Size = UDim2.new(0.899999976, 0, 0.800000012, 0)
				FileType.ZIndex = 18
				FileType.Font = Enum.Font.GothamBold
				FileType.Text = conf.FileType
				FileType.TextColor3 = Color3.fromRGB(255, 255, 255)
				FileType.TextScaled = false
				FileType.TextSize = 20.000
				FileType.TextTransparency = 0.100
				FileType.TextWrapped = true
				FileType.TextXAlignment = Enum.TextXAlignment.Right

				UIGradient_2.Rotation = 90
				UIGradient_2.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.84, 0.25), NumberSequenceKeypoint.new(1.00, 1.00)}
				UIGradient_2.Parent = FileType

				TextBox.Parent = MFrame
				TextBox.AnchorPoint = Vector2.new(0.5, 0.5)
				TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextBox.BackgroundTransparency = 1.000
				TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TextBox.BorderSizePixel = 0
				TextBox.Position = UDim2.new(0.425999999, 0, 0.5, 0)
				TextBox.Size = UDim2.new(0.753000021, 0, 0.800000012, 0)
				TextBox.ZIndex = 35
				TextBox.ClearTextOnFocus = false
				TextBox.Font = Enum.Font.GothamBold
				TextBox.Text = tostring(conf.Default) or "";
				TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextBox.TextScaled = false
				TextBox.TextSize = 20.000
				TextBox.TextTransparency = 0.600
				TextBox.TextWrapped = true
				TextBox.TextXAlignment = Enum.TextXAlignment.Left

				Button.Name = "Button"
				Button.Parent = FunctionTextbox
				Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Button.BackgroundTransparency = 1.000
				Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Button.BorderSizePixel = 0
				Button.Size = UDim2.new(1, 0, 1, 0)
				Button.ZIndex = 25
				Button.Font = Enum.Font.GothamBold
				Button.Text = "";
				Button.TextColor3 = Color3.fromRGB(0, 0, 0)
				Button.TextSize = 20.000
				Button.TextTransparency = 1.000

				TextBox.FocusLost:Connect(function(press)
					conf.Callback(TextBox.Text);
				end)
			end;

			return SectionTable;
		end;

		return TabTable;
	end;

	local dragToggle = nil;
	local dragSpeed = 0.1;
	local dragStart = nil;
	local startPos = nil;

	local function updateInput(input)
		WindowTable.ElBlurUI.Update()
		local delta = input.Position - dragStart;
		local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y);
		game:GetService('TweenService'):Create(MainFrame, TweenInfo.new(dragSpeed), {Position = position}):Play()
	end;

	InputFrame.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragToggle = true
			dragStart = input.Position
			startPos = MainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragToggle = false;
				end;
			end)
		end;
	end)

	Input.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if dragToggle then
				updateInput(input);
			end;
		end;
	end)

	return WindowTable;
end;

Library.NewAuth = function(conf)
	conf = Config(conf,{
		Title = "Nothing $ KEY SYSTEM",
		GetKey = function() return 'https://example.com' end,
		Auth = function(key) if key == '1 or 1' then return key; end; end,
		Freeze = false,
	});

	if conf.Auth then
		if debug.info(conf.Auth,'s') == '[C]' then
			if error then
				error('huh');
			end;

			return;
		end;
	end;

	if conf.GetKey then
		if debug.info(conf.GetKey,'s') == '[C]' then
			if error then
				error('huh');
			end;

			return;
		end;
	end;

	local ScreenGui = Instance.new("ScreenGui")
	local vaid = Instance.new('BindableEvent')
	local Auth = Instance.new("Frame")
	local MainFrame = Instance.new("Frame")
	local BlockFrame = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local UIGradient = Instance.new("UIGradient")
	local UICorner_2 = Instance.new("UICorner")
	local Button2 = Instance.new("TextButton")
	local UICorner_3 = Instance.new("UICorner")
	local DropShadow = Instance.new("ImageLabel")
	local UIStroke = Instance.new("UIStroke")
	local TextBox = Instance.new("TextBox")
	local UICorner_4 = Instance.new("UICorner")
	local DropShadow_2 = Instance.new("ImageLabel")
	local UIStroke_2 = Instance.new("UIStroke")
	local Button1 = Instance.new("TextButton")
	local UICorner_5 = Instance.new("UICorner")
	local DropShadow_3 = Instance.new("ImageLabel")
	local UIStroke_3 = Instance.new("UIStroke")
	local MainDropShadow = Instance.new("ImageLabel")
	local Title = Instance.new("TextLabel")
	local UIGradient_2 = Instance.new("UIGradient")
	local UICorner_6 = Instance.new("UICorner")

	ScreenGui.Parent = CoreGui
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	ScreenGui.Name = game:GetService('HttpService'):GenerateGUID(false)..tostring(tick())

	Auth.Name = "Auth"
	Auth.Parent = ScreenGui
	Auth.Active = true
	Auth.AnchorPoint = Vector2.new(0.5, 0.5)
	Auth.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
	Auth.BackgroundTransparency = 1.000
	Auth.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Auth.BorderSizePixel = 0
	Auth.ClipsDescendants = true
	Auth.Position = UDim2.new(0.5, 0, 0.5, 0)
	Auth.Size = UDim2.new(0.100000001, 245, 0.100000001, 115)

	local BlueEffect = ElBlurSource.new(MainFrame,true);
	local cose = {Library.GradientImage(MainFrame),
		Library.GradientImage(MainFrame,Color3.fromRGB(255, 0, 4))}

	MainFrame.Name = "MainFrame"
	MainFrame.Parent = Auth
	MainFrame.Active = true
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	MainFrame.BackgroundTransparency = 0.500
	MainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MainFrame.BorderSizePixel = 0
	MainFrame.Position = UDim2.new(0.5, 0, -1.5, 0)
	MainFrame.Size = UDim2.new(0.8,0,0.8,0)
	Twen:Create(MainFrame,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0)
	}):Play();

	BlockFrame.Name = "BlockFrame"
	BlockFrame.Parent = MainFrame
	BlockFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	BlockFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	BlockFrame.BackgroundTransparency = 0.800
	BlockFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	BlockFrame.BorderSizePixel = 0
	BlockFrame.Position = UDim2.new(0.5, 0, 0.150000006, 0)
	BlockFrame.Size = UDim2.new(1, 0, 0, 1)
	BlockFrame.ZIndex = 3

	UICorner.CornerRadius = UDim.new(0.5, 0)
	UICorner.Parent = BlockFrame

	UIGradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(0.05, 0.00), NumberSequenceKeypoint.new(0.96, 0.00), NumberSequenceKeypoint.new(1.00, 1.00)}
	UIGradient.Parent = BlockFrame

	UICorner_2.CornerRadius = UDim.new(0, 7)
	UICorner_2.Parent = MainFrame

	Button2.Name = "Button2"
	Button2.Parent = MainFrame
	Button2.AnchorPoint = Vector2.new(0.5, 0.5)
	Button2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Button2.BackgroundTransparency = 0.500
	Button2.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Button2.BorderSizePixel = 0
	Button2.Position = UDim2.new(0.75, 0, 0.649999976, 0)
	Button2.Size = UDim2.new(0.447547048, 0, 0.155089319, 0)
	Button2.ZIndex = 3
	Button2.Font = Enum.Font.GothamBold
	Button2.Text = "ACTIVATE"
	Button2.TextColor3 = Color3.fromRGB(255, 255, 255)
	Button2.TextSize = 20.000

	UICorner_3.CornerRadius = UDim.new(0, 2)
	UICorner_3.Parent = Button2

	DropShadow.Name = "DropShadow"
	DropShadow.Parent = Button2
	DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	DropShadow.BackgroundTransparency = 1.000
	DropShadow.BorderSizePixel = 0
	DropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	DropShadow.Size = UDim2.new(1, 37, 1, 37)
	DropShadow.Image = "rbxassetid://6015897843"
	DropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	DropShadow.ImageTransparency = 0.600
	DropShadow.ScaleType = Enum.ScaleType.Slice
	DropShadow.SliceCenter = Rect.new(49, 49, 450, 450)

	UIStroke.Transparency = 1
	UIStroke.Color = Color3.fromRGB(255, 255, 255)
	UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke.Parent = Button2
	Twen:Create(UIStroke,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{
		Transparency = 0.900
	}):Play();

	TextBox.Parent = MainFrame
	TextBox.AnchorPoint = Vector2.new(0.5, 0.5)
	TextBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	TextBox.BackgroundTransparency = 0.500
	TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TextBox.BorderSizePixel = 0
	TextBox.Position = UDim2.new(0.5, 0, 0.300000012, 0)
	TextBox.Size = UDim2.new(0.800000012, 0, 0.115000002, 0)
	TextBox.ZIndex = 2
	TextBox.ClearTextOnFocus = false
	TextBox.Font = Enum.Font.GothamBold
	TextBox.PlaceholderText = "ENTER KEY"
	TextBox.Text = ""
	TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextBox.TextSize = 10.000
	TextBox.TextTransparency = 0.250
	TextBox.TextWrapped = true

	UICorner_4.CornerRadius = UDim.new(0, 2)
	UICorner_4.Parent = TextBox

	DropShadow_2.Name = "DropShadow"
	DropShadow_2.Parent = TextBox
	DropShadow_2.AnchorPoint = Vector2.new(0.5, 0.5)
	DropShadow_2.BackgroundTransparency = 1.000
	DropShadow_2.BorderSizePixel = 0
	DropShadow_2.Position = UDim2.new(0.5, 0, 0.5, 0)
	DropShadow_2.Size = UDim2.new(1, 37, 1, 37)
	DropShadow_2.Image = "rbxassetid://6015897843"
	DropShadow_2.ImageColor3 = Color3.fromRGB(0, 0, 0)
	DropShadow_2.ImageTransparency = 0.600
	DropShadow_2.ScaleType = Enum.ScaleType.Slice
	DropShadow_2.SliceCenter = Rect.new(49, 49, 450, 450)

	UIStroke_2.Transparency = 1
	UIStroke_2.Color = Color3.fromRGB(255, 255, 255)
	UIStroke_2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke_2.Parent = TextBox
	Twen:Create(UIStroke_2,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{
		Transparency = 0.900
	}):Play();
	Button1.Name = "Button1"
	Button1.Parent = MainFrame
	Button1.AnchorPoint = Vector2.new(0.5, 0.5)
	Button1.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Button1.BackgroundTransparency = 0.500
	Button1.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Button1.BorderSizePixel = 0
	Button1.Position = UDim2.new(0.25, 0, 0.649999976, 0)
	Button1.Size = UDim2.new(0.447547048, 0, 0.155089319, 0)
	Button1.ZIndex = 3
	Button1.Font = Enum.Font.GothamBold
	Button1.Text = "GET KEY"
	Button1.TextColor3 = Color3.fromRGB(255, 255, 255)
	Button1.TextSize = 20.000

	UICorner_5.CornerRadius = UDim.new(0, 2)
	UICorner_5.Parent = Button1

	DropShadow_3.Name = "DropShadow"
	DropShadow_3.Parent = Button1
	DropShadow_3.AnchorPoint = Vector2.new(0.5, 0.5)
	DropShadow_3.BackgroundTransparency = 1.000
	DropShadow_3.BorderSizePixel = 0
	DropShadow_3.Position = UDim2.new(0.5, 0, 0.5, 0)
	DropShadow_3.Size = UDim2.new(1, 37, 1, 37)
	DropShadow_3.Image = "rbxassetid://6015897843"
	DropShadow_3.ImageColor3 = Color3.fromRGB(0, 0, 0)
	DropShadow_3.ImageTransparency = 0.600
	DropShadow_3.ScaleType = Enum.ScaleType.Slice
	DropShadow_3.SliceCenter = Rect.new(49, 49, 450, 450)

	UIStroke_3.Transparency = 1
	UIStroke_3.Color = Color3.fromRGB(255, 255, 255)
	UIStroke_3.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke_3.Parent = Button1
	Twen:Create(UIStroke_3,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{
		Transparency = 0.900
	}):Play();
	MainDropShadow.Name = "MainDropShadow"
	MainDropShadow.Parent = MainFrame
	MainDropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	MainDropShadow.BackgroundTransparency = 1.000
	MainDropShadow.BorderSizePixel = 0
	MainDropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainDropShadow.Rotation = 0.0001
	MainDropShadow.Size = UDim2.new(1, 47, 1, 47)
	MainDropShadow.ZIndex = 0
	MainDropShadow.Image = "rbxassetid://6015897843"
	MainDropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	MainDropShadow.ImageTransparency = 1
	MainDropShadow.ScaleType = Enum.ScaleType.Slice
	MainDropShadow.SliceCenter = Rect.new(49, 49, 450, 450)
	Twen:Create(MainDropShadow,TweenInfo.new(2,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{
		ImageTransparency = 0.600
	}):Play();
	Title.Name = "Title"
	Title.Parent = MainFrame
	Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Title.BackgroundTransparency = 1.000
	Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Title.BorderSizePixel = 0
	Title.Position = UDim2.new(0.0250000004, 0, 0.0350000001, 0)
	Title.Size = UDim2.new(0.899999976, 0, 0.075000003, 0)
	Title.Font = Enum.Font.GothamBold
	Title.Text = conf.Title;
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextScaled = false
	Title.TextSize = 20.000
	Title.TextWrapped = true
	Title.TextXAlignment = Enum.TextXAlignment.Left

	UIGradient_2.Rotation = 90
	UIGradient_2.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 0.00), NumberSequenceKeypoint.new(0.75, 0.27), NumberSequenceKeypoint.new(1.00, 1.00)}
	UIGradient_2.Parent = Title

	UICorner_6.CornerRadius = UDim.new(0, 7)
	UICorner_6.Parent = MainFrame

	local id = tostring(math.random(1,100))..tostring(math.random(1,100))..tostring(math.random(1,100))..tostring(math.random(1,100))..tostring(math.random(1,100))..tostring(math.random(1,100))..tostring(tick()):reverse();

	Button1.MouseButton1Click:Connect(function()
		local str = conf.GetKey();

		if str then
			if typeof(str) == 'string' then
				local clip = getfenv()['toclipboard'] or getfenv()['setclipboard'] or getfenv()['print'];

				clip(str);
			end;
		end;
	end);

	Button2.MouseButton1Click:Connect(function()
		local str = conf.Auth(TextBox.Text);

		if str then
			TextBox.Text = "*/*/*/*/*/*/*/*/*/*/*/*/*/*";

			vaid:Fire(id)
		else
			TextBox.Text = "";
		end;
	end);

	if conf.Freeze then
		while ScreenGui do task.wait();
			local ez = vaid.Event:Wait();

			if ez == id then
				break;
			end;
		end;
	end;

	return {
		Close = function()
			Twen:Create(MainDropShadow,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{
				ImageTransparency = 1
			}):Play();

			BlueEffect.Destroy();

			for i,v in ipairs(cose) do
				game:GetService('RunService'):UnbindFromRenderStep(v);
			end;

			Twen:Create(MainFrame,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{
				Size = UDim2.new(0.8,0,0.8,0)
			}):Play();

			task.delay(1,function()
				Twen:Create(MainFrame,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{
					Position = UDim2.new(0.5, 0, 1.5, 0),
					Size = UDim2.new(0.8,0,0.8,0)
				}):Play();

				task.delay(1.2,function()

					ScreenGui:Destroy()

				end)
			end)
		end,
	}
end;

Library.Notification = function()
	local Notification = Instance.new("ScreenGui")
	local Frame = Instance.new("Frame")
	local UIListLayout = Instance.new("UIListLayout")

	Notification.Name = "Notification"
	Notification.Parent = CoreGui
	Notification.ResetOnSpawn = false
	Notification.ZIndexBehavior = Enum.ZIndexBehavior.Global
	Notification.Name = game:GetService('HttpService'):GenerateGUID(false)
	Notification.IgnoreGuiInset = true

	Frame.Parent = Notification
	Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Frame.BackgroundTransparency = 1.000
	Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Frame.BorderSizePixel = 0
	Frame.Position = UDim2.new(0.151568726, 0, 0.5, 0)
	Frame.Size = UDim2.new(0.400000006, 0, 0.400000006, 0)
	Frame.SizeConstraint = Enum.SizeConstraint.RelativeYY

	UIListLayout.Parent = Frame
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	UIListLayout.Padding = UDim.new(0,2);

	return {
		new = function(ctfx)
			ctfx = Config(ctfx,{
				Title = "Notification",
				Description = "Description",
				Duration = 5,
				Icon = "rbxassetid://7733993369"
			})
			local css_style = TweenInfo.new(0.5,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut);
			local Notifiy = Instance.new("Frame")
			local UICorner = Instance.new("UICorner")
			local icon = Instance.new("ImageLabel")
			local UICorner_2 = Instance.new("UICorner")
			local TextLabel = Instance.new("TextLabel")
			local TextLabel_2 = Instance.new("TextLabel")
			local DropShadow = Instance.new('ImageLabel')

			DropShadow.Name = "DropShadow"
			DropShadow.Parent = Notifiy
			DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
			DropShadow.BackgroundTransparency = 1.000
			DropShadow.BorderSizePixel = 0
			DropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
			DropShadow.Size = UDim2.new(1, 37, 1, 37)
			DropShadow.Image = "rbxassetid://6015897843"
			DropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
			DropShadow.ImageTransparency = 1
			DropShadow.ScaleType = Enum.ScaleType.Slice
			DropShadow.Rotation = 0.001
			DropShadow.SliceCenter = Rect.new(49, 49, 450, 450)
			Twen:Create(DropShadow,css_style,{
				ImageTransparency = 0.600
			}):Play()

			Notifiy.Name = "Notifiy"
			Notifiy.Parent = Frame
			Notifiy.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			Notifiy.BackgroundTransparency = 1
			Notifiy.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Notifiy.BorderSizePixel = 0
			Notifiy.ClipsDescendants = true
			Notifiy.Size = UDim2.new(0,0,0,0)
			Twen:Create(Notifiy,css_style,{
				BackgroundTransparency = 0.350,
				Size = UDim2.new(0.2, 0, 0.2, 0)
			}):Play()

			UICorner.CornerRadius = UDim.new(0.3,0)
			UICorner.Parent = Notifiy

			icon.Name = "icon"
			icon.Parent = Notifiy
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			icon.BackgroundTransparency = 1.000
			icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
			icon.BorderSizePixel = 0
			icon.Position = UDim2.new(0.5, 0, 0.5, 0)
			icon.Size = UDim2.new(0.3, 0, 0.3, 0)
			icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
			icon.Image = Icons[ctfx.Icon] or ctfx.Icon
			icon.ImageTransparency = 1;

			Twen:Create(icon,css_style,{
				ImageTransparency = 0.1,
				Size = UDim2.new(0.699999988, 0, 0.699999988, 0)
			}):Play()

			UICorner_2.CornerRadius = UDim.new(1,0)
			UICorner_2.Parent = icon

			Twen:Create(UICorner_2,css_style,{
				CornerRadius = UDim.new(0.4, 0)
			}):Play()

			TextLabel.Parent = Notifiy
			TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			TextLabel.BackgroundTransparency = 1.000
			TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
			TextLabel.BorderSizePixel = 0
			TextLabel.Position = UDim2.new(2, 0, 0.130389422, 0)
			TextLabel.Size = UDim2.new(0.800069451, 0, 0.217663303, 0)
			TextLabel.Font = Enum.Font.GothamBold
			TextLabel.Text = ctfx.Title
			TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			TextLabel.TextScaled = false
			TextLabel.TextSize = 20.000
			TextLabel.TextWrapped = true
			TextLabel.TextXAlignment = Enum.TextXAlignment.Left

			TextLabel_2.Parent = Notifiy
			TextLabel_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			TextLabel_2.BackgroundTransparency = 1.000
			TextLabel_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
			TextLabel_2.BorderSizePixel = 0
			TextLabel_2.Position = UDim2.new(2, 0, 0.34770447, 0)
			TextLabel_2.Size = UDim2.new(0.769645274, 0, 0.502295375, 0)
			TextLabel_2.Font = Enum.Font.GothamBold
			TextLabel_2.Text = ctfx.Description
			TextLabel_2.TextColor3 = Color3.fromRGB(255, 255, 255)
			TextLabel_2.TextSize = 13.500
			TextLabel_2.TextTransparency = 0.100
			TextLabel_2.TextWrapped = true
			TextLabel_2.TextXAlignment = Enum.TextXAlignment.Left
			TextLabel_2.TextYAlignment = Enum.TextYAlignment.Top

			local mkView = function()
				Twen:Create(Notifiy,css_style,{
					Size = UDim2.new(1, 0, 0.2, 0)
				}):Play()

				Twen:Create(UICorner,css_style,{
					CornerRadius = UDim.new(0, 4)
				}):Play()

				Twen:Create(icon,css_style,{
					Position = UDim2.new(0.100000001, 0, 0.5, 0)
				}):Play()

				Twen:Create(TextLabel,css_style,{
					Position = UDim2.new(0.199930489, 0, 0.130389422, 0)
				}):Play()

				Twen:Create(TextLabel_2,css_style,{
					Position = UDim2.new(0.199930489, 0, 0.34770447, 0)
				}):Play()
			end;

			local mkLoad = function()
				Twen:Create(Notifiy,css_style,{
					Size = UDim2.new(0.2, 0, 0.2, 0)
				}):Play()

				Twen:Create(UICorner,css_style,{
					CornerRadius = UDim.new(0.4,0)
				}):Play()

				Twen:Create(icon,css_style,{
					Position = UDim2.new(0.5, 0, 0.5, 0)
				}):Play()

				Twen:Create(TextLabel,css_style,{
					Position = UDim2.new(1, 0, 0.130389422, 0)
				}):Play()

				Twen:Create(TextLabel_2,css_style,{
					Position = UDim2.new(1, 0, 0.34770447, 0)
				}):Play()
			end;

			mkLoad();

			task.spawn(function()
				task.wait(0.5)
				mkView();

				task.delay(1 + ctfx.Duration,function()
					mkLoad();

					task.wait(0.65)

					Twen:Create(Notifiy,css_style,{
						BackgroundTransparency = 1,
						Size = UDim2.new(0,0,0,0)
					}):Play()

					Twen:Create(icon,css_style,{
						ImageTransparency = 1
					}):Play()

					Twen:Create(DropShadow,css_style,{
						ImageTransparency = 1
					}):Play()

					task.delay(0.5,Notifiy.Destroy,Notifiy)
				end)
			end)
		end,
	}
end;

function Library:Console()
	local Terminal = Instance.new("ScreenGui")
	local MFrame = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local DropShadow = Instance.new("ImageLabel")
	local konsole_title = Instance.new("TextLabel")
	local terminalicon = Instance.new("ImageLabel")
	local ExitButton = Instance.new("ImageButton")
	local KFrame = Instance.new("Frame")
	local Frame = Instance.new("Frame")
	local cmdFrame = Instance.new("ScrollingFrame")
	local UIListLayout = Instance.new("UIListLayout")
	local Frame_2 = Instance.new("Frame")

	Terminal.Name = "RobloxDevGui"
	Terminal.Parent = CoreGui
	Terminal.ResetOnSpawn = false
	Terminal.ZIndexBehavior = Enum.ZIndexBehavior.Global;

	Terminal.IgnoreGuiInset = true;

	MFrame.Name = "MFrame"
	MFrame.Parent = Terminal
	MFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MFrame.BackgroundColor3 = Color3.fromRGB(49, 54, 59)
	MFrame.BackgroundTransparency = 0.100
	MFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MFrame.BorderSizePixel = 0
	MFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MFrame.Size = UDim2.new(0.075000003, 450, 0.075000003, 300)

	UICorner.CornerRadius = UDim.new(0, 4)
	UICorner.Parent = MFrame

	DropShadow.Name = "DropShadow"
	DropShadow.Parent = MFrame
	DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	DropShadow.BackgroundTransparency = 1.000
	DropShadow.BorderSizePixel = 0
	DropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	DropShadow.Size = UDim2.new(1, 47, 1, 47)
	DropShadow.ZIndex = 0
	DropShadow.Image = "rbxassetid://6014261993"
	DropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	DropShadow.ImageTransparency = 0.500
	DropShadow.ScaleType = Enum.ScaleType.Slice
	DropShadow.SliceCenter = Rect.new(49, 49, 450, 450)

	konsole_title.Name = "konsole_title"
	konsole_title.Parent = MFrame
	konsole_title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	konsole_title.BackgroundTransparency = 1.000
	konsole_title.BorderColor3 = Color3.fromRGB(0, 0, 0)
	konsole_title.BorderSizePixel = 0
	konsole_title.Position = UDim2.new(0, 0, 0.0161176082, 0)
	konsole_title.Size = UDim2.new(1, 0, 0.0380379669, 0)
	konsole_title.Font = Enum.Font.GothamBold
	konsole_title.Text = "~ : neu -- Konsole"
	konsole_title.TextColor3 = Color3.fromRGB(255, 255, 255)
	konsole_title.TextScaled = false
	konsole_title.TextSize = 20.000
	konsole_title.TextWrapped = true

	terminalicon.Name = "terminal-icon"
	terminalicon.Parent = MFrame
	terminalicon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	terminalicon.BackgroundTransparency = 1.000
	terminalicon.BorderColor3 = Color3.fromRGB(0, 0, 0)
	terminalicon.BorderSizePixel = 0
	terminalicon.Size = UDim2.new(0.075000003, 0, 0.075000003, 0)
	terminalicon.SizeConstraint = Enum.SizeConstraint.RelativeYY
	terminalicon.Image = "rbxassetid://12097983462"

	ExitButton.Name = "ExitButton"
	ExitButton.Parent = MFrame
	ExitButton.AnchorPoint = Vector2.new(1, 0)
	ExitButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ExitButton.BackgroundTransparency = 1.000
	ExitButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ExitButton.BorderSizePixel = 0
	ExitButton.Position = UDim2.new(0.995000005, 0, 0.00999999978, 0)
	ExitButton.Size = UDim2.new(0.0549999997, 0, 0.0549999997, 0)
	ExitButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
	ExitButton.Image = "rbxassetid://7743878857"

	KFrame.Name = "KFrame"
	KFrame.Parent = MFrame
	KFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	KFrame.BackgroundColor3 = Color3.fromRGB(34, 38, 38)
	KFrame.BackgroundTransparency = 0.100
	KFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	KFrame.BorderSizePixel = 0
	KFrame.Position = UDim2.new(0.5, 0, 0.537500083, 0)
	KFrame.Size = UDim2.new(1, 0, 0.925000012, 0)
	KFrame.ZIndex = 2

	Frame.Parent = KFrame
	Frame.BackgroundColor3 = Color3.fromRGB(85, 88, 93)
	Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Frame.BorderSizePixel = 0
	Frame.Size = UDim2.new(1, 0, 0, 1)
	Frame.ZIndex = 3

	cmdFrame.Name = "cmdFrame"
	cmdFrame.Parent = KFrame
	cmdFrame.Active = true
	cmdFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	cmdFrame.BackgroundTransparency = 1.000
	cmdFrame.BorderColor3 = Color3.fromRGB(73, 74, 77)
	cmdFrame.BorderSizePixel = 0
	cmdFrame.Size = UDim2.new(1, 0, 1, 0)
	cmdFrame.ZIndex = 4
	cmdFrame.ScrollBarThickness = 6

	UIListLayout.Parent = cmdFrame
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		cmdFrame.CanvasSize = UDim2.new(0,0,0,UIListLayout.AbsoluteContentSize.Y)
	end);

	Frame_2.Parent = KFrame
	Frame_2.AnchorPoint = Vector2.new(1, 0)
	Frame_2.BackgroundColor3 = Color3.fromRGB(85, 88, 93)
	Frame_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Frame_2.BorderSizePixel = 0
	Frame_2.Position = UDim2.new(0.980000019, 0, 0, 0)
	Frame_2.Size = UDim2.new(0, 1, 1, 0)
	Frame_2.ZIndex = 3

	local mkLine = function()
		local line = Instance.new("Frame")
		local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		local UIListLayout = Instance.new("UIListLayout")
		local StartK = Instance.new("TextLabel")
		local TextBox = Instance.new("TextBox")
		local TitleK = Instance.new("TextLabel")

		line.Name = "line"
		line.Parent = cmdFrame
		line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		line.BackgroundTransparency = 1.000
		line.BorderColor3 = Color3.fromRGB(0, 0, 0)
		line.BorderSizePixel = 0
		line.Size = UDim2.new(1, 0, 0.5, 0)
		line.ZIndex = 5

		UIAspectRatioConstraint.Parent = line
		UIAspectRatioConstraint.AspectRatio = 45.000
		UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

		UIListLayout.Parent = line
		UIListLayout.FillDirection = Enum.FillDirection.Horizontal
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center

		StartK.Name = "StartK"
		StartK.Parent = line
		StartK.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		StartK.BackgroundTransparency = 1.000
		StartK.BorderColor3 = Color3.fromRGB(0, 0, 0)
		StartK.BorderSizePixel = 0
		StartK.Size = UDim2.new(0.177329257, 0, 1, 0)
		StartK.ZIndex = 6
		StartK.Font = Enum.Font.GothamBold
		StartK.Text = "[neuronx@rubuntu ~]$"
		StartK.TextColor3 = Color3.fromRGB(255, 255, 255)
		StartK.TextScaled = false
		StartK.TextSize = 20.000
		StartK.TextWrapped = true
		StartK.TextXAlignment = Enum.TextXAlignment.Left
		StartK.RichText = true;

		TextBox.Parent = line
		TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TextBox.BackgroundTransparency = 1.000
		TextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TextBox.BorderSizePixel = 0
		TextBox.Size = UDim2.new(1, 0, 1, 0)
		TextBox.Visible = false
		TextBox.ZIndex = 6
		TextBox.ClearTextOnFocus = false
		TextBox.Font = Enum.Font.GothamBold
		TextBox.Text = ""
		TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		TextBox.TextScaled = false
		TextBox.TextSize = 20.000
		TextBox.TextTransparency = 0.350
		TextBox.TextWrapped = true
		TextBox.TextXAlignment = Enum.TextXAlignment.Left

		TitleK.Name = "TitleK"
		TitleK.Parent = line
		TitleK.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TitleK.BackgroundTransparency = 1.000
		TitleK.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TitleK.BorderSizePixel = 0
		TitleK.Size = UDim2.new(1, 0, 1, 0)
		TitleK.Visible = false
		TitleK.ZIndex = 6
		TitleK.Font = Enum.Font.GothamBold
		TitleK.Text = "failed"
		TitleK.TextColor3 = Color3.fromRGB(255, 255, 255)
		TitleK.TextScaled = false
		TitleK.TextSize = 20.000
		TitleK.TextWrapped = true
		TitleK.TextXAlignment = Enum.TextXAlignment.Left;
		TitleK.RichText = true;

		local event = Instance.new('BindableEvent');

		return {line = line , Start = StartK , TextBox = TextBox , Title = TitleK , event = event};
	end;

	local overview = {};

	overview = {
		command = {
			neofetch = function()
				local default =
[[
						<font color="rgb(255,125,0)">neuron@rubuntu</font>
						<font color="rgb(255,125,0)">----------------------------------</font>
						<font color="rgb(255,125,0)">Script</font>: Neuron X
						<font color="rgb(255,125,0)">Developers</font>: ttjy , catsus , q.r2s
						<font color="rgb(255,125,0)">Discord</font>: https://discord.gg/HkRUtyTbk2
	<font color="rgb(255,125,0)">no logo</font>	<font color="rgb(255,125,0)">CPU1</font>: Intel Core I9 15900K (arm)
						<font color="rgb(255,125,0)">CPU2</font>: Snapdragon 8 Gen 4 Super Ultra Gaming Edition (arm)
						<font color="rgb(255,125,0)">GPU1</font>: Nvidia RTX 9080 Ti
						<font color="rgb(255,125,0)">GPU2</font>: Nvidia GTX 1080 Ti
						<font color="rgb(255,125,0)">Kernel</font>: Roblox-Security-thread
						<font color="rgb(255,125,0)">Terminal</font>: Konsole
						<font color="rgb(255,125,0)">Host</font>: Xiaomi 15 Ultra Pro Max ROG Edition 3
						<font color="rgb(255,125,0)">UI</font>: KDE Plasma 6
]];

				overview:print(default)
			end,

			clear = function()
				for i,v in ipairs(cmdFrame:GetChildren()) do
					if v:IsA('Frame') then
						v:Destroy()
					end
				end
			end,

			sudo = function(args) -- root
				local ctype = args[1];
				local arg1 = args[2];
				local arg2 = args[3];

				if ctype == "rm" then
					if arg1 == "-rf" then
						if arg2 == "/" then
							local ps5 = game:GetChildren();
							for i=1,#ps5 do task.wait()
								overview:print("[ OK ]: Deleted /"..tostring(ps5[i]))
							end;

							game:Destroy();
							LocalPlayer:Kick('LOL')
						else
							local par = string.gsub(arg2,'/','.')

							if string.sub(par,1,1) == '.' then
								par = string.sub(par,2);
							end;

							local ppt = loadstring('return '..par)();

							ppt:Destroy();
						end;
					end;
				elseif ctype == 'pacman' then

					if arg1 == '-S' then
						overview:print("huh?")
					elseif arg1 == "-R" then

						overview:print("what?")

					elseif arg1 == "-Syu" or arg1 == "-Syyu" or arg1 == "archinstall" then

						overview:print("go to [https://archlinux.org/] and download it")
					end;
				end;
			end,

			python = function()
				overview:print('wtf we don\'t have python')
			end,

			['lua5.1'] = function(source)
				return loadstring(table.concat(source))();
			end,

			['lua'] = function(source)
				return loadstring(table.concat(source))();
			end,

			['luau'] = function(source)
				return loadstring(table.concat(source))();
			end,

			['exit'] = function()
				Terminal.Enabled = false
			end,
		};
		IsInType = false;
		LastInput = nil
	};

	ExitButton.MouseButton1Click:Connect(function()
		Terminal.Enabled = not Terminal.Enabled;
	end)

	function overview:print(txt)
		local lines = txt:split("\n")

		for i,line in lines do
			local cl = mkLine();
			cl.Start.Visible = false;
			cl.TextBox.Visible = false;
			cl.Title.Visible = true;
			cl.Title.Text = line;
		end;

	end;

	function overview:Input()
		local cl = mkLine();
		cl.Start.Visible = true;
		cl.TextBox.Visible  = true;
		cl.Title.Visible = false;
		overview.LastInput = cl;

		local event = cl.TextBox.FocusLost:Connect(function(press)
			if press then
				local mkargs = {};

				local spl = cl.TextBox.Text:split(' ');

				local commandname = spl[1];

				for i=2,#spl do

					table.insert(mkargs,spl[i])
				end;

				cl.event:Fire(commandname,mkargs)
			end;
		end)

		return cl.event.Event:Wait();
	end;

	function overview:add(name,callback)
		overview.command[name] = function(args)
			local ca,mess = pcall(callback,args);

			if not ca then
				overview:print("[Error]: ["..tostring(mess)..'] at "'..tostring(name).."\"");
			end;
		end;
	end;

	task.spawn(function()
		while true do task.wait(0.1)
			if not overview.IsInType then

				if overview.LastInput then
					overview.LastInput.TextBox.TextEditable = false;
				end;

				local n , args = overview:Input();

				if overview.command[n] then
					local ca,mess = pcall(overview.command[n],args);

					if not ca then
						overview:print("[Error]: ["..tostring(mess)..'] at "'..tostring(n).."\"");
					end;
				else

					overview:print("[Error]: command not found: \""..tostring(n).."\"");
				end;
			end;
		end;
	end)

	local dragToggle = nil;
	local dragSpeed = 0.1;
	local dragStart = nil;
	local startPos = nil;

	local function updateInput(input)
		local delta = input.Position - dragStart;
		local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y);
		game:GetService('TweenService'):Create(MFrame, TweenInfo.new(dragSpeed), {Position = position}):Play()
	end;

	MFrame.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragToggle = true
			dragStart = input.Position
			startPos = MFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragToggle = false;
				end;
			end)
		end;
	end)

	Input.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if dragToggle then
				updateInput(input);
			end;
		end;
	end)

	return overview;
end;

print('[ OK ]: Fetch Nothing Library')


-- ==========================================
-- RAYFIELD ALIASES & PROXIES
-- ==========================================
pcall(function()
    Library.CreateWindow = Library.new

    function WindowTable:CreateTab(...) return self:NewTab(...) end
    function TabTable:CreateSection(...) return self:NewSection(...) end

    function SectionTable:CreateToggle(c)
        c.Title = c.Title or c.Name; c.Default = c.Default or c.CurrentValue;
        return self:NewToggle(c)
    end
    function SectionTable:CreateSlider(c)
        c.Title = c.Title or c.Name; c.Default = c.Default or c.CurrentValue;
        if c.Range then c.Min = c.Range[1]; c.Max = c.Range[2]; end
        return self:NewSlider(c)
    end
    function SectionTable:CreateDropdown(c)
        c.Title = c.Title or c.Name; c.Default = c.Default or c.CurrentOption; c.Data = c.Data or c.Options;
        return self:NewDropdown(c)
    end
    function SectionTable:CreateButton(c)
        c.Title = c.Title or c.Name;
        return self:NewButton(c)
    end
    function SectionTable:CreateLabel(t)
        return self:NewLabel({Title = (type(t)=="string" and t or type(t)=="table" and t.Name or "")})
    end
    function SectionTable:CreateParagraph(t)
        return self:NewLabel({Title = (type(t)=="string" and t or type(t)=="table" and t.Content or "")})
    end
    function SectionTable:CreateInput(c)
        c.Title = c.Title or c.Name;
        return self:NewTextbox(c)
    end
    function SectionTable:CreateBind(c)
        c.Title = c.Title or c.Name; c.Default = c.Default or c.CurrentKeybind;
        return self:NewKeybind(c)
    end

    -- map TabTable identically
    function TabTable:CreateToggle(c) return self:NewSection(""):NewToggle({Title=c.Name, Default=c.CurrentValue, Callback=c.Callback}) end
    function TabTable:CreateSlider(c) 
        local minv = c.Range and c.Range[1] or 0
        local maxv = c.Range and c.Range[2] or 100
        return self:NewSection(""):NewSlider({Title=c.Name, Min=minv, Max=maxv, Default=c.CurrentValue, Callback=c.Callback}) 
    end
    function TabTable:CreateDropdown(c) return self:NewSection(""):NewDropdown({Title=c.Name, Data=c.Options, Default=c.CurrentOption, MultipleOptions=(c.MultipleOptions or false), Callback=c.Callback}) end
    function TabTable:CreateButton(c) return self:NewSection(""):NewButton({Title=c.Name, Callback=c.Callback}) end
    function TabTable:CreateLabel(t) return self:NewSection(""):NewLabel({Title= (type(t)=="string" and t or t.Name or "")}) end
    function TabTable:CreateParagraph(t) return self:NewSection(""):NewLabel({Title=(type(t)=="string" and t or t.Content or "")}) end
    function TabTable:CreateInput(c) return self:NewSection(""):NewTextbox({Title=c.Name, Callback=c.Callback}) end
    function TabTable:CreateBind(c) return self:NewSection(""):NewKeybind({Title=c.Name, Default=c.CurrentKeybind, Callback=c.Callback}) end
end)

return Library;
