local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local resource_logic = require "logic.resource"
local panel_prototype = require "ui.panel"
local icon_panel = require "ui.icon_panel"
--r2
local platform_manager = require "logic.platform_manager"

local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local FORCE_LV_COST_RESOURCE_NUM = constants["FORCE_LV_COST_RESOURCE_NUM"]

local FORCE_LV_COST_SUB_PANEL_POS_Y = 488
local FORCE_LV_COST_SUB_PANEL_MAX_NUM = 3  --界限突破资源类型个数
local CHANGE_PROPERTY_NODE_DURATION = 0.3

local RESOURCE_TYPE = constants.RESOURCE_TYPE
local PLIST_TYPE = ccui.TextureResType.plistType

local force_panel = panel_prototype.New(true)
function force_panel:Init(root_node)

    self.root_node = cc.CSLoader:createNode("ui/force_panel.csb")

    self.panel_title_text = self.root_node:getChildByName("force_lv_tab"):getChildByName("desc")

    local prompt_node = self.root_node:getChildByName("promote")

    self.cost_node = prompt_node:getChildByName("consume")
    self.cost_node_title = self.cost_node:getChildByName("title")

    self.cost_sub_panels = {}
    for i = 1, FORCE_LV_COST_SUB_PANEL_MAX_NUM do
        local cost_sub_panel = icon_panel.New()
        cost_sub_panel:Init(self.cost_node)
        self.cost_sub_panels[i] = cost_sub_panel
    end

    self.not_start_force_node = prompt_node:getChildByName("status1")
    self.forcing_node = prompt_node:getChildByName("status2")

    local forcing_node = self.forcing_node
    --突破完成获取的额外属性加成
    self.ex_prop_icon_img = forcing_node:getChildByName("property_icon")
    self.ex_prop_val_text = forcing_node:getChildByName("property_value")
    self.role_img1 = forcing_node:getChildByName("lbar_iconbg"):getChildByName("role")
    self.role_img1:ignoreContentAdaptWithSize(true)
    self.role_img1:setScale(2, 2)

    --进度条
    self.force_lbar = forcing_node:getChildByName("lbar")
    self.force_lbar_width = self.force_lbar:getContentSize().width
    self.force_lbar_pos_x = self.force_lbar:getPositionX()
    self.force_lbar:setPercent(0)
    self.light_img = self.force_lbar:getChildByName("head")

    self.no_finish_node = forcing_node:getChildByName("no_finish")
    self.finish_node = forcing_node:getChildByName("finish")

    self.add_bp_text = self.no_finish_node:getChildByName("bp_add")

    -- 突破到最高级
    self.finish_desc_text = prompt_node:getChildByName("finish")
    self.finish_desc_text:setVisible(false)

    self.force_btn = self.root_node:getChildByName("confirm_btn")

    -- 属性转化
    self.change_property_node = prompt_node:getChildByName("status3")

    -- 属性图片
    self.role_img2 = self.change_property_node:getChildByName("lbar_iconbg"):getChildByName("role")
    self.role_img2:ignoreContentAdaptWithSize(true)
    self.role_img2:setScale(2, 2)

    -- 属性 ＋ 数值
    self.property_value = self.change_property_node:getChildByName("property_value")
    self.property_limit = self.change_property_node:getChildByName("property_limit")
    self.property_icon = self.change_property_node:getChildByName("property_icon")
    -- 文字 当前属性（契约加成）
    self.change_property_desc1 = self.change_property_node:getChildByName("desc1")

    self.is_max_force = false
    self.change_property_node_animate = true
    self.change_property_node_durantion = 0

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function force_panel:Show(instance_id)
    if instance_id ~= self.instance_id then
        self.is_max_force = false
        self.change_property_node_animate = false
    end

    local mercenary = troop_logic:GetMercenaryInfo(instance_id)
    self.role_img1:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. mercenary.template_info.sprite .. ".png", PLIST_TYPE)
    self.role_img2:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. mercenary.template_info.sprite .. ".png", PLIST_TYPE)

    -- 突破面板
    self.forcing_node:setVisible(false)
    -- 属性转换面板
    self.change_property_node:setVisible(false)

    --是否已经开始突破
    local is_start_force = mercenary.force_lv == 0
    self.not_start_force_node:setVisible(is_start_force)

    --是否突破到满级
    local is_max_force = self.is_max_force
    self.is_max_force = mercenary.force_lv == constants["MAX_FORCE_LEVEL"]

    local config
    local title_text, btn_text, btn_color = "", "", 0xFFFFFF

    if not self.is_max_force then
        title_text = lang_constants:Get("force_title")
        btn_text = lang_constants:Get("confirm_force")

        -- 资源消耗
        config = FORCE_LV_COST_RESOURCE_NUM

        -- 突破
        if not is_start_force then
            -- 属性透明度
            self.ex_prop_icon_img:setOpacity(255 * 0.5)
            self.ex_prop_val_text:setOpacity(255 * 0.5)

            self.forcing_node:setVisible(true)
            self:ShowForce(mercenary)
        end

    else
        title_text = lang_constants:Get("change_exproperty_title")
        btn_text = lang_constants:Get("change_exproperty_confirm")

        -- 资源消耗 灵魂碎片 ＝ 佣兵解雇获得数量
        config = constants.CHANGE_EX_PROPERTY_RESOURCE
        config.soul_chip = mercenary.template_info.soul_chip * config.scale

        -- 属性转化面板0.3s内透明度从0到1
        self.change_property_node_animate = not is_max_force

        -- 属性转换
        self.change_property_node:setVisible(true)
        if self.change_property_node_animate then
            self.change_property_node:setOpacity(0)
        else
            self.change_property_node:setOpacity(255)
        end
        self:ShowChangeProperty(mercenary)
    end

    local _, resource_is_enough = panel_util:LoadCostResourceInfo(config, self.cost_sub_panels, FORCE_LV_COST_SUB_PANEL_POS_Y, FORCE_LV_COST_SUB_PANEL_MAX_NUM)

    if not resource_is_enough then
        btn_text = lang_constants:Get("resource_general_not_enough")
        btn_color = 0x7F7F7F
    end

    self.panel_title_text:setString(title_text)
    self.force_btn:setTitleText(btn_text)
    self.force_btn:setColor(panel_util:GetColor4B(btn_color))

    self.instance_id = instance_id

    if not self.root_node:isVisible() then
        self.root_node:setVisible(true)
    end
end

-- 突破
function force_panel:ShowForce(mercenary)
    self.ex_prop_icon_img:loadTexture(client_constants.MERCENARY_PROPERTY_ICON[mercenary.ex_prop_type], PLIST_TYPE)
    self.ex_prop_val_text:setString("+".. mercenary.ex_prop_val * constants["CONTRACT_FORCE_UP"][mercenary.contract_lv] )

    self.add_bp_text:setString(string.format(lang_constants:Get("mercenary_force_bp"), mercenary.force_lv))

    local percent = math.ceil(mercenary.force_lv / constants["MAX_FORCE_LEVEL"] * 100)
    self.force_lbar:setPercent(percent)
    self.light_img:setPositionX(self.force_lbar_width * (percent / 100))

    self.cost_node_title:setString(lang_constants:Get("force_consume"))

    self.finish_node:setVisible(false)
    self.no_finish_node:setVisible(true)
end

-- 属性转化
function force_panel:ShowChangeProperty(mercenary)
    self.property_icon:loadTexture(client_constants.MERCENARY_PROPERTY_ICON[mercenary.ex_prop_type], PLIST_TYPE)

    local full_contract = mercenary.contract_lv >= 2

    -- 四维中文称呼 + 数值
    -- 如果因为二阶契约有突破属性加成，四维中文称呼 + 数值 + (x2)
    local prop_name = constants.PROPERTY_TYPE_NAME[mercenary.ex_prop_type]
    local text = lang_constants:Get("mercenary_" .. prop_name) .. "+" .. mercenary.ex_prop_val
    --r2修改
    if platform_manager:GetChannelInfo().force_panel_ex_prop_val_text_add_air then
        --加一个空格
        text = lang_constants:Get("mercenary_" .. prop_name) .. " +" .. mercenary.ex_prop_val
    end
    if full_contract then
        text = text .. "(x2)"
    end
    self.property_value:setString(text)

    -- / 上限数值
    text = "/  +" .. constants.FORCE_LEVEL_PROPERTY[constants.PROPERTY_TYPE_NAME[mercenary.ex_prop_type]]
    self.property_limit:setString(text)

    -- 当没有二阶契约时，“当前属性”，当有二阶加成时，是“当前属性（契约加成）”
    text = lang_constants:Get("now_property")
    if full_contract then
        text = text .. " (" .. lang_constants:Get("mercenary_contract_add") .. ")"
    end
    self.change_property_desc1:setString(text)

    self.cost_node_title:setString(lang_constants:Get("change_exproperty_consume"))
end


function force_panel:Update(elapsed_time)
    -- 属性转化面板0.3s内透明度从0到1
    if self.change_property_node_animate then
        self.change_property_node_durantion = self.change_property_node_durantion + elapsed_time

        local percent = 1.01 * math.exp(- ( 1.2 * (self.change_property_node_durantion / CHANGE_PROPERTY_NODE_DURATION) - 1.5) ^ 4)
        if percent >= 1 then
            percent = 1
            self.change_property_node_animate = false
            self.change_property_node_durantion = 0
        end

        self.change_property_node:setOpacity(255 * percent)
    end
end

function force_panel:RegisterWidgetEvent()

    --觉醒或者界限突破 加 属性转换
    self.force_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            --转换附加属性提示弹窗
            if self.is_max_force then
                local title = lang_constants:Get("change_exproperty_confirm")

                local confirm_text = lang_constants:Get("common_confirm")
                local cancel_text = lang_constants:Get("common_cancel")

                local mercenary = troop_logic:GetMercenaryInfo(self.instance_id)
                local prop_name = constants.PROPERTY_TYPE_NAME[mercenary.ex_prop_type]

                if mercenary.ex_prop_val >= constants.FORCE_LEVEL_PROPERTY[prop_name] then
                    local desc = lang_constants:Get("change_property_desc1")

                    graphic:DispatchEvent("show_simple_msgbox", title, desc, confirm_text, cancel_text,
                    function()
                        troop_logic:ChangeExProperty(self.instance_id)
                    end)

                else
                    troop_logic:ChangeExProperty(self.instance_id)
                end
            else
                troop_logic:UpgradeMercenaryForcelv(self.instance_id)
            end
        end
    end)

    --关闭
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("cancel_btn"), self:GetName())
end

function force_panel:RegisterEvent()

    graphic:RegisterEvent("update_force_panel", function(instance_id)
        if not self.root_node:isVisible() then
            return
        end

        if self.instance_id == instance_id then
            self:Show(instance_id)
        end
    end)
end

return force_panel

