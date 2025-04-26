local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"

local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local configuration = require "util.configuration"
local spine_manager = require "util.spine_manager"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local user_logic  = require "logic.user"
local platform_manager = require "logic.platform_manager"
local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]
local MERCENARY_CHOOSE_SHOW_MODE = client_constants["MERCENARY_CHOOSE_SHOW_MODE"]
local MERCENARY_PROPERTY_ICON = client_constants["MERCENARY_PROPERTY_ICON"]
local PROPERTY_TYPE = constants["PROPERTY_TYPE"]
local leader_contract_config = config_manager.leader_contract_config
local PLIST_TYPE = ccui.TextureResType.plistType

local ANIMATION_STATE =
{
    ["none"] = 1,
    ["show_info"] = 2,
    ["move_info"] = 3,
    ["hide_info"] = 4,
    ["contract_one"] = 5,
    ["contract_two"] = 6,
    ["contract_loop"] = 7,
    ["leader_contract_lv"] = 8,
}

local SPINE_ANIMATION = {
    ["none"] = 1,
    ["contract_first_enter"] = 2,
    ["contract_first_loop"] = 3,
}

local DURATION = 0.3
local MAX_OPACITY = 255

local info_sub_panel = panel_prototype.New()
info_sub_panel.__index = info_sub_panel
function info_sub_panel.New()
    return setmetatable({}, info_sub_panel)
end

function info_sub_panel:Init(root_node, panel_contract_lv)
    self.root_node = root_node
    self.panel_contract_lv = panel_contract_lv

    self.desc_text = self.root_node:getChildByName("desc")

    self.property_nodes = {}
    self.property_icon_imgs = {}

    for i = 1, 4 do
        local node = root_node:getChildByName("property" .. i)
        self.property_icon_imgs[i] = node:getChildByName("icon")

        self.property_nodes[i] = node
    end
end

local PROPERTY_LIST = { "speed", "defense", "dodge", "authority" }

function info_sub_panel:Load(mercenary)
    local contract_map = config_manager.mercenary_contract_config[self.panel_contract_lv]
    if not contract_map then
        return
    end

    local conf = contract_map[mercenary.template_info.ID]
    if not conf then
        return
    end

    self.desc_text:setString(mercenary.contract_lv >= self.panel_contract_lv and lang_constants:Get("mercenary_contract_state1") or lang_constants:Get("mercenary_contract_state2"))

    self.index = 1

    local old_conf
    if self.panel_contract_lv > 1 then
        old_conf = config_manager.mercenary_contract_config[self.panel_contract_lv-1][mercenary.template_info.ID]
    end

    for i = 1, #PROPERTY_LIST do
        self:LoadProperty(conf, PROPERTY_LIST[i], old_conf)
    end

    for i = self.index, 4 do
        local node = self.property_nodes[i]
        local icon = self.property_icon_imgs[i]

        local val_text = node:getChildByName("gain_num")
        local desc_text = node:getChildByName("desc")

        node:setOpacity(77)
        icon:setVisible(false)
        val_text:setString("")
        desc_text:setString("")
    end
end

function info_sub_panel:LoadProperty(conf, property_name, old_conf)
    local val = conf[property_name]
    if old_conf then
        val = val - old_conf[property_name]
    end

    local node = self.property_nodes[self.index]

    local icon = self.property_icon_imgs[self.index]
    local val_text = node:getChildByName("gain_num")
    local desc_text = node:getChildByName("desc")
    local property_type = PROPERTY_TYPE[property_name]

    if val > 0 then
        node:setOpacity(MAX_OPACITY)
        icon:setVisible(true)

        icon:loadTexture(MERCENARY_PROPERTY_ICON[property_type], PLIST_TYPE)
        val_text:setString("+" .. val)

        desc_text:setString(lang_constants:Get("mercenary_"  .. property_name))

        self.index = self.index + 1
    end
end

local mercenary_contract_panel = panel_prototype.New()
function mercenary_contract_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mercenary_contract_panel.csb")

    self.choose_target_node = self.root_node:getChildByName("choose_target")
    self.choose_target_pos_y = self.choose_target_node:getPositionY()

    self.contract_btn = self.root_node:getChildByName("contract_btn")
    self.contract_btn_pos_y = self.contract_btn:getPositionY()

    self.info_node = self.root_node:getChildByName("info")
    self.info_node_pos_y = self.info_node:getPositionY()

    self.back_btn = self.root_node:getChildByName("back_btn")

    self.shadow1_img = self.root_node:getChildByName("shadow1")
    self.shadow1_pos_y = self.shadow1_img:getPositionY()
    self.shadow2_img = self.root_node:getChildByName("shadow2")
    self.shadow2_pos_y = self.shadow2_img:getPositionY()

    self.info_sub_panels = {}
    self.info_sub_panels[1] = info_sub_panel.New()
    self.info_sub_panels[2] = info_sub_panel.New()
    self.info_sub_panels[1]:Init(self.info_node:getChildByName("one"), 1)
    self.info_sub_panels[2]:Init(self.info_node:getChildByName("two"), 2)

    self.two_desc_text = self.info_node:getChildByName("two_closed")

    local con_node = self.info_node:getChildByName("contractinfobg")
    self.bg1_img = con_node:getChildByName("contract_bg1")
    self.bg2_img = con_node:getChildByName("contract_bg2")

    self.bg1_img:setTouchEnabled(true)
    self.bg2_img:setTouchEnabled(true)

    self.leader_role_img = self.contract_btn:getChildByName("leadrole")
    self.leader_role_img:setScale(2, 2)

    local icon = client_constants["MERCENARY_ROLE_IMG_PATH"] .. troop_logic:GetLeader().template_info.sprite .. ".png"
    self.leader_role_img:loadTexture(icon, PLIST_TYPE)

    self.target_role_img = self.contract_btn:getChildByName("role")
    self.target_role_img:ignoreContentAdaptWithSize(true)
    self.target_role_img:setScale(2, 2)

    self.contract_desc1_text = self.contract_btn:getChildByName("desc1")
    self.contract_desc2_text = self.contract_btn:getChildByName("desc2")

    local bottom_node = self.root_node:getChildByName("bottom_bar_two")

    self.leader_role_img = bottom_node:getChildByName("leadrole_icon")
    self.leader_contract_lv_text = bottom_node:getChildByName("lv")
    self.leader_contract_exp_text = bottom_node:getChildByName("exp")
    self.leader_contract_exp_lbar = bottom_node:getChildByName("exp_lbar")
    self.leader_contract_exp_bg_img = bottom_node:getChildByName("lbar_bg")

    self.animation_state = ANIMATION_STATE["none"]

    self.arrow1_img = self.root_node:getChildByName("arrow0")
    self.arrow2_img = self.root_node:getChildByName("arrow1")
    self.arrow1_y = self.arrow1_img:getPositionY()
    self.arrow2_y = self.arrow2_img:getPositionY()

    self.arrow_duration = 0

    self.spine_node = spine_manager:GetNode("contract_success", 1.0, true)
    self.info_node:addChild(self.spine_node)

    self.info_sub_pos = {{}, {}}
    for i = 1, 2 do
        self.info_sub_pos[i].x = self.info_sub_panels[i].root_node:getPositionX() + self.info_sub_panels[i].root_node:getChildByName("iconbg"):getPositionX()
        self.info_sub_pos[i].y = self.info_sub_panels[i].root_node:getPositionY() + self.info_sub_panels[i].root_node:getChildByName("iconbg"):getPositionY()
    end
    self.spine_node:setPosition(self.info_sub_pos[1].x, self.info_sub_pos[1].y)

    self.spine_node:setLocalZOrder(200)

    self.spine_node:setVisible(false)

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function mercenary_contract_panel:Show(mercenary_id)
    self.root_node:setVisible(true)
    self.mercenary_id = mercenary_id

    self:Load(false)

    self.animation = SPINE_ANIMATION["none"]
    self.spine_node:setVisible(false)

    self.info_node:setPositionY(self.info_node_pos_y)

    self.panel_contract_lv = 1

    local leader = troop_logic:GetLeader()
    self.leader_role_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. leader.template_info.sprite .. ".png", PLIST_TYPE)
    self.arrow_duration = 0

    self:CaclLeaderContractLvInfo()
    self:UpdateLeaderContractInfo()

    self:LoadContractInfo()

    self.leader_contract_lv = user_logic.base_info.contract_lv
end

function mercenary_contract_panel:UpdateLeaderContractInfo()
    self.leader_contract_lv_text:setString(string.format(lang_constants:Get("leader_contract_lv"), self.conf_index))
    if self.conf_index == #leader_contract_config then
        self.leader_contract_exp_text:setString("MAX")
        self.leader_contract_exp_lbar:setPercent(100)

    elseif self.conf_index == 0 then
        self.leader_contract_exp_text:setString(string.format(lang_constants:Get("mercenary_contract_exp"), "0/" .. leader_contract_config[1].num))
        self.leader_contract_exp_lbar:setPercent(0)
    else
        self.leader_contract_exp_text:setString(string.format(lang_constants:Get("mercenary_contract_exp"),""..self.cur_contract_num .. "/" .. self.need_contract_num))
        self.leader_contract_exp_lbar:setPercent(self.cur_contract_num / self.need_contract_num * 100)
    end
end

function mercenary_contract_panel:CaclLeaderContractLvInfo()
    local conf_index = troop_logic:GetLeaderContractConfIndex()
    self.conf_index = conf_index
    if conf_index == 0 then
        self.conf_index = 0
        self.cur_contract_num = 0
        self.need_contract_num = 0

    elseif conf_index == #leader_contract_config then
        self.cur_contract_num = 99999
        self.need_contract_num = 99999
    else
        local conf = leader_contract_config[conf_index]
        self.cur_contract_num = user_logic.base_info.contract_lv - conf.num
        self.need_contract_num = leader_contract_config[conf_index + 1].num - conf.num
    end
end

function mercenary_contract_panel:ShowTarget(is_show, opacity)
    self.choose_target_node:setVisible(is_show)
    self.info_node:setVisible(not is_show)
    self.contract_btn:setVisible(not is_show)
    self.shadow1_img:setVisible(not is_show)
    self.shadow2_img:setVisible(not is_show)
    self.choose_target_node:setOpacity(opacity)
end

function mercenary_contract_panel:LoadContractInfo()
    if not self.mercenary_id then
        return
    end

    local mercenary = troop_logic:GetMercenaryInfo(self.mercenary_id)

    self.mercenary = mercenary
    for i = 1, 2 do
        self.info_sub_panels[i]:Load(mercenary)
    end

    local icon = client_constants["MERCENARY_ROLE_IMG_PATH"] .. mercenary.template_info.sprite .. ".png"
    self.target_role_img:loadTexture(icon, PLIST_TYPE)

    local leader = troop_logic:GetLeader()
    self.contract_desc1_text:setString(leader.template_info.name .. " & " .. mercenary.template_info.name)

    --二阶契约是否已经开放

    local lv_2 = false
    local channel = platform_manager:GetChannelInfo()
    if channel.is_open_qi2 then
        lv_2 = troop_logic:CanContractLv(mercenary.template_info.ID, 2)
    else
        
    end
    
    self.two_desc_text:setVisible(not lv_2)
    self.info_sub_panels[2].root_node:setVisible(lv_2)

    if mercenary.contract_lv == 0 then
        self.spine_node:setVisible(false)
        self.animation = SPINE_ANIMATION["none"]
        self.spine_node:clearTrack(0)
    end

    self:SignNextLevelContract(self.panel_contract_lv)
end

function mercenary_contract_panel:ContrcatLoopAniamtion()
    self.spine_node:setVisible(true)
    self.animation = SPINE_ANIMATION["contract_first_loop"]
    self.spine_node:setAnimation(0, "contract_first_loop", true)
end

function mercenary_contract_panel:SignNextLevelContract(panel_contract_lv)
    self.spine_node:setPosition(self.info_sub_pos[panel_contract_lv].x, self.info_sub_pos[panel_contract_lv].y)

    local f = panel_contract_lv == 1
    self.arrow1_img:setVisible(not f)
    self.arrow2_img:setVisible(f)

    if self.mercenary.contract_lv >= panel_contract_lv then
        self:ContrcatLoopAniamtion()
        self.contract_desc2_text:setString(string.format(lang_constants:Get("mercenary_current_contract_lv"), panel_contract_lv))
        self.contract_btn:setColor(panel_util:GetColor4B(0x7f7f7f))

    else
        self.spine_node:setVisible(false)
        if troop_logic:CheckContractResource(self.mercenary_id, panel_contract_lv) then
            self.contract_desc2_text:setString(string.format(lang_constants:Get("mercenary_sign_contract_lv"), panel_contract_lv))
            self.contract_btn:setColor(panel_util:GetColor4B(0xffffff))
        else
            self.contract_desc2_text:setString(lang_constants:Get("resource_general_not_enough"))
            self.contract_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
        end

        --未开放
        if not troop_logic:CanContractLv(self.mercenary.template_info.ID, panel_contract_lv) then
            self.contract_desc2_text:setString(string.format(lang_constants:Get("mercenary_not_contract_lv"), panel_contract_lv))
        else
            --未签订一阶
            if self.mercenary.contract_lv == 0 and panel_contract_lv == constants["MAX_CONTRACT_LV"] then
                self.contract_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
                self.contract_desc2_text:setString(string.format(lang_constants:Get("mercenary_canot_contract_lv1"), panel_contract_lv))
            end
        end
    end
end

function mercenary_contract_panel:Load(is_clear_target)

    self.arrow1_img:setVisible(false)
    self.arrow2_img:setVisible(false)

    if is_clear_target then
        self.animation_state = ANIMATION_STATE["hide_info"]

        self:SetPositionY(0)

        self:SetOpacity(MAX_OPACITY)
        self.cur_opacity = MAX_OPACITY

        self.choose_target_node:setOpacity(0)
        self.choose_target_node:setVisible(true)
        self.choose_target_node:setPositionY(self.choose_target_pos_y - 500)

        self.mercenary_id = nil

    elseif not self.mercenary_id then
        --第一次打开
        self.animation_state = ANIMATION_STATE["none"]
        self:ShowTarget(true, MAX_OPACITY)
        return

    else
        self.arrow1_img:setVisible(true)
        self.arrow2_img:setVisible(true)

        self.animation_state = ANIMATION_STATE["show_info"]
        self:ShowTarget(false, 0)

        self:SetOpacity(0)
        self:SetPositionY(-500)

        self.cur_opacity = 0
    end
    self.duration = 0
end

function mercenary_contract_panel:SetOpacity(opacity)
    self.contract_btn:setOpacity(opacity)
    self.info_node:setOpacity(opacity)
    self.shadow1_img:setOpacity(opacity)
    self.shadow2_img:setOpacity(opacity)
end

function mercenary_contract_panel:SetPositionY(dis_pos)
    self.contract_btn:setPositionY(self.contract_btn_pos_y + dis_pos)
    self.info_node:setPositionY(self.info_node_pos_y + dis_pos)
    self.shadow1_img:setPositionY(self.shadow1_pos_y + dis_pos)
    self.shadow2_img:setPositionY(self.shadow2_pos_y + dis_pos)
end

function mercenary_contract_panel:Update(elapsed_time)

    self:UpdateArrowImg(elapsed_time)

    if self.animation_state == ANIMATION_STATE["none"] then
        return
    end

    self.duration = self.duration + elapsed_time

    if self.animation_state == ANIMATION_STATE["show_info"] then
        self.cur_opacity = math.min(self.cur_opacity + elapsed_time * MAX_OPACITY / DURATION, MAX_OPACITY)
        self:SetOpacity(self.cur_opacity)

        local percent = 1.01 * math.exp(- ( 1.2 * (self.duration / DURATION) - 1.5) ^ 4)
        self:SetPositionY(500 * (1 - percent))

        if self.duration >= DURATION then
            self.animation_state = ANIMATION_STATE["none"]
            self:SetPositionY(0)
        end

    elseif self.animation_state == ANIMATION_STATE["move_info"] then

    elseif self.animation_state == ANIMATION_STATE["hide_info"] then
        self.cur_opacity = math.max(self.cur_opacity - elapsed_time * MAX_OPACITY / DURATION, 0)

        self:SetOpacity(self.cur_opacity)
        self.choose_target_node:setOpacity( 255 - self.cur_opacity)

        local percent = 1.01 * math.exp(- ( 1.2 * (self.duration / DURATION) - 1.5) ^ 4)
        self:SetPositionY(500 * percent)
        self.choose_target_node:setPositionY((self.choose_target_pos_y - 500) + 500 * percent)

        if self.duration >= DURATION then
            self.animation_state = ANIMATION_STATE["none"]
            self.duration = 0
            self.cur_opacity = 0
        end

    elseif self.animation_state == ANIMATION_STATE["contract_one"] then
        self.change_contract_duration = self.change_contract_duration + elapsed_time

        if self.change_contract_duration < 0.3 then
            local percent = 1.01 * math.exp(- ( 1.2 * (self.change_contract_duration / 0.3) - 1.5) ^ 4)
            percent = math.min(percent, 1)
            self.info_node:setPositionY(self.info_node_pos_y + percent * 630)
        else
            self.panel_contract_lv = 2
            self.animation_state = ANIMATION_STATE["none"]
        end

    elseif self.animation_state == ANIMATION_STATE["contract_two"] then
        self.change_contract_duration = self.change_contract_duration + elapsed_time

        if self.change_contract_duration < 0.3 then
            local percent = 1.01 * math.exp(- ( 1.2 * (self.change_contract_duration / 0.3) - 1.5) ^ 4)
            percent = math.min(percent, 1)

            self.info_node:setPositionY(self.info_node_pos_y + 600 - percent * 600)
        else
            self.panel_contract_lv = 1
            self.animation_state = ANIMATION_STATE["none"]

        end

    elseif self.animation_state == ANIMATION_STATE["contract_loop"] then
        self.contract_loop_duration = self.contract_loop_duration + elapsed_time

        if self.contract_loop_duration > 1.5 then
            -- self.animation_state = ANIMATION_STATE["none"]
            self.change_contract_duration = 0
            self.animation_state = ANIMATION_STATE["contract_one"]
            self:SignNextLevelContract(2)
        end

    elseif self.animation_state == ANIMATION_STATE["leader_contract_lv"] then
        self.leader_contract_lv_duration = self.leader_contract_lv_duration + elapsed_time

        if self.leader_contract_lv_duration < 0.3 then
            -- self.animation_state = ANIMATION_STATE["none"]
            local percent = 1.01 * math.exp(- ( 1.2 * (self.leader_contract_lv_duration / 0.3) - 1.5) ^ 4)
            percent = math.min(percent, 1)

            self.leader_contract_exp_lbar:setPercent(self.cur_leader_percent + (self.max_leader_percent - self.cur_leader_percent) * percent)

        else
            self.animation_state = ANIMATION_STATE["none"]
            self:UpdateLeaderContractInfo()

        self.leader_contract_lv_duration = 0
        end
    end
end

function mercenary_contract_panel:UpdateArrowImg(elapsed_time)
    --抖箭头
    self.arrow_duration =  self.arrow_duration  + elapsed_time
    if  self.arrow_duration > 0.314 then
        self.arrow_duration = 0
    end

    self.arrow1_img:setPositionY(self.arrow1_y + 5 * math.sin(10 * self.arrow_duration))
    self.arrow2_img:setPositionY(self.arrow2_y - 5 * math.sin(10 * self.arrow_duration))
end

function mercenary_contract_panel:RegisterWidgetEvent()

    self.choose_target_node:getChildByName("confirm_btn"):addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "mercenary_choose_sub_scene", SCENE_TRANSITION_TYPE["none"], MERCENARY_CHOOSE_SHOW_MODE["contract"])
        end
    end)

    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if self.show_animation then
                return
            end

            if self.info_node:isVisible() then
                graphic:DispatchEvent("show_world_sub_scene", "mercenary_choose_sub_scene", SCENE_TRANSITION_TYPE["none"], MERCENARY_CHOOSE_SHOW_MODE["contract"])
                return
            end

            if self.mercenary_id then
                self:Load(true)

            else
                self.spine_node:clearTrack(0)
                self.spine_node:setVisible(false)
                graphic:DispatchEvent("show_world_sub_scene", "mercenary_sub_scene", constants["SCENE_TRANSITION_TYPE"]["none"])
                -- graphic:DispatchEvent("hide_world_sub_scene", self:GetName())
            end
        end
    end)

    self.contract_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if self.show_animation then
                return
            end

            if self.mercenary_id then
                local conf = troop_logic:GetContractConf(self.mercenary_id, self.panel_contract_lv)
                if not conf then
                    return
                end

                if self.panel_contract_lv == self.mercenary.contract_lv then
                    return
                end

                if self.mercenary.contract_lv == constants["MAX_CONTRACT_LV"] then
                    return
                end

                graphic:DispatchEvent("show_world_sub_panel", "mercenary_contract_msgbox", self.mercenary_id, self.panel_contract_lv)
            end
        end
    end)

    local contract_lv_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            self.start_pos = widget:getTouchBeganPosition()

        elseif event_type == ccui.TouchEventType.moved then
            self.move_pos = widget:getTouchMovePosition()

        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            if self.move_pos and self.start_pos then
                self.spine_node:setToSetupPose()
                if self.move_pos.y - self.start_pos.y >= 40 then
                    if self.panel_contract_lv == 1 then
                        self.change_contract_duration = 0
                        self.animation_state = ANIMATION_STATE["contract_one"]
                        self:SignNextLevelContract(2)
                    end

                elseif self.move_pos.y - self.start_pos.y <= -40 then
                    if self.panel_contract_lv == 2 then
                        self.change_contract_duration = 0
                        self.animation_state = ANIMATION_STATE["contract_two"]
                        self:SignNextLevelContract(1)

                    end
                end
            end
        end
    end

    self.bg1_img:addTouchEventListener(contract_lv_method)
    self.bg2_img:addTouchEventListener(contract_lv_method)

    self.spine_node:registerSpineEventHandler(function(event)
        -- self.show_forge_animation = false
        if self.animation == SPINE_ANIMATION["contract_first_enter"] then
            self.show_animation = false
            self:LoadContractInfo()
            self.spine_node:setToSetupPose()

            self.animation = SPINE_ANIMATION["contract_first_loop"]
            self.spine_node:setAnimation(0, "contract_first_loop", true)

            local mercenary = troop_logic:GetMercenaryInfo(self.mercenary_id)

            if mercenary.contract_lv == 1 and troop_logic:CanContractLv(mercenary.template_info.ID, 2) then
                self.contract_loop_duration = 0
                self.animation_state = ANIMATION_STATE["contract_loop"]
            elseif mercenary.contract_lv == 2 then
                self.cur_leader_percent = self.cur_contract_num / self.need_contract_num * 100
                local conf_index = self.conf_index
                self:CaclLeaderContractLvInfo()
                if self.conf_index - conf_index == 1 then
                    --主角升级
                    self.max_leader_percent = 100
                else
                    self.max_leader_percent = self.cur_contract_num / self.need_contract_num * 100
                end

                self.leader_contract_lv_duration = 0
                self.animation_state = ANIMATION_STATE["leader_contract_lv"]

            end

        end

    end, sp.EventType.ANIMATION_COMPLETE)

    self.leader_contract_exp_bg_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")
            local title, desc = panel_util:GetLeaderContractInfo()
            local pos = widget:getTouchBeganPosition()
            graphic:DispatchEvent("show_floating_panel", title, desc, pos.x, pos.y)

        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            graphic:DispatchEvent("hide_floating_panel")
        end
    end)
end

function mercenary_contract_panel:RegisterEvent()

    graphic:RegisterEvent("sign_mercenary_contract", function(mercenary_id)
        if not self.root_node:isVisible() then
            return
        end

        if self.mercenary_id ~= mercenary_id then
            return
        end
        audio_manager:PlayEffect("contract_success")
        self.animation = SPINE_ANIMATION["contract_first_enter"]
        self.spine_node:setVisible(true)
        self.show_animation = true

        self.spine_node:setAnimation(0, "contract_first_enter", false)

        --self:UpdateLeaderContractInfo()
    end)

    --图书馆招募成功
    graphic:RegisterEvent("library_recruit_success", function(template_id)
        if not self.root_node:isVisible() then
            return
        end
        self:LoadContractInfo()

    end)

    --成功合成一枚灵魂石
    graphic:RegisterEvent("craft_soul_stone_success2", function(template_id)

        if not self.root_node:isVisible() then
            return
        end

        self:LoadContractInfo()
    end)
end


return mercenary_contract_panel
