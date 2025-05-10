local graphic = require "logic.graphic"
local panel_prototype = require "ui.panel"
local config_manager = require "logic.config_manager"
local audio_manager = require "util.audio_manager"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local ladder_logic = require "logic.ladder"
local time_logic = require "logic.time"
local guild_logic = require "logic.guild"
local vip_logic = require "logic.vip"
local chat_logic = require "logic.chat"

local spine_manager = require "util.spine_manager"

local panel_util = require "ui.panel_util"

local PLIST_TYPE = ccui.TextureResType.plistType


local guild_main_panel = panel_prototype.New()
function guild_main_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/guild_panel.csb")
    local root_node = self.root_node

    self.back_btn = root_node:getChildByName("back_btn")
    self.search_btn = root_node:getChildByName("search_btn")
    self.invitation_btn = root_node:getChildByName("invitation_btn")
    self.invitation_tip = self.invitation_btn:getChildByName("num_bg")
    self.invitation_tip_value_txt = self.invitation_btn:getChildByName("num")

    self.guild_desc_txt = root_node:getChildByName("guild_desc")

    self.list_btn = root_node:getChildByName("list_btn")
    self.list_tip = root_node:getChildByName("list_tip")
    self.list_tip_value_txt = self.list_tip:getChildByName("value")
    self.discuss_btn = root_node:getChildByName("discuss_btn")
    self.discuss_tip = root_node:getChildByName("discuss_tip")
    self.discuss_tip_value = self.discuss_tip:getChildByName("value")
    self.found_btn = root_node:getChildByName("found_btn")

    self.guild_id_bg = root_node:getChildByName("guild_id_bg")
    self.guild_id_txt = self.guild_id_bg:getChildByName("guild_desc_1")

    self.setting_btn = root_node:getChildByName("setting_btn")
    self.setting_btn:setVisible(false)

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function guild_main_panel:Show()
    self.root_node:setVisible(true)

    if guild_logic:IsGuildMember() then
        self.guild_desc_txt:setString(guild_logic.guild_name)
        self.guild_id_txt:setString(string.format(lang_constants:Get("guild_title"), guild_logic.guild_id))

        self.found_btn:setVisible(false)
        self.list_btn:setVisible(true)
        self.discuss_btn:setVisible(true)
        self:RefreshMemberTips()
        self:RefreshNoticeTips()
        self.guild_id_bg:setVisible(true)

    else
        self.guild_desc_txt:setString(lang_constants:Get("guild_none"))
        
        self.list_btn:setVisible(false)
        self.list_tip:setVisible(false)
        self.discuss_btn:setVisible(false)
        self.discuss_tip:setVisible(false)
        self.found_btn:setVisible(true)
        self.guild_id_bg:setVisible(false)
        self.setting_btn:setVisible(false)
    end
    self:RefreshBbsTips()
end

function guild_main_panel:RefreshBbsTips()
    local num = chat_logic.new_mine_guild
    if num > 0 then
        self.discuss_tip:setVisible(true)
        self.discuss_tip_value:setString(num)
    else
        self.discuss_tip:setVisible(false)
    end
end

function guild_main_panel:RefreshMemberTips()
    local num = guild_logic:GetMemberUnReadNum()
    if num > 0 then
        self.list_tip:setVisible(true)
        self.list_tip_value_txt:setString(num)
    else
        self.list_tip:setVisible(false)
    end
end

function guild_main_panel:RefreshNoticeTips()
    local num = guild_logic:GetNoticeUnReadNum()
    if num > 0 and not guild_logic.is_notice_notifiy then
        self.invitation_tip:setVisible(true)
        self.invitation_tip_value_txt:setVisible(true)
        self.invitation_tip_value_txt:setString(num)
    else
        self.invitation_tip:setVisible(false)
        self.invitation_tip_value_txt:setVisible(false)
    end
end

function guild_main_panel:RegisterEvent()
    graphic:RegisterEvent("join_guild", function(is_creator)
        if not self.root_node:isVisible() then
            return
        end

        if is_creator then
            audio_manager:PlayEffect("guild_build_success")
        end

        self:Show()
    end)

    graphic:RegisterEvent("exit_guild", function()
        if not self.root_node:isVisible() then
            return
        end

        self:Show()
    end)

    graphic:RegisterEvent("refresh_member_tips", function(num)
        if not self.root_node:isVisible() then
            return
        end

        self:RefreshMemberTips()
    end)

    graphic:RegisterEvent("update_guild_member", function(num)
        if not self.root_node:isVisible() then
            return
        end

        self:RefreshMemberTips()
    end)

    graphic:RegisterEvent("refresh_notice_tips", function(num)
        if not self.root_node:isVisible() then
            return
        end

        audio_manager:PlayEffect("guild_notice")
        self:RefreshNoticeTips()
    end)

    graphic:RegisterEvent("refresh_guild_chairman", function()
        if not self.root_node:isVisible() then
            return
        end

        self.setting_btn:setVisible(guild_logic:IsGuildChairman())
    end)
end

function guild_main_panel:RegisterWidgetEvent()
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    -- 创建公会
    self.found_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if vip_logic:IsActivated(constants["VIP_TYPE"]["adventure"]) then
                graphic:DispatchEvent("show_world_sub_panel", "guild_create_msgbox")
            else
                graphic:DispatchEvent("show_prompt_panel", "guild_create_error")
            end
        end
    end)

    -- 搜索公会
    self.search_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "guild_search_panel")
        end
    end)

    -- 设置公会
    self.setting_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "guild_setting_msgbox")
        end
    end)

    -- 查看公会成员
    self.list_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            guild_logic:ReadMemberList()
        end
    end)

    -- 查看公会讨论区
    self.discuss_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "bbs_sub_scene", false, "guild")
        end
    end)

    -- 查看通知
    self.invitation_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            guild_logic:ReadNoticeList()
        end
    end)
end

return guild_main_panel
