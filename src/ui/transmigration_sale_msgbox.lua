local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local configuration = require "util.configuration"
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

    local conf = self.icon_panel:Show(constants.REWARD_TYPE["mercenary"], mercenary_id, nil, nil, true)
    self.desc_text:setString(conf.desc)
    self.name_text:setString(conf.name)

    self.root_node:setVisible(true)
end


local transmigration_sale_msgbox = panel_prototype.New(true)
function transmigration_sale_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/transmigration_sale_msgbox.csb")

    self.list_sview = self.root_node:getChildByName("scroll_view")

    self.time_text = self.root_node:getChildByName("time")


    --FYD
    local time_change_x = platform_manager:GetChannelInfo().transmigration_scale_msgbox_time_change_x
    if time_change_x then
         local x,y = self.time_text:getPosition()
         self.time_text:setPositionX(x+time_change_x)
    end

    self.close_btn = self.root_node:getChildByName("close_btn")

    self.template = self.root_node:getChildByName("mercenary_template")
    self.free_node = self.root_node:getChildByName("free_node")
    self.free_node:setVisible(false)
    self.template:setVisible(false)

    local size = self.list_sview:getContentSize()
    self.lview_width, self.lview_height = size.width, size.height + SUB_PANEL_OFFSET_Y

    self.sub_panel_num = 0
    self.mercenary_sub_panels = {}

    self:RegisterWidgetEvent()
end

--[[
  活动灵力转移显示逻辑
]]
function transmigration_sale_msgbox:ShowCarnivalView()
    local index = 1

    local conf = carnival_logic:GetSpecialCarnival(client_constants.CARNIVAL_TEMPLATE_TYPE["transmigrate"])
    local mercenary_list = conf.mult_num1
    local mercenary_num = #mercenary_list
    self.list_sview:setVisible(true)
    self.free_node:setVisible(false)
    if mercenary_num > 0 then
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
    end

    for i = index, self.sub_panel_num do
        self.mercenary_sub_panels[i]:Hide()
    end

    local cur_time = time_logic:Now()
    self.duration = conf.end_time - cur_time
end

function transmigration_sale_msgbox:Show()
    self.duration = 0
    local free_tag = configuration:GetViewedFreeTransmigration()
    if  free_tag then
        self.list_sview:setVisible(false)
        self.free_node:setVisible(true)
        local now_time = time_logic:Now()
        local free_time_limit = user_logic.base_info.create_time + time_logic:GetSecondsFromDays(constants['NOVICE_DAYS'])
        self.duration = free_time_limit - now_time
    else
        self:ShowCarnivalView()
    end

    self.root_node:setVisible(true)
end

function transmigration_sale_msgbox:Update(elapsed_time)
    self.duration = self.duration - elapsed_time
    if self.duration < 0 then
        self.duration = 0
    end

    self.time_text:setString(panel_util:GetTimeStr(self.duration))
end

function transmigration_sale_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())
end

return transmigration_sale_msgbox

