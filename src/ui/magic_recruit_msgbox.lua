local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local user_logic = require "logic.user"
local carnival_logic = require "logic.carnival"

local time_logic = require "logic.time"
local graphic = require "logic.graphic"

local lang_constants = require "util.language_constants"
local icon_template = require "ui.icon_panel"
local resource_template = require "ui.icon_panel"
local platform_manager = require "logic.platform_manager"

local SUB_PANEL_HEIGHT = 180
local SUB_PANEL_OFFSET_Y = 20

local mercenary_sub_panel = panel_prototype.New()
mercenary_sub_panel.__index = mercenary_sub_panel

function mercenary_sub_panel.New()
    return setmetatable({}, mercenary_sub_panel)
end

function mercenary_sub_panel:Init(root_node)
    self.root_node = root_node

    self.name_text = root_node:getChildByName("name")
    self.desc_text = root_node:getChildByName("desc")

    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(root_node, true)
    self.icon_panel:SetPosition(75, 90)
end

function mercenary_sub_panel:Show(mercenary_id)
    self.mercenary_id = mercenary_id

    local conf = self.icon_panel:Show(constants["REWARD_TYPE"]["mercenary"], mercenary_id, nil, nil, true)
    self.desc_text:setString(conf.desc)
    self.name_text:setString(conf.name)

    self.root_node:setVisible(true)
end

local magic_recruit_msgbox = panel_prototype.New(true)
function magic_recruit_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/magic_recruit_msgbox.csb")

    self.cancel_btn = self.root_node:getChildByName("cancel_btn")
    self.confirm_btn = self.root_node:getChildByName("confirm_btn")
    self.close_btn = self.root_node:getChildByName("close_btn")

    self.notice_node = self.root_node:getChildByName("notice")
    self.desc_text = self.root_node:getChildByName("desc")

    self.template = self.root_node:getChildByName("mercenary_template")
    self.template:setVisible(false)

    self.list_sview = self.root_node:getChildByName("scroll_view")
    self.time_text = self.root_node:getChildByName("time")

    self.cost_icon_panel = resource_template.New()
    self.cost_icon_panel:Init(self.root_node)
    self.cost_icon_panel.root_node:setPosition(320, 312)

    local size = self.list_sview:getContentSize()
    self.lview_width, self.lview_height = size.width, size.height + SUB_PANEL_OFFSET_Y

    self.mercenary_sub_panels = {}
    self.sub_panel_num = 0

    self:RegisterWidgetEvent()
    --r2位置修改  --fyd
    local desc2_pos=platform_manager:GetChannelInfo().magic_recruit_msgbox_template_desc2_pos
    if desc2_pos then
        local desc2_text=self.template:getChildByName("desc2")
        desc2_text:setAnchorPoint({x=1,y=0.5})
        desc2_text:setPositionX(495)
    end
    --FYD  qiku 追加高度以換行
    local append = platform_manager:GetChannelInfo().change_recruit_msgbox_template_desc_append_height
    local append2 = platform_manager:GetChannelInfo().change_recruit_msgbox_template_desc_append_height2 
    if append then
        local desc_text = self.template:getChildByName("desc") 
        local size = desc_text:getContentSize()
        size.height = size.height + append
        desc_text:setContentSize(size)
        local x,y = desc_text:getPosition()
        desc_text:setPosition(cc.p(x,y-append/2))   
    end

    if append2 then
        local size = self.desc_text:getContentSize()
        size.height = size.height + append2
        self.desc_text:setContentSize(size)
        local x,y = self.desc_text:getPosition()
        self.desc_text:setPosition(cc.p(x,y-append2/2))   
    end
    
end

function magic_recruit_msgbox:Show()
    self.root_node:setVisible(true)
    self.duration = 0

    local index = 1

    local conf = carnival_logic:GetSpecialCarnival(client_constants.CARNIVAL_TEMPLATE_TYPE["magic_door"], constants.CARNIVAL_TYPE["magic_door"])

    if #conf.mult_num1 ~= 0 then
        local mercenary_list = conf.mult_num1
        local mercenary_num = #mercenary_list

        self.desc_text:setString(lang_constants:Get("magic_door_desc1"))
        self.notice_node:setVisible(false)

        local height = math.max(SUB_PANEL_HEIGHT * mercenary_num, self.lview_height) + SUB_PANEL_OFFSET_Y

        for i = self.sub_panel_num+1, mercenary_num do
            local sub_panel = mercenary_sub_panel.New()
            sub_panel:Init(self.template:clone())
            self.list_sview:addChild(sub_panel.root_node)

            local pos_y = height - (i - 1) * SUB_PANEL_HEIGHT - SUB_PANEL_OFFSET_Y
            sub_panel.root_node:setPosition(0, pos_y)

            self.mercenary_sub_panels[i] = sub_panel
        end

        index = mercenary_num + 1
        self.sub_panel_num = mercenary_num

        for i = 1, mercenary_num do
            self.mercenary_sub_panels[i]:Show(mercenary_list[i])
        end

        self.list_sview:getInnerContainer():setPositionY(self.lview_height - height)
        --setInnerContainerSize会触发scrolling事件
        self.list_sview:setInnerContainerSize(cc.size(self.lview_width, height))

    else
        self.desc_text:setString(lang_constants:Get("magic_door_desc2"))
        self.notice_node:setVisible(true)
        self.notice_node:getChildByName("desc"):setString(conf.desc)
    end

    for i = index, self.sub_panel_num do
        self.mercenary_sub_panels[i]:Hide()
    end

    local cur_time = time_logic:Now()
    self.duration = conf.end_time - cur_time

    self.cost_icon_panel:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["blood_diamond"], conf.extra_num1, true, false)
end

function magic_recruit_msgbox:Update(elapsed_time)
    self.duration = self.duration - elapsed_time
    if self.duration < 0 then
        self.duration = 0
    end

    self.time_text:setString(panel_util:GetTimeStr(self.duration))
end

function magic_recruit_msgbox:RegisterWidgetEvent()

    panel_util:RegisterCloseMsgbox(self.cancel_btn, "magic_recruit_msgbox")
    panel_util:RegisterCloseMsgbox(self.close_btn, "magic_recruit_msgbox")

    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            troop_logic:RecruitMercenary("magic_door")
            --graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)
end

return magic_recruit_msgbox
