local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local animation_manager = require "util.animation_manager"
local shader_manager = require "util.shader_manager"
local graphic = require "logic.graphic"
local panel_prototype = require "ui.panel"
local spine_manager = require "util.spine_manager"
local maze_role_prototype = require "entity.ui_role"

local BLEND_FUNC = { src = gl.SRC_ALPHA, dst = gl.ONE_MINUS_SRC_ALPHA }

local evolution_animation_panel = panel_prototype.New(true)
function evolution_animation_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/evolution_panel_up.csb")
    
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


    --闪金化动画
    self.leader_flash_timeline = animation_manager:GetTimeLine("leader_flash_timeline")
    self.root_node:runAction(self.leader_flash_timeline)

    self.leader_flash_timeline:setFrameEventCallFunc(function(frame)
        local event_name = frame:getEvent()
        if event_name == "change" then
            local origin_color = self.role_sprite1:getDisplayedColor()
            origin_color.r = 255
            origin_color.g = 255
            origin_color.b = 255

            self.origin_opacity = 0

            self.role_sprite1:setColor(origin_color)

            self.role_sprite1:setOpacity(self.origin_opacity)
            self.start_end_animation = true
        elseif event_name == "out" then
            graphic:DispatchEvent("hide_world_sub_scene")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            graphic:DispatchEvent("show_world_sub_panel", "evolution_final_panel")
        end
    end)

    self.start_end_animation = false
    
end

--显示界面
function evolution_animation_panel:Show(leader_templent_id)
    self.root_node:setVisible(true)
    self.start_end_animation = false

    local evolution_config = config_manager.evolution_config
    for k,v in pairs(evolution_config) do
        if tonumber(v.before_template_id) == leader_templent_id then
            self.flash_leader_templent_id = tonumber(k)
        end
    end
    self.leader_templent_id = leader_templent_id
    
    
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

    self.leader_flash_timeline:play("ani_in", false)

end


--Update定时器
function evolution_animation_panel:Update(elapsed_time)
    if self.start_end_animation then
        if self.origin_opacity < 255 then
            self.origin_opacity = self.origin_opacity + 6
            self.role_sprite1:setOpacity(math.floor(self.origin_opacity))
        else
            self.start_end_animation = false
            local conf = config_manager.mercenary_config[self.flash_leader_templent_id]
            self.role1:Init(self.role_sprite1, conf.sprite)
            self.role_sprite1:setColor(self.origin_color)
            self.role_sprite1:setOpacity(self.origin_opacity)
            self.role1:WalkAnimation(1)
            self.role1:SetScale(2.5,2.5)
        end
    end
end

return evolution_animation_panel

