local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"

local PLIST_TYPE = ccui.TextureResType.plistType


local ladder_tournament_rule_msgbox = panel_prototype.New(true)
function ladder_tournament_rule_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/ladder_tournament_rule_msgbox.csb")
    self.back_btn = self.root_node:getChildByName("close_btn")

    self:RegisterWidgetEvent()
end

function ladder_tournament_rule_msgbox:Show()
    self.root_node:setVisible(true)
end

function ladder_tournament_rule_msgbox:RegisterWidgetEvent()
	--关闭按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)
end

return ladder_tournament_rule_msgbox

