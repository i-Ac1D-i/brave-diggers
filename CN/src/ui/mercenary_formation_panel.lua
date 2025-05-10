local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local config_manager = require "logic.config_manager"
local mine_logic = require "logic.mine"
local destiny_logic = require "logic.destiny_weapon"

local adventure_maze_config = config_manager.adventure_maze_config
local destiny_skill_config = config_manager.destiny_skill_config
local cooperative_skill_config = config_manager.cooperative_skill_config

local panel_prototype = require "ui.panel"
local ui_role_prototype = require "entity.ui_role"
local panel_util = require "ui.panel_util"
local mercenary_template_panel = require "ui.mercenary_template_panel"
local mercenary_preview_sub_panel = require "ui.mercenary_preview_panel"

local lang_constants = require "util.language_constants"
local client_constants = require "util.client_constants"
local spine_manager = require "util.spine_manager"
local skill_manager = require "logic.skill_manager"

local CHOOSE_SHOW_MODE = client_constants["MERCENARY_CHOOSE_SHOW_MODE"]["formation"]
local MAX_FORMATION_CAPACITY = constants["MAX_FORMATION_CAPACITY"]

local MAX_FORMATION_NUM = constants["MAX_FORMATION_NUM"]

local ACTIVE_SKILL_EFFECT_TYPE = constants["ACTIVE_SKILL_EFFECT_TYPE"]

local PLIST_TYPE = ccui.TextureResType.plistType
local MAX_SCROLLVIEW_HEIGHT = 670
local MIN_SCROLLVIEW_HEIGHT = 556

local SCREEN_WIDTH = 640
local TRANSITION_TIME = 0.3
local FORMATION_TRANSITION_TIME = 0.5
local ARRANGE_TRANSITION_TIME = 0.5


local SCROLL_VIEW_CHANGE_POS_Y = 270
local MAX_SVIEW_SHOW_MERCEANRY_NUM = 20 --sview里最多能看到的佣兵个数
local LINEUP_MOVE_Y_DISTANCE = 536

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

--------------------------------------
---------------阵容-------------------
--------------------------------------
local mercenary_formation_panel = panel_prototype.New()
function mercenary_formation_panel:Init()

    self.root_node = cc.CSLoader:createNode("ui/mercenary_formation_panel.csb")

    self.scroll_view = self.root_node:getChildByName("scroll_view")
    self.mercenary_template = self.scroll_view:getChildByName("mercenary_template")
    self.mercenary_template:setVisible(false)
    self.choose_img = self.scroll_view:getChildByName("choose")
    self.choose_img:setAnchorPoint(0.5, 0.5)
    self.choose_img:setLocalZOrder(100)

    --佣兵信息预览框
    self.preview_sub_panel = mercenary_preview_sub_panel.New(self.root_node:getChildByName("preview"))
    self.preview_sub_panel:Init(client_constants["MERCENARY_PREVIEW_SHOW_MOD"]["formation"])
    self.preview_sub_panel_init_pos_y = self.preview_sub_panel.root_node:getPositionY()

    self.top_bg_img = self.root_node:getChildByName("top_bg")
    self.border_bg_img = self.root_node:getChildByName("border_top")
    self.border_bg_img_init_y = self.border_bg_img:getPositionY()

    --lineup监听遮挡板
    self.lineup_swallow_touch_img = self.root_node:getChildByName("click_shadow")
    --阵容增加的属性
    self.lineup_bg = self.root_node:getChildByName("lineup")
    local crit_progress_node = self.lineup_bg:getChildByName("crit_progress_bar")
    self.crit_percent_text = crit_progress_node:getChildByName("percent_value")
    self.crit_percent_progress = crit_progress_node:getChildByName("percent_bar")
    self.crit_desc_text = crit_progress_node:getChildByName("property_desc_b")
    local pure_progress_node = self.lineup_bg:getChildByName("pure_progress_bar")
    self.pure_percent_text = pure_progress_node:getChildByName("percent_value")
    self.pure_percent_progress = pure_progress_node:getChildByName("percent_bar")
    local recovery_progress_node = self.lineup_bg:getChildByName("recovery_progress_bar")
    self.recovery_percent_text = recovery_progress_node:getChildByName("percent_value")
    self.recovery_percent_progress = recovery_progress_node:getChildByName("percent_bar")
    self.recovery_desc_text = recovery_progress_node:getChildByName("property_desc_b")
    local stateless_progress_node = self.lineup_bg:getChildByName("stateless_progress_bar")
    self.stateless_percent_text = stateless_progress_node:getChildByName("percent_value")
    self.stateless_percent_progress = stateless_progress_node:getChildByName("percent_bar")
    self.skill_percent_img = self.lineup_bg:getChildByName("skill_percent")
    self.skill_percent_progress = self.skill_percent_img:getChildByName("percent_bar")
    self.skill_percent_text = self.skill_percent_img:getChildByName("percent_value")
    self.skill_percent_img:setTouchEnabled(true)
    local property_node = self.lineup_bg:getChildByName("property")
    self.speed_text = property_node:getChildByName("speed"):getChildByName("value")
    self.defense_text = property_node:getChildByName("defense"):getChildByName("value")
    self.dodge_text = property_node:getChildByName("dodge"):getChildByName("value")
    self.authority_text = property_node:getChildByName("authority"):getChildByName("value")
    self.property_bg_img = property_node:getChildByName("bg3")
    self.skill_percent_content = self.lineup_bg:getChildByName("lineup_text")
    self.skill_details_button = self.lineup_bg:getChildByName("button_details")
    self.property_bg_img:setTouchEnabled(false)
    --阵容调整界面
    self.arrange_node = self.root_node:getChildByName("arrange_node")
    self.arrange_node:setVisible(false)
    self.arrange_mercenary_pos_btn = self.root_node:getChildByName("arrange_mercenary_pos_btn")
    self.arrange_text = self.root_node:getChildByName(("arrange_text"))

    self.replace_btn =  self.arrange_node:getChildByName("replace_btn")
    self.rest_btn =  self.arrange_node:getChildByName("rest_btn")
    self.change_name_btn = self.arrange_node:getChildByName("change_name_btn")

    --多阵容
    self.multi_formation_node = self.root_node:getChildByName("formations")
    self.formation_arrow1_img = self.multi_formation_node:getChildByName("arrow1")
    self.formation_arrow2_img = self.multi_formation_node:getChildByName("arrow2")
    self.location_bg1_img = self.multi_formation_node:getChildByName("location_bg1")
    self.location_bg2_img = self.multi_formation_node:getChildByName("location_bg2")
    self.formation_arrow1_x = self.formation_arrow1_img:getPositionX()
    self.formation_arrow2_x = self.formation_arrow2_img:getPositionX()
    self.formation_imgs = {}
    for i = 1, MAX_FORMATION_NUM do
        self.formation_imgs[i] = self.multi_formation_node:getChildByName("formation" .. i)
    end

    self.formation_tip_img = self.multi_formation_node:getChildByName("formation_tip")
    self.formation_tip_text = self.formation_tip_img:getChildByName("desc")

    --选择佣兵动画
    self.cur_choose_spine_tracker = self:CreateChooseSpineTracker()
    self.last_choose_spine_tracker = self:CreateChooseSpineTracker()

    self.back_btn = self.root_node:getChildByName("back_btn")

    self.root_node:getChildByName("arrange_pvp_btn"):setVisible(false)

    --推荐上阵
    self.recommend_formation_button = self.root_node:getChildByName("arrange_mercenary_pos_btn_0")

    --事件
    self.origin_event_dispatcher = cc.Director:getInstance():getEventDispatcher()
    self.scroll_view_pos_y = self.scroll_view:getPositionY()

    --阵容的临时表，值为佣兵的instance_id, 用于操作调整阵型
    self.temp_formations = {}
    for i = 1, #constants["ALL_FORMATIONS"] do --MAX_FORMATION_NUM
        local index = constants["ALL_FORMATIONS"][i]
        self.temp_formations[index] = {}
    end

    self.cur_mercenary_pos = 1
    self.last_mercenary_pos = 1
    self.find_pos = 1
    self.last_find_pos = 1

    self.cur_mercenary_id = 0
    --两套sub_panel, 用于切换
    self.mercenary_sub_panels = {{}, {}}
    self.sub_panel_pos_xs = {}
    self.sub_panel_pos_ys = {}

    --当前界面使用的哪一组sub_panel
    self.cur_group_index = 1
    self.cur_mercenary_sub_panels = self.mercenary_sub_panels[1]
    self.another_mercenary_sub_panels = self.mercenary_sub_panels[2]

    self.shaking_spine_trackers = {}

    self.lineup_move_flag = false
    self.skill_datas = { skill_percent = 0,
                         critical_percent = 0,
                         true_percent = 0,
                         increase_percent = 0,
                         other_percent = 0 ,
                         critical_effect = 0,
                         increase_effect = 0,}
    self:RegisterEvent()
    self:RegisterWidgetEvent()

    self:CreateMercenarySubPanels()
end

--创建选择动画
function mercenary_formation_panel:CreateChooseSpineTracker()
    local cur_choose_spine_node = spine_manager:GetNode("choose_bg")
    cur_choose_spine_node:setAnchorPoint(0.5, 1)
    self.scroll_view:addChild(cur_choose_spine_node, 0)
    local choose_spine_tracker = choose_spine_tracker.New(cur_choose_spine_node, "herobg")
    choose_spine_tracker.root_node:setVisible(false)
    return choose_spine_tracker
end

--创建一个sub_panel
function mercenary_formation_panel:CreateOneMercenarySubPanel(tag)
    local sub_panel = mercenary_template_panel.New()
    sub_panel:Init(self.mercenary_template:clone(), client_constants["MERCENARY_TEMPLATE_PANEL_SOURCE"]["formation"])
    sub_panel.root_node:setAnchorPoint(0.5, 0.5)
    sub_panel.root_node:setLocalZOrder(1)
    sub_panel.root_node:setTouchEnabled(true)
    sub_panel.root_node:addTouchEventListener(self.view_mercenary)
    sub_panel.root_node:setPosition(0, 0)
    sub_panel.root_node:setTag(tag)

    self.scroll_view:addChild(sub_panel.root_node)

    return sub_panel
end

--创建sub_panel
function mercenary_formation_panel:CreateMercenarySubPanels()
    local math_random = math.random
    for i = 1, MAX_FORMATION_CAPACITY do

        self.mercenary_sub_panels[1][i] = self:CreateOneMercenarySubPanel(i)
        self.mercenary_sub_panels[2][i] = self:CreateOneMercenarySubPanel(i)

        self.sub_panel_pos_xs[i] = 0
        self.sub_panel_pos_ys[i] = 0

        --抖动动画
        local spine_node = spine_manager:GetNode("formation_shake")
        local animation = "shake" .. math_random(1, 4)
        self.scroll_view:addChild(spine_node, 300)
        self.shaking_spine_trackers[i] = shaking_spine_tracker.New(spine_node, "herolist_bg5", animation)
    end

    local content = self.mercenary_sub_panels[1][1].root_node:getContentSize()
    self.sub_panel_height = content.height
    self.sub_panel_width = content.width

    --调整佣兵位置的地方 移动的佣兵sub_panel
    self.moving_sub_panel = mercenary_template_panel.New()
    self.moving_sub_panel:Init(self.mercenary_template:clone(), client_constants["MERCENARY_TEMPLATE_PANEL_SOURCE"]["formation"])
    self.root_node:addChild(self.moving_sub_panel.root_node)
    self.moving_sub_panel.root_node:setAnchorPoint(0.5, 0.5)
    self.moving_sub_panel.root_node:setScale(1.2, 1.2)
end

--设定阵容的tip_img的透明度
function mercenary_formation_panel:SetMultiFormationImgsOpacity()
    for i = 1, MAX_FORMATION_NUM do
        if i == self.formation_id then
           self.formation_imgs[i]:setOpacity(255)
        else
           self.formation_imgs[i]:setOpacity(255 * 0.3)
        end
    end
end

--初始化滚动容器的ContainerSize or ContentSize 大小
function mercenary_formation_panel:IntiScrollViewSize(set_content_size)
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
            self.scroll_view:setContentSize(cc.size(SCREEN_WIDTH, MIN_SCROLLVIEW_HEIGHT))
        else
            self.scroll_view:setInnerContainerSize(cc.size(SCREEN_WIDTH, MIN_SCROLLVIEW_HEIGHT))
            begin_y = MIN_SCROLLVIEW_HEIGHT - 20
        end
    end
    return begin_y
end

--阵容属性
function mercenary_formation_panel:UpdateTroopProperty(formation_id)
    formation_id = formation_id or self.formation_id
    local speed, authority, dodge, defense = troop_logic:GetTroopProperty(formation_id)
    self.skill_datas.critical_effect = speed * 0.5
    self.skill_datas.increase_effect = dodge * 0.5

    self.speed_text:setString(tostring(speed))
    self.crit_desc_text:setString(string.format(lang_constants:Get("mercenary_recommend_critcal_text"), self.skill_datas.critical_effect))
    self.authority_text:setString(tostring(authority))
    self.dodge_text:setString(tostring(dodge))
    self.recovery_desc_text:setString(string.format(lang_constants:Get("mercenary_recommend_recovery_text"), self.skill_datas.increase_effect))
    self.defense_text:setString(tostring(defense))

    self:UpdateSkillCoverPercent(formation_id)
end

--技能覆盖率刷新
function mercenary_formation_panel:UpdateSkillCoverPercent(formation_id)
    formation_id = formation_id or self.formation_id
    --首回合是否能释放检测

    local function _GetProgressColor(percent)
        local progress_bg_color
        if percent >= 80 then
           progress_bg_color = panel_util:GetColor4B(0xC1FA1A)
        elseif percent >= 40 and percent < 80 then
            progress_bg_color = panel_util:GetColor4B(0xF5D31F)
        else
            progress_bg_color = panel_util:GetColor4B(0xEB4D19)
        end

        return progress_bg_color
    end

    local all_skills = {}
    local cooperative_skills = {}
    local priority_index = 1

    local formation = troop_logic.formations[formation_id]

    for i = 1, #formation do
        local mercenary = formation[i]
        local mercenary_template_info = mercenary.template_info

        if mercenary.is_leader then
            local weapon_id = troop_logic:GetFormationWeaponId(formation_id)
            if weapon_id ~= 0 then
                local leader_skill = destiny_logic:GetCurWeaponSkillId(weapon_id)
                if skill_manager:IsCanUseSkill(leader_skill, 1, 100) then
                    table.insert(all_skills, leader_skill)
                end
            end
        else
            for j = 1, 3 do
                local skill_id = mercenary_template_info["skill" .. j]
                if skill_manager:IsCanUseSkill(skill_id, 1, 100) then
                    table.insert(all_skills, skill_id)
                end
            end

            for j = 1, 2 do
                local skill_id = mercenary_template_info["ex_skill" .. j]
                if  not cooperative_skills[skill_id] and skill_manager:IsCanUseSkill(skill_id, 1, 100) and skill_manager:CheckCoopSkillCanUse(troop_logic, skill_id) then
                    table.insert(all_skills, priority_index, skill_id)
                    cooperative_skills[skill_id] = true
                    priority_index = priority_index + 1
                end
            end
        end
    end

    local skill_percent, increase_percent, critical_percent, true_percent, other_percent = 0, 0, 0, 0, 0
    local math_min = math.min

    for _, v in ipairs(all_skills) do
        local skill_info = skill_manager:GetSkill(v)
        skill_percent = skill_percent + skill_info.trigger_chance

        if ACTIVE_SKILL_EFFECT_TYPE["critical_damage"] == skill_info.effect_type then
            critical_percent = critical_percent + skill_info.trigger_chance

        elseif ACTIVE_SKILL_EFFECT_TYPE["true_damage"] == skill_info.effect_type then
            true_percent = true_percent + skill_info.trigger_chance

        elseif ACTIVE_SKILL_EFFECT_TYPE["increase_by_self_bp"] == skill_info.effect_type or
                ACTIVE_SKILL_EFFECT_TYPE["increase_by_self_init_bp"] == skill_info.effect_type or
                ACTIVE_SKILL_EFFECT_TYPE["increase_by_enemy_bp"] == skill_info.effect_type or
                ACTIVE_SKILL_EFFECT_TYPE["increase_by_enemy_init_bp"] == skill_info.effect_type then
            increase_percent = increase_percent + skill_info.trigger_chance

        else
            other_percent = other_percent + skill_info.trigger_chance
        end

        if skill_percent >= 100 then
           break
        end
    end

    skill_percent = math_min(skill_percent, 100)
    increase_percent = math_min(increase_percent, 100)
    critical_percent = math_min(critical_percent, 100)
    true_percent = math_min(true_percent, 100)
    other_percent = math_min(other_percent, 100)

    self.skill_datas.skill_percent = skill_percent
    self.skill_datas.increase_percent = increase_percent
    self.skill_datas.critical_percent = critical_percent
    self.skill_datas.true_percent = true_percent
    self.skill_datas.other_percent = other_percent

    self.skill_percent_progress:setColor(_GetProgressColor(skill_percent))
    -- self.crit_percent_progress:setColor(_GetProgressColor(critical_percent))
    -- self.pure_percent_progress:setColor(_GetProgressColor(true_percent))
    -- self.recovery_percent_progress:setColor(_GetProgressColor(increase_percent))

    self.skill_percent_progress:setPercent(skill_percent)
    self.crit_percent_progress:setPercent(critical_percent)
    self.pure_percent_progress:setPercent(true_percent)
    self.recovery_percent_progress:setPercent(increase_percent)
    self.stateless_percent_progress:setPercent(other_percent)


    self.skill_percent_content:setString(string.format(lang_constants:Get("mercenary_skill_percent_text"), skill_percent))
    self.skill_percent_text:setString(string.format(lang_constants:Get("skill_percent"), skill_percent))
    self.crit_percent_text:setString(string.format(lang_constants:Get("skill_percent"), critical_percent))

    self.pure_percent_text:setString(string.format(lang_constants:Get("skill_percent"), true_percent))

    self.recovery_percent_text:setString(string.format(lang_constants:Get("skill_percent"), increase_percent))

    self.stateless_percent_text:setString(string.format(lang_constants:Get("skill_percent"), other_percent))
end

--计算行数和列数
function mercenary_formation_panel:CalcRowAndCol(index)
    local row = math.ceil(index / 5)
    local col = index - (row - 1) * 5
    return row, col
end

--重置选中动画
function mercenary_formation_panel:ResetChooseTracker()
    --进入拖动调正佣兵位置 要将 选中动画隐藏并且其scale置为1

    local cur_sub_panels = self.mercenary_sub_panels[self.cur_group_index]
    cur_sub_panels[self.cur_mercenary_pos].root_node:setScale(1, 1)
    cur_sub_panels[self.last_mercenary_pos].root_node:setScale(1, 1)

    self.cur_choose_spine_tracker.root_node:setVisible(false)
    self.last_choose_spine_tracker.root_node:setVisible(false)
end

--进入编辑阵容界面时的动态
function mercenary_formation_panel:UpdateArrangePos(elapsed_time)
    if self.change_arrange_node then

        self.change_arrange_transition_time = self.change_arrange_transition_time + elapsed_time
        if self.change_arrange_transition_time < ARRANGE_TRANSITION_TIME then
            local percent = 1.01 * math.exp(- ( 1.2 * (self.change_arrange_transition_time / ARRANGE_TRANSITION_TIME) - 1.5) ^ 4)
            percent = math.min(percent, 1)
            local change_pos = 118 * percent

            self.preview_sub_panel:SetSkillNodePosY(self.preview_sub_panel:GetSkillNodePosY() + change_pos)
            self.border_bg_img:setPositionY(self.border_bg_img_init_y + change_pos)
            self.scroll_view:setPositionY(self.scroll_view_pos_y + change_pos)

            local opacity = 255 * percent
            self.rest_btn:setOpacity(opacity)
            self.replace_btn:setOpacity(opacity)
            self.change_name_btn:setOpacity(opacity)
        else
            self.change_arrange_node = false
            self.arrange_text:setString(lang_constants:Get("confirm"))
        end

    end
end

--设定调整区域的状态
function mercenary_formation_panel:SetArrangeNodeStatus()

    local arrange_isvisible = self.arrange_node:isVisible()
    self.top_bg_img:setVisible(not arrange_isvisible)
    self.preview_sub_panel:SetCanShowFloatPanel(arrange_isvisible)
    local enabled_flag = true
    if self.mode == client_constants["FORMATION_PANEL_MODE"]["guild"] or self.mode == client_constants["FORMATION_PANEL_MODE"]["server_pvp"] or self.mode == client_constants["FORMATION_PANEL_MODE"]["mine"] then
        enabled_flag = false
        self.change_name_btn:setVisible(false)
    else
        self.change_name_btn:setVisible(true)
    end
    
    self.touch_listener:setEnabled(not arrange_isvisible and enabled_flag)
    self.multi_formation_node:setVisible(not arrange_isvisible)
    
    self.choose_img:setVisible(arrange_isvisible)

    if arrange_isvisible then

        self.change_name_btn:setOpacity(0)
        self.rest_btn:setOpacity(0)

        self.change_arrange_transition_time = 0
        self.change_arrange_node = true

        self.formation_tip_flag = false
        self.formation_tip_img:setOpacity(0)
        self.replace_btn:setOpacity(0)

        self:ResetChooseTracker()

        --在调整阵容界面
        self:IntiScrollViewSize(true)

    else
        self.preview_sub_panel:SetSkillNodePosY()
        self.border_bg_img:setPositionY(self.border_bg_img_init_y)

        self.scroll_view:setPositionY(self.scroll_view_pos_y)
        self.scroll_view:setContentSize(cc.size(SCREEN_WIDTH, MIN_SCROLLVIEW_HEIGHT))
        self.arrange_text:setString(lang_constants:Get("mercenary_adjust_formation"))
    end

    self:ShakingMercenarySubPanels()
end

--按钮是否可以点击
function mercenary_formation_panel:SetBtnsTouchEnabled(can_touch)
    self.back_btn:setTouchEnabled(can_touch)
    self.recommend_formation_button:setTouchEnabled(can_touch)
    self.rest_btn:setTouchEnabled(can_touch)
    self.change_name_btn:setTouchEnabled(can_touch)
    self.replace_btn:setTouchEnabled(can_touch)
    self.arrange_mercenary_pos_btn:setTouchEnabled(can_touch)
end

--取消选中动画
function mercenary_formation_panel:UnchosenMercenaryAnimation()
    if self.last_mercenary_pos ~= self.cur_mercenary_pos then
        local x, y = self.sub_panel_pos_xs[self.last_mercenary_pos], self.sub_panel_pos_ys[self.last_mercenary_pos]
        local last_ref_node = self.mercenary_sub_panels[self.cur_group_index][self.last_mercenary_pos].root_node
        last_ref_node:setLocalZOrder(last_ref_node:getLocalZOrder() - 1)
        self.last_choose_spine_tracker:Bind("unchosen", x, y, last_ref_node)
    end
end

--选中动画
function mercenary_formation_panel:ChooseMercenaryAnimation()
    if self.cur_mercenary_pos <= self.cur_mercenary_num then
        local x, y = self.sub_panel_pos_xs[self.cur_mercenary_pos], self.sub_panel_pos_ys[self.cur_mercenary_pos]
        local cur_ref_node = self.mercenary_sub_panels[self.cur_group_index][self.cur_mercenary_pos].root_node
        cur_ref_node:setLocalZOrder(cur_ref_node:getLocalZOrder() + 1)
        self.cur_choose_spine_tracker:Bind("choose", x, y, cur_ref_node)
    end
end

function mercenary_formation_panel:ShowEx()
    if not self.arrange_node:isVisible() then
        self.cur_mercenary_pos = self.last_mercenary_pos
        self.cur_mercenary_id = self.mercenary_sub_panels[self.cur_group_index][self.cur_mercenary_pos].mercenary_id
        self.preview_sub_panel:Show(self.cur_mercenary_id, self.formation_id)

        self:ChooseMercenaryAnimation()

        if self.mode ~= client_constants["FORMATION_PANEL_MODE"]["guild"] and self.mode ~= client_constants["FORMATION_PANEL_MODE"]["server_pvp"] and self.mode ~= client_constants["FORMATION_PANEL_MODE"]["mine"]then
            self.touch_listener:setEnabled(true)
        end
    end

    self.root_node:setVisible(true)
end

function mercenary_formation_panel:Show(mode)
    self.mode = mode

    self.formation_name_list = troop_logic:GetFormationNameList()

    self.arrange_node:setVisible(false)

    self.is_draging_one = false

    --阵容箭头抖动
    self.formation_arrow_duration = 0
    --面板组id
    self.cur_group_index = 1
    --佣兵详情
    self.enter_detail_panel_duration, self.enter_detail_panel_flag = 0, false
    --切换阵容 动画时间
    self.formation_transition_duration, self.formation_transition_flag = 0, false
    self.formation_tip_duration, self.formation_tip_flag = 0, true
    self.formation_tip_img:setOpacity(255)

    --切换阵容检测时间 和 开始切换阵容flag
    self.change_formation_check_time, self.start_change_formation = 0, false

    self.formation_capacity = troop_logic:GetFormationCapacity()

    if self.mode == client_constants["FORMATION_PANEL_MODE"]["multi"] then
        self.multi_formation_node:setVisible(true)
        self.touch_listener:setEnabled(true)
        self:SetSingleFormationView(false)
        self.formation_id = troop_logic:GetCurFormationId()
        self:SetMultiFormationImgsOpacity()

    elseif self.mode == client_constants["FORMATION_PANEL_MODE"]["guild"] then
        self.multi_formation_node:setVisible(false)
        self.touch_listener:setEnabled(false)
        self:SetSingleFormationView(true)
        self.formation_id = constants["GUILD_WAR_TROOP_ID"]
    elseif self.mode == client_constants["FORMATION_PANEL_MODE"]["server_pvp"] then
        self.multi_formation_node:setVisible(false)
        self.touch_listener:setEnabled(false)
        self:SetSingleFormationView(true)
        self.formation_id = constants["KF_PVP_TROOP_ID"]
    elseif self.mode == client_constants["FORMATION_PANEL_MODE"]["mine"] then
        self.multi_formation_node:setVisible(false)
        self.touch_listener:setEnabled(false)
        self:SetSingleFormationView(true)
        self.formation_id = constants["MINE_TROOP_ID"][mine_logic:GetCurSelectMineIndex()]
    end

    troop_logic:SetClientFormationId(self.formation_id)

    self:LoadFormationInfo()
    self:SetArrangeNodeStatus()
    self:ResetMercenarySubPanelPos()
    self:ChooseMercenary()

    self.preview_sub_panel:SetCanShowFloatPanel(false)
    self.root_node:setVisible(true)
end

function mercenary_formation_panel:SetSingleFormationView(flag) 
    self.formation_arrow1_img:setVisible(not flag)
    self.formation_arrow2_img:setVisible(not flag)
    self.location_bg1_img:setVisible(not flag)
    self.location_bg2_img:setVisible(not flag)
    for i = 1, MAX_FORMATION_NUM do
        self.formation_imgs[i]:setVisible(not flag)
    end
end

--加载整个阵容中的信息
function mercenary_formation_panel:LoadFormationInfo(formation_id, group_index)
    formation_id = formation_id or self.formation_id
    group_index = group_index or self.cur_group_index

    self:LoadMercenaryInfo(false, formation_id, group_index)

    for i = (self.cur_mercenary_num + 1), constants["MAX_FORMATION_CAPACITY"] do
        local sub_panel = self.mercenary_sub_panels[group_index][i]
        sub_panel.root_node:setVisible(true)
        sub_panel.root_node:setScale(1, 1)

        if i <= self.formation_capacity then
            sub_panel:Clear(true)

        elseif i == (self.formation_capacity + 1) then
            --下一个可以解锁的位置
            local maze_id = client_constants["UNLOCAK_FOTMATION_CAPACITY_MAZE"][self.formation_capacity]
            local next_unlock_pos = adventure_maze_config[maze_id]["name"]
            sub_panel:UnLockPosition(true, next_unlock_pos)
        else
            sub_panel:Clear(false)
            sub_panel.root_node:setVisible(false)
        end
    end

    self.cur_mercenary_pos, self.last_mercenary_pos, self.find_pos =  1, 1, 1
    self.cur_mercenary_id = self.mercenary_sub_panels[group_index][self.cur_mercenary_pos].mercenary_id
    self.preview_sub_panel:Show(self.cur_mercenary_id, formation_id)

    self.formation_tip_text:setString(troop_logic:GetFormationName(formation_id))

    self:UpdateTroopProperty(formation_id)
end

--加载阵容中已经有的佣兵的信息
function mercenary_formation_panel:LoadMercenaryInfo(is_temp_formation, formation_id, group_index)
    formation_id = formation_id or self.formation_id
    group_index = group_index or self.cur_group_index

    self.mercenary_list = troop_logic:GetFormationMercenaryList(formation_id)

    self.cur_mercenary_num = #self.mercenary_list
    
    --如果两者长度不相等，则重置temp_formation
    if self.temp_formations[formation_id] then
        if self.cur_mercenary_num ~= #self.temp_formations[formation_id] then
            is_temp_formation = false
        end
    end

    local mercenary
    for i = 1, self.cur_mercenary_num do
        local sub_panel = self.mercenary_sub_panels[group_index][i]
        if is_temp_formation then
            mercenary = troop_logic:GetMercenaryInfo(self.temp_formations[formation_id][i])
            --防止拖动后位置错乱
            self.shaking_spine_trackers[i]:Bind(self.sub_panel_pos_xs[i], self.sub_panel_pos_ys[i], sub_panel.root_node)
        else
            mercenary = self.mercenary_list[i]
            self.temp_formations[formation_id][i] = mercenary.instance_id
        end

        local ntemp = is_temp_formation and 1 or 0
        assert(mercenary,  string.format("mercenary %d, %d, %d, %d, %d", i, self.cur_mercenary_num, self.formation_capacity, ntemp, self.temp_formations[formation_id][i]))
        if mercenary then
            sub_panel:Load(mercenary)
        else
            sub_panel:Clear(true)
        end

        --sub_panel.root_node:setTouchEnabled(true)
        sub_panel.root_node:setTag(i)
        sub_panel.root_node:setScale(1, 1)
        sub_panel.root_node:setVisible(true)
    end
end

--选中佣兵
function mercenary_formation_panel:ChooseMercenary()
    if self.cur_mercenary_pos <= self.cur_mercenary_num then
        if self.arrange_node:isVisible() then
            --上一个处于选择状态的佣兵移除选择框
            if self.last_mercenary_pos ~= self.cur_mercenary_pos then
                self.shaking_spine_trackers[self.last_mercenary_pos]:RemoveSelectWidget()
            end

            --选择框跟随当前 选中的佣兵 抖起来  抖抖抖抖
            local x, y = self.sub_panel_pos_xs[self.cur_mercenary_pos], self.sub_panel_pos_ys[self.cur_mercenary_pos]
            self.shaking_spine_trackers[self.cur_mercenary_pos]:BindSelectWidget(self.choose_img, x, y)
            self.choose_img:setVisible(true)
        else
            --选中动画
            self:UnchosenMercenaryAnimation()
            self:ChooseMercenaryAnimation()
            self.choose_img:setVisible(false)
        end

        self.preview_sub_panel:Show(self.cur_mercenary_id, self.formation_id)
        self.last_mercenary_pos = self.cur_mercenary_pos

    elseif self.cur_mercenary_pos <= self.formation_capacity then
        graphic:DispatchEvent("show_world_sub_scene", "mercenary_choose_sub_scene", nil, CHOOSE_SHOW_MODE, self.cur_mercenary_id, self.cur_mercenary_pos, self.formation_id)
    end
end

--重置mercenary_sub_panels的位置
function mercenary_formation_panel:ResetMercenarySubPanelPos()
    local begin_y = self:IntiScrollViewSize(false)
    local cur_sub_panels = self.mercenary_sub_panels[self.cur_group_index]

    for i = 1, constants["MAX_FORMATION_CAPACITY"] do
        local root_node = cur_sub_panels[i].root_node
        local row, col = self:CalcRowAndCol(i)
        local x = BEGIN_X + (col - 1) * INTERVAL_X
        local y = begin_y - (row - 1) * INTERVAL_Y - self.sub_panel_height / 2
        root_node:setPosition(x, y)
        root_node:setOpacity(255)

        --设置另外一个组的位置, 默认在屏幕的右侧
        self.mercenary_sub_panels[self:GetAnotherGroupIndex()][i].root_node:setPosition(x + 640, y)

        self.sub_panel_pos_xs[i] = x
        self.sub_panel_pos_ys[i] = y
    end
end

--抖动
function mercenary_formation_panel:ShakingMercenarySubPanels()
    local shaking = self.arrange_node:isVisible()
    local cur_sub_panels = self.mercenary_sub_panels[self.cur_group_index]

    for i = 1, constants["MAX_FORMATION_CAPACITY"] do
        local tracker = self.shaking_spine_trackers[i]
        tracker.root_node:setVisible(shaking)

        local ref_node = cur_sub_panels[i].root_node
        if i <= self.cur_mercenary_num then
            if shaking then
                tracker:Bind(self.sub_panel_pos_xs[i], self.sub_panel_pos_ys[i], ref_node)
            else
                tracker:StopShaking()
            end
        end
    end
    self.shaking = shaking
end

--获取另一组index
function mercenary_formation_panel:GetAnotherGroupIndex()
    return self.cur_group_index == 1 and 2 or 1
end

--拖动之后重新设定位置
function mercenary_formation_panel:ResetPosAfterDrag()
    local cur_sub_panels = self.mercenary_sub_panels[self.cur_group_index]

    if self.last_find_pos == self.find_pos then
        return

    elseif self.last_find_pos < self.find_pos then
        for i = (self.last_find_pos + 1), self.find_pos do
            local sub_panel = cur_sub_panels[i]
            local x, y = self.sub_panel_pos_xs[i - 1], self.sub_panel_pos_ys[i - 1]
            self.shaking_spine_trackers[i]:Bind(x, y, sub_panel.root_node)
        end

    else
        for i = self.find_pos, self.last_find_pos - 1 do
            local sub_panel = cur_sub_panels[i]
            local x, y = self.sub_panel_pos_xs[i + 1], self.sub_panel_pos_ys[i + 1]
            self.shaking_spine_trackers[i]:Bind(x, y, sub_panel.root_node)
        end
    end

    --操作sub_panel, 更新sub_panel的索引
    local last_find_sub_panel = cur_sub_panels[self.last_find_pos]
    table.remove(cur_sub_panels, self.last_find_pos)
    table.insert(cur_sub_panels, self.find_pos, last_find_sub_panel)

    --防止不抖动
    self:ShakingMercenarySubPanels()
    self.last_find_pos = self.find_pos
end

--寻找拖动的位置
function mercenary_formation_panel:FindMovingPanelPos()
    --TODO find_pos. last_find_pos 是否可以和 cur_mercenary_pos, last_mercenary_pos 一致
    self.start_find_pos = false
    local row, col, find_pos = 0, 0, 1
    local moving_pos_x, moving_pos_y = self.moving_sub_panel.root_node:getPositionX(), self.moving_sub_panel.root_node:getPositionY()
    local scroll_view_y = self.scroll_view:getPositionY() - 20

    --先找行, 目前未找到self.mercenary_sub_panels[self.cur_group_index][i].root_node的位置转换方法，只能采取根据scroll_view的位置设定y
    for i = 1, self.cur_mercenary_num, 5 do
        local cur_row = math.ceil(i / 5)
        local y = scroll_view_y - (cur_row -1) * INTERVAL_Y
        if moving_pos_y < y and moving_pos_y > (y - self.sub_panel_height) then
            row = cur_row
            break
        end
    end

    --再找列
    for i = 1, 5 do
        local col_pos_x = self.sub_panel_pos_xs[i]
        if moving_pos_x < (col_pos_x + self.sub_panel_width / 2) and moving_pos_x > (col_pos_x - self.sub_panel_width / 2)  then
            col = i
            break
        end
    end

    if row == 0 or col == 0 then
        find_pos = self.last_find_pos
    else
        find_pos = (row - 1) * 5 + col
        if find_pos > self.cur_mercenary_num then
            find_pos = self.last_find_pos
        end
    end

    if find_pos == self.find_pos or find_pos == self.last_find_pos then
        return
    end

    self.find_pos = find_pos
    self:ResetPosAfterDrag()
end

--拖动的最终位置
function mercenary_formation_panel:FindMovingPanelEndPos()
    if not self.moving_sub_panel_flag then
        return
    end
    self.moving_sub_panel_flag = false
    self.start_find_pos = false
    self.moving_sub_panel.root_node:setVisible(false)

    if self.find_pos ~= self.cur_mercenary_pos then
        if self.cur_mercenary_pos <= self.cur_mercenary_num and self.find_pos <= self.cur_mercenary_num and self.cur_mercenary_id ~= 0 then
            table.remove(self.temp_formations[self.formation_id], self.cur_mercenary_pos)
            table.insert(self.temp_formations[self.formation_id], self.find_pos, self.cur_mercenary_id)
            self:LoadMercenaryInfo(true)
        else
            return
        end

    else
        local x, y = self.sub_panel_pos_xs[self.find_pos], self.sub_panel_pos_ys[self.find_pos]
        self.shaking_spine_trackers[self.cur_mercenary_pos]:Bind(x, y, self.choose_sub_panel.root_node)
        self.choose_sub_panel:Load(troop_logic:GetMercenaryInfo(self.cur_mercenary_id))
    end

    --位置交换 则id重设
    self.cur_mercenary_id = self.mercenary_sub_panels[self.cur_group_index][self.find_pos].mercenary_id
    self.cur_mercenary_pos = self.find_pos
    self:ChooseMercenary()
end

--update
function mercenary_formation_panel:Update(elapsed_time)
    --多阵容箭头
    self:UpdateFormationArrowImg(elapsed_time)

    if not self.arrange_node:isVisible() then
        --详情
        self:EnterDetailPanel(elapsed_time)
        --检测是否可以切换阵容
        self:CheckChangeFormation(elapsed_time)
        
        self:FormationTipTransition(elapsed_time)

        --切换阵容动画
        self:ChangeFormationTransition(elapsed_time)

        self.cur_choose_spine_tracker:Update(elapsed_time)
        self.last_choose_spine_tracker:Update(elapsed_time)

    else

        self:UpdateArrangePos(elapsed_time)
        --检测是否可以移动sub_panel
        self:CheckCanMovingSubPanel(elapsed_time)

        --寻找位置
        if self.start_find_pos then
            self.find_duration = self.find_duration + elapsed_time
            if self.find_duration >= 0.1 then
                self.start_find_pos = false
                self.find_duration = 0
                self:FindMovingPanelPos()
            end
        end

        --抖动动画
        if self.shaking then
            for i = 1, self.cur_mercenary_num do
                self.shaking_spine_trackers[i]:Update(elapsed_time)
            end
        end
    end
end

--抖动阵容箭头图片
function mercenary_formation_panel:UpdateFormationArrowImg(elapsed_time)
    --抖箭头
    self.formation_arrow_duration = self.formation_arrow_duration + elapsed_time
    if self.formation_arrow_duration > 0.314 then
        self.formation_arrow_duration = 0
    end

    self.formation_arrow1_img:setPositionX(self.formation_arrow1_x + 5 * math.sin(10 * self.formation_arrow_duration))
    self.formation_arrow2_img:setPositionX(self.formation_arrow2_x - 5 * math.sin(10 * self.formation_arrow_duration))
end

--检测是否可以开始移动sub_panel
function mercenary_formation_panel:CheckCanMovingSubPanel(elapsed_time)
    if self.start_drag_sub_panel then
        self.drag_duration = self.drag_duration + elapsed_time
        if self.drag_duration >= 0.2 then

            --则开始移动sub_panel
            self.start_drag_sub_panel = false
            self.drag_duration = 0

            self.moving_sub_panel_flag = true

            --防止长按的时候 手指移动位置
            self.moving_sub_panel.root_node:setPosition(self.touch_start_location)
            --开始寻找位置
            self.start_find_pos = true
            self.find_duration = 0
        end
    end
end

--判断是否可以进入详情 按住 前后左右如果位移超过20像素 则不能进详情面板
function mercenary_formation_panel:CheckCanEnterDetailPanel(move_location)
    local OFFSET = 20
    if self.show_detail_panel then
        local start_pos = self.touch_start_location
        if (start_pos.x < move_location.x - OFFSET) or (start_pos.x > move_location.x + OFFSET) then
            self.show_detail_panel = false
            self.detail_duration = 0
        end

        if (start_pos.y <  move_location.y - OFFSET) or (start_pos.y > move_location.y + OFFSET) then
            self.show_detail_panel = false
            self.detail_duration = 0
        end
    end
end

--进入佣兵详情
function mercenary_formation_panel:EnterDetailPanel(elapsed_time)
    if self.show_detail_panel then
        self.detail_duration = self.detail_duration + elapsed_time
        if self.detail_duration > 0.5 then
            self.show_detail_panel = false
            self.detail_duration = 0

            local mode = client_constants["MERCENARY_DETAIL_MODE"]["formation"]
            graphic:DispatchEvent("show_world_sub_panel", "mercenary_detail_panel", mode, self.cur_mercenary_id, self.formation_id)
        end
    end
end

--检测拖动之后 是否有佣兵位置变化
function mercenary_formation_panel:CheckMercenaryPosIsChanged()

    local is_change_pos = false
    if #self.mercenary_list ~= #self.temp_formations[self.formation_id] then
        return is_change_pos
    end

    for i = 1, #self.mercenary_list do
        local instance_id = self.mercenary_list[i].instance_id
        local temp_instance_id = self.temp_formations[self.formation_id][i]

        if instance_id ~= temp_instance_id then
            is_change_pos = true
            break
        end
    end

    return is_change_pos
end

--获取id在mercenary_id_list中的位置
function mercenary_formation_panel:GetPosInTempIdList(mercenary_id)
    for i, id in ipairs(self.temp_formations[self.formation_id]) do
        if id == mercenary_id then
            return i
        end
    end
    return 0
end

--开始拖动佣兵 sub_panel
function mercenary_formation_panel:StartDragMercenarySubPanel(move_location)
    self.choose_sub_panel:Clear(true)
    local moving_root_node = self.moving_sub_panel.root_node
    if not moving_root_node:isVisible() then
       moving_root_node:setVisible(true)
       self.choose_img:setVisible(false)
       self.moving_sub_panel:Load(troop_logic:GetMercenaryInfo(self.cur_mercenary_id))
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
end

--点击佣兵事件结束
function mercenary_formation_panel:CancelViewMercenaryEvent()
    self.show_detail_panel = false
    self.detail_duration = 0

    self.start_drag_sub_panel = false
    self:SetBtnsTouchEnabled(true)

    if self.moving_sub_panel_flag then
        self:FindMovingPanelEndPos()
    end

    if not self.scrolling then
        self:ChooseMercenary()
    end
end

--流派面板滑动
function mercenary_formation_panel:MoveGenreSubPanel(move_flag)

    if move_flag and not self.lineup_move_flag then
       self.lineup_bg:setPositionY(self.lineup_bg:getPositionY() + LINEUP_MOVE_Y_DISTANCE)
       self.multi_formation_node:setVisible(not move_flag)
       self.lineup_swallow_touch_img:setVisible(move_flag)
       self.lineup_move_flag = move_flag

    else
       if not move_flag and self.lineup_move_flag then
           self.lineup_bg:setPositionY(self.lineup_bg:getPositionY() - LINEUP_MOVE_Y_DISTANCE)
           self.multi_formation_node:setVisible(not move_flag)
           self.lineup_swallow_touch_img:setVisible(move_flag)
           self.lineup_move_flag = move_flag
       end
    end
end
--formation_tip 移动动画
function mercenary_formation_panel:FormationTipTransition(elapsed_time)
    if self.formation_tip_flag then
        self.formation_tip_duration = self.formation_tip_duration + elapsed_time

        if self.formation_tip_duration <=  FORMATION_TRANSITION_TIME then
            local percent = 1.01 * math.exp(- ( 1.2 * self.formation_tip_duration / FORMATION_TRANSITION_TIME - 1.5 ) ^ 4)
            percent = math.min(percent, 1)
            self.formation_tip_img:setOpacity(255 * percent)

        elseif self.formation_tip_duration <= FORMATION_TRANSITION_TIME + 0.3 then

        elseif self.formation_tip_duration <= FORMATION_TRANSITION_TIME + 0.8 then
            local percent = 1 - 1.01 * math.exp(- ( 1.2 * (self.formation_tip_duration - 0.8)  / FORMATION_TRANSITION_TIME - 1.5 ) ^ 4)
            percent = math.max(percent, 0)
            self.formation_tip_img:setOpacity(255 * percent)
        else
            self.formation_tip_img:setOpacity(0)

            self.formation_tip_flag = false
            self.formation_tip_duration = 0
        end
    end
end

--阵容切换动画
function mercenary_formation_panel:ChangeFormationTransition(elapsed_time)
    if self.change_formation_transition_flag then
        self.change_formation_transition_time = self.change_formation_transition_time + elapsed_time
        if self.change_formation_transition_time <= TRANSITION_TIME then
            local another_group_index = self:GetAnotherGroupIndex()
            self.can_change_formation = false

            local cur_sub_panels = self.mercenary_sub_panels[self.cur_group_index]
            local another_sub_panels = self.mercenary_sub_panels[another_group_index]

            local percent = 1.01 * math.exp(- ( 1.2 * (self.change_formation_transition_time / TRANSITION_TIME) - 1.5) ^ 4)
            percent = math.min(percent, 1)

            for i = 1, MAX_FORMATION_CAPACITY do
                local cur_sub_panel = cur_sub_panels[i]
                cur_sub_panel.root_node:setOpacity(255 * (1 - percent))

                local next_sub_panel = another_sub_panels[i]
                next_sub_panel.root_node:setOpacity(255 * percent)

                if self.offset_pos < 0 then
                    next_sub_panel.root_node:setPositionX(self.sub_panel_pos_xs[i] + self.offset_pos + percent * SCREEN_WIDTH)
                    cur_sub_panel.root_node:setPositionX(self.sub_panel_pos_xs[i] + percent * SCREEN_WIDTH)
                else
                    next_sub_panel.root_node:setPositionX(self.sub_panel_pos_xs[i] + self.offset_pos - percent * SCREEN_WIDTH)
                    cur_sub_panel.root_node:setPositionX(self.sub_panel_pos_xs[i] - percent * SCREEN_WIDTH)
                end
            end

            self.cur_choose_spine_tracker.root_node:setVisible(false)
            self.last_choose_spine_tracker.root_node:setVisible(false)
        else
            self.change_formation_transition_flag = false
            self.change_formation_transition_time = 0

            --切换动画完毕
            if self.finish_change_formation_transition then
                self.cur_group_index = self:GetAnotherGroupIndex()
                self:ChooseMercenaryAnimation()
                self:SetMultiFormationImgsOpacity()

                --更新属性
                --TODO
                --self:UpdateTroopProperty()
                --更新战斗力
                troop_logic:CalcTroopBP(self.formation_id, true)

                self.scroll_view:setTouchEnabled(true)
                self:SetBtnsTouchEnabled(true)

                local cur_sub_panels = self.mercenary_sub_panels[self.cur_group_index]
                --修正最后的位置
                for i = 1, constants["MAX_FORMATION_CAPACITY"] do
                    local root_node = cur_sub_panels[i].root_node

                    root_node:setPosition(self.sub_panel_pos_xs[i], self.sub_panel_pos_ys[i])
                    root_node:setOpacity(255)
                end
                self.finish_change_formation_transition = false
            end
        end
    end
end

--检测是否切换阵容
function mercenary_formation_panel:CheckChangeFormation(elapsed_time)
    if self.change_formation_move_pos and self.start_change_formation then
        self.change_formation_check_time = self.change_formation_check_time + elapsed_time

        if self.change_formation_check_time < 0.2 then
            local distance_x = self.change_formation_move_pos.x - self.change_formation_begin_pos.x
            local distance_y = math.abs(self.change_formation_move_pos.y - self.change_formation_begin_pos.y)
            if math.abs(distance_x) > 30 and math.abs(distance_x) > distance_y then
                self.start_change_formation = false
                --截断进入详情
                self.show_detail_panel, self.detail_duration = false, 0

                local next_formation_id = self:GetNextFormationId(distance_x)
                --可以切换阵容，初始化一些数据
                if next_formation_id ~= self.formation_id then
                    --取消当前选中状态
                    self:ResetChooseTracker()

                    --另外一组面板更新要切换的阵容中的佣兵信息
                    local another_group_index = self:GetAnotherGroupIndex()
                    self:LoadFormationInfo(next_formation_id, another_group_index)

                    self.formation_id = next_formation_id

                    troop_logic:SetClientFormationId(self.formation_id)

                    self.change_formation_transition_time, self.change_formation_transition_flag = 0, true
                    self.formation_tip_duration, self.formation_tip_flag = 0, true

                    self.finish_change_formation_transition = true

                    self.scroll_view:setTouchEnabled(false)
                    self:SetBtnsTouchEnabled(false)
                end
            end
        end
    end
end

--切换之后获得下一个阵容id
function mercenary_formation_panel:GetNextFormationId(distance_x)
    local next_formation_id
    if distance_x < 0 then
        --向左滑动
        if self.formation_id == MAX_FORMATION_NUM then
            --切换到阵容1
            next_formation_id = 1
        else
            next_formation_id = self.formation_id + 1
        end

        self.offset_pos = SCREEN_WIDTH
    else
        --向右滑动
        if self.formation_id == 1 then
            --切换到阵容4
            next_formation_id = MAX_FORMATION_NUM
        else
            next_formation_id = self.formation_id - 1
        end

        self.offset_pos = -SCREEN_WIDTH
    end

    return next_formation_id
end

--清空资源，注册的事件
function mercenary_formation_panel:Clear()
    self.origin_event_dispatcher:removeEventListener(self.touch_listener)
    panel_prototype.Clear(self)
end

function mercenary_formation_panel:Hide(last_sub_scene)
    --重置选中状态
    self:ResetChooseTracker()
    self.touch_listener:setEnabled(false)

    if last_sub_scene ~= "mercenary_choose_sub_scene" then
        if self.formation_id ~= constants["GUILD_WAR_TROOP_ID"] then
            troop_logic:ChangeFormation(self.formation_id)
        end
        troop_logic:SetClientFormationId(troop_logic:GetCurFormationId())
    end

    self:MoveGenreSubPanel(false)
    self.skill_percent_img:setTouchEnabled(true)
    self.root_node:setVisible(false)
end

function mercenary_formation_panel:SetBackPanel(back_panel, ex_params)
    self.back_panel = back_panel
    self.back_panel_ex_params = ex_params
end

function mercenary_formation_panel:RegisterEvent()
    --更换佣兵，重新load资源
    graphic:RegisterEvent("update_exploring_merceanry_position", function(mode, index, src_id, dest_id, formation_id)
        if not self.root_node:isVisible() then
            return
        end

        if formation_id ~= self.formation_id then
            return
        end

        self:SetBtnsTouchEnabled(true)

        local cur_sub_panels = self.mercenary_sub_panels[self.cur_group_index]

        if mode == client_constants["MERCENARY_TO_FORMATION"]["rest"] then
            --休息, 默认显示下一个佣兵， 若是最后一个则显示前一个
            local src_pos = self:GetPosInTempIdList(src_id)
            if src_pos > 0 and src_pos <= self.cur_mercenary_num then
                --最后一个sub_panel 不再加载信息，并停止抖动
                cur_sub_panels[self.cur_mercenary_num]:Clear(true)
                self.shaking_spine_trackers[self.cur_mercenary_num]:StopShaking()

                table.remove(self.temp_formations[self.formation_id], src_pos)
                self:LoadMercenaryInfo(true)
                self.cur_mercenary_pos = math.min(src_pos, self.cur_mercenary_num)
            end

        elseif mode == client_constants["MERCENARY_TO_FORMATION"]["replace"] then
            --替换
            local src_pos = self:GetPosInTempIdList(src_id)
            if src_pos > 0 and src_pos <= self.cur_mercenary_num then
                self.temp_formations[self.formation_id][src_pos] = dest_id

                local dest_mercenary = self.mercenary_list[index]
                local sub_panel = cur_sub_panels[src_pos]
                sub_panel:Load(dest_mercenary)

                self.cur_mercenary_pos = src_pos
            end

        elseif mode == client_constants["MERCENARY_TO_FORMATION"]["add"] then
            ---空位上阵，默认显示最后一个
            self.cur_mercenary_num = #self.mercenary_list

            local mercenary = troop_logic:GetMercenaryInfo(src_id)
            table.insert(self.temp_formations[self.formation_id], mercenary.instance_id)

            self.cur_mercenary_pos = self.cur_mercenary_num
            local sub_panel = cur_sub_panels[self.cur_mercenary_pos]
            self.shaking_spine_trackers[self.cur_mercenary_pos]:Bind(sub_panel.root_node:getPositionX(), sub_panel.root_node:getPositionY(), sub_panel.root_node)

            sub_panel:Load(mercenary)

        elseif mode == client_constants["MERCENARY_TO_FORMATION"]["recommend"] then
            self:MoveGenreSubPanel(false)

            for i, sub_panel in pairs(cur_sub_panels) do
                if i <= self.cur_mercenary_num then
                    sub_panel:Clear(true)
                    --self.shaking_spine_trackers[i]:StopShaking()
                end
            end

            self.temp_formations[self.formation_id] = {}
            self:LoadFormationInfo()
            self:ChooseMercenary()
            return
        end

        self.cur_mercenary_id = cur_sub_panels[self.cur_mercenary_pos].mercenary_id
        self:ChooseMercenary()
        self:UpdateTroopProperty()
    end)
    
    graphic:RegisterEvent("update_exploring_merceanry", function(mercenary_id)
        if not self.root_node:isVisible() then
            return
        end

        self:MoveGenreSubPanel(false)

        self:SetBtnsTouchEnabled(true)

        local cur_sub_panels = self.mercenary_sub_panels[self.cur_group_index]

        for i, sub_panel in pairs(cur_sub_panels) do
            if i <= self.cur_mercenary_num then
                sub_panel:Clear(true)
            end
        end

        self.temp_formations[self.formation_id] = {}
        self:LoadFormationInfo()
        self:ChooseMercenary()
    end)

    graphic:RegisterEvent("update_mercenary_info", function(mercenary_id)
        --强化成功， 觉醒，开启宝具， 限界突破
        if not self.root_node:isVisible() then
            return
        end

        local mercenary = troop_logic:GetMercenaryInfo(mercenary_id)
        self.mercenary_sub_panels[self.cur_group_index][self.cur_mercenary_pos]:Load(mercenary)
        self:UpdateTroopProperty()
    end)

    graphic:RegisterEvent("open_artifact", function(mercenary_id)
        --开启宝具
        if not self.root_node:isVisible() then
            return
        end

        self:UpdateTroopProperty()
    end)

    graphic:RegisterEvent("update_leader_weapon", function()
        --装备武器
        if not self.root_node:isVisible() then
            return
        end

        self:UpdateTroopProperty()
        self.preview_sub_panel:Show(self.cur_mercenary_id, self.formation_id)
    end)

    graphic:RegisterEvent("upgrade_leader_weapon_lv", function()
        --主角武器强化
        if not self.root_node:isVisible() then
            return
        end

        self:UpdateTroopProperty()
        self.preview_sub_panel:Show(self.cur_mercenary_id, self.formation_id)
    end)
end

function mercenary_formation_panel:RegisterWidgetEvent()
    self.view_mercenary = function(widget, event_type)
        if event_type == ccui.TouchEventType.began then

            --160927-WYJ:在手动调整模式下，如果已经开始拖动佣兵了则直接返回
            if self.arrange_node:isVisible() then
                if self.is_draging_one then
                    return
                else
                    self.is_draging_one = true
                end
            end

            self.scrolling = false
            self.cur_mercenary_pos = widget:getTag()

            self.choose_sub_panel = self.mercenary_sub_panels[self.cur_group_index][self.cur_mercenary_pos]
            self.cur_mercenary_id = self.choose_sub_panel.mercenary_id
            self.find_pos, self.last_find_pos = self.cur_mercenary_pos, self.cur_mercenary_pos

            self.touch_start_location = widget:getTouchBeganPosition()

            if self.cur_mercenary_id ~= 0 then
                if self.arrange_node:isVisible() then
                    self.drag_duration = 0
                    self.moving_sub_panel_flag = false
                    self.start_drag_sub_panel = true
                else
                    self.show_detail_panel = true
                    self.detail_duration = 0
                end
            end

        elseif event_type == ccui.TouchEventType.moved then
            if self.cur_mercenary_pos > self.cur_mercenary_num then
                return
            end

            local move_location = widget:getTouchMovePosition()
            self:CheckCanEnterDetailPanel(move_location)

            self:SetBtnsTouchEnabled(false)
            --开始拖动
            if self.moving_sub_panel_flag then
                self:StartDragMercenarySubPanel(move_location)
            end

        --松开手时开始移动mercenary_template_panel
        elseif event_type == ccui.TouchEventType.ended then
            self.is_draging_one = false
            self:CancelViewMercenaryEvent()
        elseif event_type == ccui.TouchEventType.canceled then
            self.is_draging_one = false
            self:CancelViewMercenaryEvent()
        end
    end

    --返回
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.arrange_node:isVisible() then
                self.arrange_node:setVisible(false)
                self:SetArrangeNodeStatus()
                self:LoadMercenaryInfo(false)
                self:ChooseMercenary()
            else
                graphic:DispatchEvent("hide_world_sub_scene")
              
                if self.back_panel then
                    if self.back_panel_ex_params then
                        if self.back_panel == "campaign_event_msgbox" or self.back_panel == "guild.formation_panel" or self.back_panel == "mine_plunder_panel"then 
                            graphic:DispatchEvent("show_world_sub_panel", self.back_panel, unpack(self.back_panel_ex_params))
                        else
                            graphic:DispatchEvent("show_world_sub_panel", self.back_panel, nil, nil, unpack(self.back_panel_ex_params))
                        end
                    else
                        if self.back_panel == "guild.main_panel" then
                            graphic:DispatchEvent("show_world_sub_scene", "guild_sub_scene")
                        else
                            graphic:DispatchEvent("show_world_sub_panel", self.back_panel)
                        end
                    end
                end
            end

            graphic:DispatchEvent("hide_floating_panel")
        end
    end)

    --推荐
    self.recommend_formation_button:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "mercenary_recommend_panel", self.formation_id)
        end
    end)

    --替换佣兵
    self.replace_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "mercenary_choose_sub_scene", nil, CHOOSE_SHOW_MODE, self.cur_mercenary_id, self.cur_mercenary_pos, self.formation_id)
        end
    end)

    --下阵
    self.rest_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            troop_logic:RestMercenary(self.formation_id, self.cur_mercenary_id)
        end
    end)

    --修改阵容名字
    self.change_name_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "rename_panel", client_constants["RENAME_PANEL_MODE"]["formation"], self.formation_id)
        end
    end)

    --手动调整
    self.arrange_mercenary_pos_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            self:MoveGenreSubPanel(false)
            local arrange_isvisible = self.arrange_node:isVisible()
            if arrange_isvisible then
                if self:CheckMercenaryPosIsChanged() then
                    troop_logic:AdjustMercenaryPosition(self.formation_id, self.temp_formations[self.formation_id])
                end
            end
            self.skill_percent_img:setTouchEnabled(arrange_isvisible)
            self.arrange_node:setVisible(not arrange_isvisible)
            self:SetArrangeNodeStatus()
            self:ChooseMercenary()
            graphic:DispatchEvent("hide_floating_panel")
       end
    end)

    --显示“属性”说明
    self.skill_percent_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:MoveGenreSubPanel(not self.lineup_move_flag)
        end
    end)

    --查看技能覆盖率
    self.skill_details_button:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
           audio_manager:PlayEffect("click")
           graphic:DispatchEvent("show_world_sub_panel", "mercenary_lineup_details_panel", self.skill_datas)
        end
    end)

    --滚动容器事件
    self.scroll_view:addEventListener(function(lview, event_type)
        if event_type == ccui.ScrollViewEventType.scrolling then
            self.scrolling = true
        end
    end)

    --用于切换至阵容
    local touch_listener = cc.EventListenerTouchOneByOne:create()
    touch_listener:registerScriptHandler(function(touches, event)
        if self.lineup_move_flag then return end
        self.change_formation_begin_pos = touches:getLocation()
        --限定区域
        if self.change_formation_begin_pos.y > 209 and self.change_formation_begin_pos.y < 765 and not self.finish_change_formation_transition then
            self.scroll_view:setTouchEnabled(false)

            self.change_formation_check_time = 0
            self.start_change_formation = true
        end

        return true
    end, cc.Handler.EVENT_TOUCH_BEGAN)

    touch_listener:registerScriptHandler(function(touches, event)
        if self.lineup_move_flag then return end
        self.change_formation_move_pos = touches:getLocation()
    end, cc.Handler.EVENT_TOUCH_MOVED)

    touch_listener:registerScriptHandler(function(touches, event)
        if self.lineup_move_flag then return end
        self.change_formation_check_time = 0
        self.start_change_formation = false
        self.scroll_view:setTouchEnabled(true)
        self:SetBtnsTouchEnabled(true)
        self.change_formation_move_pos = nil
    end, cc.Handler.EVENT_TOUCH_ENDED)

    self.touch_listener = touch_listener
    self.origin_event_dispatcher:addEventListenerWithFixedPriority(touch_listener, -1)
end

return mercenary_formation_panel

