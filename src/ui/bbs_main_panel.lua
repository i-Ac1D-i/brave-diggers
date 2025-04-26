local graphic = require "logic.graphic"
local panel_util = require "ui.panel_util"
local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"
local time_logic = require "logic.time"
local chat_logic = require "logic.chat"
local guild_logic = require "logic.guild"
local feature_config = require "logic.feature_config"
local cjson = require "util.json"
local platform_manager = require "logic.platform_manager"
local client_constants = require "util.client_constants"
local constants = require "util.constants"
local lang_constants = require "util.language_constants"
local configuration = require "util.configuration"

local reuse_scrollview = require "widget.reuse_scrollview"

local PLIST_TYPE = ccui.TextureResType.plistType

local MARGIN = 5
local FIRST_SUB_PANEL_OFFSET = -30
local MAX_SUB_PANEL_NUM = 7
local SUB_PANEL_HEIGHT = 0

local BG_SPEC = 0xFFB9B9 -- 后台发布讨论背景
local BG_NORMAL = 0xFFFFFF -- 普通讨论背景

local TAB_TYPE =
{
    ["all"] = 1,
    ["guild"] = 2,
    ["mine"] = 3,
}

local discuss_sub_panel = panel_prototype.New()
discuss_sub_panel.__index = discuss_sub_panel

function discuss_sub_panel.New()
    return setmetatable({}, discuss_sub_panel)
end

function discuss_sub_panel:Init(root_node, index)
    self.root_node = root_node

    self.role_img = root_node:getChildByName("user_icon")
    self.name_text = root_node:getChildByName("user_name")
    self.time_text = root_node:getChildByName("time")
    self.detail_text = root_node:getChildByName("discuss_detail")

    self.reply_num_text = root_node:getChildByName("discuss_num")

    self.root_node:setTag(index)
end

function discuss_sub_panel:Show(discuss)
    local content = discuss
    content.discuss = content.discuss or ""
    self.name_text:setString(content.role)

    self.detail_text:setString(content.discuss)

    local date = time_logic:GetDateInfo(content.time)
    if platform_manager:GetLocale() == "en-US" then
        self.time_text:setString(string.format("%02d/%02d/%d %d:%d:%d", date.month, date.day, date.year, date.hour, date.min, date.sec))
    elseif platform_manager:GetLocale() == "zh-CN" or platform_manager:GetLocale() == "zh-TW" then
        self.time_text:setString(string.format("%d/%02d/%02d %d:%d:%d", date.year, date.month, date.day, date.hour, date.min, date.sec))
    else
        self.time_text:setString(string.format("%02d/%02d/%d %d:%d:%d", date.day, date.month, date.year, date.hour, date.min, date.sec))
    end

    self.role_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. content.icon .. ".png", PLIST_TYPE)
    self.role_img:setScale(2, 2)

    if tonumber(content.user_type) == 1 then
        self.root_node:setColor(panel_util:GetColor4B(BG_SPEC))
    else
        self.root_node:setColor(panel_util:GetColor4B(BG_NORMAL))
    end

    self.reply_num_text:setString(tostring(discuss.num))

    self.root_node:setVisible(true)

    self.root_node.discuss = content
end

local bbs_main_panel = panel_prototype.New(true)
function bbs_main_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/discuss_main_panel.csb")
    self.back_btn = self.root_node:getChildByName("back_btn")

    self.new_discuss_btn = self.root_node:getChildByName("discuss_btn")
    if platform_manager:GetLocale() == "fr" and platform_manager:GetChannelInfo().bbs_main_panel_change_discuss_btn_text_pos_x then
        self.new_discuss_btn:getTitleRenderer():setPositionX(self.new_discuss_btn:getTitleRenderer():getPositionX() + 45)
    end

    self.back_top_btn = self.root_node:getChildByName("back_top_btn")

    self.guild_tab_btn = self.root_node:getChildByName("tab_discuss_guild")
    self.guild_tab_btn:setTag(TAB_TYPE["guild"])

    self.guild_tab_btn:setVisible(feature_config:IsFeatureOpen("guild"))

    self.all_tab_btn = self.root_node:getChildByName("tab_discuss")
    self.all_tab_btn:setTag(TAB_TYPE["all"])

    self.mine_tab_btn = self.root_node:getChildByName("tab_mine")
    self.mine_tab_btn:setTag(TAB_TYPE["mine"])

    self.tab_btns = {}
    self.tab_btns[TAB_TYPE["all"]] = self.all_tab_btn
    self.tab_btns[TAB_TYPE["guild"]] = self.guild_tab_btn
    self.tab_btns[TAB_TYPE["mine"]] = self.mine_tab_btn

    self.new_tips_img = self.root_node:getChildByName("new_tips")
    self.tips_num_text = self.new_tips_img:getChildByName("num")

    self.new_tips_img:setVisible(false)
    self.new_tips_img:setLocalZOrder(10)
    self.tips_num_text:setString("0")

    self.rotation = 0
    self.flush_flag = false

    self.loading_img = self.root_node:getChildByName("loading_img")
    self.loading_text = self.root_node:getChildByName("loading_text")

    self.discuss_list = self.root_node:getChildByName("discuss_list")

    self.template = self.root_node:getChildByName("template")
    self.template:getChildByName("user_icon"):ignoreContentAdaptWithSize(true)
    self.template:setVisible(false)

    self.discuss_list:setBounceEnabled(true)

    SUB_PANEL_HEIGHT = self.template:getContentSize().height + MARGIN

    self.back_top_btn:setVisible(false)

    self.discuss_sub_panels = {}
    self.sub_panel_num = 0

    self.bbs_list = {}

    self.reuse_scrollview = reuse_scrollview.New(self, self.discuss_list, self.discuss_sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return #self.parent_panel.bbs_list
        end,

        function(self, sub_panel, is_up)
            local index =  is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
            sub_panel:Show(self.parent_panel.bbs_list[index])
        end
    )

    self.height = 0
    self.data_offset = 0

    self.cur_tab_type = TAB_TYPE["all"]

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function bbs_main_panel:Show(default_tab_type)
    self.root_node:setVisible(true)

    self.cur_tab_type = TAB_TYPE[default_tab_type] or self.cur_tab_type

    if self.cur_tab_type == TAB_TYPE["all"] then
        chat_logic:QueryDiscussCommon()
    elseif self.cur_tab_type == TAB_TYPE["guild"] then
        chat_logic:QueryDiscussGuild()
    end

    self:UpdateTab(self.cur_tab_type)
    self:ResetData(self.cur_tab_type)
end

function bbs_main_panel:CreateSubPanels()
    local num = math.min(MAX_SUB_PANEL_NUM, #self.bbs_list)
    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = discuss_sub_panel.New()
        sub_panel:Init(self.template:clone(), i)

        self.discuss_sub_panels[i] = sub_panel
        sub_panel.root_node:addTouchEventListener(self.view_discuss_method)

        self.discuss_list:addChild(sub_panel.root_node)
    end

    self.sub_panel_num = num
end

function bbs_main_panel:ResetData(tab_type)

    if tab_type == TAB_TYPE["all"] then
        self.bbs_list = chat_logic.bbs_channel_common or {}
        self.new_discuss_btn:setVisible(true)

    elseif tab_type == TAB_TYPE["mine"] then
        self.new_discuss_btn:setVisible(false)
        self.bbs_list = chat_logic.bbs_channel_mine or {}

        -- 更新刷新时间
        configuration:SetFlushBBSTime(os.time())
        configuration:Save()

        graphic:DispatchEvent("new_bbs")
        chat_logic.new_mine_num = 0

    elseif tab_type == TAB_TYPE["guild"] then
        self.new_discuss_btn:setVisible(true)
        self.bbs_list = chat_logic.bbs_channel_guild or {}
    end

    -- 小绿点
    local new_mine = chat_logic.new_mine_num
    if new_mine > 0 then
        self.new_tips_img:setVisible(true)
        self.tips_num_text:setString(tostring(new_mine))
    else
        self.new_tips_img:setVisible(false)
    end

    self.loading_img:setVisible(false)
    self.loading_text:setVisible(false)

    self:CreateSubPanels()

    if self.cur_tab_type ~= tab_type then
        self.data_offset = 0

    else
        self.data_offset = self.reuse_scrollview.data_offset
    end

    self:UpdatePanel()
    self.cur_tab_type = tab_type
end

function bbs_main_panel:UpdatePanel()
    local count = #self.bbs_list

    self.height = math.max(SUB_PANEL_HEIGHT * count, self.reuse_scrollview.sview_height) + 30

    self.back_top_btn:setVisible(false)

    for i = 1, self.sub_panel_num do
        local discuss = self.bbs_list[i + self.data_offset]
        local sub_panel = self.discuss_sub_panels[i]

        if discuss then
            sub_panel:Show(discuss)
            sub_panel.root_node:setPositionY(self.height + FIRST_SUB_PANEL_OFFSET - (self.data_offset + i - 1) * SUB_PANEL_HEIGHT)

        else
            sub_panel:Hide()
        end
    end

    self.reuse_scrollview:Show(self.height, self.data_offset)
end

function bbs_main_panel:UpdateTab(tab_type)

    for i = 1, 3 do
        local is_selected = tab_type == i
        local tab_btn = self.tab_btns[i]

        if is_selected then
            tab_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
            tab_btn:setLocalZOrder(2)
        else
            tab_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
            tab_btn:setLocalZOrder(1)
        end
    end
end

function bbs_main_panel:RegisterWidgetEvent()

    --返回按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    --发起讨论
    self.new_discuss_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if not chat_logic:IsAuthorized() then
                -- 月卡购买提示
                graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("buy_vip_title"),
                            lang_constants:Get("chat_not_use_desc"),
                            lang_constants:Get("common_confirm"),
                            lang_constants:Get("common_cancel"),
                function()
                     graphic:DispatchEvent("show_world_sub_panel", "vip_panel")
                end)
                return
            end

            local channel_type = constants.BBS_CHANNEL.common
            if self.cur_tab_type  == TAB_TYPE["all"] then
                channel_type = constants.BBS_CHANNEL.common
            elseif self.cur_tab_type  == TAB_TYPE["guild"] then
                channel_type = constants.BBS_CHANNEL.guild
            end
            graphic:DispatchEvent("show_world_sub_scene", "bbs_new_disscuss_sub_scene", false, channel_type)
        end
    end)

    self.mine_tab_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            self:UpdateTab(TAB_TYPE["mine"])
            self:ResetData(TAB_TYPE["mine"])
        end
    end)

    self.all_tab_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            chat_logic:QueryDiscussCommon()

            self:UpdateTab(TAB_TYPE["all"])
            self:ResetData(TAB_TYPE["all"])
        end
    end)

    self.guild_tab_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if not guild_logic:IsGuildMember() then
                graphic:DispatchEvent("show_prompt_panel", "guild_not_member")
                return
            end

            chat_logic:QueryDiscussGuild()

            self:UpdateTab(TAB_TYPE["guild"])
            self:ResetData(TAB_TYPE["guild"])
        end
    end)

    self.back_top_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.back_top_btn:setVisible(false)
            self.reuse_scrollview:Show(self.height, 0)
            self:ResetData(self.cur_tab_type)
        end
    end)

    self.view_discuss_method =  function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            chat_logic:QueryDiscussDetail(widget.discuss)
        end
    end

    self.discuss_list:addEventListener(function(widget, event_type)
        if event_type == ccui.ScrollViewEventType.bounceTop then
            --隐藏返回顶部按钮
            self.back_top_btn:setVisible(false)

            if self.flush_flag then
                if self.cur_tab_type == TAB_TYPE["all"] then
                    chat_logic:QueryDiscussCommon(true)
                elseif self.cur_tab_type == TAB_TYPE["guild"] then
                    chat_logic:QueryDiscussGuild(true)
                else
                    self.loading_img:setVisible(false)
                    self.loading_text:setVisible(false)
                end
            end

        elseif event_type == ccui.ScrollViewEventType.scrolling then
            local cur_y = self.discuss_list:getInnerContainer():getPositionY()
            if cur_y < (self.reuse_scrollview.sview_height - self.height) then
                self.loading_img:setVisible(true)
                self.loading_text:setVisible(true)
                self.flush_flag = true
            else
                self.loading_img:setVisible(false)
                self.loading_text:setVisible(false)

                self.back_top_btn:setVisible(true)
            end

            self.reuse_scrollview:OnScrolling(widget, event_type)
        end
    end)
end

function bbs_main_panel:RegisterEvent()
    graphic:RegisterEvent("update_bbs_main_panel", function()
        if self.flush_flag then
            self.flush_flag = false
        end

        if not self.root_node:isVisible() then
            return
        end
        self:ResetData(self.cur_tab_type)
    end)

    graphic:RegisterEvent("update_bbs_detail_panel", function(discuss)
        if not self.root_node:isVisible() then
            return
        end
    end)
end

function bbs_main_panel:Update(elapsed_time)
    if self.loading_img:isVisible() then
        self.rotation = self.rotation + elapsed_time * 180
        self.loading_img:setRotation(self.rotation)
    end
end

return bbs_main_panel
