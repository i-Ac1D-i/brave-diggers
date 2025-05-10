local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local campaign_logic = require "logic.campaign"
local lang_constants = require "util.language_constants"
local troop_logic = require "logic.troop"
local panel_util = require "ui.panel_util"
local graphic = require "logic.graphic"
local client_constants = require "util.client_constants"
local icon_text_panel = require "ui.icon_panel"

local constants = require "util.constants"

-- 设置item信息
local function SetItemInfo(item, data)
    local level_desc1 = item:getChildByName("level_desc1")
    local level_desc2 = item:getChildByName("level_desc2")
    local item_desc = item:getChildByName("item_desc")
    local get_btn = item:getChildByName("get_btn")
    get_btn.data = data

    local cost_num1_text = get_btn:getChildByName("cost_resource_num1")
    local name_text = item:getChildByName("name")

    local type_str = lang_constants:GetCampaignBuffType(data.type)
    local title_str = ""

    local icon_img = item:getChildByName("iconbg")
    icon_img:removeAllChildren()

    if data.type == constants["CAMPAIGN_CONVERT_SCORE"] then
        level_desc1:setVisible(false)
        level_desc2:setVisible(false)
        title_str = string.format(lang_constants:Get("campaign_score"),type_str,data.next_value,data.level)
        item_desc:setString(lang_constants:Get("campaign_res_score_desc"))

        local icon_panel = icon_text_panel.New(nil, 2)
        icon_panel:Init(icon_img)
        icon_panel:SetPosition(55,55)
        icon_panel:Show(constants["REWARD_TYPE"]["campaign"], 2, data.next_value, false, true)

    else
        item_desc:setVisible(false)
        title_str = string.format(lang_constants:Get("campaign_buff"),type_str,data.level)
        level_desc1:setString(string.format(lang_constants:Get("campaign_level_cur"),type_str,data.cur_value))
        level_desc2:setString(string.format(lang_constants:Get("campaign_level_next"),type_str,data.next_value))

        local icon = cc.Sprite:createWithSpriteFrameName(client_constants.CAMPAIGN_PROPERTY_ICON[data.type])
        icon:setPosition(55, 55)
        icon:setAnchorPoint(0.5, 0.5)
        icon_img:addChild(icon)
    end

    name_text:setString(title_str)

    if data.req_exp == 0  then
        get_btn:setVisible(false)
    else
        cost_num1_text:setString(data.req_exp)
    end

end

local campaign_buff_msgbox = panel_prototype.New(true)
function campaign_buff_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/campaign_buff_panel.csb")

    self.exp_txt = self.root_node:getChildByName("ladder_num")

    self.buff_list = self.root_node:getChildByName("list_view")

    self.score_template = self.root_node:getChildByName("point_template")
    self.score_template:setVisible(false)

    self.formation_name_text = self.root_node:getChildByName("formation_desc")

    self.buff_item_list = {}

    self.property_texts = {}

    local property_img = self.root_node:getChildByName("property_bg")
    self.property_texts[1] = property_img:getChildByName("speed_value")
    self.property_texts[2] = property_img:getChildByName("defense_value")
    self.property_texts[3] = property_img:getChildByName("dodge_value")
    self.property_texts[4] =  property_img:getChildByName("authority_value")

    self.bp_text = property_img:getChildByName("bp_value")

    self:RegisterWidgetEvent()
    self:RegisterEvent()

    for k,v in pairs(campaign_logic.buff_info_map) do

        local item = self.score_template:clone()
        item:setVisible(true)
        SetItemInfo(item, v)

        local get_btn = item:getChildByName("get_btn")
        get_btn:addTouchEventListener(self.buy_buff_method)

        self.buff_list:addChild(item)
        self.buff_item_list[v.type] = item
    end
end

function campaign_buff_msgbox:Show()
    self.root_node:setVisible(true)

    self.exp_txt:setString(campaign_logic.exp)

    for k,v in pairs(self.buff_item_list) do
        SetItemInfo(v,campaign_logic.buff_info_map[k])
    end

    self:UpdateTroopProperty()
end

function campaign_buff_msgbox:UpdateTroopProperty()
    self.formation_name_text:setString(string.format(lang_constants:Get("mercenary_cur_formation"), troop_logic.cur_formation_id))

    local speed, authority, dodge, defense = troop_logic:GetTroopProperty(troop_logic.cur_formation_id)

    for i, val in ipairs({speed, defense, dodge, authority}) do
        self.property_texts[i]:setString(val + campaign_logic.buff_info_map[i+1].cur_value + campaign_logic.evo_info_list[i+1])
    end
    panel_util:ConvertUnit(campaign_logic.buff_info_map[1].cur_value + campaign_logic.evo_info_list[1], self.bp_text)
end

function campaign_buff_msgbox:RegisterEvent()
    -- 更新BUFF—Item
    graphic:RegisterEvent("update_buff_msgbox_item", function(data)
        local item = self.buff_item_list[data.type]
        SetItemInfo(item, data)
        self.exp_txt:setString(campaign_logic.exp)
        self:UpdateTroopProperty()
    end)

end

function campaign_buff_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), "campaign_buff_msgbox")

    self.buy_buff_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            local item_data = widget.data
            local mode = client_constants.CONFIRM_MSGBOX_MODE["buy_campaign_buff"]
            graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode, item_data)

            -- campaign_logic:BuyBuff(item_data)
        end
    end
end

return campaign_buff_msgbox
