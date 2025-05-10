local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local reuse_scrollview = require "widget.reuse_scrollview"

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local rune_logic = require "logic.rune"
local troop_logic = require "logic.troop"
local carnival_logic = require "logic.carnival"

local mercenary_exchange_config = config_manager.mercenary_exchange_config
local mercenary_config = config_manager.mercenary_config

local PLIST_TYPE = ccui.TextureResType.plistType

local MAX_SUB_PANEL_NUM = 7
local SUB_PANEL_HEIGHT = 150
local FIRST_SUB_PANEL_OFFSET = -90

local carnival_exchange_sub_panel = panel_prototype.New()
carnival_exchange_sub_panel.__index = carnival_exchange_sub_panel

function carnival_exchange_sub_panel.New()
    return setmetatable({}, carnival_exchange_sub_panel)
end

function carnival_exchange_sub_panel:Init(root_node)
    self.root_node = root_node

    self.role_bg_img = self.root_node:getChildByName("role_bg")
    self.role_icon_img = self.role_bg_img:getChildByName("icon")

    self.exchange_times = self.root_node:getChildByName("Text_36")
    self.remain_icon = self.root_node:getChildByName("Image_14_0")
    self.remain_num = self.root_node:getChildByName("number_0")
    self.remain_desc = self.root_node:getChildByName("desc")

    self.exchange_btn = self.root_node:getChildByName("exchange_btn")
    self.cost_icon = self.exchange_btn:getChildByName("Image_14")
    self.cost_num = self.exchange_btn:getChildByName("number")
    
    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function carnival_exchange_sub_panel:Show(config, step_index, exchange_config)
    self.config = config
    self.step_index = step_index
    self.exchange_config = exchange_config
    
    self:ShowInfo()

    self.root_node:setVisible(true)
end


function carnival_exchange_sub_panel:ShowInfo()
    local template_info = mercenary_config[self.exchange_config.mercenary_id]
    self.role_bg_img:loadTexture(client_constants["MERCENARY_BG_SPRITE"][template_info.quality], PLIST_TYPE)
    self.role_icon_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. template_info.sprite .. ".png", PLIST_TYPE)

    self.remain_num:setString(troop_logic:GetMercenaryLibraryCount(self.exchange_config.mercenary_id) or 0)

    self.cost_num:setString(self.exchange_config.cost_num)

    local remain_times = self.exchange_config.times
    local info = carnival_logic:GetCarnivalInfo(self.config.key)
    if info.exchange_record and info.exchange_record[self.exchange_config.id] then
        remain_times = remain_times - info.exchange_record[self.exchange_config.id]
    end
    self.exchange_times:setString(lang_constants:GetFormattedStr("remain_exchange_times", remain_times))

    if remain_times > 0 then
        self.root_node:setColor(panel_util:GetColor4B(0xffffff))
    else
        self.root_node:setColor(panel_util:GetColor4B(0x7f7f7f))
    end
end

function carnival_exchange_sub_panel:RegisterWidgetEvent()
    self.exchange_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if (troop_logic:GetMercenaryLibraryCount(self.exchange_config.mercenary_id) or 0) <= 0 then
                graphic:DispatchEvent("show_prompt_panel", "mercenary_soul_stone_not_enough")
            else
                local remain_times = self.exchange_config.times
                local info = carnival_logic:GetCarnivalInfo(self.config.key)
                if info.exchange_record and info.exchange_record[self.exchange_config.id] then
                    remain_times = remain_times - info.exchange_record[self.exchange_config.id]
                end
                
                if remain_times <= 0 then
                    graphic:DispatchEvent("show_prompt_panel", "carnival_exchange_limit")
                else
                    carnival_logic:TakeReward(self.config, self.step_index, false, self.exchange_config.id)
                end
            end
        end
    end)
end


function carnival_exchange_sub_panel:RegisterEvent()
    graphic:RegisterEvent("update_sub_carnival_reward_status", function(key, step, exchange_id)
        if key == self.config.key and step == self.step_index and self.exchange_config.id == exchange_id then
            self:ShowInfo()
        end
    end)
end

local carnival_exchange_panel = panel_prototype.New(true)
function carnival_exchange_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/exchange_reward_panel.csb")

    self.back_btn = self.root_node:getChildByName("back_btn")

    self.scroll_view = self.root_node:getChildByName("scrollView")
    self.scroll_view:setTouchEnabled(true)

    self.template = self.scroll_view:getChildByName("template")
    self.template:setVisible(false)

    self.sub_panel_num = 0
    self.sub_panels = {}

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return #self.parent_panel.mercenary_list
        end,

        function(self, sub_panel, is_up)
            local index = is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
            sub_panel:Show(self.parent_panel.config, self.parent_panel.step_index, self.parent_panel.mercenary_list[index])
        end
    )

    self:RegisterWidgetEvent()
end

function carnival_exchange_panel:CreateSubPanels()
    local num = math.min(MAX_SUB_PANEL_NUM, #self.mercenary_list)

    if self.sub_panel_num >= num then
        for i=num + 1,self.sub_panel_num do
            self.scroll_view:removeChild(self.sub_panels[i].root_node, true)
            self.sub_panels[i] = nil
        end
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = carnival_exchange_sub_panel.New()
        sub_panel:Init(self.template:clone())

        self.sub_panels[i] = sub_panel
        self.scroll_view:addChild(sub_panel.root_node)
    end

    self.sub_panel_num = num
end

function carnival_exchange_panel:Show(config, step_index)
    self.config = config
    self.step_index = step_index

    self.reward_group_id = self.config.reward_list[self.step_index].reward_group_id
    self.mercenary_list = mercenary_exchange_config[self.reward_group_id]

    self:CreateSubPanels()

    local height = math.max(#self.mercenary_list * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

    for i = 1, self.sub_panel_num do
        local sub_panel = self.sub_panels[i]

        sub_panel:Show(self.config, self.step_index, self.mercenary_list[i])
        sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - (i - 1) * SUB_PANEL_HEIGHT)
    end

    self.reuse_scrollview:Show(height, 0)

    self.root_node:setVisible(true)
end

function carnival_exchange_panel:RegisterWidgetEvent()
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)
end

return carnival_exchange_panel

