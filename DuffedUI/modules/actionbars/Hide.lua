local D, C, L = unpack(select(2, ...)) 
if not C['actionbar']['enable'] then return end

local hide = DuffedUIUIHider
local frames = {
	MainMenuBar, MainMenuBarArtFrame, PossessBarFrame, 
	PetActionBarFrame, IconIntroTracker, ShapeshiftBarLeft,
	ShapeshiftBarMiddle, ShapeshiftBarRight,
}

for i, f in pairs(frames) do
	f:UnregisterAllEvents()
	f.ignoreFramePositionManager = true
	f:SetParent(hide)
end

IconIntroTracker:UnregisterAllEvents()
IconIntroTracker:SetParent(hide)
MainMenuBar.slideOut.IsPlaying = function() return true end
SetCVar('alwaysShowActionBars', 1)

hooksecurefunc('TalentFrame_LoadUI', function() PlayerTalentFrame:UnregisterEvent('ACTIVE_TALENT_GROUP_CHANGED') end)

hide:RegisterEvent('PLAYER_ENTERING_WORLD')
hide:SetScript('OnEvent', function(self, event, ...)
	if event == 'PLAYER_ENTERING_WORLD' then
		ActionBarButtonEventsFrame:UnregisterEvent('ACTIONBAR_SHOWGRID')
		ActionBarButtonEventsFrame:UnregisterEvent('ACTIONBAR_HIDEGRID')
		ActionBarButtonEventsFrame:UnregisterEvent('PLAYER_ENTERING_WORLD')
	end
end)