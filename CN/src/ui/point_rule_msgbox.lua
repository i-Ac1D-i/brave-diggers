local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local graphic = require "logic.graphic"

local point_rule_msgbox = panel_prototype.New(true)
function point_rule_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/point_rule_msgbox.csb")

    self.close_btn = self.root_node:getChildByName('close_btn')

    self.close_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                graphic:DispatchEvent("hide_world_sub_panel", "point_rule_msgbox")   
            end
        end)
end

return point_rule_msgbox