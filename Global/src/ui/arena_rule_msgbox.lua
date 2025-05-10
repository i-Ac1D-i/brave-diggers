local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local platform_manager = require "logic.platform_manager"
local arena_rule_msgbox = panel_prototype.New(true)
function arena_rule_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/arena_rule_msgbox.csb")
    local channel_info = platform_manager:GetChannelInfo()
    local append_height = channel_info.append_height_arena_rule_msgbox
    local scroll_view = self.root_node:getChildByName("scrol_view")
    if append_height then
        local childName = "desc"
        for i=1,5 do
        	local child = scroll_view:getChildByName(childName..i) 
        	local origin_size = child:getContentSize();
            if i == 3 or i==5 then
                 append_height = append_height*2
            end

        	origin_size.height = origin_size.height + append_height
            child:setContentSize(origin_size)
        end
    end

    if channel_info.append_height_arena_rule_msgbox_desc4_fix then
        local desc4 = scroll_view:getChildByName("desc4") 
        desc4:setPositionY(desc4:getPositionY() - channel_info.append_height_arena_rule_msgbox_desc4_fix)
    end
   --FYD
    if channel_info.append_height_arena_rule_msgbox_desc5_fix then
        local d_pos = channel_info.append_height_arena_rule_msgbox_desc5_fix
        local desc5 = scroll_view:getChildByName("desc5") 
        desc5:setPositionY(desc5:getPositionY() - d_pos.y) 
        --左对齐
        desc5:setPositionX(desc5:getPositionX() - d_pos.x)   
    end

    self:RegisterWidgetEvent()
end

function arena_rule_msgbox:Show()
    self.root_node:setVisible(true)
end

function arena_rule_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), "arena_rule_msgbox")
end

return arena_rule_msgbox
