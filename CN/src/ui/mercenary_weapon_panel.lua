local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local resource_logic = require "logic.resource"
local reminder_logic = require "logic.reminder"

local panel_prototype = require "ui.panel"
local icon_panel = require "ui.icon_panel"

local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local panel_util = require "ui.panel_util"
local spine_manager = require "util.spine_manager"
local platform_manager = require "logic.platform_manager"
local feature_config = require "logic.feature_config"

local PLIST_TYPE = ccui.TextureResType.plistType

local FORGE_WEAPON_ANIMATION_MAX_TIME = 100 -- 强化武器动画的最大时间

local WEAPON_COST_SUB_PANEL_POS_Y = 410  --觉醒消耗sub_panel 位置
local WEAPON_COST_SUB_PANEL_MAX_NUM = 5  --觉醒消耗资源类型个数

local ARTIFACT_COST_POS_Y_UP = 135  --觉醒消耗sub_panel 位置
local ARTIFACT_COST_POS_Y_BOTTOM = 45  --觉醒消耗sub_panel 位置
local ARTIFACT_COST_POS_Y_CENTER = 100  --觉醒消耗sub_panel 位置

local ARTIFACT_COST_SUB_PANEL_POS_Y = 320  --觉醒消耗sub_panel 位置
local ARTIFACT_COST_SUB_PANEL_POS_X = 312.00  --觉醒消耗sub_panel 位置

local CONFIRM_BTN_LEFT_POS_X = 187
local CONFIRM_BTN_CENTER_POS_X = 310

local ARTIFACT_COST_SUB_PANEL_MAX_NUM = 5  --觉醒消耗资源类型个数
local SPINE_NODE_ZORDER = 100

local ARTIFACT_PROPERTY_OFFSET_Y = 33 --宝具等级信息每个间距
local ARTIFACT_UPDATE_PANEL_CENTER_OFFSET_X = 125 --等级距离中间的位置

local ARTIFACT_INFO_TEXT_COLOR = cc.c3b(99, 89, 62)
local ARTIFACT_INFO_TEXT_MAX_COLOR = cc.c3b(255, 255, 255)

--[[
    complete == 可以升级
    update == 升级中
    runaction == 执行动画中
]]
local ARTIFACT_UPDATE_STATE = {
    ["complete"] = 1,
    ["update"] = 2,
    ["runaction"] = 3
}

local change_msgbox = panel_prototype:New()
function change_msgbox:Init(root_node)
    self.root_node = root_node

    self.close1_btn = root_node:getChildByName("close1_btn")
    self.close2_btn = root_node:getChildByName("close2_btn")
    self.confirm_btn = root_node:getChildByName("confirm_btn")

    self.root_node:setVisible(false)

    local hide = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            self.root_node:setVisible(false)
            local chance = weapon_sub_panel.total_chance
            if chance > 0 and chance <= 50 and _show_forge_notify then
                graphic:DispatchEvent("show_world_sub_panel", "notification_msgbox", 1)
            end
        end
    end

    self.close1_btn:addTouchEventListener(hide)
    self.close2_btn:addTouchEventListener(hide)
end

function change_msgbox:Show()
    self.root_node:setVisible(true)
end

--武器强化子panel
local weapon_sub_panel = panel_prototype.New()
function weapon_sub_panel:Init(root_node)
    self.root_node = root_node
    --info
    local weapon_info_node = root_node:getChildByName("info")
    weapon_info_node:setLocalZOrder(SPINE_NODE_ZORDER - 1 )

    self.quality_img = weapon_info_node:getChildByName("quality")
    self.role_img = self.quality_img:getChildByName("role_img")
    self.role_img:ignoreContentAdaptWithSize(true)
    self.role_img:setScale(2, 2)

    local zorder = SPINE_NODE_ZORDER + 1
    self.quality_img:setLocalZOrder(zorder)

    self.cur_level_text = weapon_info_node:getChildByName("weapon_level1")
    self.cur_level_text:setLocalZOrder(zorder)

    self.next_level_text = weapon_info_node:getChildByName("weapon_level2")
    self.next_level_text:setLocalZOrder(zorder)

    panel_util:SetTextOutline(self.next_level_text)
    self.cur_add_bp_text = weapon_info_node:getChildByName("bp_add1")
    self.cur_add_bp_text:setLocalZOrder(zorder)

    self.next_add_bp_text = weapon_info_node:getChildByName("bp_add2")
    self.next_add_bp_text:setLocalZOrder(zorder)

    panel_util:SetTextOutline(self.next_add_bp_text)

    self.arrow_img1 = weapon_info_node:getChildByName("change_icon1")
    self.arrow_img1:setLocalZOrder(zorder)

    self.arrow_img2 = weapon_info_node:getChildByName("change_icon2")
    self.arrow_img2:setLocalZOrder(zorder)

    weapon_info_node:getChildByName("weapon_level_icon"):setLocalZOrder(zorder)
    weapon_info_node:getChildByName("weapon_word"):setLocalZOrder(zorder)
    weapon_info_node:getChildByName("bp_word"):setLocalZOrder(zorder)

    --consume
    local consume_node = root_node:getChildByName("consume")
    self.blood_diamond_num_text = consume_node:getChildByName("blood_diamond_value")

    local consume0_node = root_node:getChildByName("consume_0")
    self.finish_forge_text = consume0_node:getChildByName("finish_forge")
    panel_util:SetTextOutline(self.finish_forge_text)

    local forge_bg_img = consume_node:getChildByName("add_success_rate")
    self.decrease_forge_success_btn = forge_bg_img:getChildByName("decrease_btn")
    self.increase_forge_success_btn = forge_bg_img:getChildByName("add_btn")
    self.max_forge_success_btn = forge_bg_img:getChildByName("max_btn")
    self.success_chance_text = forge_bg_img:getChildByName("total_success_rate")
    self.lucky_chance_text = forge_bg_img:getChildByName("desc_1")

    --COST
    self.cost_sub_panels = {}
    for i = 1, WEAPON_COST_SUB_PANEL_MAX_NUM do
        local cost_sub_panel = icon_panel.New()
        cost_sub_panel:Init(self.root_node)
        self.cost_sub_panels[i] = cost_sub_panel
    end

    --是否可以将武器锻造为宝具
    self.can_artifact_desc_text = root_node:getChildByName("can_artifact"):getChildByName("desc")
    self:RegisterEvent()
    self:RegisterWidgetEvent()

    --强化动画
    self.spine_node = spine_manager:GetNode("forge", 1.0, true)
    self.spine_node:setPosition(320, -13)
    self.spine_node:setLocalZOrder(SPINE_NODE_ZORDER)
    weapon_info_node:addChild(self.spine_node)

    self.spine_node:setVisible(false)
    self.spine_node:registerSpineEventHandler(function(event)
        self.show_forge_animation = false
        self.spine_node:setVisible(false)
        self.spine_node:setToSetupPose()

        self:UpdateCostResource()
        self:UpdateSuccessRate()
        graphic:DispatchEvent("update_mercenary_info", self.mercenary_id)
        graphic:DispatchEvent("update_battle_point", troop_logic:GetTroopBP())

    end, sp.EventType.ANIMATION_COMPLETE)
end

function weapon_sub_panel:Show(mercenary_id)
    self.root_node:setVisible(true)
    self.mercenary_id = mercenary_id
    local mercenary = troop_logic:GetMercenaryInfo(mercenary_id)

    self.role_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. mercenary.template_info.sprite .. ".png", PLIST_TYPE)
    self.quality_img:loadTexture(client_constants["MERCENARY_BG_SPRITE"][mercenary.template_info.quality], PLIST_TYPE)

    self.min_success_chance = 0
    self.extra_success_chance = 0

    --更新消耗资源
    self:UpdateCostResource()

    --更新成功率
    self:UpdateSuccessRate()

    self.show_forge_animation = false

end

function weapon_sub_panel:UpdateCostResource()
    local mercenary = troop_logic:GetMercenaryInfo(self.mercenary_id)
    local weapon_lv = mercenary.weapon_lv
    local template_info = mercenary.template_info

    if template_info.have_artifact then
        if mercenary.is_open_artifact then
            local str = string.format(lang_constants:Get("mercenary_already_open_artifact_prompt"), template_info["artifact_name"])
            self.can_artifact_desc_text:setString(str)
            panel_util:SetTextOutline(self.can_artifact_desc_text)

        else
            panel_util:disableEffect(self.can_artifact_desc_text)
            self.can_artifact_desc_text:setString(lang_constants:Get("mercenary_can_open_artifact_prompt"))
        end
    else
        panel_util:disableEffect(self.can_artifact_desc_text)
        self.can_artifact_desc_text:setString(lang_constants:Get("mercenary_cant_open_artifact_prompt"))
    end

    self.cur_level_text:setString(weapon_lv)
    local config = config_manager.weapon_forge_config[mercenary.weapon_lv + 1]
    self.cur_add_bp_text:setString(config.bp_factor .. "%")

    local weapon_lv_reach_max = (weapon_lv == constants["MAX_WEAPON_LV"])

    --根据是否满级设定状态
    self.next_level_text:setVisible(not weapon_lv_reach_max)
    self.next_add_bp_text:setVisible(not weapon_lv_reach_max)
    self.arrow_img1:setVisible(not weapon_lv_reach_max)
    self.arrow_img2:setVisible(not weapon_lv_reach_max)
    self.finish_forge_text:setVisible(weapon_lv_reach_max)
    self:SetCostResourceVisible(not weapon_lv_reach_max)

    self.weapon_lv_reach_max = weapon_lv_reach_max

    if weapon_lv_reach_max then
        self.min_success_chance = 0
        self.extra_success_chance = 0
        return
    end

    local next_weapon_lv = weapon_lv < constants["MAX_WEAPON_LV"] and (weapon_lv + 1) or constants["MAX_WEAPON_LV"]
    self.next_level_text:setString(next_weapon_lv)
    --add bp rate
    self.next_add_bp_text:setString(config_manager.weapon_forge_config[next_weapon_lv+1].bp_factor .. "%")

    panel_util:LoadCostResourceInfo(config, self.cost_sub_panels, WEAPON_COST_SUB_PANEL_POS_Y, WEAPON_COST_SUB_PANEL_MAX_NUM,nil,true) -- 资源跳转

    self.min_success_chance = config.success_chance
    if troop_logic.forge_info.mercenary_id == self.mercenary_id then
        self.min_success_chance = self.min_success_chance + troop_logic.forge_info.lucky_num
    end        

    self.extra_success_chance = 0
end

function weapon_sub_panel:UpdateSuccessRate()
    self.total_chance = self.min_success_chance + self.extra_success_chance

    local need_blood_diamond = 0
    if self.extra_success_chance > 0 then
        need_blood_diamond = config_manager.weapon_forge_extra_config[self.extra_success_chance].blood_diamond
    end

    if self.total_chance == 0 then
        self.success_chance_text:setString("--")
        self.blood_diamond_num_text:setString("--")
    else
        self.success_chance_text:setString(self.total_chance .. "%")
        self.blood_diamond_num_text:setString(need_blood_diamond)
        --r2修改
        if platform_manager:GetChannelInfo().weapon_panel_success_chance_text_add_air then
            self.success_chance_text:setString(" "..self.total_chance .. "%")
        end
    end

    local lucky_num = 0
    if troop_logic.forge_info.mercenary_id == self.mercenary_id then
        lucky_num = troop_logic.forge_info.lucky_num
    end

    self.lucky_chance_text:setString(string.format(lang_constants:Get("forge_weapon_lucky_num"), lucky_num))
end

function weapon_sub_panel:SetCostResourceVisible(is_visible)
    for i = 1, WEAPON_COST_SUB_PANEL_MAX_NUM do
        self.cost_sub_panels[i].root_node:setVisible(is_visible)
    end
end

function weapon_sub_panel:RegisterWidgetEvent()
    --降低强化成功率
    self.decrease_forge_success_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.show_forge_animation then
                return
            end
            
            if self.weapon_lv_reach_max then
                return
            end

            self.extra_success_chance = self.total_chance > self.min_success_chance and (self.extra_success_chance - 1) or 0
            self:UpdateSuccessRate()
        end
    end)

    --增加
    self.increase_forge_success_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.show_forge_animation then
                return
            end

            if self.weapon_lv_reach_max then
                return
            end

            self.extra_success_chance = self.total_chance < 100 and (self.extra_success_chance + 1) or self.extra_success_chance
            self:UpdateSuccessRate()
        end
    end)

    --强化成功率直接增加到100
    self.max_forge_success_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.show_forge_animation then
                return
            end

            if self.weapon_lv_reach_max then
                return
            end

            self.extra_success_chance = 100 - self.min_success_chance
            self:UpdateSuccessRate()
        end
    end)

end

function weapon_sub_panel:RegisterEvent()
    graphic:RegisterEvent("update_resource_list", function()
        if not self.root_node:isVisible() then
            return
        end
        self:RefreshResource()
    end)
end

function weapon_sub_panel:RefreshResource()
    if self.cost_sub_panels then
        for k,v in pairs(self.cost_sub_panels) do
            local resourceType = v:GetIconResourceType()
            if resource_logic:IsResourceUpdated(resourceType) then
                v:SetTextStatus(resourceType)
            end
        end
    end
end

--宝具升级界面
local artifact_update_info_panel = panel_prototype.New(true)

function artifact_update_info_panel:Init(root_node)
    self.root_node = root_node
    --总属性加成
    self.info_level_property_label = self.root_node:getChildByName("lv_1_0_0_8_2_0"):getChildByName("value")

    self.mercenary_id = nil
end

function artifact_update_info_panel:Show(mercenary_id)
    if self.root_node then
        self.root_node:setVisible(true)
        if self.mercenary_id ~= mercenary_id then
            self.mercenary_id = mercenary_id
            local mercenary = troop_logic:GetMercenaryInfo(self.mercenary_id)
            local artifact_config = config_manager.mercenary_artifact_config[mercenary.template_id]

            --总属性加成
            local max_conf = artifact_config[#artifact_config]
            local str = ""
            local property_index = 0
            if max_conf.sum_speed > 0 then
                property_index = property_index + 1
                str = str .. lang_constants:Get("mercenary_property1") .. "+" .. max_conf.sum_speed
            end

            if max_conf.sum_defense > 0 then
                if property_index >= 1 then
                    str = str .. ","
                end
                property_index = property_index + 1
                str = str .. lang_constants:Get("mercenary_property2") .. "+" .. max_conf.sum_defense
            end

            if max_conf.sum_dodge > 0 then
                if property_index >= 1 then
                    str = str .. ","
                end
                property_index = property_index + 1
                str = str .. lang_constants:Get("mercenary_property3") .. "+" .. max_conf.sum_dodge
            end

            if max_conf.sum_authority > 0 then
                if property_index == 3 then
                    str = str.."\n"
                    property_index = 0
                elseif property_index >= 1 then
                    str = str .. ","
                end
                property_index = property_index + 1
                str = str .. lang_constants:Get("mercenary_property4") .. "+" .. max_conf.sum_authority
            end

            if max_conf.sum_bp > 0 then
                if property_index >= 2 then
                    str = str.."\n"
                    property_index = 0
                elseif property_index >= 1 then
                    str = str .. ","
                end
                str = str .. lang_constants:Get("mercenary_property5") .. "+" .. max_conf.sum_bp.."%"
            end
            self.info_level_property_label:setString(str)
        end
    end
end

--宝具升级界面
local artifact_update_panel = panel_prototype.New(true)

function artifact_update_panel:Init(root_node)
    self.root_node = root_node
    --宝具升级控件
    --升级前
    local update_before_node = self.root_node:getChildByName("attribute")
    --先攻属性label
    self.speed_value_text = update_before_node:getChildByName("speed_value")
    self.speed_add_value_text = update_before_node:getChildByName("speed_value_0")
    panel_util:SetTextOutline(self.speed_add_value_text)
    --防御属性label
    self.defense_value_text = update_before_node:getChildByName("defense_value")
    self.defense_add_value_text = update_before_node:getChildByName("speed_value_0_0")
    panel_util:SetTextOutline(self.defense_add_value_text)
    --闪避属性label
    self.dodge_value_text = update_before_node:getChildByName("dodge_value")
    self.dodge_add_value_text = update_before_node:getChildByName("speed_value_0_0_0")
    panel_util:SetTextOutline(self.dodge_add_value_text)
    --王者属性label
    self.authority_value_text = update_before_node:getChildByName("authority_value")
    self.authority_add_value_text = update_before_node:getChildByName("speed_value_0_0_0_1")
    panel_util:SetTextOutline(self.authority_add_value_text)
    --战力百分比label
    self.battle_value_text = update_before_node:getChildByName("speed_value_0_0_0_0")
    self.battle_add_value_text = update_before_node:getChildByName("speed_value_0_0_0_1_0")
    panel_util:SetTextOutline(self.battle_add_value_text)
    
    --箭头
    self.speed_value_arrow = update_before_node:getChildByName("arrow")
    self.defense_value_arrow = update_before_node:getChildByName("arrow_0")
    self.dodge_value_arrow = update_before_node:getChildByName("arrow_0_0")
    self.authority_value_arrow = update_before_node:getChildByName("arrow_0_0_0")
    self.battle_value_arrow = update_before_node:getChildByName("arrow_0_0_0_0")

    --当前等级label 
    self.now_level_info_text = self.root_node:getChildByName("Text_235")
    panel_util:SetTextOutline(self.now_level_info_text)
    --宝具名字label 
    self.artifact_name_text = self.root_node:getChildByName("name_title")
    --升级按钮
    self.update_btn = self.root_node:getChildByName("level_up_btn")
    --宝具icon
    self.artifact_icon = self.root_node:getChildByName("quality"):getChildByName("role_img")
    --最高级提示文字
    self.max_tips_label = self.root_node:getChildByName("prompt_0")
    self.max_tips_label:setVisible(false)

    --升级动画
    self.spine_node = spine_manager:GetNode("fuwen", 1.0, true)
    self.spine_node:setScale(2)
    self.spine_node:setPosition(cc.p(self.root_node:getChildByName("quality"):getPositionX(), self.root_node:getChildByName("quality"):getPositionY()))
    self.root_node:addChild(self.spine_node)
    self.spine_node:setTimeScale(1.0)

    self.update_state = ARTIFACT_UPDATE_STATE["complete"]
    self.cost_sub_panels = {}

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end 

function artifact_update_panel:Show(mercenary_id)
    if self.root_node then
        self.root_node:setVisible(true)
        self.mercenary_id = mercenary_id

        self.update_state = ARTIFACT_UPDATE_STATE["complete"] --升级状态

        self:LoadArtifactUpdateInfo()  --加载宝具等级信息
    end
end

--执行升级动画
function artifact_update_panel:RunUpdateAnimation()
    if self.spine_node then
        self.update_state = ARTIFACT_UPDATE_STATE["runaction"]
        self.spine_node:setVisible(true)
        self.spine_node:setAnimation(0, "upgrade", false)
    end
end

--加载宝具升级信息
function artifact_update_panel:LoadArtifactUpdateInfo()

    local mercenary = troop_logic:GetMercenaryInfo(self.mercenary_id)
    local template_info = mercenary.template_info

    local cost_config = {}
    local cost_num = 0
    self.artifact_level = mercenary.artifact_lv or 1

    local artifact_config = config_manager.mercenary_artifact_config[mercenary.template_id]
   
    self.max_level = #artifact_config  --最大级是

    --当等级超过当前等级最大等级是用最大等级
    if self.artifact_level >= self.max_level then
       self.artifact_level = self.max_level
       self.update_btn:setTitleText(lang_constants:Get("mercenary_artifact_maxgrade_btn_title")) --满级
       self.update_btn:setColor(panel_util:GetColor4B(client_constants["DARK_BLEND_COLOR"]))
       self.update_btn:setTouchEnabled(false)
    else
        self.update_btn:setTitleText(lang_constants:Get("mercenary_artifact_update_btn_title"))
        self.update_btn:setColor(panel_util:GetColor4B(client_constants["LIGHT_BLEND_COLOR"]))
        self.update_btn:setTouchEnabled(true)
    end

    if artifact_config and artifact_config[self.artifact_level] then
        local config = artifact_config[self.artifact_level]
        local next_config = artifact_config[self.artifact_level+1]
        local forever_fade_in_out = cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(0.5), cc.FadeIn:create(0.5), cc.DelayTime:create(1), cc.FadeOut:create(0.5), cc.DelayTime:create(0.5)))

        --当前等级
        --先攻属性label
        self.speed_value_text:setString(template_info["artifact_speed"] + config.sum_speed)
        self.speed_add_value_text:stopAllActions()
        self.speed_value_arrow:stopAllActions()
        if next_config and next_config.speed > 0 then
            
            self.speed_add_value_text:setVisible(true)
            self.speed_add_value_text:setString(template_info["artifact_speed"] + next_config.sum_speed)
            self.speed_add_value_text:runAction(forever_fade_in_out:clone())
            self.speed_value_arrow:setVisible(true)
            self.speed_value_arrow:runAction(forever_fade_in_out:clone())
        else
            self.speed_add_value_text:setVisible(false)
            self.speed_value_arrow:setVisible(false)
            self.speed_add_value_text:setString("")
            
        end
        --最大级
        if next_config then
            self.speed_value_text:setColor(ARTIFACT_INFO_TEXT_COLOR)
            panel_util:disableEffect(self.speed_value_text)
        else
            self.speed_value_text:setColor(ARTIFACT_INFO_TEXT_MAX_COLOR)
            panel_util:SetTextOutline(self.speed_value_text)
        end
        --防御属性label
        self.defense_value_text:setString(template_info["artifact_defense"] + config.sum_defense)
        self.defense_add_value_text:stopAllActions()
        self.defense_value_arrow:stopAllActions()
        if next_config and next_config.defense > 0 then
            self.defense_add_value_text:setVisible(true)
            self.defense_add_value_text:setString(template_info["artifact_defense"] + next_config.sum_defense)
            self.defense_add_value_text:runAction(forever_fade_in_out:clone())
            self.defense_value_arrow:setVisible(true)
            self.defense_value_arrow:runAction(forever_fade_in_out:clone())
        else
            self.defense_add_value_text:setVisible(false)
            self.defense_value_arrow:setVisible(false)
        end
        --最大级
        if next_config then
            self.defense_value_text:setColor(ARTIFACT_INFO_TEXT_COLOR)
            panel_util:disableEffect(self.defense_value_text)
        else
            self.defense_value_text:setColor(ARTIFACT_INFO_TEXT_MAX_COLOR)
            panel_util:SetTextOutline(self.defense_value_text)
        end

        --闪避属性label
        self.dodge_value_text:setString(template_info["artifact_dodge"] + config.sum_dodge)
        self.dodge_add_value_text:stopAllActions()
        self.dodge_value_arrow:stopAllActions()
        if next_config and next_config.dodge > 0 then
            self.dodge_add_value_text:setVisible(true)
            self.dodge_add_value_text:setString(template_info["artifact_dodge"] + next_config.sum_dodge)
            self.dodge_add_value_text:runAction(forever_fade_in_out:clone())
            self.dodge_value_arrow:setVisible(true)
            self.dodge_value_arrow:runAction(forever_fade_in_out:clone())
        else
            self.dodge_add_value_text:setVisible(false)
            self.dodge_value_arrow:setVisible(false)
        end
        --最大级
        if next_config then
            self.dodge_value_text:setColor(ARTIFACT_INFO_TEXT_COLOR)
            panel_util:disableEffect(self.dodge_value_text)
        else
            self.dodge_value_text:setColor(ARTIFACT_INFO_TEXT_MAX_COLOR)
            panel_util:SetTextOutline(self.dodge_value_text)
        end

        --王者属性label
        self.authority_value_text:setString(template_info["artifact_authority"] + config.sum_authority)
        self.authority_add_value_text:stopAllActions()
        self.authority_value_arrow:stopAllActions()
        if next_config and next_config.authority > 0 then
            self.authority_add_value_text:setVisible(true)
            self.authority_add_value_text:setString(template_info["artifact_authority"] + next_config.sum_authority)
            self.authority_add_value_text:runAction(forever_fade_in_out:clone())
            self.authority_value_arrow:setVisible(true)
            self.authority_value_arrow:runAction(forever_fade_in_out:clone())
        else
            self.authority_add_value_text:setVisible(false)
            self.authority_value_arrow:setVisible(false)
            
        end
        --最大级
        if next_config then
            self.authority_value_text:setColor(ARTIFACT_INFO_TEXT_COLOR)
            panel_util:disableEffect(self.authority_value_text)
        else
            self.authority_value_text:setColor(ARTIFACT_INFO_TEXT_MAX_COLOR)
            panel_util:SetTextOutline(self.authority_value_text)
        end

        self.battle_value_text:setString(config.sum_bp.."%")
        self.battle_add_value_text:stopAllActions()
        self.battle_value_arrow:stopAllActions()
        if next_config and next_config.bp > 0 then
            self.battle_add_value_text:setVisible(true)
            self.battle_add_value_text:setString(next_config.sum_bp.."%")
            self.battle_add_value_text:runAction(forever_fade_in_out:clone())
            self.battle_value_arrow:setVisible(true)
            self.battle_value_arrow:runAction(forever_fade_in_out:clone())
        else
            self.battle_value_arrow:setVisible(false)
            self.battle_add_value_text:setVisible(false)
        end
        --最大级
        if next_config then
            self.battle_value_text:setColor(ARTIFACT_INFO_TEXT_COLOR)
            panel_util:disableEffect(self.battle_value_text)
        else
            self.battle_value_text:setColor(ARTIFACT_INFO_TEXT_MAX_COLOR)
            panel_util:SetTextOutline(self.battle_value_text)
        end

        --消耗资源
        local cost_list = config.cost_list
        if cost_list then 
            for _type,_num in pairs(cost_list) do
                cost_num = cost_num + 1
                cost_config[constants["RESOURCE_TYPE_NAME"][_type]] = _num
            end
        end
    end

    --等级
    self.now_level_info_text:setString(string.format(lang_constants:Get("mercenary_artifact_level"),mercenary.artifact_lv))
    --名字
    self.artifact_name_text:setString(template_info["artifact_name"])
    --宝具icon
    self.artifact_icon:loadTexture(client_constants["ARTIFACT_ICON_PATH"] .. template_info["artifact_icon"], PLIST_TYPE)

    --加载消耗资源
    for k,cost_sub_panel in ipairs(self.cost_sub_panels) do
        cost_sub_panel.root_node:removeFromParent()
    end
    self.cost_sub_panels = {}
    if self.artifact_level >= self.max_level then
        --显示最大值得label提示
        self.max_tips_label:setString(lang_constants:Get("artifact_update_max_tips"))
        self.max_tips_label:setVisible(true)
    else
        self.max_tips_label:setVisible(false)
        for i = 1, cost_num do
            local cost_sub_panel = icon_panel.New()
            cost_sub_panel:Init(self.root_node)
            self.cost_sub_panels[i] = cost_sub_panel
        end

        panel_util:LoadCostResourceInfo(cost_config, self.cost_sub_panels, ARTIFACT_COST_SUB_PANEL_POS_Y, cost_num, ARTIFACT_COST_SUB_PANEL_POS_X) 
    end

end

function artifact_update_panel:RegisterWidgetEvent()
    self.update_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.update_state == ARTIFACT_UPDATE_STATE["complete"] then
                if self.artifact_level < constants["MAX_ARTIFACT_LEVEL"] then
                    local state = troop_logic:UpdateArtifact(self.mercenary_id, "update")
                    if state then
                        self.update_state = ARTIFACT_UPDATE_STATE["update"]
                    end
                else
                    graphic:DispatchEvent("show_prompt_panel", "mercenary_artifact_upgrade_max")
                end
            end
        end
    end)

    self.spine_node:registerSpineEventHandler(function(event)
        -- self.show_forge_animation = false
        local animation_name = event.animation
        if animation_name == "upgrade" then
            self.spine_node:setVisible(false)
            self.update_state = ARTIFACT_UPDATE_STATE["complete"]
            graphic:DispatchEvent("show_prompt_panel", "mercenary_artifact_upgrade_success") --宝具升级成功
        end
    end, sp.EventType.ANIMATION_COMPLETE)
end

function artifact_update_panel:RegisterEvent()
    graphic:RegisterEvent("update_resource_list", function()
        if not self.root_node:isVisible() then
            return
        end
        self:RefreshResource()
    end)
end

function artifact_update_panel:RefreshResource()
    if self.cost_sub_panels then
        for k,v in pairs(self.cost_sub_panels) do
            local resourceType = v:GetIconResourceType()
            if resource_logic:IsResourceUpdated(resourceType) then
                v:SetTextStatus(resourceType)
            end
        end
    end
end

local artifact_sub_panel = panel_prototype.New(true)
--param:
--[[
    root_node --- >锻造宝具界面节点
]]
function artifact_sub_panel:Init(root_node)
    self.root_node = root_node

    --info
    local artifact_info_node = root_node:getChildByName("info")
    self.name_text = artifact_info_node:getChildByName("name_bg"):getChildByName("name")
    --panel_util:SetTextOutline(self.name_text)

    self.quality_img = artifact_info_node:getChildByName("quality")
    self.artifact_icon = self.quality_img:getChildByName("role_img")

    --info attribute
    local attribute_node = artifact_info_node:getChildByName("attribute")
    self.speed_text = attribute_node:getChildByName("speed_value")
    self.defense_text = attribute_node:getChildByName("defense_value")
    self.dodge_text = attribute_node:getChildByName("dodge_value")
    self.authority_text = attribute_node:getChildByName("authority_value")

    --propmt
    self.propmt_text = root_node:getChildByName("prompt")
    panel_util:SetTextOutline(self.propmt_text)

    --conusme
    self.consume_node = root_node:getChildByName("consume")
    self.cost_sub_panels = {}
    for i = 1, ARTIFACT_COST_SUB_PANEL_MAX_NUM do
        local cost_sub_panel = icon_panel.New()
        cost_sub_panel:Init(self.consume_node)
        self.cost_sub_panels[i] = cost_sub_panel
    end

    if feature_config:IsFeatureOpen("forge_ticket") then
        self.consume_node2 = root_node:getChildByName("consume_0")
        self.cost_sub_panels2 = {}
        local cost_sub_panel = icon_panel.New()
        cost_sub_panel:Init(self.consume_node2)
        self.cost_sub_panels2[1] = cost_sub_panel
    end

    self.root_node:setVisible(false)
    self:RegisterEvent()
end

--retrun 是用来判断是否有升级界面如果有要隐藏锻造按钮
function artifact_sub_panel:Show(mercenary_id)
    self.root_node:setVisible(true)
    self.mercenary_id = mercenary_id

    if self.consume_node2 then
        local cost_line_up = {
            self.cost_sub_panels[1],
            self.cost_sub_panels[2],
        }
        
        local cost_conf_list_up = {
            ["gold_coin"] = constants["OPEN_ARTIFACT_CONSUME_RESOURCE_1"]["gold_coin"],
            ["red_soul_crystal"] = constants["OPEN_ARTIFACT_CONSUME_RESOURCE_1"]["red_soul_crystal"],
        }
        panel_util:LoadCostResourceInfo(cost_conf_list_up, cost_line_up, ARTIFACT_COST_POS_Y_UP, #cost_line_up, self.consume_node:getContentSize().width / 2, true)

        local cost_line_down = {
            self.cost_sub_panels[3],
            self.cost_sub_panels[4],
            self.cost_sub_panels[5],
        }
        local cost_conf_list_down = {
            ["green_soul_crystal"] = constants["OPEN_ARTIFACT_CONSUME_RESOURCE_1"]["green_soul_crystal"],
            ["light_soul_crystal"] = constants["OPEN_ARTIFACT_CONSUME_RESOURCE_1"]["light_soul_crystal"],
            ["dark_soul_crystal"] = constants["OPEN_ARTIFACT_CONSUME_RESOURCE_1"]["dark_soul_crystal"],
        }
        panel_util:LoadCostResourceInfo(cost_conf_list_down, cost_line_down, ARTIFACT_COST_POS_Y_BOTTOM, #cost_line_down, self.consume_node:getContentSize().width / 2, true)
    
        panel_util:LoadCostResourceInfo(constants["OPEN_ARTIFACT_CONSUME_RESOURCE_2"], self.cost_sub_panels2, ARTIFACT_COST_POS_Y_CENTER, #self.cost_sub_panels2, self.consume_node2:getContentSize().width / 2, true)
    else
        panel_util:LoadCostResourceInfo(constants["OPEN_ARTIFACT_CONSUME_RESOURCE_1"], self.cost_sub_panels, ARTIFACT_COST_POS_Y_BOTTOM, #self.cost_sub_panels, self.consume_node:getContentSize().width / 2, true)
    end

    local mercenary = troop_logic:GetMercenaryInfo(mercenary_id)
    local template_info = mercenary.template_info
    self.speed_text:setString(template_info["artifact_speed"])
    self.defense_text:setString(template_info["artifact_defense"])
    self.dodge_text:setString(template_info["artifact_dodge"])
    self.authority_text:setString(template_info["artifact_authority"])

    if template_info["have_artifact"] then
        self.name_text:setString(template_info["artifact_name"])
        self.artifact_icon:loadTexture(client_constants["ARTIFACT_ICON_PATH"] .. template_info["artifact_icon"], PLIST_TYPE)
    end
    
    --宝具升级界面显示判断
    if troop_logic:IsArtifactUpgrade(self.mercenary_id)  then
        self.root_node:setVisible(false)
        artifact_update_panel:Show(self.mercenary_id)
        return true
    else
        artifact_update_panel:Hide()
    end

    self.propmt_text:setVisible(mercenary.is_open_artifact)
    self.consume_node:setVisible(not mercenary.is_open_artifact)
    self:SetCostResourceVisible(not mercenary.is_open_artifact)

    if self.consume_node2 then
        self.consume_node2:setVisible(not mercenary.is_open_artifact)
    end

    --锻造完毕如果没有可以锻造升级的时候提示
    if not mercenary.template_info.have_artifact_upgrade then
        local tip_str = lang_constants:Get("mercenary_no_artifact_update_tips")
        if feature_config:IsFeatureOpen("artifact_upgrade") then
            tip_str = tip_str .. lang_constants:Get("mercenary_no_artifact_update_tips2")
        end
        self.propmt_text:setString(tip_str)
    end

    return false 
end

function artifact_sub_panel:Hide()
    self.root_node:setVisible(false)
    artifact_update_panel:Hide()
end

function artifact_sub_panel:SetCostResourceVisible(is_visible)
    for i = 1, ARTIFACT_COST_SUB_PANEL_MAX_NUM do
        self.cost_sub_panels[i].root_node:setVisible(is_visible)
    end
end

function artifact_sub_panel:RegisterEvent()
    graphic:RegisterEvent("update_resource_list", function()
        if not self.root_node:isVisible() then
            return
        end
        self:RefreshResource()
    end)
end

function artifact_sub_panel:RefreshResource()
    if self.cost_sub_panels then
        for k,v in pairs(self.cost_sub_panels) do
            local resourceType = v:GetIconResourceType()
            if resource_logic:IsResourceUpdated(resourceType) then
                v:SetTextStatus(resourceType)
            end
        end
    end
    if self.cost_sub_panels2 then
        for k,v in pairs(self.cost_sub_panels2) do
            local resourceType = v:GetIconResourceType()
            if resource_logic:IsResourceUpdated(resourceType) then
                v:SetTextStatus(resourceType)
            end
        end
    end
end

local mercenary_weapon_panel = panel_prototype.New(true)
function mercenary_weapon_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/weapon_panel.csb")
    self.panel_root_node = self.root_node:getChildByName("Node_20") or self.root_node
    --weapon
    self.weapon_tab_img = self.panel_root_node:getChildByName("weapon_tab")
    self.weapon_tab_img:setTouchEnabled(true)
    self.weapon_node = self.panel_root_node:getChildByName("weapon")
    weapon_sub_panel:Init(self.weapon_node)

    ---artifact
    self.artifact_tab_img = self.panel_root_node:getChildByName("artifact_tab")
    self.artifact_tab_img:setTouchEnabled(true)


    self.artifact_title_text = self.artifact_tab_img:getChildByName("desc")

    self.artifact_rule_btn = self.panel_root_node:getChildByName("rule_btn")
    self.artifact_node1 = self.panel_root_node:getChildByName("artifact_0")
    self.level_info_node = self.panel_root_node:getChildByName("level_info") --升级信息节点

    if feature_config:IsFeatureOpen("artifact_upgrade") then
        if self.level_info_node then
            artifact_update_info_panel:Init(self.level_info_node)
            artifact_update_info_panel:Hide()
        end
        if self.artifact_node1 then
            artifact_update_panel:Init(self.artifact_node1)
        end
    else
        if self.artifact_rule_btn then
            self.artifact_rule_btn:setVisible(false)
        end
        if self.level_info_node then
            self.level_info_node:setVisible(false)
        end
        if self.artifact_node1 then
            self.artifact_node1:setVisible(false)
        end
    end

    self.artifact_node = self.panel_root_node:getChildByName("artifact")
    artifact_sub_panel:Init(self.artifact_node)

    self.confirm_btn = self.panel_root_node:getChildByName("confirm_btn")
    self.cancel_btn = self.panel_root_node:getChildByName("cancel_btn")

    self.confirm_btn2 = self.panel_root_node:getChildByName("confirm_btn_0")
    if feature_config:IsFeatureOpen("forge_ticket") then
        self.confirm_btn:setPositionY(self.confirm_btn2:getPositionY())  --位置对齐
    else
        if self.confirm_btn2 then
            self.confirm_btn2:setVisible(false)
        end
    end

    local change_msgbox_node = self.panel_root_node:getChildByName("change_msgbox")
    change_msgbox:Init(change_msgbox_node)

    self.change_msgbox_desc_text = change_msgbox_node:getChildByName("desc")

    local bg_img = self.panel_root_node:getChildByName("bg")
    
    --宝具升级时动画
    self.spine_node = spine_manager:GetNode("change_frame", 1.0, true)
    self.spine_node:setScale(2)
    self.spine_node:setPosition(cc.p(bg_img:getPositionX(),bg_img:getPositionY() - bg_img:getContentSize().height/2))
    self.spine_node:setLocalZOrder(SPINE_NODE_ZORDER)
    self.spine_node:setVisible(false)
    self.root_node:addChild(self.spine_node)

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

--默认显示weapon_sub_panel
function mercenary_weapon_panel:Show(mercenary_id, show_artifact_sub_panel)
    self.mercenary_id = mercenary_id

    self:HasArtifact()

    if show_artifact_sub_panel then
        weapon_sub_panel:Hide()
        artifact_sub_panel:Show(self.mercenary_id)
        self:UpdateTabStatus(false)

    else
        weapon_sub_panel:Show(self.mercenary_id)
        artifact_sub_panel:Hide()
        self:UpdateTabStatus(true)
    end

    self.artifact_node:setOpacity(255)
    self.confirm_btn:setOpacity(255)

    if feature_config:IsFeatureOpen("forge_ticket") then
        self.confirm_btn2:setOpacity(255)
    end
    self:ShowArtifactTab()
    self.root_node:setVisible(true)
    self.panel_root_node:setVisible(true)
end

function mercenary_weapon_panel:ShowArtifactTab()
    if troop_logic:IsArtifactUpgrade(self.mercenary_id) then
        --宝具升级界面
        self.artifact_title_text:setString(lang_constants:Get("mercenary_artifact_title2"))
    else
        --锻造宝具界面
        self.artifact_title_text:setString(lang_constants:Get("mercenary_artifact_title1"))
    end
end

function mercenary_weapon_panel:HasArtifact()
    local mercenary = troop_logic:GetMercenaryInfo(self.mercenary_id)
    if mercenary.template_info.have_artifact then
        self.weapon_tab_img:setPositionX(210)
        self.artifact_tab_img:setVisible(true)
    else
        self.weapon_tab_img:setPositionX(320)
        self.artifact_tab_img:setVisible(false)
    end
end

--更新tab 状态
function mercenary_weapon_panel:UpdateTabStatus(show_weapon_sub_panel)
    if self.artifact_rule_btn then
        self.artifact_rule_btn:setVisible(false)
    end
    local mercenary = troop_logic:GetMercenaryInfo(self.mercenary_id)
    if show_weapon_sub_panel then
        self.weapon_tab_img:setColor(panel_util:GetColor4B(client_constants["LIGHT_BLEND_COLOR"]))
        self.artifact_tab_img:setColor(panel_util:GetColor4B(client_constants["DARK_BLEND_COLOR"]))
        artifact_sub_panel:Hide()
        weapon_sub_panel:Show(self.mercenary_id)
        self.confirm_btn:setVisible(true)
        self.confirm_btn:setTitleText(lang_constants:Get("mercenary_confirm_forge_btn"))
        self.confirm_btn:setPositionX(310)
        if feature_config:IsFeatureOpen("forge_ticket") and self.confirm_btn2 then
            self.confirm_btn2:setVisible(false)
        end
    else
        self.weapon_tab_img:setColor(panel_util:GetColor4B(client_constants["DARK_BLEND_COLOR"]))
        self.artifact_tab_img:setColor(panel_util:GetColor4B(client_constants["LIGHT_BLEND_COLOR"]))
        weapon_sub_panel:Hide()
        local show_update_state = artifact_sub_panel:Show(self.mercenary_id)

        if mercenary.is_open_artifact then
            self.confirm_btn:setTitleText(lang_constants:Get("mercenary_finish_artifact_btn"))
            if feature_config:IsFeatureOpen("forge_ticket") and self.confirm_btn2 then
                self.confirm_btn2:setTitleText(lang_constants:Get("mercenary_finish_artifact_btn"))
                self.confirm_btn:setPositionX(CONFIRM_BTN_CENTER_POS_X)
                self.confirm_btn2:setVisible(false)
            end

            self.confirm_btn:setVisible(not show_update_state)
            
            if self.artifact_rule_btn then
                self.artifact_rule_btn:setVisible(show_update_state)
            end
        else
            self.confirm_btn:setTitleText(lang_constants:Get("mercenary_confirm_artifact_btn"))
            if feature_config:IsFeatureOpen("forge_ticket") and self.confirm_btn2 then
                self.confirm_btn2:setTitleText(lang_constants:Get("mercenary_confirm_artifact_btn2"))
                self.confirm_btn:setPositionX(CONFIRM_BTN_LEFT_POS_X)
                self.confirm_btn:setVisible(true)
                self.confirm_btn2:setVisible(true)
            end
        end
    end
end

function mercenary_weapon_panel:OpenArtifactSuccess()
    self.artifact_node:setOpacity(255)
    self.confirm_btn:setOpacity(255)
    artifact_sub_panel.propmt_text:setVisible(true)
    artifact_sub_panel.consume_node:setVisible(false)
    self.confirm_btn:setTitleText(lang_constants:Get("mercenary_finish_artifact_btn"))
    if artifact_sub_panel.consume_node2 then
        artifact_sub_panel.consume_node2:setVisible(false)
    end
    if feature_config:IsFeatureOpen("forge_ticket") and self.confirm_btn2 then
        self.confirm_btn2:setTitleText(lang_constants:Get("mercenary_finish_artifact_btn"))
        self.confirm_btn:setPositionX(CONFIRM_BTN_CENTER_POS_X)
        self.confirm_btn2:setVisible(false)
        self.confirm_btn2:setOpacity(255)
    end
    self.confirm_btn:setVisible(false)
    artifact_sub_panel:SetCostResourceVisible(false)
    artifact_sub_panel:Show(self.mercenary_id)
    self:UpdateTabStatus(false)
    self:ShowArtifactTab()
end

function mercenary_weapon_panel:RegisterWidgetEvent()
    local do_forge = function()
        if weapon_sub_panel.show_forge_animation then
            return
        end

        if weapon_sub_panel.weapon_lv_reach_max then
            return
        end

        --检查血钻 
        local extra_chance = weapon_sub_panel.extra_success_chance
        local cost_blood_diamand = troop_logic:GetForgeWeaponBloodDiamond(extra_chance)

        if cost_blood_diamand < 0 or not panel_util:CheckBloodDiamond(cost_blood_diamand) then
            return
        end
        troop_logic.is_open = true  -- 资源跳转
        troop_logic:ForgeWeapon(self.mercenary_id, extra_chance)
    end

    local do_forge_notify = function()
        --强化武器
        local chance = weapon_sub_panel.total_chance
        if chance > 0 and chance <= 50 and reminder_logic:IsShowForgeNotify() then
            graphic:DispatchEvent("show_world_sub_panel", "notification_msgbox", 1, function() do_forge() end)
          else
            do_forge()
        end
        change_msgbox.root_node:setVisible(false)  
    end

    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if weapon_sub_panel.root_node:isVisible() then
                --强化武器
                local mercenary_id = troop_logic.forge_info.mercenary_id
                local lucky_num = troop_logic.forge_info.lucky_num

                if lucky_num ~= 0 and mercenary_id ~= 0 and mercenary_id ~= self.mercenary_id then
                    local mercenary = troop_logic:GetMercenaryInfo(mercenary_id)

                    if mercenary then
                        local desc_text = string.format(lang_constants:Get("clear_forge_lucky_num_prompt"), mercenary.template_info.name, lucky_num)
                        self.change_msgbox_desc_text:setString(desc_text)
                        change_msgbox:Show()
                        return
                    end
                    local chance = weapon_sub_panel.total_chance
                    --强化概率小于50 显示提示
                    if chance > 0 and chance <= 50 and _show_forge_notify then
                        graphic:DispatchEvent("show_world_sub_panel", "notification_msgbox", 1)
                    else
                        do_forge()
                    end
                end
                do_forge_notify()

            elseif artifact_sub_panel.root_node:isVisible() then
                --锻造宝具
                if artifact_sub_panel.is_open_artifact then
                    return
                end
                troop_logic:UpdateArtifact(self.mercenary_id, "normal")
            end
        end
    end)
    
    if feature_config:IsFeatureOpen("forge_ticket") and self.confirm_btn2 then
        self.confirm_btn2:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")

                if artifact_sub_panel.root_node:isVisible() then
                    --锻造宝具
                    if artifact_sub_panel.is_open_artifact then
                        return
                    end

                    troop_logic:UpdateArtifact(self.mercenary_id, "ticket")
                end
            end
        end)
    end

    self.cancel_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if weapon_sub_panel.show_forge_animation then
                return
            end
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)

    self.artifact_tab_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then

            if weapon_sub_panel.show_forge_animation then
                return
            end
            audio_manager:PlayEffect("click")

           self:UpdateTabStatus(false)
        end
    end)

    self.weapon_tab_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:UpdateTabStatus(true)
        end
    end)

    if feature_config:IsFeatureOpen("artifact_upgrade") then
        self.artifact_rule_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.began then
                artifact_update_info_panel:Show(self.mercenary_id)
            elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
                audio_manager:PlayEffect("click")
                artifact_update_info_panel:Hide()
            end
        end)
    end

    change_msgbox.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            do_forge_notify()
        end
    end)

    --动画监听事件
    self.spine_node:registerSpineEventHandler(function (event)
        if event.eventData.name == "change_out" then
            
            self.artifact_node:runAction(cc.Sequence:create(cc.FadeOut:create(0.1),cc.CallFunc:create(function ()
                self.artifact_node:setVisible(false)
            end)))

            if self.confirm_btn2 then
                self.confirm_btn2:runAction(cc.FadeOut:create(0.1))
            end
            self.confirm_btn:runAction(cc.FadeOut:create(0.1))
        elseif event.eventData.name == "change_in" then
            self.artifact_node1:runAction(cc.Sequence:create(cc.FadeOut:create(0),cc.CallFunc:create(function () self:OpenArtifactSuccess() end), cc.FadeIn:create(0.1)))
        end 
    end, sp.EventType.ANIMATION_EVENT)    
end

function mercenary_weapon_panel:RegisterEvent()

    graphic:RegisterEvent("update_mercenary_weapon_lv", function(mercenary_id, result)
        if not self.root_node:isVisible() then
            return
        end

        if self.mercenary_id == mercenary_id then
            weapon_sub_panel.show_forge_animation = true

            if result == "success" then
                audio_manager:PlayEffect("forge_success")
                weapon_sub_panel.spine_node:setVisible(true)
                weapon_sub_panel.spine_node:setAnimation(0, "win", false)
            else
                audio_manager:PlayEffect("forge_failure")
                weapon_sub_panel.spine_node:setVisible(true)
                weapon_sub_panel.spine_node:setAnimation(0, "lose", false)
            end

        end
    end)

    graphic:RegisterEvent("open_artifact", function(mercenary_id)
        if not self.root_node:isVisible() then
            return
        end

        if self.mercenary_id == mercenary_id then
            if troop_logic:IsArtifactUpgrade(self.mercenary_id) then
                self.spine_node:setVisible(true)
                self.spine_node:setAnimation(0, "change_frame", false)
            else
                self:OpenArtifactSuccess()
            end
        end
    end)

    graphic:RegisterEvent("mercenary_artifact_upgrade", function(result,mercenary_id)
        self.update_state = ARTIFACT_UPDATE_STATE["complete"]
        if not artifact_update_panel.root_node:isVisible() then
            return
        end
        if mercenary_id and result == "success" then
            artifact_update_panel:Show(mercenary_id)
            artifact_update_panel:RunUpdateAnimation()
        end
    end)
end
return mercenary_weapon_panel
