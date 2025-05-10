local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local animation_manager = require "util.animation_manager"
local achievement_logic = require "logic.achievement"
local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local spine_manager = require "util.spine_manager"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local json = require "util.json"
local maze_role_prototype = require "entity.ui_role"
local icon_panel = require "ui.icon_panel"
local shader_manager = require "util.shader_manager"

local PLIST_TYPE = ccui.TextureResType.plistType
local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]
local FLASH_LEADER_TEMPLENT_ID = "9800000"
local CHNAGE_LEADER_TEMPLENT_ID = "9700000"
local MAX_TEMPLENT_ID = 7
local BLEND_FUNC = { src = gl.SRC_ALPHA, dst = gl.ONE_MINUS_SRC_ALPHA }
local ACTION_TYPE = {
    unlock = 1,
    use = 2,
}
--templent node
local role_node_panel = panel_prototype.New()
role_node_panel.__index = role_node_panel

function role_node_panel.New()
    return setmetatable({}, role_node_panel)
end

function role_node_panel:Init(root_node, parent)
    self.root_node = root_node
    self.root_node:setTouchEnabled(true)
    self.icon_img = self.root_node:getChildByName("icon")
    self.select_img = self.root_node:getChildByName("equiped_icon")
    self.lock_img = self.root_node:getChildByName("lock")

    self.root_node:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            parent:SelectTemplent(self.templent_id)
        end
    end)
end


function role_node_panel:Show(info_conf)
    self.root_node:setVisible(true)
    self.templent_id = info_conf.ID
    self.conf_icon = client_constants["MERCENARY_ROLE_IMG_PATH"] .. info_conf.sprite .. ".png"
    self.icon_img:loadTexture(self.conf_icon, PLIST_TYPE)
    self.select_img:setVisible(false)
    self.lock_img:setVisible(false)
end

function role_node_panel:UnlockState(state)
    if troop_logic:UnLockSkin(self.templent_id) then
        self.lock_img:setVisible(false)
    else
        self.lock_img:setVisible(true)
    end
    if self.templent_id == troop_logic:GetLeaderTempateId() then
        self.select_img:setVisible(true)
    else
        self.select_img:setVisible(false)
    end
    
end

function role_node_panel:SetStatus(template_id)
    if self.templent_id == template_id then
        self.root_node:setColor(panel_util:GetColor4B(0xffffff))
        self.icon_img:setColor(panel_util:GetColor4B(0xffffff))
        self.select_img:setColor(panel_util:GetColor4B(0xffffff))
        self.lock_img:setColor(panel_util:GetColor4B(0xffffff))
    else
        self.root_node:setColor(panel_util:GetColor4B(0x7F7F7F))
        self.icon_img:setColor(panel_util:GetColor4B(0x7F7F7F))
        self.select_img:setColor(panel_util:GetColor4B(0x7F7F7F))
        self.lock_img:setColor(panel_util:GetColor4B(0x7F7F7F))
    end
end




local evolution_final_panel = panel_prototype.New(true)
function evolution_final_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/evolution_final_panel.csb")
    self.back_btn = self.root_node:getChildByName("back_btn")
    local bg = self.root_node:getChildByName("bg")

    self.unlock_animation = cc.CSLoader:createNode("ui/node_levelup_light.csb")
    self.unlock_animation:setScale(4)
    self.unlock_animation:setPosition(cc.p(bg:getContentSize().width/2, bg:getContentSize().height/2))
    bg:addChild(self.unlock_animation)
    self.leader_unlock_timeline = animation_manager:GetTimeLine("leader_unlock_timeline")
    self.unlock_animation:runAction(self.leader_unlock_timeline)
    self.unlock_animation:setVisible(false)

    bg:setTouchEnabled(true)

    self.list_view = self.root_node:getChildByName("list_view")

    self.templent = self.list_view:getChildByName("weapon_template")

    self.shadow = self.root_node:getChildByName("shadow")

    --装备动画
    self.use_animation = cc.CSLoader:createNode("ui/ladder_light.csb")
    self.use_animation:setScale(0.25)
    self.use_animation:setPosition(cc.p(self.shadow:getContentSize().width/2, self.shadow:getContentSize().height))
    self.shadow:addChild(self.use_animation)
    self.leader_use_timeline = animation_manager:GetTimeLine("leader_use_timeline")
    self.use_animation:runAction(self.leader_use_timeline)
    self.use_animation:setVisible(false)

    --主角名字
    self.name_text = self.root_node:getChildByName("biography_bg_0"):getChildByName("name_0")

    self.change_name_btn = self.root_node:getChildByName("back_btn_0")

    self.role_name = self.root_node:getChildByName("is_get_status")
    panel_util:SetTextOutline(self.role_name)

    --解锁按钮
    self.unlock_btn = self.root_node:getChildByName("bottom_bar"):getChildByName("points_btn")

    --解锁条件
    self.condition_name1 = self.root_node:getChildByName("cost_title_0_1")
    self.condition_num1 = self.root_node:getChildByName("cost_title_0_1_0")

    self.condition_name2 = self.root_node:getChildByName("cost_title_0_0_0")
    self.condition_num2 = self.root_node:getChildByName("cost_title_0_0_0_0")

    --消耗
    self.reward_bg = self.root_node:getChildByName("skill_desc_bg_0_0")

    self.unlock_desc_bg = self.root_node:getChildByName("biography_bg")
    self.unlock_desc_scrollview = self.unlock_desc_bg:getChildByName("desc_sview")
    self.unlock_desc_scrollview:setInnerContainerSize(cc.size(0,0))
    self.unlock_desc_text = self.unlock_desc_scrollview:getChildByName("slogan")
    self.unlock_desc_text:setPosition(cc.p(0,self.unlock_desc_scrollview:getContentSize().height))
    self.unlock_desc_bg:setVisible(false)


    --自己英雄node
    self.role_sprite1 = cc.Sprite:create()
    self.role_sprite1:setAnchorPoint(0.5, 0)

    self.role_sprite1:setPosition(self.shadow:getPosition())
    self.role_sprite1:setScale(2)

    self.battle_shader = shader_manager:GetProgram("battle_role")
    self.grayscale_shader = shader_manager:GetProgram("grayscale") 
    self.role_sprite_shader = self.role_sprite1:getGLProgram()
    self.role_sprite1:setBlendFunc(BLEND_FUNC)
    
    self.root_node:addChild(self.role_sprite1, 100)

    self.role1 = maze_role_prototype.New()

    self.origin_color = nil
    self.add_step = 1
    self.action_type = nil

    self.role_node_panel_list = {}
    self.cost_sub_panels = {}

    self.leader_unlock_timeline:clearFrameEventCallFunc()
    self.leader_unlock_timeline:setFrameEventCallFunc(function(frame)
        local event_name = frame:getEvent()
        if event_name == "over" then
            self:SelectTemplent(self.leader_templent_id, true)
        end
    end)

    self:RegisterEvent()
    self:RegisterWidgetEvent()

    
end

--显示界面
function evolution_final_panel:Show()
    self.root_node:setVisible(true)
        
    --得到所有皮肤英雄id
    local evolution_config = config_manager.evolution_config
    local flash_templeat_ids = {}
    for k,v in pairs(evolution_config) do
        if (v.before_template_id and tonumber(v.before_template_id) == 0) or v.before_template_id == nil then
            table.insert(flash_templeat_ids, tonumber(k))
        end
    end
    --皮肤id排序
    table.sort(flash_templeat_ids, function (v1, v2)
        return v1 < v2
    end)

    for i = 1, #flash_templeat_ids + 1 do
        local template_id 
        if i == 1 then
            --第一个是闪金主角升级时获得的
            template_id = troop_logic.origin_skin_template_id
        else
            template_id = flash_templeat_ids[i-1]
        end
        local conf = config_manager.mercenary_config[template_id]
        if self.role_node_panel_list[i] == nil then
            local temp_node 
            if i == 1 then
                temp_node = self.templent
            else
               temp_node = self.templent:clone()
               self.list_view:addChild(temp_node)
            end
             
            local role_node = role_node_panel.New()
            self.role_node_panel_list[i] = role_node
            role_node:Init(temp_node, self)
        end
        self.role_node_panel_list[i]:Show(conf)
    end
    self:UpdateUnlockState()
    
    self:SelectTemplent(troop_logic:GetLeaderTempateId(),true)

    self.name_text:setString(troop_logic:GetLeaderName())

end

function evolution_final_panel:UpdateUnlockState()
    for k,role_node in pairs(self.role_node_panel_list) do
        role_node:UnlockState()
    end
end

function evolution_final_panel:SetDesc(desc_text)
    self.unlock_desc_text:setString(desc_text)
end

function evolution_final_panel:SelectTemplent(template_id, is_change)
    --现在自己的英雄
    if self.leader_templent_id ~= template_id or is_change then
        self.stopAction = true
        self.leader_templent_id = template_id
        for k,role_node in pairs(self.role_node_panel_list) do
            role_node:SetStatus(template_id)
        end

        self.role_sprite1:setOpacityModifyRGB(false)
        self.role_sprite1:setGLProgram(self.role_sprite_shader)
        self.role_sprite1:setColor(cc.c3b(255,255,255))
        self.unlock_btn:setColor(cc.c3b(255,255,255))

        

        local conf = config_manager.mercenary_config[template_id]
        --解锁条件和消耗
        local unlock_conf = config_manager.evolution_config[template_id]
        if troop_logic:UnLockSkin(template_id) then
            unlock_conf = nil
            if template_id == troop_logic:GetLeaderTempateId() then
                --已装备
                self.role_name:setString(lang_constants:Get("evolution_equipment"))
                self.role_name:setColor(panel_util:GetColor4B(0xb8ec4a))
            else
                --已获得未装备
                self.role_name:setString(lang_constants:Get("evolution_have"))
                self.role_name:setColor(panel_util:GetColor4B(0xffffff))
            end
            self.role1:Init(self.role_sprite1, conf.sprite)
            self.walk_animate_forever = self.role1:WalkAnimation(1)
            self.role_sprite1:setOpacity(255)
            self.role1:SetScale(4,4)

            --设置描述文字
            local conf = config_manager.mercenary_config[template_id]
            if conf and conf.introduction then
                self:SetDesc(conf.introduction)
            else
                self:SetDesc("")
            end
            --解锁按钮显示
            if template_id ~= troop_logic:GetLeaderTempateId() then
                self.unlock_btn:setVisible(true)
                self.unlocn_btn_type = client_constants["EVOLUTION_UNLOCK_TYPE"].use
                self.unlock_btn:getChildByName("title_0_0"):setString(lang_constants:Get("skin_unlock_use_text"))
            else
                self.unlock_btn:setVisible(false)
            end
            
        else
            self.role1:Init(self.role_sprite1, conf.sprite)
            self.role_sprite1:stopAction(self.walk_animate_forever)
            local conf = config_manager.mercenary_config[template_id]
            local sprite_frame_name = client_constants["MERCENARY_ROLE_IMG_PATH"] .. conf.sprite .. ".png"
            self.role_sprite1:setSpriteFrame(sprite_frame_name)
            self.role1:SetScale(4,4)
            --未获得
            self.role_name:setString(lang_constants:Get("evolution_havent"))
            self.role_name:setColor(panel_util:GetColor4B(0xffffff))

            --解锁按钮显示
            self.unlock_btn:setVisible(true)
            self.have_all_unlock = true
            self.unlocn_btn_type = client_constants["EVOLUTION_UNLOCK_TYPE"].unlock
            self.unlock_btn:getChildByName("title_0_0"):setString(lang_constants:Get("skin_unlock_unlock_text"))
        end
        if unlock_conf then
            self.unlock_desc_bg:setVisible(false) 
            -- print("解锁条件")

            local index = 0
            
            for k,v in pairs(unlock_conf.achievement_conf) do
                index = index + 1
                local achievement_name = constants["ACHIEVEMENT_TYPE_NAME"][k]
                local cur_value = achievement_logic:GetStatisticValue(k)
                if index == 1 then
                    self.condition_name1:setString("1. "..lang_constants:Get("achievement_"..achievement_name))
                    self.condition_num1:setString(cur_value.."/"..v)
                    if cur_value >= v then
                        self.condition_num1:setColor(panel_util:GetColor4B(0xBEF337))
                    else
                        self.have_all_unlock = false
                        self.unlock_btn:setColor(cc.c3b(125,125,125))
                        --不满足条件
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
                        self.have_all_unlock = false
                        self.unlock_btn:setColor(cc.c3b(125,125,125))
                        self.condition_num2:setColor(panel_util:GetColor4B(0xEB6A47))
                    end
                end
            end

            if index == 1 then
                self.condition_name2:setVisible(false)
                self.condition_num2:setVisible(false)
            end

            --删除之前所有的icon
            for k,cost_sub_panel in ipairs(self.cost_sub_panels) do
                cost_sub_panel.root_node:removeFromParent()
            end
            self.cost_sub_panels = {}
            local reward_num = 0
            local reward_config = {}
            for k,v in pairs(unlock_conf.cost_conf) do
                reward_num = reward_num + 1
                reward_config[constants["RESOURCE_TYPE_NAME"][k]] = v
            end
            for i = 1, reward_num do
                if self.cost_sub_panels[i] == nil then
                    local cost_sub_panel = icon_panel.New()
                    cost_sub_panel:Init(self.reward_bg)
                    self.cost_sub_panels[i] = cost_sub_panel
                end
            end

            panel_util:LoadCostResourceInfo(reward_config, self.cost_sub_panels, self.reward_bg:getContentSize().height*2/5, reward_num, self.reward_bg:getContentSize().width/2, false) 
        else
            self.unlock_desc_bg:setVisible(true)  
        end
    end
end


--Update定时器
function evolution_final_panel:Update(elapsed_time)
    if not self.stopAction then
        --解锁成功
        local now_opacity = self.role_sprite1:getOpacity() + self.add_step
        if now_opacity < 255 then
            self.role_sprite1:setOpacity(now_opacity)
        else
            self.stopAction = true
            if self.action_type == ACTION_TYPE.unlock then
                self.unlock_animation:setVisible(true)
                self.leader_unlock_timeline:gotoFrameAndPlay(0, 20, false)
                self:SelectTemplent(self.leader_templent_id, true)
            elseif self.action_type == ACTION_TYPE.use then
                self:SelectTemplent(self.leader_templent_id, true)
            end
            self.action_type = nil
        end
    end
end


function evolution_final_panel:RegisterEvent()

    --修改名字
    graphic:RegisterEvent("update_panel_leader_name", function()
        if not self.root_node:isVisible() then
            return
        end
        self.name_text:setString(troop_logic:GetLeaderName())
    end)

    graphic:RegisterEvent("unlock_ladder_success", function()
        if not self.root_node:isVisible() then
            return
        end
        self:UpdateUnlockState()
        self.stopAction = false
        self.add_step = 8
        self.action_type = ACTION_TYPE.unlock
        self.role_sprite1:setGLProgram(self.battle_shader)
        self.role_sprite1:setOpacity(0)
        self.role_sprite1:setColor(cc.c3b(255,255,255))
    end)
    
    --换装成功
    graphic:RegisterEvent("change_ladder_skin_success", function()
        if not self.root_node:isVisible() then
            return
        end
        self.action_type = ACTION_TYPE.use
        self.add_step = 16
        self.stopAction = false
        self.role_sprite1:setGLProgram(self.battle_shader)
        self.role_sprite1:setOpacity(0)
        self.role_sprite1:setColor(cc.c3b(255,255,255))

        self.use_animation:setVisible(true)
        self.leader_use_timeline:gotoFrameAndPlay(0, 36, false)
        self:UpdateUnlockState()
    end)
    
end

function evolution_final_panel:RegisterWidgetEvent()
    --关闭按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)

    self.change_name_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "rename_panel", client_constants["RENAME_PANEL_MODE"]["user"])
        end
    end)

    self.unlock_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.unlocn_btn_type == client_constants["EVOLUTION_UNLOCK_TYPE"].use then
                if troop_logic:UnLockSkin(self.leader_templent_id) and troop_logic:GetLeaderTempateId() ~= self.leader_templent_id then
                    troop_logic:UnLockOrUseSkin(self.leader_templent_id, self.unlocn_btn_type)
                end
            elseif self.unlocn_btn_type == client_constants["EVOLUTION_UNLOCK_TYPE"].unlock then
                if self.have_all_unlock then
                    troop_logic:UnLockOrUseSkin(self.leader_templent_id, self.unlocn_btn_type)
                else
                    graphic:DispatchEvent("show_prompt_panel", "evolution_unlock_no_condition")
                end
            end
        end
    end)
end

return evolution_final_panel

