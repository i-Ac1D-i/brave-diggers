local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local graphic = require "logic.graphic"
local audio_manager = require "util.audio_manager"
local user_logic = require "logic.user"
local configuration = require "util.configuration"
local platform_manager = require "logic.platform_manager"
local http_client = require "logic.http_client"
local json = require "util.json"
local share_logic = require "logic.share"
local constants = require "util.constants"
local resource_logic = require "logic.resource"
local lang_constants = require "util.language_constants"
local troop_logic = require "logic.troop"
local new_mercenarys_panel = require "ui.new_vanity_mercenarys_panel"

local client_constants = require "util.client_constants"
local PLIST_TYPE = ccui.TextureResType.plistType
local RESOURCE_TYPE = constants.RESOURCE_TYPE

local show_mercenarys_list_panel = panel_prototype.New(true)

function show_mercenarys_list_panel:Init()
    self.root_node = cc.Node:create()

    self.mercenary_sub_panel = new_mercenarys_panel 
    self.mercenary_sub_panel:Init()
    self.root_node:addChild(self.mercenary_sub_panel.root_node)
    
    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function show_mercenarys_list_panel:Show(mercenary_list)
    self.root_node:setVisible(true)
    self.mercenary_sub_panel:Hide()
    
    local list = {}
    local num = 0
    for k,mercenary_info in pairs(mercenary_list) do
        num = num + 1
        table.insert(list, troop_logic:InitMercenaryInfoByConfig(mercenary_info))
    end
    
    self.mercenary_sub_panel:Show(list, num, 1)
end



function show_mercenarys_list_panel:RegisterWidgetEvent()
    -- self.close_btn:addTouchEventListener(function(widget, event_type)
    --     if event_type == ccui.TouchEventType.ended then
    --         audio_manager:PlayEffect("click")
    --         graphic:DispatchEvent("hide_world_sub_scene")
    --     end
    -- end)
end

function show_mercenarys_list_panel:Update(elapsed_time)

    if self.mercenary_sub_panel then
        self.mercenary_sub_panel:Update(elapsed_time)
        if self.mercenary_sub_panel.can_leave_reward then
            self.mercenary_sub_panel:Hide()
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            troop_logic:ShowGetVanityMercenary()
        end
    end
end

function show_mercenarys_list_panel:RegisterEvent()
   
end

return show_mercenarys_list_panel
