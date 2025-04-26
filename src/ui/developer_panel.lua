local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local developer_panel = panel_prototype.New(true)
function developer_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/developer_panel.csb")

    self:RegisterWidgetEvent()
end


function developer_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
end

return developer_panel
