local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local adventure_logic = require "logic.adventure"
local arena_logic = require "logic.arena"
local ladder_logic = require "logic.ladder"
local social_logic = require "logic.social"
local vip_logic = require "logic.vip"
local sns_logic = require "logic.sns"
local lang_constants = require "util.language_constants"

local config_manager = require "logic.config_manager"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local platform_manager = require "logic.platform_manager"
local client_constants = require "util.client_constants"
local MERCENARY_BG_SPRITE = client_constants["MERCENARY_BG_SPRITE"]

local PLIST_TYPE = ccui.TextureResType.plistType
local BATTLE_TYPE = client_constants.BATTLE_TYPE
local LEFT_BUFF_NODE_X = -250
local RIGHT_BUFF_NODE_X = 707

local troop_sub_panel = {}
troop_sub_panel.__index = troop_sub_panel

function troop_sub_panel.New()
    return setmetatable({}, troop_sub_panel)
end

function troop_sub_panel:Init(root_node)
    self.root_node = root_node

    self.name_text = root_node:getChildByName("role_name")
    panel_util:SetTextOutline(self.name_text, nil, 3, -5)

    self.bp_lbar = root_node:getChildByName("bp_lbar")
    self.bp_text = root_node:getChildByName("bp")
    panel_util:SetTextOutline(self.bp_text, nil, 2, -2)

    self.dodge_text = root_node:getChildByName("dodge")
    self.speed_text = root_node:getChildByName("speed")
    self.defense_text = root_node:getChildByName("defense")
    self.authority_text = root_node:getChildByName("authority")

    self.max_bp = 1
    self.cur_bp = 1
end

function troop_sub_panel:UpdateProperty(troop_entity, show_original_property)
    if show_original_property then
        self.speed_text:setString(tostring(troop_entity.original_speed))
        self.defense_text:setString(tostring(troop_entity.original_defense))
        self.dodge_text:setString(tostring(troop_entity.original_dodge))
        self.authority_text:setString(tostring(troop_entity.original_authority))
    else
        self.speed_text:setString(tostring(troop_entity.speed))
        self.defense_text:setString(tostring(troop_entity.defense))
        self.dodge_text:setString(tostring(troop_entity.dodge))
        self.authority_text:setString(tostring(troop_entity.authority))
    end
end

function troop_sub_panel:ShowBuff(troop_entity)
    local action = cc.Sequence:create(cc.ScaleTo:create(0.2, 1.8),cc.ScaleTo:create(0.2, 1))

    self.speed_text:runAction(action:clone())
    self.defense_text:runAction(action:clone())
    self.dodge_text:runAction(action:clone())
    self.authority_text:runAction(action:clone())

    self:UpdateProperty(troop_entity)
end

function troop_sub_panel:UpdateBattlePoint(cur_bp, play_animation)
    local percent = 0
    if cur_bp < 0 then
        cur_bp = 0
    end

    percent = math.min(cur_bp / self.max_bp * 100, 100)

    self.bp_text:setString(tostring(cur_bp))
    self.bp_lbar:setPercent(percent)

    self.cur_bp = cur_bp
end

local battle_panel = panel_prototype.New()

function battle_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/battle_panel.csb")

    self.troop1_sub_panel = troop_sub_panel.New()
    self.troop1_sub_panel:Init(self.root_node:getChildByName("troop1"))

    self.troop2_sub_panel = troop_sub_panel.New()
    self.troop2_sub_panel:Init(self.root_node:getChildByName("troop2"))

    self.turn_text = self.root_node:getChildByName("turn_text")

    self.skip_btn = self.root_node:getChildByName("skip_btn")

    self.bp_add_bmf = self.root_node:getChildByName("bp_add")
    self.bp_minus_bmf = self.root_node:getChildByName("bp_minus")

    self.fb_share_node = self.root_node:getChildByName("fb_share_panel")
    self.fb_share_btn = self.fb_share_node:getChildByName("fb_share_btn")
    self.fb_share_num = self.fb_share_node:getChildByName("reward_num")

    self.balance_desc1 = self.root_node:getChildByName("balance_desc1")
    self.balance_desc2 = self.root_node:getChildByName("balance_desc2")
    self.balance_desc3 = self.root_node:getChildByName("balance_desc3")
    self.tap_quit = self.root_node:getChildByName("tap_quit")

    if platform_manager:GetChannelInfo().facebook_share_not_get_reward then
        self.fb_share_desc = self.fb_share_node:getChildByName("reward_desc")
        self.fb_share_icon = self.fb_share_node:getChildByName("reward_icon")
        self.fb_share_bg = self.fb_share_node:getChildByName("bg")
        self.fb_share_num:setVisible(false)
        self.fb_share_desc:setVisible(false)
        self.fb_share_icon:setVisible(false)
        self.fb_share_bg:setVisible(false)
    end
    
    self.left_buff_btn = self.root_node:getChildByName("Button_7")
    self.right_buff_btn = self.root_node:getChildByName("Button_8")

    self.left_buff_node = self.root_node:getChildByName("left")
    self.right_buff_node = self.root_node:getChildByName("left_0")

    self.left_buff_node:getChildByName("buff1_txt_0"):setVisible(false)
    self.right_buff_node:getChildByName("buff1_txt_0"):setVisible(false)

    self.left_buff_icon_list = {}
    self.left_buff_icon_list[1] = self.root_node:getChildByName("speed_buff1")
    self.left_buff_icon_list[2] = self.root_node:getChildByName("speed_buff2")
    self.left_buff_icon_list[3] = self.root_node:getChildByName("speed_buff3")
    self.left_buff_icon_list[4] = self.root_node:getChildByName("speed_buff4")

    self.right_buff_icon_list = {}
    self.right_buff_icon_list[1] = self.root_node:getChildByName("speed_buff5")
    self.right_buff_icon_list[2] = self.root_node:getChildByName("speed_buff6")
    self.right_buff_icon_list[3] = self.root_node:getChildByName("speed_buff7")
    self.right_buff_icon_list[4] = self.root_node:getChildByName("speed_buff8")

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function battle_panel:Show(battle_type, data, left_troop_info, right_troop_info, left_rune_property, right_rune_property)
    left_rune_property = left_rune_property or {}
    right_rune_property = right_rune_property or {}

    self.left_buff_property = {}
    self.right_buff_property = {}

    self.left_buff_property.speed = (left_rune_property.mine_property.speed or 0) + (right_rune_property.enemy_property.speed or 0)
    self.left_buff_property.defense = (left_rune_property.mine_property.defense or 0) + (right_rune_property.enemy_property.defense or 0)
    self.left_buff_property.dodge = (left_rune_property.mine_property.dodge or 0) + (right_rune_property.enemy_property.dodge or 0)
    self.left_buff_property.authority = (left_rune_property.mine_property.authority or 0) + (right_rune_property.enemy_property.authority or 0)

    self.right_buff_property.speed = (right_rune_property.mine_property.speed or 0) + (left_rune_property.enemy_property.speed or 0)
    self.right_buff_property.defense = (right_rune_property.mine_property.defense or 0) + (left_rune_property.enemy_property.defense or 0)
    self.right_buff_property.dodge = (right_rune_property.mine_property.dodge or 0) + (left_rune_property.enemy_property.dodge or 0)
    self.right_buff_property.authority = (right_rune_property.mine_property.authority or 0) + (left_rune_property.enemy_property.authority or 0)

    --更新玩家军团信息
    local troop1 = self.troop1_sub_panel
    troop1.max_bp = left_troop_info.max_bp

    troop1:UpdateBattlePoint(left_troop_info.cur_bp)
    troop1:UpdateProperty(left_troop_info, true)
    troop1.name_text:setString(left_troop_info.name)

    local troop2 = self.troop2_sub_panel
    troop2.max_bp = right_troop_info.max_bp
    troop2:UpdateBattlePoint(right_troop_info.cur_bp)
    troop2:UpdateProperty(right_troop_info, true)
    troop2.name_text:setString(right_troop_info.name)

    --回合
    self.turn_text:setString("0")
    self.skip_btn:setVisible(false)

    self.bp_add_bmf:setVisible(false)
    self.bp_minus_bmf:setVisible(false)

    self.can_leave_battle = false
    self.fb_share_node:setVisible(false)

    self.balance_desc1:setOpacity(0)
    self.balance_desc2:setOpacity(0)
    self.balance_desc3:setOpacity(0)
    self.tap_quit:stopAllActions()
    self.tap_quit:setOpacity(0)

    self.battle_type = battle_type
    if self.battle_type == BATTLE_TYPE["vs_boss"] then 
        self.fb_share_num:setString(string.format(lang_constants:Get("share_og_get_reward_count"),constants["SNS_SHARE_REWARD"]["share_mining"]))
    elseif self.battle_type == BATTLE_TYPE["vs_ladder_player"] then
        self.fb_share_num:setString(string.format(lang_constants:Get("share_og_get_reward_count"),constants["SNS_SHARE_REWARD"]["share_ladder"]))
    end
    
    self.left_buff_node:setPositionX(LEFT_BUFF_NODE_X)
    self.right_buff_node:setPositionX(RIGHT_BUFF_NODE_X)

    self.left_buff_btn:setVisible(false)
    for i,left_buff_icon in ipairs(self.left_buff_icon_list) do
        left_buff_icon:setVisible(false)
    end

    self.right_buff_btn:setVisible(false)
    for i,right_buff_icon in ipairs(self.right_buff_icon_list) do
        right_buff_icon:setVisible(false)
    end
    performWithDelay(self.root_node,function() 
         self:ShowSkipBtn() 
    end,1) 
end
      
function battle_panel:ShowBuff()
    for property_name,index in pairs(constants["PROPERTY_TYPE"]) do
        local property_value = self.left_buff_property[property_name]
        local color = panel_util:GetColor4B(client_constants["TEXT_COLOR"]["write"])
        if property_value < 0 then
            self.left_buff_icon_list[index]:getChildByName("buff"):setVisible(false)
            self.left_buff_icon_list[index]:getChildByName("debuff"):setVisible(true)
            color = panel_util:GetColor4B(client_constants["TEXT_COLOR"]["red"])
        elseif property_value > 0 then
            self.left_buff_icon_list[index]:getChildByName("buff"):setVisible(true)
            self.left_buff_icon_list[index]:getChildByName("debuff"):setVisible(false)
            color = panel_util:GetColor4B(client_constants["TEXT_COLOR"]["green"])
            property_value = string.format("+%d", property_value)
        else
            self.left_buff_icon_list[index]:getChildByName("buff"):setVisible(false)
            self.left_buff_icon_list[index]:getChildByName("debuff"):setVisible(false)
        end
        self.left_buff_node:getChildByName(string.format("value0%d", index)):setColor(color)
        self.left_buff_node:getChildByName(string.format("value0%d", index)):setString(tostring(property_value))

        self.left_buff_icon_list[index]:setVisible(true)
    end
    self.left_buff_btn:setVisible(true)

    for property_name,index in pairs(constants["PROPERTY_TYPE"]) do
        local property_value = self.right_buff_property[property_name]
        local color = panel_util:GetColor4B(client_constants["TEXT_COLOR"]["write"])
        if property_value < 0 then
            self.right_buff_icon_list[index]:getChildByName("buff"):setVisible(false)
            self.right_buff_icon_list[index]:getChildByName("debuff"):setVisible(true)
            color = panel_util:GetColor4B(client_constants["TEXT_COLOR"]["red"])
        elseif property_value > 0 then
            self.right_buff_icon_list[index]:getChildByName("buff"):setVisible(true)
            self.right_buff_icon_list[index]:getChildByName("debuff"):setVisible(false)
            color = panel_util:GetColor4B(client_constants["TEXT_COLOR"]["green"])
            property_value = string.format("+%d", property_value)
        else
            self.right_buff_icon_list[index]:getChildByName("buff"):setVisible(false)
            self.right_buff_icon_list[index]:getChildByName("debuff"):setVisible(false)
        end
        self.right_buff_node:getChildByName(string.format("value0%d", index)):setColor(color)
        self.right_buff_node:getChildByName(string.format("value0%d", index)):setString(tostring(property_value))

        self.right_buff_icon_list[index]:setVisible(true)
    end
    self.right_buff_btn:setVisible(true)
end

function battle_panel:UpdateTurn(turn)
    self.turn_text:setString(tostring(turn))
end

function battle_panel:UpdateBattlePoint(troop_id, cur_bp)
    local troop_sub_panel, x, y
    if troop_id == client_constants.BATTLE["left_troop_id"] then
        troop_sub_panel = self.troop1_sub_panel
        x, y = 150, 576
    else
        troop_sub_panel = self.troop2_sub_panel
        x, y = 490, 576
    end

    local bmf
    local bp_delta = cur_bp - troop_sub_panel.cur_bp
    if bp_delta > 0 then
        self.bp_add_bmf:setVisible(true)
        self.bp_minus_bmf:setVisible(false)

        self.bp_add_bmf:setString("+" .. bp_delta)
        bmf = self.bp_add_bmf

    elseif bp_delta < 0 then
        self.bp_add_bmf:setVisible(false)
        self.bp_minus_bmf:setVisible(true)

        self.bp_minus_bmf:setString(tostring(bp_delta))

        bmf = self.bp_minus_bmf
    end

    troop_sub_panel:UpdateBattlePoint(cur_bp)

    return bmf, x, y
end

function battle_panel:SetLeave(flag)
    self.can_leave_battle = flag

    if self.battle_type == BATTLE_TYPE["vs_boss"] and sns_logic:CanShareMining() then 
            self.fb_share_node:setVisible(true)
    elseif self.battle_type == BATTLE_TYPE["vs_ladder_player"] and sns_logic:CanShareLadder() then 
            self.fb_share_node:setVisible(true)
    end
end

function battle_panel:ShowLeaveBtn()
    self.skip_btn:setVisible(false)
end

function battle_panel:ShowSkipBtn()
    self.skip_btn:setVisible(true)
end

function battle_panel:ShowBalanceDescText()
    self.balance_desc1:runAction(cc.FadeIn:create(0.3))
    self.balance_desc2:runAction(cc.FadeIn:create(0.3))
    self.balance_desc3:runAction(cc.FadeIn:create(0.3))
end

function battle_panel:ShowTapQuitText()
    local sequence = cc.Sequence:create(cc.FadeIn:create(0.5),cc.FadeOut:create(0.5))
    self.tap_quit:runAction(cc.RepeatForever:create(sequence))
end

function battle_panel:RegisterEvent()
    -- 隐藏FB按钮
    graphic:RegisterEvent("hide_battle_panel_fb_node", function()
        if self.root_node:isVisible() then
            self.fb_share_node:setVisible(false)
        end
    end)
end

function battle_panel:RegisterWidgetEvent()
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(function(touch, event)
        return true
    end, cc.Handler.EVENT_TOUCH_BEGAN)

    listener:registerScriptHandler(function(touch, event)
        if self.can_leave_battle then
            graphic:DispatchEvent("hide_battle_room")
        end
    end, cc.Handler.EVENT_TOUCH_ENDED)

    local event_dispatcher = self.root_node:getEventDispatcher()
    event_dispatcher:addEventListenerWithSceneGraphPriority(listener, self.root_node)

    self.fb_share_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.battle_type == BATTLE_TYPE["vs_boss"] then 
                sns_logic:ShareMining()
            elseif self.battle_type == BATTLE_TYPE["vs_ladder_player"] then
                sns_logic:ShareLadder()
            end
        end
    end)
end

return battle_panel
