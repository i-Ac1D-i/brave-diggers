local panel_prototype = require "ui.panel"
local config_manager = require "logic.config_manager"
local audio_manager = require "util.audio_manager"
local graphic = require "logic.graphic"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local bit_extension = require "util.bit_extension"

local guild_logic = require "logic.guild"
local troop_logic = require "logic.troop"

local panel_util = require "ui.panel_util"

local reuse_scrollview = require "widget.reuse_scrollview"

local CAMPAIGN_PROPERTY_ICON = client_constants["CAMPAIGN_PROPERTY_ICON"]

local PLIST_TYPE = ccui.TextureResType.plistType
local SUB_PANEL_HEIGHT = 160
local FIRST_SUB_PANEL_OFFSET = -20
local MAX_SUB_PANEL_NUM = 7

local BUFF_FACTOR = constants.GUILDWAR_BUFF_FACTOR
local BUFF_TYPE = constants.GUILDWAR_BUFF_TYPE
local BUFF_TYPE_NAME = {}
for k, v in pairs(BUFF_TYPE) do
    BUFF_TYPE_NAME[v] = k
end

local buff_sub_panel = panel_prototype.New()
buff_sub_panel.__index = buff_sub_panel

function buff_sub_panel.New()
    return setmetatable({}, buff_sub_panel)
end

function buff_sub_panel:Init(root_node, buff_type)
    self.root_node = root_node

    self.icon_img = self.root_node:getChildByName("icon")
    self.icon_img:ignoreContentAdaptWithSize(true)
    self.icon_img:loadTexture(CAMPAIGN_PROPERTY_ICON[buff_type], PLIST_TYPE)

    self.desc_text = self.root_node:getChildByName("desc")

    -- self.rule_btn = self.root_node:getChildByName("rule_icon")
    self.buy_btn = self.root_node:getChildByName("buy_btn")
    self.armor_text = self.root_node:getChildByName("armor_desc")

    self.root_node:getChildByName("bg"):setOpacity(255 * 0.1)

    self.buff_type = buff_type
        
    self.root_node:setVisible(true)
end

function buff_sub_panel:Load(member_info, my_right, user_id)
    local has_buff = false
    local armor_desc_text = lang_constants:Get("guild_war_buy_buff1")

    if bit_extension:GetBitNum(member_info.buff_info, self.buff_type - 1) == 1 then
        --已经购买
        has_buff = true
    end
    
    if my_right == constants.GUILD_GRADE["staff"] and user_id ~= guild_logic.user_id then 
        if not has_buff then 
           armor_desc_text = lang_constants:Get("guild_war_buy_buff2")
        end
        self.buy_btn:setVisible(false)
        self.armor_text:setVisible(true)
    else
        self.buy_btn:setVisible(not has_buff)
        self.armor_text:setVisible(has_buff)
    end

    self.armor_text:setString(armor_desc_text)

    if self.buff_type == BUFF_TYPE["bp"] then
        self.desc_text:setString(lang_constants:GetCampaignBuffType(self.buff_type) .. "+" .. BUFF_FACTOR[self.buff_type] * 100 .. "%")

    else
        self.desc_text:setString(lang_constants:GetCampaignBuffType(self.buff_type) .. "+" .. BUFF_FACTOR[self.buff_type])
    end

    return has_buff
end

local arm_msgbox = panel_prototype.New(true)
function arm_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/guildwar_armor_panel.csb")

    local bg_img = self.root_node:getChildByName("bg2")
    self.template = bg_img:getChildByName("template")

    local BEGIN_Y = self.template:getPositionY()

    local property_bg_img = self.root_node:getChildByName("property_bg")

    local buff_img = self.root_node:getChildByName("buff_info")

    self.buff_num_text = buff_img:getChildByName("buff_num")
    self.buff_desc_text = buff_img:getChildByName("desc")

    self.buff_sub_panels = {}

    for type, buff_name in ipairs(BUFF_TYPE_NAME) do
        self[buff_name .. "_text"] = property_bg_img:getChildByName(buff_name):getChildByName("value")
        local sub_panel = buff_sub_panel.New()

        if type == BUFF_TYPE["bp"] then
            sub_panel:Init(self.template, type)
        else
            sub_panel:Init(self.template:clone(), type)
            bg_img:addChild(sub_panel.root_node)
        end

        sub_panel.buy_btn:setTag(type)
        sub_panel.root_node:setPosition(10, BEGIN_Y - (type - 1) * 80)

        self.buff_sub_panels[type] = sub_panel
    end

    self.close_btn = self.root_node:getChildByName("close_btn")
    self.view_btn = self.root_node:getChildByName("view_btn")

    self.my_right = guild_logic:GetMyGuildRight()

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function arm_msgbox:Show(user_id)
    self.user_id = user_id
    self.my_right = guild_logic:GetMyGuildRight()

    local member_info = guild_logic:GetMemberByUserid(user_id)
    local troop_info = guild_logic:GetMemberTroopInfo(user_id)

    for i = 1, #self.buff_sub_panels do
        local has_buff = self.buff_sub_panels[i]:Load(member_info, self.my_right, user_id)

        if i == BUFF_TYPE["bp"] then
            self.bp_text:setString(tostring(troop_info.battle_point))

        else
            self[BUFF_TYPE_NAME[i] .. "_text"]:setString(tostring(troop_info[BUFF_TYPE_NAME[i]]))
        end
    end

    self.buff_num_text:setString(tostring(member_info.buff_num))
    self.buff_desc_text:setString(lang_constants:GetFormattedStr("guild_war_buff_level", member_info.buff_num))

    self.root_node:setVisible(true)
end

function arm_msgbox:RegisterEvent()
    graphic:RegisterEvent("update_guild_member_buff", function(user_id)
        if not self.root_node:isVisible() then
            return
        end

        if self.user_id ~= user_id then
            return
        end

        self:Show(user_id)
    end)
end

function arm_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())

    self.view_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")

            local SOCIAL_SHOW_TYPE = client_constants["SOCIAL_EVENT_SHOW_TYPE"]["guild_member"]
            graphic:DispatchEvent("show_world_sub_panel", "social_event_panel", self.user_id, SOCIAL_SHOW_TYPE)
        end
    end)

    local buy_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")
            local buff_type = widget:getTag()

            graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", client_constants.CONFIRM_MSGBOX_MODE["buy_guild_buff"], self.user_id, buff_type)
        end
    end

    for i = 1, #self.buff_sub_panels do
        self.buff_sub_panels[i].buy_btn:addTouchEventListener(buy_method)
    end
end

return arm_msgbox
