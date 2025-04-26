local config_manager = require "logic.config_manager"

local mercenary_config = config_manager.mercenary_config
local resource_config = config_manager.resource_config
local item_config = config_manager.item_config
local rune_config = config_manager.rune_config

local social_logic = require "logic.social"
local resource_logic = require "logic.resource"
local graphic = require "logic.graphic"
local mail_logic = require "logic.mail"
local payment_logic = require "logic.payment"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local icon_template = require "ui.icon_panel"
local single_reward_panel = require "ui.single_reward_panel"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"
local spine_manager = require "util.spine_manager"
local spine_node_tracker = require "util.spine_node_tracker"

local reuse_scrollview = require "widget.reuse_scrollview"

local SUB_PANEL_HEIGHT = 114
local FIRST_SUB_PANEL_OFFSET = -70
local MAX_SUB_PANEL_NUM = 8

local PLIST_TYPE = ccui.TextureResType.plistType

local MAIL_PANEL_TYPE = constants.MAIL_PANEL_TYPE
local MAIL_TYPE = constants.MAIL_TYPE
local RESOURCE_TYPE = constants.RESOURCE_TYPE

local mail_sub_panel = panel_prototype.New()
mail_sub_panel.__index = mail_sub_panel

function mail_sub_panel.New()
    return setmetatable({}, mail_sub_panel)
end

function mail_sub_panel:Init(root_node)
    self.root_node = root_node

    self.name_text = root_node:getChildByName("name")
    self.desc_text = root_node:getChildByName("desc")
    self.count_down_text = root_node:getChildByName("count_down")
    self.already_take_text = root_node:getChildByName("already_take")
    self.send_text = root_node:getChildByName("send")

    self.icon_template = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_template:Init(root_node)
    self.icon_template.root_node:setPosition(60, 60)

    --todo 将btn事件弄到最下面
    self.take_btn = root_node:getChildByName("take")
    self.take_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if self.mail then
                mail_logic:OpenMail(self.mail)
            end
        end
    end)

    self.root_node:setCascadeColorEnabled(true)
    self.icon_template.root_node:setCascadeColorEnabled(false)
end

function mail_sub_panel:Show(mail)
    if not mail then
        return
    end

    if not mail.extra_num then
        mail.extra_num = 0
    end

    self.root_node:setVisible(true)

    self.mail = mail

    local template_id, source_type,icon = mail.detail_id, nil, nil

    --todo 修改这里
    if mail.mail_type == MAIL_TYPE["reward_group"] then
        source_type = constants.REWARD_TYPE["reward_group"]
        icon = client_constants.GIFT_ICON_PATH
        self.desc_text:setString(lang_constants:Get("mail_reward_group_desc"))

    elseif mail.mail_type == MAIL_TYPE["item"] then
        name = item_config[template_id]["name"]
        source_type = constants.REWARD_TYPE["item"]
        self.desc_text:setString(name .. "x" .. mail.extra_num)

    elseif mail.mail_type == MAIL_TYPE["resource"] then
        name = resource_config[template_id]["name"]
        source_type = constants.REWARD_TYPE["resource"]
        self.desc_text:setString(name .. "x" .. mail.extra_num)

    elseif mail.mail_type == MAIL_TYPE["payment"] then
        source_type = constants.REWARD_TYPE["reward_group"]
        icon = client_constants.PAYMENT_ICON_PATH

        local product = payment_logic:GetProductInfo(mail.detail_id)
        if product then
            self.desc_text:setString(product.name)
        else
            self.desc_text:setString("")
        end

    elseif mail.mail_type == MAIL_TYPE["campaign"] then
        source_type = constants.REWARD_TYPE["reward_group"]

        if mail.detail_id == constants.CAMPAIGN_RESOURCE["exp"] then
            icon = client_constants.CAMPAIGN_RESOURCE_ICON.exp
            name = lang_constants:Get("campaign_res_exp")
        else

            icon = client_constants.CAMPAIGN_RESOURCE_ICON.score
            name = lang_constants:Get("campaign_res_score")
        end
        self.desc_text:setString(name .. "x" .. mail.extra_num)
    elseif mail.mail_type == MAIL_TYPE["text"] then
        local str_id = client_constants.MAIL_TYPE_TEXT[mail.detail_id]
        name = lang_constants:Get(str_id)
        self.desc_text:setString(name)
        -- icon = "icon/festival/christmascard.png"
    elseif mail.mail_type == MAIL_TYPE["rune"] then
        name = rune_config[template_id]["name"]
        source_type = constants.REWARD_TYPE["rune"]
        icon = rune_config[template_id]["icon"]
        self.desc_text:setString(name)
    end

    local writer_name = ""
    local mail_desc = client_constants.MAIL_SOURCE_TEXT[mail.source]

    if mail_desc then
        self.send_text:setVisible(false)

    else
        self.send_text:setVisible(true)
    end

    if mail.writer_name then
        writer_name = mail.writer_name
    else
        writer_name = lang_constants:Get(mail_desc)
    end


    if type(writer_name) == "string" then
        self.name_text:setString(writer_name)
    elseif type(writer_name) == "table" then
        local temp_name = writer_name["writer_name_"..platform_manager:GetLocale()]
        if temp_name then
            self.name_text:setString(temp_name)
        else
            temp_name = writer_name["writer_name"]
            self.name_text:setString(temp_name)
        end
    end
    
    self.icon_template:Show(source_type, template_id, icon, nil, false)

    self.count_down_text:setString(mail_logic:GetCountDown(mail))

    if mail.mark_read then
        self.already_take_text:setVisible(true)
        self.take_btn:setVisible(false)

        local str = mail.mail_type == MAIL_TYPE["payment"] and "mail_confirm_text2" or "mail_confirm_text1"
        self.already_take_text:setString(lang_constants:Get(str))

    else
        self.already_take_text:setVisible(false)
        self.take_btn:setVisible(true)

        local str = mail.mail_type == MAIL_TYPE["payment"] and "mail_confirm_btn2" or "mail_confirm_btn1"
        self.take_btn:setTitleText(lang_constants:Get(str))
    end

    local color = mail.mark_read and 0x7f7f7f or 0xffffff
    self.root_node:setColor(panel_util:GetColor4B(color))
end

local mail_panel = panel_prototype.New(true)

function mail_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mail_panel.csb")
    self.system_num_text = self.root_node:getChildByName("tab_system"):getChildByName("txt")
    self.friend_num_text = self.root_node:getChildByName("tab_friend"):getChildByName("txt")

    self.no_mail_text = self.root_node:getChildByName("no_mail")

    self.scroll_view = self.root_node:getChildByName("scroll_view")
    self.template = self.scroll_view:getChildByName("template")

    self.system_mail_btn = self.root_node:getChildByName("tab_system")
    self.friend_mail_btn = self.root_node:getChildByName("tab_friend")

    self.reward_node = self.root_node:getChildByName("reward")
    self.reward_panel = single_reward_panel.New()
    self.reward_panel:Init(self.reward_node)

    self.id_desc = self.root_node:getChildByName("id_desc")
    self.tip1 = self.root_node:getChildByName("tip1")
    self.tip2 = self.root_node:getChildByName("tip2")
    self.tip1:setLocalZOrder(2)
    self.tip2:setLocalZOrder(2)

    self.friendship_left_pt = 0

    self.mail_sub_panels = {}
    self.sub_panel_num = 1

    local mail_sub_panel = mail_sub_panel.New()
    mail_sub_panel:Init(self.template:clone())
    mail_sub_panel.root_node:setPositionX(320 - 54)
    self.scroll_view:addChild(mail_sub_panel.root_node)
    self.mail_sub_panels[1] = mail_sub_panel

    self.template:setVisible(false)

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.mail_sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return self.parent_panel.sum_mail_num
        end,

        function(self, sub_panel, is_up)
            local index = is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
            sub_panel:Show(self.parent_panel:GetMail(index))
        end
    )

    self.low_btn_zorder = self.friend_mail_btn:getLocalZOrder()
    self.high_btn_zorder = self.system_mail_btn:getLocalZOrder() + 1

    self.mail_panel_type = MAIL_PANEL_TYPE["system"]

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function mail_panel:CreateSubPanels()

    local num = math.min(MAX_SUB_PANEL_NUM, mail_logic:GetSumMailNum(self.mail_panel_type))

    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = mail_sub_panel.New()
        sub_panel:Init(self.template:clone())

        self.mail_sub_panels[i] = sub_panel

        sub_panel.root_node:setPositionX(320 - 54)
        self.scroll_view:addChild(sub_panel.root_node)
    end

    self.sub_panel_num = num
end

function mail_panel:Show()

    self.root_node:setVisible(true)
    self:UpdateFriendship()
    self:UpdateMailNum()
    self.mail_panel_type = MAIL_PANEL_TYPE["system"]
    if self.friend_not_read > 0 and self.system_not_read <= 0 then
        self.mail_panel_type = MAIL_PANEL_TYPE["friend"]
    end

    self:UpdateTab(self.mail_panel_type)
end

function mail_panel:UpdateTab(mail_panel_type)
    self.mail_panel_type = mail_panel_type

    if self.mail_panel_type == MAIL_PANEL_TYPE["system"] then
        self.not_read_list = mail_logic:GetMailList("system_not_read")
        self.already_read_list = mail_logic:GetMailList("system_already_read")

        self.friend_mail_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
        self.system_mail_btn:setColor(panel_util:GetColor4B(0xffffff))
        self.friend_mail_btn:setLocalZOrder(self.low_btn_zorder)
        self.system_mail_btn:setLocalZOrder(self.high_btn_zorder)

    elseif self.mail_panel_type == MAIL_PANEL_TYPE["friend"] then
        self.not_read_list = mail_logic:GetMailList("friend_not_read")
        self.already_read_list = mail_logic:GetMailList("friend_already_read")

        self.system_mail_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
        self.friend_mail_btn:setColor(panel_util:GetColor4B(0xffffff))
        self.friend_mail_btn:setLocalZOrder(self.high_btn_zorder)
        self.system_mail_btn:setLocalZOrder(self.low_btn_zorder)
    end

    local sum_mail_num = mail_logic:GetSumMailNum(self.mail_panel_type)

    if sum_mail_num == 0 then
        self.scroll_view:setVisible(false)
        self.no_mail_text:setVisible(true)
        return
    else
        self.scroll_view:setVisible(true)
        self.no_mail_text:setVisible(false)
    end

    self:CreateSubPanels()

    local height = math.max(sum_mail_num * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

    for i = 1, self.sub_panel_num do
        local sub_panel = self.mail_sub_panels[i]
        local mail = self:GetMail(i)

        if mail then
            sub_panel:Show(mail)
            sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - (i - 1) * SUB_PANEL_HEIGHT)
        else
            sub_panel:Hide()
        end
    end

    self.reuse_scrollview:Show(height, 0)

    self.sum_mail_num = sum_mail_num
end

function mail_panel:UpdateFriendship()
    local left_point = social_logic:GetMaxFriendPoint() - social_logic:GetFriendshipPoint()
    self.id_desc:setString(string.format(lang_constants:Get("daily_left_gift"), left_point))
end

function mail_panel:Update(elspsed_time)
    self.reward_panel:Update(elapsed_time)
    self:HaveNotReadMail(elspsed_time)
end

local time_deleta = 0
function mail_panel:HaveNotReadMail(elspsed_time)
    -- 每秒执行一次
    time_deleta = time_deleta + elspsed_time
    if time_deleta <= 1 then
        return
    end

    self:UpdateMailNum()
    self.tip1:setVisible(self.system_not_read > 0)
    self.tip2:setVisible(self.friend_not_read > 0)
end

function mail_panel:UpdateMailNum()
    -- 刷新未读邮件数
    self.friend_not_read = mail_logic:GetNotReadMailNum(MAIL_PANEL_TYPE["friend"])
    self.system_not_read = mail_logic:GetNotReadMailNum(MAIL_PANEL_TYPE["system"])

    self.friend_num_text:setString(string.format(lang_constants:Get("mail_friend_num"), self.friend_not_read))
    self.system_num_text:setString(string.format(lang_constants:Get("mail_system_num"), self.system_not_read))
end

function mail_panel:GetMail(index)
    if index <= #self.not_read_list then
        mail = self.not_read_list[index]
    else
        mail = self.already_read_list[index - #self.not_read_list]
    end

    return mail
end

function mail_panel:RegisterEvent()

    graphic:RegisterEvent("open_mail", function(mail)
        if not self.root_node:isVisible() then
            return
        end

        for i = 1, self.sub_panel_num do
            local mail_index = self.reuse_scrollview:GetDataIndex(i)
            local mail = self:GetMail(mail_index)

            if mail then
                self.mail_sub_panels[i]:Show(mail)

            else
                self.mail_sub_panels[i]:Hide()
            end
        end

        self:UpdateMailNum()

        if mail.mail_type == MAIL_TYPE["resource"] and mail.detail_id == RESOURCE_TYPE["friendship_pt"] then
            self.reward_panel:SetString(tostring(mail.extra_num))
            
            self.reward_panel:ToBindNode()
        
            self:UpdateFriendship()

            if self.friend_not_read == 0 and self.system_not_read > 0 then
                self:UpdateTab(MAIL_PANEL_TYPE["system"])
            end
        else
            if self.friend_not_read > 0 and self.system_not_read == 0 then
                self:UpdateTab(MAIL_PANEL_TYPE["friend"])
            end
        end
    end)
end

function mail_panel:RegisterWidgetEvent()

    self.friend_mail_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:UpdateTab(MAIL_PANEL_TYPE["friend"])
        end
    end)

    self.system_mail_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:UpdateTab(MAIL_PANEL_TYPE["system"])
        end
    end)

    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), "mail_panel")
end

return mail_panel
