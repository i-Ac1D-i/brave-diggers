local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local adventure_logic = require "logic.adventure"
local bag_logic = require "logic.bag"
local chat_logic = require "logic.chat"
local store_logic = require "logic.store"
local troop_logic = require "logic.troop"
local reminder_logic = require "logic.reminder"
local audio_manager = require "util.audio_manager"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local platform_manager = require "logic.platform_manager"
local lang_constants = require "util.language_constants"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local spine_manager = require "util.spine_manager"

local user_logic = require "logic.user"
local vip_logic = require "logic.vip"

local RESOURCE_TYPE = constants["RESOURCE_TYPE"]
local PLIST_TYPE = ccui.TextureResType.plistType
local ADVENTURE_EVENT_TYPE = constants["ADVENTURE_EVENT_TYPE"]
local MAZE_TYPE_ICON = client_constants["MAZE_TYPE_ICON"]

local PERMANENT_MARK = constants["PERMANENT_MARK"]

local FEATURE_TYPE = client_constants["FEATURE_TYPE"]
local LIGHT_STAR = client_constants["LIGHT_STAR"]
local DARK_STAR = client_constants["DARK_STAR"]

local MAZE_EVENT_STATUS = client_constants.ADVENTURE_MAZE_EVENT_STATUS

-- 评论类型
local COMMENT_TYPE = constants["COMMENT_TYPE"]["maze"]

local SPINE_SKIN = {"coin","exp"}
local SPINE_PARAMS = {["POS_X"] = 300, ["POS_Y"] = 400, ["OFFSET_X"] = 20, ["OFFSET_Y"] = 20, ["INTERVAl"] = 0.8 }

local difficulty_panel = panel_prototype.New()
function difficulty_panel:Init(root_node)
    self.root_node = root_node
    root_node:setLocalZOrder(2)

    self.btns = {}
    self.desc_texts = {}

    self.btns[1] = root_node:getChildByName("easy_btn")
    self.btns[2] = root_node:getChildByName("normal_btn")
    self.btns[3] = root_node:getChildByName("hard_btn")

    self.star_imgs = {}

    for i = 1, 3 do
        self.desc_texts[i] = self.btns[i]:getChildByName("desc")
        self.star_imgs[i] = self.btns[i]:getChildByName("star")
        panel_util:SetTextOutline(self.desc_texts[i], 0x000000, 3, -5)
    end
end

function difficulty_panel:Show(area_id)
    self.root_node:setVisible(true)

    local area_conf = config_manager.area_info_config[area_id]
    local maze_list_map = area_conf.maze_list_map

    for i = 1, 3 do
        local text = self.desc_texts[i]
        if adventure_logic:IsDifficultyUnlocked(area_id, i) then
            text:setString(lang_constants:Get("adventure_difficulty" .. i))
        else
            text:setString(lang_constants:Get("adventure_area_is_locked") .. " " .. lang_constants:Get("adventure_difficulty" .. i))
        end

        local maze_list = maze_list_map[i]
        if maze_list then
            self.btns[i]:setVisible(true)
            local is_clear = adventure_logic:IsMazeClear(maze_list[#maze_list].ID)
            self.star_imgs[i]:loadTexture(is_clear and LIGHT_STAR or DARK_STAR, PLIST_TYPE)
        else

            self.btns[i]:setVisible(false)
        end
    end
end

local maze_sub_panel = panel_prototype.New()
maze_sub_panel.__index = maze_sub_panel

function maze_sub_panel.New()
    return setmetatable({}, maze_sub_panel)
end

function maze_sub_panel:Init(root_node)
    self.root_node = root_node
    root_node:setLocalZOrder(1)

    self.root_node:setCascadeColorEnabled(true)

    self.maze_icon_img = root_node:getChildByName("icon")

    self.type_icon_img = root_node:getChildByName("info")

    self.name_text = self.type_icon_img:getChildByName("maze_num")
    self.star_img = self.type_icon_img:getChildByName("star")

    self.type_icon_img:setCascadeColorEnabled(true)
end

function maze_sub_panel:Load(maze_conf, x, y)
    self.root_node:setPosition(x, y)
    self.root_node:setTag(maze_conf.ID)

    self.name_text:setString(maze_conf.name)

    self.maze_icon_img:loadTexture(maze_conf.icon .. "_big.png", PLIST_TYPE)

    if maze_conf.ID == adventure_logic.cur_maze_id then
        self.root_node:setColor(panel_util:GetColor4B(0xffffff))
        self.root_node:setScale(1.0, 1.0)

    else
        self.root_node:setColor(panel_util:GetColor4B(0x7f7f7f))
        self.root_node:setScale(0.8, 0.8)
    end

    self.star_img:loadTexture(adventure_logic:IsMazeClear(maze_conf.ID) and LIGHT_STAR or DARK_STAR, PLIST_TYPE)

    self.type_icon_img:loadTexture(MAZE_TYPE_ICON[maze_conf.type], PLIST_TYPE)
end

local exploring_panel = panel_prototype.New()

function exploring_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/explore_panel.csb")

    self.area_info_img = self.root_node:getChildByName("area_info")
    self.area_name_text = self.area_info_img:getChildByName("area_name")
    self.difficulty_text = self.area_info_img:getChildByName("difficulty")

    self.area_choose_btn = self.root_node:getChildByName("area")

    self.gold_income_text = self.root_node:getChildByName("gold_income")
    panel_util:SetTextOutline(self.gold_income_text)
    self.exp_income_text = self.root_node:getChildByName("exp_income")
    panel_util:SetTextOutline(self.exp_income_text)

    self.channel_info = platform_manager:GetChannelInfo()

    --位置偏移一点点
    if self.channel_info.exploring_panel_exp_icon_move_x ~= nil then
        self.exp_income_text:setPositionX(self.exp_income_text:getPositionX()+self.channel_info.exploring_panel_exp_icon_move_x)
        local exp_icon=self.root_node:getChildByName("exp_icon")
        exp_icon:setPositionX(exp_icon:getPositionX()+self.channel_info.exploring_panel_exp_icon_move_x)
    end
    --难度等级标签位置偏移
    if self.channel_info.exploring_panel_difficulty_text_offset_x then
        self.difficulty_text:setPositionX(self.difficulty_text:getPositionX()+self.channel_info.exploring_panel_difficulty_text_offset_x)
    end
    
    

    self.path_img = self.root_node:getChildByName("path")
    self.loot_btn = self.root_node:getChildByName("loot_btn")

    local exploring_node = self.root_node:getChildByName("explore")

    -- 背包
    self.bag_btn = exploring_node:getChildByName("bag_btn")
    self.bag_btn:getChildByName("remind"):setVisible(false)
    panel_util:SetTextOutline(self.bag_btn:getChildByName("text"))

    self.event_btn = exploring_node:getChildByName("event_btn")
    self.event_btn:setCascadeColorEnabled(true)

    self.event_icon_img = self.event_btn:getChildByName("icon")
    self.event_icon_img:ignoreContentAdaptWithSize(true)
    self.event_icon_img:setScale(2, 2)

    self.event_desc_text = self.event_btn:getChildByName("text")
    panel_util:SetTextOutline(self.event_desc_text)

    self.levelup_btn = exploring_node:getChildByName("levelup_btn")
    self.levelup_remind_img = self.levelup_btn:getChildByName("remind_tip")
    self.levelup_remind_img:setVisible(false)
    panel_util:SetTextOutline(self.levelup_btn:getChildByName("text"))

    self.open_box_btn = exploring_node:getChildByName("item_btn")
    self.quick_btn = exploring_node:getChildByName("quick__btn_0")
    self.quick_times_text = self.quick_btn:getChildByName("count_0")

    self.box_info_img = exploring_node:getChildByName("item_info")
    self.box_num_text = self.box_info_img:getChildByName("count")
    self.box_notify_img = self.box_info_img:getChildByName("count_bg")
    self.box_time_lbar = self.box_info_img:getChildByName("lbar")
    self.box_time_text = self.box_info_img:getChildByName("time")

    local time_node = exploring_node:getChildByName("time")
    self.progress_lbar = time_node:getChildByName("lbar")
    self.progress_arrow_img = time_node:getChildByName("lbar_top_icon")

    self.progress_lbar_width = self.progress_lbar:getContentSize().width

    self.normal_time_node = time_node:getChildByName("normal_time")
    self.remain_time_text = self.normal_time_node:getChildByName("remaining_time")
    self.cur_maze_name_text = self.normal_time_node:getChildByName("maze_num")
    self.maze_desc_text = self.normal_time_node:getChildByName("desc")

    self.exploring_node = exploring_node

    self.layer_node = exploring_node:getChildByName("clip_layer")

    self.maze_sub_panels = {}

    local sub_panel = maze_sub_panel.New()
    local maze_template = self.root_node:getChildByName("maze_template")

    sub_panel:Init(maze_template)
    self.maze_sub_panels[1] = sub_panel

    for i = 2, 5 do
        local sub_panel = maze_sub_panel.New()
        sub_panel:Init(maze_template:clone())
        self.maze_sub_panels[i] = sub_panel

        self.root_node:addChild(sub_panel.root_node)
    end

    difficulty_panel:Init(self.root_node:getChildByName("difficulty_panel"))


    self.open_comment_msgbox_btn = exploring_node:getChildByName("comment_btn")
    self.comment_num = self.open_comment_msgbox_btn:getChildByName("value")

    self.exp_spine_node = spine_manager:GetNode("exp_n_coin_tip", 1.0, true)
    self.root_node:addChild(self.exp_spine_node)
    self.exp_spine_node:setVisible(false)
    self.exp_spine_node:setPosition(SPINE_PARAMS["POS_X"], SPINE_PARAMS["POS_Y"])

    self.cur_area_id = nil
    self.cur_difficulty = nil

    self:CreateSpineNodes()

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function exploring_panel:CreateSpineNodes()
    self.event_spine_node = spine_manager:GetNode("adventure_event", 1.0, true)

    local x, y = self.event_btn:getPosition()
    self.event_spine_node:setPosition(x, y)
    self.event_spine_node:setVisible(false)

    self.event_btn:setLocalZOrder(2)
    self.event_spine_node:setLocalZOrder(1)

    self.exploring_node:addChild(self.event_spine_node)

    self.event_spine_node:registerSpineEventHandler(function(event)
        if event.animation == "appear" then
            self.event_spine_node:setToSetupPose()
            self.event_spine_node:setAnimation(1, "loop", true)
        end
    end, sp.EventType.ANIMATION_END)
end

function exploring_panel:Show(area_id, difficulty)
    -- 检测强化提醒
    reminder_logic:CheckForgeReminder()
    self.root_node:setVisible(true)

    area_id = area_id or adventure_logic.cur_area_id
    difficulty = difficulty or adventure_logic.cur_difficulty

    self:LoadInfo(area_id, difficulty)

    difficulty_panel:Hide()

    if self.channel_info.enable_quick_battle then
        self.quick_btn:setVisible(true)
        self:LoadQuickBattleInfo()
    else
        self.quick_btn:setVisible(false)
    end

    -- 背包满了提醒
    if bag_logic:GetCapacity() > #bag_logic.item_list then
        self.bag_btn:getChildByName("remind"):setVisible(false)
    else
        self.bag_btn:getChildByName("remind"):setVisible(true)
    end
end

function exploring_panel:LoadQuickBattleInfo()
    -- 更新快速战斗次数
    local adventure_buy_config = config_manager.adventure_buy_config
    local max_num = 0
    if not vip_logic:IsActivated(constants.VIP_TYPE["adventure"]) then
        for i = 1, #adventure_buy_config do
            local next_info = adventure_buy_config[i]
            if next_info.month_card == 0 then
                max_num = next_info.times
            end
        end
    else
        max_num = adventure_buy_config[#adventure_buy_config].times
    end

    self.quick_times_text:setString(string.format("%d/%d", adventure_logic.buy_adventure_num, max_num))
end

function exploring_panel:LoadInfo(area_id, difficulty)
    self.cur_area_id = area_id
    self.cur_difficulty = difficulty

    adventure_logic:StartExplore()

    local area_conf = config_manager.area_info_config[area_id]
    local maze_list_map = area_conf.maze_list_map

    local cur_maze_list = maze_list_map[difficulty]

    local POSITION = client_constants["MAZE_POSITION"][area_conf.maze_position]

    self.path_img:setPosition(POSITION.x, POSITION.y)
    self.path_img:setScale(POSITION.scale_x, POSITION.scale_y)

    for i = 1, #cur_maze_list do
        self.maze_sub_panels[i]:Load(cur_maze_list[i], POSITION[i * 2 - 1], POSITION[i * 2])
    end

    self.area_name_text:setString(area_conf.name)
    self.difficulty_text:setString(lang_constants:Get("adventure_difficulty" .. difficulty))

    --当前迷宫信息
    local income_info = adventure_logic.income_info
    self.gold_income_text:setString(income_info.gold_coin .. "/s")
    self.exp_income_text:setString(income_info.exp .. "/s")

    local cur_maze_template_info = adventure_logic.cur_maze_template_info
    self.cur_maze_name_text:setString(cur_maze_template_info.name)

    if adventure_logic.cur_maze_info.event_is_finish then
        if adventure_logic:IsMazeNew(adventure_logic.next_maze_id) then
            self.event_spine_node:setVisible(true)
            self.track_event_animation = true
            self.event_spine_node:setAnimation(1, "loop", true)
        else
            self.track_event_animation = false
            self.event_spine_node:setVisible(false)
        end

    else
        self.event_spine_node:setVisible(true)
        self.event_spine_node:clearTrack(1)

        if adventure_logic.cur_maze_info.event_time < cur_maze_template_info.event_time then
            self.event_spine_node:setAnimation(0, "wait", true)
        end
    end

    self.maze_desc_text:setString(lang_constants:GetExploreTip())

    self:UpdateBoxNum()
    self:UpdateEventProgress(cur_maze_template_info.event_id, adventure_logic.cur_maze_info.event_time, cur_maze_template_info.event_time)

    -- 更新评论数量
    local count = chat_logic:GetCommentNum(COMMENT_TYPE, adventure_logic.cur_maze_id)
    if count then
        self.comment_num:setString(tostring(count))
    else
        self.comment_num:setString(tostring(0))
        -- 取关卡评论数据
        chat_logic:QueryCommentNum(COMMENT_TYPE, adventure_logic.cur_maze_id)
    end
end

function exploring_panel:UpdateBoxNum()
    local box_num = adventure_logic.cur_maze_info["box_num"]
    self.box_num_text:setString(tostring(box_num) .. "/" .. adventure_logic.max_box_num)

    if box_num > 0 then
        self.box_info_img:setColor(panel_util:GetColor4B(0xffffff))
        self.box_notify_img:setVisible(true)
    else
        self.box_info_img:setColor(panel_util:GetColor4B(0x7f7f7f))
        self.box_notify_img:setVisible(false)
    end
end

function exploring_panel:UpdateEventProgress(event_id, cur_time, need_time)
    local width = self.progress_lbar_width
    local cur_event_info = config_manager.event_config[event_id]

    if adventure_logic.cur_maze_info.event_is_finish then
        --探索完毕
        self.progress_lbar:setPercent(100)
        self.progress_arrow_img:setVisible(false)

        self.remain_time_text:setString("∞")
        if not adventure_logic:IsMazeNew(adventure_logic.next_maze_id) then
            self.event_spine_node:clearTrack(0)
            self.event_spine_node:clearTrack(1)
            self.event_spine_node:setVisible(false)
        end

        if adventure_logic.can_enter_next_area then
            self.event_icon_img:loadTexture("button/maze_eventbtn_passbg_d.png", PLIST_TYPE)
            self.event_desc_text:setString(lang_constants:Get("adventure_next_area"))

            self.event_btn:setVisible(true)

        elseif adventure_logic.can_enter_next_maze then
            self.event_icon_img:loadTexture("button/maze_eventbtn_passbg_d.png", PLIST_TYPE)
            self.event_desc_text:setString(lang_constants:Get("adventure_next_maze"))
            self.event_btn:setVisible(true)

        else
            self.event_btn:setVisible(false)
            local show_animation = platform_manager:GetChannelInfo().exploring_panel_max_area_num_show_animation
            if show_animation then
                self.event_spine_node:setVisible(true)
                self.event_spine_node:clearTrack(1)
                self.event_spine_node:setAnimation(0, "wait", true)
            end
        end

        self.track_event_animation = adventure_logic:IsMazeNew(adventure_logic.next_maze_id)

    else
        if cur_time < need_time then
            self.event_btn:setVisible(false)

            local percent = cur_time / need_time
            self.progress_lbar:setPercent(percent * 100)
            self.progress_arrow_img:setVisible(true)

            self.progress_arrow_img:setPositionX(self.progress_lbar:getPositionX() + width * percent - width / 2)

            self.remain_time_text:setString(panel_util:GetTimeStr(need_time - cur_time, true))

            self.track_event_animation = false

        else
            self.progress_lbar:setPercent(100)
            self.progress_arrow_img:setVisible(false)

            local cur_event_cd = adventure_logic:GetCurEventCD()

            if cur_event_cd > 0 then
                self.track_event_animation = false
                self.event_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
            else
                self.event_spine_node:setAnimation(0, "appear", false)
                self.track_event_animation = true
                self.event_btn:setColor(panel_util:GetColor4B(0xffffff))
            end

            self.remain_time_text:setString("∞")
            self.event_btn:setVisible(true)

            if cur_event_info.event_type == ADVENTURE_EVENT_TYPE["battle"] then
                self.event_icon_img:loadTexture("button/maze_eventbtn_fight_d.png", PLIST_TYPE)
                self.event_desc_text:setString(lang_constants:Get("adventure_battle_event"))
            end
        end
    end
end

local time_delta = 0

local temp_color = {}
function exploring_panel:Update(elapsed_time)
    if self.track_event_animation then
        local _, _, scale_x, scale_y, _, _, r, g, b = self.event_spine_node:getSlotTransform("btn")
        temp_color.r = r
        temp_color.g = g
        temp_color.b = b
        self.event_btn:setScale(scale_x, scale_y)
        self.event_btn:setColor(temp_color)
    end

    local time, total_time = adventure_logic:GetBoxRemainTime()
    if time < 0 then
        time = 0
    end

    self.box_time_lbar:setPercent(math.floor((time/total_time)*100))
    self.box_time_text:setString(panel_util:GetTimeStr(time))

    time_delta = time_delta + elapsed_time
    if time_delta >= SPINE_PARAMS["INTERVAl"] then
        -- 金币，经验动画
        self.exp_spine_node:setVisible(true)
        local skin = SPINE_SKIN[math.random(1, 2)]
        local pos_x = SPINE_PARAMS["POS_X"] + math.random(-SPINE_PARAMS["OFFSET_X"], SPINE_PARAMS["OFFSET_X"])
        local pos_y = SPINE_PARAMS["POS_Y"] + math.random(-SPINE_PARAMS["OFFSET_Y"], SPINE_PARAMS["OFFSET_Y"])
        self.exp_spine_node:setSkin(skin)
        self.exp_spine_node:setPosition(pos_x, pos_y)
        self.exp_spine_node:setAnimation(0, "animation", false)
        time_delta = 0
    end

    self:UpdateBoxNum()
end
--[[
  刷新强化BUTTON REMIND提示
]]
function exploring_panel:UpdateForgeRemind(flag)
   if self.levelup_remind_img then
      self.levelup_remind_img:setVisible(flag)
   end
end

function exploring_panel:RegisterEvent()
    --更新宝箱数目
    graphic:RegisterEvent("show_maze_box", function(is_open_box, opened_box_num)
        if not self.root_node:isVisible() then
            return
        end

        self:UpdateBoxNum()

        if is_open_box then
            graphic:DispatchEvent("show_world_sub_panel", "loot_result_panel", opened_box_num)
        end
    end)

    graphic:RegisterEvent("update_explore_event_progress", function(event_id, cur_time, need_time)
        if not self.root_node:isVisible() then
            return
        end

        self:UpdateEventProgress(event_id, cur_time, need_time)
    end)

    graphic:RegisterEvent("solve_event_result", function(event_id, is_finish)
        if not self.root_node:isVisible() then
            return
        end

        if event_id ~= adventure_logic.cur_maze_template_info.event_id then
            return
        end

        if is_finish then
            self:UpdateEventProgress(event_id, 0, 0)
            self.event_spine_node:setVisible(true)
            self.event_spine_node:setAnimation(1, "loop", true)

        else
            local cur_event_cd = math.floor(adventure_logic:GetCurEventCD())
            if cur_event_cd > 0 then
                self.event_spine_node:setToSetupPose()
                self.event_spine_node:clearTrack(1)
                self.event_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
                self.track_event_animation = false
            end
        end
    end)

    -- 背包满了提醒
    graphic:RegisterEvent("bag_is_full", function()
        if not self.root_node:isVisible() then
            return
        end

        if bag_logic:GetCapacity() > #bag_logic.item_list then
            self.bag_btn:getChildByName("remind"):setVisible(false)
        else
            self.bag_btn:getChildByName("remind"):setVisible(true)
        end
    end)

    -- 更新评论数量
    graphic:RegisterEvent("update_comment_num", function(comment_type, id, num)
        if not self.root_node:isVisible() or comment_type ~= COMMENT_TYPE then
            return
        end

        if tonumber(id) ~= adventure_logic.cur_maze_id then
            return
        end

        self.comment_num:setString(tostring(num))
    end)

    graphic:RegisterEvent("store_buy_success", function(goods_id)
        if not self.root_node:isVisible() then
            return
        end

        local goods_info = store_logic:GetGoodsInfoById(goods_id)
        if not goods_info then
            return
        end

        if goods_info.type == constants.STORE_GOODS_TYPE["max_box_num"] then
            self.box_num_text:setString(adventure_logic.cur_maze_info["box_num"] .. "/" .. adventure_logic.max_box_num)
        end
    end)

    -- 强化提醒
    graphic:RegisterEvent("remind_forge" , function(flag)
        self:UpdateForgeRemind(flag)
    end)

    graphic:RegisterEvent("refresh_quick_battle" , function(flag)
        if self.channel_info.enable_quick_battle then
            self:LoadQuickBattleInfo()
        end
    end)
    
end

function exploring_panel:RegisterWidgetEvent()

    --打开背包
    self.bag_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "bag_panel" )
        end
    end)

    self.event_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local event_conf = config_manager.event_config[adventure_logic.cur_maze_template_info.event_id]
            local event_type = event_conf["event_type"]

            if adventure_logic.maze_event_status == MAZE_EVENT_STATUS["explored_but_not_solve"] then
                --解决事件
                graphic:DispatchEvent("show_world_sub_panel", "event_panel", event_type, event_conf.ID)

            elseif adventure_logic.maze_event_status == MAZE_EVENT_STATUS["not_start_explore"]  then
                graphic:DispatchEvent("show_prompt_panel", "adventure_event_not_start_explore")

            else

                --事件已经解决，尝试进入下一区域
                if adventure_logic.can_enter_next_area and adventure_logic:IsMazeNew(adventure_logic.next_maze_id) then
                    local next_maze_template_info = config_manager.adventure_maze_config[adventure_logic.next_maze_id]
                    local income_info = config_manager.adventure_income_config[next_maze_template_info.income_id]
                    local area_conf = config_manager.area_info_config[income_info.area_id]
                    graphic:DispatchEvent("show_world_sub_panel", "bp_limit_msgbox", area_conf, adventure_logic.next_maze_id)
                else
                    adventure_logic:EnterNextMaze()
                end
            end
        end
    end)

    --选择区域
    self.area_choose_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "area_choose_sub_scene" )
        end
    end)

    --分配经验
    self.levelup_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if user_logic:IsFeatureUnlock(FEATURE_TYPE["alloc_exp"]) then
                graphic:DispatchEvent("show_world_sub_scene", "mercenary_levelup_sub_scene")
            end
        end
    end)

    --开启宝箱
    self.open_box_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if user_logic:IsFeatureUnlock(FEATURE_TYPE["explore_box"]) then

                if adventure_logic.cur_maze_info["box_num"] <= 0 then
                    graphic:DispatchEvent("show_world_sub_panel", "loot_result_panel", 0)

                else
                    adventure_logic:OpenBox()
                end
            end
        end
    end)

    --选择难度
    self.area_info_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if difficulty_panel:IsVisible() then
                difficulty_panel:Hide()
            else
                difficulty_panel:Show(self.cur_area_id)
            end
        end
    end)

    local enter_maze_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            local maze_id = widget:getTag()
            audio_manager:PlayEffect("click")
            adventure_logic:EnterMaze(maze_id)
        end
    end

    for i = 1, 5 do
        local sub_panel = self.maze_sub_panels[i]
        sub_panel.root_node:addTouchEventListener(enter_maze_method)
    end

    --查看掉落信息
    self.loot_btn:setTouchEnabled(true)
    self.loot_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "loot_preview_panel", self.cur_area_id, self.cur_difficulty)
        end
    end)

    local choose_difficulty = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            difficulty_panel:Hide()

            local difficulty = widget:getTag()
            if difficulty == self.cur_difficulty then
                return
            end

            self:LoadInfo(self.cur_area_id, difficulty)
        end
    end

    for i = 1, 3 do
        local btn = difficulty_panel.btns[i]
        btn:setTag(i)
        btn:addTouchEventListener(choose_difficulty)
    end

    local img = difficulty_panel.root_node:getChildByName("shadow")
    img:setTouchEnabled(true)

    img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            difficulty_panel:Hide()
        end
    end)

    -- 打开佣兵评论窗口
    self.open_comment_msgbox_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            chat_logic:QueryCommentList(COMMENT_TYPE, adventure_logic.cur_maze_id)
        end
    end)

    --快速战斗
    self.quick_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if user_logic:IsFeatureUnlock(FEATURE_TYPE["quick_adventure"]) then

                local adventure_buy_config = config_manager.adventure_buy_config
                local next_info = adventure_buy_config[adventure_logic.buy_adventure_num + 1]

                --总次数购买完成
                if not next_info then
                    graphic:DispatchEvent("show_prompt_panel", "quick_battle_not_enough_all_num")
                else
                    --下一次需要月卡购买了
                    if next_info.month_card > 0 and not vip_logic:IsActivated(constants.VIP_TYPE["adventure"]) then
                        graphic:DispatchEvent("show_prompt_panel", "quick_battle_not_enough_num")
                    else
                        --打开面板
                        graphic:DispatchEvent("show_world_sub_panel", "quick_battle_panel")
                    end
                end
            end
        end
    end)
end

return exploring_panel
