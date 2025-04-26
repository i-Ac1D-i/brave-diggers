local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local animation_manager = require "util.animation_manager"

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local time_logic = require "logic.time"
local spine_manager = require "util.spine_manager"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local user_logic = require "logic.user"
local escort_logic = require "logic.escort"

local PLIST_TYPE = ccui.TextureResType.plistType
local TRAMCAR_NUM = 4
local COST_NUM = 3

--老虎机滚动效果配置
--times：从第几次开始
--speed：停顿多久（秒）滚动到下一个
local TRAMCAR_ANIMATION_CONFIG = {
    [1] = { times = 1, speed = 0.15},
    [2] = { times = 4, speed = 0.1},
    [3] = { times = 7, speed = 0.05},
    [4] = { times = 20, speed = 0.1},
    [5] = { times = 23, speed = 0.15},
    [6] = { times = 26, speed = 0.2},
    [7] = { times = 28, speed = 0.25},
}

--单个矿车
local tramcar_sub_panel = panel_prototype.New()
tramcar_sub_panel.__index = tramcar_sub_panel
function tramcar_sub_panel.New()
    return setmetatable({}, tramcar_sub_panel)
end

function tramcar_sub_panel:Init(root_node, select_node, selected_action)
    self.root_node = root_node
    self.select_node = select_node
    self.selected_action = selected_action

    self.tramcar_name_text = self.root_node:getChildByName("Text_36")
    self.cost_icon_list = {}
    self.cost_num_list = {}

    for index = 1, COST_NUM do
        self.cost_icon_list[index] = self.root_node:getChildByName(string.format("cost_icon_%d", index))
        self.cost_num_list[index] = self.root_node:getChildByName(string.format("cost_num_%d", index))
    end
end

function tramcar_sub_panel:Show(tramcar_conf)
    self.tramcar_conf = tramcar_conf

    if self.tramcar_conf then
        self.tramcar_name_text:setString(self.tramcar_conf.name)
        for index = 1, COST_NUM do
            self.cost_icon_list[index]:setVisible(false)
            self.cost_num_list[index]:setVisible(false)

            local reward = self.tramcar_conf.rewards[index]
            if reward then
                local template_id = reward.param1
                local num = reward.param2

                local resource_conf = config_manager.resource_config[template_id]
                if resource_conf then
                    self.cost_icon_list[index]:loadTexture(resource_conf.icon, PLIST_TYPE)
                    self.cost_num_list[index]:setString(num)

                    self.cost_icon_list[index]:setVisible(true)
                    self.cost_num_list[index]:setVisible(true)
                end
            end
        end

        self.root_node:setVisible(true)
    else
        --理论上不应该走到这，配表中应该有四种矿车
        self.root_node:setVisible(false)
    end
end

--显示选中效果
function tramcar_sub_panel:ShowSelected(is_selected, show_animation)
    if self.is_selected ~= is_selected then
        if is_selected then
            if show_animation then
                self.root_node:runAction(cc.ScaleTo:create(0.2, 1, 1))
            else
                self.root_node:setScale(1)
            end
            self.root_node:setColor(panel_util:GetColor4B(0xffffff))
        else
            if show_animation then
                self.root_node:runAction(cc.ScaleTo:create(0.2, 0.95, 0.95))
            else
                self.root_node:setScale(0.95)
            end
            self.root_node:setColor(panel_util:GetColor4B(0x7f7f7f))
        end
        self.is_selected = is_selected
    end
end

--显示选中框
function tramcar_sub_panel:ShowSelectedFrame(is_show, show_animation)
    if self.is_selected and is_show then
        if show_animation then
            self.select_node:runAction(cc.FadeIn:create(0.2))
            self.selected_action:gotoFrameAndPlay(0, 500, false)
        else
            self.select_node:setOpacity(255)
        end
    else
        if show_animation then
            self.select_node:runAction(cc.FadeOut:create(0.2))
        else
            self.select_node:setOpacity(0)
        end
    end
end

local escort_tramcar_panel = panel_prototype.New(true)
function escort_tramcar_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/tramcar_select_msgbox.csb")

    self.refresh_specify_tramcar_btn = self.root_node:getChildByName("refresh_btn_0")
    self.refresh_random_tramcar_btn = self.root_node:getChildByName("refresh_btn")
    self.start_escort_btn = self.root_node:getChildByName("confirm_btn")

    self.remain_escort_times_text = self.root_node:getChildByName("value1")
    self.free_refresh_times_text = self.root_node:getChildByName("value1_0")

    self.refresh_random_tramcar_cost = self.refresh_random_tramcar_btn:getChildByName("Text_83")
    self.refresh_random_tramcar_icon = self.refresh_random_tramcar_btn:getChildByName("blood_diamond_icon_0_0")
    self.refresh_random_tramcar_text = self.refresh_random_tramcar_btn:getChildByName("200reflash")

    self.buy_escort_btn = self.root_node:getChildByName("add_area_btn")

    self.refresh_free_text = self.refresh_random_tramcar_btn:getChildByName("free_reflash")

    self:RegisterEvent()
    self:RegisterWidgetEvent()

    self.tramcar_sub_panel_list = {}
    for index = 1, TRAMCAR_NUM do
        local tramcar_node = self.root_node:getChildByName(string.format("tramcar_%d", index))
        local selected_node = self.root_node:getChildByName(string.format("selected_effect_%d", index))
        
        local selected_animation = cc.CSLoader:createNode("ui/Node_car_light.csb")
        selected_animation:setScale(2)
        selected_animation:setPosition(tramcar_node:getContentSize().width / 2, tramcar_node:getContentSize().height / 2)
        tramcar_node:addChild(selected_animation, -1)

        local selected_action = animation_manager:GetTimeLine("tramcar_selected_timeline")
        selected_animation:runAction(selected_action)

        self.tramcar_sub_panel_list[index] = tramcar_sub_panel.New()
        self.tramcar_sub_panel_list[index]:Init(tramcar_node, selected_node, selected_action)
    end

end

function escort_tramcar_panel:Show()
    local tramcar_config = escort_logic:GetTramcarList()
    for index = 1, TRAMCAR_NUM do
        local tramcar_conf = tramcar_config[index]
        self.tramcar_sub_panel_list[index]:Show(tramcar_conf)
    end

    self:RefreshRemainEscortTimes()
    self:RefreshRemainFreeTimes()

    local escort_info = escort_logic:GetEscortInfo()
    self:ShowSelectedTramcar(escort_info.tramcar_id, false)
    self:ShowSelectedFrame(true, false)

    self.root_node:setVisible(true)
    
    if escort_logic:IsAutoRefreshTramcar() then
        escort_logic:RefreshTramcar("auto")
    end
end

--刷新剩余护送次数
function escort_tramcar_panel:RefreshRemainEscortTimes()
    local display_text = string.format(lang_constants:Get("mining_cave_battle_counts"), escort_logic:GetRemainEscortTimes(), constants["DEFAULT_ESCORT_TIMES"])
    self.remain_escort_times_text:setString(display_text)

    if escort_logic:GetRemainEscortTimes() > 0 then
        self.start_escort_btn:setColor(panel_util:GetColor4B(0xffffff))
        self.remain_escort_times_text:setColor(panel_util:GetColor4B(0xffe08a))
    else
        self.start_escort_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
        self.remain_escort_times_text:setColor(panel_util:GetColor4B(0xc45d1d))
    end
end

--刷新剩余免费随机刷新次数
function escort_tramcar_panel:RefreshRemainFreeTimes()
    if constants["FREE_REFRESH_TRAMCAR_TIMES"] > escort_logic:GetRefreshTramcarTimes() then
        local display_text = string.format(lang_constants:Get("mining_cave_battle_counts"), constants["FREE_REFRESH_TRAMCAR_TIMES"] - escort_logic:GetRefreshTramcarTimes(), constants["FREE_REFRESH_TRAMCAR_TIMES"])
        self.free_refresh_times_text:setString(display_text)
        
        self.refresh_free_text:setVisible(true)

        self.refresh_random_tramcar_cost:setVisible(false)
        self.refresh_random_tramcar_icon:setVisible(false)
        self.refresh_random_tramcar_text:setVisible(false)

        self.refresh_random_tramcar_btn:setColor(panel_util:GetColor4B(0xffffff))
    else
        local display_text = string.format(lang_constants:Get("mining_cave_battle_counts"), 0, constants["FREE_REFRESH_TRAMCAR_TIMES"])
        self.free_refresh_times_text:setString(display_text)
        self.refresh_random_tramcar_cost:setString(tostring(constants["ESCORT_REFRESH_TRAMCAR_RANDOM_COST"]))

        self.refresh_free_text:setVisible(false)

        self.refresh_random_tramcar_cost:setVisible(true)
        self.refresh_random_tramcar_icon:setVisible(true)
        self.refresh_random_tramcar_text:setVisible(true)

        if not resource_logic:CheckResourceNum(constants["RESOURCE_TYPE"]["blood_diamond"], constants["ESCORT_REFRESH_TRAMCAR_RANDOM_COST"], false) then
            self.refresh_random_tramcar_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
            self.refresh_random_tramcar_icon:setColor(panel_util:GetColor4B(0x7f7f7f))
        else
            self.refresh_random_tramcar_btn:setColor(panel_util:GetColor4B(0xffffff))
            self.refresh_random_tramcar_icon:setColor(panel_util:GetColor4B(0xffffff))
        end
    end
end

--显示滚动选择效果
function escort_tramcar_panel:ShowSelectedTramcar(selected_tramcar_id, show_animation)
    for index,sub_panel in ipairs(self.tramcar_sub_panel_list) do
        sub_panel:ShowSelected(selected_tramcar_id == index, show_animation)
    end
    self.selected_tramcar_id = selected_tramcar_id
end

--显示选定后的效果
function escort_tramcar_panel:ShowSelectedFrame(is_show, show_animation)
    for index,sub_panel in ipairs(self.tramcar_sub_panel_list) do
        sub_panel:ShowSelectedFrame(is_show, show_animation)
    end
end

function escort_tramcar_panel:RegisterEvent()
    --刷新选择的矿车
    graphic:RegisterEvent("refresh_select_tramcar", function(refresh_type)
        if not self.root_node:isVisible() then
            return
        end

        self:RefreshRemainFreeTimes()

        local escort_info = escort_logic:GetEscortInfo()
        if refresh_type == "random" or refresh_type == "auto" then
            --随机、自动选择需要显示老虎机一样的滚动选择动画
            local times = 1
            local speed = 0
            local show_tramcar_id = self.selected_tramcar_id

            local function func()
                --标记正在播放滚动动画
                self.show_selected_animation = true

                --根据当前已滚动次数获取停顿时长
                local stop = false
                for index,conf in ipairs(TRAMCAR_ANIMATION_CONFIG) do
                    if times >= conf.times then
                        speed = conf.speed
                        stop = index == #TRAMCAR_ANIMATION_CONFIG
                    end
                end

                --如果当前界面关闭了 或者 已经标记为需要停止且已经停顿在最终选中的矿车上时，停止播放
                if not self.root_node:isVisible() or (stop and escort_info.tramcar_id == show_tramcar_id) then
                    self:ShowSelectedFrame(true, true)
                    self.show_selected_animation = false
                    return
                end

                show_tramcar_id = show_tramcar_id + 1
                if show_tramcar_id > TRAMCAR_NUM then
                    show_tramcar_id = 1
                end

                --停顿一定时长后，显示滚动选择到下一个矿车并自调用
                local sequence = cc.Sequence:create(cc.DelayTime:create(speed), cc.CallFunc:create(function() self:ShowSelectedTramcar(show_tramcar_id, true) func() end))
                self.root_node:runAction(sequence)

                --递增滚动次数
                times = times + 1
            end
            func()

            --不限制选中框
            self:ShowSelectedFrame(false, true)
        elseif refresh_type == "specify" then
            --指定终极矿车直接显示选定后的动画
            self:ShowSelectedTramcar(escort_info.tramcar_id, true)
            self:ShowSelectedFrame(true, true)
        end
    end)

    --刷新剩余护送次数
    graphic:RegisterEvent("refresh_remain_escort_times", function(show_animation)
        self:RefreshRemainEscortTimes()
    end)
    
    --更新护送相关的次数
    graphic:RegisterEvent("update_escort_times", function()
        self:RefreshRemainEscortTimes()
        self:RefreshRemainFreeTimes()
    end)
end

function escort_tramcar_panel:RegisterWidgetEvent()
   --刷新指定终极矿车
    self.refresh_specify_tramcar_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            --当前正在播放滚动动画则提醒
            if not self.show_selected_animation then
                local escort_info = escort_logic:GetEscortInfo()
                --检查当前是否已经是终极矿车了
                if escort_info.tramcar_id ~= constants["SPECITY_TRAMCAR_ID"] then
                    local mode = client_constants.CONFIRM_MSGBOX_MODE["refresh_tramcar"]
                    graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode, "specify")
                else
                    graphic:DispatchEvent("show_prompt_panel", "already_specify_tramcar")
                end
            else
                graphic:DispatchEvent("show_prompt_panel", "is_selecting_tramcar")
            end
        end
    end)

    --随机刷新
    self.refresh_random_tramcar_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            --当前正在播放滚动动画则提醒
            if not self.show_selected_animation then
                local escort_info = escort_logic:GetEscortInfo()
                --检查当前是否已经是终极矿车了
                if escort_info.tramcar_id ~= constants["SPECITY_TRAMCAR_ID"] then
                    --是否免费刷新
                    if constants["FREE_REFRESH_TRAMCAR_TIMES"] > escort_logic:GetRefreshTramcarTimes() then
                        escort_logic:RefreshTramcar("random")
                    else
                        local mode = client_constants.CONFIRM_MSGBOX_MODE["refresh_tramcar"]
                        graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode, "random")
                    end
                else
                    graphic:DispatchEvent("show_prompt_panel", "already_specify_tramcar")
                end
            else
                graphic:DispatchEvent("show_prompt_panel", "is_selecting_tramcar")
            end
        end
    end)

    self.start_escort_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            --当前正在播放滚动动画则提醒
            if not self.show_selected_animation then
                --检查剩余护送次数
                if escort_logic:GetRemainEscortTimes() > 0 then
                    escort_logic:StartEscort()
                    graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
                else
                    graphic:DispatchEvent("show_prompt_panel", "no_escort_times")
                end
            else
                graphic:DispatchEvent("show_prompt_panel", "is_selecting_tramcar")
            end
        end
    end)

    self.buy_escort_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            --当前正在播放滚动动画则提醒
            if not self.show_selected_animation then

                local could_buy, cost = escort_logic:GetBuyEscortCost(1)
                if could_buy then
                    local mode = client_constants.CONFIRM_MSGBOX_MODE["buy_escort_times"]
                    graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode)
                else
                    graphic:DispatchEvent("show_prompt_panel", "has_buy_too_much_escort_times")
                end

            else
                graphic:DispatchEvent("show_prompt_panel", "is_selecting_tramcar")
            end
        end
    end)

    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("cancel_btn"), self:GetName())
end

return escort_tramcar_panel

