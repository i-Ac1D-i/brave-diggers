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
local FIRST_SUB_PANEL_OFFSET = -20
local MAX_SUB_PANEL_NUM = 7

local score_sub_panel = panel_prototype.New()
score_sub_panel.__index = score_sub_panel

function score_sub_panel.New()
    return setmetatable({}, score_sub_panel)
end

function score_sub_panel:Init(root_node)
    self.root_node = root_node

    self.name_text = self.root_node:getChildByName("name")

    self.base_score_text = self.root_node:getChildByName("base_score")
    self.kill_score_text = self.root_node:getChildByName("kill_score")
    self.field_score_text = self.root_node:getChildByName("field_score")
    self.round_score_text = self.root_node:getChildByName("round_score")

    self.score_text = self.root_node:getChildByName("score")
end

function score_sub_panel:Show(member_info)
    self.name_text:setString(member_info.leader_name)

    self.kill_score_text:setString(tostring(member_info.kill_score))
    self.base_score_text:setString(tostring(member_info.base_score))
    self.field_score_text:setString(tostring(member_info.field_score))
    self.round_score_text:setString(tostring(member_info.round_score))

    self.score_text:setString(tostring(member_info.score))

    self.root_node:setVisible(true)
end

local score_detail_msgbox = panel_prototype.New(true)
function score_detail_msgbox:Init()

    self.root_node = cc.CSLoader:createNode("ui/guildwar_score_detail_msgbox.csb")

    self.scroll_view = self.root_node:getChildByName("scrollview")
    self.template = self.root_node:getChildByName("template")

    self.close_btn = self.root_node:getChildByName("close_btn")

    self.name_text = self.root_node:getChildByName("name")
    self.kill_num_text = self.root_node:getChildByName("kill_txt")

    self.template:setVisible(false)

    self.sub_panel_num = 0
    self.score_sub_panels = {}

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.score_sub_panels, SUB_PANEL_HEIGHT, 1.0)
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

function score_detail_msgbox:Show(index)

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

    local height = math.max(self.member_num * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

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

    self.reuse_scrollview:Show(height, 0)

    self.root_node:setVisible(true)
end

function score_detail_msgbox:CreateSubPanels()
    local num = math.min(MAX_SUB_PANEL_NUM, self.member_num)

    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = score_sub_panel.New()
        sub_panel:Init(self.template:clone())

        self.score_sub_panels[i] = sub_panel
        sub_panel.root_node:setPositionX(10)
        self.scroll_view:addChild(sub_panel.root_node)
    end

    self.sub_panel_num = num
end

function score_detail_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())
end

return score_detail_msgbox
