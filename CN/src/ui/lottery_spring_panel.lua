local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"
local configuration = require "util.configuration"
local lang_constants = require "util.language_constants"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local graphic = require "logic.graphic"
local time_logic = require "logic.time"
local user_logic = require "logic.user"
local troop_logic = require "logic.troop"
local carnival_logic = require "logic.carnival"

local reuse_scrollview = require "widget.reuse_scrollview"

local icon_panel = require "ui.icon_panel"

local RANK_CELL_HEIGHT = 118 
local FIRST_SUB_PANEL_OFFSET = -60
local MARGIN_CELL_HEIGHT = 1
local MAX_RANK_CELLS = 6

local MAX_RANK_NUM = 50
local PLIST_TYPE = ccui.TextureResType.plistType

local rank_cell_panel = panel_prototype.New()
rank_cell_panel.__index = rank_cell_panel

function rank_cell_panel.New()
    return setmetatable({}, rank_cell_panel)
end

function rank_cell_panel:Init(root_node, index)
    self.root_node = root_node
    self.index = index
    self.config_data = nil

    self.name_text = self.root_node:getChildByName("name")
    self.open_time_text = self.root_node:getChildByName("time")
    self.root_node:getChildByName("role"):setVisible(false)
    self.icon_panel = icon_panel.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(self.root_node)
    self.icon_panel:SetPosition(58, 62)
    self.tip_img = self.root_node:getChildByName("tip_bg")
    self.tip_img:setVisible(false)
    self.blood_value_text = self.root_node:getChildByName("blood_name")
    panel_util:SetTextOutline(self.blood_value_text, 0x000, 2)
end

function rank_cell_panel:SetData()
    self.name_text:setString(self.config_data.user_name)

    local time_info = time_logic:GetDateInfo(self.config_data.open_time)
    self.open_time_text:setString(string.format(lang_constants:Get("lottery_open_time"), time_info.hour, time_info.min, time_info.sec ))

    self.blood_value_text:setString(string.format(lang_constants:Get("lottery_get_blood_num"), self.config_data.num))

    if self.index == 1 then 
        self.tip_img:setVisible(true)
    else
        self.tip_img:setVisible(false)
    end
    
    self.icon_panel:Show(constants["REWARD_TYPE"]["mercenary"], self.config_data.template_id, nil, nil, false)
end

function rank_cell_panel:Show(data, index)
    self.index = index
    self.config_data = data
    self:SetData()
    self.root_node:setVisible(true)
end

local lottery_spring_panel = panel_prototype.New(true)

function lottery_spring_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/carnival_newyear_panel.csb")

    self.rank_cells = {}
    self.rank_list = {}

    self.rank_cell_nums = 0

    self.lottery_open_img = self.root_node:getChildByName("titlebg")
    self.lottery_open_img:setVisible(false)
    self.open_lottery_btn = self.lottery_open_img:getChildByName("confirm_btn")
    self.open_lottery_btn:setTouchEnabled(false)

    self.lottery_result_img = self.root_node:getChildByName("result_msgbox")
    self.lottery_result_img:setVisible(false)

    self.rank_cell_template = self.lottery_result_img:getChildByName("player_template")
    self.rank_cell_template:setAnchorPoint(cc.p(0, 0.5))
    self.rank_cell_template:setPosition(cc.p(23, 534))
    self.rank_cell_template:setVisible(false)

    self.list_view = self.lottery_result_img:getChildByName("scrollview")
    self.list_view:setTouchEnabled(true)

    self:CreateRankList()

    RANK_CELL_HEIGHT = RANK_CELL_HEIGHT + MARGIN_CELL_HEIGHT

    self.reuse_scrollview = reuse_scrollview.New(self, self.list_view, self.rank_cells, RANK_CELL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return #self.parent_panel.rank_list
        end,

        function(self, sub_panel, is_up)
            local index = is_up and self.data_offset + #self.parent_panel.rank_cells or self.data_offset + 1
            sub_panel:Show(self.parent_panel.rank_list[index], index)
        end
    )

    self.get_reward_node = self.lottery_result_img:getChildByName("get_node")
    self.get_reward_text = self.get_reward_node:getChildByName("blood_diamond_value")

    self.get_nothing_node = self.lottery_result_img:getChildByName("do_not_get_node")
    
    self.close_btn = self.lottery_result_img:getChildByName("close_btn")
    self.close_btn:setTouchEnabled(true)

    self.get_reward_node:setVisible(false)
    self.get_nothing_node:setVisible(false)

    self.current_value = 0
   
    self:RegisterEvent()
    self:RegiserWidgetEvent()
end

function lottery_spring_panel:CreateRankList()
    for i = 1, MAX_RANK_CELLS do
        local cell = rank_cell_panel.New()
        cell:Init(self.rank_cell_template:clone(), i)
        self.rank_cells[i] = cell
        self.list_view:addChild(cell.root_node)
    end 
end

function lottery_spring_panel:Show(value, rank_list, flag)
    self.current_value = value
    self.rank_list = rank_list
    self.lottery_result_img:setVisible(true)
    self:ShowResult(flag)
    self.root_node:setVisible(true)
end

function lottery_spring_panel:ShowResult(flag)
    self.get_reward_node:setVisible(false)
    self.get_nothing_node:setVisible(false)

    if self.current_value > 0 then 
       self.get_reward_text:setString(tostring(self.current_value))
       self.get_reward_node:setVisible(true)
    else
       self.get_nothing_node:setVisible(true)
    end

    self:ResortRankList(flag)

    self:LoadRankList()

    self.lottery_result_img:setVisible(true)
end

function lottery_spring_panel:ResortRankList(get_flag)
    if get_flag then 
       local t_info = {}
       local last_index = #self.rank_list
       t_info.user_name = user_logic.leader_name
       t_info.open_time = time_logic:Now()
       t_info.num = self.current_value
       t_info.template_id = troop_logic:GetLeaderTempateId()
        
       if last_index < MAX_RANK_NUM then 
          self.rank_list[last_index + 1] = t_info
       else
          if self.rank_list[MAX_RANK_NUM].num < self.current_value then 
             self.rank_list[MAX_RANK_NUM] = t_info
          end
       end
    end
    
    table.sort(self.rank_list, function(a, b)
        if a.num ~= b.num then 
           return a.num > b.num
        end

        return a.open_time < b.open_time
    end)
end

function lottery_spring_panel:LoadRankList()
    local scrollview_height = math.max(RANK_CELL_HEIGHT * #self.rank_list, self.reuse_scrollview.sview_height) 
    for i = 1, #self.rank_cells do 
         local cell = self.rank_cells[i]
         if self.rank_list[i] then 
             cell:Show(self.rank_list[i], i)
             cell.root_node:setPositionY(scrollview_height + FIRST_SUB_PANEL_OFFSET - (i - 1) * RANK_CELL_HEIGHT)
         else
            cell:Hide()
         end
    end

    self.reuse_scrollview:Show(scrollview_height, 0)
end

function lottery_spring_panel:Hide()
    self.root_node:setVisible(false)
end


function lottery_spring_panel:RegisterEvent()

end

function lottery_spring_panel:RegiserWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())
end

return lottery_spring_panel
