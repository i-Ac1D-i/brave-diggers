local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local resource_logic = require "logic.resource"

local panel_prototype = require "ui.panel"
local icon_panel = require "ui.icon_panel"

local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local panel_util = require "ui.panel_util"
local spine_manager = require "util.spine_manager"
--r2
local platform_manager = require "logic.platform_manager"

local PLIST_TYPE = ccui.TextureResType.plistType

local FORGE_WEAPON_ANIMATION_MAX_TIME = 100 -- 强化武器动画的最大时间

local WEAPON_COST_SUB_PANEL_POS_Y = 488  --觉醒消耗sub_panel 位置
local WEAPON_COST_SUB_PANEL_MAX_NUM = 5  --觉醒消耗资源类型个数

local ARTIFACT_COST_SUB_PANEL_POS_Y = 448  --觉醒消耗sub_panel 位置
local ARTIFACT_COST_SUB_PANEL_MAX_NUM = 5  --觉醒消耗资源类型个数
local SPINE_NODE_ZORDER = 100

local _show_forge_notify = true

local msgbox = panel_prototype.New()
function msgbox:Init(root_node)
    self.root_node = root_node

    self.close1_btn = root_node:getChildByName("close1_btn")
    self.close2_btn = root_node:getChildByName("close2_btn")
    self.confirm_btn = root_node:getChildByName("confirm_btn")

    self.notify_btn = root_node:getChildByName("notify_btn")
    self.notify_img = root_node:getChildByName("notify_img")


    self.root_node:setVisible(false)

    local hide = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            self.root_node:setVisible(false)
        end
    end

    self.close1_btn:addTouchEventListener(hide)
    self.close2_btn:addTouchEventListener(hide)

    self.notify_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            _show_forge_notify = not _show_forge_notify
            self.notify_img:setVisible(not _show_forge_notify)
        end
    end)
    --r2位置修改
    local pos_y=platform_manager:GetChannelInfo().weapon_sub_panel_msgbox_pos_y
    if pos_y ~= nil then
        local desc_text=root_node:getChildByName("desc")
        desc_text:setPositionY(desc_text:getPositionY()+pos_y)
    end
end

function msgbox:Show()
    self.root_node:setVisible(true)
    self.notify_img:setVisible(true)
    _show_forge_notify = false
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

    self.finish_forge_text = consume_node:getChildByName("finish_forge")
    panel_util:SetTextOutline(self.finish_forge_text)

    local forge_bg_img = consume_node:getChildByName("add_success_rate")
    self.decrease_forge_success_btn = forge_bg_img:getChildByName("decrease_btn")
    self.increase_forge_success_btn = forge_bg_img:getChildByName("add_btn")
    self.max_forge_success_btn = forge_bg_img:getChildByName("max_btn")
    self.success_chance_text = forge_bg_img:getChildByName("total_success_rate")

    --COST
    self.cost_sub_panels = {1, 2, 3, 4, 5}
    for i = 1, WEAPON_COST_SUB_PANEL_MAX_NUM do
        local cost_sub_panel = icon_panel.New()
        cost_sub_panel:Init(self.root_node)
        self.cost_sub_panels[i] = cost_sub_panel
    end

    --是否可以将武器锻造为宝具
    self.can_artifact_desc_text = root_node:getChildByName("can_artifact"):getChildByName("desc")
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
        graphic:DispatchEvent("update_battle_point", troop_logic.battle_point)

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
        panel_util:SetTextOutline(self.can_artifact_desc_text)
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

    panel_util:LoadCostResourceInfo(config, self.cost_sub_panels, WEAPON_COST_SUB_PANEL_POS_Y, WEAPON_COST_SUB_PANEL_MAX_NUM)

    self.min_success_chance = config.success_chance
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

--宝具强化
local artifact_sub_panel = panel_prototype.New(true)

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

    self.cost_sub_panels = {1, 2, 3, 4, 5}
    for i = 1, ARTIFACT_COST_SUB_PANEL_MAX_NUM do
        local cost_sub_panel = icon_panel.New()
        cost_sub_panel:Init(self.root_node)
        self.cost_sub_panels[i] = cost_sub_panel
    end

    self.root_node:setVisible(false)
end

function artifact_sub_panel:Show(mercenary_id)
    self.root_node:setVisible(true)
    self.mercenary_id = mercenary_id

    local mercenary = troop_logic:GetMercenaryInfo(mercenary_id)
    panel_util:LoadCostResourceInfo(constants["OPEN_ARTIFACT_CONSUME_RESOURCE"], self.cost_sub_panels, ARTIFACT_COST_SUB_PANEL_POS_Y, ARTIFACT_COST_SUB_PANEL_MAX_NUM)

    local template_info = mercenary.template_info
    self.speed_text:setString(template_info["artifact_speed"])
    self.defense_text:setString(template_info["artifact_defense"])
    self.dodge_text:setString(template_info["artifact_dodge"])
    self.authority_text:setString(template_info["artifact_authority"])

    if template_info["have_artifact"] then
        self.name_text:setString(template_info["artifact_name"])
        self.artifact_icon:loadTexture(client_constants["ARTIFACT_ICON_PATH"] .. template_info["artifact_icon"], PLIST_TYPE)
    end

    self.propmt_text:setVisible(mercenary.is_open_artifact)
    self.consume_node:setVisible(not mercenary.is_open_artifact)
    self:SetCostResourceVisible(not mercenary.is_open_artifact)

end

function artifact_sub_panel:SetCostResourceVisible(is_visible)
    for i = 1, ARTIFACT_COST_SUB_PANEL_MAX_NUM do
        self.cost_sub_panels[i].root_node:setVisible(is_visible)
    end
end

local mercenary_weapon_panel = panel_prototype.New(true)
function mercenary_weapon_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/weapon_panel.csb")

    --weapon
    self.weapon_tab_img = self.root_node:getChildByName("weapon_tab")
    self.weapon_tab_img:setTouchEnabled(true)
    self.weapon_node = self.root_node:getChildByName("weapon")
    weapon_sub_panel:Init(self.weapon_node)

    ---artifact
    self.artifact_tab_img = self.root_node:getChildByName("artifact_tab")
    self.artifact_tab_img:setTouchEnabled(true)

    self.artifact_title_text = self.artifact_tab_img:getChildByName("desc")

    self.artifact_node = self.root_node:getChildByName("artifact")
    artifact_sub_panel:Init(self.artifact_node)

    self.confirm_btn = self.root_node:getChildByName("confirm_btn")
    self.cancel_btn = self.root_node:getChildByName("cancel_btn")

    msgbox:Init(self.root_node:getChildByName("msgbox"))

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

    self.root_node:setVisible(true)
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
    local mercenary = troop_logic:GetMercenaryInfo(self.mercenary_id)

    if show_weapon_sub_panel then
        self.weapon_tab_img:setColor(panel_util:GetColor4B(client_constants["LIGHT_BLEND_COLOR"]))
        self.artifact_tab_img:setColor(panel_util:GetColor4B(client_constants["DARK_BLEND_COLOR"]))
        artifact_sub_panel:Hide()
        weapon_sub_panel:Show(self.mercenary_id)
        self.confirm_btn:setTitleText(lang_constants:Get("mercenary_confirm_forge_btn"))

    else
        self.weapon_tab_img:setColor(panel_util:GetColor4B(client_constants["DARK_BLEND_COLOR"]))
        self.artifact_tab_img:setColor(panel_util:GetColor4B(client_constants["LIGHT_BLEND_COLOR"]))
        weapon_sub_panel:Hide()
        artifact_sub_panel:Show(self.mercenary_id)

        if mercenary.is_open_artifact then
            self.confirm_btn:setTitleText(lang_constants:Get("mercenary_finish_artifact_btn"))
        else
            self.confirm_btn:setTitleText(lang_constants:Get("mercenary_confirm_artifact_btn"))
        end
    end
end

function mercenary_weapon_panel:Update(elapsed_time)
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

        troop_logic:ForgeWeapon(self.mercenary_id, extra_chance)
    end

    self.root_node:getChildByName("confirm_btn"):addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if weapon_sub_panel.root_node:isVisible() then
                --强化武器
                local chance = weapon_sub_panel.total_chance
                if chance > 0 and chance <= 50 and _show_forge_notify then
                    msgbox:Show()

                else
                    do_forge()
                end

            elseif artifact_sub_panel.root_node:isVisible() then
                --锻造宝具
                if artifact_sub_panel.is_open_artifact then
                    return
                end

                troop_logic:OpenArtifact(self.mercenary_id)
            end
        end
    end)

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

    msgbox.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            do_forge()
            msgbox.root_node:setVisible(false)
        end
    end)
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
            artifact_sub_panel.propmt_text:setVisible(true)
            artifact_sub_panel.consume_node:setVisible(false)
            self.confirm_btn:setTitleText(lang_constants:Get("mercenary_finish_artifact_btn"))
            artifact_sub_panel:SetCostResourceVisible(false)
        end
    end)

end

return mercenary_weapon_panel
