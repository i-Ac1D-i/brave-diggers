local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local reuse_scrollview = require "widget.reuse_scrollview"
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local ladder_tower_logic = require "logic.ladder_tower"
local icon_panel = require "ui.icon_panel"
local lang_constants = require "util.language_constants"

local PLIST_TYPE = ccui.TextureResType.plistType

local SHOW_TYPE = {
    rank_tab = 1,
    reward_tab = 2,
}

-------------------------------------------------------排行面板-------------------------------
local RANK_SUB_PANEL_HEIGHT = 120
local FIRST_SUB_PANEL_OFFSET = -80
local RANK_MAX_SUB_PANEL_NUM = 5
local RANK_TEMPLENT_OFFSET_X = 28

local rank_tab_sub_panel = panel_prototype.New()
rank_tab_sub_panel.__index = rank_tab_sub_panel

function rank_tab_sub_panel.New()
    local t = {}
    return setmetatable(t, rank_tab_sub_panel)
end

function rank_tab_sub_panel:Init(root_node)
    self.root_node = root_node
    self.rank_text = self.root_node:getChildByName("rank") 
    self.name_text = self.root_node:getChildByName("name")
    self.bp_text = self.root_node:getChildByName("kill_number")
    self.score_text = self.root_node:getChildByName("point_member")
    self.rank_bg1 = self.root_node:getChildByName("na1")
    self.rank_bg2 = self.root_node:getChildByName("na2")
    self.rank_bg3 = self.root_node:getChildByName("na3")
    self.rank_bg4 = self.root_node:getChildByName("na4")
    --头像
    self.head_icon_img = self.root_node:getChildByName("role")
    --等级图标
    self.level_img = self.root_node:getChildByName("rank_bg")
end

function rank_tab_sub_panel:Show(info)
    
    if info then
        self.rank_text:setString(info.rank)
        self:ShowRankBg(info.rank)
        self.name_text:setString(info.leader_name)
        self.bp_text:setString(info.max_bp)
        self.score_text:setString(info.ladder_core)
        if info and info.leader_template_id then
            self.conf = config_manager.mercenary_config[info.leader_template_id]
            self.conf.icon = client_constants["MERCENARY_ROLE_IMG_PATH"] .. self.conf.sprite .. ".png"
            self.head_icon_img:loadTexture(self.conf.icon, PLIST_TYPE)
        end

        self.level_img:loadTexture(client_constants["LADDER_LEVEL_S_IMG_TYPE"][info.group], PLIST_TYPE)
    end

    self.root_node:setVisible(true)
end

function rank_tab_sub_panel:ShowRankBg(rank_index)
    self.rank_bg1:setVisible(false)
    self.rank_bg2:setVisible(false)
    self.rank_bg3:setVisible(false)
    self.rank_bg4:setVisible(false)
    if rank_index == 1 then
        self.rank_bg1:setVisible(true)
    elseif rank_index == 2 then
        self.rank_bg2:setVisible(true)
    elseif rank_index == 3 then 
        self.rank_bg3:setVisible(true)
    else
        self.rank_bg4:setVisible(true)
    end
end

--排行榜tab
local rank_tab_panel = panel_prototype.New()
rank_tab_panel.__index = rank_tab_panel

function rank_tab_panel:Init(root_node)
    self.root_node = root_node

    self.scroll_view = self.root_node:getChildByName("scrollview0")
    self.template = self.scroll_view:getChildByName("template_personal")
    self.template:setVisible(false)

    self.my_rank_node = self.root_node:getChildByName("template_personal_0")
    self.my_rank_sub_panel = rank_tab_sub_panel.New()
    self.my_rank_sub_panel:Init(self.my_rank_node)

    --跳到顶部
    self.up_btn = self.root_node:getChildByName("up_btn")
    self.up_btn:setTouchEnabled(true)

    self.sub_panel_num = 0
    self.rank_list_num = 0
    self.rank_tab_sub_panels = {}

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.rank_tab_sub_panels, RANK_SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return self.parent_panel.rank_list_num
        end,

        function(self, sub_panel, is_up)
            local index = is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
            local rank_list = ladder_tower_logic:GetRankList()
            sub_panel:Show(rank_list[index])
        end
    )
    self:RegisterWidgetEvent()
end

function rank_tab_panel:CreateSubPanels()
    local num = math.min(RANK_MAX_SUB_PANEL_NUM, self.rank_list_num)
    
    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = rank_tab_sub_panel.New()
        sub_panel:Init(self.template:clone())
        sub_panel.root_node:setPositionX(self.scroll_view:getContentSize().width/2 + RANK_TEMPLENT_OFFSET_X)
        self.rank_tab_sub_panels[i] = sub_panel
        
        self.scroll_view:addChild(sub_panel.root_node)
    end

    self.sub_panel_num = num
end

function rank_tab_panel:Show(is_load)
    if is_load then
        self:LoadScrollview()
    end
    self.my_rank_sub_panel:Show(ladder_tower_logic:GetSelfRankInfo())
    self.root_node:setVisible(true)
end

function rank_tab_panel:LoadScrollview()
    local rank_list = ladder_tower_logic:GetRankList()
    self.rank_list_num = #rank_list
    self:CreateSubPanels()

    local height = math.max(self.rank_list_num * RANK_SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

    
    for i = 1, self.sub_panel_num do
        local sub_panel = self.rank_tab_sub_panels[i]

        sub_panel:Show(rank_list[i])
        sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - (i - 1) * RANK_SUB_PANEL_HEIGHT)
    end

    self.reuse_scrollview:Show(height, 0)
end

function rank_tab_panel:RegisterWidgetEvent()
    --关闭按钮
    self.up_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.scroll_view:scrollToTop(0.5, false)
        end
    end)
end
-------------------------------------------------------排行面板end-------------------------------

-------------------------------------------------------奖励面板----------------------------------------------------------------------

local REWARD_SUB_PANEL_HEIGHT = 120
local FIRST_REWARD_SUB_PANEL_OFFSET = -60
local REWARD_MAX_SUB_PANEL_NUM = 10
local REWARD_CONTENTSIZE_WIDTH = 86

local reward_tab_sub_panel = panel_prototype.New()
reward_tab_sub_panel.__index = reward_tab_sub_panel

function reward_tab_sub_panel.New()
    local t = {}
    return setmetatable(t, reward_tab_sub_panel)
end

function reward_tab_sub_panel:Init(root_node)
    self.root_node = root_node
    self.name_text = self.root_node:getChildByName("name")
    self.name_text1 = self.root_node:getChildByName("name_0")

    self.bg_img = self.root_node:getChildByName("template_123")
    self.bg_img2 = self.root_node:getChildByName("template_123_0")

    self.level_img = self.root_node:getChildByName("rank_bg")

    panel_util:SetTextOutline(self.name_text)
    self.reward_sub_panels = {}
end

function reward_tab_sub_panel:Show(info, index)
    if info then
        --设置名字背景颜色
        self.bg_img:setVisible(false)
        self.bg_img2:setVisible(true)

        --设置当前奖励名字
        local level_str = ""
        if info.min_rank == info.max_rank then
            if info.min_rank > 0 then
                level_str = string.format(lang_constants:Get("rank_level_desc"),info.min_rank)
            else
                level_str = lang_constants:Get("ladder_all_level_desc")
            end 
        else
            if info.min_rank == 0  or info.max_rank == 0 then
                level_str = string.format(lang_constants:Get("rank_level_desc"),info.max_rank).."~"..lang_constants:Get("ladder_last_level_desc")
            else
                level_str = string.format(lang_constants:Get("rank_level_desc"),info.max_rank).."~"..string.format(lang_constants:Get("rank_level_desc"),info.min_rank)
            end
            
        end

        self.name_text:setColor(panel_util:GetColor4B(client_constants["LADDER_LEVEL_REWARD_BG_COLOR"][info.group_type]))
        

        self.name_text:setString(lang_constants:Get("ladder_level_"..info.group_type))
        self.name_text1:setString(level_str)
        --删除旧的icon
        --获得的奖励iconf
        for k,reward_sub_panel in ipairs(self.reward_sub_panels) do
            reward_sub_panel.root_node:removeFromParent()
        end
        self.reward_sub_panels = {}

        local reward_config = {}
        local reward_num = 0
        for k,v in pairs(info.reward_info) do
            reward_num = reward_num + 1
            reward_config[constants["RESOURCE_TYPE_NAME"][v.param1]] = v.param2
        end
        for i = 1, reward_num do
            if self.reward_sub_panels[i] == nil then
                local sub_panel = icon_panel.New()
                sub_panel:Init(self.root_node)
                self.reward_sub_panels[i] = sub_panel
            end
        end

        local posx = self.bg_img:getContentSize().width / 2 - (reward_num - 0.5) / 2  * REWARD_CONTENTSIZE_WIDTH

        panel_util:LoadCostResourceInfo(reward_config, self.reward_sub_panels, self.bg_img:getContentSize().height / 4, reward_num, posx, false) 
        --等级图标
        self.level_img:loadTexture(client_constants["LADDER_LEVEL_L_IMG_TYPE"][info.group_type], PLIST_TYPE)

    end

    self.root_node:setVisible(true)
end

--奖励tab
local reward_tab_panel = panel_prototype.New()
reward_tab_panel.__index = reward_tab_panel

function reward_tab_panel:Init(root_node)
    self.root_node = root_node

    self.scroll_view = self.root_node:getChildByName("scrollview0")
    self.template = self.scroll_view:getChildByName("lv123")
    self.template:setVisible(false)

    --跳到顶部
    self.up_btn = self.root_node:getChildByName("up_btn")
    self.up_btn:setTouchEnabled(true)

    self.sub_panel_num = 0
    self.reward_list_num = 0
    self.reward_tab_sub_panels = {}

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.reward_tab_sub_panels, REWARD_SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return self.parent_panel.reward_list_num
        end,

        function(self, sub_panel, is_up)
            local index = is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
            local reward_list = ladder_tower_logic.reward_list
            sub_panel:Show(reward_list[index], index)
        end
    )
    self.is_load = false
    self:RegisterWidgetEvent()
end

function reward_tab_panel:CreateSubPanels()
    local num = math.min(REWARD_MAX_SUB_PANEL_NUM, self.reward_list_num)
    
    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = reward_tab_sub_panel.New()
        sub_panel:Init(self.template:clone())
        sub_panel.root_node:setPositionX(self.scroll_view:getContentSize().width/2)
        self.reward_tab_sub_panels[i] = sub_panel
        
        self.scroll_view:addChild(sub_panel.root_node)
    end

    self.sub_panel_num = num
end

function reward_tab_panel:Show(is_load)
    if not self.is_load then
        self.is_load = true
        self:LoadScrollview()
    end
    
    self.root_node:setVisible(true)
end

function reward_tab_panel:LoadScrollview()
    local reward_list = ladder_tower_logic.reward_list
    self.reward_list_num = #reward_list
    self:CreateSubPanels()

    local height = math.max(self.reward_list_num * REWARD_SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

    
    for i = 1, self.sub_panel_num do
        local sub_panel = self.reward_tab_sub_panels[i]

        sub_panel:Show(reward_list[i], i)
        sub_panel.root_node:setPositionY(height + FIRST_REWARD_SUB_PANEL_OFFSET - (i - 1) * REWARD_SUB_PANEL_HEIGHT)
    end

    self.reuse_scrollview:Show(height, 0)
end

function reward_tab_panel:RegisterWidgetEvent()
    --关闭按钮
    self.up_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.scroll_view:scrollToTop(0.5, false)
        end
    end)
end

-------------------------------------------------------奖励面板 end--------------------------------------------------------

local ladder_tournament_ranklist_panel = panel_prototype.New(true)
function ladder_tournament_ranklist_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/ladder_tournament_ranklisk_msgbox.csb")
    self.back_btn = self.root_node:getChildByName("back_btn")

    self.rank_btn = self.root_node:getChildByName("weekly_tab")
    self.reward_btn = self.root_node:getChildByName("metallurgy_tab")

    self.rank_bg = self.root_node:getChildByName("Image_222")
    self.reward_bg = self.root_node:getChildByName("Image_221")

    self.rank_node = self.root_node:getChildByName("list")
    rank_tab_panel:Init(self.rank_node)
    self.reward_node = self.root_node:getChildByName("list_0")
    reward_tab_panel:Init(self.reward_node)

    self.show_type = SHOW_TYPE.rank_tab

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function ladder_tournament_ranklist_panel:Show()
    self:ShowTab(self.show_type, true)
    self.root_node:setVisible(true)
end

function ladder_tournament_ranklist_panel:ShowTab(show_type, is_load)
    self.show_type = show_type or self.show_type
    if self.show_type == SHOW_TYPE.rank_tab then
        self.rank_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
        self.reward_btn:setColor(panel_util:GetColor4B(0x7F7F7F))

        self.rank_bg:setVisible(true)
        self.reward_bg:setVisible(false)

        self.rank_btn:setLocalZOrder(2)
        self.reward_btn:setLocalZOrder(1)

        rank_tab_panel:Show(is_load)
        reward_tab_panel:Hide()
    else
        self.rank_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
        self.reward_btn:setColor(panel_util:GetColor4B(0xFFFFFF))

        self.rank_bg:setVisible(false)
        self.reward_bg:setVisible(true)

        self.rank_btn:setLocalZOrder(1)
        self.reward_btn:setLocalZOrder(2)

        rank_tab_panel:Hide()
        reward_tab_panel:Show(is_load)
    end
end

function ladder_tournament_ranklist_panel:RegisterEvent()
    graphic:RegisterEvent("rank_refresh_success", function()
        if not self.root_node:isVisible() then
            return
        end
        if self.show_type == SHOW_TYPE.rank_tab then
            rank_tab_panel:Show(true)
        end
    end)
end

function ladder_tournament_ranklist_panel:RegisterWidgetEvent()
	--关闭按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)


    self.rank_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if self.show_type ~= SHOW_TYPE.rank_tab then
                audio_manager:PlayEffect("click")
                self:ShowTab(SHOW_TYPE.rank_tab)
            end
        end
    end)

    self.reward_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if self.show_type ~= SHOW_TYPE.reward_tab then
                audio_manager:PlayEffect("click")
                self:ShowTab(SHOW_TYPE.reward_tab)
            end
        end
    end)
end

return ladder_tournament_ranklist_panel

