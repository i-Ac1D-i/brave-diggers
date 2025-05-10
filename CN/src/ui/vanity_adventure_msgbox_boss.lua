
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"
local troop_logic = require "logic.troop"
local graphic = require "logic.graphic"

local vanity_adventure_msgbox_boss = panel_prototype.New(true)
function vanity_adventure_msgbox_boss:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/vanity_adventure_msgbox_boss.csb")

    self.ok_btn = self.root_node:getChildByName("confirm_btn")

    self.formation_btn = self.root_node:getChildByName("canel_btn")

    self:RegisterWidgetEvent()
end

function vanity_adventure_msgbox_boss:Show(vanity_maze_id)
    self.root_node:setVisible(true)
    self.maze_id = vanity_maze_id
end

function vanity_adventure_msgbox_boss:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
    
    --阵容调整按钮
    self.formation_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            graphic:DispatchEvent("hide_world_sub_panel", "vanity_adventure_stagestart")
            graphic:DispatchEvent("show_world_sub_scene", "vanity_adventure_sub_scene", self.maze_id)
        end
    end)

    --开始战斗按钮
    self.ok_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            troop_logic:FightingByMazeId(self.maze_id)   
        end
    end)
end

return vanity_adventure_msgbox_boss

