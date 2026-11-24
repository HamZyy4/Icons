-- ForktUI Icons v2
-- Icon packs remain independently maintained in their own folders.

local RAW_BASE = "https://raw.githubusercontent.com/HamZyy4/Icons/refs/heads/main/"

local function isExecutor()
	return type(request) == "function"
		or type(request) == "table"
		or type(http_request) == "function"
		or (type(syn) == "table" and type(syn.request) == "function")
end

local function getSource(url)
	local requestFn = type(request) == "function" and request
		or type(http_request) == "function" and http_request
		or (type(syn) == "table" and type(syn.request) == "function" and syn.request)

	if requestFn then
		local success, response = pcall(requestFn, { Url = url, Method = "GET" })
		if success and type(response) == "table" and type(response.Body) == "string" then
			return response.Body
		end
	end

	local success, result = pcall(function()
		return game:HttpGet(url)
	end)
	if success and type(result) == "string" then
		return result
	end

	warn("[ForktUI Icons] HTTP request failed:", result)
	return nil
end

local function executeSource(source)
	if type(source) ~= "string" or type(loadstring) ~= "function" then
		return nil
	end

	local chunk, compileError = loadstring(source)
	if not chunk then
		error(compileError or "Icon pack compilation failed")
	end
	return chunk()
end

local function loadRemotePack(packName)
	local source = getSource(RAW_BASE .. packName .. "/dist/Icons.lua")
	if not source then
		return nil
	end

	local success, result = pcall(executeSource, source)
	if success and type(result) == "table" then
		return result
	end
	if not success then
		warn("[ForktUI Icons] Could not load '" .. packName .. "':", result)
	end
	return nil
end

local function loadPack(packName, localLoader)
	if isExecutor() then
		local remotePack = loadRemotePack(packName)
		if remotePack then
			return remotePack
		end
	end

	-- Keep literal module paths so Rojo/DarkLua can resolve the existing pack folders.
	local success, result = pcall(localLoader)
	if success and type(result) == "table" then
		return result
	end

	warn("[ForktUI Icons] Pack '" .. packName .. "' is unavailable:", result)
	return { Icons = {}, Spritesheets = {} }
end

local IconModule = {
	IconsType = "lucide",
	New = nil,
	IconThemeTag = nil,
	Icons = {},
}

-- Load only the family that is actually requested. This avoids six HTTP fetches
-- when an executor starts but the project only uses one icon family.
local PACK_LOADERS = {
	lucide = function() return require("./lucide/dist/Icons") end,
	solar = function() return require("./solar/dist/Icons") end,
	craft = function() return require("./craft/dist/Icons") end,
	geist = function() return require("./geist/dist/Icons") end,
	sfsymbols = function() return require("./sfsymbols/dist/Icons") end,
	gravity = function() return require("./gravity/dist/Icons") end,
}

local function getPack(packName)
	local pack = IconModule.Icons[packName]
	if type(pack) == "table" then
		return pack
	end

	local loader = PACK_LOADERS[packName]
	if not loader then
		return nil
	end

	pack = loadPack(packName, loader)
	IconModule.Icons[packName] = pack
	return pack
end

local function parseIconString(iconString)
	if type(iconString) ~= "string" then
		return nil, nil
	end

	local splitIndex = iconString:find(":", 1, true)
	if splitIndex then
		return iconString:sub(1, splitIndex - 1), iconString:sub(splitIndex + 1)
	end

	return nil, iconString
end

local function normalizeImageId(imageId)
	if type(imageId) == "number" then
		return "rbxassetid://" .. tostring(imageId)
	end
	return imageId
end

function IconModule.AddIcons(packName, iconsData)
	if type(packName) ~= "string" or packName == "" then
		error("AddIcons: packName must be a non-empty string", 2)
	end
	if type(iconsData) ~= "table" then
		error("AddIcons: iconsData must be a table", 2)
	end

	local pack = getPack(packName)
	if type(pack) ~= "table" or type(pack.Icons) ~= "table" then
		pack = { Icons = {}, Spritesheets = {} }
		IconModule.Icons[packName] = pack
	end
	pack.Spritesheets = type(pack.Spritesheets) == "table" and pack.Spritesheets or {}

	for iconName, iconValue in pairs(iconsData) do
		if type(iconName) ~= "string" or iconName == "" then
			warn("AddIcons: skipped an icon with an invalid name")
		elseif type(iconValue) == "number" or (type(iconValue) == "string" and iconValue:match("^rbxassetid://")) then
			local imageId = normalizeImageId(iconValue)
			pack.Icons[iconName] = {
				Image = imageId,
				ImageRectSize = Vector2.new(0, 0),
				ImageRectPosition = Vector2.new(0, 0),
				Parts = nil,
			}
			pack.Spritesheets[imageId] = imageId
		elseif type(iconValue) == "table" then
			local imageId = normalizeImageId(iconValue.Image)
			if imageId and iconValue.ImageRectSize and iconValue.ImageRectPosition then
				pack.Icons[iconName] = {
					Image = imageId,
					ImageRectSize = iconValue.ImageRectSize,
					ImageRectPosition = iconValue.ImageRectPosition,
					Parts = iconValue.Parts,
				}
				pack.Spritesheets[imageId] = imageId
			else
				warn("AddIcons: invalid spritesheet data for icon '" .. iconName .. "'")
			end
		else
			warn("AddIcons: unsupported data type for icon '" .. iconName .. "': " .. type(iconValue))
		end
	end

	return pack
end

function IconModule.SetIconsType(iconType)
	if type(iconType) ~= "string" or iconType == "" then
		return false
	end
	IconModule.IconsType = iconType
	return true
end

function IconModule.Init(newFunction, iconThemeTag)
	if newFunction ~= nil and type(newFunction) ~= "function" then
		error("Init: newFunction must be a function or nil", 2)
	end
	IconModule.New = newFunction
	IconModule.IconThemeTag = iconThemeTag
	return IconModule
end

function IconModule.Icon(icon, iconType, defaultFormat)
	local parsedType, iconName = parseIconString(icon)
	if not iconName then
		return nil
	end

	local targetType = parsedType or iconType or IconModule.IconsType
	local pack = getPack(targetType)
	if type(pack) ~= "table" then
		return nil
	end

	if type(pack.Icons) == "table" then
		local iconData = pack.Icons[iconName]
		if type(iconData) == "table" and iconData.Image then
			local imageId = iconData.Image
			local sheet = pack.Spritesheets and pack.Spritesheets[tostring(imageId)] or imageId
			local result = { sheet, iconData }
			return defaultFormat == false and imageId or result
		end
	end

	local directImage = pack[iconName]
	if type(directImage) == "string" and directImage:find("rbxassetid://", 1, true) then
		if defaultFormat == false then
			return directImage
		end
		return {
			directImage,
			{
				ImageRectSize = Vector2.new(0, 0),
				ImageRectPosition = Vector2.new(0, 0),
			},
		}
	end

	return nil
end

function IconModule.GetIcon(icon, iconType)
	return IconModule.Icon(icon, iconType, false)
end

function IconModule.Icon2(icon, iconType, defaultFormat)
	return IconModule.Icon(icon, iconType, defaultFormat)
end

function IconModule.Image(config)
	if type(config) ~= "table" then
		error("Image: icon configuration must be a table", 2)
	end

	local iconData = IconModule.Icon(config.Icon, config.Type, true)
	if not iconData then
		return nil
	end

	local colors = type(config.Colors) == "table" and config.Colors
		or { IconModule.IconThemeTag or Color3.new(1, 1, 1), Color3.new(1, 1, 1) }
	local transparency = type(config.Transparency) == "table" and config.Transparency or { 0, 0 }
	local isAssetId = type(iconData) == "string"
	local iconInfo = not isAssetId and iconData[2] or nil

	local primaryColor = colors[1]
	local primaryTransparency = transparency[1]
	local properties = {
		Size = config.Size or UDim2.new(0, 24, 0, 24),
		BackgroundTransparency = 1,
		Image = isAssetId and iconData or iconData[1],
		ImageColor3 = typeof(primaryColor) == "Color3" and primaryColor or nil,
		ImageTransparency = type(primaryTransparency) == "number" and math.clamp(primaryTransparency, 0, 1) or nil,
	}

	if iconInfo then
		properties.ImageRectSize = iconInfo.ImageRectSize
		properties.ImageRectOffset = iconInfo.ImageRectPosition
	end
	if type(primaryColor) == "string" or type(primaryTransparency) == "string" then
		properties.ThemeTag = {
			ImageColor3 = type(primaryColor) == "string" and primaryColor or nil,
			ImageTransparency = type(primaryTransparency) == "string" and primaryTransparency or nil,
		}
	end

	local frame
	if IconModule.New then
		frame = IconModule.New("ImageLabel", properties)
	else
		frame = Instance.new("ImageLabel")
		for property, value in pairs(properties) do
			if value ~= nil then
				frame[property] = value
			end
		end
	end

	if iconInfo and type(iconInfo.Parts) == "table" then
		for index, part in ipairs(iconInfo.Parts) do
			local partData = IconModule.Icon(part, config.Type, true)
			if partData then
				local partInfo = type(partData) == "table" and partData[2] or nil
				local partColor = colors[index + 1]
				local partTransparency = transparency[index + 1]
				local partProperties = {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = type(partData) == "string" and partData or partData[1],
					ImageColor3 = typeof(partColor) == "Color3" and partColor or nil,
					ImageTransparency = type(partTransparency) == "number" and math.clamp(partTransparency, 0, 1) or nil,
				}
				if partInfo then
					partProperties.ImageRectSize = partInfo.ImageRectSize
					partProperties.ImageRectOffset = partInfo.ImageRectPosition
				end
				if type(partColor) == "string" or type(partTransparency) == "string" then
					partProperties.ThemeTag = {
						ImageColor3 = type(partColor) == "string" and partColor or nil,
						ImageTransparency = type(partTransparency) == "string" and partTransparency or nil,
					}
				end

				if IconModule.New then
					partProperties.Parent = frame
					IconModule.New("ImageLabel", partProperties)
				else
					local partFrame = Instance.new("ImageLabel")
					for property, value in pairs(partProperties) do
						if value ~= nil then
							partFrame[property] = value
						end
					end
					partFrame.Parent = frame
				end
			end
		end
	end

	return {
		Icon = config.Icon,
		Type = config.Type,
		Colors = colors,
		Transparency = transparency,
		Size = config.Size or UDim2.new(0, 24, 0, 24),
		IconFrame = frame,
	}
end

return IconModule
