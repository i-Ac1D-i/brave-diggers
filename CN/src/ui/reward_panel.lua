local config_manager = require "logic.config_manager"
local reward_logic = require 'logic.reward'
local audio_manager = require "util.audio_manager"

local destiny_skill_config = config_manager.destiny_skill_config

local troop_logic = require "logic.troop"
local constants = require "util.constants"
local client_constants = require "util.client_constants"

local graphic = require "logic.graphic"
local language= require "logic.language"

local icon_template = require "ui.icon_panel"
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local new_mercenarys_panel = require "ui.new_mercenarys_panel"
local platform_manager = require "logic.platform_manager"

local REWARD_TYPE = constants.REWARD_TYPE
local REWARD_SOURCE = constants.REWARD_SOURCE

local PLIST_TYPE = ccui.TextureResType.plistType

local REWARD_PANEL_TYPE = client_constants.REWARD_PANEL_TYPE

--r2bug优化
local DESTINY_DESC_POS = {x=320,y=469} 
local DESTINY_NAME_POS = {x=320,y=445} 

local lang_constants = require "util.language_constants"

local PANEL_TYPE_MAP =
{
    [REWARD_TYPE["item"]] = REWARD_PANEL_TYPE["get_item"],
    [REWARD_TYPE["resource"]] = REWARD_PANEL_TYPE["get_item"],
    [REWARD_TYPE["pickaxe_count"]] = REWARD_PANEL_TYPE["special"],
    [REWARD_TYPE["area"]] = REWARD_PANEL_TYPE["no_reward"],
    [REWARD_TYPE["destiny_weapon"]] = REWARD_PANEL_TYPE["special"],
    [REWARD_TYPE["leader_bp"]] = REWARD_PANEL_TYPE["special"],
    [REWARD_TYPE["camp_capacity"]] = REWARD_PANEL_TYPE["special"],
    [REWARD_TYPE["mercenary"]] = REWARD_PANEL_TYPE["mercenary"],
    [REWARD_TYPE["maze"]] = REWARD_PANEL_TYPE["no_reward"],
    [REWARD_TYPE["feature"]] = REWARD_PANEL_TYPE["unlock_new_features"],
    [REWARD_TYPE["pickaxe_level"]] = REWARD_PANEL_TYPE["special"],
    [REWARD_TYPE["formation_capacity"]] = REWARD_PANEL_TYPE["special"],
    [REWARD_TYPE["carnival_token"]] = REWARD_PANEL_TYPE["get_item"],
    [REWARD_TYPE["campaign"]] = REWARD_PANEL_TYPE["get_item"],
}

local MAX_ITEM_NUM = 6
--缓存奖励信息 队列

--奖励列表中的项 资源or道具
local normal_msgbox = panel_prototype.New()
function normal_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/reward_normal_msgbox.csb")

    self.confirm_btn = self.root_node:getChildByName("confirm_btn")
    self.close_btn = self.root_node:getChildByName("close_btn")

    self.item_sub_panels = {}
    for i = 1, MAX_ITEM_NUM do
        local sub_panel = icon_template.New()
        sub_panel:Init(self.root_node)
        self.item_sub_panels[i] = sub_panel
    end

    self.item_bg = self.root_node:getChildByName("item_bg")
    local item_bg_size = self.item_bg:getContentSize()
    self.scroll_view_items = {}

    self.scroll_view = ccui.ScrollView:create()
    self.scroll_view:setTouchEnabled(true)
    self.scroll_view:setClippingEnabled(true)
    self.scroll_view:setBounceEnabled(false)
    self.scroll_view:setDirection(ccui.ScrollViewDir.horizontal)
    self.scroll_view:setContentSize(cc.size(item_bg_size.width - 30, item_bg_size.height)) 
    self.scroll_view:setInnerContainerSize(self.scroll_view:getContentSize())
    self.scroll_view:setAnchorPoint(cc.p(0, 0))
    self.scroll_view:setPosition(cc.p(15, 0))   
    self.item_bg:addChild(self.scroll_view)
    self.scroll_view:setVisible(false)
end

function normal_msgbox:ShowSubPanel(flag)
    for i = 1, MAX_ITEM_NUM do
        self.item_sub_panels[i].root_node:setVisible(flag)
    end
end

function normal_msgbox:ShowReward()
    
    self:ShowSubPanel(not self.use_scroll_view_flag)

    if self.use_scroll_view_flag then 
       local scroll_view_items = #self.scroll_view_items
       local item_width = 82
       local init_x = 40

       for i = 1, scroll_view_items do 
           self.scroll_view_items[i]:SetPosition(init_x + (i - 1) * item_width, 63)
       end

       local content_size = self.scroll_view:getContentSize()
       self.scroll_view:setInnerContainerSize(cc.size(scroll_view_items * item_width, content_size.height))
    else
        panel_util:SetIconSubPanelsPosition(self.item_sub_panels, MAX_ITEM_NUM, self.cur_sub_count, 600)
    end
    self.scroll_view:setVisible(self.use_scroll_view_flag)

end

function normal_msgbox:Hide()
   self.scroll_view:removeAllChildren()
   self.scroll_view_items = {} 
   self.root_node:setVisible(false)
end

function normal_msgbox:Show(reward_info, index)
    if not self.use_scroll_view_flag then 
       self.item_sub_panels[index]:Show(reward_info.id, reward_info.param1, reward_info.param2, false, false)
    else
        local icon_panel = icon_template.New()
        icon_panel:Init(self.scroll_view)
        icon_panel:Show(reward_info.id, reward_info.param1, reward_info.param2, false, false)
        self.scroll_view_items[index] = icon_panel
    end
end

---------------------------------------------------------------
--特殊奖励 比如开启新地图，十字镐升级,出战人数提升等
local special_msgbox = panel_prototype.New()

function special_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/reward_special_msgbox.csb")
    local root_node = self.root_node

    self.icon_img = root_node:getChildByName("icon")

    self.close_btn = root_node:getChildByName("close_btn")
    self.confirm_btn = root_node:getChildByName("confirm_btn")

    self.destiny_node = root_node:getChildByName("destiny")
    self.destiny_name_text = self.destiny_node:getChildByName("name")

    self.add_bp_node = root_node:getChildByName("add_bp")
    self.add_bp_desc_text = self.add_bp_node:getChildByName("desc")
    self.add_bp_text = self.add_bp_node:getChildByName("bp")
    self:RecordPos()
end

function special_msgbox:RecordPos( )
    if not self.add_bp_node_origin then
        self.add_bp_node_origin = cc.p(self.add_bp_node:getPosition())
    end
    if not self.add_bp_desc_text_origin then
        self.add_bp_desc_text_origin = cc.p(self.add_bp_desc_text:getPosition())
    end
    if not self.add_bp_text_origin then
        self.add_bp_text_origin = cc.p(self.add_bp_text:getPosition())
    end
    if not self.add_bp_text_origin_anchor then
        self.add_bp_text_origin_anchor = self.add_bp_text:getAnchorPoint()
    end

    self.add_bp_node:setPosition(self.add_bp_node_origin)
    self.add_bp_desc_text:setPosition(self.add_bp_desc_text_origin)
    self.add_bp_text:setAnchorPoint(self.add_bp_text_origin_anchor)
    self.add_bp_text:setPosition(self.add_bp_text_origin) 
end

function special_msgbox:Show(reward_info)
    self.root_node:setVisible(true)

    local reward_type = reward_info.id
    local value = reward_info.param1
    local icon_path, desc, show_destiny = "", "", false

    local is_move_pos = false
    local is_move_pos2 = false
    local is_move_pos3 = false

    if reward_type == REWARD_TYPE["formation_capacity"] then
        --出站人数提升
        desc = lang_constants:Get("reward_formation_capacity")
        icon_path = client_constants.SPECIAL_REWARD_TYPE_IMG_PATH["add_max_explorer"]
        need_center = true
        is_move_pos2 = true
    elseif reward_type == REWARD_TYPE["pickaxe_level"] then
        --矿镐等级提升
        desc = lang_constants:Get("reward_pickaxe_upgrade")
        icon_path = client_constants.SPECIAL_REWARD_TYPE_IMG_PATH["pickaxe"]
        is_move_pos = true  --当矿镐次数提升的时候需要移动文本
        need_center = true
    elseif reward_type == REWARD_TYPE["leader_bp"] then
        --提升战斗力
        desc = lang_constants:Get("reward_leader_bp")
        icon_path = client_constants.SPECIAL_REWARD_TYPE_IMG_PATH["add_bp"]
        need_center = true

    elseif reward_type == REWARD_TYPE["destiny_weapon"] then
        --获取宿命武器
        desc = destiny_skill_config[reward_info.param1]["name"]
        icon_path = destiny_skill_config[reward_info.param1]["icon"]
        show_destiny = true
        is_move_pos3 = true
    elseif reward_type == REWARD_TYPE["camp_capacity"] then
        desc = lang_constants:Get("reward_camp_capacity")
        icon_path = client_constants.SPECIAL_REWARD_TYPE_IMG_PATH["add_max_explorer"]

    elseif reward_type == REWARD_TYPE["pickaxe_count"] then
        --矿镐次数提升
        desc =  lang_constants:Get("reward_pickaxe_count")
        icon_path =  client_constants.SPECIAL_REWARD_TYPE_IMG_PATH["pickaxe"]  
        need_center = true
    end

    if icon_path ~= "" then
        self.icon_img:loadTexture(icon_path, PLIST_TYPE)
    end

    self.icon_img:setVisible(true)

    self.destiny_node:setVisible(show_destiny)
    self.add_bp_node:setVisible(not show_destiny)
    self:RecordPos()
    if show_destiny then
        self.destiny_name_text:setString(desc)
         --R2
        local add_destiny_desc_two_line = platform_manager:GetChannelInfo().add_destiny_desc_two_line
        if add_destiny_desc_two_line then
            --宿命武器时描述两行
            local desc_text = self.destiny_node:getChildByName("desc")
            local name_text = self.destiny_node:getChildByName("name")
            local desc2_text = self.destiny_node:getChildByName("desc2")
            
            desc_text:setPosition(DESTINY_DESC_POS)
            name_text:setAnchorPoint({x=0.5,y=0.5})
            name_text:setPosition(DESTINY_NAME_POS)
            desc2_text:setVisible(false)

        end
    else
        self.add_bp_desc_text:setString(desc)

        if value then
            panel_util:ConvertUnit(value, self.add_bp_text)

        else
            self.add_bp_text:setString("")
        end

         --FYD  修改位置
        local add_bp_desc_pos = platform_manager:GetChannelInfo().cord_origin_pos
        if add_bp_desc_pos and (add_bp_desc_pos.x ~= -1 and add_bp_desc_pos.y ~= -1) then --重置该文本控件的位置为原始位置
             self.add_bp_desc_text:setPosition(add_bp_desc_pos)
        end

        if add_bp_desc_pos and add_bp_desc_pos.x == -1 and add_bp_desc_pos.y == -1 then    --第一次进来，记录该text的原始位置
            platform_manager:GetChannelInfo().cord_origin_pos = cc.p(self.add_bp_desc_text:getPosition())   --记录原始的位置
        end

        if is_move_pos and add_bp_desc_pos then  --如果add_bp_desc_pos 存在 说明需要 文本需要修改位置
            if add_bp_desc_pos.x == -1 and add_bp_desc_pos.y == -1 then    --第一次进来，记录该text的原始位置
                 platform_manager:GetChannelInfo().cord_origin_pos = cc.p(self.add_bp_desc_text:getPosition())   --记录原始的位置
             end
             local mv_width = platform_manager:GetChannelInfo().ad_bp_width_move or 35
            self.add_bp_desc_text:setPositionX(self.add_bp_desc_text:getPositionX()+mv_width) 
        end

        if is_move_pos2 and add_bp_desc_pos then  -- FYD  跟上面不一樣，合并的时候不要删掉
            if add_bp_desc_pos.x == -1 and add_bp_desc_pos.y == -1 then    
                 platform_manager:GetChannelInfo().cord_origin_pos = cc.p(self.add_bp_desc_text:getPosition())   --记录原始的位置
             end
             local mv_width = platform_manager:GetChannelInfo().ad_bp_width_move2 or 35
            self.add_bp_desc_text:setPositionX(self.add_bp_desc_text:getPositionX()+mv_width) 
        end
        --R2 修改位置
        local move_bp3_pos = platform_manager:GetChannelInfo().ad_bp_width_move3
        if is_move_pos2 and move_bp3_pos then  
            if move_bp3_pos ~= self.add_bp_text:getPositionX() then
                move_bp3_pos=self.add_bp_text:getPositionX()+move_bp3_pos
                platform_manager:GetChannelInfo().ad_bp_width_move3= move_bp3_pos
            end
            self.add_bp_text:setPositionX(move_bp3_pos)
        end

        if platform_manager:GetChannelInfo().reward_special_desc_center and need_center then
            local center_pos = cc.p(self.confirm_btn:getPosition())
            center_pos.y = center_pos.y + 60
            self.add_bp_node:setPosition(center_pos)
            self.add_bp_desc_text:setAnchorPoint(0,0)
            local desc_width = self.add_bp_desc_text:getBoundingBox().width 
            print("desc_width : ",desc_width)
            local bp_width = self.add_bp_text:getBoundingBox().width
            local all_width = desc_width + bp_width
            local add_bg_desc_pos = cc.p(- all_width/2,0)
            self.add_bp_desc_text:setPosition(add_bg_desc_pos)
            add_bg_desc_pos.x = add_bg_desc_pos.x + desc_width + 5
            add_bg_desc_pos.y = add_bg_desc_pos.y - 10
            self.add_bp_text:setAnchorPoint(0,0)
            self.add_bp_text:setPosition(add_bg_desc_pos)
        end

    end
end

local reward_panel = panel_prototype.New(true)
function reward_panel:Init()
    self.root_node = cc.Node:create()

    self.normal_msgbox = normal_msgbox
    self.normal_msgbox:Init()
    self.root_node:addChild(self.normal_msgbox.root_node)

    self.special_msgbox = special_msgbox
    self.special_msgbox:Init()
    self.root_node:addChild(self.special_msgbox.root_node)

    self.mercenary_sub_panel = new_mercenarys_panel
    self.mercenary_sub_panel:Init()
    self.root_node:addChild(self.mercenary_sub_panel.root_node)

    self.special_info = {}
    self.new_mercenary_list = {}
    self.new_mercenary_num = 0

    self.reward_info_queue = {}

    self.root_node:setVisible(false)

    self:RegisterWidgetEvent()
end

--获取奖励信息
function reward_panel:Show(close_call)
    self:PushRewardInfoToQueue()
    self.close_call = close_call
    if not self.root_node:isVisible() then
    self.root_node:setVisible(true)
        self:PopRewardInfoFromQueue()
    end
end

function reward_panel:PushRewardInfoToQueue()
    local reward_info_list = reward_logic:GetRewardInfoList() 
    if not reward_info_list then
        return
    end

    local copy_list = {}
    for i, reward_info in ipairs(reward_info_list) do
        copy_list[i] = reward_info
    end

    reward_logic:ResetRewardInfoList()

    table.insert(self.reward_info_queue, 1, copy_list)
end

function reward_panel:PopRewardInfoFromQueue()
    self.normal_msgbox:Hide()
    self.special_msgbox:Hide()
    self.mercenary_sub_panel:Hide()

    local cur_reward_num = #self.reward_info_queue
    if cur_reward_num <= 0 then
        graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        if self.close_call and type(self.close_call) == "function" then
            self.close_call()
        end 
    else
        self.cur_reward_info = self.reward_info_queue[cur_reward_num]
        table.remove(self.reward_info_queue)

        self:ParseRewardInfoAndShow()
    end
end

--解析奖励信息 并且显示出来
function reward_panel:ParseRewardInfoAndShow()
    local resource_count = 0
    local special_count = 0
    self.new_mercenary_num = 0
    self.normal_msgbox.use_scroll_view_flag = false

     --判断普通奖励的个数
    local normal_numbers = 0
    for i, reward_info in ipairs(self.cur_reward_info) do
        local panel_type = PANEL_TYPE_MAP[reward_info.id]
        if panel_type == REWARD_PANEL_TYPE["get_item"] then
            normal_numbers = normal_numbers + 1
        end
    end

    if normal_numbers > MAX_ITEM_NUM then 
        self.normal_msgbox.use_scroll_view_flag = true 
    end

    for i, reward_info in ipairs(self.cur_reward_info) do
        local panel_type = PANEL_TYPE_MAP[reward_info.id]

        if panel_type == REWARD_PANEL_TYPE["get_item"] then
            resource_count = resource_count + 1
            self.normal_msgbox:Show(reward_info, resource_count)

        elseif panel_type == REWARD_PANEL_TYPE["special"] then
            special_count = special_count + 1
            self.special_info[special_count] = reward_info

        elseif panel_type == REWARD_PANEL_TYPE["mercenary"] then
            self.new_mercenary_num = self.new_mercenary_num + 1
            self.new_mercenary_list[self.new_mercenary_num] = troop_logic:GetMercenaryInfo(reward_info["mercenary_id"])
        end
    end

    self.normal_msgbox.cur_sub_count = resource_count
    self.special_msgbox.cur_sub_count = special_count

    self:ShowRewardMsgbox()
end

function reward_panel:Update(elapsed_time)
    self.mercenary_sub_panel:Update(elapsed_time)

    if self.new_mercenary_num > 0 and self.mercenary_sub_panel.can_leave_reward then
        self.mercenary_sub_panel:Hide()
        self.new_mercenary_num = 0
        self:PopRewardInfoFromQueue()
    end
end

function reward_panel:ShowRewardMsgbox()
    local special_count = self.special_msgbox.cur_sub_count

    if special_count > 0 then
        self.special_msgbox:Show(self.special_info[special_count])

    else
        self.special_msgbox:Hide()

        if self.normal_msgbox.cur_sub_count > 0 then
            self.normal_msgbox:ShowReward()
            self.normal_msgbox.root_node:setVisible(true)

        elseif self.new_mercenary_num > 0 then
            self.mercenary_sub_panel:Show(self.new_mercenary_list, self.new_mercenary_num)

        else
            self:PopRewardInfoFromQueue()
        end
    end
end

--注册控件事件
function reward_panel:RegisterWidgetEvent()
    local close_normal_msgbox = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            self.normal_msgbox:Hide()

            if self.new_mercenary_num > 0 then
                self.mercenary_sub_panel:Show(self.new_mercenary_list, self.new_mercenary_num)
            else
                self:PopRewardInfoFromQueue()
            end
        end
    end

    self.normal_msgbox.close_btn:addTouchEventListener(close_normal_msgbox)
    self.normal_msgbox.confirm_btn:addTouchEventListener(close_normal_msgbox)

    --尝试关闭特殊奖励msgbox
    local close_special_msgbox = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            self.special_msgbox.cur_sub_count = self.special_msgbox.cur_sub_count - 1
            self:ShowRewardMsgbox()
        end
    end

    self.special_msgbox.close_btn:addTouchEventListener(close_special_msgbox)
    self.special_msgbox.confirm_btn:addTouchEventListener(close_special_msgbox)

end

return reward_panel
