local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local spine_manager = require "util.spine_manager"
local rune_logic = require "logic.rune"

local rune_config = config_manager.rune_config
local rune_exp_config = config_manager.rune_exp_config

local PLIST_TYPE = ccui.TextureResType.plistType

local BAG_CELL_COL = 5

local PROPERTY_NUM = 4

local exp_rune_sub_panel = panel_prototype.New()
exp_rune_sub_panel.__index = exp_rune_sub_panel

function exp_rune_sub_panel.New()
    return setmetatable({}, exp_rune_sub_panel)
end

function exp_rune_sub_panel:Init(root_node)
    self.root_node = root_node
    self.icon_img = self.root_node:getChildByName("rune_icon")
    self.bg_img = self.root_node:getChildByName("graph")

    self.top_quality_icon = self.root_node:getChildByName("top_quality")
    self.equipped_icon = self.root_node:getChildByName("equipped_icon")
    self.level_text = self.root_node:getChildByName("level")
    self.level_text:setLocalZOrder(1)
    panel_util:SetTextOutline(self.level_text, 0x000, 2)

    self.equipped_icon:setVisible(false)
    self.top_quality_icon:setVisible(false)

    self.spine_node = spine_manager:GetNode("fuwen", 1.0, true)
    self.spine_node:setScale(2)
    self.spine_node:setPosition(cc.p(self.root_node:getContentSize().width / 2, self.root_node:getContentSize().height / 2))
    self.root_node:addChild(self.spine_node)
    self.spine_node:setTimeScale(1.0)
end

function exp_rune_sub_panel:Show(rune_info)
    self.rune_info = rune_info
    
    if rune_info then
        self.icon_img:loadTexture(self.rune_info.template_info.icon, PLIST_TYPE)
        self.bg_img:setVisible(true)
        self.icon_img:setVisible(true)
        self.top_quality_icon:setVisible(self.rune_info.template_info.quality == constants["MAX_RUNE_QUALITY"])
        self.equipped_icon:setVisible(self.rune_info.equip_pos > 0)
        self.level_text:setString(string.format(lang_constants:Get("rune_level"), self.rune_info.level))
    else
        self.bg_img:setVisible(false)
        self.icon_img:setVisible(false)
        self.top_quality_icon:setVisible(false)
        self.equipped_icon:setVisible(false)
        self.level_text:setString("")
    end

    self.root_node:setVisible(true)
end

function exp_rune_sub_panel:ShowDisappearAnimation(delayTime)
    local seq_action = cc.Sequence:create(  cc.DelayTime:create(delayTime),
                                            cc.CallFunc:create(function()
                                                self.spine_node:setAnimation(0, "clear", false)
                                            end),
                                            cc.DelayTime:create(0.1),
                                            cc.CallFunc:create(function()
                                                self:Show()
                                            end))

    self.root_node:runAction(seq_action)
end

local rune_upgrade_panel = panel_prototype.New(true)
function rune_upgrade_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/rune_levelup_panel.csb")

    local rune_info_node = self.root_node:getChildByName("rune_info")
    self.rune_name_text = rune_info_node:getChildByName("rune_name")
    self.rune_level_text = rune_info_node:getChildByName("value1")
    self.preview_rune_level_text = rune_info_node:getChildByName("value2")
    self.arrow_img = rune_info_node:getChildByName("arrow")
    self.exp_text = rune_info_node:getChildByName("desc")
    self.preview_exp_text = rune_info_node:getChildByName("desc1")
    self.rune_bg_img = rune_info_node:getChildByName("rune_bg")
    self.preview_exp_bar = rune_info_node:getChildByName("loadingbar_blue")
    self.exp_bar = rune_info_node:getChildByName("loadingbar_yellow")
    self.rune_icon_img = rune_info_node:getChildByName("rune_icon")
    self.rune_icon_img:setTouchEnabled(true)

    self.equipped_icon_img = self.rune_icon_img:getChildByName("equipped_icon_0")
    self.top_quality_img = self.rune_icon_img:getChildByName("top_quality_0")

    self.out_exp_text = self.root_node:getChildByName("exp_num")

    self.back_btn = self.root_node:getChildByName("back_btn")
    self.one_key_select_btn = self.root_node:getChildByName("quick_btn")
    self.confirm_btn = self.root_node:getChildByName("confirm_btn")

    self.more_quality_select_img = self.root_node:getChildByName("yes_icon")
    self.more_quality_btn = self.root_node:getChildByName("10times_btn")

    self.rune_cell_prototype = self.root_node:getChildByName("rune_panel")
    self.add_panel_prototype = self.root_node:getChildByName("rune_box")

    local desc_node = self.root_node:getChildByName("rune_desc")
    desc_node:getChildByName("exp"):setVisible(false)

    self.property_name_list = {}
    self.property_value_list = {}
    self.property_arrow_list = {}
    self.property_preview_value_list = {}

    for index=1,PROPERTY_NUM do
        local property_node = desc_node:getChildByName(string.format("buff_0%d_txt", index))
        self.property_name_list[index] = property_node
        self.property_value_list[index] = property_node:getChildByName(string.format("number_old0%d", index))
        self.property_arrow_list[index] = property_node:getChildByName(string.format("arrow_0%d", index))
        self.property_preview_value_list[index] = property_node:getChildByName(string.format("number_new0%d", index))

        self.property_value_list[index]:setColor(panel_util:GetColor4B(client_constants["TEXT_COLOR"]["orange"]))
    end

    self.rune_cell_prototype:setVisible(false)
    self.add_panel_prototype:setVisible(false)

    self.preview_level = 0
    self.preview_exp = 0
    self.target_rune_info = nil

    self.exp_rune_list = {}
    self.exp_rune_cell_pos = {}
    self.exp_rune_sub_panels = {}

    self.upgrade_animation_conf = {}
    self.upgrade_animation_conf.show_upgrade_animation = false
    self.upgrade_animation_conf.elapsed_time = 0
    self.upgrade_animation_conf.star_level = 0
    self.upgrade_animation_conf.end_level = 0
    self.upgrade_animation_conf.start_exp = 0
    self.upgrade_animation_conf.end_exp = 0

    self.spine_node = spine_manager:GetNode("fuwen", 1.0, true)
    self.spine_node:setScale(2)
    self.spine_node:setPosition(cc.p(self.rune_icon_img:getContentSize().width / 2, self.rune_icon_img:getContentSize().height / 2))
    self.rune_icon_img:addChild(self.spine_node)
    self.spine_node:setTimeScale(1.0)

    self:RegisterEvent()
    self:RegisterWidgetEvent()

    self:CreateExpRuneCell()
end

function rune_upgrade_panel:Show(target_rune_info)
    self.upgrade_animation_conf.show_upgrade_animation = false
    
    self:ShowTargetRune(target_rune_info)

    self.exp_rune_list = {}
    self:ShowExpRunes()
    self:ShowPreviewInfo()
    self:SetMoreQualitySelected(rune_logic:IsSelectedMoreQuality())

    self.root_node:setVisible(true)
end

function rune_upgrade_panel:Update(elapsed_time)
    if self.upgrade_animation_conf.show_upgrade_animation then
        self.upgrade_animation_conf.elapsed_time = self.upgrade_animation_conf.elapsed_time + elapsed_time

        self.exp_bar:setPercent(100 * self.upgrade_animation_conf.show_exp / self.upgrade_animation_conf.show_exp_limit)
        
        self.upgrade_animation_conf.start_exp = self.upgrade_animation_conf.start_exp + elapsed_time * self.upgrade_animation_conf.speed
        self.upgrade_animation_conf.show_exp = self.upgrade_animation_conf.show_exp + elapsed_time * self.upgrade_animation_conf.speed
        if self.upgrade_animation_conf.show_exp >= self.upgrade_animation_conf.show_exp_limit then
            self.spine_node:setAnimation(0, "upgrade", false)
            self.upgrade_animation_conf.star_level = self.upgrade_animation_conf.star_level + 1
            self.upgrade_animation_conf.show_exp, self.upgrade_animation_conf.show_exp_limit = rune_logic:GetRuneExpForShow(self.upgrade_animation_conf.start_exp, self.upgrade_animation_conf.star_level, self.target_rune_info.template_info.quality)
        end
        self:ShowTargetRune(self.upgrade_animation_conf.target_rune_info, self.upgrade_animation_conf.start_exp, self.upgrade_animation_conf.star_level)

        if self.upgrade_animation_conf.star_level >= self.upgrade_animation_conf.end_level and self.upgrade_animation_conf.start_exp >= self.upgrade_animation_conf.end_exp then
            self.upgrade_animation_conf.show_upgrade_animation = false

            self:ShowTargetRune(self.upgrade_animation_conf.target_rune_info)
        end
    end
end

function rune_upgrade_panel:CreateExpRuneCell()
    local bag_init_x = self.add_panel_prototype:getPositionX()
    local bag_init_y = self.add_panel_prototype:getPositionY()
    local bag_offset_x = 120
    local bag_offset_y = 120

    for index = 1, constants["MAX_RUNE_BAG_MUILT_SELECT_NUM"] do
        local row = math.ceil(index / BAG_CELL_COL) - 1
        local col = index - row * BAG_CELL_COL - 1
        self.exp_rune_cell_pos[index] = {x = (bag_init_x + bag_offset_x * col), y = (bag_init_y - bag_offset_y * row)}

        local rune_cell = self.add_panel_prototype:clone()
        rune_cell:setVisible(true)
        rune_cell:setPosition(self.exp_rune_cell_pos[index])
        
        self.root_node:addChild(rune_cell)

        local sub_panel = exp_rune_sub_panel.New()
        sub_panel:Init(self.rune_cell_prototype:clone())
        sub_panel.root_node:setAnchorPoint(cc.p(0.5, 0.5))
        sub_panel.root_node:setPosition(self.exp_rune_cell_pos[index])
        sub_panel.root_node:addTouchEventListener(self.select_rune_method)

        self.root_node:addChild(sub_panel.root_node)

        self.exp_rune_sub_panels[index] = sub_panel
    end
end

function rune_upgrade_panel:SetPropertyValue(preview_level)
    local index = 1
    if self.target_rune_info then
        local property_conf = config_manager.rune_property_config[self.target_rune_info.template_id]
        if property_conf then
            for i,key in ipairs(constants["RUNE_PROPERTY_KEYS"]) do
                local property = property_conf[key][self.target_rune_info.level] or {}
                local preview_property = property_conf[key][preview_level] or {}

                for k,property_name in pairs(constants["PROPERTY_TYPE_NAME"]) do
                    local property_value = property[property_name] or 0
                    local preview_property_value = preview_property[property_name] or 0
                    if property_value ~= 0 or preview_property_value ~= 0 then

                        local desc_name = property_value > 0 and lang_constants:Get("add_property") or lang_constants:Get("sub_property")
                        desc_name = desc_name .. lang_constants:Get(key) .. lang_constants:Get(string.format("%s_property", property_name)) .. ":"

                        self.property_name_list[index]:setVisible(true)
                        self.property_name_list[index]:setString(desc_name)

                        self.property_value_list[index]:setString(tostring(math.ceil(math.abs(property_value))))

                        if preview_level > 0 then
                            self.property_preview_value_list[index]:setString(tostring(math.ceil(math.abs(preview_property_value))))
                            if math.ceil(math.abs(property_value)) > math.ceil(math.abs(preview_property_value)) then
                                self.property_preview_value_list[index]:setColor(panel_util:GetColor4B(client_constants["TEXT_COLOR"]["red"]))
                            elseif math.ceil(math.abs(property_value)) < math.ceil(math.abs(preview_property_value)) then
                                self.property_preview_value_list[index]:setColor(panel_util:GetColor4B(client_constants["TEXT_COLOR"]["green"]))
                            else
                                self.property_preview_value_list[index]:setColor(panel_util:GetColor4B(client_constants["TEXT_COLOR"]["orange"]))
                            end
                        else
                            self.property_preview_value_list[index]:setString("")
                        end

                        index = index + 1
                    end
                end
            end
        end
    end

    for empty_index=index,PROPERTY_NUM do
        self.property_name_list[empty_index]:setVisible(false)
    end
end

function rune_upgrade_panel:ShowTargetRune(target_rune_info, exp, level)
    self.target_rune_info = target_rune_info or self.target_rune_info
    exp = exp or self.target_rune_info.exp
    level = level or self.target_rune_info.level

    if self.target_rune_info then
        self.rune_bg_img:setVisible(true)
        self.rune_icon_img:setVisible(true)
        self.rune_icon_img:loadTexture(self.target_rune_info.template_info.icon, PLIST_TYPE)
        self.rune_name_text:setString(self.target_rune_info.template_info.name)
        self.rune_level_text:setString(string.format(lang_constants:Get("rune_level"), level))
        self.top_quality_img:setVisible(self.target_rune_info.template_info.quality == constants["MAX_RUNE_QUALITY"])
        self.equipped_icon_img:setVisible(self.target_rune_info.equip_pos > 0)

        if level >= self.target_rune_info.template_info.level_limit then
            self.exp_text:setString(lang_constants:Get("level_max"))
            self.exp_bar:setPercent(100)
        else
            local show_exp, show_exp_limit = rune_logic:GetRuneExpForShow(exp, level, self.target_rune_info.template_info.quality)
            self.exp_text:setString(string.format("%d/%d", show_exp, show_exp_limit))
            self.exp_bar:setPercent(100 * show_exp / show_exp_limit)
        end
    else
        self.rune_bg_img:setVisible(false)
        self.rune_icon_img:setVisible(false)
        self.rune_name_text:setString("")
        self.rune_level_text:setString("")
        self.top_quality_img:setVisible(false)
        self.equipped_icon_img:setVisible(false)
        self.exp_bar:setPercent(0)
        self.preview_exp_bar:setPercent(0)
        self.exp_text:setString("")
        self.preview_exp_text:setString("")
    end
end

function rune_upgrade_panel:ShowExpRunes()
    if self.target_rune_info then
        for index,exp_rune_info in ipairs(self.exp_rune_list) do
            if exp_rune_info.rune_id == self.target_rune_info.rune_id then
                table.remove(self.exp_rune_list, index)
                graphic:DispatchEvent("show_prompt_panel", "auto_remove_rune_upgrade_targert")
                break
            end
        end
    end
    for index,sub_panel in ipairs(self.exp_rune_sub_panels) do
        sub_panel:Show(self.exp_rune_list[index])
    end
    self:RefreshUpgradeBtnEnable()
end

function rune_upgrade_panel:SetMoreQualitySelected( is_selected )
    self.more_quality_select_img:setVisible(is_selected)
    rune_logic:SetSelectedMoreQuality(is_selected)
end

function rune_upgrade_panel:RefreshUpgradeBtnEnable()
    if #self.exp_rune_list > 0 then
        self.confirm_btn:setColor(panel_util:GetColor4B(client_constants["TEXT_COLOR"]["write"]))
    else
        self.confirm_btn:setColor(panel_util:GetColor4B(client_constants["TEXT_COLOR"]["gray"]))
    end
end

function rune_upgrade_panel:ShowPreviewInfo()
    local preview_level = 0
    local preview_exp = 0

    self.arrow_img:setOpacity(0)
    self.exp_bar:setOpacity(255)
    self.exp_text:setOpacity(255)
    self.preview_exp_bar:setOpacity(0)
    self.preview_exp_text:setOpacity(0)
    self.preview_rune_level_text:setOpacity(0)

    self.arrow_img:stopAllActions()
    self.preview_rune_level_text:stopAllActions()
    self.exp_bar:stopAllActions()
    self.preview_exp_bar:stopAllActions()
    self.exp_text:stopAllActions()
    self.preview_exp_text:stopAllActions()

    self.out_exp_text:setString("0")

    for index=1,PROPERTY_NUM do
        self.property_arrow_list[index]:stopAllActions()
        self.property_preview_value_list[index]:stopAllActions()
        self.property_arrow_list[index]:setOpacity(0)
        self.property_preview_value_list[index]:setOpacity(0)
    end

    if self.target_rune_info and #self.exp_rune_list > 0 then
        preview_level, preview_exp = rune_logic:GetRunePreviewLevelAndExp(self.target_rune_info, self.exp_rune_list)

        self.out_exp_text:setString(tostring(preview_exp - self.target_rune_info.exp))

        if preview_level >= self.target_rune_info.template_info.level_limit then
            self.preview_exp_text:setString(lang_constants:Get("level_max"))
            self.preview_exp_bar:setPercent(100)
        else
            local show_preview_exp, show_preview_exp_limit = rune_logic:GetRuneExpForShow(preview_exp, preview_level, self.target_rune_info.template_info.quality)
            self.preview_exp_text:setString(string.format("%d/%d", show_preview_exp, show_preview_exp_limit))
            self.preview_exp_bar:setPercent(100 * show_preview_exp / show_preview_exp_limit)
        end
        self.preview_rune_level_text:setString(string.format(lang_constants:Get("rune_level"), preview_level))

        local forever_fade_in_out = cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(0.5), cc.FadeIn:create(0.5), cc.DelayTime:create(1), cc.FadeOut:create(0.5), cc.DelayTime:create(0.5)))
        self.arrow_img:runAction(forever_fade_in_out:clone())
        self.preview_rune_level_text:runAction(forever_fade_in_out:clone())
        self.preview_exp_bar:runAction(forever_fade_in_out:clone())

        local forever_fade_out_in = cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(0.5), cc.FadeOut:create(0.5), cc.DelayTime:create(1), cc.FadeIn:create(0.5), cc.DelayTime:create(0.5)))
        if self.target_rune_info.level ~= preview_level then
            self.exp_bar:runAction(forever_fade_out_in:clone())
        end

        self.exp_text:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(0.5), cc.FadeOut:create(0.25), cc.DelayTime:create(1.5), cc.FadeIn:create(0.25), cc.DelayTime:create(0.5))))
        self.preview_exp_text:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(0.75), cc.FadeIn:create(0.25), cc.DelayTime:create(1), cc.FadeOut:create(0.25), cc.DelayTime:create(0.75))))

        for index=1,PROPERTY_NUM do
            self.property_arrow_list[index]:runAction(forever_fade_in_out:clone())
            self.property_preview_value_list[index]:runAction(forever_fade_in_out:clone())
        end
    end
    
    self:SetPropertyValue(preview_level)
end

function rune_upgrade_panel:RegisterEvent()
    graphic:RegisterEvent("rune_bag_select_confirm", function(show_type, select_rune_list)
        if not self.root_node:isVisible() then
            return
        end
        if show_type == client_constants["RUNE_BAG_SHOW_TYPE"]["SELECT_ONE"] and #select_rune_list > 0 then
            self:ShowTargetRune(select_rune_list[1])
            self:ShowPreviewInfo()
        elseif show_type == client_constants["RUNE_BAG_SHOW_TYPE"]["SELECT_MUILT"] then
            self.exp_rune_list = select_rune_list
            self:ShowExpRunes()
            self:ShowPreviewInfo()
        end
    end)


    graphic:RegisterEvent("rune_upgrade_success", function(start_level, start_exp, target_rune_info)
        if not self.root_node:isVisible() then
            return
        end

        self.upgrade_animation_conf.elapsed_time = 0
        self.upgrade_animation_conf.target_rune_info = target_rune_info
        self.upgrade_animation_conf.star_level = start_level
        self.upgrade_animation_conf.end_level = self.target_rune_info.level
        self.upgrade_animation_conf.start_exp = start_exp
        self.upgrade_animation_conf.end_exp = self.target_rune_info.exp
        self.upgrade_animation_conf.speed = (self.target_rune_info.exp - start_exp) / 1.5
        self.upgrade_animation_conf.show_exp, self.upgrade_animation_conf.show_exp_limit = rune_logic:GetRuneExpForShow(self.upgrade_animation_conf.start_exp, self.upgrade_animation_conf.star_level, self.target_rune_info.template_info.quality)
        self.upgrade_animation_conf.show_upgrade_animation = true

        self.exp_rune_list = {}
        self:RefreshUpgradeBtnEnable()
        self:ShowPreviewInfo()

        for index,sub_panel in ipairs(self.exp_rune_sub_panels) do
            if sub_panel.rune_info then
                sub_panel:ShowDisappearAnimation(math.random(50) / 100)
            end
        end
    end)
end

function rune_upgrade_panel:RegisterWidgetEvent()

    self.select_rune_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            if self.upgrade_animation_conf.show_upgrade_animation then
                graphic:DispatchEvent("show_prompt_panel", "rune_is_upgrading")
                return
            end
            local target_rune_id
            if self.target_rune_info then
                target_rune_id = self.target_rune_info.rune_id
            end
            graphic:DispatchEvent("show_world_sub_scene", "rune_bag_sub_scene", constants["SCENE_TRANSITION_TYPE"]["none"], client_constants["RUNE_BAG_SHOW_TYPE"]["SELECT_MUILT"], self.exp_rune_list, target_rune_id)
        end
    end

    self.rune_icon_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            if self.upgrade_animation_conf.show_upgrade_animation then
                graphic:DispatchEvent("show_prompt_panel", "rune_is_upgrading")
                return
            end

            graphic:DispatchEvent("show_world_sub_scene", "rune_bag_sub_scene", constants["SCENE_TRANSITION_TYPE"]["none"], client_constants["RUNE_BAG_SHOW_TYPE"]["SELECT_ONE"], { self.target_rune_info })
        end
    end)

    self.one_key_select_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if self.upgrade_animation_conf.show_upgrade_animation then
                graphic:DispatchEvent("show_prompt_panel", "rune_is_upgrading")
                return
            end

            local exp_rune_id_map = {}
            for i,exp_rune_info in ipairs(self.exp_rune_list) do
                exp_rune_id_map[exp_rune_info.rune_id] = true
            end
            
            local rune_list = rune_logic:GetSortRuneList(false, true, true)

            local quality_limit = constants["MAX_AUTO_SELECT_EXP_RUNE_QUALITY"]
            if rune_logic:IsSelectedMoreQuality() then
                quality_limit = constants["MAX_AUTO_SELECT_EXP_RUNE_MORE_QUALITY"]
            end
            for index,rune_info in ipairs(rune_list) do
                if #self.exp_rune_list >= constants["MAX_RUNE_BAG_MUILT_SELECT_NUM"] then
                    break
                end
                if rune_info.equip_pos == 0 then
                    if rune_info.template_info.type == constants["RUNE_TYPE"]["EXP"] or rune_info.template_info.quality <= quality_limit then
                        if self.target_rune_info.rune_id == nil or rune_info.rune_id ~= self.target_rune_info.rune_id then
                            if not exp_rune_id_map[rune_info.rune_id] then
                                table.insert(self.exp_rune_list, rune_info)
                            end
                        end
                    end
                end
            end

            self:ShowExpRunes()
            self:ShowPreviewInfo()
        end
    end)

    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if #self.exp_rune_list == 0 then
                graphic:DispatchEvent("show_prompt_panel", "no_exp_rune_list")
            elseif self.target_rune_info.level < self.target_rune_info.template_info.level_limit then


                for index,exp_rune_info in ipairs(self.exp_rune_list) do
                    local quality_limit = constants["MAX_AUTO_SELECT_EXP_RUNE_QUALITY"]
                    if rune_logic:IsSelectedMoreQuality() then
                        quality_limit = constants["MAX_AUTO_SELECT_EXP_RUNE_MORE_QUALITY"]
                    end
                    if exp_rune_info.template_info.quality > quality_limit then
                        graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("has_high_quality_exp_rune"),
                            lang_constants:Get("has_high_quality_exp_rune_desc"),
                            lang_constants:Get("common_confirm"),
                            lang_constants:Get("common_cancel"),
                            function()
                                rune_logic:UpgradeRune(self.target_rune_info, self.exp_rune_list)
                            end) 
                        return
                    end
                end

                rune_logic:UpgradeRune(self.target_rune_info, self.exp_rune_list)
            else
                graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("rune_already_max_level"),
                    lang_constants:Get("rune_already_max_level_desc"),
                    lang_constants:Get("common_confirm"),
                    lang_constants:Get("common_cancel"),
                    function()
                        rune_logic:UpgradeRune(self.target_rune_info, self.exp_rune_list)
                    end) 
            end
        end
    end)

    --紫色品质加入一键选择
    self.more_quality_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            self:SetMoreQualitySelected( not rune_logic:IsSelectedMoreQuality() )
        end
    end)

    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)
end

return rune_upgrade_panel

