local constants = require "util.constants"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"
local platform_manager = require "logic.platform_manager"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local mining_logic = require "logic.mining"
local resource_logic = require "logic.resource"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local resource_config = config_manager.resource_config
local PLIST_TYPE = ccui.TextureResType.plistType
local REWARD_TYPE = constants.REWARD_TYPE
local RESOURCE_TYPE = constants.RESOURCE_TYPE

local BG_COLOR_MAP = client_constants["BG_QUALITY_COLOR"]

local lang_constants = require "util.language_constants"

local DEPTH_LIMIT =
{
    [1] = 0,
    [2] = 35,
    [3] = 120,
    [4] = 250,
}

local PROJECT_MAP =
{
    [1] = { 1, 2, 3 },
    [2] = { 4, 5, 6 },
    [3] = { 7, 8, 9 },
    [4] = { 10, 11, 12 },
}

local GREEN = 0xa1e01b
local RED = 0xf87f26

local add_project_msgbox = panel_prototype.New(true)
function add_project_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/new_project_msgbox.csb")

    self.depth_select_img = self.root_node:getChildByName("select1")
    self.time_select_img = self.root_node:getChildByName("select2")

    self.close_btn = self.root_node:getChildByName("close_btn")
    self.cancel_btn = self.root_node:getChildByName("cancel_btn")
    self.confirm_btn = self.root_node:getChildByName("confirm_btn")

    self.depth_texts = {}
    self.time_imgs = {}

    for i = 1, 4 do
        local node = self.root_node:getChildByName("depth" .. i)
        node:setTag(i)
        self.depth_texts[i] = node:getChildByName("depth")
    end

    for i = 1, 3 do
        self.time_imgs[i] = self.root_node:getChildByName("time" .. i)
        self.time_imgs[i]:setTag(i)
    end

    self.pickaxe_num_text = self.root_node:getChildByName("pickaxe_cost"):getChildByName("num")
    self.tnt_num_text = self.root_node:getChildByName("tnt_cost"):getChildByName("num")

    --TAG:MASTER_MERGE
    if platform_manager:GetChannelInfo().meta_channel == "txwy" or platform_manager:GetChannelInfo().meta_channel == "txwy_dny" then
        self.pickaxe_num_text:setAnchorPoint({x=0.5,y=0.5})
        self.pickaxe_num_text:setPosition({x=37,y=self.pickaxe_num_text:getContentSize().height/2})
        self.tnt_num_text:setAnchorPoint({x=0.5,y=0.5})
        self.tnt_num_text:setPosition({x=37,y=self.pickaxe_num_text:getContentSize().height/2})
    end
    
    self.project_name_text = self.root_node:getChildByName("project_name")

    self.output_count_text = self.root_node:getChildByName("output")

    self.ore_icon_imgs = {}
    for i = 1, 3 do
        self.ore_icon_imgs[i] = self.root_node:getChildByName("get_ore" .. i)
        self.ore_icon_imgs[i]:setCascadeColorEnabled(false)
    end

    panel_util:SetTextOutline(self.pickaxe_num_text)
    panel_util:SetTextOutline(self.tnt_num_text)

    self:RegisterWidgetEvent()
end

function add_project_msgbox:Show(msgbox_type, project_id)
    local cur_depth = mining_logic:GetDepth()

    local layer = 1
    for i = 1, 4 do
        if cur_depth >= DEPTH_LIMIT[i] then
            self.depth_texts[i]:setColor(panel_util:GetColor4B(GREEN))
            layer = i
        else
            self.depth_texts[i]:setColor(panel_util:GetColor4B(RED))
        end
    end

    self.cur_depth_index = 1
    self.cur_time_index = 1

    self.depth_select_img:setPosition(self.depth_texts[1]:getParent():getPosition())
    self.time_select_img:setPosition(self.time_imgs[1]:getPosition())

    self:UpdateProjectInfo(PROJECT_MAP[self.cur_depth_index][self.cur_time_index])

    self.root_node:setVisible(true)
end

function add_project_msgbox:UpdateProjectInfo(project_id)
    self.project_id = project_id

    local config = config_manager.mining_quarry_config[project_id]

    self.output_count_text:setString(string.format(lang_constants:Get("mining_project_income"), config.output_count, config.output_count*2))

    local iter = string.gmatch(config.resource_ids, "(%d+)")
    for i = 1, 3 do
        local resource_type = tonumber(iter())
        local ore_icon = self.ore_icon_imgs[i]

        if resource_type then
            local conf = resource_config[resource_type]
            ore_icon:setVisible(true)
            ore_icon:setColor(panel_util:GetColor4B(BG_COLOR_MAP[conf.quality]))
            ore_icon:getChildByName("icon"):loadTexture(conf.icon, PLIST_TYPE)
        else
            ore_icon:setVisible(false)
        end
    end

    self.pickaxe_num_text:setString(mining_logic.dig_count.. "/" .. config.dig_count)
    self.pickaxe_num_text:setColor(mining_logic.dig_count >= config.dig_count and panel_util:GetColor4B(GREEN) or panel_util:GetColor4B(RED))

    local tnt = resource_logic:GetResourceNum(RESOURCE_TYPE["tnt"])
    self.tnt_num_text:setString(tnt .. "/" .. config.tnt_count)
    self.tnt_num_text:setColor(tnt >= config.tnt_count and panel_util:GetColor4B(GREEN) or panel_util:GetColor4B(RED))

    self.project_name_text:setString(config.name)
end

function add_project_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())
    panel_util:RegisterCloseMsgbox(self.cancel_btn, self:GetName())

    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if mining_logic:AddProject(self.project_id) then
                graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            end
        end
    end)

    local select_project_by_depth = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.cur_time_index = 1
            self.cur_depth_index = widget:getTag()

            self.depth_select_img:setPosition(widget:getPosition())
            self.time_select_img:setPosition(self.time_imgs[1]:getPosition())

            self:UpdateProjectInfo(PROJECT_MAP[self.cur_depth_index][self.cur_time_index])
        end
    end

    local select_project_by_time = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.cur_time_index = widget:getTag()
            self.time_select_img:setPosition(widget:getPosition())

            self:UpdateProjectInfo(PROJECT_MAP[self.cur_depth_index][self.cur_time_index])
        end
    end

    for i = 1, 4 do
        self.depth_texts[i]:getParent():addTouchEventListener(select_project_by_depth)
    end

    for i = 1, 3 do
        self.time_imgs[i]:addTouchEventListener(select_project_by_time)
    end
end

return add_project_msgbox
