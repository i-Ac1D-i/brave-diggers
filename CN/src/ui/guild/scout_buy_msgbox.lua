local panel_prototype = require "ui.panel"
local config_manager = require "logic.config_manager"
local audio_manager = require "util.audio_manager"
local graphic = require "logic.graphic"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local spine_manager = require "util.spine_manager"

local guild_logic = require "logic.guild"

local panel_util = require "ui.panel_util"

local PLIST_TYPE = ccui.TextureResType.plistType
local SUB_PANEL_HEIGHT = 160
local FIRST_SUB_PANEL_OFFSET = -20
local MAX_SUB_PANEL_NUM = 7

local scout_buy_msgbox = panel_prototype.New(true)
function scout_buy_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/guildwar_scout_detail_panel.csb")

    self.close_btn = self.root_node:getChildByName("close_btn")
    self.view_btn = self.root_node:getChildByName("view_btn")

    self.scout_panels = {}

    self.scout_btns = {}
    self.scout_name_texts = {}
    self.cost_num_tests = {}

    for i = 1, 3 do
        local panel = self.root_node:getChildByName("panel" .. i)
        self.scout_btns[i] = panel:getChildByName("scout_btn")
        self.scout_btns[i]:setTag(i)
        self.scout_name_texts[i] = panel:getChildByName("scouted_bg"):getChildByName("desc")

        self.cost_num_tests[i] = panel:getChildByName("resource_num")

        self.scout_panels[i] = panel
    end

    self.spine_node = spine_manager:GetNode("box_all", 1.0, true)
    self.spine_node:setPosition(320, 580)
    self.root_node:addChild(self.spine_node, -1)

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function scout_buy_msgbox:Show()
    for i = 1, 3 do
        self.scout_panels[i]:setOpacity(0)
        self.scout_panels[i]:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.FadeIn:create(1)))
    end
    self.spine_node:setAnimation(0, "mail_black", false)

    self:Load()
    self.root_node:setVisible(true)
end

function scout_buy_msgbox:Load()
    for i = 1, 3 do
        local name, cost = guild_logic:GetScoutInfo(i)
        if name == "" then
            self.scout_btns[i]:setVisible(true)
            self.scout_name_texts[i]:getParent():setVisible(false)
            self.cost_num_tests[i]:setString(tostring(cost))

        else
            self.scout_btns[i]:setVisible(false)
            self.scout_name_texts[i]:getParent():setVisible(true)
            self.cost_num_tests[i]:setString(tostring(constants.SCOUT_GUILD_RIVAL_COST))

            self.scout_name_texts[i]:setString(lang_constants:GetFormattedStr("guild_war_has_scouted", name))
        end
    end
end

function scout_buy_msgbox:RegisterWidgetEvent()
    local scout_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if guild_logic:GetCurStatus() == client_constants.CLIENT_GUILDWAR_STATUS["before_match_end"] or guild_logic:GetCurStatus() == client_constants.CLIENT_GUILDWAR_STATUS["before_ready_end"] then 
                graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", client_constants.CONFIRM_MSGBOX_MODE["scout_guild_rival"], widget:getTag())
            else
                graphic:DispatchEvent("show_prompt_panel", "guild_scout_wrong_status")
            end
        end
    end

    for i = 1, 3 do
        self.scout_btns[i]:addTouchEventListener(scout_method)
    end

    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())

    self.view_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            graphic:DispatchEvent("show_world_sub_panel", "guild.scout_main_panel")
        end
    end)
end

function scout_buy_msgbox:RegisterEvent()
    graphic:RegisterEvent("update_guild_scout_info", function()
        if not self.root_node:isVisible() then
            return
        end

        self:Load()
    end)
end

return scout_buy_msgbox
