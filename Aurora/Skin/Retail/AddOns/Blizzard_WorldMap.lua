local _, private = ...
if not private.isRetail then return end

--[[ Lua Globals ]]
-- luacheck: globals next

--[[ Core ]]
local Aurora = private.Aurora
local Base = Aurora.Base
local Hook, Skin = Aurora.Hook, Aurora.Skin
local Color, Util = Aurora.Color, Aurora.Util

do --[[ AddOns\Blizzard_WorldMap.lua ]]
    do --[[ Blizzard_WorldMap.lua ]]
        Hook.WorldMapMixin = {}
        function Hook.WorldMapMixin:Minimize()
            self.NavBar:SetPoint("TOPLEFT", self.TitleCanvasSpacerFrame, 5, -30)
        end
        function Hook.WorldMapMixin:Maximize()
            --self.NavBar:SetPoint("TOPLEFT", self.TitleCanvasSpacerFrame, 4, -25)
        end
        function Hook.WorldMapMixin:AddOverlayFrame(templateName, templateType, anchorPoint, relativeTo, relativePoint, offsetX, offsetY)
            if Skin[templateName] then
                Skin[templateName](self.overlayFrames[#self.overlayFrames])
            end
        end
    end
end

do --[[ AddOns\Blizzard_WorldMap.xml ]]
    do --[[ Blizzard_WorldMapTemplates.xml ]]
        function Skin.WorldMapFloorNavigationFrameTemplate(Frame)
            Skin.UIDropDownMenuTemplate(Frame)
        end
        function Skin.WorldMapTrackingOptionsButtonTemplate(Button)
            Button:GetRegions():SetPoint("TOPRIGHT")
            Button.Background:Hide()
            Button.Border:Hide()

            local tex = Button:GetHighlightTexture()
            tex:SetTexture([[Interface\Minimap\Tracking\None]], "ADD")
            tex:SetAllPoints(Button.Icon)
        end
        function Skin.WorldMapTrackingPinButtonTemplate(Button)
        end
        function Skin.WorldMapNavBarTemplate(Frame)
            Skin.NavBarTemplate(Frame)  -- this is skinned from hooks in NavigationBar.lua
            Frame.InsetBorderBottomLeft:Hide()
            Frame.InsetBorderBottomRight:Hide()
            Frame.InsetBorderBottom:Hide()
            Frame.InsetBorderLeft:Hide()
            Frame.InsetBorderRight:Hide()
        end

        local function SkinQuestToggle(Button, arrowDir)
            Skin.FrameTypeButton(Button)
            Button:SetAllPoints()

            local arrow = Button:CreateTexture(nil, "ARTWORK")
            arrow:SetPoint("TOPLEFT", 5, -9)
            arrow:SetPoint("BOTTOMRIGHT", -20, 9)
            arrow:SetVertexColor(Color.yellow:GetRGB())
            Base.SetTexture(arrow, "arrow"..arrowDir)

            local quest = Button:CreateTexture(nil, "ARTWORK")
            quest:SetAtlas("questlog-waypoint-finaldestination-questionmark", true)
            quest:SetPoint("TOPLEFT", 11, -1)
        end
        function Skin.WorldMapSidePanelToggleTemplate(Frame)
            SkinQuestToggle(Frame.OpenButton, "Right")
            SkinQuestToggle(Frame.CloseButton, "Left")
        end
        function Skin.WorldMapZoneTimerTemplate(Frame)
        end
    end

    do --[[ Blizzard_WorldMap.xml ]]
        function Skin.WorldMapFrameTemplate(Frame)
            Skin.MapCanvasFrameTemplate(Frame)
            Skin.MapCanvasFrameScrollContainerTemplate(Frame.ScrollContainer)
        end
    end

end

function private.AddOns.Blizzard_WorldMap()
    ----====####$$$$%%%%%$$$$####====----
    --        Blizzard_WorldMap        --
    ----====####$$$$%%%%%$$$$####====----
    local WorldMapFrame = _G.WorldMapFrame
    Skin.WorldMapFrameTemplate(WorldMapFrame)
    Util.Mixin(WorldMapFrame, Hook.WorldMapMixin)

    Skin.PortraitFrameTemplate(WorldMapFrame.BorderFrame)
    WorldMapFrame.BorderFrame:SetFrameStrata(WorldMapFrame:GetFrameStrata())

    WorldMapFrame.BorderFrame.InsetBorderTop:Hide()
    Skin.MainHelpPlateButton(WorldMapFrame.BorderFrame.Tutorial)
    WorldMapFrame.BorderFrame.Tutorial:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", -15, 15)
    Skin.MaximizeMinimizeButtonFrameTemplate(WorldMapFrame.BorderFrame.MaximizeMinimizeFrame)

    Skin.WorldMapFloorNavigationFrameTemplate(WorldMapFrame.overlayFrames[1])
    Skin.WorldMapTrackingOptionsButtonTemplate(WorldMapFrame.overlayFrames[2])
    WorldMapFrame.overlayFrames[2]:SetPoint("TOPRIGHT", WorldMapFrame:GetCanvasContainer(), "TOPRIGHT", 0, 0)
    Skin.WorldMapTrackingPinButtonTemplate(WorldMapFrame.overlayFrames[3])
    Skin.WorldMapBountyBoardTemplate(WorldMapFrame.overlayFrames[4])
    Skin.WorldMapActionButtonTemplate(WorldMapFrame.overlayFrames[5])
    Skin.WorldMapZoneTimerTemplate(WorldMapFrame.overlayFrames[6])

    Skin.WorldMapNavBarTemplate(WorldMapFrame.NavBar)
    WorldMapFrame.NavBar:SetPoint("BOTTOMRIGHT", WorldMapFrame.TitleCanvasSpacerFrame, -5, 5)

    Skin.WorldMapSidePanelToggleTemplate(WorldMapFrame.SidePanelToggle)
end

