local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local adventure_logic = require "logic.adventure"
local arena_logic = require "logic.arena"
local ladder_logic = require "logic.ladder"
local social_logic = require "logic.social"
local vip_logic = require "logic.vip"
local sns_logic = require "logic.sns"
local lang_constants = require "util.language_constants"
local utils = require "util.utils"
local config_manager = require "logic.config_manager"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"
local spine_manager = require "util.spine_manager"
local title_panel = require "ui.title_panel"
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local platform_manager = require "logic.platform_manager"
local client_constants = require "util.client_constants"
local MERCENARY_BG_SPRITE = client_constants["MERCENARY_BG_SPRITE"]
local feature_config = require "logic.feature_config"
local BATTLE_TYPE = client_constants.BATTLE_TYPE
local LEFT_BUFF_NODE_X = -250
local RIGHT_BUFF_NODE_X = 707
local destiny_skill_config = config_manager.destiny_skill_config
local PLIST_TYPE = ccui.TextureResType.plistType

local troop_sub_panel = {}
troop_sub_panel.__index = troop_sub_panel

function troop_sub_panel.New()
    return setmetatable({}, troop_sub_panel)
end

function troop_sub_panel:Init(root_node)
    self.root_node = root_node

    self.name_text = root_node:getChildByName("role_name")
    
    local channel = platform_manager:GetChannelInfo()
    if channel.meta_channel ~= "txwy_dny" then
        --东南亚渠道不加描边
        panel_util:SetTextOutline(self.name_text, nil, 3, -5)
    end

    self.bp_lbar = root_node:getChildByName("bp_lbar")
    self.bp_shieldbar = root_node:getChildByName("bp_shieldbar")
    self.bp_text = root_node:getChildByName("bp")
    if channel.meta_channel ~= "txwy_dny" then
        --东南亚渠道不加描边
        panel_util:SetTextOutline(self.bp_text, nil, 2, -2)
    end

    self.dodge_text = root_node:getChildByName("dodge")
    self.speed_text = root_node:getChildByName("speed")
    self.defense_text = root_node:getChildByName("defense")
    self.authority_text = root_node:getChildByName("authority")

    self.max_bp = 1
    self.cur_bp = 1
    cc.SpriteFrameCache:getInstance():addSpriteFrames("res/ui/entrust.plist")
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

function troop_sub_panel:UpdateBattlePoint(cur_bp, cur_shield_bp)
    local percent = 0
    if cur_bp < 0 then
        cur_bp = 0
    end
    percent = math.min(cur_bp / self.max_bp * 100, 100)

    local percent2 = 0
    if cur_shield_bp < 0 then
        cur_shield_bp = 0
    end
    percent2 = math.min(cur_shield_bp / self.max_bp * 100, 100)

    local all_bp = cur_bp + cur_shield_bp

    self.bp_text:setString(tostring(all_bp))
    self.bp_lbar:setPercent(percent)
    self.bp_shieldbar:setPercent(percent2)
    self.cur_bp = all_bp
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

    self.property_desc_left = self.left_buff_node:getChildByName("buff1_txt_0")
    if self.property_desc_left then
        self.property_desc_origin_left = cc.p(self.property_desc_left:getPosition())
        self.property_desc_left:setVisible(false)
    end

    self.property_desc_right = self.right_buff_node:getChildByName("buff1_txt_0")
    if self.property_desc_right then 
        self.property_desc_origin_right = cc.p(self.property_desc_right:getPosition())
        self.property_desc_right:setVisible(false)
    end

    if feature_config:IsFeatureOpen("mine_and_cultivation") and self.property_desc_left then
        self.left_nodes = {}
        self.right_nodes = {} 
        self:InitailList(self.left_nodes,self.property_desc_origin_left,self.property_desc_left,self.left_buff_node)
        self:InitailList(self.right_nodes,self.property_desc_origin_right,self.property_desc_right,self.right_buff_node)
    end
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

    self.left_weapon_img = self.root_node:getChildByName("weapon_icon")
    self.left_weapon_node = self.root_node:getChildByName("Node_22")
    self.right_weapon_img = self.root_node:getChildByName("weapon_icon_0")
    self.right_weapon_node = self.root_node:getChildByName("Node_22_0")
    if feature_config:IsFeatureOpen("title") then
        self.left_title = title_panel.New()
        self.left_title:Init(cc.CSLoader:createNode("ui/title_player.csb"))
        self.root_node:addChild(self.left_title.root_node)
        self.left_title_origin = cc.p(-100,560)
        self.left_title.root_node:setPosition(self.left_title_origin)
        self.left_title:Hide()

        self.right_title = title_panel.New()
        self.right_title:Init(cc.CSLoader:createNode("ui/title_player.csb"))  
        self.root_node:addChild(self.right_title.root_node)
        self.right_title_origin = cc.p(740,550)
        self.right_title.root_node:setPosition(self.right_title_origin)
        self.right_title:Hide()
    end

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function battle_panel:RecordPos()
    self.left_title.root_node:setPosition(self.left_title_origin)
    self.right_title.root_node:setPosition(self.right_title_origin)
end

function battle_panel:InitailList(node_container,origin_pos,item_retain,parent)
    
    local top_x = origin_pos.x
    local top_y = origin_pos.y 
    for i=1,6 do
        local new_item = item_retain:clone()
         new_item:setPosition(cc.p(top_x,top_y))
         new_item:setVisible(true)
         local skill_icon = new_item:getChildByName("Image_119")

            if i == 1 then
                print()
                skill_icon:loadTexture("bg/skill/skill_2.png", PLIST_TYPE)
            elseif i == 2 then
                skill_icon:loadTexture("entrust/skill_22.png", PLIST_TYPE)
            elseif i == 3 then
                skill_icon:loadTexture("entrust/skill_23.png", PLIST_TYPE)
            elseif i == 4 then
                skill_icon:loadTexture("entrust/skill_24.png", PLIST_TYPE)
            elseif i == 5 then
                skill_icon:loadTexture("bg/skill/skill_13.png", PLIST_TYPE)
            elseif i == 6 then
                skill_icon:loadTexture("bg/skill/skill_9.png", PLIST_TYPE)
            end


         local value1 = new_item:getChildByName("buff1_txt_0_0")
         local value2 = new_item:getChildByName("buff1_txt_0_0_0")
         value1:setString("0%")
         value2:setString("0%")
         parent:addChild(new_item)
         table.insert(node_container,value1)
         table.insert(node_container,value2)

         top_y = top_y - 60
    end
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

    troop1:UpdateBattlePoint(left_troop_info.cur_bp, left_troop_info.cur_shield_bp)
    troop1:UpdateProperty(left_troop_info, true)
    troop1.name_text:setString(left_troop_info.name)

    local troop2 = self.troop2_sub_panel
    troop2.max_bp = right_troop_info.max_bp
    troop2:UpdateBattlePoint(right_troop_info.cur_bp, right_troop_info.cur_shield_bp)
    troop2:UpdateProperty(right_troop_info, true)
    troop2.name_text:setString(right_troop_info.name)

    self.left_cultivation_property = left_troop_info.cultivation_property or {}
    self.right_cultivation_property = right_troop_info.cultivation_property or {}

    self.left_weapon_info = left_troop_info.weapon_info or {}
    self.right_weapon_info = right_troop_info.weapon_info or {}
    self.left_have_ladder = left_troop_info.have_leader
    self.right_have_ladder = right_troop_info.have_leader

    if feature_config:IsFeatureOpen("title") then
        self.left_title_id = left_troop_info.title_id
        self.right_title_id = right_troop_info.title_id

        self:RecordPos() 
        if self.left_title_id and self.left_title_id ~= 0 then
            self.left_title:Show()
            self.left_title:Load(self.left_title_id)
            performWithDelay(self.root_node,function()
                self.left_title:PlayAnimation()
            end,0.2)
            self.left_title:PlayBattleAction(0.2,cc.p(200,0),function() 
                    self.left_title.root_node:setPosition(cc.p(115,1090))
                    self.left_title.root_node:setOpacity(0)
                    local action = cc.FadeIn:create(0.5)
                    self.left_title.root_node:runAction(action)
                end)
        else
            self.left_title:Hide()
        end
        if self.right_title_id and self.right_title_id ~= 0 then
            self.right_title:Show()
            self.right_title:Load(self.right_title_id)
            performWithDelay(self.root_node,function()
                self.right_title:PlayAnimation() 
            end,0.2)
            self.right_title:PlayBattleAction(0.2,cc.p(-200,0),function() 
                    self.right_title.root_node:setPosition(cc.p(525,1090))
                    self.right_title.root_node:setOpacity(0)
                    local action = cc.FadeIn:create(0.5)
                    self.right_title.root_node:runAction(action)
                end)
        else
            self.right_title:Hide()
        end
    end

    --回合
    self.turn_text:setString("0")

    self.bp_add_bmf:setVisible(false)
    self.bp_minus_bmf:setVisible(false)

    self.can_leave_battle = false
    self.fb_share_node:setVisible(false)

    if self.balance_desc1 then
        self.balance_desc1:setOpacity(0)
        self.balance_desc2:setOpacity(0)
        self.balance_desc3:setOpacity(0)
    end
    if self.tap_quit then
        self.tap_quit:stopAllActions()
        self.tap_quit:setOpacity(0)
    end

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
        --虚空不要跳过按钮
        if self.battle_type == BATTLE_TYPE["vs_vanity"] then
            self:ShowLeaveBtn()
        else
            self:ShowSkipBtn() 
        end
    end,1)

    if feature_config:IsFeatureOpen("expedition_and_destiny_weapon") then
        self.left_weapon_img:setVisible(false)
        self.right_weapon_img:setVisible(false)
        self.left_weapon_node:removeAllChildren()
        self.right_weapon_node:removeAllChildren()
    end

    --虚空不要跳过按钮
    if self.battle_type == BATTLE_TYPE["vs_vanity"] then
        self:ShowLeaveBtn()
    else
        self:ShowSkipBtn() 
    end
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
    if feature_config:IsFeatureOpen("mine_and_cultivation") then
        for index,item in ipairs(self.left_cultivation_property) do
            if item.coefficient1 then
                self.left_nodes[index*2 -1]:setString(math.abs(item.coefficient1).."%")
            end

            if item.coefficient2 then
                self.left_nodes[index*2]:setString(math.abs(item.coefficient2).."%")
            end
        end

        for index,item in ipairs(self.right_cultivation_property) do
            if item.coefficient1 then
                self.right_nodes[index*2 -1]:setString(math.abs(item.coefficient1).."%")
            end

            if item.coefficient2 then
                self.right_nodes[index*2]:setString(math.abs(item.coefficient2).."%") 
            end
        end
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

function battle_panel:ShowWeapon()
    if feature_config:IsFeatureOpen("expedition_and_destiny_weapon") then
        if self.left_weapon_info.weapon_id > 0 and self.left_have_ladder then
            local weapon_config = destiny_skill_config[self.left_weapon_info.weapon_id]
            self.left_weapon_img:loadTexture(weapon_config["icon"], PLIST_TYPE)
            self.left_weapon_img:setVisible(true)

            if self.left_weapon_info.star_level >= 4 then
                local spine = spine_manager:GetNode("lose_light", 1.0, true)
                if self.left_weapon_info.star_level < 8 then
                    spine:setAnimation(0, "b_light", true)
                elseif self.left_weapon_info.star_level < 12 then
                    spine:setAnimation(0, "g_light3", true)
                else
                    spine:setAnimation(0, "y_light2", true)
                end
                self.left_weapon_node:addChild(spine)
            end
        elseif self.left_weapon_img then
            self.left_weapon_img:setVisible(false)
        end
    end

    if self.right_weapon_info.weapon_id > 0 and self.right_have_ladder then
        local weapon_config = destiny_skill_config[self.right_weapon_info.weapon_id]
        self.right_weapon_img:loadTexture(weapon_config["icon"], PLIST_TYPE)
        self.right_weapon_img:setVisible(true)

        if self.right_weapon_info.star_level >= 4 then
            local spine = spine_manager:GetNode("lose_light", 1.0, true)
            if self.right_weapon_info.star_level < 8 then
                spine:setAnimation(0, "b_light", true)
            elseif self.right_weapon_info.star_level < 12 then
                spine:setAnimation(0, "g_light3", true)
            else
                spine:setAnimation(0, "y_light2", true)
            end
            self.right_weapon_node:addChild(spine)
        end
    elseif self.right_weapon_img then
        self.right_weapon_img:setVisible(false)
    end
end

function battle_panel:UpdateTurn(turn)
    self.turn_text:setString(tostring(turn))
end

function battle_panel:UpdateBattlePoint(troop_id, cur_bp, cur_shield_bp, resist_lethal_damage)
    local troop_sub_panel, x, y
    if troop_id == client_constants.BATTLE["left_troop_id"] then
        troop_sub_panel = self.troop1_sub_panel
        x, y = 150, 576
    else
        troop_sub_panel = self.troop2_sub_panel
        x, y = 490, 576
    end

    local bmf
    local bp_delta = cur_bp + cur_shield_bp - troop_sub_panel.cur_bp
    if resist_lethal_damage then
        bp_delta = resist_lethal_damage
    end
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
    
    troop_sub_panel:UpdateBattlePoint(cur_bp , cur_shield_bp)

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
    if self.balance_desc1 then
        self.balance_desc1:runAction(cc.FadeIn:create(0.3))
        self.balance_desc2:runAction(cc.FadeIn:create(0.3))
        self.balance_desc3:runAction(cc.FadeIn:create(0.3))
    end
end

function battle_panel:ShowTapQuitText()
    if self.tap_quit then
        local sequence = cc.Sequence:create(cc.FadeIn:create(0.5),cc.FadeOut:create(0.5))
        self.tap_quit:runAction(cc.RepeatForever:create(sequence))
    end
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
