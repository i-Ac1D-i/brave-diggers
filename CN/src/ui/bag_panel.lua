local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local single_reward_panel = require "ui.single_reward_panel"

local resource_logic = require "logic.resource"
local bag_logic = require "logic.bag"
local reward_logic = require "logic.reward"

local resource_config = config_manager.resource_config

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local RESOURCE_SHOW_BAG_TYPE_NAME = client_constants["RESOURCE_SHOW_BAG_TYPE_NAME"]

local platform_manager = require "logic.platform_manager"

local spine_manager = require "util.spine_manager"
local spine_node_tracker = require "util.spine_node_tracker"

local REWARD_TYPE = constants.REWARD_TYPE
local RESOURCE_TYPE = constants.RESOURCE_TYPE
local ITEM_RULE = constants.ITEM_RULE

local TEXT_QUALITY_COLOR = client_constants["TEXT_QUALITY_COLOR"]
local BG_QUALITY_COLOR = client_constants["BG_QUALITY_COLOR"]
local BIG_QUALITY_BG_IMG_PATH = client_constants["MERCENARY_BG_SPRITE"]

local audio_manager = require "util.audio_manager"
local reuse_scrollview = require "widget.reuse_scrollview"

local MAX_ROW, MAX_COL = 6, 6
local SUB_PANEL_HEIGHT = 88
local FIRST_SUB_PANEL_OFFSET = -55

local BAG_EMPTY_BG = "bg/bag_emtpybg.png"
local BAG_BG = "bg/activity_herobg.png"

local EXP_ICON = "icon/resource/exp_header.png"
local BP_ICON = "icon/resource/bp_header.png"
local PICKAGE_ICON = "icon/global/ore_picks.png"

local TAB_TYPE =
{
    ["item"] = 1,
    ["resource"] = 2,
}

local PLIST_TYPE = ccui.TextureResType.plistType

local ITEM_STATUS =
{
    ["have_item"] = 1,
    ["unlock_but_no_item"] = 2,
    ["show_lock_text"] = 3,
    ["lock"] = 4,
}

local detail_info_sub_panel = panel_prototype.New()
function detail_info_sub_panel:Init(root_node)
    self.root_node = root_node

    self.have_item_node = root_node:getChildByName("have_item_node")
    self.no_item_desc_text = root_node:getChildByName("no_item_desc")

    self.bg_img = self.have_item_node:getChildByName("item_bg")
    self.icon_img = self.have_item_node:getChildByName("item_icon")
    self.name_text = self.have_item_node:getChildByName("item_name")
    self.icon_img:ignoreContentAdaptWithSize(true)

    self.use_btn = self.have_item_node:getChildByName("use_btn")

    self.desc_scroll_view = self.have_item_node:getChildByName("desc_list")
    self.desc_text = self.desc_scroll_view:getChildByName("desc")

    self.use_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if self.cur_tab_type ~= TAB_TYPE["item"] then
                return
            end

            local item = bag_logic:GetItemInfo(self.item_id)

            if not item then
                graphic:DispatchEvent("show_prompt_panel", "bag_item_not_exist")
                return
            end

            if item.template_info.rule_type == ITEM_RULE["refresh_mining"] then
                graphic:DispatchEvent("show_world_sub_panel", "mining_reset_panel", self.item_id)

            elseif item.template_info.rule_type == ITEM_RULE["refresh_temple"] then
                local mode = client_constants.CONFIRM_MSGBOX_MODE["use_item"]
                graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode, self.item_id)

            else
                bag_logic:UseItem(self.item_id)
            end
        end
    end)

    --r2修改
    local offset_x=platform_manager:GetChannelInfo().detail_info_sub_panel_use_btn_offset_x
    if offset_x then
        self.use_btn:setPositionX(self.use_btn:getPositionX()+offset_x)
    end
    self.root_node:setVisible(true)
end

function detail_info_sub_panel:SetCurTabType(tab_type)
    self.cur_tab_type = tab_type
    self.use_btn:setVisible(self.cur_tab_type == TAB_TYPE['item'])

    if self.cur_tab_type == TAB_TYPE['item'] then
        self.desc_scroll_view:setContentSize(287, 72)
        self.desc_text:setContentSize(285, 300)
    else
        self.desc_scroll_view:setContentSize(377, 72)
        self.desc_text:setContentSize(375, 300)
    end
end

function detail_info_sub_panel:Show(id)
    if not id or id == 0 then
        self.have_item_node:setVisible(false)
        self.no_item_desc_text:setVisible(true)
        return
    end

    self.have_item_node:setVisible(true)
    self.no_item_desc_text:setVisible(false)

    if  self.cur_tab_type == TAB_TYPE["item"] then
        self:ShowItem(id)
    elseif  self.cur_tab_type == TAB_TYPE['resource'] then
        self:ShowResource(id)
    end
end

--显示道具
function detail_info_sub_panel:ShowItem(item_id)

    local item = bag_logic:GetItemInfo(item_id)
    if not item then return end

    self.item_id = item_id

    local quality = item.template_info.quality
    self.name_text:setString(item.template_info.name)
    self.bg_img:loadTexture(client_constants.MERCENARY_BG_SPRITE[quality], PLIST_TYPE)
    if quality == client_constants["DEFAULT_QUALITY"] then
        self.bg_img:setOpacity(255 * 0.6)
    else
        self.bg_img:setOpacity(255)
    end

    self.icon_img:loadTexture(item.template_info.icon, PLIST_TYPE)
    self.desc_text:setString(item.template_info.desc)
end

--显示资源
function detail_info_sub_panel:ShowResource(index)
    local resource_name = constants["RESOURCE_TYPE_NAME"][index]
    if resource_name then
        local template_id = constants['RESOURCE_TYPE'][resource_name]
        local resource_template = resource_config[template_id]
        self.icon_img:loadTexture(resource_template.icon, PLIST_TYPE)
        self.item_id = template_id
        self.name_text:setString(resource_template.name .. "x" .. resource_logic:GetResourcenNumByName(resource_name))
        self.desc_text:setString(resource_template.desc)

        local quality = resource_template["quality"]
        self.bg_img:loadTexture(client_constants.MERCENARY_BG_SPRITE[quality], PLIST_TYPE)
        if quality == client_constants["DEFAULT_QUALITY"] then
            self.bg_img:setOpacity(255 * 0.6)
        else
            self.bg_img:setOpacity(255)
        end

    end
end

local item_sub_panel = panel_prototype.New()
item_sub_panel.__index = item_sub_panel

function item_sub_panel.New()
    return setmetatable({}, item_sub_panel)
end

function item_sub_panel:Init(root_node)
    self.root_node = root_node
    self.icon_img = root_node:getChildByName("item_icon")
    self.lock_icon = root_node:getChildByName("lock_icon")
    self.text_bg_img = root_node:getChildByName("text_bg")
    self.num_text = self.text_bg_img:getChildByName("num")
    self.text_bg_img:setVisible(false)

    self.root_node:setCascadeColorEnabled(false)
    self.root_node:setCascadeOpacityEnabled(true)
end

function item_sub_panel:Load(item_info, status, tab_type)
    self.root_node:setVisible(true)
    self.root_node:setOpacity(255)
    self.lock_icon:setVisible(false)
    self.next_unlock = false

    if tab_type == TAB_TYPE["item"] then
        self:LoadItem(item_info, status)
        self.text_bg_img:setVisible(false)

    elseif tab_type == TAB_TYPE['resource'] then
        self:LoadResource(item_info, status)
    end
end

--load 道具
function item_sub_panel:LoadItem(item_info, status)
    if item_info and item_info.template_info then
        self.icon_img:setVisible(true)
        self.icon_img:loadTexture(item_info.template_info.icon, PLIST_TYPE)
        local quality = item_info.template_info.quality or 1

        if quality == client_constants["DEFAULT_QUALITY"] then
            self.root_node:loadTexture(BAG_EMPTY_BG, PLIST_TYPE)
        else
            self.root_node:loadTexture(BAG_BG, PLIST_TYPE)
            self.root_node:setColor(panel_util:GetColor4B(BG_QUALITY_COLOR[quality]))
        end

        self.item_id = item_info.item_id
    else
        self.icon_img:setVisible(false)
        self.root_node:loadTexture(BAG_EMPTY_BG, PLIST_TYPE)
        self.root_node:setColor(panel_util:GetColor4B(client_constants["LIGHT_BLEND_COLOR"]))
        self.item_id = 0
    end

    if status == ITEM_STATUS["show_lock_text"] then
        self.lock_icon:setVisible(true)
        self.next_unlock = true

    elseif status == ITEM_STATUS["lock"] then
        self.root_node:setOpacity(255 * 0.4)
    end
end

--load资源
function item_sub_panel:LoadResource(resource_name, status)
    if resource_name and resource_logic:GetResourcenNumByName(resource_name) > 0 then
        local template_id = constants['RESOURCE_TYPE'][resource_name]
        local resource_template = resource_config[template_id]
        self.icon_img:loadTexture(resource_template.icon, PLIST_TYPE)
        self.icon_img:setVisible(true)
        self.item_id = template_id
        self.num_text:setString(resource_logic:GetResourcenNumByName(resource_name))

        local quality = resource_template["quality"]
        if quality == client_constants["DEFAULT_QUALITY"] then
            self.root_node:loadTexture(BAG_EMPTY_BG, PLIST_TYPE)
        else
            self.root_node:loadTexture(BAG_BG, PLIST_TYPE)
            self.root_node:setColor(panel_util:GetColor4B(BG_QUALITY_COLOR[quality]))
        end
        self.text_bg_img:setVisible(true)

    else
        self.icon_img:setVisible(false)
        self.root_node:loadTexture(BAG_EMPTY_BG, PLIST_TYPE)
        self.root_node:setColor(panel_util:GetColor4B(client_constants["LIGHT_BLEND_COLOR"]))
        self.text_bg_img:setVisible(false)
        self.item_id = 0
    end
end

local bag_panel = panel_prototype.New(true)
function bag_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/bag_panel.csb")
    local root_node = self.root_node
    detail_info_sub_panel:Init(root_node:getChildByName("item_explain"))

    self.item_tab_btn = root_node:getChildByName("item_tab")
    self.item_tab_btn:setTag(1)
    self.resource_tab_btn = root_node:getChildByName("res_tab")
    self.resource_tab_btn:setTag(2)

    self.template = root_node:getChildByName("bag_template")
    self.template:setVisible(false)

    self.scroll_view = root_node:getChildByName("scroll_view")

    self.reward_node = root_node:getChildByName("reward")
    self.reward_panel = single_reward_panel.New()
    self.reward_panel:Init(self.reward_node)
    
    self.root_node:getChildByName("close_btn"):setLocalZOrder(102)
    self.select_spine = spine_manager:GetNode("item_skill_choose")
    self.scroll_view:addChild(self.select_spine, 100)
    self.select_spine:setVisible(false)
    self.select_spine:setAnimation(0, "animation", true)

    self.scroll_view:setVisible(true)

    self.duration = 0
    self.cur_capacity_row = 0
    self.item_sub_panels = {}

    self.item_offset, self.sub_panel_row = 0, 0

    self.cur_reward_index, self.reward_num, self.reward_info_list  = 1, 0, {}
    self.cur_sub_panel_index = 1

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.item_sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return self.parent_panel.cur_capacity_row
        end,

        function(self, sub_panel, is_up)
            local offset = is_up and self.parent_panel.sub_panel_row or 1
            local pos_y = sub_panel.root_node:getPositionY()
            self.parent_panel:ShowSingleRowItem(self.data_offset + offset, sub_panel, pos_y)
        end
    )
    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function bag_panel:CreateSubPanels(row)
    local cur_row = math.min(MAX_ROW, row)
    if self.sub_panel_row >= cur_row then
        return
    end

    local begin_x, interval = 53, 88
    --绑定事件
    for row = self.sub_panel_row + 1, cur_row do
        self.item_sub_panels[row] = {}

        for col = 1, MAX_COL do
            local x = begin_x + (col - 1) * interval
            local tag = (row - 1) * MAX_COL + col

            local sub_panel = item_sub_panel.New()
            sub_panel:Init(self.template:clone())
            sub_panel.root_node:setTag(tag)
            sub_panel.root_node:setPositionX(x)

            sub_panel.root_node:setTouchEnabled(true)
            sub_panel.root_node:addTouchEventListener(self.view_bag_content)
            self.scroll_view:addChild(sub_panel.root_node)

            self.item_sub_panels[row][col] = sub_panel
            sub_panel.root_node:setVisible(true)
        end

        self.item_sub_panels[row].root_node = self.item_sub_panels[row][1].root_node
    end

    self.sub_panel_row = cur_row
end

function bag_panel:Show()
    self:UpdateTabStatus(TAB_TYPE['item'])

    self.root_node:setVisible(true)
end

function bag_panel:LoadItems()
    -- body
    self.item_list = bag_logic:GetItemList()
    self.real_capacity, self.bag_level = bag_logic:GetCapacity()

    self.item_num = #self.item_list
    local capacity_row = 0
    if self.real_capacity == constants["MAX_BAG_CAPACITY"] then
        capacity_row = math.ceil(self.real_capacity / MAX_COL)
    else
        capacity_row = math.ceil((self.real_capacity + 1) / MAX_COL)
    end

    self.cur_capacity_row = capacity_row
    self:UpdateItemSubPanels()
end

function bag_panel:LoadResource()

    local item_list = {}
    for k, v in pairs(RESOURCE_SHOW_BAG_TYPE_NAME) do
        if resource_logic:GetResourcenNumByName(v) > 0 then
            table.insert(item_list, v)
        end
    end

    self.item_list = item_list

    self.cur_capacity_row = math.ceil(client_constants["RESOURCE_SHOW_BAG_MAX_NUM"] / MAX_COL)
    self.real_capacity = client_constants["RESOURCE_SHOW_BAG_MAX_NUM"] - 1
    self.item_num =  #self.item_list

    self:UpdateItemSubPanels()
end

function bag_panel:UpdateItemSubPanels()

    self:CreateSubPanels(self.cur_capacity_row)

    self.height = math.max(self.cur_capacity_row * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)
    self.cur_sub_panel_index = 1

    local begin_x, interval = 53, 88
    local begin_y = self.height + FIRST_SUB_PANEL_OFFSET

    for row = 1, self.sub_panel_row do
        local y = begin_y - (row - 1) * interval
        self:ShowSingleRowItem(row, self.item_sub_panels[row], y)
    end

    if self.item_num > 0 then
        if self.cur_sub_panel_index > self.item_num then
            self.cur_sub_panel_index = self.item_num
        end

        local row = math.ceil(self.cur_sub_panel_index / MAX_COL)
        local col = self.cur_sub_panel_index - (row - 1) * MAX_COL
        local sub_panel = self.item_sub_panels[row][col]
        detail_info_sub_panel:Show(sub_panel.item_id)

        self:SetSelectBoxPosition()

    else
        detail_info_sub_panel:Show(nil)
        self.select_spine:setVisible(false)
    end

    self.reuse_scrollview:Show(self.height, 0)
end

function bag_panel:ShowSingleRowItem(item_row, sub_row_panel, pos_y)
    for col = 1, MAX_COL do
        local data_index = (item_row - 1) * MAX_COL + col
        local sub_panel = sub_row_panel[col]

        sub_panel.root_node:setVisible(true)

        if data_index <= self.item_num then
            local item = self.item_list[data_index]
            sub_panel:Load(item, ITEM_STATUS["have_item"], self.cur_tab_type)

        elseif data_index <= self.real_capacity then
            sub_panel:Load(nil, ITEM_STATUS["unlock_but_no_item"], self.cur_tab_type)

        elseif data_index == (self.real_capacity + 1) then
            sub_panel:Load(nil, ITEM_STATUS["show_lock_text"], self.cur_tab_type)

        else
            sub_panel:Hide()
        end

        if pos_y then
            sub_panel.root_node:setPositionY(pos_y)
        end
    end
end

function bag_panel:UpdateReward()
    local reward_info = self.reward_info_list[self.cur_reward_index]
    if not reward_info then
        return
    end

    self.cur_reward_index = self.cur_reward_index + 1
    local reward_type = reward_info.id

    local value = reward_info.param2 or reward_info.param1
    local value_str = "+" .. value

    if reward_type == REWARD_TYPE["resource"] then
        local resource_type = reward_info.param1
        self:UpdateSpineNode(resource_config[resource_type]["icon"], value_str)

    elseif reward_type == REWARD_TYPE["leader_bp"] then
        self:UpdateSpineNode(BP_ICON, value_str)

    elseif reward_type == REWARD_TYPE["pickaxe_count"] then
        self:UpdateSpineNode(PICKAGE_ICON, value_str)

    elseif reward_type == REWARD_TYPE["carnival_token"] then
        self:UpdateSpineNode(config_manager.carnival_token_config[reward_info.param1].icon, value_str)

    elseif reward_type == REWARD_TYPE["mercenary"] then
        self.reward_num = 1
        graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
    end

end

function bag_panel:UpdateSpineNode(icon, value_str)
    self.reward_panel:LoadIcon(icon)
    self.reward_panel:SetString(value_str)

    self.reward_panel:ToBindNode()
end

function bag_panel:SetSelectBoxPosition()
    local row = math.ceil(self.cur_sub_panel_index / MAX_COL)
    local col = self.cur_sub_panel_index  - (row - 1) * MAX_COL

    local sub_panel = self.item_sub_panels[row][col]

    self.select_spine:setPosition(sub_panel.root_node:getPosition())
    self.select_spine:setVisible(true)
end

function bag_panel:Update(elspsed_time)
    self.reward_panel:Update()
    
    if not self.reward_panel:IsSpineVisible() and self.cur_reward_index <= self.reward_num then
        self:UpdateReward()
    end
end

function bag_panel:UpdateTabStatus(tab_type)
    self.cur_tab_type = tab_type
    detail_info_sub_panel:SetCurTabType(tab_type)

    if tab_type == TAB_TYPE["item"] then
        self.item_tab_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
        self.item_tab_btn:setLocalZOrder(101)
        self.resource_tab_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
        self.resource_tab_btn:setLocalZOrder(100)

        --加载item
        self:LoadItems()

    elseif tab_type == TAB_TYPE["resource"] then
        self.resource_tab_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
        self.resource_tab_btn:setLocalZOrder(101)
        self.item_tab_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
        self.item_tab_btn:setLocalZOrder(100)

        --加载resource
        self:LoadResource()
    end
end

function bag_panel:RegisterWidgetEvent()

    local click_tab_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local index = widget:getTag()
            self:UpdateTabStatus(index)
        end
    end

    self.item_tab_btn:addTouchEventListener(click_tab_method)
    self.resource_tab_btn:addTouchEventListener(click_tab_method)

    self.view_bag_content = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local index = widget:getTag()

            local row = math.ceil(index / MAX_COL)
            local col = index - (row - 1) * MAX_COL
            local sub_panel = self.item_sub_panels[row][col]

            if sub_panel.next_unlock then
                local mode = client_constants.CONFIRM_MSGBOX_MODE["upgrade_bag"]
                graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode)
                return
            end

            self.cur_itme_id = sub_panel.item_id
            if self.cur_itme_id == 0 then
                return
            end

            detail_info_sub_panel:Show(self.cur_itme_id)

            self.cur_sub_panel_index = index
            self:SetSelectBoxPosition()
        end
    end

    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), "bag_panel")
end

function bag_panel:RegisterEvent()

    graphic:RegisterEvent("update_bag", function()
        if not self.root_node:isVisible() then
            return
        end

        self:Show()
    end)

    --使用道具
    graphic:RegisterEvent("use_item_which_in_bag", function(item_id, extra_num, item_template_info)
        if not self.root_node:isVisible() then
            return
        end

        if not item_template_info then
            return
        end

        if self.cur_tab_type ~= TAB_TYPE['item'] then
            return
        end

        local rule_type = item_template_info.rule_type
        if rule_type == ITEM_RULE["refresh_temple"] then
            graphic:DispatchEvent("show_prompt_panel", "temple_refresh_success")

        elseif rule_type == ITEM_RULE["vip"] or rule_type == ITEM_RULE["refresh_mining"] then

        elseif rule_type == ITEM_RULE["recycle_coolant"] then  --CG
            --冷却剂使用成功后的客户端处理
        else
            local reward_info_list = reward_logic:GetRewardInfoList()
            self.reward_num = #reward_info_list
            self.cur_reward_index = 1

            for i, reward_info in ipairs(reward_info_list) do
                self.reward_info_list[i] = reward_info
            end

            self:UpdateReward()
        end

        self.item_list = bag_logic:GetItemList()
        self.item_num = #self.item_list

        --第一个item_row 2:sub_panel_row
        for i = 1, self.sub_panel_row do
            local item_row = self.reuse_scrollview:GetDataIndex(i)
            self:ShowSingleRowItem(item_row, self.item_sub_panels[i])
        end

        if self.item_num > 0 then
            local head_sub_panel_index = self.reuse_scrollview.head_sub_panel_index

            if self.item_sub_panels[head_sub_panel_index][1].item_id == 0 then
                self.select_spine:setVisible(false)
                detail_info_sub_panel:Show(nil)

                detail_info_sub_panel.no_item_desc_text:setVisible(false)

            else
                --判断是不是最后一个， 下一个的item_id是否为0
                local next_row = math.ceil(self.cur_sub_panel_index / MAX_COL)
                local next_col = self.cur_sub_panel_index  - (next_row - 1) * MAX_COL

                if self.item_sub_panels[next_row][next_col].item_id == 0 then
                    self.cur_sub_panel_index = self.cur_sub_panel_index - 1

                    if self.cur_sub_panel_index <= 0 then
                        self.cur_sub_panel_index = MAX_COL*MAX_ROW
                    end
                end

                local row = math.ceil(self.cur_sub_panel_index / MAX_COL)
                local col = self.cur_sub_panel_index  - (row - 1) * MAX_COL
                local item_id = self.item_sub_panels[row][col].item_id

                detail_info_sub_panel:Show(item_id)

                self:SetSelectBoxPosition()
                self.select_spine:setVisible(true)
            end

        else
            detail_info_sub_panel:Show(nil, self.cur_tab_type)
            self.select_spine:setVisible(false)
        end
    end)
end

return bag_panel
