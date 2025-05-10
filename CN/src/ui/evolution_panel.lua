local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local animation_manager = require "util.animation_manager"
local shader_manager = require "util.shader_manager"
local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local spine_manager = require "util.spine_manager"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local json = require "util.json"
local maze_role_prototype = require "entity.ui_role"
local achievement_logic = require "logic.achievement"
local destiny_weapon_logic = require "logic.destiny_weapon"

local BLEND_FUNC = { src = gl.SRC_ALPHA, dst = gl.ONE_MINUS_SRC_ALPHA }


local PLIST_TYPE = ccui.TextureResType.plistType
local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]
local FLASH_LEADER_TEMPLENT_ID = "9800000"
local change_leader_templent_id = "9700000"

local evolution_panel = panel_prototype.New(true)
function evolution_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/evolution_panel.csb")
    self.back_btn = self.root_node:getChildByName("back_btn")
    self.flash_btn = self.root_node:getChildByName("add_friend_btn")
    
    --解锁条件
    self.condition_name1 = self.root_node:getChildByName("cost_title_0_1")
    self.condition_num1 = self.root_node:getChildByName("cost_title_0_1_0")

    self.condition_name2 = self.root_node:getChildByName("cost_title_0_0_0")
    self.condition_num2 = self.root_node:getChildByName("cost_title_0_0_0_0")

    --呼吸背景
    self.animation_bg = self.root_node:getChildByName("Image_58")
    
    --自己英雄node
    self.own_node = self.root_node:getChildByName("own_node")

    self.role_sprite1 = cc.Sprite:create()
    self.role_sprite1:setAnchorPoint(0.5, 0.5)

    local battle_shader = shader_manager:GetProgram("battle_role")
    self.role_sprite1:setGLProgram(battle_shader)
    self.role_sprite1:setBlendFunc(BLEND_FUNC)
    self.role_sprite1:setOpacityModifyRGB(false)

    self.role_sprite1:setPosition(cc.p(0,0))
    self.role_sprite1:setScale(2)
    self.own_node:addChild(self.role_sprite1, 100)

    self.role1 = maze_role_prototype.New()

    --闪金英雄node
    self.own_node2 = self.root_node:getChildByName("own_node_next")
    self.role_sprite2 = cc.Sprite:create()
    self.role_sprite2:setAnchorPoint(0.5, 0.5)

    self.role_sprite2:setPosition(cc.p(0,0))
    self.role_sprite2:setScale(2)
    self.own_node2:addChild(self.role_sprite2, 100)

    self.role2 = maze_role_prototype.New()


    self:RegisterEvent()
    self:RegisterWidgetEvent()

    
end

--显示界面
function evolution_panel:Show()
    self.root_node:setVisible(true)
    self.start_end_animation = false

    local evolution_config = config_manager.evolution_config
    self.leader_templent_id = troop_logic:GetLeaderTempateId()
    local flash_config
    for k,v in pairs(evolution_config) do
        if tonumber(v.before_template_id) == self.leader_templent_id then
            self.flash_leader_templent_id = tonumber(k)
            flash_config = v
            break
        end
    end
    if flash_config  then
        --闪金时英雄
        self.own_node2:setVisible(true)
        self.have_full_condition = true
        self.flash_btn:setColor(cc.c3b(255,255,255))
        --解锁条件
        local index = 0    
        for k,v in pairs(flash_config.achievement_conf) do
            index = index + 1
            local achievement_name = constants["ACHIEVEMENT_TYPE_NAME"][k]
            local cur_value = achievement_logic:GetStatisticValue(k)
            if k == constants["ACHIEVEMENT_TYPE"]["destiny_num"] then
                cur_value = destiny_weapon_logic:GetWeaponNum()
            end
            if index == 1 then
                self.condition_name1:setString("1. "..lang_constants:Get("achievement_"..achievement_name))
                self.condition_num1:setString(cur_value.."/"..v)
                if cur_value >= v then
                    self.condition_num1:setColor(panel_util:GetColor4B(0xBEF337))
                else
                    --不满足条件
                    self.have_full_condition = false
                    self.flash_btn:setColor(cc.c3b(125,125,125))
                    self.condition_num1:setColor(panel_util:GetColor4B(0xEB6A47))
                end
            else
                self.condition_name2:setVisible(true)
                self.condition_num2:setVisible(true)
                self.condition_name2:setString("2. "..lang_constants:Get("achievement_"..achievement_name))
                self.condition_num2:setString(cur_value.."/"..v)
                if cur_value >= v then
                    self.condition_num2:setColor(panel_util:GetColor4B(0xBEF337))
                else
                    --不满足条件
                    self.have_full_condition = false
                    self.flash_btn:setColor(cc.c3b(125,125,125))
                    self.condition_num2:setColor(panel_util:GetColor4B(0xEB6A47))
                end
            end
            
        end
        if index == 1 then
            self.condition_name2:setVisible(false)
            self.condition_num2:setVisible(false)
        end

        --解锁后的人物
        local conf2 = config_manager.mercenary_config[self.flash_leader_templent_id]
        if conf2 then
            self.role2:Init(self.role_sprite2, conf2.sprite)
            self.role2:WalkAnimation(1)
            self.role2:SetScale(2.5,2.5)
        end
    end
    
    --现在自己的英雄
    local conf = config_manager.mercenary_config[self.leader_templent_id]
    self.role1:Init(self.role_sprite1, conf.sprite)
    self.role1:WalkAnimation(1)
    self.role1:SetScale(2.5,2.5)

    self.origin_color = self.role_sprite1:getDisplayedColor()
    self.origin_color.r = 0
    self.origin_color.g = 0
    self.origin_color.b = 0

    self.origin_opacity = 255

    self.role_sprite1:setColor(self.origin_color)

    self.role_sprite1:setOpacity(self.origin_opacity)

    --界面呼吸动画
    self.animation_bg:stopAllActions()
    self.animation_bg:setOpacity(255)
    self.animation_bg:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeTo:create(1.5, 255*0.6),cc.DelayTime:create(0.5),cc.FadeTo:create(0.7, 255),cc.DelayTime:create(3))))

end


--Update定时器
function evolution_panel:Update(elapsed_time)
    
end


function evolution_panel:RegisterEvent()

    --闪金化成功返回做动画效果
    graphic:RegisterEvent("ladder_flash_success", function()
        if not self.root_node:isVisible() then
            return
        end
        self.own_node2:setVisible(false)
        self.animation_bg:stopAllActions()
        self.animation_bg:setOpacity(255)
        graphic:DispatchEvent("show_world_sub_panel", "evolution_animation_panel", self.leader_templent_id)
    end)

end

function evolution_panel:RegisterWidgetEvent()
    --关闭按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    --闪金进化按钮
    self.flash_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.have_full_condition then
                troop_logic:FlashGoldLader()
            else
                graphic:DispatchEvent("show_prompt_panel", "evolution_flash_no_condition")
            end
        end
    end)

end

return evolution_panel

