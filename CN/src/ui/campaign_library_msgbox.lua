local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local campaign_logic = require "logic.campaign"
local lang_constants = require "util.language_constants"
local troop_logic = require "logic.troop"
local panel_util = require "ui.panel_util"
local graphic = require "logic.graphic"
local client_constants = require "util.client_constants"


local campaign_library_msgbox = panel_prototype.New(true)
function campaign_library_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/campaign_story_panel.csb")

    local info = self.root_node:getChildByName("info")

    self.title_text = info:getChildByName("title")
    self.desc_text = info:getChildByName("desc")
    self.back_btn = info:getChildByName("confirm_btn")

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function campaign_library_msgbox:Show()
    self.root_node:setVisible(true)

    self.title_text:setString(lang_constants:Get("campaign_library_title"))
    self.desc_text:setString(lang_constants:Get("campaign_library_desc"))
end


function campaign_library_msgbox:RegisterEvent()

    
end

function campaign_library_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.back_btn, "campaign_library_msgbox")

end

return campaign_library_msgbox
