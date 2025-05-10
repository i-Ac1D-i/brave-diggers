local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local platform_manager = require "logic.platform_manager"
local lang_constants = require "util.language_constants"

local graphic = require "logic.graphic"
local panel_prototype = require "ui.panel"

local panel_util = require "ui.panel_util"
local icon_template = require "ui.icon_panel"
local client_constants = require "util.client_constants"
local common_function_util = require "util.common_function"

local PLIST_TYPE = ccui.TextureResType.plistType
local STAGE_INIT_X = 260
local STAGE_INIT_Y = 970
local DISTANCE_Y = 16

local REWARD_ICON_INIT_X = 45
local REWARD_ICON_INIT_Y = 65
local REWARD_DISTANCE_X = 85

local MINING_BOSS_RULE = client_constants["MINING_BOSS_RULE"]

local stage_panel = panel_prototype.New()
stage_panel.__index = stage_panel

function stage_panel.New()
    return setmetatable({}, stage_panel)
end

function stage_panel:Init(root_node, reward_data, parent, index)
    self.index = index
    self.parent_panel = parent
    self.root_node = root_node
    self.reward_data = reward_data
    self.reward_icons = {}

    self.bg_img = self.root_node:getChildByName("bp_bg")

    self.level_img = self.root_node:getChildByName("level_img")
    self.level_img:setLocalZOrder(2)

    self.level_text = self.root_node:getChildByName("level_text")   
    self.level_text:setRotation(-32) 
    self.level_text:setLocalZOrder(2)
    
    self:ShowLevelText()
    self:ShowRewardIcon()
end

function stage_panel:ShowLevelText()
    local lv_str = lang_constants:Get("mercenary_template_panel_lv_text")
    if lv_str == "" then
        lv_str = "Lv."
    end
    self.level_text:setString(lv_str..self.reward_data.level)
end

function stage_panel:SetAnchorPoint(x, y)
   self.root_node:setAnchorPoint(cc.p(x, y)) 
end

function stage_panel:SetPosition(x, y)
    self.root_node:setPosition(cc.p(x, y))
end

function stage_panel:GetHeight()
    return self.root_node:getContentSize().height
end

function stage_panel:GetWidth()
    return self.root_node:getContentSize().width
end

function stage_panel:ShowRewardIcon()
    local reward_table = common_function_util.Split(self.reward_data.reward_type, '|')
    local id_table = common_function_util.Split(self.reward_data.reward_id, '|')
    local to_number = tonumber
    local display_index = 1
    local reward_index = 1
    local mod = 5
    local root_height = self.root_node:getContentSize().height
    local reward_nums = #reward_table
    local math_ceil = math.ceil 

    REWARD_ICON_INIT_Y = 65
    if reward_nums > mod then 
       self.root_node:setContentSize(self.root_node:getContentSize().width, root_height * math_ceil(reward_nums/mod))
       self.bg_img:setContentSize(self.bg_img:getContentSize().width, self.bg_img:getContentSize().height * math_ceil(reward_nums/mod))
       self.level_img:setPositionY(self.level_img:getPositionY() * 2 - 41)
       self.level_text:setPositionY(self.level_text:getPositionY() * 2 - 41)
       self.bg_img:setPositionY(self.bg_img:getPositionY() - 12)
       REWARD_ICON_INIT_Y = 103
       if self.reward_data.level == "17-25" then 
          DISTANCE_Y = 40
       elseif self.reward_data.level == "26-28" then 
          DISTANCE_Y = 44
       end
    end

    for index = 1, reward_nums do 
        local icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
        reward_index = index - (display_index - 1) * mod 
        icon_panel:Init(self.root_node)
        icon_panel:SetPosition(REWARD_ICON_INIT_X + (reward_index - 1) * REWARD_DISTANCE_X, REWARD_ICON_INIT_Y - (display_index - 1) * 90)
        icon_panel:Show(to_number(reward_table[index]), to_number(id_table[index]), false, false, false)
        self.reward_icons[index] = icon_panel

        if index % mod == 0 then 
           display_index = display_index + 1
        end
    end
end

function stage_panel:Show()
    self.root_node:setVisible(true)
end

local mining_boss_rule_panel = panel_prototype.New(true)
function mining_boss_rule_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/mining_rule_msgbox.csb")

    self.stage_panels = {}

    self.scroll_view = self.root_node:getChildByName("scroll_view")
    self.scroll_view:setClippingEnabled(true)

    self.reward_list_view = self.scroll_view:getChildByName("scrollview_a")
    self.reward_list_view:setVisible(false)

    self.reward_template = self.scroll_view:getChildByName("template")
    local level_text = self.reward_template:getChildByName("level_text")
    level_text:setRotation(0)
    local fixed_height = platform_manager:GetChannelInfo().fixd_mining_boss_reward_height
    if fixed_height then
        self.origin_pos = cc.p(self.reward_template:getPosition())
        STAGE_INIT_Y = self.origin_pos.y
    end
    self.reward_template:setVisible(false)
    for i = 1, #MINING_BOSS_RULE do
        DISTANCE_Y = 16
        local sub_panel = stage_panel.New()
        sub_panel:Init(self.reward_template:clone(), MINING_BOSS_RULE[i], self, i)
        self.scroll_view:addChild(sub_panel:GetRootNode())
        sub_panel:SetAnchorPoint(0.5, 0.5)
        sub_panel:SetPosition(STAGE_INIT_X, STAGE_INIT_Y)
        STAGE_INIT_Y = STAGE_INIT_Y - sub_panel:GetHeight() - DISTANCE_Y
        sub_panel:Show()
        self.stage_panels[i] = sub_panel
    end

    if fixed_height then
        local now_size = self.scroll_view:getInnerContainerSize()
        self.scroll_view:setInnerContainerSize(cc.size(now_size.width,now_size.height+fixed_height))
        for i,v in pairs(self.scroll_view:getChildren()) do
            v:setPositionY(v:getPositionY()+fixed_height) 
        end
    end
        
    --r2滑动框大小改变，
    local scrollview_inner_setsize=platform_manager:GetChannelInfo().mining_boss_rule_panel_scrollview_inner_setsize
    if STAGE_INIT_Y < 0 and scrollview_inner_setsize then
        local now_size = self.scroll_view:getInnerContainerSize()
        self.scroll_view:setInnerContainerSize(cc.size(now_size.width,now_size.height-STAGE_INIT_Y))
        for i,v in pairs(self.scroll_view:getChildren()) do
            v:setPositionY(v:getPositionY()-STAGE_INIT_Y)
        end
    end
    
    self:RegisterWidgetEvent()
end

function mining_boss_rule_panel:RegisterWidgetEvent()
    --关闭按钮
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
end

return mining_boss_rule_panel

