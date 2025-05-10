local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"
local graphic = require "logic.graphic"
local sns_rule_panel = panel_prototype.New(true) 

function sns_rule_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/carnival_facebook_rule_panel.csb")
    self.close_btn = self.root_node:getChildByName('close_btn') 
    self:RegisterWidgetEvent()
end

function sns_rule_panel:Show(callback)
    self.root_node:setVisible(true)

end

function sns_rule_panel:RegisterWidgetEvent()
    
    self.close_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", "sns_rule_panel") 
        end
    end)
end

return sns_rule_panel
