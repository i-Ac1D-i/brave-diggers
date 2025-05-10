local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local guild_logic = require "logic.guild"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local config_manager = require "logic.config_manager"
local feature_config = require "logic.feature_config"

local reuse_scrollview = require "widget.reuse_scrollview"

local PLIST_TYPE = ccui.TextureResType.plistType
local MEMBER_TAB_SHOW = 1
local GUILD_TAB_SHOW = 2
local GUILD_BOSS_TAG_SHOW = 3
local RANK_CELL_HEIGHT = {
    [1] = 114,
    [2] = 120,
    [3] = 120,
}
local KILL_TITLE_NUM = {
    [1] = 7,
    [2] = 6,
    [3] = 5,
}
local FIRST_SUB_PANEL_OFFSET = -70
local GUILD_SUB_PANEL_OFFSET = -30
local GUILD_BOSS_SUB_PANEL_OFFSET = -15
local MAX_SUB_PANEL_NUM = 7
local MAX_GUILD_SUB_PANEL_NUM = 8
local TAB_NOT_CLICKED_COLOR = 0x7F7F7F
local TAB_CLICKED_COLOR = 0xFFFFFF

local RANK_BONUS_MAP = constants["GUILDWAR_RANK_BONUS_MAP"]

local rank_cell_panel = panel_prototype.New()
rank_cell_panel.__index = rank_cell_panel

function rank_cell_panel.New()
    return setmetatable({}, rank_cell_panel)
end

function rank_cell_panel:Init(root_node, index, data, show_type)
    
    self.root_node = root_node
    self.index = index
    self.data = data
    self.show_type = show_type

    self.name_text = self.root_node:getChildByName("name")
    self.rank_text = self.root_node:getChildByName("rank")
    self.rank_bg_img = self.root_node:getChildByName("rank_bg")

    if show_type == GUILD_TAB_SHOW then 
        self.name_text = self.root_node:getChildByName("name")
        self.score_text = self.root_node:getChildByName("rank_points")
        self.reward_points_text = self.root_node:getChildByName("reward_points")
    elseif show_type == MEMBER_TAB_SHOW then 
        self.battle_num_text = self.root_node:getChildByName("join_number")
        self.kill_num_text = self.root_node:getChildByName("kill_number")
        self.role_img = self.root_node:getChildByName("role")
        self.score = self.root_node:getChildByName("point_member")

        --杀敌数称号
        self.kill_title_img = {}
        for i = 1, #KILL_TITLE_NUM do
            self.kill_title_img[i] = self.root_node:getChildByName("title_type0" .. i)
            self.kill_title_img[i]:setVisible(false)
        end
        self.kill_title_text = self.root_node:getChildByName("title_txt")
        self.kill_title_text:setVisible(false)
    elseif show_type == GUILD_BOSS_TAG_SHOW then 
        self.reward_txt = self.root_node:getChildByName("reward_txt")
        self.reward_points_0 = self.root_node:getChildByName("reward_points_0")
    end

    -- self.icon_panel = icon_panel.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    -- self.icon_panel:Init(self.root_node)
    -- self.icon_panel:SetPosition(58, 62)
    -- self.blood_value_text = self.root_node:getChildByName("blood_name")
    -- panel_util:SetTextOutline(self.blood_value_text, 0x000, 2)
end

function rank_cell_panel:SetData()
    local rank_bg_color = 0xFFFFFF 

    self.name_text:setString(self.data.leader_name)
    self.rank_text:setString(tostring(self.index))

    if self.show_type == GUILD_TAB_SHOW then 
        self.name_text:setString(self.data.guild_name)
        self.score_text:setString(tostring(self.data.war_score))
        local bonus = RANK_BONUS_MAP[self.index] or 0
        self.reward_points_text:setString(tostring(bonus))
    elseif self.show_type == MEMBER_TAB_SHOW then 
        self.battle_num_text:setString(string.format(lang_constants:Get("guild_war_member_battle_num"), self.data.battle_round))
        self.kill_num_text:setString(string.format(lang_constants:Get("guild_war_member_kill_num"), self.data.win_num))
        local conf = config_manager.mercenary_config[self.data.template_id]
        self.role_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. conf.sprite .. ".png", PLIST_TYPE)
        self.score:setString(tostring(self.data.season_score))

        self.kill_title_text:setVisible(false)
        for k,kill_title_img in pairs(self.kill_title_img) do
            kill_title_img:setVisible(false)
        end
    
        for i = #KILL_TITLE_NUM, 1, -1 do
            if self.data.win_num >= KILL_TITLE_NUM[i] then
                self.kill_title_text:setString(lang_constants:Get("guild_war_rank_kill_title" .. i))
                self.kill_title_text:setVisible(true)
                self.kill_title_img[i]:setVisible(true)
                break
            end
        end
    elseif self.show_type == GUILD_BOSS_TAG_SHOW then 
        self.name_text:setString(self.data.guild_name)
        self.reward_txt:setString(lang_constants:Get("guild_boss_kill_title")..tostring(self.data.kill_boss_count))
        self.reward_points_0:setString(tostring(self.data.kill_boss_all_damage))
    end

    if self.index == 1 then
        rank_bg_color = 0xFFDD00
    elseif self.index >= 3 then
        rank_bg_color = 0xCBB48A
    end

    if rank_bg_color then 
        self.rank_bg_img:setColor(panel_util:GetColor4B(rank_bg_color))
    end
end

function rank_cell_panel:Show(data, index)
    self.index = index
    self.data = data
    self:SetData()
    self.root_node:setVisible(true)
end

function rank_cell_panel:RemoveSelf()
    self.root_node:removeFromParent()
end

local ranklist_tab = panel_prototype.New(true)
ranklist_tab.__index = ranklist_tab

function ranklist_tab.New()
    return setmetatable({}, ranklist_tab)
end

function ranklist_tab:Init(root_node, tab_type)
    self.root_node = root_node 
    self.ranklist_type = tab_type

    self.tab_text = self.root_node:getChildByName("txt")
    self.tab_text:setCascadeColorEnabled(true)

    self.root_node:setTag(self.ranklist_type)
    self.root_node:setTouchEnabled(true)
    self.root_node:setCascadeColorEnabled(true)    
end

function ranklist_tab:Show()
    self.root_node:setVisible(true)
end

function ranklist_tab:Hide()
    self.root_node:setVisible(false)
end

function ranklist_tab:SetTabColor(color)
    self.root_node:setColor(panel_util:GetColor4B(color))
    self.tab_text:setColor(panel_util:GetColor4B(color))
end

local ranklist_panel = panel_prototype.New(true)
ranklist_panel.__index = ranklist_panel
function ranklist_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/guildwar_ranklist_panel.csb")
    self.desc_text = self.root_node:getChildByName("desc_tip")
    
    self.scroll_view = self.root_node:getChildByName("scrollview")

    self.tab_node = { [MEMBER_TAB_SHOW] = {}, [GUILD_TAB_SHOW] = {}, [GUILD_BOSS_TAG_SHOW] = {}}

    self.template_member = self.scroll_view:getChildByName("template_personal")
    self.template_member:setVisible(false)
    self.template_guild = self.scroll_view:getChildByName("template_guild")
    self.template_guild:setVisible(false)
    self.template_guild_boss =self.scroll_view:getChildByName("template_guild_boss")
    self.template_guild_boss:setVisible(false)
    
    self.template_guild_default = self.scroll_view:getChildByName("node_txt")
    self.template_guild_default:setVisible(false)

    self.default_txt1 = self.template_guild_default:getChildByName("default_txt1")

    self.rank_cells = {}
    self.data_list = {}
    self.reuse_scrollview = nil
   
    for i = 1, #self.tab_node do 
        self.tab_node[i] = ranklist_tab.New()
        local tab_panel
        if i == MEMBER_TAB_SHOW then 
           tab_panel = self.root_node:getChildByName("personal_rank_tab")
        elseif i == GUILD_TAB_SHOW then 
           tab_panel = self.root_node:getChildByName("top_rank_tab")
        elseif i == GUILD_BOSS_TAG_SHOW then
           tab_panel = self.root_node:getChildByName("boss_rank_tab")
        end
        self.tab_node[i]:Init(tab_panel, i)
    end

    self.tab_node[MEMBER_TAB_SHOW]:SetTabColor(TAB_CLICKED_COLOR)
    self.tab_node[GUILD_TAB_SHOW]:SetTabColor(TAB_NOT_CLICKED_COLOR)
    self.tab_node[GUILD_BOSS_TAG_SHOW]:SetTabColor(TAB_NOT_CLICKED_COLOR)

    self.show_tab = MEMBER_TAB_SHOW

    self:CreateScrollView()

    self.scroll_view:setTouchEnabled(true)
    self.scroll_view:setVisible(true)

    self.up_btn = self.root_node:getChildByName("up_btn")
    self.up_btn:setTouchEnabled(true)

    self.close_btn = self.root_node:getChildByName("close_btn")    

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function ranklist_panel:CreateScrollView()
    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.rank_cells, RANK_CELL_HEIGHT[self.show_tab])
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return #self.parent_panel.data_list
        end,

        function(self, sub_panel, is_up)
            local index = is_up and self.data_offset + #self.parent_panel.rank_cells or self.data_offset + 1
            sub_panel:Show(self.parent_panel.data_list[index], index)
        end
    )
end

function ranklist_panel:CreateRankList()
    self.data_list = {}
    local cell_template 

    for k, v in ipairs(self.rank_cells) do 
        v:RemoveSelf()
    end
    self.rank_cells = {}
    self.template_guild_default:setVisible(false)
    
    if self.show_tab == GUILD_TAB_SHOW then 
        cell_template = self.template_guild
        self.data_list = guild_logic:GetRankList() or {}
        self.panel_offset = GUILD_SUB_PANEL_OFFSET
        self.panel_nums = MAX_GUILD_SUB_PANEL_NUM
    elseif self.show_tab == MEMBER_TAB_SHOW then 
        guild_logic:SortMemberList(client_constants["MEMBER_SORT_TYPE"]["score"])
        self.data_list = guild_logic.member_list 
        cell_template = self.template_member
        self.panel_offset = FIRST_SUB_PANEL_OFFSET
        self.panel_nums = MAX_SUB_PANEL_NUM
    elseif self.show_tab == GUILD_BOSS_TAG_SHOW then
        self.data_list = guild_logic:GetBossRankList() 
        cell_template = self.template_guild_boss
        self.panel_offset = GUILD_BOSS_SUB_PANEL_OFFSET
        self.panel_nums = MAX_SUB_PANEL_NUM
    end

    local num = math.min(self.panel_nums, #self.data_list)
    self.reuse_scrollview:BindSubPanels(self.rank_cells)
   
    if #self.data_list > 0 then 
       for i = 1, num do
           local cell = rank_cell_panel.New()
           cell:Init(cell_template:clone(), i, self.data_list[i], self.show_tab)
           self.rank_cells[i] = cell
           self.scroll_view:addChild(cell.root_node)
       end
    else
       self.template_guild_default:setVisible(true)
       self.default_txt1:setString(lang_constants:Get("guild_ranklist_panel_tips"..self.show_tab))
    end
end

function ranklist_panel:LoadTab(new_tab)
    local new_tab = new_tab or 0
    
    if new_tab > 0 then 
       self:SwitchTabShow(false)
       self.show_tab = new_tab
    end
    
    self:ShowTabDesc()
    self:CreateRankList()
    self:LoadRankList()
    self:SwitchTabShow(true)
end

function ranklist_panel:SwitchTabShow(flag)
    local tab_color = TAB_NOT_CLICKED_COLOR
    if flag then 
        tab_color = TAB_CLICKED_COLOR
    end

    self.tab_node[self.show_tab]:SetTabColor(tab_color)   
end

function ranklist_panel:Show()
    self:LoadTab()
    self.root_node:setVisible(true)
end

function ranklist_panel:LoadRankList()
    local scrollview_height = math.max(RANK_CELL_HEIGHT[self.show_tab] * #self.data_list, self.reuse_scrollview.sview_height) 
                
    for i = 1, #self.rank_cells do 
         local cell = self.rank_cells[i]
         if self.data_list[i] then 
             cell:Show(self.data_list[i], i)
             cell.root_node:setPositionY(scrollview_height + self.panel_offset - (i - 1) * RANK_CELL_HEIGHT[self.show_tab])
         else
             cell:Hide()
         end
    end
    self.reuse_scrollview:Show(scrollview_height, 0)
end


function ranklist_panel:ShowTabDesc()
    local desc_name
    if self.show_tab == GUILD_TAB_SHOW then 
        desc_name = "guild_war_guild_ranklist_desc"  
    elseif self.show_tab == MEMBER_TAB_SHOW then 
        desc_name = "guild_war_member_ranklist_desc"
    elseif self.show_tab == GUILD_BOSS_TAG_SHOW then 
        desc_name = "guild_boss_ranklist_desc"
    end
    
    self.desc_text:setString(lang_constants:Get(desc_name))
end

function ranklist_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())

    -- tab
    local tab_touch_event = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            local show_tab = widget:getTag()

            if show_tab == GUILD_BOSS_TAG_SHOW then
                if not feature_config:IsFeatureOpen("guild_boss") then
                    graphic:DispatchEvent("show_prompt_panel", "feature_is_opening_soon")
                    return
                end
            end

            self:LoadTab(show_tab)
        end
    end
    
    for i = 1, #self.tab_node do 
        self.tab_node[i]:GetRootNode():addTouchEventListener(tab_touch_event)
    end

    self.up_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.scroll_view:scrollToTop(0.2, true)
        end
    end)
end

function ranklist_panel:RegisterEvent()

    graphic:RegisterEvent("guild_ranking_refsh", function()
        if not self.root_node:isVisible() then
            return
        end
        self:Show()
    end)

end

return ranklist_panel

