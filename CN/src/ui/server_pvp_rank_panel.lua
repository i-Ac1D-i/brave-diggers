local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local guild_logic = require "logic.guild"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local config_manager = require "logic.config_manager"
local icon_template = require "ui.icon_panel"

local reuse_scrollview = require "widget.reuse_scrollview"
local server_pvp_logic = require "logic.server_pvp"

local PLIST_TYPE = ccui.TextureResType.plistType

local SUB_PANEL_HEIGHT = 120
local FIRST_SUB_PANEL_OFFSET = -70
local MAX_SUB_PANEL_NUM = 7

local TAB_NOT_CLICKED_COLOR = 0x7F7F7F
local TAB_CLICKED_COLOR = 0xFFFFFF

local RANK_BONUS_MAP = constants["GUILDWAR_RANK_BONUS_MAP"]

local rank_cell_panel = panel_prototype.New()
rank_cell_panel.__index = rank_cell_panel

function rank_cell_panel.New()
    return setmetatable({}, rank_cell_panel)
end

function rank_cell_panel:Init(root_node)
    self.root_node = root_node

    self.rank_top_10_frame_img = self.root_node:getChildByName("rank_bg")
    self.rank_normal_frame_img = self.root_node:getChildByName("rank_bg2")
    self.rank_value = self.root_node:getChildByName("rank")

    self.leader_img = self.root_node:getChildByName("role")
    self.name_text = self.root_node:getChildByName("name")
    self.server_name_text = self.root_node:getChildByName("reward_num")
end

function rank_cell_panel:Show(rank_info)
    self.rank_info = rank_info
    
    self.rank_top_10_frame_img:setVisible(false)
    self.rank_normal_frame_img:setVisible(false)

    if rank_info.rank == 1 then
        self.rank_top_10_frame_img:setVisible(true)
        self.rank_top_10_frame_img:setColor(panel_util:GetColor4B(0xffd100))
    elseif rank_info.rank == 2 then
        self.rank_top_10_frame_img:setVisible(true)
        self.rank_top_10_frame_img:setColor(panel_util:GetColor4B(0xffffff))
    elseif rank_info.rank == 3 then
        self.rank_top_10_frame_img:setVisible(true)
        self.rank_top_10_frame_img:setColor(panel_util:GetColor4B(0xe5a163))
    else
        self.rank_normal_frame_img:setVisible(true)
    end

    self.rank_value:setString(self.rank_info.rank)
    
    local server_info = config_manager.server_config[self.rank_info.origin_server_id]
    if server_info then
        self.server_name_text:setString(server_info.name)
    else
        self.server_name_text:setString("")
    end

    local template_info = config_manager.mercenary_config[self.rank_info.template_id]
    self.leader_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. template_info.sprite .. ".png", PLIST_TYPE)
    self.name_text:setString(self.rank_info.leader_name)

    self.root_node:setVisible(true)
end

local reward_cell_panel = panel_prototype.New()
reward_cell_panel.__index = reward_cell_panel

function reward_cell_panel.New()
    return setmetatable({}, reward_cell_panel)
end

function reward_cell_panel:Init(root_node)
    self.root_node = root_node

    self.rank_node1 = self.root_node:getChildByName("1-3")
    self.rank_node2 = self.root_node:getChildByName("4-10")
    self.rank_node3 = self.root_node:getChildByName("11-20")

    self.rank_top_10_frame_img = self.root_node:getChildByName("rank_bg")
    self.rank_normal_frame_img = self.root_node:getChildByName("rank_bg2")
end

function reward_cell_panel:Show(index, reward_info, is_two_line)
    self.reward_info = reward_info

    self.rank_node1:setVisible(false)
    self.rank_node2:setVisible(false)
    self.rank_node3:setVisible(false)

    self.rank_top_10_frame_img:setVisible(false)
    self.rank_normal_frame_img:setVisible(false)

    if index == 1 then
        self.rank_top_10_frame_img:setVisible(true)
        self.rank_top_10_frame_img:setColor(panel_util:GetColor4B(0xffd100))
    elseif index == 2 then
        self.rank_top_10_frame_img:setVisible(true)
        self.rank_top_10_frame_img:setColor(panel_util:GetColor4B(0xffffff))
    elseif index == 3 then
        self.rank_top_10_frame_img:setVisible(true)
        self.rank_top_10_frame_img:setColor(panel_util:GetColor4B(0xe5a163))
    else
        self.rank_normal_frame_img:setVisible(true)
    end

    if #reward_info.req_value == 1 then
        self.rank_node1:getChildByName("rank"):setString(reward_info.req_value[1])
        self.rank_node1:setVisible(true)
    elseif #tostring(reward_info.req_value[1]) == 1 then
        self.rank_node2:getChildByName("rank"):setString(reward_info.req_value[1])
        self.rank_node2:getChildByName("rank_2"):setString(reward_info.req_value[2])
        self.rank_node2:setVisible(true)
    else
        self.rank_node3:getChildByName("rank"):setString(reward_info.req_value[1])
        self.rank_node3:getChildByName("rank_2"):setString(reward_info.req_value[2])
        self.rank_node3:setVisible(true)
    end

    for index,reward in ipairs(self.reward_info.rewards) do
        local icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["with_text2"])
        icon_panel:Init(self.root_node, false)
        icon_panel.root_node:setScale(0.7)
        if reward.expire_time and reward.expire_time > 0 then
            local level_img = icon_panel.root_node:getChildByName("level_img") 
            if level_img then
                level_img:setVisible(true)
            end
            local level_text = icon_panel.root_node:getChildByName("level_text") 
            if level_text then
                level_text:setVisible(true)
                level_text:setRotation(-40)
            end
        else
            local level_img = icon_panel.root_node:getChildByName("level_img") 
            if level_img then
                level_img:setVisible(false)
            end
            local level_text = icon_panel.root_node:getChildByName("level_text") 
            if level_text then
                level_text:setVisible(false)
            end
        end

        icon_panel:Show(reward.reward_type, reward.param1, reward.param2, false, true)
        if index <= 4 then
            icon_panel:SetPosition(100 + (index - 1) * 90, is_two_line and 140 or 45)
        elseif index <= 8 then
            icon_panel:SetPosition(100 + (index - 5) * 90, 55)
        end
    end
    
    self.root_node:setVisible(true)
end

local server_pvp_rank_panel = panel_prototype.New(true)
server_pvp_rank_panel.__index = server_pvp_rank_panel
function server_pvp_rank_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/server_pvp_reward_msgbox.csb")

    cc.SpriteFrameCache:getInstance():addSpriteFrames("res/ui/tower.plist")
    local tex = cc.Director:getInstance():getTextureCache():getTextureForKey("res/ui/tower.png")
    if tex then
        tex:setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
    end

    self.desc_text = self.root_node:getChildByName("desc_tip")
    
    local scrollview_node = self.root_node:getChildByName("metallurgy_node")

    self.reward_bg = scrollview_node:getChildByName("Image_231")
    self.rank_scroll_view = scrollview_node:getChildByName("ScrollView_top100")
    self.reward_scroll_view = scrollview_node:getChildByName("ScrollView_reward")

    self.rank_template = self.rank_scroll_view:getChildByName("template")

    self.reward_template_two = self.reward_scroll_view:getChildByName("template1")
    self.reward_template_one = self.reward_scroll_view:getChildByName("template2")

    self.top_reward_node = scrollview_node:getChildByName("cost_bg")
    self.daily_reward_node = scrollview_node:getChildByName("cost_bg2")

    self.rank_template:setVisible(false)
    self.reward_template_one:setVisible(false)
    self.reward_template_two:setVisible(false)

    self.reward_btn = self.root_node:getChildByName("weekly_tab")
    self.rank_btn = self.root_node:getChildByName("metallurgy_tab")
    self.reward_btn:setTouchEnabled(true)
    self.rank_btn:setTouchEnabled(true)

    self.close_btn = self.root_node:getChildByName("close_btn")
    self.up_btn = self.root_node:getChildByName("up_btn")
    self.up_btn2 = self.root_node:getChildByName("up_btn2")
    self.up_btn:setTouchEnabled(true)
    self.up_btn2:setTouchEnabled(true)

    self.world_rank_list = {}
    self.rank_num = 0

    self.sub_panel_num = 0
    self.rank_sub_panels = {}

    self.reuse_scrollview = reuse_scrollview.New(self, self.rank_scroll_view, self.rank_sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return self.parent_panel.rank_num
        end,

        function(self, sub_panel, is_up)
            local index = is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
            sub_panel:Show(self.parent_panel.world_rank_list[index])
        end
    )

    self:CreateRewardScrollView()
    self:CreateReward(self.top_reward_node, server_pvp_logic.top_reward_list)
    self:CreateReward(self.daily_reward_node, server_pvp_logic.daily_reward_list)

    self:RegisterWidgetEvent()

end

function server_pvp_rank_panel:CreateRankScrollView()
    local num = math.min(MAX_SUB_PANEL_NUM, self.rank_num)
    
    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = rank_cell_panel.New()
        sub_panel:Init(self.rank_template:clone())

        self.rank_sub_panels[i] = sub_panel
        self.rank_scroll_view:addChild(sub_panel.root_node)
    end

    self.sub_panel_num = num
end

function server_pvp_rank_panel:LoadRankList()

    local height = math.max(self.rank_num * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

    for i = 1, self.sub_panel_num do
        local sub_panel = self.rank_sub_panels[i]

        sub_panel:Show(self.world_rank_list[i])
        sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - (i - 1) * SUB_PANEL_HEIGHT)
    end

    self.reuse_scrollview:Show(height, 0)

    self.root_node:setVisible(true)
end

function server_pvp_rank_panel:CreateRewardScrollView()
    local size = self.rank_scroll_view:getContentSize()

    local pos_y = 0
    for index = #server_pvp_logic.reward_list, 1, -1 do
        local reward_info = server_pvp_logic.reward_list[index]
        local reward_cell = reward_cell_panel.New()
        if #reward_info.rewards > 4 then
            reward_cell:Init(self.reward_template_two:clone())
            reward_cell:Show(index, reward_info, true)
            reward_cell.root_node:setPosition(cc.p(295, pos_y + 200))
            pos_y = pos_y + 200
        else
            reward_cell:Init(self.reward_template_one:clone())
            reward_cell:Show(index, reward_info, false)
            reward_cell.root_node:setPosition(cc.p(295, pos_y + 110))
            pos_y = pos_y + 110
        end
        self.reward_scroll_view:addChild(reward_cell.root_node)
    end

    self.reward_scroll_view:setInnerContainerSize(cc.size(size.width, pos_y + 20))

    self.reward_scroll_view:jumpToTop()
end

function server_pvp_rank_panel:CreateReward(root_node, reward_list)
    local reward_num = #reward_list
    local beg_pos_x = root_node:getContentSize().width / 2 - (reward_num - 1) * 45

    for index,reward in ipairs(reward_list) do
        local icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["with_text2"])
        icon_panel:Init(root_node, false)
        icon_panel.root_node:setScale(0.7)
        if reward.expire_time and reward.expire_time > 0 then
            local level_img = icon_panel.root_node:getChildByName("level_img") 
            if level_img then
                level_img:setVisible(true)
            end
            local level_text = icon_panel.root_node:getChildByName("level_text") 
            if level_text then
                level_text:setVisible(true)
                level_text:setRotation(-40)
            end
        else
            local level_img = icon_panel.root_node:getChildByName("level_img") 
            if level_img then
                level_img:setVisible(false)
            end
            local level_text = icon_panel.root_node:getChildByName("level_text") 
            if level_text then
                level_text:setVisible(false)
            end
        end

        icon_panel:Show(reward.reward_type, reward.param1, reward.param2, false, true)
        icon_panel:SetPosition(beg_pos_x + (index - 1) * 90, 40)
    end
end

function server_pvp_rank_panel:SwitchTabShow(tab)
    if tab == 1 then
        self.reward_btn:setColor(panel_util:GetColor4B(TAB_CLICKED_COLOR))
        self.rank_btn:setColor(panel_util:GetColor4B(TAB_NOT_CLICKED_COLOR))

        self.reward_scroll_view:setVisible(true)
        self.top_reward_node:setVisible(true)
        self.daily_reward_node:setVisible(true)
        self.up_btn2:setVisible(true)
        self.reward_bg:setVisible(true)
    
        self.rank_scroll_view:setVisible(false)
        self.up_btn:setVisible(false)
    else
        self.reward_btn:setColor(panel_util:GetColor4B(TAB_NOT_CLICKED_COLOR))
        self.rank_btn:setColor(panel_util:GetColor4B(TAB_CLICKED_COLOR))

        self.reward_scroll_view:setVisible(false)
        self.top_reward_node:setVisible(false)
        self.daily_reward_node:setVisible(false)
        self.up_btn2:setVisible(false)
        self.reward_bg:setVisible(false)

        self.rank_scroll_view:setVisible(true)
        self.up_btn:setVisible(true)
    end
end

function server_pvp_rank_panel:Show()
    self.world_rank_list = server_pvp_logic.world_rank_list
    self.rank_num = #self.world_rank_list

    self:CreateRankScrollView()
    self:LoadRankList()
    
    self:SwitchTabShow(1)

    self.root_node:setVisible(true)
end

function server_pvp_rank_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())

    self.reward_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            self:SwitchTabShow(1)
        end
    end)

    self.rank_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            self:SwitchTabShow(2)
        end
    end)

    self.up_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            self.rank_scroll_view:scrollToTop(0.5, true)
        end
    end)

    self.up_btn2:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            self.reward_scroll_view:scrollToTop(0.5, true)
        end
    end)
end

return server_pvp_rank_panel

