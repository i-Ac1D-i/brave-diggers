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

local BATTLE_STATUS = client_constants.BATTLE_STATUS

local PLIST_TYPE = ccui.TextureResType.plistType
local SUB_PANEL_HEIGHT = 102
local FIRST_SUB_PANEL_OFFSET = -48
local MAX_SUB_PANEL_NUM = 7

local record_sub_panel = panel_prototype.New()
record_sub_panel.__index = record_sub_panel

function record_sub_panel.New()
    return setmetatable({}, record_sub_panel)
end

function record_sub_panel:Init(root_node)
    self.root_node = root_node
    self.desc_text = self.root_node:getChildByName("desc")
end

function record_sub_panel:Show(record_index)
    self.record_index = record_index

    local record = guild_logic:GetSingleBattleRecord(record_index)
    local rival_name = record.player1.user_id == self.user_id and record.player2.leader_name or record.player1.leader_name

    if record.win_user_id == "" then
        --draw game
        self.desc_text:setString(lang_constants:GetFormattedStr("guild_war_battle_result1", rival_name))
        self.status = BATTLE_STATUS["draw"]

    elseif record.win_user_id == self.user_id and record.self_mirror_win == 0 then
        --win
        self.desc_text:setString(lang_constants:GetFormattedStr("guild_war_battle_result2", rival_name))
        self.status = BATTLE_STATUS["win"]

    else
        --lose
        self.desc_text:setString(lang_constants:GetFormattedStr("guild_war_battle_result3", rival_name))
        self.status = BATTLE_STATUS["lose"]
    end

    self.record = record
    self.root_node:setVisible(true)
end

local battle_replay_msgbox = panel_prototype.New(true)

function battle_replay_msgbox:Init()

    self.root_node = cc.CSLoader:createNode("ui/guildwar_battle_replay_msgbox.csb")

    self.scroll_view = self.root_node:getChildByName("scrollview")
    self.template = self.scroll_view:getChildByName("template")

    self.close_btn = self.root_node:getChildByName("close_btn")

    self.name_text = self.root_node:getChildByName("name")
    self.kill_num_text = self.root_node:getChildByName("kill_txt")
    self.buff_num_text = self.root_node:getChildByName("buff_number")

    self.template:setVisible(false)

    self.sub_panel_num = 0
    self.record_sub_panels = {}

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.record_sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return self.parent_panel.record_num
        end,

        function(self, sub_panel, is_up)
            local index = is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
            sub_panel:Show(index)
        end
    )

    self:RegisterWidgetEvent()
end

function battle_replay_msgbox:Show(user_id)
    local all_records = guild_logic:GetCurBattleRecords()

    self.all_records = all_records
    self.record_num = #all_records

    self.user_id = user_id

    local member = guild_logic:GetMemberByUserid(user_id)

    self.name_text:setString(all_records.leader_name)
    self.kill_num_text:setString(string.format(lang_constants:Get("guild_war_win_num"), all_records.win_num))
    self.buff_num_text:setString(tostring(member.buff_num))

    record_sub_panel.user_id = user_id

    self:CreateSubPanels()

    local height = math.max(self.record_num * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

    for i = 1, self.sub_panel_num do
        local sub_panel = self.record_sub_panels[i]
        local record = self.all_records[i]

        if record then
            sub_panel:Show(i)
            sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - (i - 1) * SUB_PANEL_HEIGHT)
        else
            sub_panel:Hide()
        end
    end

    self.reuse_scrollview:Show(height, 0)

    self.root_node:setVisible(true)
end

function battle_replay_msgbox:CreateSubPanels()
    local num = math.min(MAX_SUB_PANEL_NUM, self.record_num)

    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = record_sub_panel.New()
        sub_panel:Init(self.template:clone())

        self.record_sub_panels[i] = sub_panel
        sub_panel.root_node:addTouchEventListener(self.view_record_method)
        sub_panel.root_node:setTag(i)
        self.scroll_view:addChild(sub_panel.root_node)
    end

    self.sub_panel_num = num
end

function battle_replay_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())

    self.view_record_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")

            local index = widget:getTag()
            local sub_panel = self.record_sub_panels[index]

            local battle_type = client_constants.BATTLE_TYPE["vs_guild_player"]
            local record = sub_panel.record

            graphic:DispatchEvent("show_battle_room", battle_type, sub_panel.record_index, record.battle_property, record.battle_record, sub_panel.status, function()
                graphic:DispatchEvent("show_world_sub_panel", "guild.battle_replay_msgbox", self.user_id)
            end)
        end
    end
end

return battle_replay_msgbox
