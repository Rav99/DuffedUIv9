local _G = _G
local math_floor = _G.math.floor
local select = _G.select
local string_find = _G.string.find
local string_format = _G.string.format
local string_lower = _G.string.lower
local table_insert = _G.table.insert
local table_sort = _G.table.sort
local tonumber = _G.tonumber
local type = _G.type
local unpack = _G.unpack

local APPLY = _G.APPLY
local CLOSE = _G.CLOSE
local COLOR = _G.COLOR
local CreateFrame = _G.CreateFrame
local GameMenuFrame = _G.GameMenuFrame
local GameTooltip = _G.GameTooltip
local GetLocale = _G.GetLocale
local GetRealmName = _G.GetRealmName
local HideUIPanel = _G.HideUIPanel
local PlaySound = _G.PlaySound
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS
local ReloadUI = _G.ReloadUI
local ShowUIPanel = _G.ShowUIPanel
local UIParent = _G.UIParent
local UNKNOWN = _G.UNKNOWN
local UnitClass = _G.UnitClass
local UnitName = _G.UnitName

local DuffedUIConfig = CreateFrame('Frame', 'DuffedUIConfig', UIParent)
DuffedUIConfig.Functions = {}
local GroupPages = {}
local Locale = GetLocale()
local Class = select(2, UnitClass('player'))
local Colors = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[Class] or RAID_CLASS_COLORS[Class]

local DropDownMenus = {}

if (Locale == 'enGB') then Locale = 'enUS' end

local myPlayerRealm = GetRealmName()
local myPlayerName  = UnitName('player')

local s = 1 or 1
function DuffedUIConfig:SetOption(group, option, value)
	local myPlayerRealm = GetRealmName()
	local myPlayerName = UnitName('player')

	local mergesettings
	if DuffedUIConfigPrivate == DuffedUIConfigPublic then mergesettings = true else mergesettings = false end

	if DuffedUIConfigAll[myPlayerRealm][myPlayerName] == true then
		if not DuffedUIConfigPrivate then DuffedUIConfigPrivate = {} end
		if not DuffedUIConfigPrivate[group] then DuffedUIConfigPrivate[group] = {} end
		DuffedUIConfigPrivate[group][option] = value
	else
		if mergesettings == true then
			if not DuffedUIConfigPrivate then DuffedUIConfigPrivate = {} end
			if not DuffedUIConfigPrivate[group] then DuffedUIConfigPrivate[group] = {} end
			DuffedUIConfigPrivate[group][option] = value
		end
		if not DuffedUIConfigPublic then DuffedUIConfigPublic = {} end
		if not DuffedUIConfigPublic[group] then DuffedUIConfigPublic[group] = {} end
		DuffedUIConfigPublic[group][option] = value
	end
end

function DuffedUIConfig:SetCallback(group, option, func)
	if (not self.Functions[group]) then self.Functions[group] = {} end
	self.Functions[group][option] = func
end

DuffedUIConfig.ColorDefaults = {
	-- General
	['general'] = {
		['backdropcolor'] = {.05, .05, .05},
		['bordercolor'] = {.125, .125, .125}
	},
	-- Classtimer
	['classtimer'] = {
		['playercolor'] = {.2, .2, .2, 1},
		['targetbuffcolor'] = {70/255, 150/255, 70/255, 1},
		['targetdebuffcolor'] = {150/255, 30/255, 30/255, 1},
		['trinketcolor'] = {75/255, 75/255, 75/255, 1},
		['separatorcolor'] = {0, 0, 0, .5}
	},
	-- Castbar
	['castbar'] = {
		['color'] = {.31, .45, .63, .5}
	},
	-- Unitframes
	['unitframes'] = {
		['healthbarcolor'] = {.125, .125, .125, 1},
		['deficitcolor'] = {0, 0, 0}
	},
}

function DuffedUIConfig:UpdateColorDefaults()
	-- General
	self.ColorDefaults.general.backdropcolor = {.05, .05, .05}
	self.ColorDefaults.general.bordercolor = {.125, .125, .125}
	-- Classtimer
	self.ColorDefaults.classtimer.playercolor = {.2, .2, .2, 1}
	self.ColorDefaults.classtimer.targetbuffcolor = {70/255, 150/255, 70/255, 1}
	self.ColorDefaults.classtimer.targetdebuffcolor = {150/255, 30/255, 30/255, 1}
	self.ColorDefaults.classtimer.trinketcolor = {75/255, 75/255, 75/255, 1}
	self.ColorDefaults.classtimer.separatorcolor = {0, 0, 0, .5}
	-- Castbar
	self.ColorDefaults.castbar.color = {.31, .45, .63, .5}
	-- Unitframes
	self.ColorDefaults.unitframes.healthbarcolor = {.125, .125, .125, 1}
	self.ColorDefaults.unitframes.deficitcolor = {0, 0, 0}
end

-- Filter unwanted groups
DuffedUIConfig.Filter = {
	['media'] = true,
	['OrderedIndex'] = true,
	['uifonts'] = true,
	['uitextures'] = true,
}

local function TrimHex(s)
	local Subbed = string.match(s, '|c%x%x%x%x%x%x%x%x(.-)|r')
	return Subbed or s
end

local function GetOrderedIndex(t)
	local OrderedIndex = {}

	for key in pairs(t) do table_insert(OrderedIndex, key) end
	table_sort(OrderedIndex, function(a, b) return TrimHex(a) < TrimHex(b) end)
	return OrderedIndex
end

local function OrderedNext(t, state)
	local OrderedIndex = GetOrderedIndex(t)
	local Key

	if (state == nil) then
		Key = OrderedIndex[1]
		return Key, t[Key]
	end

	for i = 1, #OrderedIndex do
		if (OrderedIndex[i] == state) then Key = OrderedIndex[i + 1] end
	end
	if Key then return Key, t[Key] end
	return
end

local function PairsByKeys(t) return OrderedNext, t, nil end

local function ControlOnEnter(self)
	local D = DuffedUI[1]

	GameTooltip:SetOwner(self, 'NONE')
	GameTooltip:SetPoint(D['GetAnchors'](self))
	GameTooltip:ClearLines()
	GameTooltip:AddLine(self.Tooltip, nil, nil, nil, 1)
	GameTooltip:Show()
end

local function ControlOnLeave() GameTooltip:Hide() end

local function SetControlInformation(control, group, option)
	if (not DuffedUIConfig[Locale] or not DuffedUIConfig[Locale][group]) then
		control.Label:SetText(option or UNKNOWN)
		return
	end

	if (not DuffedUIConfig[Locale][group][option]) then control.Label:SetText(option or UNKNOWN) end

	local Info = DuffedUIConfig[Locale][group][option]

	if (not Info) then return end

	control.Label:SetText(Info.Name)

	if control.Box then
		control.Box.Tooltip = Info.Desc
		control.Box:HookScript('OnEnter', ControlOnEnter)
		control.Box:HookScript('OnLeave', ControlOnLeave)
	else
		control.Tooltip = Info.Desc
		control:HookScript('OnEnter', ControlOnEnter)
		control:HookScript('OnLeave', ControlOnLeave)
	end
end

local function EditBoxOnMouseDown(self) self:SetAutoFocus(true) end
local function EditBoxOnEditFocusLost(self) self:SetAutoFocus(false) end

local function EditBoxOnTextChange(self)
	local Value = self:GetText()

	if (type(tonumber(Value)) == 'number') then Value = tonumber(Value) end
	DuffedUIConfig:SetOption(self.Group, self.Option, Value)
end

local function EditBoxOnEnterPressed(self)
	self:SetAutoFocus(false)
	self:ClearFocus()

	local Value = self:GetText()

	if (type(tonumber(Value)) == 'number') then Value = tonumber(Value) end
	DuffedUIConfig:SetOption(self.Group, self.Option, Value)
end

local function EditBoxOnMouseWheel(self, delta)
	local Number = tonumber(self:GetText())

	if (delta > 0) then Number = Number + 2 else Number = Number - 2 end
	self:SetText(Number)
end

local function ButtonOnClick(self)
	if self.Toggled then
		self.Tex:SetTexture(nil)
		self.Toggled = false
		self.Label:SetTextColor(128/255, 128/255, 128/255)
		PlaySound(857)
	else
		self.Tex:SetTexture('Interface\\AddOns\\DuffedUI_ConfigUI\\media\\UI-CheckBox-Check')
		self.Toggled = true
		self.Label:SetTextColor(255/255, 255/255, 255/255)
		PlaySound(856)
	end

	DuffedUIConfig:SetOption(self.Group, self.Option, self.Toggled)
end

local function ButtonCheck(self)
	self.Toggled = true
	self.Tex:SetTexture('Interface\\AddOns\\DuffedUI_ConfigUI\\media\\UI-CheckBox-Check')
	self.Label:SetTextColor(255/255, 255/255, 255/255)
end

local function ButtonUncheck(self)
	self.Toggled = false
	self.Tex:SetTexture(nil)
	self.Label:SetTextColor(128/255, 128/255, 128/255)
end

local function ResetColor(self)
	local Defaults = DuffedUIConfig.ColorDefaults

	if (Defaults[self.Group] and Defaults[self.Group][self.Option]) then
		local Default = Defaults[self.Group][self.Option]
		self.Color:SetVertexColor(Default[1], Default[2], Default[3], Default[4])
		DuffedUIConfig:SetOption(self.Group, self.Option, {Default[1], Default[2], Default[3], Default[4]})
	end
end

local function SetSelectedValue(dropdown, value)
	local Key

	if (dropdown.Type == 'Custom') then
		for k, v in pairs(dropdown.Info.Options) do
			if (v == value) then
				Key = k
				break
			end
		end
	end

	if Key then value = Key end

	if dropdown[value] then
		if (dropdown.Type == 'Texture') then
			dropdown.CurrentTex:SetTexture(dropdown[value])
		elseif (dropdown.Type == 'Font') then
			dropdown.Current:SetFontObject(dropdown[value])
		end

		dropdown.Current:SetText((value))
	end
end

local function SetIconUp(self)
	self:ClearAllPoints()
	self:SetPoint('CENTER', self.Owner, 1, -4)
	self:SetTexture('Interface\\BUTTONS\\Arrow-Down-Up')
end

local function SetIconDown(self)
	self:ClearAllPoints()
	self:SetPoint('CENTER', self.Owner, 1, 1)
	self:SetTexture('Interface\\BUTTONS\\Arrow-Up-Up')
end

local function ListItemOnClick(self)
	local List = self.Owner
	local DropDown = List.Owner

	if (DropDown.Type == 'Texture') then
		DropDown.CurrentTex:SetTexture(self.Value)
	elseif (DropDown.Type == 'Font') then
		DropDown.Current:SetFontObject(self.Value)
	else
		DropDown.Info.Value = self.Value
	end

	DropDown.Current:SetText(self.Name)

	SetIconUp(DropDown.Button.Tex)
	List:Hide()

	if (DropDown.Type == 'Custom') then
		DuffedUIConfig:SetOption(DropDown._Group, DropDown._Option, DropDown.Info)
	else
		DuffedUIConfig:SetOption(DropDown._Group, DropDown._Option, self.Name)
	end
end

local function ListItemOnEnter(self) self.Hover:SetVertexColor(1, 0.82, 0, 0.4) end
local function ListItemOnLeave(self) self.Hover:SetVertexColor(1, 0.82, 0, 0) end

local function AddListItems(self, info)
	local DropDown = self.Owner
	local Type = DropDown.Type
	local Height = 3
	local LastItem

	for Name, Value in pairs(info) do
		local Button = CreateFrame('Button', nil, self)
		Button:SetSize(self:GetWidth(), 20)

		local Text = Button:CreateFontString(nil, 'OVERLAY')
		Text:SetPoint('LEFT', Button, 4, 0)

		if (Type ~= 'Font') then
			local C = DuffedUI[2]

			Text:SetFont(C['media'].font, 11)
			Text:SetShadowColor(0, 0, 0)
			Text:SetShadowOffset(s, -s/2)
		else
			Text:SetFontObject(Value)
		end

		Text:SetText(Name)

		if (Type == 'Texture') then
			local Bar = self:CreateTexture(nil, 'ARTWORK')
			Bar:SetAllPoints(Button)
			Bar:SetTexture(Value)
			Bar:SetVertexColor(Colors.r, Colors.g, Colors.b)

			Button.Bar = Bar
		end

		local Hover = Button:CreateTexture(nil, 'OVERLAY')
		Hover:SetTexture('Interface\\Buttons\\UI-Listbox-Highlight2')
		Hover:SetBlendMode('ADD')
		Hover:SetAllPoints()
		Button:SetHighlightTexture(Hover)

		Button.Owner = self
		Button.Name = Name
		Button.Text = Text
		Button.Value = Value
		Button.Hover = Hover

		Button:SetScript('OnClick', ListItemOnClick)
		Button:SetScript('OnEnter', ListItemOnEnter)
		Button:SetScript('OnLeave', ListItemOnLeave)

		if (not LastItem) then
			Button:SetPoint('TOP', self, 0, 0)
		else
			Button:SetPoint('TOP', LastItem, 'BOTTOM', 0, -0.5)
		end

		DropDown[Name] = Value

		LastItem = Button
		Height = Height + 20
	end

	self:SetHeight(Height)
end

local function CloseOtherLists(self)
	for i = 1, #DropDownMenus do
		local Menu = DropDownMenus[i]
		local List = Menu.List

		if (self ~= Menu and List:IsShown()) then
			List:Hide()
			SetIconUp(Menu.Button.Tex)
		end
	end
end

local function CloseList(self)
	for i = 1, #DropDownMenus do
		local Menu = DropDownMenus[i]
		local List = Menu.List

		if (self == List and self:IsShown()) then
			self:Hide()
			SetIconUp(Menu.Button.Tex)
			return
		end
	end
end

local function DropDownButtonOnClick(self)
	local DropDown = self.Owner
	local Texture = self.Tex

	if DropDown.List then
		local List = DropDown.List
		CloseOtherLists(DropDown)

		if List:IsVisible() then
			DropDown.List:Hide()
			SetIconUp(Texture)
			PlaySound(857)
		else
			DropDown.List:Show()
			SetIconDown(Texture)
			PlaySound(856)
		end
	end
end

local function SliderOnValueChanged(self, value)
	if (not self.ScrollFrame.Set) and (self.ScrollFrame:GetVerticalScrollRange() ~= 0) then
		self:SetMinMaxValues(0, math_floor(self.ScrollFrame:GetVerticalScrollRange()) - 1)
		self.ScrollFrame.Set = true
	end

	self.ScrollFrame:SetVerticalScroll(value)
end

local function SliderOnMouseWheel(self, delta)
	local Value = self:GetValue()

	if (delta > 0) then Value = Value - 10 else Value = Value + 10 end
	self:SetValue(Value)
end

local function CreateConfigButton(parent, group, option, value)
	local C = DuffedUI[2]

	local Button = CreateFrame('Button', nil, parent)
	Button:SkinCheckBox()

	Button:SetSize(18, 18)
	Button.Toggled = false
	Button:SetScript('OnClick', ButtonOnClick)
	Button.Type = 'Button'

	Button.Tex = Button:CreateTexture(nil, 'OVERLAY')
	Button.Tex:SetAllPoints()

	Button.Check = ButtonCheck
	Button.Uncheck = ButtonUncheck

	Button.Group = group
	Button.Option = option

	Button.Label = Button:CreateFontString(nil, 'OVERLAY')
	Button.Label:SetFont(C['media'].font, 11)
	Button.Label:SetPoint('LEFT', Button, 'RIGHT', 5, 0)
	Button.Label:SetShadowColor(0, 0, 0)
	Button.Label:SetShadowOffset(s, -s/2)

	if value then Button:Check() else Button:Uncheck() end

	return Button
end

local function CreateConfigEditBox(parent, group, option, value, max)
	local C = DuffedUI[2]

	local EditBox = CreateFrame('Frame', nil, parent)
	EditBox:SetSize(50, 18)
	EditBox:SkinEditBox()

	EditBox.Type = 'EditBox'

	EditBox.Box = CreateFrame('EditBox', nil, EditBox)
	EditBox.Box:SetFont(C['media'].font, 11)
	EditBox.Box:SetShadowOffset(s, -s/2)
	EditBox.Box:SetPoint('TOPLEFT', EditBox, 4, -2)
	EditBox.Box:SetPoint('BOTTOMRIGHT', EditBox, -4, 2)
	EditBox.Box:SetMaxLetters(max or 4)
	EditBox.Box:SetAutoFocus(false)
	EditBox.Box:EnableKeyboard(true)
	EditBox.Box:EnableMouse(true)
	EditBox.Box:SetScript('OnMouseDown', EditBoxOnMouseDown)
	EditBox.Box:SetScript('OnEscapePressed', EditBoxOnEnterPressed)
	EditBox.Box:SetScript('OnEnterPressed', EditBoxOnEnterPressed)
	EditBox.Box:SetScript('OnEditFocusLost', EditBoxOnEditFocusLost)
	EditBox.Box:SetScript('OnTextChanged', EditBoxOnTextChange)
	EditBox.Box:SetText(value)

	if (not max) then
		EditBox.Box:EnableMouseWheel(true)
		EditBox.Box:SetScript('OnMouseWheel', EditBoxOnMouseWheel)
	end

	EditBox.Label = EditBox:CreateFontString(nil, 'OVERLAY')
	EditBox.Label:SetFont(C['media'].font, 11)
	EditBox.Label:SetPoint('LEFT', EditBox, 'RIGHT', 5, 0)
	EditBox.Label:SetShadowColor(0, 0, 0)
	EditBox.Label:SetShadowOffset(s, -s/2)

	EditBox.Box.Group = group
	EditBox.Box.Option = option
	EditBox.Box.Label = EditBox.Label

	return EditBox
end

local function CreateConfigColorPicker(parent, group, option, value)
	local D = DuffedUI[1]
	local C = DuffedUI[2]

	local ConfigTexture = D.GetTexture(C['uitextures'].GeneralTextures)

	local Button = CreateFrame('Button', nil, parent)
	Button:SkinButton()
	
	Button:SetSize(50, 18)
	Button.Colors = value
	Button.Type = 'Color'
	Button.Group = group
	Button.Option = option
	Button:RegisterForClicks('AnyUp')
	Button:SetScript('OnClick', function(self, button)
		if (button == 'RightButton') then
			ResetColor(self)
		else
			if ColorPickerFrame:IsShown() then return end

			local OldR, OldG, OldB, OldA = unpack(value)

			local function ShowColorPicker(r, g, b, a, changedCallback, sameCallback)
				HideUIPanel(ColorPickerFrame)
				ColorPickerFrame.button = self
				ColorPickerFrame:SetColorRGB(r, g, b)
				ColorPickerFrame:SetTemplate() -- FIX
				ColorPickerFrame.Border:Kill() -- FIX
				ColorPickerFrame.Header:StripTextures() -- FIX
				ColorPickerFrame.hasOpacity = (a ~= nil and a < 1)
				ColorPickerFrame.opacity = a
				ColorPickerFrame.previousValues = {OldR, OldG, OldB, OldA}
				ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = changedCallback, changedCallback, sameCallback
				ShowUIPanel(ColorPickerFrame)
			end

			local function ColorCallback(restore)
				if (restore ~= nil or self ~= ColorPickerFrame.button) then return end

				local NewA, NewR, NewG, NewB = OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB()

				value = {NewR, NewG, NewB, NewA}
				DuffedUIConfig:SetOption(group, option, value)
				self.Color:SetVertexColor(NewR, NewG, NewB, NewA)
			end

			local function SameColorCallback()
				value = {OldR, OldG, OldB, OldA}
				DuffedUIConfig:SetOption(group, option, value)
				self.Color:SetVertexColor(OldR, OldG, OldB, OldA)
			end

			ShowColorPicker(OldR, OldG, OldB, OldA, ColorCallback, SameColorCallback)
		end
	end)

	Button.Name = Button:CreateFontString(nil, 'OVERLAY')
	Button.Name:SetFont(C['media'].font, 11)
	Button.Name:SetPoint('CENTER', Button)
	Button.Name:SetShadowColor(0, 0, 0)
	Button.Name:SetShadowOffset(s, -s/2)
	Button.Name:SetText(COLOR)

	Button.Color = Button:CreateTexture(nil, 'OVERLAY')
	Button.Color:SetAllPoints(Button)
	Button.Color:SetTexture(ConfigTexture)
	Button.Color:SetVertexColor(value[1], value[2], value[3], value[4])

	Button.Label = Button:CreateFontString(nil, 'OVERLAY')
	Button.Label:SetFont(C['media'].font, 11)
	Button.Label:SetPoint('LEFT', Button, 'RIGHT', 5, 0)
	Button.Label:SetShadowColor(0, 0, 0)
	Button.Label:SetShadowOffset(s, -s/2)

	return Button
end

local function CreateConfigDropDown(parent, group, option, value, type)
	local D = DuffedUI[1]
	local C = DuffedUI[2]

	local DropDown = CreateFrame('Button', nil, parent)
	DropDown:SetSize(150, 20)
	DropDown:SetTemplate()

	DropDown.Type = type
	DropDown._Group = group
	DropDown._Option = option
	local Info

	if (type == 'Font') then
		Info = D['FontTable']
	elseif (type == 'Texture') then
		Info = D['TextureTable']
	else
		Info = value
	end

	DropDown.Info = Info

	local Current = DropDown:CreateFontString(nil, 'OVERLAY')
	Current:SetPoint('LEFT', DropDown, 6, -0.5)

	if (type == 'Texture') then
		local CurrentTex = DropDown:CreateTexture(nil, 'ARTWORK')
		CurrentTex:SetSize(DropDown:GetWidth(), 20)
		CurrentTex:SetPoint('LEFT', DropDown, 0, 0)
		CurrentTex:SetVertexColor(Colors.r, Colors.g, Colors.b)
		DropDown.CurrentTex = CurrentTex

		Current:SetFont(C['media'].font, 11)
		Current:SetShadowColor(0, 0, 0)
		Current:SetShadowOffset(s, -s/2)
	elseif (type == 'Custom') then
		Current:SetFont(C['media'].font, 11)
		Current:SetShadowColor(0, 0, 0)
		Current:SetShadowOffset(s, -s/2)
	end

	local Button = CreateFrame('Button', nil, DropDown)
	Button:SetSize(16, 16)
	Button:CreateBorder()

	Button:SetPoint('RIGHT', DropDown, -2, 0)
	Button.Owner = DropDown

	local ButtonTex = Button:CreateTexture(nil, 'OVERLAY')
	ButtonTex:SetSize(14, 14)
	ButtonTex:SetPoint('CENTER', Button, 1, -4)
	ButtonTex:SetTexture('Interface\\BUTTONS\\Arrow-Down-Up')
	ButtonTex.Owner = Button

	local Label = DropDown:CreateFontString(nil, 'OVERLAY')
	Label:SetFont(C['media'].font, 11)
	Label:SetShadowColor(0, 0, 0)
	Label:SetShadowOffset(s, -s/2)
	Label:SetPoint('LEFT', DropDown, 'RIGHT', 5, 0)

	local List = CreateFrame('Frame', nil, UIParent)
	List:SetPoint('TOPLEFT', DropDown, 'BOTTOMLEFT', 0, -4)
	List:SetTemplate()

	List:Hide()
	List:SetWidth(150)
	List:SetFrameLevel(DropDown:GetFrameLevel() + 3)
	List:SetFrameStrata('HIGH')
	List:SetFrameLevel(100)
	List:EnableMouse(true)
	List:HookScript('OnHide', CloseList)
	List.Owner = DropDown

	if (type == 'Custom') then AddListItems(List, Info.Options) else AddListItems(List, Info) end

	DropDown.Label = Label
	DropDown.Button = Button
	DropDown.Current = Current
	DropDown.List = List
	DropDown:HookScript('OnHide', function() List:Hide() end)

	Button.Tex = ButtonTex
	Button:SetScript('OnClick', DropDownButtonOnClick)

	if (type == 'Custom') then SetSelectedValue(DropDown, value.Value) else SetSelectedValue(DropDown, value) end
	table_insert(DropDownMenus, DropDown)

	return DropDown
end

local function CreateGroupOptions(group)
	local Control
	local LastControl
	local GroupPage = GroupPages[group]
	local Group = group

	for Option, Value in pairs(DuffedUI[2][group]) do
		if (type(Value) == 'boolean') then -- Button
			Control = CreateConfigButton(GroupPage, Group, Option, Value)
		elseif (type(Value) == 'number') then -- EditBox
			Control = CreateConfigEditBox(GroupPage, Group, Option, Value)
		elseif (type(Value) == 'table') then -- Color Picker / Custom DropDown
			if Value.Options then
				Control = CreateConfigDropDown(GroupPage, Group, Option, Value, 'Custom')
			else
				Control = CreateConfigColorPicker(GroupPage, Group, Option, Value)
			end
		elseif (type(Value) == 'string') then -- DropDown / EditBox
			if string_find(string_lower(Option), 'font') then
				Control = CreateConfigDropDown(GroupPage, Group, Option, Value, 'Font')
			elseif string_find(string_lower(Option), 'texture') then
				Control = CreateConfigDropDown(GroupPage, Group, Option, Value, 'Texture')
			else
				Control = CreateConfigEditBox(GroupPage, Group, Option, Value, 155)
			end
		end

		SetControlInformation(Control, Group, Option) -- Set the label and tooltip

		if (not GroupPage.Controls[Control.Type]) then GroupPage.Controls[Control.Type] = {} end

		table_insert(GroupPage.Controls[Control.Type], Control)
	end

	local Buttons = GroupPage.Controls['Button']
	local ColorPickers = GroupPage.Controls['Color']
	local Custom = GroupPage.Controls['Custom']
	local EditBoxes = GroupPage.Controls['EditBox']
	local Fonts = GroupPage.Controls['Font']
	local Textures = GroupPage.Controls['Texture']

	if Buttons then
		for i = 1, #Buttons do
			if (i == 1) then
				if LastControl then
					Buttons[i]:SetPoint('TOPLEFT', LastControl, 'BOTTOMLEFT', 0, -6)
				else
					Buttons[i]:SetPoint('TOPLEFT', GroupPage, 6, -6)
				end
			else
				Buttons[i]:SetPoint('TOPLEFT', LastControl, 'BOTTOMLEFT', 0, -6)
			end

			LastControl = Buttons[i]
		end
	end

	if EditBoxes then
		for i = 1, #EditBoxes do
			if (i == 1) then
				if LastControl then
					EditBoxes[i]:SetPoint('TOPLEFT', LastControl, 'BOTTOMLEFT', 0, -6)
				else
					EditBoxes[i]:SetPoint('TOPLEFT', GroupPage, 6, -6)
				end
			else
				EditBoxes[i]:SetPoint('TOPLEFT', LastControl, 'BOTTOMLEFT', 0, -6)
			end

			LastControl = EditBoxes[i]
		end
	end

	if ColorPickers then
		for i = 1, #ColorPickers do
			if (i == 1) then
				if LastControl then
					ColorPickers[i]:SetPoint('TOPLEFT', LastControl, 'BOTTOMLEFT', 0, -6)
				else
					ColorPickers[i]:SetPoint('TOPLEFT', GroupPage, 6, -6)
				end
			else
				ColorPickers[i]:SetPoint('TOPLEFT', LastControl, 'BOTTOMLEFT', 0, -6)
			end

			LastControl = ColorPickers[i]
		end
	end

	if Fonts then
		for i = 1, #Fonts do
			if (i == 1) then
				if LastControl then
					Fonts[i]:SetPoint('TOPLEFT', LastControl, 'BOTTOMLEFT', 0, -6)
				else
					Fonts[i]:SetPoint('TOPLEFT', GroupPage, 6, -6)
				end
			else
				Fonts[i]:SetPoint('TOPLEFT', LastControl, 'BOTTOMLEFT', 0, -6)
			end

			LastControl = Fonts[i]
		end
	end

	if Textures then
		for i = 1, #Textures do
			if (i == 1) then
				if LastControl then
					Textures[i]:SetPoint('TOPLEFT', LastControl, 'BOTTOMLEFT', 0, -6)
				else
					Textures[i]:SetPoint('TOPLEFT', GroupPage, 6, -6)
				end
			else
				Textures[i]:SetPoint('TOPLEFT', LastControl, 'BOTTOMLEFT', 0, -6)
			end

			LastControl = Textures[i]
		end
	end

	if Custom then
		for i = 1, #Custom do
			if (i == 1) then
				if LastControl then
					Custom[i]:SetPoint('TOPLEFT', LastControl, 'BOTTOMLEFT', 0, -6)
				else
					Custom[i]:SetPoint('TOPLEFT', GroupPage, 6, -6)
				end
			else
				Custom[i]:SetPoint('TOPLEFT', LastControl, 'BOTTOMLEFT', 0, -6)
			end

			LastControl = Custom[i]
		end
	end

	GroupPage.Handled = true
end

local function ShowGroup(group)
	if (not GroupPages[group]) then return end
	if (not GroupPages[group].Handled) then CreateGroupOptions(group) end

	for _, page in pairs(GroupPages) do
		page:Hide()
		if page.Slider then page.Slider:Hide() end
	end

	GroupPages[group]:Show()
	do
		local msg = DuffedUIConfig
		and DuffedUIConfig[Locale]
		and DuffedUIConfig[Locale]['GroupNames']
		and DuffedUIConfig[Locale]['GroupNames'][group]
		or group
		DuffedUIConfigFrameTitle.Text:SetText(msg)
	end
	DuffedUIConfigFrameTitle.Text:SetTextColor(196 / 255, 31 / 255, 59 / 255)

	if GroupPages[group].Slider then GroupPages[group].Slider:Show() end
end

local function GroupButtonOnClick(self) ShowGroup(self.Group) end

-- Create the config window
function DuffedUIConfig:CreateConfigWindow()
	local D = DuffedUI[1]
	local C = DuffedUI[2]
	local L = DuffedUI[3]
	local SettingText = DuffedUIConfigPerAccount and 'CharSettings' or 'GlobalSettings' --FIX

	self:UpdateColorDefaults()

	local NumGroups = 0

	for Group in pairs(C) do
		if (not self.Filter[Group]) then NumGroups = NumGroups + 1 end
	end

	local Height = (12 + (NumGroups * 20) + ((NumGroups - 1) * 4)) -- Padding + (NumButtons * ButtonSize) + ((NumButtons - 1) * ButtonSpacing)
	
	-- Fuck Dialogs
	StaticPopupDialogs.PERCHAR = {
		text = L['config']['perchar'],
		button1 = APPLY,
		button2 = CANCEL,
		OnAccept = function()
			if DuffedUIConfigAllCharacters:GetChecked() then 
				DuffedUIConfigAll[myPlayerRealm][myPlayerName] = true
				DuffedUIConfigPublic = nil
			else 
				DuffedUIConfigAll[myPlayerRealm][myPlayerName] = false
				DuffedUIConfigPrivate = nil
			end
			ReloadUI()
		end,
		OnCancel = function()
			if DuffedUIConfigAllCharacters:GetChecked() then
				DuffedUIConfigAllCharacters:SetChecked(false)
			else 
				DuffedUIConfigAllCharacters:SetChecked(true)
			end
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	StaticPopupDialogs.RESET_PERCHAR = {
		text = L['config']['resetchar'],
		button1 = APPLY,
		button2 = CANCEL,
		OnAccept = function()
			DuffedUIConfig = DuffedUIConfigPublic
			ReloadUI() 
		end,
		OnCancel = function()
			ConfigFrame:Hide()
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = true,
		preferredIndex = 3
	}

	StaticPopupDialogs.RESET_ALL = {
		text = L['config']['resetall'],
		button1 = APPLY,
		button2 = CANCEL,
		OnAccept = function()
			DuffedUIConfigPublic = nil
			DuffedUIConfigPrivate = nil
			ReloadUI()
		end,
		hideOnEscape = true,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = false,
		preferredIndex = 3
	}
	
	local ConfigFrame = CreateFrame('Frame', 'DuffedUIConfigFrame', UIParent)
	ConfigFrame:SetSize(636, Height)
	ConfigFrame:SetPoint('CENTER', 0, 100)
	ConfigFrame:SetFrameStrata('HIGH')

	ConfigFrame:SetClampedToScreen(true)
	ConfigFrame:SetMovable(true)
	ConfigFrame:EnableMouse(true)
	ConfigFrame:RegisterForDrag('LeftButton')
	ConfigFrame:SetScript('OnDragStart', ConfigFrame.StartMoving)
	ConfigFrame:SetScript('OnDragStop', ConfigFrame.StopMovingOrSizing)

	local LeftWindow = CreateFrame('Frame', 'DuffedUIConfigFrameLeft', ConfigFrame)
	LeftWindow:SetTemplate('Transparent')

	LeftWindow:SetSize(170, Height)
	LeftWindow:SetPoint('LEFT', ConfigFrame, 0, 0)
	LeftWindow:EnableMouse(true)

	local RightWindow = CreateFrame('Frame', 'DuffedUIConfigFrameRight', ConfigFrame)
	RightWindow:SetTemplate('Transparent')

	RightWindow:SetSize(460, Height)
	RightWindow:SetPoint('RIGHT', ConfigFrame, 0, 0)
	RightWindow:EnableMouse(true)
	RightWindow:EnableMouseWheel(true)

	local TitleFrame = CreateFrame('Frame', 'DuffedUIConfigFrameTitle', ConfigFrame)
	TitleFrame:SetTemplate('Transparent')
	TitleFrame:SetHeight(24)
	TitleFrame:SetPoint('BOTTOMLEFT', ConfigFrame, 'TOPRIGHT', 0, 6)
	TitleFrame:SetPoint('BOTTOMRIGHT', ConfigFrame, 'TOPLEFT', 0, 6)
	TitleFrame:EnableMouse(true)
	TitleFrame:SetScript('OnMouseDown', function() ConfigFrame:StartMoving() end)
	TitleFrame:SetScript('OnMouseUp', function() ConfigFrame:StopMovingOrSizing() end)
	TitleFrame:SetClampedToScreen(true)
	TitleFrame:SetMovable(true)

	TitleFrame.Text = TitleFrame:CreateFontString(nil, 'OVERLAY')
	TitleFrame.Text:SetFont(C['media'].font, 16)
	TitleFrame.Text:SetPoint('CENTER', TitleFrame, 0, 0)
	TitleFrame.Text:SetShadowColor(0, 0, 0)
	TitleFrame.Text:SetShadowOffset(s, -s/2)
	
	local DuffedUIConfigUIIcon = CreateFrame('Frame', 'DuffedUIConfigUITitle', ConfigFrame)
	DuffedUIConfigUIIcon:Size(24, 24)
	DuffedUIConfigUIIcon:SetPoint('RIGHT', TitleFrame, 'LEFT', 26, 0)
	DuffedUIConfigUIIcon:SetTemplate('Transparent')

	DuffedUIConfigUIIcon.bg = DuffedUIConfigUIIcon:CreateTexture(nil, 'ARTWORK')
	DuffedUIConfigUIIcon.bg:Point('TOPLEFT', 2, -2)
	DuffedUIConfigUIIcon.bg:Point('BOTTOMRIGHT', -2, 2)
	DuffedUIConfigUIIcon.bg:SetTexture(C['media'].duffed)
	
	local version = DuffedUIConfigUIIcon:CreateFontString(nil, 'OVERLAY', nil)
	version:SetFont(C['media']['font'], 11)
	version:SetText('Version: '..D['Version'] .. ' ' .. 'Revision: ' .. D['Revision'])
	version:SetPoint('LEFT', DuffedUIConfigUIIcon, 'RIGHT')

	local InfoFrame = CreateFrame('Frame', 'DuffedUIConfigFrameCredit', ConfigFrame)
	InfoFrame:SetTemplate('Transparent')
	InfoFrame:SetFrameStrata('BACKGROUND')
	InfoFrame:SetHeight(24)
	InfoFrame:SetPoint('TOPLEFT', ConfigFrame, 'BOTTOMRIGHT', 0, -6)
	InfoFrame:SetPoint('TOPRIGHT', ConfigFrame, 'BOTTOMLEFT', 0, -6)
	
	local InfoFrame2 = CreateFrame('Frame', 'DuffedUIConfigFrameCredit2', InfoFrame)
	InfoFrame2:SetTemplate('Transparent')
	InfoFrame2:SetFrameStrata('BACKGROUND')
	InfoFrame2:SetHeight(24)
	InfoFrame2:SetPoint('TOPLEFT', InfoFrame, 'BOTTOMRIGHT', 0, -6)
	InfoFrame2:SetPoint('TOPRIGHT', InfoFrame, 'BOTTOMLEFT', 0, -6)
	
	local sf = CreateFrame('ScrollFrame', nil, ConfigFrame)
	sf:SetSize(640, 24)
	sf:SetPoint('CENTER',InfoFrame, 0, 0)

	local scroll = CreateFrame('Frame', nil, sf)
	scroll:Size(640, 24)
	scroll:SetPoint('CENTER', InfoFrame)
	sf:SetScrollChild(scroll)
	
	local credit = 'Special thanks to: '
	for i = 1, #D.Credits do
		if (i ~= 1) then credit = credit .. ', ' .. '|cffff8000' .. D.Credits[i] .. '|r' else credit = credit .. '|cffff8000' .. D.Credits[i] .. '|r' end
	end

	local ct = scroll:CreateFontString(nil, 'OVERLAY')
	ct:SetFont(C['media']['font'], 14)
	ct:SetText(credit)
	ct:Point('LEFT', scroll, 'RIGHT', 4, 0)
	scroll:SetAnimation('Move', 'Horizontal', -1500, 0.5)

	scroll:AnimOnFinished('Move', function(self)
		if (not ConfigFrame:IsVisible()) then return end
		self:ClearAllPoints()
		self:SetPoint('CENTER', InfoFrame)
		self:SetAnimation('Move', 'Horizontal', -1500, 0.5)
	end)

	local sf2 = CreateFrame('ScrollFrame', nil, ConfigFrame)
	sf2:SetSize(636, 24)
	sf2:SetPoint('CENTER', InfoFrame2, 0, 0)

	local scroll2 = CreateFrame('Frame', nil, sf2)
	scroll2:Size(636, 24)
	scroll2:SetPoint('CENTER', InfoFrame2)
	sf2:SetScrollChild(scroll2)

	local credit2 = 'Special thanks to my Betatester & Bugreporter: '
	for i = 1, #D.DuffedCredits do
		if (i ~= 1) then credit2 = credit2 .. ', ' .. '|cffC41F3B' ..  D.DuffedCredits[i]  .. '|r' else credit2 = credit2 .. '|cffC41F3B' ..  D.DuffedCredits[i]  .. '|r' end
	end

	local ct2 = scroll2:CreateFontString(nil, 'OVERLAY')
	ct2:SetFont(C['media']['font'], 14)
	ct2:SetText(credit2)
	ct2:Point('LEFT', scroll2, 'RIGHT', 4, 0)
	scroll2:SetAnimation('Move', 'Horizontal', -1500, 0.5)

	scroll2:AnimOnFinished('Move', function(self)
		if (not ConfigFrame:IsVisible()) then return end
		self:ClearAllPoints()
		self:SetPoint('CENTER', InfoFrame2)
		self:SetAnimation('Move', 'Horizontal', -1500, 0.5)
	end)

	local CloseButton = CreateFrame('Button', nil, InfoFrame)
	CloseButton:SkinButton()
	CloseButton:SetSize(624/3, 22)
	CloseButton:SetScript('OnClick', function()
		PlaySound(604)
		ConfigFrame:Hide()
	end)
	
	CloseButton:SetFrameLevel(InfoFrame2:GetFrameLevel() + 1)
	CloseButton:SetPoint('BOTTOMLEFT', InfoFrame2, 'BOTTOMLEFT', 0, -28)

	CloseButton.Text = CloseButton:CreateFontString(nil, 'OVERLAY')
	CloseButton.Text:SetFont(C['media'].font, 11)
	CloseButton.Text:SetShadowOffset(s, -s/2)
	CloseButton.Text:SetPoint('CENTER', CloseButton)
	CloseButton.Text:SetTextColor(1, 0, 0)
	CloseButton.Text:SetText('|cffFF0000' .. CLOSE .. '|r')

	local ReloadButton = CreateFrame('Button', nil, InfoFrame)
	ReloadButton:SkinButton()
	ReloadButton:SetSize(624/3, 22)
	ReloadButton:SetScript('OnClick', function() ReloadUI() end)
	
	ReloadButton:SetFrameLevel(InfoFrame2:GetFrameLevel() + 1)
	ReloadButton:SetPoint('LEFT', CloseButton, 'RIGHT', 6, 0)

	ReloadButton.Text = ReloadButton:CreateFontString(nil, 'OVERLAY')
	ReloadButton.Text:SetFont(C['media'].font, 11)
	ReloadButton.Text:SetShadowOffset(s, -s/2)
	ReloadButton.Text:SetPoint('CENTER', ReloadButton)
	ReloadButton.Text:SetText('|cff00FF00' .. APPLY .. '|r')
	
	local ResetButton = CreateFrame('Button', nil, InfoFrame)
	local myPlayerRealm = GetRealmName()
	local myPlayerName  = UnitName('player')
	ResetButton:SkinButton()
	ResetButton:SetSize(624/3, 22)
	ResetButton:SetScript('OnClick', function()
		print('Test')
		if DuffedUIConfigAll[myPlayerRealm][myPlayerName] == true then
			StaticPopup_Show('RESET_PERCHAR') 
		else
			StaticPopup_Show('RESET_ALL')
		end
	end)
	ResetButton:SetFrameLevel(InfoFrame2:GetFrameLevel() + 1)
	ResetButton:SetPoint('LEFT', ReloadButton, 'RIGHT', 6, 0)

	ResetButton.Text = ResetButton:CreateFontString(nil, 'OVERLAY')
	ResetButton.Text:SetFont(C['media'].font, 11)
	ResetButton.Text:SetShadowOffset(s, -s/2)
	ResetButton.Text:SetPoint('CENTER', ResetButton)
	ResetButton.Text:SetText('|cffffd100'..L['config']['resetbutton']..'|r')
	
	if DuffedUIConfigAll then
		local myPlayerRealm = GetRealmName()
		local myPlayerName = UnitName('player')

		local button = CreateFrame('CheckButton', 'DuffedUIConfigAllCharacters', DuffedUIConfigFrameTitle, 'InterfaceOptionsCheckButtonTemplate')
		button:SkinCheckBox()
		button:SetScript('OnClick', function()
			StaticPopup_Show('PERCHAR')
			ConfigFrame:Hide()
		end)
		button:SetPoint('RIGHT', DuffedUIConfigFrameTitle, 'RIGHT', -3, 0)
		local label = DuffedUIConfigAllCharacters:CreateFontString(nil, 'OVERLAY', nil)
		label:SetFont(C['media']['font'], 11)
		label:SetText(L['config']['setsavedsetttings'])
		label:SetPoint('RIGHT', button, 'LEFT')
		if DuffedUIConfigAll[myPlayerRealm][myPlayerName] == true then button:SetChecked(true) else button:SetChecked(false) end
	end

	local LastButton
	local ButtonCount = 0

	for Group, Table in PairsByKeys(C) do
		if (not self.Filter[Group]) then
			local NumOptions = 0

			for _ in pairs(Table) do NumOptions = NumOptions + 1 end

			local GroupHeight = 8 + (NumOptions * 25)

			local GroupPage = CreateFrame('Frame', nil, ConfigFrame)
			GroupPage:SetSize(460, Height)
			GroupPage:SetPoint('TOPRIGHT', ConfigFrame)
			GroupPage.Controls = {}

			if (GroupHeight > Height) then
				GroupPage:SetSize(460, GroupHeight)

				local ScrollFrame = CreateFrame('ScrollFrame', nil, RightWindow)
				ScrollFrame:SetSize(460, Height)
				ScrollFrame:SetAllPoints(RightWindow, 0, 4)
				ScrollFrame:SetScrollChild(GroupPage)
				ScrollFrame:SetClipsChildren(true)

				local Slider = CreateFrame('Slider', nil, ScrollFrame)
				Slider:SetPoint('RIGHT', -6, 0)
				Slider:SetWidth(12)
				Slider:SetHeight(Height - 12)
				Slider:SetThumbTexture(C['media'].normTex)
				Slider:SetOrientation('VERTICAL')
				Slider:SetValueStep(1)
				Slider:SetTemplate()

				Slider:SetMinMaxValues(0, 1)
				Slider:SetValue(0)
				Slider.ScrollFrame = ScrollFrame
				Slider:EnableMouseWheel(true)
				Slider:SetScript('OnMouseWheel', SliderOnMouseWheel)
				Slider:SetScript('OnValueChanged', SliderOnValueChanged)

				Slider:SetValue(10)
				Slider:SetValue(0)

				local Thumb = Slider:GetThumbTexture()
				Thumb:SetWidth(12)
				Thumb:SetHeight(18)
				Thumb:SetVertexColor(196 / 255, 31 / 255, 59 / 255, 0.8)

				Slider:Show()

				GroupPage.Slider = Slider
			end

			GroupPages[Group] = GroupPage

			local Button = CreateFrame('Button', nil, ConfigFrame)
			Button.Group = Group

			Button:SetSize(167, 20)
			Button:SetScript('OnClick', GroupButtonOnClick)
			Button:SetFrameLevel(LeftWindow:GetFrameLevel() + 1)

			if Button.SetHighlightTexture and not Button.Hover then
				Button.Hover = Button:CreateTexture(nil, 'ARTWORK')
				Button.Hover:SetVertexColor(Colors.r, Colors.g, Colors.b, 1)
				Button.Hover:SetTexture('Interface\\Buttons\\UI-Listbox-Highlight2')
				Button.Hover:SetBlendMode('ADD')
				Button.Hover:SetAllPoints()
				Button:SetHighlightTexture(Button.Hover)
			end

			Button.Text = Button:CreateFontString(nil, 'OVERLAY')
			Button.Text:SetFont(C['media'].font, 11)
			Button.Text:SetShadowOffset(s, -s/2)
			Button.Text:SetPoint('CENTER', Button)
			do
				local msg = DuffedUIConfig
				and DuffedUIConfig[Locale]
				and DuffedUIConfig[Locale]['GroupNames']
				and DuffedUIConfig[Locale]['GroupNames'][Group]
				or Group
				Button.Text:SetText(msg)
			end

			Button.Active = Button:CreateTexture(nil, 'ARTWORK')
			Button.Active:SetAlpha(0.3)
			Button.Active:SetTexture('Interface\\Buttons\\UI-Listbox-Highlight')
			Button.Active:SetBlendMode('ADD')
			Button.Active:SetAllPoints()
			Button.Active:Hide()

			GroupPage:HookScript('OnShow', function() Button.Active:Show() end)
			GroupPage:HookScript('OnHide', function() Button.Active:Hide() end)
			if (ButtonCount == 0) then Button:SetPoint('TOP', LeftWindow, 0, -6) else Button:SetPoint('TOP', LastButton, 'BOTTOM', 0, -4) end

			ButtonCount = ButtonCount + 1
			LastButton = Button
		end
	end

	ShowGroup('general') -- Show General options by default
	
	ConfigFrame:Hide()
	
	GameMenuFrame:HookScript('OnShow', function() ConfigFrame:Hide() end)
end

do
	SlashCmdList['CONFIG'] = function()
		if (not DuffedUIConfigFrame) then
			DuffedUIConfig:CreateConfigWindow()
			PlaySound(603)
		end
		if DuffedUIConfigFrame:IsVisible() then
			DuffedUIConfigFrame:Hide()
			PlaySound(604)
		else
			DuffedUIConfigFrame:Show()
			PlaySound(603)
		end
		HideUIPanel(GameMenuFrame)
	end
	SLASH_CONFIG1 = '/config'
	SLASH_CONFIG2 = '/cfg'
	SLASH_CONFIG3 = '/configui'
	SLASH_CONFIG4 = '/dc'
	SLASH_CONFIG5 = '/Duffedui'
	
	local loaded = CreateFrame('Frame')
	loaded:RegisterEvent('PLAYER_LOGIN')
	loaded:SetScript('OnEvent', function(self, event, addon)
		D, C, L = unpack(DuffedUI)
		if IsAddOnLoaded('Aurora') then F = unpack(Aurora) end
		local menu = GameMenuFrame
		local menuy = menu:GetHeight()
		local quit = GameMenuButtonQuit
		local continue = GameMenuButtonContinue
		local continuex = continue:GetWidth()
		local continuey = continue:GetHeight()
		local config = DuffedUIConfigUI
		local interface = GameMenuButtonUIOptions
		local keybinds = GameMenuButtonKeybindings

		menu:SetHeight(menuy + continuey)

		local button = CreateFrame('BUTTON', 'GameMenuButtonDuffedUIOptions', menu, 'GameMenuButtonTemplate')
		button:SetSize(continuex, continuey)
		button:Point('TOP', interface, 'BOTTOM', 0, -1)
		button:SetText('DuffedUI')
		if IsAddOnLoaded('Aurora') then F.Reskin(button) end
		button:SetScript('OnClick', function(self)
			if InCombatLockdown() then print(ERR_NOT_IN_COMBAT) return end
			if (not DuffedUIConfigFrame) then
				DuffedUIConfig:CreateConfigWindow()
				PlaySound(603)
			end
			if DuffedUIConfigFrame:IsVisible() then
				DuffedUIConfigFrame:Hide()
				PlaySound(604)
			else
				DuffedUIConfigFrame:Show()
				PlaySound(603)
			end
			HideUIPanel(GameMenuFrame)
			end)
		keybinds:ClearAllPoints()
		keybinds:Point('TOP', button, 'BOTTOM', 0, -1)
	end)
end