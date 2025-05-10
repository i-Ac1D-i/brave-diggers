local graphic = require "logic.graphic"
local panel_prototype = require "ui.panel"
local config_manager = require "logic.config_manager"
local audio_manager = require "util.audio_manager"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local guild_logic = require "logic.guild"

local panel_util = require "ui.panel_util"
local reuse_scrollview = require "widget.reuse_scrollview"

local PLIST_TYPE = ccui.TextureResType.plistType
local SUB_PANEL_HEIGHT = 160
local FIRST_SUB_PANEL_OFFSET = -85
local MAX_SUB_PANEL_NUM = 5

local member_sub_panel = panel_prototype.New()
member_sub_panel.__index = member_sub_panel

function member_sub_panel.New()
    return setmetatable({}, member_sub_panel)
end

function member_sub_panel:Init(root_node)
    self.root_node = root_node

    self.name_text = self.root_node:getChildByName("name")

    self.point_num_icon = self.root_node:getChildByName("point_coin_icon")
    self.point_num_text = self.root_node:getChildByName("member_points")
    self.point_num_icon:setVisible(false)
    self.point_num_text:setVisible(false)

    self.kill_num_text = self.root_node:getChildByName("desc_kill")
    self.battle_num_text = self.root_node:getChildByName("desc_join")

    local alloc_node = self.root_node:getChildByName("buy_num_bg")
    
    self.sub_btn = alloc_node:getChildByName("sub_btn")
    self.add_btn = alloc_node:getChildByName("add_btn")
    self.add_ten_btn = alloc_node:getChildByName("add_btn_0")
    self.sub_ten_btn = alloc_node:getChildByName("add_btn_0_0")

    self.alloc_num_text = alloc_node:getChildByName("points")
end

function member_sub_panel:Show(member_info)
    self.member_info = member_info
    
    self.name_text:setString(member_info.leader_name)

    self.kill_num_text:setString(string.format(lang_constants:Get("guild_war_member_kill_num"), member_info.win_num))
    self.battle_num_text:setString(string.format(lang_constants:Get("guild_war_member_battle_num"), member_info.battle_round))

    --self.point_num_text:setString(tostring(member_info.season_score))

    self:RefreshInfo()

    self.root_node:setVisible(true)
end


function member_sub_panel:RefreshInfo()
    if guild_logic:IsGuildChairman() and guild_logic:GetIsAllocated() == false then 
        self.sub_btn:setVisible(true)
        self.add_btn:setVisible(true)
        self.add_ten_btn:setVisible(true)
        self.sub_ten_btn:setVisible(true)
    else
        self.sub_btn:setVisible(false)
        self.add_btn:setVisible(false)
        self.add_ten_btn:setVisible(false)
        self.sub_ten_btn:setVisible(false)
    end

    self.alloc_num_text:setString(tostring(self.member_info.alloc_num))
end

function member_sub_panel:RefreshBtn(now_surplus)
    now_surplus = now_surplus or 0
    if self.member_info.alloc_num > 0 then
        self.sub_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
        self.sub_ten_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
    else
        self.sub_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
        self.sub_ten_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
    end

    if now_surplus > 0 then
        self.add_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
        self.add_ten_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
    else
        self.add_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
        self.add_ten_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
    end

end

local bonus_allocation_panel = panel_prototype.New(true)
function bonus_allocation_panel:Init()

    self.root_node = cc.CSLoader:createNode("ui/guildwar_rewards_panel.csb")

    self.scroll_view = self.root_node:getChildByName("scrollview")
    self.template = self.scroll_view:getChildByName("template")
    self.template:setVisible(false)

    self.close_btn = self.root_node:getChildByName("close_btn")
    self.up_btn = self.root_node:getChildByName("up_btn")

    self.guild_all_bonus_text = self.root_node:getChildByName("point_coin_num")
    self.alloc_btn = self.root_node:getChildByName("allot_btn")
    self.auto_btn = self.root_node:getChildByName("auto_btn")
    self.reset_btn = self.root_node:getChildByName("reset_btn")

    self.title_text = self.root_node:getChildByName("title")
    self.tip_text = self.root_node:getChildByName("desc_tip")

    self.cur_alloc_bouns = guild_logic:GetAllocBonus()

    self.sub_panel_num = 0
    self.member_sub_panels = {}

    self.member_list = guild_logic:GetMemberList()
    self.member_num = guild_logic:GetCurMemberNum()

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.member_sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return self.parent_panel.member_num
        end,

        function(self, sub_panel, is_up)
            local index = is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
            sub_panel:Show(self.parent_panel.member_list[index])
        end
    )

    self:RegisterEvent()
    self:RegisterWidgetEvent()

    self:CreateSubPanels()

    self:ResetAllocBouns()
end

function bonus_allocation_panel:RefreshInfo()
    local desc_name
    if guild_logic:IsGuildChairman() and guild_logic:GetIsAllocated() == false then 
        desc_name = "guild_war_alloc_title1"  
        desc_tip = "guild_war_alloc_tip1"  

        self.alloc_btn:setVisible(true)
        self.auto_btn:setVisible(true)
        self.reset_btn:setVisible(true)
    else
        desc_name = "guild_war_alloc_title2"
        desc_tip = "guild_war_alloc_tip2"  

        self.alloc_btn:setVisible(false)
        self.auto_btn:setVisible(false)
        self.reset_btn:setVisible(false)
    end
    
    self.title_text:setString(lang_constants:Get(desc_name))
    self.tip_text:setString(lang_constants:Get(desc_tip))
end

function bonus_allocation_panel:RefreshSubPanelInfo()
    for i = 1, self.sub_panel_num do
    local sub_panel = self.member_sub_panels[i]
        sub_panel:RefreshInfo()
    end
end

function bonus_allocation_panel:RefreshSubPanelBtn()
    for i = 1, self.sub_panel_num do
    local sub_panel = self.member_sub_panels[i]
        sub_panel:RefreshBtn(self.cur_alloc_bouns)
    end
    
end

function bonus_allocation_panel:RefreshAllocBouns(cur_alloc_bouns)
    self.cur_alloc_bouns = cur_alloc_bouns
    self.guild_all_bonus_text:setString(self.cur_alloc_bouns)
    self:RefreshSubPanelBtn()
end

function bonus_allocation_panel:Show()
    self:RefreshInfo()
    self.root_node:setVisible(true)
end

function bonus_allocation_panel:CreateSubPanels()
    local num = math.min(MAX_SUB_PANEL_NUM, self.member_num)

    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = member_sub_panel.New()
        sub_panel:Init(self.template:clone())

        self.member_sub_panels[i] = sub_panel
        sub_panel.sub_btn:addTouchEventListener(self.sub_btn_method)
        sub_panel.add_btn:addTouchEventListener(self.add_btn_method)
        sub_panel.add_ten_btn:addTouchEventListener(self.add_ten_btn_method)
        sub_panel.sub_ten_btn:addTouchEventListener(self.sub_ten_btn_method)

        sub_panel.sub_btn:setTag(i)
        sub_panel.add_btn:setTag(i)
        sub_panel.add_ten_btn:setTag(i)
        sub_panel.sub_ten_btn:setTag(i)
        self.scroll_view:addChild(sub_panel.root_node)
    end

    self.sub_panel_num = num

    
    local height = math.max(self.member_num * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

    for i = 1, self.sub_panel_num do
        local sub_panel = self.member_sub_panels[i]

        sub_panel:Show(self.member_list[i])
        sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - (i - 1) * SUB_PANEL_HEIGHT)
    end

    self.reuse_scrollview:Show(height, 0)
end

function bonus_allocation_panel:RegisterEvent()
    graphic:RegisterEvent("update_guild_alloc_bonus", function()
        if not self.root_node:isVisible() then
            return
        end
        self.member_list = guild_logic:GetMemberList()

        self:RefreshInfo()
        self:ResetAllocBouns()
    end)
end

function bonus_allocation_panel:ResetAllocBouns()
    self:RefreshSubPanelInfo()
    self:RefreshAllocBouns(guild_logic:GetAllocBonus())
end

function bonus_allocation_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())

    self.auto_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local alloc_bouns = guild_logic:GetAllocBonus()
            if guild_logic:GetIsAllocated() == false and alloc_bouns > 0 then
                local avg_alloc_num = math.floor(alloc_bouns / self.member_num)
                local mode_alloc_num = alloc_bouns - avg_alloc_num * self.member_num

                for i,member_info in pairs(self.member_list) do
                    if mode_alloc_num > 0 then
                        member_info.alloc_num = avg_alloc_num + 1
                        mode_alloc_num = mode_alloc_num - 1
                    else
                        member_info.alloc_num = avg_alloc_num
                    end
                end
            end
            self:RefreshSubPanelInfo()

            self.cur_alloc_bouns = 0
            self:RefreshAllocBouns(0)
        end
    end)

    self.reset_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            for i,member_info in pairs(self.member_list) do
                member_info.alloc_num = 0
            end
            self:ResetAllocBouns()
        end
    end)

    self.alloc_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local alloc_bouns = guild_logic:GetAllocBonus()
            if guild_logic:GetIsAllocated() == false then
                if alloc_bouns > 0 then
                    local alloc_list = {}

                    local total_alloc_num = 0
                    for i,member_info in pairs(self.member_list) do
                        total_alloc_num = total_alloc_num + member_info.alloc_num
                        table.insert(alloc_list, {user_id = member_info.user_id, alloc_num = member_info.alloc_num})
                    end

                    if total_alloc_num ~= alloc_bouns then
                        graphic:DispatchEvent("show_prompt_panel", "not_alloc_all_bouns")
                        return 
                    end

                    guild_logic:AllocBonus(alloc_list)
                else
                    graphic:DispatchEvent("show_prompt_panel", "no_alloc_bouns")
                end
            end

        end
    end)

    self.sub_btn_method = function(widget, event_type)
        local index = widget:getTag()
        local sub_panels = self.member_sub_panels[index]
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")

            local t = 0
            local function sub_func()
                if sub_panels.member_info.alloc_num > 0 then
                    sub_panels.member_info.alloc_num = sub_panels.member_info.alloc_num - 1
                    sub_panels:RefreshInfo()

                    self:RefreshAllocBouns(self.cur_alloc_bouns + 1)
                end
            end
            sub_func()

            schedule(sub_panels.alloc_num_text, function ( ... )
                if t > 20 then
                    sub_func()
                else
                    t = t + 1
                end
            end, 0.02)

        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            sub_panels.alloc_num_text:stopAllActions()
        end
    end

    
    self.add_btn_method = function(widget, event_type)
        local index = widget:getTag()
        local sub_panels = self.member_sub_panels[index]
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")

            local t = 0
            local function add_func()
                if self.cur_alloc_bouns > 0 then
                    sub_panels.member_info.alloc_num = sub_panels.member_info.alloc_num + 1
                    sub_panels:RefreshInfo()
                    self:RefreshAllocBouns(self.cur_alloc_bouns - 1)
                    
                end
            end
            add_func()

            schedule(sub_panels.alloc_num_text, function ( ... )
                if t > 20 then
                    add_func()
                else
                    t = t + 1
                end
            end, 0.02)

        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            sub_panels.alloc_num_text:stopAllActions()
        end
    end

    self.add_ten_btn_method = function(widget, event_type)
        local index = widget:getTag()
        local sub_panels = self.member_sub_panels[index]
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")

            local t = 0
            local function add_func()
                if (self.cur_alloc_bouns - 10) > 0 then
                    sub_panels.member_info.alloc_num = sub_panels.member_info.alloc_num + 10
                    sub_panels:RefreshInfo()

                    self:RefreshAllocBouns(self.cur_alloc_bouns - 10)
                elseif self.cur_alloc_bouns > 0 then
                    sub_panels.member_info.alloc_num = sub_panels.member_info.alloc_num + self.cur_alloc_bouns
                    sub_panels:RefreshInfo()
                    self:RefreshAllocBouns(self.cur_alloc_bouns - self.cur_alloc_bouns)
                end
            end
            add_func()

            schedule(sub_panels.alloc_num_text, function ( ... )
                if t > 20 then
                    add_func()
                else
                    t = t + 1
                end
            end, 0.02)

        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            sub_panels.alloc_num_text:stopAllActions()
        end
    end

    self.sub_ten_btn_method = function(widget, event_type)
        local index = widget:getTag()
        local sub_panels = self.member_sub_panels[index]
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")

            local t = 0
            local function add_func()
                if (sub_panels.member_info.alloc_num - 10) > 0 then
                    sub_panels.member_info.alloc_num = sub_panels.member_info.alloc_num - 10
                    sub_panels:RefreshInfo()

                    self:RefreshAllocBouns(self.cur_alloc_bouns + 10)
                elseif sub_panels.member_info.alloc_num > 0 then
                    local now_surplus = sub_panels.member_info.alloc_num
                    sub_panels.member_info.alloc_num = sub_panels.member_info.alloc_num - now_surplus
                    sub_panels:RefreshInfo()
                    self:RefreshAllocBouns(self.cur_alloc_bouns + now_surplus)
                end
            end
            add_func()

            schedule(sub_panels.alloc_num_text, function ( ... )
                if t > 20 then
                    add_func()
                else
                    t = t + 1
                end
            end, 0.02)

        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            sub_panels.alloc_num_text:stopAllActions()
        end
    end

    self.up_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.scroll_view:scrollToTop(0.2, true)
        end
    end)
end

return bonus_allocation_panel
