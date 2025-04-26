local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local platform_manager = require "logic.platform_manager"
local ladder_rule_msgbox = panel_prototype.New(true)
function ladder_rule_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/ladder_rule_msgbox.csb")
    local append_height = platform_manager:GetChannelInfo().append_height_ladder_rule_desc;
    if append_height then
        local scroll_view = self.root_node:getChildByName("scrol_view")
        local childName = "desc"
        for i=1,2 do
        	local child = scroll_view:getChildByName(childName..i) 
        	local origin_size = child:getContentSize();
        	origin_size.height = origin_size.height + append_height
            child:setContentSize(origin_size)
        end
    end

    self:RegisterWidgetEvent()
end

function ladder_rule_msgbox:Show()
    self.root_node:setVisible(true)
end

function ladder_rule_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), "ladder_rule_msgbox")
end

return ladder_rule_msgbox
