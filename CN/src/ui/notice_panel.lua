local graphic = require "logic.graphic"
local panel_util = require "ui.panel_util"
local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"
local notice_logic = require "logic.notice"
local constants = require "util.constants"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"
local json = require "util.json"

-- title img desc 之间的间隔
local V_MARGIN = 40
local TITLE_LINE_HEIGHT = 35
local DESC_LINE_HEIGHT = 27

local notice_panel = panel_prototype.New(true)

function notice_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/notice_panel.csb")

    self.container_pos_y = 0

    self.close_btn = self.root_node:getChildByName("close_btn")
    self.back_top_btn = self.root_node:getChildByName("back_top_btn")

    self.scroll_view = self.root_node:getChildByName("scrollview")
    self.sview_size = self.scroll_view:getContentSize()

    self.notice_title_text = self.scroll_view:getChildByName("notice_title")
    self.notice_desc_text = self.scroll_view:getChildByName("title_desc")
    self.notice_desc_text:ignoreContentAdaptWithSize(true)
    self.notice_desc_text:getVirtualRenderer():setMaxLineWidth(486)

    self:RegisterWidgetEvent()
end

function notice_panel:Show(mode)
    if mode == 1 then
        notice_logic:SetNewNotice(false)
        local notice_info = notice_logic:GetNoticeInfo()
        self:Load(notice_info["title"], notice_info["desc"])

    elseif mode == 2 then
        self:Load(lang_constants:Get("first_pay_btn2"), lang_constants:Get("vip_invitation"))
    end

    self.mode = mode

    self.scroll_view:getInnerContainer():setPositionY(self.container_pos_y)
    self.back_top_btn:setVisible(false)

    self.root_node:setVisible(true)
end

function notice_panel:Load(title_str, desc_str)
    -- 填内容
    if platform_manager:GetChannelInfo().use_locale_notic then
        local title_table = json:decode(title_str)
        title_str = title_table["title"]
        if title_table["title_"..platform_manager:GetLocale()] then
            title_str = title_table["title_"..platform_manager:GetLocale()]
        end

        local desc_table = json:decode(desc_str)
        desc_str = desc_table["desc"]
        if desc_table["desc_"..platform_manager:GetLocale()] then
            desc_str = desc_table["desc_"..platform_manager:GetLocale()]
        end
    end

    self.notice_title_text:setString(title_str)
    self.notice_desc_text:setString(desc_str)

    local desc_render = self.notice_desc_text:getVirtualRenderer()
    local line_num = desc_render:getStringNumLines()
    if platform_manager:GetChannelInfo().is_open_system then
        local size = self.notice_desc_text:getAutoRenderSize()
        local content_size = desc_render:getContentSize()
        line_num = math.ceil(size.width / content_size.width)
    end 
    local desc_height = line_num * DESC_LINE_HEIGHT

    local sview_container_height = desc_height + V_MARGIN + TITLE_LINE_HEIGHT + V_MARGIN + V_MARGIN

    local height = math.max(sview_container_height, self.sview_size.height)
    self.scroll_view:setInnerContainerSize(cc.size(self.sview_size.width, height))

    local title_pos_y = height - TITLE_LINE_HEIGHT

    self.notice_title_text:setPositionY(title_pos_y)
    self.notice_desc_text:setPositionY(title_pos_y - TITLE_LINE_HEIGHT - V_MARGIN)

    --scroll_view 内部容器pos_y
    self.container_pos_y  = self.sview_size.height - height
end

function notice_panel:RegisterWidgetEvent()
    -- scroll view
    self.scroll_view:addEventListener(function(lview, event_type)
        if event_type == ccui.ScrollViewEventType.scrolling then
            local y = self.scroll_view:getInnerContainer():getPositionY()
            self.back_top_btn:setVisible(y > self.container_pos_y)
        end
    end)

    -- back to top
    self.back_top_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            self.scroll_view:getInnerContainer():setPositionY(self.container_pos_y)

            audio_manager:PlayEffect("click")
            self.back_top_btn:setVisible(false)
        end
    end)

    --关闭按钮
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())
end

return notice_panel
