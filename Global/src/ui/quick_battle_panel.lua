local graphic = require "logic.graphic"
local panel_util = require "ui.panel_util"
local panel_prototype = require "ui.panel"
local adventure_logic = require "logic.adventure"
local config_manager = require "logic.config_manager"
local network = require "util.network"
local lang_constants = require "util.language_constants"
local audio_manager = require "util.audio_manager"

local quick_battle_panel = panel_prototype.New(true)
function quick_battle_panel:Init(root_node)

    self.root_node = cc.CSLoader:createNode("ui/quick_battle_panel.csb")
    self.desc = self.root_node:getChildByName("desc")
    self.confirm_btn = self.root_node:getChildByName("confirm_btn")
    self.bd_num = self.confirm_btn:getChildByName("Text_4")

    self:RegisterWidgetEvent()
end

function quick_battle_panel:Show()
    self.root_node:setVisible(true)
    
    local adventure_buy_config = config_manager.adventure_buy_config
    local next_info = adventure_buy_config[adventure_logic.buy_adventure_num+1]

    if not next_info then
        self.confirm_btn:setVisible(false)
    else
        self.desc:setString(string.format(lang_constants:Get("quick_battle_panel_desc"), math.ceil(next_info.mins/60)))
        self.bd_num:setString(string.format("%d", next_info.price))
        self.confirm_btn:setVisible(true)
    end
end

function quick_battle_panel:RegisterWidgetEvent()

    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            network:Send({ buy_adventure_reward = {} })

        end
    end)

    --关闭
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close1_btn"), self:GetName())
end

return quick_battle_panel

