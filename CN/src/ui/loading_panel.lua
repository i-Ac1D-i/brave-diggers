local panel_prototype = require "ui.panel"

local loading_panel = panel_prototype.New()

function loading_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/loading_panel.csb")

    self.total_bar = self.root_node:getChildByName("total_lbar")
    self.percentage_text = self.root_node:getChildByName("percentage")
    self.desc_text = self.root_node:getChildByName("desc")
end

function loading_panel:GetRootNode()
    return self.root_node
end

function loading_panel:UpdatePercentage(percent)
    self.total_bar:setPercent(percent)
    self.percentage_text:setString(percent .. "%")
end

return loading_panel


