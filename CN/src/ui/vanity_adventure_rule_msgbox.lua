
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"


local vanity_adventure_rule_msgbox = panel_prototype.New(true)
function vanity_adventure_rule_msgbox:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/vanity_adventure_rule_msgbox.csb")

    self:RegisterWidgetEvent()
end

function vanity_adventure_rule_msgbox:Show()
    self.root_node:setVisible(true)
end

function vanity_adventure_rule_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
end

return vanity_adventure_rule_msgbox

