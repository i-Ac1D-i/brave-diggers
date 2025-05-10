local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local graphic = require "logic.graphic"

local cultivation_rule_msgbox = panel_prototype.New(true)
function cultivation_rule_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/cultivation_rule_msgbox.csb")

    self.close_btn = self.root_node:getChildByName('close_btn')

    self.close_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                graphic:DispatchEvent("hide_world_sub_panel", "cultivation_rule_msgbox")   
            end
        end)
end

return cultivation_rule_msgbox