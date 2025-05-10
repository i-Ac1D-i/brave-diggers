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

    self.buy_btn = self.root_node:getChildByName("buy_btn")
    self.armor_text = self.root_node:getChildByName("armor_desc")
    self.armor_text:setVisible(true)

    self.root_node:getChildByName("bg"):setOpacity(255 * 0.1)

    self.buff_type = buff_type
    self.buy_btn:setVisible(false)
        
    self.root_node:setVisible(true)
end

function buff_sub_panel:Load(buff_info)
    local has_buff = false
    local armor_desc_text = lang_constants:Get("guild_war_buy_buff1")

    if bit_extension:GetBitNum(buff_info, self.buff_type - 1) == 1 then
        --已经购买
        has_buff = true
    end
    
    if not has_buff then 
        armor_desc_text = lang_constants:Get("guild_war_buy_buff2")
    end

    self.armor_text:setString(armor_desc_text)

    if self.buff_type == BUFF_TYPE["bp"] then
        self.desc_text:setString(lang_constants:GetCampaignBuffType(self.buff_type) .. "+" .. BUFF_FACTOR[self.buff_type] * 100 .. "%")
    else
        self.desc_text:setString(lang_constants:GetCampaignBuffType(self.buff_type) .. "+" .. BUFF_FACTOR[self.buff_type])
    end

    return has_buff
end

local scout_arm_msgbox = panel_prototype.New(true)
function scout_arm_msgbox:Init()
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

        sub_panel.root_node:setPosition(10, BEGIN_Y - (type - 1) * 80)

        self.buff_sub_panels[type] = sub_panel
    end

    self.close_btn = self.root_node:getChildByName("close_btn")
    self.view_btn = self.root_node:getChildByName("view_btn")
    self.view_btn:setVisible(false)

    self:RegisterWidgetEvent()
end

function scout_arm_msgbox:Show(user_id)
    local rival_info = guild_logic:GetRivalInfo()
    local buff_info = 0
    local buff_num = 0

    for _,v in pairs(rival_info.field_troop) do
        if v.troop_list then
            for __,member in pairs(v.troop_list) do
                if member.user_id == user_id then
                    buff_info = member.buff_info
                    buff_num = member.buff_num
                    break
                end
            end
        end
    end

    local troop_info = guild_logic:GetRivalTroopInfo(user_id)
    for i = 1, #self.buff_sub_panels do
        local has_buff = self.buff_sub_panels[i]:Load(buff_info)

        if i == BUFF_TYPE["bp"] then
            self.bp_text:setString(tostring(troop_info.battle_point))
        else
            self[BUFF_TYPE_NAME[i] .. "_text"]:setString(tostring(troop_info[BUFF_TYPE_NAME[i]]))
        end
    end

    self.buff_num_text:setString(tostring(buff_num))
    self.buff_desc_text:setString(lang_constants:GetFormattedStr("guild_war_buff_level", buff_num))

    self.root_node:setVisible(true)
end

function scout_arm_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())
end

return scout_arm_msgbox
