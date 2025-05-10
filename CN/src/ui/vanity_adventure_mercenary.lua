local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"
local troop_logic = require "logic.troop"
local graphic = require "logic.graphic"

local vanity_adventure_mercenary = panel_prototype.New(true)

function vanity_adventure_mercenary:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/vanity_adventure_mercenary.csb")
    self.save_mercenary_btn = self.root_node:getChildByName("confirm_btn")
    self.maze_id = 0
    self:RegisterWidgetEvent()
end

--获得通关所获得佣兵提示面板
function vanity_adventure_mercenary:Show(maze_id)
    --要领取关卡的id
    self.maze_id = maze_id
    self.root_node:setVisible(true)
end

function vanity_adventure_mercenary:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close1_btn"), self:GetName())

    self.save_mercenary_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            if self.maze_id and self.maze_id ~= 0 then
                troop_logic:GetVanityMercenaryByMazeId(self.maze_id)
            end
        end
    end)
end

return vanity_adventure_mercenary

