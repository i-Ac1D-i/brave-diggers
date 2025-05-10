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
local SUB_PANEL_HEIGHT = 80
local FIRST_SUB_PANEL_OFFSET = -41
local MAX_SUB_PANEL_NUM = 7

local score_sub_panel = panel_prototype.New()
score_sub_panel.__index = score_sub_panel

function score_sub_panel.New()
    return setmetatable({}, score_sub_panel)
end

function score_sub_panel:Init(root_node)
    self.root_node = root_node

    self.name_text = self.root_node:getChildByName("name")
    self.buff_num_text = self.root_node:getChildByName("buff_number")
    self.kill_num_text = self.root_node:getChildByName("kill_value")
    self.score_text = self.root_node:getChildByName("points_value")
    self.replay_btn = self.root_node:getChildByName("replay_btn")
end

function score_sub_panel:Show(member_info)
    self.name_text:setString(member_info.leader_name)

    self.kill_num_text:setString(tostring(member_info.win_num))
    self.score_text:setString(tostring(member_info.score))

    local m = guild_logic:GetMemberByUserid(member_info.user_id)

    if m then
        self.buff_num_text:setString(tostring(m.buff_num))
    else
        self.buff_num_text:setString("0")
    end

    self.user_id = member_info.user_id
    self.replay_btn:setVisible(member_info.battle_num > 0)

    self.root_node:setVisible(true)
end

local battle_summary_msgbox = panel_prototype.New(true)
function battle_summary_msgbox:Init()

    self.root_node = cc.CSLoader:createNode("ui/guildwar_summary_panel.csb")

    self.scroll_view = self.root_node:getChildByName("scrollview")
    self.template = self.scroll_view:getChildByName("template")

    self.close_btn = self.root_node:getChildByName("close_btn")

    self.name_text = self.root_node:getChildByName("name")
    self.kill_num_text = self.root_node:getChildByName("kill_txt")

    self.view_detail_btn = self.root_node:getChildByName("points_rule_btn")

    self.no_enemy_text = self.scroll_view:getChildByName("no_enemy_txt")

    self.template:setVisible(false)

    self.sub_panel_num = 0
    self.score_sub_panels = {}

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.score_sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return self.parent_panel.member_num
        end,

        function(self, sub_panel, is_up)
            local index = is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
            sub_panel:Show(self.parent_panel.member_list[index])
        end
    )

    self:RegisterWidgetEvent()
end

function battle_summary_msgbox:Show(index)
    self.index = index
    local all_list = guild_logic:GetWarMemberList()
    self.member_list = {}
    if all_list then 
      for i = 1 , #all_list do 
        local member = all_list[i]
        if member.war_field == index then  
           table.insert(self.member_list, member)               
        end
      end
    end

    self.member_num = #self.member_list
  
    self:CreateSubPanels()

    local height = self.reuse_scrollview:CalcHeight()

    for i = 1, self.sub_panel_num do
        local sub_panel = self.score_sub_panels[i]
        local member = self.member_list[i]

        if member then
            sub_panel:Show(member)
            sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - (i - 1) * SUB_PANEL_HEIGHT)
        else
            sub_panel:Hide()
        end
    end


    local rep_fade = cc.RepeatForever:create(cc.Sequence:create(cc.FadeTo:create(3, 50), cc.FadeTo:create(3, 200)))
    self.view_detail_btn:runAction(rep_fade)

    self.reuse_scrollview:Show(height, 0)

    self.no_enemy_text:setVisible(guild_logic:GetVsTroopNum(index) == 0)

    self.root_node:setVisible(true)
end

function battle_summary_msgbox:CreateSubPanels()
    local num = math.min(MAX_SUB_PANEL_NUM, self.member_num)

    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = score_sub_panel.New()
        sub_panel:Init(self.template:clone())

        self.score_sub_panels[i] = sub_panel
        sub_panel.replay_btn:addTouchEventListener(self.view_record_method)
        sub_panel.replay_btn:setTag(i)
        self.scroll_view:addChild(sub_panel.root_node)
    end

    self.sub_panel_num = num
end

function battle_summary_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())

    self.view_record_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")

            local index = widget:getTag()
            local sub_panel = self.score_sub_panels[index]

            guild_logic:QueryBattleRecord(sub_panel.user_id)
        end
    end

    self.view_detail_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "guild.score_detail_msgbox", self.index)
        end
    end)
end

return battle_summary_msgbox
