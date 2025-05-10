local config_manager = require "logic.config_manager"
local constants = require "util.constants"
local audio_manager = require"util.audio_manager"

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local time_logic = require "logic.time"
local campaign_logic = require "logic.campaign"
local vip_logic = require "logic.vip"

local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local utils = require "util.utils"
local mercenary_template_panel = require "ui.mercenary_template_panel"
local MERCENARY_PREVIEW_SHOW_MOD = client_constants["MERCENARY_PREVIEW_SHOW_MOD"]  --preview 面板显示mod
local mercenary_preview_sub_panel = require "ui.mercenary_preview_panel"
local spine_manager = require "util.spine_manager"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local SORT_TYPE = client_constants["SORT_TYPE"]
local SORT_RANGE = client_constants["SORT_RANGE"]

local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]
local MERCENARY_MSGBOX = client_constants["MERCENARY_MSGBOX"] --佣兵弹窗

local MERCENARY_TEMPLATE_SOURCE = client_constants["MERCENARY_TEMPLATE_PANEL_SOURCE"]["list"]
local MAX_MERCENARY_NUM_PER_ROW = 5
local MAX_FORMATION_CAPACITY = constants["MAX_FORMATION_CAPACITY"]
local CHOOSE_SHOW_MODE = client_constants["MERCENARY_CHOOSE_SHOW_MODE"]["vanity_adventure"]

local MAX_SVIEW_SHOW_MERCEANRY_NUM = 20 --sview里最多能看到的佣兵个数
local PLIST_TYPE = ccui.TextureResType.plistType
local MAX_SCROLLVIEW_HEIGHT = 770
local MIN_SCROLLVIEW_HEIGHT = 540
local SCREEN_WIDTH = 640
local MOVE_DIS = 230

local TEXT_MAX_LENGTH = 286

local MERCENRAY_SUB_PANEL_HEIGHT = 62
local INTERVAL_X = 124
local INTERVAL_Y = 124
local BEGIN_X = 72

--选中动画
local choose_spine_tracker = {}
choose_spine_tracker.__index = choose_spine_tracker

function choose_spine_tracker.New(root_node, slot_name)
    local t = {}
    t.slot_name = slot_name
    t.root_node = root_node
    t.finish_choose = true

    t.root_node:registerSpineEventHandler(function(event)
        t.finish_choose = true
    end, sp.EventType.ANIMATION_END)

    return setmetatable(t, choose_spine_tracker)
end

--widget 绑定要播放的动画
function choose_spine_tracker:Bind(animation, x, y, widget)
    self.widget = widget
    self.root_node:setPosition(x, y)
    self.root_node:setSlotsToSetupPose()
    self.root_node:setAnimation(0, animation, false)
    self.finish_choose = false
    self.root_node:setVisible(true)
end

function choose_spine_tracker:Update()
    if not self.finish_choose then
        if self.root_node:isVisible() and self.widget then
            local x, y, scale_x, scale_y, alpha, rotation = self.root_node:getSlotTransform(self.slot_name)
            self.widget:setScale(scale_x, scale_y)
        end
    end
end
--佣兵抖动动画, 选中的白色框也会跟着抖
local shaking_spine_tracker = {}
shaking_spine_tracker.__index = shaking_spine_tracker

function shaking_spine_tracker.New(root_node, slot_name, animation)
    local t = {}
    t.slot_name = slot_name
    t.root_node = root_node
    t.animation = animation
    return setmetatable(t, shaking_spine_tracker)
end

--绑定要抖动的控件
function shaking_spine_tracker:Bind(x, y, widget)
    if not widget then
        self.root_node:setVisible(false)
        return
    end

    self.root_node:setSlotsToSetupPose()
    self.root_node:setAnimation(0, self.animation, true)

    self.offset_x = x
    self.offset_y = y
    self.widget = widget

    widget:setPosition(x, y)
    widget:setVisible(true)

    self.root_node:setPosition(x, y)
    self.root_node:setVisible(true)
end

---停止抖动
function shaking_spine_tracker:StopShaking()
    self.root_node:setVisible(false)
    if self.widget then
        --回到初始状态
        self.widget:setPosition(self.offset_x, self.offset_y)
        self.widget:setRotation(0)
    end

    self:RemoveSelectWidget()
end

--移除选中的白框
function shaking_spine_tracker:RemoveSelectWidget()
    if self.select_widget then
        self.select_widget:setRotation(0)
        self.select_widget = nil
    end
end

--绑定选中控件
function shaking_spine_tracker:BindSelectWidget(select_widget)
    self.select_widget = select_widget
end

function shaking_spine_tracker:Update()
    if self.root_node:isVisible() and self.widget then
        local x, y, scale_x, scale_y, alpha, rotation = self.root_node:getSlotTransform(self.slot_name)
        self.widget:setPosition(self.offset_x + x, self.offset_y + y)
        self.widget:setOpacity(alpha)
        self.widget:setRotation(rotation)

        if self.select_widget then
            self.select_widget:setPosition(self.offset_x + x, self.offset_y + y)
            self.select_widget:setOpacity(alpha)
            self.select_widget:setRotation(rotation)
        end
    end
end

--选中动画
local select_spine_tracker = {}
select_spine_tracker.__index = select_spine_tracker

function select_spine_tracker.New(root_node, slot_name)
    local t = {}
    t.slot_name = slot_name
    t.root_node = root_node

    t.root_node:registerSpineEventHandler(function(event)
        t.finish_choose = true
    end, sp.EventType.ANIMATION_END)

    return setmetatable(t, select_spine_tracker)
end

function select_spine_tracker:Bind(animation, x, y, widget)
    if not widget then
        self.root_node:setVisible(false)
        return
    end

    self.animation = animation

    self.offset_x = x

    self.offset_y = y

    self.widget = widget

    self.root_node:setPosition(x, y)
    self.root_node:setVisible(true)

    self.root_node:setSlotsToSetupPose()
    self.root_node:setAnimation(0, self.animation, false)
    self.finish_choose = false
end

function select_spine_tracker:Update()
    if not self.finish_choose then
        if self.root_node:isVisible() and self.widget then
            local x, y, scale_x, scale_y, alpha, rotation = self.root_node:getSlotTransform(self.slot_name)
            self.widget:setScale(scale_x, scale_y)
        end
    end
end

local vanity_adventure_list_panel = panel_prototype.New()

function vanity_adventure_list_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/vanity_adventure_list_panel.csb")

    self.back_btn = self.root_node:getChildByName("back_btn")
        
    self.scroll_view = self.root_node:getChildByName("scroll_view")

    self.mercenary_template = self.scroll_view:getChildByName("mercenary_template"):getChildByName("mercenary_template_0")

    self.mercenary_template:setVisible(false)

    self.arrange_mercenary_pos_btn = self.root_node:getChildByName("arrange_mercenary_pos_btn")
    self.arrange_node = self.root_node:getChildByName("arrange_node")
    self.arrange_node:setVisible(false)

    self.arrange_text = self.root_node:getChildByName("arrange_text")

    self.rest_btn = self.arrange_node:getChildByName("rest_btn")
    self.replace_btn = self.arrange_node:getChildByName("replace_btn")

    self.choose_img = self.scroll_view:getChildByName("select")
    self.choose_img:setAnchorPoint(0.5, 0.5)
    self.choose_img:setLocalZOrder(100)

    self.top_node = self.root_node:getChildByName("top_node")

    self.my_skill_name = self.top_node:getChildByName("desc_myskill_title")
    self.my_skill_scroll_view = self.top_node:getChildByName("scroll_view_skills")
    self.my_skill_desc = self.my_skill_scroll_view:getChildByName("desc_myskill")
    self.my_skill_desc:getVirtualRenderer():setMaxLineWidth(TEXT_MAX_LENGTH)

    self.boss_skill_name = self.top_node:getChildByName("desc_myskill_title")
    self.boss_skill_scroll_view = self.top_node:getChildByName("scroll_view_skills_boss")
    self.boss_skill_desc = self.boss_skill_scroll_view:getChildByName("desc_myskill")
    self.boss_skill_desc:getVirtualRenderer():setMaxLineWidth(TEXT_MAX_LENGTH)

    self.title_text = self.top_node:getChildByName("title_text")

    self.property_node = self.root_node:getChildByName("property")
    self.speed_text = self.property_node:getChildByName("speed"):getChildByName("value")
    self.defense_text = self.property_node:getChildByName("defense"):getChildByName("value")
    self.dodge_text = self.property_node:getChildByName("dodge"):getChildByName("value")
    self.authority_text = self.property_node:getChildByName("authority"):getChildByName("value")

    self.select_img = self.scroll_view:getChildByName("select")
    self.select_img:setVisible(false)

    self.cur_choose_spine_tracker = self:CreateChooseSpineTracker()
    self.last_choose_spine_tracker = self:CreateChooseSpineTracker()

    self.mercenary_sub_panels = {}
    self.sub_panel_pos_xs = {}
    self.sub_panel_pos_ys = {}
    self.shaking_spine_trackers = {}

    self.last_mercenary_pos = 1
    self.cur_mercenary_pos = 1
    self.max_formation_capacity = 0 
    self.select_maze_id = 1

    self:RegisterWidgetEvent()
    self:RegisterEvent()

    self:CreateMoveMercenaryPanel()
end

--创建一个sub_panel
function vanity_adventure_list_panel:CreateOneMercenarySubPanel(tag)
    local sub_panel = mercenary_template_panel.New()
    sub_panel:Init(self.mercenary_template:clone(), client_constants["MERCENARY_TEMPLATE_PANEL_SOURCE"]["vanity_adventure_formation"])
    sub_panel:SetIndex(tag)
    sub_panel.root_node:setAnchorPoint(0.5, 0.5)
    sub_panel.root_node:setLocalZOrder(1)
    sub_panel.root_node:setTouchEnabled(true)
    sub_panel.root_node:addTouchEventListener(self.view_mercenary)
    sub_panel.root_node:setPosition(0, 0)
    sub_panel.root_node:setTag(tag)

    self.scroll_view:addChild(sub_panel.root_node)

    return sub_panel
end

function vanity_adventure_list_panel:Show(select_maze_id)
    self.root_node:setVisible(true)
    if select_maze_id then
        --选中第一个
        self.cur_mercenary_pos = 1
        self:RestUIBefore()
    end
    
    self.select_maze_id = select_maze_id or self.select_maze_id
    self:LoadFormation()
    self:UpdateProperty()
    troop_logic:CalcVanityTroopBP(true)
end

--重置界面结构
function vanity_adventure_list_panel:RestUIBefore()
    self.shaking = false
    if self.arrange_node:isVisible() then
        self.choose_img:setVisible(false)
        self:ShakingMercenarySubPanels(false)
        self.arrange_node:setVisible(false)
    end
    self.arrange_text:setString(lang_constants:Get("mercenary_adjust_formation"))
    self.top_node:setPosition(cc.p(0,0))
    if self.scroll_view_y then
        self.scroll_view:setPosition(cc.p(self.scroll_view:getPositionX(),self.scroll_view_y)) 
        self.scroll_view:setContentSize(cc.size(SCREEN_WIDTH, MIN_SCROLLVIEW_HEIGHT))
    end
end

--更新阵容四维属性
function vanity_adventure_list_panel:UpdateProperty()
    local speed, authority, dodge, defense = troop_logic:GetVanityTroopProperty()
    self.speed_text:setString(speed)
    self.defense_text:setString(defense)
    self.dodge_text:setString(dodge)
    self.authority_text:setString(authority)
end

function vanity_adventure_list_panel:Update(elapsed_time)
    --多阵容箭头
    self.cur_choose_spine_tracker:Update(elapsed_time)
    self.last_choose_spine_tracker:Update(elapsed_time)

    --抖动动画
    if self.shaking then
        for i = 1, self.cur_mercenary_num do
            self.shaking_spine_trackers[i]:Update(elapsed_time)
        end
    end

    self:CheckCanMovingSubPanel(elapsed_time)
end

--检测是否可以开始移动sub_panel
function vanity_adventure_list_panel:CheckCanMovingSubPanel(elapsed_time)
    if self.start_drag_sub_panel then
        self.drag_duration = self.drag_duration + elapsed_time
        if self.drag_duration >= 0.2 then

            --则开始移动sub_panel
            self.start_drag_sub_panel = false
            self.drag_duration = 0

            self.moving_sub_panel_flag = true

            --防止长按的时候 手指移动位置
            -- self.moving_sub_panel.root_node:setPosition(self.touch_start_location)
            --开始寻找位置
            self.start_find_pos = true
            self.find_duration = 0
        end
    end
end


--开始拖动佣兵 sub_panel
function vanity_adventure_list_panel:StartDragMercenarySubPanel(move_location)
    local moving_root_node = self.moving_sub_panel.root_node
    if not moving_root_node:isVisible() then
       moving_root_node:setVisible(true)
       self.choose_img:setVisible(false)
       self.moving_sub_panel:Load(self.choose_sub_panel.mercenary)
    end

    --拖动位置判断
    local move_x, move_y = moving_root_node:getPositionX(), moving_root_node:getPositionY()
    --移动位移超过20 则开始寻找位移
    if (move_x > move_location.x - 20) and (move_x < move_location.x + 20) then
        if (move_y > move_location.y - 20) and (move_y < move_location.y + 20) then
            self.start_find_pos = true
        else
           self.find_duration = 0
        end
    else
       self.find_duration = 0
    end
    moving_root_node:setPosition(move_location.x, move_location.y)

    local scroll_pos_y = self.scroll_view:getPositionY()

    local in_scrollview_pos_y = scroll_pos_y - move_location.y - 20
    local x = math.ceil(move_location.x/INTERVAL_X)
    if in_scrollview_pos_y < 0 or x < 1 or x > 5 then
        return
    end
    local y = math.ceil(in_scrollview_pos_y/INTERVAL_Y)
    local now_pos_index = (y - 1) * 5 + x

    if now_pos_index == self.select_mercenary_index then
        self.choose_sub_panel:Clear(true)
        if self.change_index > 0 and self.change_index ~= now_pos_index then
            self:ChangeBeforePos()
        end
        self.change_index = now_pos_index
        return
    end

    if self.change_index ~= now_pos_index then
        if self.cur_mercenary_num < now_pos_index then
            if self.change_index > 0 and self.change_index ~= self.select_mercenary_index then
                self:ChangeBeforePos()
            else
                self.choose_sub_panel:Clear(true)
            end
            self.change_index = self.select_mercenary_index
            return
        end
        if self.change_index > 0 and self.change_index ~= now_pos_index then
            self:ChangeBeforePos()
        end
        self.change_index = now_pos_index
        self:ChangeMercenaryPos()
    end

end

--和当前移动的位置交换
function vanity_adventure_list_panel:ChangeMercenaryPos()
    local now_move_sub_panel  = self.mercenary_sub_panels[self.change_index]
    self.mercenary_sub_panels[self.select_mercenary_index]:Load(now_move_sub_panel.mercenary)
    now_move_sub_panel:Clear(true)
end

--撤销和当前的交换
function vanity_adventure_list_panel:ChangeBeforePos()
    local now_move_sub_panel  = self.mercenary_sub_panels[self.select_mercenary_index]
    self.mercenary_sub_panels[self.change_index]:Load(now_move_sub_panel.mercenary)
    now_move_sub_panel:Clear(true)
end

--加载阵容信息
function vanity_adventure_list_panel:LoadFormation()
    local list = {}
    --循环遍历得到当前阵容结构
    for k,instance_id in pairs(troop_logic.vanity_troop) do
        for k1,mercenary_info in pairs(troop_logic.vanity_mercenarys_list) do
            if mercenary_info.instance_id == instance_id then
                table.insert(list, troop_logic:InitMercenaryInfoByConfig(mercenary_info))
                break
            end
        end
    end
    
    self.max_formation_capacity = #troop_logic.vanity_troop
    self.formation_capacity = self.max_formation_capacity

    --创建所需要的英雄面板节点
    self:CreateMercenarySubPanels()
    
    --重置英雄面板
    self:ResetMercenarySubPanelPos()

    self.cur_mercenary_num = 0 

    self.mercenary_list = list

    --将当前阵容显示出来
    for k,mercenary in pairs(list) do
        self.cur_mercenary_num = k
        self.mercenary_sub_panels[k]:Load(mercenary)
    end

    --根据当前状态是否要抖动
    self:ShakingMercenarySubPanels(self.shaking)

    --置空空位子，
    for i = self.cur_mercenary_num +1,self.max_formation_capacity do
        self.mercenary_sub_panels[i]:Clear(true)
    end

    --初始化选择一个英雄
    if #list >= 1 then 
        self.no_mercenary = false
        self:ChooseMercenary()
    else
        self.no_mercenary = true

        local arrange_isvisible = self.arrange_node:isVisible()

        if arrange_isvisible then
            self.choose_img:setVisible(false)
            self.arrange_node:setVisible(false)
            self.arrange_text:setString(lang_constants:Get("mercenary_adjust_formation"))
            self:AdjustLineup(false)
        end
        
        self:ShowMySkillDesc()
        self.cur_mercenary_pos = 0
    end

    --显示boss技能
    self:ShowBossSkillDesc()
end

--boss技能
function vanity_adventure_list_panel:ShowBossSkillDesc()
    local week = utils:getWDay(time_logic:Now())
    local vanity_maze_conf = config_manager.vanity_maze_config[week]
    self.maze_conf = nil
    for k,v in pairs(vanity_maze_conf) do
        if v.map_id == self.select_maze_id then
            self.maze_conf = v
            break
        end
    end

    if self.maze_conf then
        --设置title
        self.title_text:setString(self.maze_conf.name)

        --得到怪物表格信息
        local monster_config = config_manager.monster_config[self.maze_conf.boss_id]
        if monster_config.skill then
            --有技能
            local num = 1
            local max_height = 0
            local skill_group = {}
            for skill_id in string.gmatch(monster_config.skill, "%d+") do
                skill_group[skill_id] = skill_group[skill_id] and skill_group[skill_id] + 1 or 1
            end
            local skill_str = ""
            for k, v in pairs(skill_group) do
                local skill_info = panel_util:GetSkillInfo(tonumber(k))
                if skill_info then
                    skill_str = skill_str .. skill_info.name.." : ".. skill_info.desc .. "\n"
                end
            end
            --设置技能
            self.boss_skill_desc:setString(skill_str)

            --扩大文本框及滑动框
            local len = self.boss_skill_desc:getVirtualRenderer():getStringLength()
            local max_text_length = 14
            if len >= max_text_length then
                local line_num = math.ceil(len / max_text_length)
                local real_height = line_num  * 24
                local max_height = self.boss_skill_scroll_view:getContentSize().height
                if real_height > max_height then
                    max_height = real_height
                    --设置滑动框的大小
                    self.boss_skill_scroll_view:setInnerContainerSize(cc.size(self.boss_skill_scroll_view:getContentSize().width, real_height))
                else
                    --设置滑动框的大小
                    self.boss_skill_scroll_view:setInnerContainerSize(cc.size(self.boss_skill_scroll_view:getContentSize().width, self.my_skill_scroll_view:getContentSize().height))
                end
                --设置文本位置
                self.boss_skill_desc:setPositionY(max_height)
                self.boss_skill_desc:setContentSize({width = TEXT_MAX_LENGTH, height = real_height })
            else
                self.boss_skill_scroll_view:setInnerContainerSize(cc.size(self.boss_skill_scroll_view:getContentSize().width, self.my_skill_scroll_view:getContentSize().height))
            end
        end
    end
end

--显示当前选择的英雄技能
function vanity_adventure_list_panel:ShowMySkillDesc(mercenary_id)
    if mercenary_id then
        --得到当前技能信息
        local skills_info = {{}, {}, {}, {}, {}}
        --解析技能
        panel_util:ParseSkillInfo(mercenary_id, skills_info)
        self.my_skill_name:setString(skills_info[1].name)
        self.my_skill_desc:setString(skills_info[1].desc)

        local len = self.my_skill_desc:getVirtualRenderer():getStringLength()
        local max_text_length = 14
        if len >= max_text_length then
            local line_num = math.ceil(len / max_text_length)
            local real_height = line_num  * 24
            local max_height = self.my_skill_scroll_view:getContentSize().height
            if real_height > max_height then
                max_height = real_height
                --设置滑动框的大小
                self.my_skill_scroll_view:setInnerContainerSize(cc.size(self.my_skill_scroll_view:getContentSize().width, real_height))
            else
                --设置滑动框的大小
                self.my_skill_scroll_view:setInnerContainerSize(cc.size(self.my_skill_scroll_view:getContentSize().width, self.my_skill_scroll_view:getContentSize().height))
            end
            --设置文本位置
            self.my_skill_desc:setPositionY(max_height)
            self.my_skill_desc:setContentSize({width = TEXT_MAX_LENGTH, height = real_height })
        else
            --设置滑动框的大小
            self.my_skill_scroll_view:setInnerContainerSize(cc.size(self.my_skill_scroll_view:getContentSize().width, self.my_skill_scroll_view:getContentSize().height))
        end
    else
        --没有技能
        self.my_skill_name:setString("")
        self.my_skill_desc:setString("")
    end
end

--创建sub_panel
function vanity_adventure_list_panel:CreateMercenarySubPanels()
    local math_random = math.random
    --创建当前最大需要展现的英雄面板
    for i = 1, self.max_formation_capacity do
        if self.mercenary_sub_panels[i] == nil then
            self.mercenary_sub_panels[i] = self:CreateOneMercenarySubPanel(i)

            self.sub_panel_pos_xs[i] = 0
            self.sub_panel_pos_ys[i] = 0

            --抖动动画
            local spine_node = spine_manager:GetNode("formation_shake")
            local animation = "shake" .. math_random(1, 4)
            self.scroll_view:addChild(spine_node, 300)
            self.shaking_spine_trackers[i] = shaking_spine_tracker.New(spine_node, "herolist_bg5", animation)
        end
    end

    --得到一个面板的大小
    local content = self.mercenary_sub_panels[1].root_node:getContentSize()
    self.sub_panel_height = content.height
    self.sub_panel_width = content.width
end

function vanity_adventure_list_panel:CreateMoveMercenaryPanel()
    local sub_panel = mercenary_template_panel.New()
    sub_panel:Init(self.mercenary_template:clone(), client_constants["MERCENARY_TEMPLATE_PANEL_SOURCE"]["vanity_adventure_list"])
    sub_panel.root_node:setAnchorPoint(0.5, 0.5)
    sub_panel.root_node:setLocalZOrder(1)
    sub_panel.root_node:setPosition(0, 0)
    sub_panel.root_node:setVisible(false)

    self.root_node:addChild(sub_panel.root_node)

    self.moving_sub_panel = sub_panel
    self.moving_sub_panel.root_node:setTouchEnabled(false)
end

--初始化滚动容器的ContainerSize or ContentSize 大小
function vanity_adventure_list_panel:IntiScrollViewSize(set_content_size)
    local num = self.formation_capacity
    if self.formation_capacity < constants.MAX_FORMATION_CAPACITY then
        num = num + 1
    end

    local begin_y = 1
    if num > MAX_SVIEW_SHOW_MERCEANRY_NUM then
        if set_content_size then
            self.scroll_view:setContentSize(cc.size(SCREEN_WIDTH, MAX_SCROLLVIEW_HEIGHT))
        else
            self.scroll_view:setInnerContainerSize(cc.size(SCREEN_WIDTH, MAX_SCROLLVIEW_HEIGHT))
            begin_y = MAX_SCROLLVIEW_HEIGHT - 20
        end
    else
        if set_content_size then
            
        else
            self.scroll_view:setInnerContainerSize(cc.size(SCREEN_WIDTH, MIN_SCROLLVIEW_HEIGHT))
            begin_y = MIN_SCROLLVIEW_HEIGHT - 20
        end
    end
    return begin_y
end

--重置mercenary_sub_panels的位置
function vanity_adventure_list_panel:ResetMercenarySubPanelPos()
    local begin_y = self:IntiScrollViewSize(false)
    local cur_sub_panels = self.mercenary_sub_panels

    for i = 1, self.max_formation_capacity do
        if cur_sub_panels[i] then
            local root_node = cur_sub_panels[i].root_node
            local row, col = self:CalcRowAndCol(i)
            local x = BEGIN_X + (col - 1) * INTERVAL_X
            local y = begin_y - (row - 1) * INTERVAL_Y - self.sub_panel_height / 2
            root_node:setPosition(x, y)
            root_node:setOpacity(255)

            --设置另外一个组的位置, 默认在屏幕的右侧
            self.sub_panel_pos_xs[i] = x
            self.sub_panel_pos_ys[i] = y
        end
    end
end

--计算行数和列数
function vanity_adventure_list_panel:CalcRowAndCol(index)
    local row = math.ceil(index / 5)
    local col = index - (row - 1) * 5
    return row, col
end

--选中动画
function vanity_adventure_list_panel:ChooseMercenaryAnimation()
    if self.cur_mercenary_pos > 0 and self.cur_mercenary_pos <= self.cur_mercenary_num then
        local x, y = self.sub_panel_pos_xs[self.cur_mercenary_pos], self.sub_panel_pos_ys[self.cur_mercenary_pos]
        local cur_ref_node = self.mercenary_sub_panels[self.cur_mercenary_pos].root_node
        cur_ref_node:setLocalZOrder(cur_ref_node:getLocalZOrder() + 1)
        self.cur_choose_spine_tracker:Bind("choose", x, y, cur_ref_node)
        local mercenary_id = troop_logic:GetVanityMercenarys(troop_logic.vanity_troop[self.cur_mercenary_pos]).template_id
        self:ShowMySkillDesc(mercenary_id)
    end
end

--取消选中动画
function vanity_adventure_list_panel:UnchosenMercenaryAnimation()
    if self.last_mercenary_pos and self.last_mercenary_pos ~= self.cur_mercenary_pos then
        local x, y = self.sub_panel_pos_xs[self.last_mercenary_pos], self.sub_panel_pos_ys[self.last_mercenary_pos]
        local last_ref_node = self.mercenary_sub_panels[self.last_mercenary_pos].root_node
        last_ref_node:setLocalZOrder(last_ref_node:getLocalZOrder() - 1)
        self.last_choose_spine_tracker:Bind("unchosen", x, y, last_ref_node)
    end
end

--重置选中动画
function vanity_adventure_list_panel:ResetChooseTracker()
    --进入拖动调正佣兵位置 要将 选中动画隐藏并且其scale置为1
    if self.mercenary_sub_panels[self.cur_mercenary_pos] then
        self.mercenary_sub_panels[self.cur_mercenary_pos].root_node:setScale(1, 1)
        self.cur_choose_spine_tracker.root_node:setVisible(false)
    end
end

--创建选择动画
function vanity_adventure_list_panel:CreateChooseSpineTracker()
    local cur_choose_spine_node = spine_manager:GetNode("choose_bg")
    cur_choose_spine_node:setAnchorPoint(0.5, 1)
    self.scroll_view:addChild(cur_choose_spine_node, 0)
    local choose_spine_tracker = choose_spine_tracker.New(cur_choose_spine_node, "herobg")
    choose_spine_tracker.root_node:setVisible(false)
    return choose_spine_tracker
end

--选中一个佣兵
function vanity_adventure_list_panel:ChooseMercenary()
    if self.arrange_node:isVisible() then
        --上一个处于选择状态的佣兵移除选择框
        if self.last_mercenary_pos and self.last_mercenary_pos ~= self.cur_mercenary_pos then
            self.shaking_spine_trackers[self.last_mercenary_pos]:RemoveSelectWidget()
        end

        --选择框跟随当前 选中的佣兵 抖起来  抖抖抖抖
        local x, y = self.sub_panel_pos_xs[self.cur_mercenary_pos], self.sub_panel_pos_ys[self.cur_mercenary_pos]
        self.shaking_spine_trackers[self.cur_mercenary_pos]:BindSelectWidget(self.choose_img, x, y)
        self.choose_img:setVisible(true)
    else
        --选中动画
        self:ChooseMercenaryAnimation()
        self:UnchosenMercenaryAnimation()
        self.choose_img:setVisible(false)
    end

    self.last_mercenary_pos = self.cur_mercenary_pos
end

function vanity_adventure_list_panel:Hide()
    --重置选中状态
    self:ResetChooseTracker()
    self.root_node:setVisible(false)
end

--进入调整状态
function vanity_adventure_list_panel:AdjustLineup(state)
    self:IntiScrollViewSize(true)
    if self.scroll_view_y == nil then
        self.scroll_view_y = self.scroll_view:getPositionY()
    end
    if state then
        self:UnchosenMercenaryAnimation()
        self:ResetChooseTracker()
        self.top_node:stopAllActions()
        self.top_node:runAction(cc.MoveTo:create(0.5,cc.p(0,MOVE_DIS)))
        self.scroll_view:stopAllActions()
        self.scroll_view:runAction(cc.MoveTo:create(0.5, cc.p(self.scroll_view:getPositionX(),self.scroll_view_y+MOVE_DIS)))
    else
        self.top_node:stopAllActions()
        self.top_node:runAction(cc.MoveTo:create(0.5,cc.p(0,0)))
        self.scroll_view:stopAllActions()
        self.scroll_view:runAction(cc.Sequence:create(cc.MoveTo:create(0.5, cc.p(self.scroll_view:getPositionX(),self.scroll_view_y)),cc.CallFunc:create(function ()
            self.scroll_view:setContentSize(cc.size(SCREEN_WIDTH, MIN_SCROLLVIEW_HEIGHT))
        end)))
    end
    
    self:ShakingMercenarySubPanels(state)
end

--抖动
function vanity_adventure_list_panel:ShakingMercenarySubPanels(state)
    local cur_sub_panels = self.mercenary_sub_panels

    for i = 1, self.max_formation_capacity do
        local tracker = self.shaking_spine_trackers[i]
        tracker.root_node:setVisible(state)

        local ref_node = cur_sub_panels[i].root_node
        if i <= self.cur_mercenary_num then
            if state then
                tracker:Bind(self.sub_panel_pos_xs[i], self.sub_panel_pos_ys[i], ref_node)
            else
                tracker:StopShaking()
            end
        end
    end
    self.shaking = state
end

function vanity_adventure_list_panel:RegisterWidgetEvent()

    self.view_mercenary = function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            self.scrolling = false

            local pos = widget:getTag()

            self.choose_sub_panel = self.mercenary_sub_panels[pos]

            self.cur_mercenary_id = self.choose_sub_panel.mercenary_id
            self.moving_sub_panel_flag = false
            self.ismoved = false

            if self.cur_mercenary_id ~= 0 then
                if self.arrange_node:isVisible() then
                    self.select_mercenary_index = pos
                    self.change_index = pos 
                    self.drag_duration = 0
                    self.start_drag_sub_panel = true
                else
                    self.show_detail_panel = true
                    self.detail_duration = 0
                end
            end

        elseif event_type == ccui.TouchEventType.moved then
            local move_location = widget:getTouchMovePosition()
           --开始拖动
            if self.moving_sub_panel_flag then
                self.ismoved = true
                self:StartDragMercenarySubPanel(move_location)
            end
        elseif event_type == ccui.TouchEventType.ended then

            if self.moving_sub_panel_flag and self.ismoved then
                self.moving_sub_panel_flag = false
                self.moving_sub_panel.root_node:setVisible(false)
                self.choose_sub_panel:Load(self.moving_sub_panel.mercenary)
            end

            local pos = widget:getTag()
            if not self.scrolling then
                if self.cur_mercenary_pos ~= pos then
                    if self.cur_mercenary_num >= pos then
                        self.cur_mercenary_pos = pos
                        self:ChooseMercenary()
                    else
                        --上阵
                        graphic:DispatchEvent("show_world_sub_scene", "mercenary_vanity_choose_sub_scene")
                    end
                end
            end
            
        elseif event_type == ccui.TouchEventType.canceled then
            if self.moving_sub_panel_flag and self.ismoved then
                self.moving_sub_panel_flag = false
                self.moving_sub_panel.root_node:setVisible(false)
                if self.change_index ~= self.select_mercenary_index then
                    self.cur_mercenary_pos = self.change_index
                    self.mercenary_sub_panels[self.change_index]:Load(self.moving_sub_panel.mercenary)
                    troop_logic:ChangePosition(self.change_index, self.select_mercenary_index)
                else
                    local pos = widget:getTag()
                    self.cur_mercenary_pos = pos
                    self.choose_sub_panel:Load(self.moving_sub_panel.mercenary)
                end
                self:ChooseMercenary()
            end
        end
    end

    --滚动容器事件
    self.scroll_view:addEventListener(function(lview, event_type)
        if event_type == ccui.ScrollViewEventType.scrolling then
            self.scrolling = true
        end
    end)

    --手动调整
    self.arrange_mercenary_pos_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if self.no_mercenary then
                return 
            end

            local arrange_isvisible = self.arrange_node:isVisible()

            self.arrange_node:setVisible(not arrange_isvisible)
            if not arrange_isvisible then
                self.arrange_text:setString(lang_constants:Get("confirm"))
                self:AdjustLineup(true)
            else
                self.arrange_text:setString(lang_constants:Get("mercenary_adjust_formation"))
                self:AdjustLineup(false)
            end
            self:ChooseMercenary()
       end
    end)

    --下阵
    self.rest_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            troop_logic:RestToBattle(troop_logic.vanity_troop[self.cur_mercenary_pos], self.cur_mercenary_pos)
        end
    end)

    --替换
    self.replace_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            --替换
            graphic:DispatchEvent("show_world_sub_scene", "mercenary_vanity_choose_sub_scene", nil, self.cur_mercenary_pos)
        end
    end)

    --返回
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
            --打开虚空界面
            graphic:DispatchEvent("show_world_sub_scene", "vanity_main_sub_scene")    
            graphic:DispatchEvent("show_world_sub_panel", "vanity_adventure_stagestart")
        end
    end)
end

function vanity_adventure_list_panel:RegisterEvent()

    graphic:RegisterEvent("update_vainty_formation_success", function(update_type, index)
        --上阵成功
        if not self.root_node:isVisible() then
            return
        end
        if index then
            self.cur_mercenary_pos = index
        end
        self:LoadFormation()
        self:UpdateProperty()
        troop_logic:CalcVanityTroopBP(true)
    end)

    
end

return vanity_adventure_list_panel
