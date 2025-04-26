local feature_config = require "logic.feature_config"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"

local adventure_logic = require "logic.adventure"
local client_constants = require "util.client_constants"

local panel_prototype = require "ui.panel"
local lang_constants = require "util.language_constants"

local mercenary_config = config_manager.mercenary_config
local soul_stone_config = config_manager.mercenary_soul_stone_config
local resource_config = config_manager.resource_config
local icon_panel = require "ui.icon_panel"

local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]
local MERCENARY_LIST_SHOW_MODE = client_constants["MERCENARY_LIST_SHOW_MODE"]

local PERMANENT_MARK = constants["PERMANENT_MARK"]
local panel_util = require "ui.panel_util"

local spine_manager = require "util.spine_manager"


local PLIST_TYPE = ccui.TextureResType.plistType
local first_row_begin_x =  121
local first_row_begin_y =  257

local second_row_begin_x =  239
local second_row_begin_y =  173

local internal_x = 80

local TAB_TYPE =
{
    ["recruit"] = 1,
    ["craft"] = 2,
    ["res"] = 3,
}

local CRAFT_COST_RESOURCE = client_constants["CRAFT_COST_RESOURCE"]
local mercenary_soul_stone_panel = panel_prototype.New(true)

function mercenary_soul_stone_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mercenary_soul_panel.csb")
    local root_node = self.root_node

    self.recruit_tab = root_node:getChildByName("recruit_tab")
    self.recruit_tab:setTag(TAB_TYPE["recruit"])
    self.craft_tab = root_node:getChildByName("craft_tab")
    self.craft_tab:setTag(TAB_TYPE["craft"])

    self.recruit_node = root_node:getChildByName("recruit_node")
    self.craft_node = root_node:getChildByName("craft_node")

    self.role_bg_img = self.recruit_node:getChildByName("role_bg")
    self.role_icon_img = self.role_bg_img:getChildByName("icon")
    self.role_icon_img:ignoreContentAdaptWithSize(true)
    self.role_icon_img:setScale(2, 2)

    self.soul_stone_num_text = self.recruit_node:getChildByName("soul_value")
    self.soul_chip_num_text = self.recruit_node:getChildByName("honour_value")

    self.soul_stone_desc_text = self.craft_node:getChildByName("soul_desc")
    self.soul_stone_num2_text = self.craft_node:getChildByName("soul_num_desc")

    self.cant_craft_desc_text = self.craft_node:getChildByName("desc")
    self.cant_craft_desc_text:setVisible(false)
    self.craft_cost_sub_panels = {}

    self.craft_cost_node = self.craft_node:getChildByName("cost_node")
    --魂骨
    self.soul_bone_name_text = self.recruit_node:getChildByName("soul_bone6")
    self.soul_bone_icon_img = self.recruit_node:getChildByName("soul_bone_icon6")
    self.soul_bone_value = self.recruit_node:getChildByName("honour_value_0")

    self.soul_bone_name_text:setVisible(feature_config:IsFeatureOpen("sign_contract"))
    self.soul_bone_icon_img:setVisible(feature_config:IsFeatureOpen("sign_contract"))
    self.soul_bone_value:setVisible(feature_config:IsFeatureOpen("sign_contract"))

    for i = 1, 7 do
        local sub_panel = icon_panel.New()
        sub_panel:Init(self.craft_cost_node)
        if i <= 5 then
            sub_panel.root_node:setPosition(first_row_begin_x + (i - 1) * internal_x, first_row_begin_y)
        else
            sub_panel.root_node:setPosition(second_row_begin_x + (i - 1 - 5) * internal_x, second_row_begin_y)
        end
        sub_panel.root_node:setVisible(true)

        self.craft_cost_sub_panels[i] =  sub_panel
    end

    self.craft_cost_node:setVisible(true)

    self.root_node:setVisible(false)

    self.confirm_btn = root_node:getChildByName("ok_btn")
    self.close_btn = root_node:getChildByName("close_btn")
    self.close_btn:setLocalZOrder(110)

    self.spine_node = spine_manager:GetNode("soul_compose", 1.0, true)
    self.spine_node:setPosition(self.craft_node:getChildByName("iconbg"):getPosition())
    self.spine_node:setLocalZOrder(200)
    self.craft_node:addChild(self.spine_node)

    self.spine_node:setVisible(false)
    self.spine_node:registerSpineEventHandler(function(event)
        self.craft_animation = false
        self.spine_node:setVisible(false)
        self.spine_node:setToSetupPose()
        self:LoadCraftInfo()
        graphic:DispatchEvent("craft_soul_stone_success2", self.template_id)

    end, sp.EventType.ANIMATION_COMPLETE)


    self:RegisterWidget()
    self:RegisterWidgetEvent()
    self.craft_tab:setVisible(feature_config:IsFeatureOpen("craft_soul_stone"))
end

function mercenary_soul_stone_panel:Show(template_id, tab_type)
    self.template_id = template_id
    self:UpdateTabStatus(TAB_TYPE[tab_type])
    self.root_node:setVisible(true)
end

function mercenary_soul_stone_panel:UpdateTabStatus(tab_type)
    self.cur_tab_type = tab_type

    if tab_type == TAB_TYPE["recruit"] then
        self.recruit_tab:setColor(panel_util:GetColor4B(0xFFFFFF))
        self.recruit_tab:setLocalZOrder(101)
        self.craft_tab:setColor(panel_util:GetColor4B(0x7F7F7F))
        self.craft_tab:setLocalZOrder(100)

        self.recruit_node:setVisible(true)
        self.craft_node:setVisible(false)

        self:LoadRecruitInfo()
    elseif tab_type == TAB_TYPE["craft"] then
        self.craft_tab:setColor(panel_util:GetColor4B(0xFFFFFF))
        self.craft_tab:setLocalZOrder(101)
        self.recruit_tab:setColor(panel_util:GetColor4B(0x7F7F7F))
        self.recruit_tab:setLocalZOrder(100)
        self.recruit_node:setVisible(false)
        self.craft_node:setVisible(true)
    --    self:LoadCraftInfo()
    -- elseif tab_type == TAB_TYPE["res"] then
    --     self.craft_tab:setColor(panel_util:GetColor4B(0xFFFFFF))
    --     self.craft_tab:setLocalZOrder(101)
    --     self.recruit_tab:setColor(panel_util:GetColor4B(0x7F7F7F))
    --     self.recruit_tab:setLocalZOrder(100)
    --     self.recruit_node:setVisible(false)
    --     self.craft_node:setVisible(true)
    --     self:LoadResInfo()
    --     print("LoadRESInfo2")
    end
end

function mercenary_soul_stone_panel:LoadRecruitInfo()
    local template_info = mercenary_config[self.template_id]
    self.role_bg_img:loadTexture(client_constants["MERCENARY_BG_SPRITE"][template_info.quality], PLIST_TYPE)
    self.role_icon_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. template_info.sprite .. ".png", PLIST_TYPE)

    -- self.soul_desc_text:setString(string.format(lang_constants:Get("mercenary_whos_soul_cyrstal"), template_info.name))
    local count = troop_logic:GetMercenaryLibraryCount(self.template_id) or 0
    if count == 0 then
        self.soul_stone_num_text:setColor(panel_util:GetColor4B(0xf87f26))
    else
        self.soul_stone_num_text:setColor(panel_util:GetColor4B(0xffffff))
    end
    self.soul_stone_num_text:setString(tostring(count) .. "/1")

    --解雇的2倍
    local need_soul_chip = math.ceil(template_info.soul_chip * constants["LIBRARY_COST_SOUL_CHIP_MULTI"])
    local is_enough = resource_logic:CheckResourceNum(constants.RESOURCE_TYPE["soul_chip"], need_soul_chip, false)
    if is_enough then
        self.soul_chip_num_text:setColor(panel_util:GetColor4B(0xffffff))
    else
        self.soul_chip_num_text:setColor(panel_util:GetColor4B(0xf87f26))
    end
    
    local s = resource_logic:GetResourceNum(constants.RESOURCE_TYPE["soul_chip"]) .. "/" .. tostring(need_soul_chip)
    self.soul_chip_num_text:setString(s)
    
    if is_enough and count > 0 then
        self.confirm_btn:setTitleText(lang_constants:Get("library_recruit_confirm"))
        self.confirm_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
    else
        self.confirm_btn:setTitleText(lang_constants:Get("cant_recruit"))
        self.confirm_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
    end
    --魂骨
    local res_name = "soul_bone" .. (template_info.quality)
    local need_soul_bone = math.ceil(template_info.soul_bone * constants["COST_SOUL_BONE_MULTI"])

    local is_enough = resource_logic:CheckResourceNum(constants.RESOURCE_TYPE[res_name], need_soul_bone, false)

    local res_temp_id = 44 + template_info.quality
    local  res_confg  =  config_manager.resource_config[res_temp_id] --constants.RESOURCE_TYPE_NAME[constants.RESOURCE_TYPE[res_name]]

    self.soul_bone_name_text:setString(res_confg.name)    --soul_bone_name_list[template_info.quality])
    local res_name = "soul_bone" .. (template_info.quality)
    local soul_bone_num = resource_logic:GetResourcenNumByName(res_name) .. "/" .. tostring(need_soul_bone)
    
     if is_enough then
        self.soul_bone_value:setColor(panel_util:GetColor4B(0xffffff))
    else
        self.soul_bone_value:setColor(panel_util:GetColor4B(0xf87f26))
    end


    self.soul_bone_value:setString(soul_bone_num)
    self.soul_bone_icon_img:loadTexture(client_constants["SOUL_BONE_SPRITE"][template_info.quality], PLIST_TYPE)
    if is_enough then
        self.confirm_btn:setTitleText(lang_constants:Get("library_recruit_confirm"))
        self.confirm_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
    else
        self.confirm_btn:setTitleText(lang_constants:Get("cant_recruit"))
        self.confirm_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
    end
    
end

function mercenary_soul_stone_panel:LoadResInfo()

    local template_info = resource_config[self.template_id]
    self.soul_stone_desc_text:setString(string.format(lang_constants:Get("mercenary_whos_soul_cyrstal"), template_info.name))


end

function mercenary_soul_stone_panel:LoadCraftInfo()

   local template_info = mercenary_config[self.template_id]
    

    self.soul_stone_desc_text:setString(string.format(lang_constants:Get("mercenary_whos_soul_cyrstal"), template_info.name))

    local count = troop_logic:GetMercenaryLibraryCount(template_info.ID)
    local str = string.format(lang_constants:Get("soul_stone_num"), count or 0)
    self.soul_stone_num2_text:setString(str)

    if template_info.is_unique then
        self.craft_cost_node:setVisible(false)
        self.cant_craft_desc_text:setVisible(true)
        self.cant_craft_desc_text:setString(lang_constants:Get("cant_craft"))

        self.confirm_btn:setTitleText(lang_constants:Get("cant_craft_confirm"))
        self.confirm_btn:setColor(panel_util:GetColor4B(0x7F7F7F))

    elseif count then
        self.craft_cost_node:setVisible(true)
        self.cant_craft_desc_text:setVisible(false)
        local soul_stone_conf  = soul_stone_config[self.template_id]

        local is_enough = true
        for i = 1, 7 do
            local resource_name = CRAFT_COST_RESOURCE[i]
            self.craft_cost_sub_panels[i]:Show(constants.REWARD_TYPE["resource"], constants["RESOURCE_TYPE"][resource_name], soul_stone_conf[resource_name], true, false)

            if not resource_logic:CheckResourceNum(constants.RESOURCE_TYPE[resource_name], soul_stone_conf[resource_name], false) then
                is_enough = false
            end
        end

        if is_enough then
            self.confirm_btn:setTitleText(lang_constants:Get("craft_confirm"))
            self.confirm_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
        else
            self.confirm_btn:setTitleText(lang_constants:Get("craft_prompt2"))
            self.confirm_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
            
        end
    else
        self.craft_cost_node:setVisible(false)
        self.cant_craft_desc_text:setVisible(true)
        self.cant_craft_desc_text:setString(lang_constants:Get("not_craft"))

        self.confirm_btn:setTitleText(lang_constants:Get("cant_craft_confirm"))
        self.confirm_btn:setColor(panel_util:GetColor4B(0x7F7F7F))

    end
end

function mercenary_soul_stone_panel:RegisterWidget()
    graphic:RegisterEvent("craft_soul_stone_success", function(template_id)

        if not self.root_node:isVisible() or self.cur_tab_type ~= TAB_TYPE["craft"] or self.template_id ~= template_id then
            return
        end
        audio_manager:PlayEffect("soul_stone_success")
        self.spine_node:setVisible(true)
        self.craft_animation = true
        self.spine_node:setAnimation(0, "animation", false)
    end)

    graphic:RegisterEvent("library_recruit_success", function(template_id)
        if not self.root_node:isVisible() or self.cur_tab_type ~= TAB_TYPE["recruit"] or self.template_id ~= template_id then
            return
        end
        graphic:DispatchEvent("show_world_sub_panel", "reward_panel")

        self:LoadRecruitInfo()
    end)

end

function mercenary_soul_stone_panel:RegisterWidgetEvent()
    local click_tab_method = function(widget, event_type)
    if event_type == ccui.TouchEventType.ended then
        audio_manager:PlayEffect("click")
        local index = widget:getTag()
        self:UpdateTabStatus(index)
    end
    end

    self.recruit_tab:addTouchEventListener(click_tab_method)
    self.craft_tab:addTouchEventListener(click_tab_method)

     --关掉召回面板
    self.close_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.craft_animation then
                return
            end
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            -- self:Hide()
        end
    end)

     --召回
    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then

            if self.craft_animation then
                return
            end

            if self.cur_tab_type == TAB_TYPE["recruit"] then
                troop_logic:LibraryRecruit(self.template_id)
            else
                troop_logic:CraftSoulStone(self.template_id)
            end
        end
    end)
end

return mercenary_soul_stone_panel

