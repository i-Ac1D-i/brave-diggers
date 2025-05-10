local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"
local resource_logic = require "logic.resource"
local graphic = require "logic.graphic"
local user_logic = require "logic.user"
local troop_logic = require "logic.troop"
local social_logic = require "logic.social"
local guild_logic = require "logic.guild"
local ui_role_prototype = require "entity.ui_role"
local ladder_tower_logic = require "logic.ladder_tower"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local config_manager = require "logic.config_manager"
local ladder_tower_logic = require "logic.ladder_tower"

local PLIST_TYPE = ccui.TextureResType.plistType
local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]
local SOCIAL_EVENT_SHOW_TYPE = client_constants["SOCIAL_EVENT_SHOW_TYPE"]

local INTERVAL_X = 80
local INTERVAL_Y = 70

local social_event_panel = panel_prototype.New(true)
function social_event_panel:Init()

    self.root_node = cc.CSLoader:createNode("ui/social_event_panel.csb")
    self.formation_btn  = self.root_node:getChildByName("formation_btn")
    self.back_btn = self.root_node:getChildByName("back_btn")
    self.confirm_btn = self.root_node:getChildByName("confirm_btn")

    self.level_img = self.root_node:getChildByName("level")

    -- body
    local root_node = self.root_node
    self.name_text = root_node:getChildByName("title_name")

    local property_bg_img = self.root_node:getChildByName("enemy_property")
    property_bg_img:setCascadeOpacityEnabled(false)
    self.speed_text = property_bg_img:getChildByName("speed_value")
    self.defense_text = property_bg_img:getChildByName("defense_value")
    self.dodge_text = property_bg_img:getChildByName("dodge_value")
    self.authority_text = property_bg_img:getChildByName("authority_value")
    self.bp_text = property_bg_img:getChildByName("bp_value")

    self.role_sprites = {}
    self.ui_roles = {}

    self.mercenary_bg_imgs = {}
    self.mercenary_bg_imgs[1] = self.root_node:getChildByName("mercenary_bg")
    local icon = self.mercenary_bg_imgs[1]:getChildByName("icon")
    icon:setVisible(false)

    local role_sprite = cc.Sprite:create()
    role_sprite:setAnchorPoint(0.5, 0)

    role_sprite:setPosition(icon:getPosition())
    self.mercenary_bg_imgs[1]:addChild(role_sprite, 100)

    self.role_sprites[1] = role_sprite
    self.ui_roles[1] = ui_role_prototype.New()

    local begin_x = self.mercenary_bg_imgs[1]:getPositionX()
    local begin_y = self.mercenary_bg_imgs[1]:getPositionY()

    for i = 2, 25 do
        local row = math.ceil(i / 5)
        local col = i - (row - 1) * 5

        local x = begin_x + (col - 1) * INTERVAL_X
        if (row % 2 ) == 0 then
            x = x + 40
        end

        local y = begin_y - (row - 1) * INTERVAL_Y

        self.mercenary_bg_imgs[i] = self.mercenary_bg_imgs[1]:clone()
        self.mercenary_bg_imgs[i]:setPosition(x, y)
        self.root_node:addChild(self.mercenary_bg_imgs[i])

        local icon = self.mercenary_bg_imgs[i]:getChildByName("icon")
        icon:setVisible(false)

        local role_sprite = cc.Sprite:create()
        role_sprite:setAnchorPoint(0.5, 0)
        role_sprite:setPosition(icon:getPosition())
        self.mercenary_bg_imgs[i]:addChild(role_sprite, 100)

        self.role_sprites[i] = role_sprite
        self.ui_roles[i] = ui_role_prototype.New()
    end

    self.show_type = SOCIAL_EVENT_SHOW_TYPE["friend"] 

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function social_event_panel:Show(user_id, show_type)
    self.user_id = user_id or self.user_id

    self.show_type = show_type or SOCIAL_EVENT_SHOW_TYPE["friend"] 
    
    if self.level_img then
        self.level_img:setVisible(false)
    end

    if self.show_type == SOCIAL_EVENT_SHOW_TYPE["guild_member"] then 
       self.formation_btn:setVisible(false)
       self.confirm_btn:setVisible(false)
    elseif self.show_type == SOCIAL_EVENT_SHOW_TYPE["ladder_tower_member"] then
        self.formation_btn:setVisible(false)
        self.confirm_btn:setVisible(true)
        if self.level_img then
            self.level_img:setVisible(true)
        end
    else
        self.formation_btn:setVisible(true)
        self.confirm_btn:setVisible(true)
    end

    self.root_node:setVisible(true)

    self:LoadFormationInfo()
    self:ShowTroopInfo(self.user_id)
end

function social_event_panel:LoadFormationInfo()
    local const_str = lang_constants:Get("mercenary_adjust_formation") .. ": " .. troop_logic:GetFormationName()
    self.formation_btn:setTitleText(const_str)
end

function social_event_panel:ShowTroopInfo(cur_user_id)
    self.root_node:setVisible(true)
    local troop_info 
    if self.show_type == SOCIAL_EVENT_SHOW_TYPE["guild_member"] then 
        troop_info = guild_logic:GetMemberTroopInfo(cur_user_id)
    elseif self.show_type == SOCIAL_EVENT_SHOW_TYPE["ladder_tower_member"] then
        --当前这个cur_user_id是天梯赛中的玩家的位置
        troop_info = ladder_tower_logic:GetMemberTroopInfo(cur_user_id)
        --等级图标
        if self.level_img then
            self.level_img:loadTexture(client_constants["LADDER_LEVEL_S_IMG_TYPE"][troop_info.cur_group], PLIST_TYPE)  
        end
    else
        troop_info = social_logic:GetFriendTroopInfo(cur_user_id)
    end

    if not troop_info then
        return
    end

    self.bp_text:setString(tostring(troop_info.battle_point))
    self.name_text:setString(troop_info.name)
    self.dodge_text:setString(tostring(troop_info.dodge))
    self.speed_text:setString(tostring(troop_info.speed))
    self.defense_text:setString(tostring(troop_info.defense))
    self.authority_text:setString(tostring(troop_info.authority))

    local num = #troop_info.template_id_list
    for i = 1, num do
        local template_id = troop_info.template_id_list[i]
        local conf = config_manager.mercenary_config[template_id]
        local img = conf.sprite

        self.ui_roles[i]:Init(self.role_sprites[i], img)
        self.ui_roles[i]:WalkAnimation(1, 0.2)
        self.mercenary_bg_imgs[i]:setColor(panel_util:GetColor4B(0xffffff))
        self.mercenary_bg_imgs[i]:setVisible(true)
    end

    for i = num + 1, constants["MAX_FORMATION_CAPACITY"] do
        self.role_sprites[i]:setVisible(false)
        self.mercenary_bg_imgs[i]:setVisible(false)
        self.mercenary_bg_imgs[i]:setColor(panel_util:GetColor4B(0x7f7f7f))
    end
end

function social_event_panel:RegisterWidgetEvent()

    local touchlistener = function (widget, event_type)
        local tag = widget:getTag()

        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if tag == self.formation_btn:getTag() then
                local trans_type = constants["SCENE_TRANSITION_TYPE"]["none"]
                local mode = client_constants["FORMATION_PANEL_MODE"]["multi"]
                local back_panel = self:GetName()
                graphic:DispatchEvent("show_world_sub_scene", "formation_sub_scene", trans_type, mode, back_panel)
                graphic:DispatchEvent("hide_world_sub_panel", self:GetName())

            elseif tag == self.back_btn:getTag() then
                graphic:DispatchEvent("hide_world_sub_panel", self:GetName())

            elseif tag == self.confirm_btn:getTag() then
                if self.show_type == SOCIAL_EVENT_SHOW_TYPE["ladder_tower_member"] then
                    if ladder_tower_logic.figthing_count <= 0 then
                        graphic:DispatchEvent("show_prompt_panel", "top_challenge_times")
                        local mode = client_constants["BATCH_MSGBOX_MODE"]["ladder_tower_fighting_times"]
                        graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode)
                    else
                        ladder_tower_logic:Figthing(self.user_id)
                    end
                else
                    social_logic:ChallengeFriend(self.user_id)
                end
            end
        end
    end

    self.formation_btn:addTouchEventListener(touchlistener)
    self.back_btn:addTouchEventListener(touchlistener)
    self.confirm_btn:addTouchEventListener(touchlistener)
end

function social_event_panel:RegisterEvent()
    graphic:RegisterEvent("change_troop_formation", function()
        if not self.root_node:isVisible() then
            return
        end

        self:LoadFormationInfo()
    end)
end

return social_event_panel

