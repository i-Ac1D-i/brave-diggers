local panel_prototype = require "ui.panel"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"

local resource_logic = require "logic.resource"
local mining_logic = require "logic.mining"
local store_logic = require "logic.store"
local user_logic = require "logic.user"
local panel_util = require "ui.panel_util"

local audio_manager = require "util.audio_manager"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"
local feature_config = require "logic.feature_config"
local channel_info = platform_manager:GetChannelInfo()

local RESOURCE_TYPE = constants.RESOURCE_TYPE
local RESOURCE_TYPE_NAME = constants.RESOURCE_TYPE_NAME
local BG_COLOR_MAP = client_constants["BG_QUALITY_COLOR"]
local REWARD_TYPE = constants.REWARD_TYPE
local STORE_GOODS_TYPE = constants.STORE_GOODS_TYPE
local CRYSTAL_BAG_NUM = 1000  --一个水晶包包含1000个水晶

local PLIST_TYPE = ccui.TextureResType.plistType

local icon_template_with_text = require "ui.icon_panel"

local JUNIOR_ORE =
{
    RESOURCE_TYPE["copper"],
    RESOURCE_TYPE["iron"],
    RESOURCE_TYPE["silver"],
    RESOURCE_TYPE["tin"],
    RESOURCE_TYPE["gold"],
    RESOURCE_TYPE["golem"],
}

local INTERMEDIATE_ORE =
{
    RESOURCE_TYPE["diamond"], --钻石
    RESOURCE_TYPE["titan_iron"], --泰坦铁
    RESOURCE_TYPE["ruby"], --红宝石
    RESOURCE_TYPE["purple_gem"],--紫宝石
    RESOURCE_TYPE["emerald"], --绿宝石
    RESOURCE_TYPE["topaz"],--黄宝石
}

local SENIOR_ORE =
{
    RESOURCE_TYPE["red_soul_crystal"],--赤魂晶
    RESOURCE_TYPE["green_soul_crystal"],--碧魂晶
    RESOURCE_TYPE["light_soul_crystal"],--光魂晶
    RESOURCE_TYPE["dark_soul_crystal"],--影魂晶
    RESOURCE_TYPE["inferno_brimstone"],--地狱硫磺
    RESOURCE_TYPE["time_sand"],--时间之砂
}

local SPECIAL_ORE = 
{
    RESOURCE_TYPE["golem2"],
    RESOURCE_TYPE["golem3"],
    RESOURCE_TYPE["golem4"],
}

local ore_sub_panel = panel_prototype.New()
ore_sub_panel.__index = ore_sub_panel

function ore_sub_panel.New()
    return setmetatable({}, ore_sub_panel)
end

function ore_sub_panel:Init(root_node, class)
    self.root_node = root_node

    self.resource_icon = root_node:getChildByName("resource_icon")
    self.name_text = root_node:getChildByName("name")
    if channel_info.ore_sub_panel_change_name_pos_x then
        self.name_text:setAnchorPoint(cc.p(0, 0.5))
        self.name_text:setPositionX(self.name_text:getPositionX() - 48)
    end

    if class == 1 then
        self.resource_type_list = JUNIOR_ORE

    elseif class == 2 then
        self.resource_type_list = INTERMEDIATE_ORE

    elseif class == 3 then
        self.resource_type_list = SENIOR_ORE

    elseif class == 4 then
        self.resource_type_list = SPECIAL_ORE
    end

    local init_x = self.resource_icon:getPositionX()

    self.resource_icon_imgs = {}
    self.resource_num_texts = {}

    for i = 1, #self.resource_type_list do
        local bg_img
        if i == 1 then
            bg_img = self.resource_icon

        else
            bg_img = self.resource_icon:clone()
            bg_img:setPositionX(init_x + (i-1) * 86)

            self.root_node:addChild(bg_img)
        end

        local resource_type = self.resource_type_list[i]
        bg_img:setTag(resource_type)
        bg_img:setTouchEnabled(true)

        local conf = config_manager.resource_config[resource_type]

        bg_img:setCascadeColorEnabled(false)
        bg_img:setCascadeOpacityEnabled(false)

        bg_img:setColor(panel_util:GetColor4B(BG_COLOR_MAP[conf.quality]))

        local icon_img = bg_img:getChildByName("icon")
        icon_img:loadTexture(conf.icon, PLIST_TYPE)
        icon_img:ignoreContentAdaptWithSize(true)

        self.resource_num_texts[i] = bg_img:getChildByName("num")
        self.resource_icon_imgs[i] = icon_img
    end
end

function ore_sub_panel:Load()
    for i = 1, #self.resource_icon_imgs do
        local img = self.resource_icon_imgs[i]
        local resource_type = self.resource_type_list[i]

        if mining_logic:IsResourceFound(resource_type) then
            img:setColor(panel_util:GetColor4B(0xffffff))
            self.resource_num_texts[i]:setString(tostring(resource_logic:GetResourceNum(resource_type)))
            self.resource_num_texts[i]:setColor(panel_util:GetColor4B(0xffffff))
        else
            img:setColor(panel_util:GetColor4B(0x000000))
            self.resource_num_texts[i]:setString("?")
            self.resource_num_texts[i]:setColor(panel_util:GetColor4B(0x929292))
        end
    end
end

local tool_sub_panel = panel_prototype.New()
tool_sub_panel.__index = tool_sub_panel

function tool_sub_panel.New()
    return setmetatable({}, tool_sub_panel)
end

function tool_sub_panel:Init(root_node, tool_type)
    self.root_node = root_node

    self.name_text = root_node:getChildByName("name")
    self.desc_text = root_node:getChildByName("desc")
    local font = platform_manager:GetChannelInfo().ore_bag_panel_name_font
    if font then
        self.name_text:setFontSize(font)
    end
    
    if channel_info.ore_bag_panel_change_desc_size then
        self.desc_text:setContentSize(self.desc_text:getContentSize().width, self.desc_text:getContentSize().height + 6)
    end

    self.use1_btn = root_node:getChildByName("use1_btn")
    self.use2_btn = root_node:getChildByName("use2_btn")

    self.use1_btn:setTag(tool_type)
    self.use2_btn:setTag(tool_type)

    local conf = config_manager.resource_config[tool_type]
    self.name_text:setString(conf.name)
    self.desc_text:setString(conf.desc)

    self.icon_panel = icon_template_with_text.New(root_node:getChildByName("icon"):getChildByName("bg"), 2)
    self.icon_panel:Init(root_node, true)

    self.tool_type = tool_type
end

function tool_sub_panel:Load()
    local resource_num = resource_logic:GetResourceNum(self.tool_type)
    self.icon_panel:Show(REWARD_TYPE["resource"], self.tool_type, resource_num, false, true)

    --数量大于0，并且 不是符文水晶包或者血钻开关没有打开
    if resource_num > 0 or (self.tool_type == RESOURCE_TYPE["crystal_bag"] and feature_config:IsFeatureOpen("review")) then
        self.use2_btn:setVisible(true)
        self.use1_btn:setTitleText(lang_constants:Get("mining_use_tool_btn1"))
    else
        self.use1_btn:setTitleText(lang_constants:Get("mining_use_tool_btn2"))
        self.use2_btn:setVisible(false)
    end
end

function tool_sub_panel:SetUseToolMethod(use_tool_method1, use_tool_method2)
    print("SetUseToolMethod")
    self.use1_btn:addTouchEventListener(use_tool_method1)
    self.use2_btn:addTouchEventListener(use_tool_method2)
end

--神力矿工包
local ultimate_tool_sub_panel = tool_sub_panel.New()
ultimate_tool_sub_panel.__index = ultimate_tool_sub_panel

function ultimate_tool_sub_panel:Init(root_node, tool_type)
    tool_sub_panel.Init(self, root_node, tool_type)

    self.pickaxe_count_text = self.root_node:getChildByName("pickaxe_count")
    self.pickaxe_count_text:setTextHorizontalAlignment(0)

    if channel_info.ore_bag_panel_change_pickaxe_name_pos_x then
        self.pickaxe_name = self.root_node:getChildByName("pickaxe_name")
        self.pickaxe_name:setAnchorPoint(cc.p(0, 0.5))
        self.pickaxe_name:setPositionX(self.pickaxe_name:getPositionX() - 85)
    end

    if channel_info.ore_bag_panel_change_desc_size then
        self.desc_text = self.root_node:getChildByName("desc")
        self.desc_text:setContentSize(self.desc_text:getContentSize().width, self.desc_text:getContentSize().height + 6)
    end

    self.use3_btn = root_node:getChildByName("use3_btn")

    self.max_pickaxe_count_text = self.root_node:getChildByName("pickaxe_count_max")
end

function ultimate_tool_sub_panel:Load()
    tool_sub_panel.Load(self)

    self.pickaxe_count_text:setString(mining_logic.dig_count .. "/")
    self.max_pickaxe_count_text:setString( mining_logic.dig_max_count)
end

--购买雷管
local tnt_sub_panel = tool_sub_panel.New()
tnt_sub_panel.__index = tnt_sub_panel

function tnt_sub_panel:Init(root_node, tool_type)
    self.root_node = root_node

    self.root_node:setVisible(true)

    self.name_text = root_node:getChildByName("name")
    local font = platform_manager:GetChannelInfo().ore_bag_panel_name_font
    if font then
        self.name_text:setFontSize(font)
    end
    self.desc_text = root_node:getChildByName("desc")

    if channel_info.ore_bag_panel_change_desc_size then
        self.desc_text:setContentSize(self.desc_text:getContentSize().width, self.desc_text:getContentSize().height + 6)
    end

    self.use1_btn = root_node:getChildByName("use1_btn")

    local conf = config_manager.resource_config[tool_type]
    self.name_text:setString(conf.name)
    self.desc_text:setString(conf.desc)

    self.icon_panel = icon_template_with_text.New(root_node:getChildByName("icon"):getChildByName("bg"), 2)
    self.icon_panel:Init(root_node, true)

    self.tool_type = tool_type
end

function tnt_sub_panel:Load()
    self.icon_panel:Show(REWARD_TYPE["resource"], self.tool_type, resource_logic:GetResourceNum(self.tool_type), false, true)
end

function tnt_sub_panel:SetUseToolMethod()
end

local ore_bag_panel = panel_prototype.New(true)

function ore_bag_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/ore_bag_panel.csb")

    self.ore_node = self.root_node:getChildByName("ore_sub_panel")
    self.tool_node = self.root_node:getChildByName("tool_sub_panel")

    self.tool_sub_panels = {}
    self.ore_sub_panels = {}

    self.tool_tab = self.root_node:getChildByName("tool_tab")
    self.ore_tab = self.root_node:getChildByName("ore_tab")

    local ore_names = { "junior", "intermediate", "senior", "special" }

    local ore_scrollview = self.ore_node:getChildByName("scrollview")
    self.ore_scroll_view = self.ore_node:getChildByName("scrollview")

    for i = 1, 4 do
        local o_sub_panel = ore_sub_panel.New()
        o_sub_panel:Init(ore_scrollview:getChildByName(ore_names[i]), i)

        self.ore_sub_panels[i] = o_sub_panel
    end

    ultimate_tool_sub_panel:Init(self.tool_node:getChildByName("tool1"), RESOURCE_TYPE["ultimate_tool"])
    table.insert(self.tool_sub_panels, ultimate_tool_sub_panel)

    for i = 1, 3 do
        local t_sub_panel = tool_sub_panel.New()
        t_sub_panel:Init(self.tool_node:getChildByName("tool" .. (i+1)), RESOURCE_TYPE["junior_tool"] + i -1 )
        table.insert(self.tool_sub_panels, t_sub_panel)
    end

    if feature_config:IsFeatureOpen("rune_and_tramcar") then
        local crystal_sub_panel = tool_sub_panel.New()
        crystal_sub_panel:Init(self.tool_node:getChildByName("tool6"), RESOURCE_TYPE["crystal_bag"])
        table.insert(self.tool_sub_panels, crystal_sub_panel)
    else
        self.tool_node:getChildByName("tool6"):setVisible(false)
    end

    tnt_sub_panel:Init(self.tool_node:getChildByName("tool5"), RESOURCE_TYPE["tnt"])
    table.insert(self.tool_sub_panels, tnt_sub_panel)

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function ore_bag_panel:Show(sub_panel_type, jumpToBottom)
    self:ShowSubPanel(sub_panel_type or 1)

    for i = 1, 4 do
        self.ore_sub_panels[i]:Load()
    end

    for _,sub_panel in ipairs(self.tool_sub_panels) do
        sub_panel:Load()
    end

    if sub_panel_type == 2 and jumpToBottom then
        self.tool_node:jumpToBottom()
    end

    self.root_node:setVisible(true)
end

function ore_bag_panel:ShowSubPanel(sub_panel_type)
    if sub_panel_type == 2 then
        self.tool_node:setVisible(true)
        self.ore_node:setVisible(false)

        self.tool_tab:setLocalZOrder(2)
        self.ore_tab:setLocalZOrder(1)

        self.tool_tab:setColor(panel_util:GetColor4B(0xffffff))
        self.ore_tab:setColor(panel_util:GetColor4B(0x7f7f7f))
    else
        self.tool_node:setVisible(false)
        self.ore_node:setVisible(true)

        self.tool_tab:setLocalZOrder(1)
        self.ore_tab:setLocalZOrder(2)

        self.tool_tab:setColor(panel_util:GetColor4B(0x7f7f7f))
        self.ore_tab:setColor(panel_util:GetColor4B(0xffffff))
    end
end

function ore_bag_panel:RegisterWidgetEvent()
    local mode = client_constants.BATCH_MSGBOX_MODE.blood_store

    local use_tool_method1 = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local tool_type = widget:getTag()

            local resource_num = resource_logic:GetResourceNum(tool_type)

            if resource_num > 0 or (tool_type == RESOURCE_TYPE["crystal_bag"] and feature_config:IsFeatureOpen("review")) then
                mining_logic:UseTool(tool_type, 1)
            else

                local goods_index = store_logic:GetResourceGoodsIndex(tool_type)
                if goods_index then
                    graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode, goods_index)
                end
            end
        end
    end

    local use_tool_method2 = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local tool_type = widget:getTag()
            mining_logic:UseTool(tool_type, 5)
        end
    end

    for _,sub_panel in ipairs(self.tool_sub_panels) do
        sub_panel:SetUseToolMethod(use_tool_method1, use_tool_method2)
    end

    --购买雷管
    tnt_sub_panel.use1_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local goods_index = store_logic:GetResourceGoodsIndex(RESOURCE_TYPE["tnt"])
            if goods_index then
                graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode, goods_index)
            end
        end
    end)

    --购买矿稿上限
    ultimate_tool_sub_panel.use3_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local goods_index = store_logic:GetPickaxeGoodsIndex()
            if goods_index then
                graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode, goods_index)
            end
        end
    end)

    self.ore_tab:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:ShowSubPanel(1)
        end
    end)

    self.tool_tab:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            self:ShowSubPanel(2)
            audio_manager:PlayEffect("click")
        end
    end)

    local view_resource_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            local pos = widget:getTouchBeganPosition()
            local resource_type = widget:getTag()
            local conf = config_manager.resource_config[resource_type]

            graphic:DispatchEvent("show_floating_panel", conf.name, conf.desc, pos.x, pos.y)

        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            graphic:DispatchEvent("hide_floating_panel")
        end
    end

    for i = 1, 4 do
        local o_sub_panel = self.ore_sub_panels[i]

        for j = 1, #o_sub_panel.resource_icon_imgs do
            o_sub_panel.resource_icon_imgs[j]:getParent():addTouchEventListener(view_resource_method)
        end
    end

    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
end

function ore_bag_panel:RegisterEvent()
    graphic:RegisterEvent("store_buy_success", function(goods_id)
        if not self.root_node:isVisible() then
            return
        end

        local goods_info = store_logic:GetGoodsInfoById(goods_id)
        if not goods_info then
            return
        end

        if goods_info.type == STORE_GOODS_TYPE["max_pickaxe_count"] then
            ultimate_tool_sub_panel:Load()

        elseif goods_info.type == STORE_GOODS_TYPE["resource"] then
            for _,sub_panel in ipairs(self.tool_sub_panels) do
                if sub_panel.tool_type == goods_info.data then
                    sub_panel:Load()
                    break
                end
            end
        end
    end)

    graphic:RegisterEvent("guide_open", function()
        if self.root_node:isVisible() and self.ore_scroll_view ~= nil and self.tool_node ~= nil then
            self.ore_scroll_view:jumpToTop()
            self.tool_node:jumpToTop()
        end
    end)

    graphic:RegisterEvent("use_mining_tool", function(tool_type, use_num)
        if not self.root_node:isVisible() then
            return
        end

        if tool_type == RESOURCE_TYPE["ultimate_tool"] then
            ultimate_tool_sub_panel:Load()
            graphic:DispatchEvent("show_prompt_panel", "ultimate_tool_tips", use_num)
        else
            for _,sub_panel in ipairs(self.tool_sub_panels) do
                if sub_panel.tool_type == tool_type then
                    sub_panel:Load()

                    for i = 1, 3 do
                        self.ore_sub_panels[i]:Load()
                    end
                    --水晶包只需要文字提示就行了不用reward_panel
                    if tool_type ~= RESOURCE_TYPE["crystal_bag"] then
                        graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
                    else
                        graphic:DispatchEvent("show_prompt_panel", "crystal_tool_tips", use_num * CRYSTAL_BAG_NUM)
                    end
                    break
                end
            end
        end
    end)

    --刷新全局配置
    graphic:RegisterEvent("update_feature_config", function()
        for _,sub_panel in ipairs(self.tool_sub_panels) do
            if sub_panel.tool_type == RESOURCE_TYPE["crystal_bag"] then
                sub_panel:Load()
                break
            end
        end
    end)
end

return ore_bag_panel
