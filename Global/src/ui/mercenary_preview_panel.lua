--阵容，列表，转生的快速预览佣兵信息panel
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"
local mercenary_config = config_manager.mercenary_config
local cooperative_skill_config = config_manager.cooperative_skill_config
local destiny_skill_config = config_manager.destiny_skill_config

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local destiny_logic = require "logic.destiny_weapon"
local user_logic = require "logic.user"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local spine_manager = require "util.spine_manager"

local client_constants = require "util.client_constants"

local MERCENARY_PREVIEW_SHOW_MOD = client_constants["MERCENARY_PREVIEW_SHOW_MOD"]  --preview 面板显示mod
local SKILL_BG_IMG_PATH = client_constants["SKILL_BG_IMG_PATH"]
local NO_SKILL_BG_IMG_PATH = client_constants["NO_SKILL_BG_IMG_PATH"]
local MERCENARY_MSGBOX = client_constants["MERCENARY_MSGBOX"]

local PLIST_TYPE = ccui.TextureResType.plistType

local platform_manager = require "logic.platform_manager"
local lang_constants = require "util.language_constants"

local MAX_SKILL_IMG = 5
local SKILL_TYPE =
{
    ["personal_skill"] = 1,   --个人技
    ["coop_skill1"] = 2, --合体技1
    ["coop_skill2"] = 3, --合体技2
    ["artifact_skill"] = 4, --宝具技
    ["contract_skill"] = 5,--契约被动

    ["destiny_skill"] = 1, --宿命武器技能
}

local mercenary_preview_panel = panel_prototype.New()
mercenary_preview_panel.__index = mercenary_preview_panel

function mercenary_preview_panel.New(root_node)
    local panel = {}
    if not root_node then
        panel.root_node = mercenary_preview_panel.meta_root_node:clone()
        panel.__is_add = true
    else
        panel.root_node = root_node
        panel.__is_add = false
    end
    return setmetatable(panel, mercenary_preview_panel)

end

function mercenary_preview_panel:InitMeta()
    local node = cc.CSLoader:createNode("ui/mercenary_preview_panel.csb")
    node:retain()

    self.meta_root_node = node

    self.meta_root_node:setCascadeColorEnabled(false)
    self.meta_root_node:setCascadeOpacityEnabled(false)
end

function mercenary_preview_panel:Init(mode, parent_node)
    self.mode = mode
    self.title_bg = self.root_node:getChildByName("title_bg")
    self.ex_prop_bg_img = self.title_bg:getChildByName("ex_prop_bg")
    self.name_text = self.title_bg:getChildByName("title")
    self.skill_name_text = self.title_bg:getChildByName("name")
    self.name_text_init_pos_x = self.name_text:getPositionX()

    --突破增加属性说明
    self.force_lv_add_property_bg_img = self.root_node:getChildByName("desc_ex_prop")
    self.force_lv_add_property_bg_img:setVisible(false)

    self.ex_prop_img = self.title_bg:getChildByName("ex_prop")
    self.ex_prop_type_img = self.ex_prop_img:getChildByName("icon")
    self.ex_prop_val_text = self.ex_prop_img:getChildByName("value")

    self.skill_node = self.root_node:getChildByName("skill_node")
    self.skill_node_pos_y = self.skill_node:getPositionY()

    self.cancel_btn = self.skill_node:getChildByName("cancel_btn")

    self.wakeup_desc_text = self.cancel_btn:getChildByName("desc")

    self.confirm_btn = self.skill_node:getChildByName("ok_btn")
    self.forge_desc_text = self.confirm_btn:getChildByName("desc")

    self.skill_imgs = {}
    self.skill_imgs_pos =  {}
    self.coop_skill_icons = {1, 2}

    for i = 1, MAX_SKILL_IMG do
        local skill_img = self.skill_node:getChildByName("skill" ..i)
        skill_img:setTouchEnabled(true)
        skill_img:setTag(i)
        self.skill_imgs[i] = skill_img

        self.skill_imgs_pos[i] = {}
        self.skill_imgs_pos[i].x = skill_img:getPositionX()
        self.skill_imgs_pos[i].y = skill_img:getPositionY()

        if i == 2 or i == 3 then
            self.coop_skill_icons[i - 1] = skill_img:getChildByName("coop_icon")
        end
    end

    --宝具技icon
    self.artifact_icon_img = self.skill_node:getChildByName("artifact_img")
    self.artifact_icon_img:ignoreContentAdaptWithSize(true)

    --宿命技icon
    self.desitiny_icon_img = self.skill_node:getChildByName("destiny_img")
    self.artifact_icon_img:ignoreContentAdaptWithSize(true)

    --选中
    self.skill_select_img = self.skill_node:getChildByName("select")
    self.skill_select_img:setVisible(false)

    self.skills_bg_img =  self.skill_node:getChildByName("skills_bg")
    self.destiny_name_text = self.skills_bg_img:getChildByName("destiny_name")
    self.change_desitiny_tip_text = self.skills_bg_img:getChildByName("tip")

    self.change_desitiny_tip_text:setString(lang_constants:Get("leader_switch_weapon"))

    local skill_desc_img = self.skill_node:getChildByName("skill_desc_shadow")
    local skill_desc_bg_node = self.skill_node:getChildByName("skill_desc_bg")
    self.skill_desc_text = skill_desc_bg_node:getChildByName("desc")

    self.view_coop_skill_text = skill_desc_bg_node:getChildByName("coop_desc")

    self.view_coop_skill_text:setString(lang_constants:Get("mercenary_coop_desc"))

    self.skill_desc_img = skill_desc_img
    self.skill_desc_img:setCascadeOpacityEnabled(false)
    self.skill_desc_img:setOpacity(255 * 0.5)
    
    
    self.leader_skill_info = {}
    self.skills_info = { {}, {}, {}, {}, {}} -- 分别保存个人技，合体技1，合体技2，宝具技

    --FYD 合体技已发动和未发动字体改小  
    local font_size = platform_manager:GetChannelInfo().coop_and_artifact_text_font_height or 24
    --合体技和宝具 是否满足发动条件动画
    self.coop_and_artifact_text = ccui.Text:create("", client_constants["FONT_FACE"], font_size) 
    skill_desc_bg_node:addChild(self.coop_and_artifact_text, 100)
    self.coop_and_artifact_text:setPosition(46, 22)
    self.coop_and_artifact_text:setAnchorPoint(0, 0.5)
    self.coop_and_artifact_text:setVisible(false)

    self.select_spine = spine_manager:GetNode("item_skill_choose")
    self.skill_node:addChild(self.select_spine, 100)
    self.select_spine:setVisible(false)
    self.select_spine:setAnimation(0, "animation", true)

    if self.__is_add then
        parent_node:addChild(self.root_node)
    end

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

--初始化图片的显示
function mercenary_preview_panel:InitImgVisible(is_leader)
    self.destiny_name_text:setVisible(is_leader)
    self.change_desitiny_tip_text:setVisible(is_leader)

    self.select_spine:setVisible(false)
    self.artifact_icon_img:setVisible(not is_leader)
    self.desitiny_icon_img:setVisible(is_leader)

    for i = 2, 4 do
        self.skill_imgs[i]:setVisible(not is_leader)
    end

    self.view_coop_skill_text:setVisible(false)

    for i = 1, 2 do
        self.coop_skill_icons[i]:setVisible(false)
    end

    self.skills_bg_img:setTouchEnabled(is_leader)
    self.skills_bg_img:setVisible(is_leader)
end

function mercenary_preview_panel:GetSkillNodePosY()
    return self.skill_node_pos_y
end

function mercenary_preview_panel:SetSkillNodePosY(y)
    self.skill_node:setPositionY(y or self.skill_node_pos_y)
end

--设定位置
function mercenary_preview_panel:SetSkillImgPositionX(padding_x)
    for i = 1, MAX_SKILL_IMG do
        local x = self.skill_imgs_pos[i].x + padding_x
        self.skill_imgs[i]:setPositionX(x)

        if i == 4 then
            self.artifact_icon_img:setPositionX(x)
        end
    end
end

function mercenary_preview_panel:InitData()
    self.ex_prop_val_text:setString("0")

    self.name_text:setString(lang_constants:Get("not_mercenary"))
    self.skill_name_text:setString(lang_constants:Get("not_skill"))
    self.skill_desc_text:setString(lang_constants:Get("not_skill_desc"))

    self.artifact_icon_img:loadTexture(client_constants["NO_SKILL_BG_IMG_PATH"], PLIST_TYPE)

    for i = 1, 4 do
        self.skill_imgs[i]:loadTexture(client_constants["NO_SKILL_BG_IMG_PATH"], PLIST_TYPE)
    end

    self.coop_and_artifact_text:setVisible(false)
    self.select_spine:setVisible(false)

    self.skill_type = 1
end

function mercenary_preview_panel:Show(mercenary_id, formation_id)
    local mercenary = troop_logic:GetMercenaryInfo(mercenary_id)

    if self.mode == MERCENARY_PREVIEW_SHOW_MOD['fire'] then
        self.cancel_btn:setVisible(false)
        self.confirm_btn:setVisible(false)
    end

    if not mercenary or mercenary_id == 0 then
        --没有佣兵
        self:InitData()
        self:InitImgVisible(false)
        self.can_select_skill = false
        return
    end

    self.formation_id = formation_id or troop_logic:GetCurFormationId()
    self.mercenary_id = mercenary_id

    self.name_text:setString(mercenary.template_info.name)

    self.is_leader = mercenary.is_leader
    self:InitImgVisible(self.is_leader)
    self.can_select_skill = true

    if self.is_leader then
        self.name_text:setString(troop_logic:GetLeaderName())
        self:LoadLeaderSkillInfo()
        if troop_logic:GetLeaderContractConfIndex() == 0 then
            self.skill_imgs[5]:setColor(panel_util:GetColor4B(0x7f7f7f))
        else
            self.skill_imgs[5]:setColor(panel_util:GetColor4B(0xffffff))
        end

    else
        self:ParseSkills(mercenary)
        if mercenary.contract_lv ~= 0 then
            self.skill_imgs[5]:setColor(panel_util:GetColor4B(0xffffff))
        else
            self.skill_imgs[5]:setColor(panel_util:GetColor4B(0x7f7f7f))
        end
    end
    self:UpdateProperty()
end

function mercenary_preview_panel:ParseSkills(mercenary)

    panel_util:ParseSkillInfo(mercenary.template_info.ID, self.skills_info)
    for i = 1, 4 do
        local info = self.skills_info[i]

        if info.active_num == 1 then
            info.name = string.format(lang_constants:Get("mercenary_skill_active_num"), info.name, info.active_num)
        end

        self.skill_imgs[i]:loadTexture(info.icon, PLIST_TYPE)

        --合体技的icon
        if i >= 2 and i <= 3 then
            self.coop_skill_icons[i - 1]:setVisible(info.has_skill)

        --宝具技
        elseif i == 4 then
            self.artifact_icon_img:setVisible(info.has_skill)
            if info.has_skill and info.artifact_icon then
                self.artifact_icon_img:loadTexture(info.artifact_icon, PLIST_TYPE)
            end

            info.can_use = mercenary.is_open_artifact

        elseif i == 5 then

        end
    end

    self.skills_info[5] = {}
    self.skills_info[5].name = ""
    self.skills_info[5].desc = ""
    self.skills_info[5].has_skill = true
    --默认定位到第一个拥有的技能
    local skill_type
    for i = 1, 4 do
        if self.skills_info[i].has_skill then
            skill_type = i
            break
        end
    end

    self.skill_type = skill_type or 1
    --如果此佣兵没有一个技能，则默认显示个人技
    if not skill_type then
        self.skill_name_text:setString(self.skills_info[1].name)
        self.skill_desc_text:setString(self.skills_info[1].desc)
    end

    self:ShowMercenarySkillDesc(self.skill_type)
end

--加载并显示主角宿命武器技能信息
function mercenary_preview_panel:LoadLeaderSkillInfo()
    self.coop_and_artifact_text:setVisible(false)

    local weapon_id = troop_logic:GetFormationWeaponId(self.formation_id)
    local has_equiped_weapon = weapon_id ~= 0

    self.desitiny_icon_img:setVisible(has_equiped_weapon)
    self.change_desitiny_tip_text:setVisible(has_equiped_weapon)

    local skill_name, skill_desc = "", ""
    if has_equiped_weapon then
        self.skill_imgs[SKILL_TYPE["destiny_skill"]]:loadTexture(SKILL_BG_IMG_PATH, PLIST_TYPE)

        --已装备宿命武器
        
        local conf = destiny_skill_config[weapon_id]
        local destiny_skill_info = panel_util:GetSkillInfo(conf.skill_id)
        self.desitiny_icon_img:loadTexture(client_constants["DESTINY_WEAPON_IMG"] .. weapon_id .. ".png", PLIST_TYPE)

        skill_name = string.format(lang_constants:Get("mercenary_destiny_skill_name"), destiny_skill_info.name)
        skill_desc = destiny_skill_info.desc

        self.destiny_name_text:setString(conf.name)
        self.skills_info[1].has_skill = true

    else
        self.destiny_name_text:setString(lang_constants:Get("mercenary_no_destiny_weapon"))

        self.skill_imgs[SKILL_TYPE["destiny_skill"]]:loadTexture(NO_SKILL_BG_IMG_PATH, PLIST_TYPE)
        self.artifact_icon_img:setVisible(false)

        skill_name = lang_constants:Get("mercenary_no_destiny_weapon")
        skill_desc = lang_constants:Get("leader_no_skill")

        self.skills_info[1].has_skill = false
    end

    self.skills_info[1].name = skill_name
    self.skills_info[1].desc = skill_desc

    self.skills_info[5].has_skill = true
    local title, contract_desc = panel_util:GetLeaderContractInfo()
    self.skills_info[5].name = title
    self.skills_info[5].desc = contract_desc

    self.skill_name_text:setString(skill_name)
    self.skill_desc_text:setString(skill_desc)
end

function mercenary_preview_panel:SetCanShowFloatPanel(can_show_float)
    self.can_show_float = can_show_float
end
--技能描述
function mercenary_preview_panel:ShowMercenarySkillDesc(skill_type, pos)
    local skill_info = self.skills_info[skill_type]
    --FYD  技能描述字體減小
    local font_size =  platform_manager:GetChannelInfo().skill_desc_text_font
    if font_size then
      self.skill_desc_text:setFontSize(font_size) 
    end
    
    if not skill_info.has_skill then
        return
    end

    if self.is_leader then

    else
        if skill_type == SKILL_TYPE["coop_skill1"] or skill_type == SKILL_TYPE["coop_skill2"] then
            self.view_coop_skill_text:setVisible(true)
        else
            self.view_coop_skill_text:setVisible(false)
        end

        if skill_type == SKILL_TYPE["personal_skill"] then
            self.coop_and_artifact_text:setVisible(false)

        elseif skill_type == SKILL_TYPE["artifact_skill"] then
            self.coop_and_artifact_text:setVisible(true)
            local str = ""
            local color
            if skill_info.can_use then
                str = lang_constants:Get("mercenary_open_artifact")
                color = 0x61E622
            else
                str = lang_constants:Get("mercenary_not_open_artifact")
                color = 0xE66221
            end
            self.coop_and_artifact_text:setString(str)
            self.coop_and_artifact_text:setColor(panel_util:GetColor4B(color))

        elseif skill_type == SKILL_TYPE["contract_skill"] then
            self.coop_and_artifact_text:setVisible(false)
            local mercenary = troop_logic:GetMercenaryInfo(self.mercenary_id)

            skill_info.name = lang_constants:Get("mercenary_contract_add")

            if mercenary.contract_lv > 0 then
                skill_info.desc = panel_util:GetContactPropertyDesc(self.mercenary_id)
            else
                skill_info.desc = lang_constants:Get("mercenary_contract_state2")
            end

        else
            self.coop_and_artifact_text:setVisible(true)
            local str = ""
            local color

            if skill_info.can_use then
                str = lang_constants:Get("coop_skill_activated")
                color = 0x61E622
            else
                color = 0xE66221
                str = lang_constants:Get("coop_skill_unactivated")
            end

            self.coop_and_artifact_text:setString(str)
            self.coop_and_artifact_text:setColor(panel_util:GetColor4B(color))
        end
    end

    self.select_spine:setVisible(skill_info.has_skill)
    self.select_spine:setPosition(self.skill_imgs[skill_type]:getPositionX(), self.skill_imgs[skill_type]:getPositionY())

    self.skill_name_text:setString(skill_info.name)
    self.skill_desc_text:setString(skill_info.desc)

    if pos and self.can_show_float then

        local is_coop_skill, skill_id = false, self.skills_info[skill_type].id
        if skill_type == SKILL_TYPE["coop_skill1"] or skill_type == SKILL_TYPE["coop_skill2"]  and skill_id ~= 0 then
            is_coop_skill = true
        end

        if is_coop_skill then
            --显示名单
            graphic:DispatchEvent("show_floating_panel", skill_info.name, skill_info.desc, pos.x, pos.y, true, self.formation_id, skill_id)
        else
            --不显示名单
            graphic:DispatchEvent("show_floating_panel", skill_info.name, skill_info.desc, pos.x, pos.y, true)
        end
    end

end

--更新属性
function mercenary_preview_panel:UpdateProperty()
    local mercenary = troop_logic:GetMercenaryInfo(self.mercenary_id)

    if not mercenary then
        return
    end

    if self.mode == MERCENARY_PREVIEW_SHOW_MOD['compare'] then
        self.forge_desc_text:setString(lang_constants:Get("common_confirm"))
        self.wakeup_desc_text:setString(lang_constants:Get("common_cancel"))
    else
        self.wakeup_desc_text:setString(string.format(lang_constants:Get("mercenary_wakeup_btn_text"), mercenary.wakeup, mercenary.template_info.max_wakeup))
        if mercenary.is_leader then
            self.forge_desc_text:setString(string.format(lang_constants:Get("mercenary_forge_btn_text"), destiny_logic:GetWeaponLevel(), constants["MAX_DESTINY_WEAPON_LV"]))
        else
            self.forge_desc_text:setString(string.format(lang_constants:Get("mercenary_forge_btn_text"), mercenary.weapon_lv, constants["MAX_WEAPON_LV"]))
        end
    end

    if mercenary.is_leader or not mercenary.template_info.can_upgrade_force then
        self.name_text:setPositionX(self.name_text_init_pos_x - 28)
        self.ex_prop_bg_img:setVisible(false)
        --self.property_node:setVisible(false)
        self.ex_prop_img:setVisible(false)
    else
        self.ex_prop_bg_img:setVisible(true)
        self.ex_prop_img:setVisible(true)

        self.name_text:setPositionX(self.name_text_init_pos_x)
        self.ex_prop_val_text:setString(tonumber(mercenary.ex_prop_val* constants["CONTRACT_FORCE_UP"][mercenary.contract_lv]))
        self.ex_prop_val_text:setOpacity(mercenary.force_lv == constants["MAX_FORCE_LEVEL"] and 255 or 51)
        self.ex_prop_type_img:loadTexture(client_constants.MERCENARY_PROPERTY_ICON[mercenary.ex_prop_type], PLIST_TYPE)
    
    end
end

function mercenary_preview_panel:RegisterEvent()
    graphic:RegisterEvent("update_mercenary_info", function(mercenary_id)
        --强化成功, 开启宝具，觉醒成功，限界突破
        if not self.root_node:isVisible() or not self.root_node:getParent():isVisible() then
            return
        end

        if mercenary_id ~= self.mercenary_id then
            return
        end

        self:UpdateProperty()
    end)

    graphic:RegisterEvent("update_panel_leader_name", function(name)
        if not self.root_node:isVisible() or not self.is_leader then
            return
        end

        self.name_text:setString(name)
    end)
end

function mercenary_preview_panel:RegisterWidgetEvent()
    --选中并查看某种技能
    local select_skill = function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            if self.can_select_skill then
                audio_manager:PlayEffect("click")
                self.skill_type = widget:getTag()
                self:ShowMercenarySkillDesc(widget:getTag(),  widget:getTouchBeganPosition())
            end
        elseif  event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            graphic:DispatchEvent("hide_floating_panel")
        end
    end

    for i = 1, MAX_SKILL_IMG do
        local skill_img = self.skill_imgs[i]
        skill_img:setTag(i)
        skill_img:setTouchEnabled(true)
        skill_img:addTouchEventListener(select_skill)
    end

    --宿命武器列表
    self.skills_bg_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if self.is_leader then
                if destiny_logic:HasDestinyWeapon() then
                    graphic:DispatchEvent("show_world_sub_panel", "destiny_weapon_list_panel", self.formation_id)
                end
            end
        end
    end)

    --查看合体技人物名单
    self.skill_desc_img:setTouchEnabled(true)
    self.skill_desc_img:addTouchEventListener(function(widget, event_type)
        if not self.can_show_float then
            if event_type == ccui.TouchEventType.began then
                if self.skill_type == SKILL_TYPE["coop_skill1"] or self.skill_type == SKILL_TYPE["coop_skill2"] then
                    local skill_id = self.skills_info[self.skill_type].id
                    if skill_id ~= 0 and not self.is_leader then
                        graphic:DispatchEvent("show_floating_panel", nil, nil, 220, 800, false, self.formation_id, skill_id)
                    end
                end

            elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
                graphic:DispatchEvent("hide_floating_panel")
            end
        end
    end)

    self.cancel_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            panel_util:ShowMercenaryMsgBox(MERCENARY_MSGBOX["wakeup"], self.mercenary_id, self.is_leader)
        end
    end)

    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["forge"]) then
                if self.is_leader then
                    graphic:DispatchEvent("show_world_sub_panel", "destiny_forge_panel", self.formation_id)
                else
                    graphic:DispatchEvent("show_world_sub_panel", "mercenary_weapon_panel", self.mercenary_id, false)
                end
            end
        end
    end)

    -- self.level_bg_img:addTouchEventListener(function(widget, event_type)
    --     if event_type == ccui.TouchEventType.began then

    --         self.force_lv_add_property_bg_img:setVisible(true)

    --     elseif event_type == ccui.TouchEventType.ended then
    --         self.force_lv_add_property_bg_img:setVisible(false)

    --     elseif event_type == ccui.TouchEventType.canceled then
    --         self.force_lv_add_property_bg_img:setVisible(false)

    --     end
    -- end)

end

do
    mercenary_preview_panel:InitMeta()
end

return mercenary_preview_panel
