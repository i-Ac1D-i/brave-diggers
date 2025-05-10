local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local mining_logic = require "logic.mining"
local time_logic = require "logic.time"

local resource_config = config_manager.resource_config

--r2
local platform_manager = require "logic.platform_manager"

local PLIST_TYPE = ccui.TextureResType.plistType
local RESOURCE_TYPE = constants.RESOURCE_TYPE
local BG_COLOR_MAP = client_constants["BG_QUALITY_COLOR"]

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local explain_sub_panel = panel_prototype.New()
function explain_sub_panel:Init(root_node)
    self.root_node = root_node
    root_node:setLocalZOrder(1)

    self.cost_text = root_node:getChildByName("cost")
    self.output_text = root_node:getChildByName("output")

    self.name_text = root_node:getChildByName("project_name")
    self.need_depth_text = root_node:getChildByName("need_depth")

    self.ore_icon_imgs = {}
    for i = 1, 3 do
        self.ore_icon_imgs[i] = self.root_node:getChildByName("get_ore" .. i)
        self.ore_icon_imgs[i]:setCascadeColorEnabled(false)
    end
end

function explain_sub_panel:Show(project_id)
    local config = config_manager.mining_quarry_config[project_id]

    local index = 1
    for resource_id in string.gmatch(config.resource_ids, "(%d+)") do
        local icon_img = self.ore_icon_imgs[index]

        local conf = resource_config[tonumber(resource_id)]
        icon_img:getChildByName("icon"):loadTexture(conf.icon, PLIST_TYPE)
        icon_img:setColor(panel_util:GetColor4B(BG_COLOR_MAP[conf.quality]))
        icon_img:setVisible(true)
        index = index + 1
    end

    for i = index + 1, 3 do
        self.ore_icon_imgs[i]:setVisible(false)
    end

    self.output_text:setString(string.format(lang_constants:Get("mining_project_income"), config.output_count, config.output_count * 2))

    if config.tnt_count > 0 then
        self.cost_text:setString(string.format(lang_constants:Get("mining_project_cost2"), config.dig_count, config.tnt_count))
    else
        self.cost_text:setString(string.format(lang_constants:Get("mining_project_cost1"), config.dig_count))
    end

    self.need_depth_text:setString(tostring(config.need_layer))

    self.name_text:setString(string.format(lang_constants:Get("mining_project_name"), config.name, config.need_time/60))

    self.root_node:setVisible(true)
end

local project_sub_panel = panel_prototype.New()
project_sub_panel.__index = project_sub_panel

function project_sub_panel.New()
    return setmetatable({}, project_sub_panel)
end

function project_sub_panel:Init(root_node)
    self.root_node = root_node

    --未解锁工程
    self.lock_img = root_node:getChildByName("lock")
    panel_util:SetTextOutline(self.lock_img:getChildByName("desc"))

    self.unlock_btn = self.lock_img:getChildByName("unlock_btn")

    --未运行的工程
    self.empty_img = root_node:getChildByName("empty")
    panel_util:SetTextOutline(self.empty_img:getChildByName("desc"))

    self.add_project_btn = self.empty_img:getChildByName("new_project_btn")

    --正在运行的工程
    local running_img = root_node:getChildByName("running")
    self.running_img = running_img

    self.finish_btn = running_img:getChildByName("finish_btn")
    self.remain_time_text = running_img:getChildByName("time")
    self.time_icon_img = running_img:getChildByName("time_icon")
    self.name_text = running_img:getChildByName("project_name")
    self.depth_img = running_img:getChildByName("depth_icon")
    self.waiting_text = running_img:getChildByName("waiting")

    self.remain_time = 0

    self.root_node:setVisible(true)
    --r2修改
    local cost_pos_y=platform_manager:GetChannelInfo().quarry_panel_project_sub_panel_soul_chip_cost_text_pos_y
    if cost_pos_y ~= nil then
        --位置y向上移动
        self.soul_chip_cost_text=self.unlock_btn:getChildByName("soul_chip_cost")
        self.soul_chip_cost_text:setPositionY(self.soul_chip_cost_text:getPositionY()+cost_pos_y)
    end
    local waiting_text_pos_y=platform_manager:GetChannelInfo().quarry_panel_project_sub_panel_waiting_text_pos_y
    if waiting_text_pos_y ~= nil then
        --位置y向上移动
        self.waiting_text:setPositionX(self.waiting_text:getPositionX()+waiting_text_pos_y)
    end
    

end

function project_sub_panel:Load(project_info)
    self.project_id = project_info.id

    local config = config_manager.mining_quarry_config[project_info.id]
    self.need_time = config.need_time * 60

    self.remain_time = project_info.endtime - time_logic:Now()
    self.is_waiting = false

    if self.remain_time <= 0 then
        self.remain_time = 0
        self.finish_btn:setVisible(true)
        self.remain_time_text:setVisible(false)
        self.time_icon_img:setVisible(false)
        self.waiting_text:setVisible(false)

    elseif self.remain_time > self.need_time then
        self.finish_btn:setVisible(false)
        self.remain_time_text:setVisible(false)
        self.time_icon_img:setVisible(false)
        self.waiting_text:setVisible(true)
        self.is_waiting = true

    else
        self.finish_btn:setVisible(false)
        self.remain_time_text:setVisible(true)
        self.time_icon_img:setVisible(true)
        self.waiting_text:setVisible(false)
        self.remain_time_text:setString(panel_util:GetTimeStr(self.remain_time))
    end


    self.name_text:setString(config.name)

    self.depth_img:loadTexture(config.icon, PLIST_TYPE)

    self.running_img:setVisible(true)
    self.empty_img:setVisible(false)
    self.lock_img:setVisible(false)
end

function project_sub_panel:Clear(is_lock)
    self.running_img:setVisible(false)
    self.empty_img:setVisible(not is_lock)
    self.lock_img:setVisible(is_lock)

    self.project_id = nil
    self.remain_time = 0
end

function project_sub_panel:UpdateTime(elapsed_time)

    if self.remain_time > 0 then
        self.remain_time = self.remain_time - elapsed_time

        if self.remain_time < 0 then
            self.remain_time = 0
            self.remain_time_text:setVisible(false)
            self.time_icon_img:setVisible(false)
            self.finish_btn:setVisible(true)

        elseif self.remain_time <= self.need_time then
            if self.is_waiting then
                self.waiting_text:setVisible(false)
                self.remain_time_text:setVisible(true)
                self.time_icon_img:setVisible(true)
                self.is_waiting = false
            else
                self.remain_time_text:setString(panel_util:GetTimeStr(self.remain_time))
            end
        end
    end
end

local quarry_panel = panel_prototype.New()
function quarry_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/quarry_panel.csb")

    self.back_btn = self.root_node:getChildByName("back_btn")

    self.project_sub_panels = {}
    local template = self.root_node:getChildByName("project_template")

    local needClone=platform_manager:GetChannelInfo().quarry_panel_project_sub_panels_need_clone
    
    for i = 1, 5 do
        local sub_panel = project_sub_panel.New()
        self.project_sub_panels[i] = sub_panel
        --r2bug如果不克隆，就会导致第一个行列与其它会不一样
        if i == 1 and needClone == nil then
            sub_panel:Init(template)
        else
            sub_panel:Init(template:clone())
            sub_panel.root_node:setPosition(320, 840 - (i-1) * 125)
            self.root_node:addChild(sub_panel.root_node)
        end

        sub_panel.root_node:setTag(i)
        sub_panel.finish_btn:setTag(i)
    end
    
    --r2bug如果不克隆，就会导致第一个行列与其它会不一样
    if needClone then
        template:setVisible(false)
    end


    self.pickaxe_count_text = self.root_node:getChildByName("pickaxe_count")
    self.tnt_num_text = self.root_node:getChildByName("tnt_num")
    self.depth_text = self.root_node:getChildByName("depth")

    explain_sub_panel:Init(self.root_node:getChildByName("explain"))

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function quarry_panel:Show()
    self.root_node:setVisible(true)

    self.pickaxe_count_text:setString(mining_logic.dig_count .. "/" .. mining_logic.dig_max_count)
    self.tnt_num_text:setString("x " .. resource_logic:GetResourceNum(RESOURCE_TYPE["tnt"]))
    self.depth_text:setString(tostring(mining_logic:GetDepth()))

    self:UpdateProjectList()
    explain_sub_panel:Hide()
end

function quarry_panel:UpdateProjectList()
    local project_count = mining_logic:GetMaxProjectCount()
    for i = 1, 5 do
        local sub_panel = self.project_sub_panels[i]

        if i <= project_count then
            local project_info = mining_logic:GetProjectInfo(i)
            if project_info then
                sub_panel:Load(project_info)
            else
                sub_panel:Clear(false)
            end

        else
            sub_panel:Clear(true)
        end
    end
end

function quarry_panel:Update(elapsed_time)
    for i = 1, 5 do
        local sub_panel = self.project_sub_panels[i]
        sub_panel:UpdateTime(elapsed_time)
    end
end

function quarry_panel:RegisterWidgetEvent()

    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    --添加工程
    local add_project_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "add_project_msgbox")
        end
    end

    --领取工程奖励
    local get_reward_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local index = widget:getTag()
            local sub_panel = self.project_sub_panels[index]
            if sub_panel.remain_time <= 0 then
                mining_logic:GetProjectReward()
            end
        end
    end

    --解锁工程
    local unlock_project_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", client_constants.CONFIRM_MSGBOX_MODE["unlock_mining_project"])
        end
    end

    --显示工程信息
    local show_project_info_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            local index = widget:getTag()
            local sub_panel = self.project_sub_panels[index]
            if sub_panel.project_id then
                explain_sub_panel:Show(sub_panel.project_id)
                explain_sub_panel.root_node:setPosition(widget:getPosition())
            end

        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            explain_sub_panel:Hide()
        end
    end

    for i = 1, 5 do
        local sub_panel = self.project_sub_panels[i]

        sub_panel.add_project_btn:addTouchEventListener(add_project_method)
        sub_panel.unlock_btn:addTouchEventListener(unlock_project_method)
        sub_panel.finish_btn:addTouchEventListener(get_reward_method)

        sub_panel.root_node:addTouchEventListener(show_project_info_method)
    end
end

function quarry_panel:RegisterEvent()
    graphic:RegisterEvent("unlock_mining_project", function()
        if not self.root_node:isVisible() then
            return
        end

        local index = mining_logic:GetMaxProjectCount()
        self.project_sub_panels[index]:Clear(false)
    end)

    graphic:RegisterEvent("update_mining_project_list", function(get_reward, project_id)
        if not self.root_node:isVisible() then
            return
        end

        if get_reward then
            --获得奖励
            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
        end

        self.pickaxe_count_text:setString(mining_logic.dig_count .. "/" .. mining_logic.dig_max_count)
        self.tnt_num_text:setString("x " .. resource_logic:GetResourceNum(RESOURCE_TYPE["tnt"]))

        self:UpdateProjectList()
    end)

    graphic:RegisterEvent("update_dig_recover_time", function(is_increased)
        if not self.root_node:isVisible() then
            return
        end

        if is_increased then
            self.pickaxe_count_text:setString(mining_logic.dig_count .. "/" .. mining_logic.dig_max_count)
        end
    end)

    graphic:RegisterEvent("update_resource_list", function()
        if not self.root_node:isVisible() then
            return
        end

        if resource_logic:IsResourceUpdated(RESOURCE_TYPE["tnt"]) then
            self.tnt_num_text:setString("x " .. resource_logic:GetResourceNum(RESOURCE_TYPE["tnt"]))
        end
    end)
end

return quarry_panel
