local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local resource_logic = require "logic.resource"
local panel_prototype = require "ui.panel"
local icon_panel = require "ui.icon_panel"

local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local FORCE_LV_COST_RESOURCE_NUM = constants["FORCE_LV_COST_RESOURCE_NUM"]

local WAKEUP_COST_SUB_PANEL_POS_Y = 488  --觉醒消耗sub_panel 位置
local WAKEUP_COST_SUB_PANEL_MAX_NUM = 2  --觉醒消耗资源类型个数

local FORCE_LV_COST_SUB_PANEL_POS_Y = 488
local FORCE_LV_COST_SUB_PANEL_MAX_NUM = 2  --界限突破资源类型个数

local RESOURCE_TYPE = constants.RESOURCE_TYPE
local PLIST_TYPE = ccui.TextureResType.plistType

local temp_mercenary = {}

--觉醒sub_panel
local mercenary_wakeup_panel = panel_prototype.New(true)
function mercenary_wakeup_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/wakeup_panel.csb")

    local wakeup_node = self.root_node:getChildByName("wakeup")
    local info_node = wakeup_node:getChildByName("info")
    --觉醒效果进度条
    self.wakeup_lbar = info_node:getChildByName("lbar")
    self.wakeup_lbar:setPercent(0)
    self.wakeup_lbar_width = self.wakeup_lbar:getContentSize().width
    self.wakeup_lbar_pos_x = self.wakeup_lbar:getPositionX() - self.wakeup_lbar_width / 2
    self.light_img = info_node:getChildByName("light")
    self.light_img:setVisible(false)

    --角色
    self.quality_img = info_node:getChildByName("quality")
    self.role_img = self.quality_img:getChildByName("role_img")
    self.role_img:ignoreContentAdaptWithSize(true)
    self.role_img:setScale(2, 2)

    self.wakeup1_text = info_node:getChildByName("wakeup_icon1"):getChildByName("desc")
    self.wakeup2_text = info_node:getChildByName("wakeup_icon2"):getChildByName("desc")

    self.cur_bp_text = info_node:getChildByName("bp1")
    self.next_bp_text = info_node:getChildByName("bp2")
    panel_util:SetTextOutline(self.next_bp_text)

    self.arrow_img1 = info_node:getChildByName("change_icon1")
    self.arrow_img2 = info_node:getChildByName("change_icon2")

    --cost
    local cost_node = wakeup_node:getChildByName("consume")
    self.cost_node = cost_node
    --该佣兵是否可以进行界限突破
    self.is_force_lv_desc_text = cost_node:getChildByName("desc2")

    self.cost_sub_panels = {}
    for i = 1, WAKEUP_COST_SUB_PANEL_MAX_NUM do
        local cost_sub_panel = icon_panel.New()
        cost_sub_panel:Init(cost_node)
        self.cost_sub_panels[i] = cost_sub_panel
    end

    --可以进行界限突破的说明
    self.full_level_desc1_text = wakeup_node:getChildByName("prompt_msg1")
    self.full_level_desc1_text:setVisible(false)

    --不可以进行界限突破，佣兵已打到自己的上限
    self.full_level_desc2_text = wakeup_node:getChildByName("prompt_msg2")
    self.full_level_desc2_text:setVisible(false)

    self.confirm_btn = self.root_node:getChildByName("confirm_btn")

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function mercenary_wakeup_panel:Show(instance_id)
    self.instance_id = instance_id
    local mercenary = troop_logic:GetMercenaryInfo(instance_id)
    self.role_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. mercenary.template_info.sprite .. ".png", PLIST_TYPE)
    self.quality_img:loadTexture(client_constants["MERCENARY_BG_SPRITE"][mercenary.template_info.quality], PLIST_TYPE)

    --是否觉醒满级
    local is_max_wakeup = ( mercenary.wakeup == mercenary.template_info.max_wakeup )

    --觉醒满级时，下面的不显示
    self.arrow_img1:setVisible(not is_max_wakeup)
    self.arrow_img2:setVisible(not is_max_wakeup)
    self.next_bp_text:setVisible(not is_max_wakeup)
    self.cost_node:setVisible(not is_max_wakeup)

    local next_wakeup = is_max_wakeup and mercenary.wakeup or (mercenary.wakeup + 1)

    temp_mercenary.exp = mercenary.exp
    temp_mercenary.wakeup = next_wakeup
    temp_mercenary.is_leader = mercenary.is_leader
    temp_mercenary.template_info = mercenary.template_info
    temp_mercenary.weapon_lv = mercenary.weapon_lv
    temp_mercenary.force_lv = mercenary.force_lv
    temp_mercenary.artifact_lv = mercenary.artifact_lv   --宝具等级
    temp_mercenary.is_open_artifact = mercenary.is_open_artifact  --是否开启宝具

    self.wakeup1_text:setString(mercenary.wakeup .. "/" .. mercenary.template_info.max_wakeup)
    self.wakeup2_text:setString(temp_mercenary.wakeup .. "/" .. mercenary.template_info.max_wakeup)

    --计算觉醒后的战力
    troop_logic:CalcMercenaryLevel(temp_mercenary)
    troop_logic:CalcMercenaryBP(temp_mercenary)

    self.cur_bp_text:setString(tostring(mercenary.battle_point))
    self.next_bp_text:setString(tostring(temp_mercenary.battle_point))

    --是否可以界限突破
    local can_upgrade_force = mercenary.template_info.can_upgrade_force
    if can_upgrade_force then
        self.is_force_lv_desc_text:setString(lang_constants:Get("mercenary_upgrade_force_prompt2"))
    else
        self.is_force_lv_desc_text:setString(lang_constants:Get("mercenary_upgrade_force_prompt1"))
    end

    --觉醒满级，则不再重置数据
    if is_max_wakeup then
        self.full_level_desc1_text:setVisible(can_upgrade_force)
        self.full_level_desc2_text:setVisible(not can_upgrade_force)

        self.confirm_btn:setColor(panel_util:GetColor4B(0xffffff))
        self.confirm_btn:setTitleText(lang_constants:Get("mercenary_confirm_wakeup_btn"))
    else

        local config = config_manager.wakeup_info_config[mercenary.wakeup]
        local rerource_type_num, resource_is_enough = panel_util:LoadCostResourceInfo(config, self.cost_sub_panels, WAKEUP_COST_SUB_PANEL_POS_Y, 2,nil,true)-- 资源跳转

        if resource_is_enough then
            self.confirm_btn:setColor(panel_util:GetColor4B(0xffffff))
            self.confirm_btn:setTitleText(lang_constants:Get("mercenary_confirm_wakeup_btn"))
        else
            self.confirm_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
            self.confirm_btn:setTitleText(lang_constants:Get("resource_general_not_enough"))
        end

        self.full_level_desc1_text:setVisible(false)
        self.full_level_desc2_text:setVisible(false)
    end

    --消耗资源
    self.root_node:setVisible(true)
    self.duration = 1

    --佣兵觉醒进度条初始化
    self.show_wakeup_aimation = false
    self.wakeup_lbar:setPercent(0)
    self.wakeup_lbar:setVisible(false)
    self.light_img:setVisible(false)
end

function mercenary_wakeup_panel:Update(elapsed_time)

    if self.show_wakeup_aimation then
        local duration = self.duration
        self.wakeup_lbar:setPercent(duration)

        local offset_x = self.wakeup_lbar_width * duration / 100
        self.light_img:setPositionX(self.wakeup_lbar_pos_x + offset_x)

        duration = duration + 1
        self.duration = duration

        if duration > 100 then
            self.duration = 1
            self.show_wakeup_aimation = false
            self.wakeup_lbar:setVisible(false)
            self.light_img:setVisible(false)
            self:Show(self.instance_id)

            graphic:DispatchEvent("update_mercenary_info", self.instance_id)
        end
    end
end

function mercenary_wakeup_panel:RegisterWidgetEvent()

    --觉醒或者界限突破
    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if self.is_max_wakeup then
                return
            end

            --觉醒进度条走动期间不能接着觉醒
            if self.show_wakeup_aimation then
                return
            end

            troop_logic:UpgradeMercenaryWakeup(self.instance_id)
        end
    end)

    --关闭
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("cancel_btn"), "mercenary_wakeup_panel")

end

function mercenary_wakeup_panel:RegisterEvent()
    --有动画时 补充
    graphic:RegisterEvent("update_mercenary_wakeup", function(instance_id)
        if not self.root_node:isVisible() then
            return
        end

        if self.instance_id == instance_id then
            audio_manager:PlayEffect("wakeup")
            self.show_wakeup_aimation = true
            self.light_img:setVisible(true)
            self.wakeup_lbar:setVisible(true)
            self.wakeup_lbar:setPercent(0)
        end
    end)
    --资源更新
    graphic:RegisterEvent("update_resource_list", function()
        if not self.root_node:isVisible() then
            return
        end
        self:RefreshResource()
    end)
end

function mercenary_wakeup_panel:RefreshResource()
    if self.cost_sub_panels then
        for k,v in pairs(self.cost_sub_panels) do
            local resourceType = v:GetIconResourceType()
            if resource_logic:IsResourceUpdated(resourceType) then
                v:SetTextStatus(resourceType)
            end
        end
    end
end
return mercenary_wakeup_panel
