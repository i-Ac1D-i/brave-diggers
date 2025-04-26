local panel_prototype = require "ui.panel"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local carnival_logic = require "logic.carnival"
local notice_logic = require "logic.notice"
local time_logic = require "logic.time"

local client_constants = require "util.client_constants"
local constants = require "util.constants"
local lang_constants = require "util.language_constants"

local audio_manager = require "util.audio_manager"

local panel_util = require "ui.panel_util"
local icon_template = require "ui.icon_panel"
local platform_manager = require "logic.platform_manager"

local V_MARGIN = 40
local TITLE_LINE_HEIGHT = 35
local DESC_LINE_HEIGHT = 27
local MAX_SUB_PANEL_NUM = 5


local version_update_panel = panel_prototype.New(true)
function version_update_panel:Init()
    --加载csb
    self.root_node = cc.CSLoader:createNode("ui/version_update_panel.csb")
    self.scroll_view = self.root_node:getChildByName("scrollview")

    self.sview_size = self.scroll_view:getContentSize()
    self.notice_title_text = self.scroll_view:getChildByName("notice_title")
    self.notice_desc_text = self.scroll_view:getChildByName("title_desc")
    self.notice_desc_text:ignoreContentAdaptWithSize(true)
    self.notice_desc_text:getVirtualRenderer():setMaxLineWidth(420)
    self.back_top_btn = self.root_node:getChildByName("back_top_btn")

    self.version_text = self.root_node:getChildByName("version_text")

    local begin_x, begin_y, interval_x = 160, 410, 80

    self.icon_sub_panels = {}
    --默认创建6个奖励
    for i = 1, MAX_SUB_PANEL_NUM do
        local sub_panel = icon_template.New()
        sub_panel:Init(self.root_node)
        sub_panel.root_node:setPosition(begin_x + (i - 1) * interval_x, begin_y)
        self.icon_sub_panels[i] = sub_panel
    end

    self.confirm_btn = self.root_node:getChildByName("confirm_btn")

    self.container_pos_y  = 0
    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function version_update_panel:Show()
    self.root_node:setVisible(true)

    self:Load()
    local config = carnival_logic:GetSpecialCarnival(client_constants.CARNIVAL_TEMPLATE_TYPE["version_update"])

    if not config then
        return
    end

    self.config = config
    local reward_list = config.reward_list[1].reward_info

    for i = 1, MAX_SUB_PANEL_NUM do
        local sub_panel = self.icon_sub_panels[i]
        if i <= #reward_list then
            local re = reward_list[i]
            sub_panel:Show(re.reward_type, re.param1, re.param2,  false, false)
        end
    end

    panel_util:SetIconSubPanelsPosition(self.icon_sub_panels, 5, #reward_list, 410)
    self.is_update = platform_manager:IsUpdateToDate()

    if self.is_update then
        self.confirm_btn:setTitleText(lang_constants:Get("take_vip_reward"))
        self.version_text:setString(lang_constants:Get("carnival_is_lastest_version"))

    else
        self.confirm_btn:setTitleText(lang_constants:Get("download_lastest_client"))
        self.version_text:setString(lang_constants:Get("carnival_not_lastest_version"))
    end
end

function version_update_panel:Load()
    -- 填内容
    local notice_info = notice_logic:GetNoticeInfo()
    self.notice_title_text:setString(notice_info["title"])
    self.notice_desc_text:setString(notice_info["desc"])

    local desc_render = self.notice_desc_text:getVirtualRenderer()
    local desc_height = desc_render:getStringNumLines() * DESC_LINE_HEIGHT

    local sview_container_height = desc_height + V_MARGIN + TITLE_LINE_HEIGHT + V_MARGIN + V_MARGIN

    local height = math.max(sview_container_height, self.sview_size.height)
    self.scroll_view:setInnerContainerSize(cc.size(self.sview_size.width, height))

    local title_pos_y = height - TITLE_LINE_HEIGHT

    self.notice_title_text:setPositionY(title_pos_y)
    self.notice_desc_text:setPositionY(title_pos_y - TITLE_LINE_HEIGHT - V_MARGIN)

    --scroll_view 内部容器pos_y

    self.container_pos_y  = self.sview_size.height - height
end


function version_update_panel:RegisterEvent()
    -- todo 领取奖励
    graphic:RegisterEvent("update_sub_carnival_reward_status", function(key, step)
        if not self.root_node:isVisible() then
            return
        end

        if key ~= self.config.key then
            return
        end

    end)
end

function version_update_panel:RegisterWidgetEvent()

    -- scroll view
    self.scroll_view:addEventListener(function(lview, event_type)
        if event_type == ccui.ScrollViewEventType.scrolling then
            local y = self.scroll_view:getInnerContainer():getPositionY()
            local visible = y <= self.container_pos_y and false or true
            self.back_top_btn:setVisible(visible)
        end
    end)

    -- take reward
    self.back_top_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.scroll_view:getInnerContainer():setPositionY(self.container_pos_y)
            self.back_top_btn:setVisible(false)
        end
    end)

    -- take reward
    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.is_update then
                carnival_logic:TakeReward(self.config, 1, false)
            else
                cc.Application:getInstance():openURL("https://appsto.re/cn/43Eb6.i")
            end
        end
    end)

    --关闭按钮
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
end

return version_update_panel
