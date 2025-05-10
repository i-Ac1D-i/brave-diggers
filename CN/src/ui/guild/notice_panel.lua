local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local constants = require "util.constants"
local campaign_logic = require "logic.campaign"
local config_manager = require "logic.config_manager"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"
local lang_constants = require "util.language_constants"

local guild_logic = require "logic.guild"
local time_logic = require "logic.time"
local icon_template = require "ui.icon_panel"


local PLIST_TYPE = ccui.TextureResType.plistType
local MAX_SUB_PANEL_NUM = 5
local SUB_PANEL_HEIGHT = 124
local FIRST_SUB_PANEL_OFFSET = -60


-- 通知子面板
local notice_sub_panel = panel_prototype.New()
notice_sub_panel.__index = notice_sub_panel

function notice_sub_panel.New()
    return setmetatable({}, notice_sub_panel)
end

function notice_sub_panel:Init(root_node, index)
    root_node:setVisible(true)
    self.root_node = root_node
    self.root_node:setCascadeColorEnabled(false)
    self.root_node:setCascadeOpacityEnabled(false)

    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(root_node)
    self.icon_panel:SetPosition(55, 60)

    self.login_time = root_node:getChildByName("login_time")
    self.name = root_node:getChildByName("name")
end

function notice_sub_panel:Show(notice_info)
    self.root_node:setVisible(true)
    local type = notice_info.notice_type
    local template_id = notice_info.template_id
    self.icon_panel:Show(constants.REWARD_TYPE["mercenary"], template_id, nil, nil, false)
    self.name:setString(notice_info.name)
    local diff_time = time_logic:Now() - notice_info.create_time
    local str = panel_util:GetDiffTimeStr(diff_time)
    self.login_time:setString(string.format(lang_constants:GetGuildNotice(type), str, notice_info.param1))
end

local notice_panel = panel_prototype.New(true)
function notice_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/social_msgbox.csb")
    local root_node = self.root_node

    local search_msgbox = root_node:getChildByName("search_msgbox")
    search_msgbox:setVisible(false)
    local invite_player_msgbox = root_node:getChildByName("invite_player_msgbox")
    invite_player_msgbox:setVisible(false)
    self.deal_invitation_msgbox = root_node:getChildByName("deal_invitation_msgbox")
    self.deal_invitation_msgbox:setVisible(true)

    local desc_txt = self.deal_invitation_msgbox:getChildByName("desc")
    desc_txt:setString(lang_constants:Get("guild_notice_notify"))
    self.select_chk = self.deal_invitation_msgbox:getChildByName("select")


    local title_text = self.deal_invitation_msgbox:getChildByName("title_bg"):getChildByName("title")
    title_text:setString(lang_constants:Get("guild_notice_title"))

    local template = self.deal_invitation_msgbox:getChildByName("template")
    template:setVisible(false)
    self.guild_news_template = self.deal_invitation_msgbox:getChildByName("guild_news_template")
    self.guild_news_template:setVisible(false)

    self.scroll_view = self.deal_invitation_msgbox:getChildByName("scroll_view")

    self.notice_sub_panels = {}

    local sub_panel = notice_sub_panel.New()
    sub_panel:Init(self.guild_news_template:clone(), 1)
    sub_panel.root_node:setPositionX(0)
    self.notice_sub_panels[1] = sub_panel
    self.scroll_view:addChild(sub_panel.root_node)

    self.sub_panel_num = 1

    self.sview_height = self.scroll_view:getContentSize().height
    self.sview_width = self.scroll_view:getContentSize().width
    self.head_sub_panel_y = 0
    self.tail_sub_panel_y = 0
    self.head_sub_panel_index = 0
    self.notice_list = {}
    self:RegisterWidgetEvent()
end

function notice_panel:CreateSubPanels()
    local num = math.min(MAX_SUB_PANEL_NUM, self.notice_num)
    if self.sub_panel_num >= num then
        return
    end
    for i = self.sub_panel_num + 1, num do
        local sub_panel = notice_sub_panel.New()
        sub_panel:Init(self.guild_news_template:clone(), i)
        sub_panel.root_node:setPositionX(0)
        -- sub_panel.refuse_btn:addTouchEventListener(self.refuse_method)
        -- sub_panel.accept_btn:addTouchEventListener(self.accept_method)

        self.notice_sub_panels[i] = sub_panel
        self.scroll_view:addChild(sub_panel.root_node)

    end
    self.sub_panel_num = num
end

function notice_panel:Show()
    self.root_node:setVisible(true)

    self.notice_num = guild_logic:GetNoticeNum()
    self:CreateSubPanels()
    self:LoadNoticeInfo()

    self.select_chk:setSelected(guild_logic.is_notice_notify)

end

function notice_panel:LoadNoticeInfo()
    local height = math.max( self.notice_num * SUB_PANEL_HEIGHT, self.sview_height)


    for i = #self.notice_list, 1, -1 do
        table.remove(self.notice_list, i)
    end

    local notices = guild_logic:GetNoticeList()
    for i = #notices, 1, -1 do
        table.insert(self.notice_list, notices[i])
    end

    for i = 1, self.sub_panel_num do
        local sub_panel = self.notice_sub_panels[i]
        if i <= self.notice_num then
            sub_panel:Show(self.notice_list[i])
            sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - (i - 1) * SUB_PANEL_HEIGHT)
        else
            sub_panel:Hide()
        end
    end

    self.friend_offset = 0
    self:SetHeadSubPanel(1)

    self.scroll_view:getInnerContainer():setPositionY(self.sview_height - height)
    --setInnerContainerSize会触发scrolling事件
    self.scroll_view:setInnerContainerSize(cc.size(self.sview_width, height))
end

function notice_panel:SetHeadSubPanel(index)
    if index > self.sub_panel_num then
        self.head_sub_panel_index = 1

    elseif index < 1 then
        self.head_sub_panel_index = self.sub_panel_num

    else
        self.head_sub_panel_index = index
    end
    self.head_sub_panel_y = self.sview_height - self.notice_sub_panels[self.head_sub_panel_index].root_node:getPositionY()
end

function notice_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.deal_invitation_msgbox:getChildByName("close_btn"), "guild.notice_panel")
    self.select_chk:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            guild_logic:SetBan()
        end
    end)
    self.scroll_view:addEventListener(function(lview, event_type)
        if event_type == ccui.ScrollViewEventType.scrolling then
            local y = self.scroll_view:getInnerContainer():getPositionY()
            if y >= self.head_sub_panel_y + SUB_PANEL_HEIGHT * 0.5 then
                if self.friend_offset + self.sub_panel_num >= self.notice_num then
                else
                    self.friend_offset = self.friend_offset + 1

                    local sub_panel = self.notice_sub_panels[self.head_sub_panel_index]
                    local last_sub_panel_index = self.sub_panel_num
                    if self.head_sub_panel_index ~= 1 then
                        last_sub_panel_index = self.head_sub_panel_index - 1
                    end
                    sub_panel.root_node:setPositionY(self.notice_sub_panels[last_sub_panel_index].root_node:getPositionY() - SUB_PANEL_HEIGHT)

                    sub_panel:Show(self.notice_list[self.friend_offset + self.sub_panel_num])
                    self:SetHeadSubPanel(self.head_sub_panel_index + 1)
                end

            elseif y <= self.head_sub_panel_y - SUB_PANEL_HEIGHT * 0.5 then

                if self.friend_offset == 0 then

                else
                    self.friend_offset = self.friend_offset - 1

                    local last_sub_panel_index = self.sub_panel_num
                    if self.head_sub_panel_index ~= 1 then
                        last_sub_panel_index = self.head_sub_panel_index - 1
                    end

                    local sub_panel = self.notice_sub_panels[last_sub_panel_index]
                    sub_panel.root_node:setPositionY(self.notice_sub_panels[self.head_sub_panel_index].root_node:getPositionY() + SUB_PANEL_HEIGHT)

                    sub_panel:Show(self.notice_list[self.friend_offset + 1])

                    self:SetHeadSubPanel(self.head_sub_panel_index - 1)
                end
            end
        end
    end)

end

return notice_panel
