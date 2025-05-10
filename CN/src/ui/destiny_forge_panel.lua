--宿命武器

local config_manager = require "logic.config_manager"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local audio_manager = require "util.audio_manager"
local platform_manager = require "logic.platform_manager"
local destiny_forge_config = config_manager.destiny_forge_config
local destiny_skill_config = config_manager.destiny_skill_config

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local destiny_logic = require "logic.destiny_weapon"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local resource_logic = require "logic.resource"

local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]
local DESTINY_WEAPON_IS_ACTIVED_ICON = "icon/mercenarylist/weaponbox_leadrole_point2.png"
local DESTINY_WEAPON_NOT_ACTIVED_ICON = "icon/mercenarylist/weaponbox_leadrole_point1.png"
local icon_panel = require "ui.icon_panel"
local COST_SUB_PANEL_POS_Y = 391.00

local PLIST_TYPE = ccui.TextureResType.plistType

local destiny_forge_panel = panel_prototype.New(true)

function destiny_forge_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/destiny_forge_panel.csb")

    local root_node = self.root_node

    self.close_btn = root_node:getChildByName("close_btn")
    self.confirm_forge_btn = root_node:getChildByName("confirm_forge_btn")
    self.more_destiny_weapon_btn = root_node:getChildByName("more_destiny_btn")

    self.title_text = root_node:getChildByName("title_text")
    local channel = platform_manager:GetChannelInfo()
    if channel.meta_channel ~= "txwy_dny" then
        --东南亚渠道不加描边
        panel_util:SetTextOutline(self.title_text)
    end
    

    local info_node = root_node:getChildByName("info")
    self.forge_lv_desc_text = info_node:getChildByName("forge_lv_desc")
    self.forge_lv_text = info_node:getChildByName("forge_lv")

    self.weapon_texts = {}
    self.weapon_icon_imgs = {}
    for i = 1, constants["MAX_DESTINY_WEAPON_LV"] do
        local node = info_node:getChildByName("weapon" .. i)
        self.weapon_texts[i] = node:getChildByName("desc")
        self.weapon_icon_imgs[i] = node:getChildByName("icon")
        if channel.meta_channel ~= "txwy_dny" then
            --东南亚渠道不加描边
            panel_util:SetTextOutline(self.weapon_texts[i], 0x9e966e)
        end
    end

    --
    local upgrade_level_node = info_node:getChildByName("upgrade_level_node")

    self.need_forge_weapon_icon_img = upgrade_level_node:getChildByName("weapon_icon")

    --缺少一把宿命武器
    self.prompt1_text = upgrade_level_node:getChildByName("prompt")

    --战斗力提升
    self.prompt4_text = upgrade_level_node:getChildByName("prompt4")

    --当前提升战斗力百分比
    self.cur_add_bp_rate_text = upgrade_level_node:getChildByName("add_bp_rate")

    --下一等级提升战斗力百分比
    self.next_add_bp_rate_text = upgrade_level_node:getChildByName("next_add_bp_rate")


    self.upgrade_level_node = upgrade_level_node

    --资源消耗
    local cost_node = root_node:getChildByName("cost")
    --COST
    self.cost_sub_panels = {1, 2, 3, 4, 5}
    for i = 1, constants["MAX_DESTINY_FORGE_COST_RESOURCE_TYPE"] do
        local cost_sub_panel = icon_panel.New()
        cost_sub_panel:Init(cost_node)
        self.cost_sub_panels[i] = cost_sub_panel
    end
    self.cost_node = cost_node

    self.max_level_prompt_text = root_node:getChildByName("max_level_prompt")
    panel_util:SetTextOutline(self.max_level_prompt_text)
    self.max_level_prompt_text:setVisible(false)

    --template:setVisible(false)
    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function destiny_forge_panel:Show(formation_id)
    self.root_node:setVisible(true)

    self.formation_id = formation_id or self.formation_id

    local leader = troop_logic:GetLeader()
    local lv = destiny_logic:GetWeaponLevel()
    self.costInfo = {} --消耗资源的id 和 num
    local weapon_lv, weapon_num = destiny_logic:GetCurWeaponInfo()
    self.forge_lv_text:setString(lang_constants:Get("level_shot_string") .. weapon_lv .. "/" .. constants["MAX_DESTINY_WEAPON_LV"])

    --满级状态
    if weapon_lv == constants["MAX_DESTINY_WEAPON_LV"] then
        self.cost_node:setVisible(true)

        for i = 1, constants["MAX_DESTINY_FORGE_COST_RESOURCE_TYPE"] do
            self.cost_sub_panels[i]:Hide()
        end

        self.max_level_prompt_text:setVisible(true)

        self.forge_lv_text:setColor(panel_util:GetColor4B(0xffde00))
        panel_util:SetTextOutline(self.forge_lv_text)
        self.forge_lv_text:setPositionX(self.forge_lv_desc_text:getPositionX() + self.forge_lv_desc_text:getContentSize().width / 2 + 20)

        self.forge_lv_desc_text:setColor(panel_util:GetColor4B(0xffde00))
        panel_util:SetTextOutline(self.forge_lv_desc_text)

        self.confirm_forge_btn:setTouchEnabled(false)

        self.upgrade_level_node:setVisible(false)

    else
        self.upgrade_level_node:setVisible(true)

        self.cur_add_bp_rate_text:setString(destiny_forge_config[weapon_lv + 1]["bp_factor"]  .. "%")
        self.next_add_bp_rate_text:setString(destiny_forge_config[weapon_lv + 2]["bp_factor"] .. "%")

        local weapon_ids = destiny_logic:GetWeaponIds()

        --已经拥有的武器
        for i, weapon_id in pairs(weapon_ids) do
            if i <= weapon_lv then
                panel_util:SetTextOutline(self.weapon_texts[weapon_id])
                self.weapon_texts[weapon_id]:setColor(panel_util:GetColor4B(0xffffff))
                self.weapon_icon_imgs[weapon_id]:loadTexture(DESTINY_WEAPON_IS_ACTIVED_ICON, PLIST_TYPE)
                self.weapon_icon_imgs[weapon_id]:setScale(1, 1)


            elseif i == weapon_lv + 1 then
                self.weapon_icon_imgs[weapon_id]:loadTexture(DESTINY_WEAPON_NOT_ACTIVED_ICON, PLIST_TYPE)
                self.weapon_icon_imgs[weapon_id]:setScale(2, 2)

                self.need_forge_weapon_icon_img:setVisible(true)
                self.prompt1_text:setString(string.format(lang_constants:Get("destiny_do_forge"), destiny_skill_config[weapon_id]["name"], weapon_lv+1))

                self.need_forge_weapon_icon_img:loadTexture(destiny_skill_config[weapon_id]["icon"], PLIST_TYPE)
                break
            end
        end

        --从weapon_lv + 1 开始
        for weapon_id = 1, constants["MAX_DESTINY_WEAPON_LV"] do
            local is_actived, index = destiny_logic:IsWeaponActived(weapon_id)

            if index and index > weapon_lv + 1 then
                self.weapon_icon_imgs[weapon_id]:setScale(1, 1)
                self.weapon_icon_imgs[weapon_id]:loadTexture(DESTINY_WEAPON_NOT_ACTIVED_ICON, PLIST_TYPE)
            end
        end

        if weapon_num == weapon_lv then
            self.prompt1_text:setString(string.format(lang_constants:Get("destiny_lack_weapon"), weapon_lv+1))
            self.need_forge_weapon_icon_img:setVisible(false)
        end
        
        local config = destiny_forge_config[weapon_lv + 1]
        local cost_type_num, resource_is_enough, resource_havre_params = panel_util:LoadCostResourceInfo(config, self.cost_sub_panels, COST_SUB_PANEL_POS_Y, constants["MAX_DESTINY_FORGE_COST_RESOURCE_TYPE"], nil, true)

        for k,v in pairs(resource_havre_params) do --根据资源字段 找出id 和 个数 （资源跳转）
            local cost = {}
            cost["resourceId"] = constants["RESOURCE_TYPE"][v]
            cost["costNum"] = config[v]
            table.insert(self.costInfo,cost)
        end
    end

    self.show_forge_animation = false
end


function destiny_forge_panel:Update(elapsed_time)
    --[[
    if self.show_forge_animation then
        local percent = self.forge_lbar:getPercent()

        percent = percent + elapsed_time * 40

        if percent >= 75 then
            percent = 75
            self.show_forge_animation = false
            self.forge_btn:setEnabled(true)
            self.close_btn:setEnabled(true)

            self:LoadInfo()
        end

        self.light_img:setPositionX(self.forge_lbar:getPositionX() + self.forge_effect_width * ( percent / 100 -  0.5 ) )
        self.forge_lbar:setPercent(percent)
    end
    ]]--
end


function destiny_forge_panel:RegisterEvent()

    graphic:RegisterEvent("upgrade_leader_weapon_lv", function()

        if not self.root_node:isVisible() then
            return
        end
        self.show_forge_animation = true
        self:Show()
    end)

    graphic:RegisterEvent("update_resource_list", function()
        if not self.root_node:isVisible() then
            return
        end
        self:RefreshResource()
    end)
end

function destiny_forge_panel:RegisterWidgetEvent()

    self.confirm_forge_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            destiny_logic:ForgeWeapon(self.costInfo)
        end
    end)

    panel_util:RegisterCloseMsgbox(self.close_btn, "destiny_forge_panel")

    self.more_destiny_weapon_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "destiny_weapon_list_panel", self.formation_id)
        end
    end)
end

function destiny_forge_panel:RefreshResource()
    if self.cost_sub_panels then
        for k,v in pairs(self.cost_sub_panels) do
            local resourceType = v:GetIconResourceType()
            if resource_logic:IsResourceUpdated(resourceType) then
                v:SetTextStatus(resourceType)
            end
        end
    end
end

return destiny_forge_panel
