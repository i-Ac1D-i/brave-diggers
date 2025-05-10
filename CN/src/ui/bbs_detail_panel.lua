local graphic = require "logic.graphic"
local panel_util = require "ui.panel_util"
local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"
local chat_logic = require "logic.chat"
local time_logic = require "logic.time"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local constants = require "util.constants"
local social_logic = require "logic.social"
local user_logic = require "logic.user"
local platform_manager = require "logic.platform_manager"
local PLIST_TYPE = ccui.TextureResType.plistType
local MARGIN_TOP = 40
local MARGIN = 30
local FONT_SIZE = 32

local json =  require "util.json"

-- 讨论内容
local sub_panel_detail = panel_prototype.New()
sub_panel_detail.__index = sub_panel_detail

function sub_panel_detail.New()
    return setmetatable({}, sub_panel_detail)
end

function sub_panel_detail:Init(root_node)
    self.root_node = root_node
    self.root_node:setVisible(true)
    self.root_node:setAnchorPoint(0,0)
    self.min_size = cc.size(630, 232)

    self.parent_sp = self.root_node:getChildByName("parent")
    self.shadow = self.parent_sp:getChildByName("shadow1")
    self.role_img = self.parent_sp:getChildByName("user_icon")
    self.name_text = self.parent_sp:getChildByName("user_name")
    self.time_text = self.parent_sp:getChildByName("time")
    self.discuss_num_text = self.parent_sp:getChildByName("discuss_num")
    self.discuss_detail_text = self.parent_sp:getChildByName("discuss_detail")
end

function sub_panel_detail:UpdatePanel(discuss_one, count)
    self.discuss_detail_text:setString(discuss_one.discuss)
    self.name_text:setString(discuss_one.role)
    local date = time_logic:GetDateInfo(discuss_one.time)

    if platform_manager:GetLocale() == "en-US" then
        self.time_text:setString(string.format("%02d/%02d/%d %d:%d:%d", date.month, date.day, date.year, date.hour, date.min, date.sec))
    elseif platform_manager:GetLocale() == "zh-CN" or platform_manager:GetLocale() == "zh-TW" then
        self.time_text:setString(string.format("%d/%02d/%02d %d:%d:%d", date.year, date.month, date.day, date.hour, date.min, date.sec))
    else
        self.time_text:setString(string.format("%02d/%02d/%d %d:%d:%d", date.day, date.month, date.year, date.hour, date.min, date.sec))
    end

    self.discuss_num_text:setString(count)
    self.role_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. discuss_one.icon .. ".png", PLIST_TYPE)

    local text_render = self.discuss_detail_text:getVirtualRenderer()
    local line_num_1 = math.ceil(text_render:getContentSize().width / 500)
    local line_num_2 = text_render:getStringNumLines()
    if platform_manager:GetChannelInfo().is_open_system then
        local size = self.discuss_detail_text:getAutoRenderSize()
        local content_size = text_render:getContentSize()
        line_num_2 = math.ceil(size.width / content_size.width) + 1
    end

    --FYD  
    local font_size = platform_manager:GetChannelInfo().bbs_detail_panel_discuss_detail_text_font_size 
    if font_size then
        FONT_SIZE = font_size 
    end

    -- 多行文本重置模版高度
    local line_num = math.max(line_num_1, line_num_2)
    local height = FONT_SIZE * line_num + 110
    if height < self.min_size.height then
        height = self.min_size.height
    end

    self.root_node:setContentSize(cc.size(630, height))
    self.parent_sp:setPosition(0, height - self.min_size.height)
    self.discuss_detail_text:setContentSize(cc.size(565, FONT_SIZE * line_num))

    return height
end

-- 回复内容
local sub_panel_reply = panel_prototype.New()
sub_panel_reply.__index = sub_panel_reply

function sub_panel_reply.New()
    return setmetatable({}, sub_panel_reply)
end

function sub_panel_reply:Init(root_node, reply_data, index)
    self.root_node = root_node
    self.root_node:setVisible(true)
    self.root_node:setAnchorPoint(0,0)
    self.reply_data = reply_data
    self.index = index
    self.reply_desc = self.root_node:getChildByName("desc")
    self.line = self.root_node:getChildByName("line")
end

function sub_panel_reply:UpdatePanel()
    -- self.reply_data.reply = string.gsub(self.reply_data.reply, " ", "")
    self.root_node:setString(self.index .. "#")
    self.reply_desc:setString(self.reply_data["reply"])

    -- 单行字体的模版高度
    local height = 26
    local font_size = platform_manager:GetChannelInfo().bbs_detail_panel_discuss_detail_text_font_size 
    if font_size then
        height = font_size 
    end
    
    local text_render = self.reply_desc:getVirtualRenderer()
    local line_num = math.ceil(text_render:getContentSize().width / 500)
    -- 多行文本重置模版高度
    if line_num > 1 then
        height = height * line_num
    end

    self.reply_desc:setContentSize(cc.size(520, height))
    self.reply_desc:setAnchorPoint(0, 0)
    self.reply_desc:setPositionY(3)
    self.line:setPositionY(-10)
    self.root_node:setContentSize(cc.size(520, height))

    return height
end


-- 某一条留言和他的讨论
local bbs_detail_panel = panel_prototype.New(true)
function bbs_detail_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/discuss_detail_panel.csb")
    self.back_btn = self.root_node:getChildByName("back_btn")
    self.add_friend_btn = self.root_node:getChildByName("add_friend_btn")
    self.reply_btn = self.root_node:getChildByName("reply_btn")
    self.report_btn = self.root_node:getChildByName("report_btn")

    self.detail_list = self.root_node:getChildByName("discuss_list")
    self.detail_template = self.root_node:getChildByName("template")
    self.detail_template:setVisible(false)
    self.reply_template = self.root_node:getChildByName("reply_template")
    self.reply_template:setVisible(false)

    self.discuss = nil

    self.inner_height = 0
    self.template_height = self.detail_template:getContentSize().height
    self.reply_template_height = self.reply_template:getContentSize().height
    self.view_size = self.detail_list:getContentSize()

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function bbs_detail_panel:Show(one)
    self.root_node:setVisible(true)
    self:UpdatePanel(one)
    if one.uid == user_logic.user_id then
        self.add_friend_btn:setVisible(false)
    else
        self.add_friend_btn:setVisible(true)
    end
end

function bbs_detail_panel:UpdatePanel(one)
    self.detail_list:removeAllChildren()

    self.discuss = one
    local has_reported = one.has_reported
    local reply = one.reply_list or {}

    if not has_reported then
        self.report_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
        self.report_btn:setTitleText(lang_constants:Get("discuss_report"))
    else
        self.report_btn:setColor(panel_util:GetColor4B(0x898989))
        self.report_btn:setTitleText(lang_constants:Get("discuss_reported"))
    end

    local detail_panel = sub_panel_detail.New()
    detail_panel:Init(self.detail_template:clone())
    local detail_height = detail_panel:UpdatePanel(self.discuss, #reply)

    self.detail_list_children = {}

    local template_height, count = self.reply_template_height, #reply
    local inner_height, pos_y = 0, 0

    for idx = count+1, 2, -1 do
        -- 每一条评论
        local reply_one = reply[idx-1]
        if reply_one then
            local child_panel = sub_panel_reply.New()
            child_panel:Init(self.reply_template:clone(), reply_one, (count-idx+2))
            child_panel.root_node:setPosition(20, pos_y)

            self.detail_list:addChild(child_panel.root_node)
            self.detail_list_children[idx] = child_panel

            local template_height = child_panel:UpdatePanel()
            pos_y = pos_y + template_height + MARGIN
            inner_height = inner_height + template_height + MARGIN
        end
    end

    detail_panel.root_node:setPosition(6, pos_y)
    self.detail_list:addChild(detail_panel.root_node)
    self.detail_list_children[1] = detail_panel
    inner_height = inner_height + detail_height + MARGIN_TOP

    -- inner height 小于容器高度, 重置children position
    if inner_height <= self.view_size.height then
        local dis = self.view_size.height - inner_height

        for _, child_panel in pairs(self.detail_list_children) do
            if child_panel then
                pos_y = child_panel.root_node:getPositionY() + dis
                child_panel.root_node:setPositionY(pos_y)
            end
        end

        inner_height = self.view_size.height
    end

    -- 重置容器container
    self.detail_list:setInnerContainerSize(cc.size(462, inner_height))
    local top_pos_y = inner_height * -1 + self.view_size.height
    self.detail_list:getInnerContainer():setPositionY(top_pos_y)
end

function bbs_detail_panel:RegisterWidgetEvent()
    -- 返回按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    -- 加好友
    self.add_friend_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.discuss and string.len(self.discuss.uid) > 0 then
                if self.discuss.uid ~= user_logic:GetUserId() then
                    social_logic:SearchFriend(self.discuss.uid)
                end
            end
        end
    end)

    -- 留言
    self.reply_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if not chat_logic:IsAuthorized() then
                return
            end

            graphic:DispatchEvent("show_world_sub_panel", "bbs_reply_panel", self.discuss)
        end
    end)

    -- 举报弹窗
    self.report_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if self.discuss.has_reported then
                graphic:DispatchEvent("show_prompt_panel", "discuss_reported")
                return
            end

            graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("discuss_report_title"),
                                lang_constants:Get("discuss_report_desc"),
                                lang_constants:Get("common_confirm"),
                                lang_constants:Get("common_cancel"),

            function()
                chat_logic:ReportDiscuss(self.discuss)
                self.report_btn:setColor(panel_util:GetColor4B(0x898989))
                self.report_btn:setTitleText(lang_constants:Get("discuss_reported"))
            end)
        end
    end)
end

function bbs_detail_panel:RegisterEvent()
    graphic:RegisterEvent("update_bbs_detail_panel", function(one)
        if not self.root_node:isVisible() then
            return
        end

        self:UpdatePanel(one)
    end)

    --搜索结果
    graphic:RegisterEvent("search_player_result", function(result, player)
        if not self.root_node:isVisible() then
            return
        end

        if not player then
            return

        end
        graphic:DispatchEvent("show_world_sub_panel", "social_msgbox", client_constants.SOCIAL_MSGBOX_TYPE["invite_player_msgbox"], player)
    end)
end

return bbs_detail_panel
