local graphic = require "logic.graphic"
local panel_util = require "ui.panel_util"
local panel_prototype = require "ui.panel"
local ui_role_prototype = require "entity.ui_role"
local audio_manager = require "util.audio_manager"
local client_constants = require "util.client_constants"
local constants = require "util.constants"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"
local reuse_scrollview = require "widget.reuse_scrollview"

local quest_logic = require "logic.quest"
local troop_logic = require "logic.troop"

local locale = platform_manager:GetLocale()

local BG_TAB_SELECTED = 0xFFFFFF
local BG_TAB_NORMAL = 0x7F7F7F

local MARGIN = 10
local FIRST_SUB_PANEL_OFFSET = -20
local MAX_SUB_PANEL_NUM = 7
local SUB_PANEL_HEIGHT = 0

local mail_sub_panel = panel_prototype.New()
mail_sub_panel.__index = mail_sub_panel

function mail_sub_panel.New()
    return setmetatable({}, mail_sub_panel)
end

function mail_sub_panel:Init(root_node)
    self.root_node = root_node
    self.root_node:setVisible(true)

    local title = root_node:getChildByName("title")
    local writer = root_node:getChildByName("writer")
    local new_mail_tip = root_node:getChildByName("tab_mail_tip")
    local honor_icon = root_node:getChildByName("levelup_icon")

    -- 调整新邮件绿色按钮
    if locale == "fr" or locale == "es-MX" and platform_manager:GetChannelInfo().quest_panel_change_new_mail_tip_size then
        local desc_text = new_mail_tip:getChildByName("desc")
        desc_text:setPositionX(desc_text:getPositionX() + 15)
        new_mail_tip:setContentSize(cc.size(new_mail_tip:getContentSize().width * 1.6, new_mail_tip:getContentSize().height))
    end

    self.title = title
    self.writer = writer
    self.new_mail_tip = new_mail_tip
    self.honor_icon = honor_icon
end

function mail_sub_panel:Show(index)
    local mail = quest_logic:GetMailList()[index]

    self.title:setString(mail.title)
    self.writer:setString(mail.writer)
    self.honor_icon:setVisible(false)

    self.new_mail_tip:setVisible(not mail.is_read)

    self.mail_index = index
end

local quest_panel = panel_prototype.New()
function quest_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/entrust_panel.csb")

    -- 返回按钮
    self.back_btn = self.root_node:getChildByName("back_btn")

    self.leader_name = troop_logic:GetLeaderName()

    local title_name = self.root_node:getChildByName("title_bg"):getChildByName("name")
    title_name:setString(string.format(lang_constants:Get("quest_mail_title"), self.leader_name))

    -- 玩家主角信息区域
    local information_area = self.root_node:getChildByName("information")
    local rank_exp = information_area:getChildByName("rank_exp")
    local exp_loadingbar = rank_exp:getChildByName("exp_loadingbar")
    exp_loadingbar:setPercent(0)
    local exp_loadingbar_head = exp_loadingbar:getChildByName("exp_loadingbar_head")
    exp_loadingbar_head:setVisible(false)

    local rank_expnum = information_area:getChildByName("rank_expnum")
    rank_expnum:setVisible(false)

    -- 设置主角信息，动画
    self:SetRoleAnimation(information_area)

    -- 两个tab区域
    local tab_area = self.root_node:getChildByName("up_border")
    -- 普通邮件
    self.mail_tab = tab_area:getChildByName("tab_mail")
    -- 委托任务
    self.quest_tab = tab_area:getChildByName("tab_quest")
    self.quest_tab:setVisible(false)

    -- 新信件remind icon
    self.mail_tip = tab_area:getChildByName("tab_mail_tip")
    self.mail_tip:setVisible(false)

    -- 滚动容器
    self.list_view = self.root_node:getChildByName("mail_list")
    self.mail_template = self.root_node:getChildByName("template")
    self.mail_template:setVisible(false)

    self.root_node:getChildByName("template2"):setVisible(false)
    self.root_node:getChildByName("quest_list"):setVisible(false)

    self.tab_choose = 0
    self.mail_list = {}

    self.mail_sub_panels = {}
    self.sub_panel_num = 0

    SUB_PANEL_HEIGHT = self.mail_template:getContentSize().height + MARGIN

    self.reuse_scrollview = reuse_scrollview.New(self, self.list_view, self.mail_sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return #self.parent_panel.mail_list
        end,

        function(self, sub_panel, is_up)
            local index

            local mail_list = quest_logic:GetMailList()
            if is_up then
                index = #mail_list - self.data_offset - self.sub_panel_num + 1
            else
                index = #mail_list - self.data_offset
            end

            sub_panel:Show(index)
        end
    )

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function quest_panel:Show()
    if not self.root_node:isVisible() then
        self.root_node:setVisible(true)
    end

    self:CreateSubPanels()

    self:UpdatePanel()
end

-- 设置主角信息，动画
function quest_panel:SetRoleAnimation(parent_node)
    local role_icon = parent_node:getChildByName("role_icon")
    role_icon:setVisible(false)

    -- 角色声望值对应的等级描述
    local level_lab= parent_node:getChildByName("rank_level")
    level_lab:setString(lang_constants:Get("quest_title"))

    --设置主角名字
    local name_lab= parent_node:getChildByName("name")
    name_lab:setString(string.format(lang_constants:Get("quest_complete_txt"), self.leader_name, 0))

    --主角走动动画
    local role_sprite = cc.Sprite:create()
    role_sprite:setPosition(role_icon:getPosition())
    parent_node:addChild(role_sprite, 10)

    local ui_role = ui_role_prototype.New()
    ui_role:Init(role_sprite, troop_logic:GetLeader().template_info.sprite)
    ui_role:SetScale(2.0, 2.0)
    ui_role:WalkAnimation(1, 0.3)
end

function quest_panel:CreateSubPanels()
    local num = math.min(MAX_SUB_PANEL_NUM, #quest_logic:GetMailList())

    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = mail_sub_panel.New()
        sub_panel:Init(self.mail_template:clone())

        self.mail_sub_panels[i] = sub_panel

        sub_panel.root_node:addTouchEventListener(self.view_mail_method)
        sub_panel.root_node:setTag(i)
        self.list_view:addChild(sub_panel.root_node)
    end

    self.sub_panel_num = num
end

-- 信件面板
function quest_panel:UpdatePanel()
 
    self.mail_list = quest_logic:GetMailList()
    
    local mail_num = #self.mail_list

    local height = math.max(mail_num * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height) + 30

    for i = 1, self.sub_panel_num do
        local mail_index = mail_num - i + 1
        local sub_panel = self.mail_sub_panels[i]

        if mail_index <= mail_num then
            sub_panel:Show(mail_index)

            sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - (i - 1) * SUB_PANEL_HEIGHT)
        else
            sub_panel:Hide()
        end
    end
    
    self.reuse_scrollview:Show(height, 0)
end

function quest_panel:RegisterWidgetEvent()
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    -- 普通邮件tab
    self.mail_tab:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            self.quest_tab:setLocalZOrder(1)
            self.mail_tab:setLocalZOrder(2)

            self.mail_tab:setColor(panel_util:GetColor4B(BG_TAB_SELECTED))
            self.quest_tab:setColor(panel_util:GetColor4B(BG_TAB_NORMAL))
        end
    end)

    -- 任务tab
    self.quest_tab:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            self.mail_tab:setLocalZOrder(1)
            self.quest_tab:setLocalZOrder(2)

            self.quest_tab:setColor(panel_util:GetColor4B(BG_TAB_SELECTED))
            self.mail_tab:setColor(panel_util:GetColor4B(BG_TAB_NORMAL))
        end
    end)

    self.view_mail_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            local sub_panel_index = widget:getTag()
            local sub_panel = self.mail_sub_panels[sub_panel_index]

            audio_manager:PlayEffect("click")
            -- 点击阅读信件
            local mail = quest_logic:GetMailList()[sub_panel.mail_index]
            graphic:DispatchEvent("show_world_sub_panel", "reading_mail_panel", mail, troop_logic:GetLeaderName())

            if not mail.is_read then
                sub_panel.new_mail_tip:setVisible(false)
                quest_logic:ReadMail(sub_panel.mail_index, mail)
            end
        end
    end
end

function quest_panel:RegisterEvent()
    graphic:RegisterEvent("update_quest_panel", function()
        if not self.root_node:isVisible() then 
            return
        end

        self:UpdatePanel()
    end)
end

return quest_panel
