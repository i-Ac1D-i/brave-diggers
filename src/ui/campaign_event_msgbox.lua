local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local campaign_logic = require "logic.campaign"
local constants = require "util.constants"
local lang_constants = require "util.language_constants"
local troop_logic = require "logic.troop"
local common_function_util = require "util.common_function"
local panel_util = require "ui.panel_util"
local icon_template = require "ui.icon_panel"
local graphic = require "logic.graphic"
local time_logic = require "logic.time"
local mining_logic = require "logic.mining"
local client_constants = require "util.client_constants"
local config_manager = require "logic.config_manager"
local audio_manager = require "util.audio_manager"

local campaign_level_config = config_manager.campaign_level_config
local monster_config = config_manager.monster_config

local PLIST_TYPE = ccui.TextureResType.plistType
local RESOURCE_TYPE = constants.RESOURCE_TYPE

local ICON_TEMPLATE_MODE = client_constants["ICON_TEMPLATE_MODE"]
local BATTLE_COST_ICON = client_constants["CAMPAIGN_RESOURCE_ICON"]["battle"]
local POINT_ICON = client_constants["CAMPAIGN_RESOURCE_ICON"]["score"]
local EXP_ICON = client_constants["CAMPAIGN_RESOURCE_ICON"]["exp"]
local PICKAXE_COST_ICON = "icon/global/ore_picks.png"

local DEMON_COST_ICON = config_manager.resource_config[RESOURCE_TYPE["demon_medal"]].icon

local CAMPAIGN_MSGBOX_MODE = client_constants.CAMPAIGN_MSGBOX_MODE

local COST_NODE_NUM = 2

local campaign_icon_node = panel_prototype.New()
campaign_icon_node.__index = campaign_icon_node

function campaign_icon_node.New()
    local t = {}
    return setmetatable(t, campaign_icon_node)
end

function campaign_icon_node:Init(root_node, index, tip_hide)
    local tip_hide = tip_hide or false
    self.icon_panel = icon_template.New()
    self.root_node = root_node
    self.icon_panel:Init(self.root_node, tip_hide)
    self.index = index 
end

function campaign_icon_node:ToShow(config_data)
    self.icon_panel:Show(config_data.reward_type, config_data.param1, false, false, false)
end

function campaign_icon_node:HideText()
    self.icon_panel.num_text:setVisible(false)
end

function campaign_icon_node:LoadIcon(resource, cost_content)
    self.icon_panel:Load("", resource, 1, cost_content, "", "", false)
end

function campaign_icon_node:SetTextColor(color)
    self.icon_panel.num_text:setColor(panel_util:GetColor4B(color))
end

function campaign_icon_node:SetTextString(text_content)
    self.icon_panel.num_text:setString(text_content)
end

function campaign_icon_node:AddTouchEvent(tag, event)
    self.icon_panel.icon_img:setTag(tag)
    self.icon_panel.icon_img:setTouchEnabled(true)
    self.icon_panel.icon_img:addTouchEventListener(event)
end

local campaign_event_msgbox = panel_prototype.New(true)
function campaign_event_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/campaign_event_panel.csb")
    local root_node = self.root_node

    self.back_btn = root_node:getChildByName("back_btn")
    self.formation_btn = self.root_node:getChildByName("formation_btn")

    self.campaign_node = root_node:getChildByName("campaign_node")

    self.skill_list = self.root_node:getChildByName("skill_node")

    self.battle_btn = root_node:getChildByName("confirm_btn")

    self.title_text = root_node:getChildByName("title_name")

    self.desc_text = self.campaign_node:getChildByName("desc")
    self.times_desc_text = self.campaign_node:getChildByName("times_desc")
    self.reward_desc_text = self.campaign_node:getChildByName("reward_desc")
    self.shadow_img = self.campaign_node:getChildByName("shadow")

    self.cost_node_all = self.root_node:getChildByName("cost")
    self.cost_node = {}
    for i = 1, COST_NODE_NUM do 
        local cost_node = campaign_icon_node.New()
        cost_node:Init(self.cost_node_all:getChildByName("cost" .. i), i, true)
        self.cost_node[i] = cost_node
    end
   
    self.enemy_template = self.root_node:getChildByName("enemy_template")
    self.enemy_template:setVisible(false)

    self.skill_template = self.root_node:getChildByName("skill_template")
    self.skill_template:setVisible(false)

    self.reward_list = self.campaign_node:getChildByName("reward_list")
    
    local reward_template = self.reward_list:getChildByName("reward_template")
    reward_template:setVisible(false)

    self.switch_btn = self.root_node:getChildByName("skill_btn")

    self.switch_type = 0

    self.level_info = nil
    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function campaign_event_msgbox:ShowCampaign(level_data)
    self.level_info = level_data or self.level_info
    local level_info = self.level_info

    local level_id = level_info.level_id

    self.times_desc_text:setString(lang_constants:Get("campaign_battle_desc"))
    if level_info.is_boss ~= 1 then
        --非BOSS关可以重复打
        self.times_desc_text:setVisible(true)
    else
        self.times_desc_text:setVisible(false)
    end

    local level_title = campaign_level_config[level_id].title
    local level_desc = campaign_level_config[level_id].desc

    self.title_text:setString(level_title)
    self.desc_text:setString(level_desc)

    self:UpdateRewardList()
    self:UpdateCostNode()

    self.skill_list:removeAllChildren()

    --敌方情报
    self:LoadEnemyInfo(level_info.monster_id, lang_constants:Get("campaign_event_enemy_skill"))

    --我方阵容
    self:LoadFormationInfo()

    self.switch_type = 0
    self:SwitchPanel()

    self.battle_btn:setColor(panel_util:GetColor4B(0xffffff))
    if time_logic:Now() < level_info.next_battle_time then
        self.is_countdown = true
    else
        self.battle_btn:setTitleText(lang_constants:Get("adventure_event_dialogue_finish"))
    end
end

function campaign_event_msgbox:CheckResource(left, right)
    local color_value = 0xa1e01b
    if left < right then 
        color_value = 0xf87f26
    end

    return color_value
end

function campaign_event_msgbox:UpdateCostNode()
   
    if self.mode == CAMPAIGN_MSGBOX_MODE["boss_cave"] then 
       self.cost_node[2]:Hide()
       
       local demon_medal_counts = resource_logic:GetResourcenNumByName("demon_medal")
       local need_demon_counts = constants["CAVE_BOSS_CHALLANGE_SUB"]
       
       self.cost_node[1]:LoadIcon(DEMON_COST_ICON, string.format(lang_constants:Get("mining_cave_boss_bp_desc"), panel_util:ConvertUnit(demon_medal_counts), panel_util:ConvertUnit(need_demon_counts)))

       self.cost_node[1]:SetTextColor(self:CheckResource(demon_medal_counts, need_demon_counts))
       
    elseif self.mode == CAMPAIGN_MSGBOX_MODE["normal_cave"] then 
        self.cost_node[2]:Show()
        local challenge_counts = mining_logic.cave_challenge_nums[self.event_data.cave_type]
        local need_cost = 1
        local pickaxe_counts = mining_logic.dig_count
        local need_pickaxe_counts = self.event_data.pickaxe_count

        self.cost_node[1]:LoadIcon(BATTLE_COST_ICON, string.format(lang_constants:Get("mining_cave_boss_bp_desc"), panel_util:ConvertUnit(challenge_counts), panel_util:ConvertUnit(need_cost)) )
        self.cost_node[2]:LoadIcon(PICKAXE_COST_ICON, string.format(lang_constants:Get("mining_cave_boss_bp_desc"), panel_util:ConvertUnit(pickaxe_counts), panel_util:ConvertUnit(need_pickaxe_counts)))

        self.cost_node[1]:SetTextColor(self:CheckResource(challenge_counts, need_cost))
        self.cost_node[2]:SetTextColor(self:CheckResource(pickaxe_counts, need_pickaxe_counts))
    else
        self.cost_node[2]:Hide() 
        self.cost_node[1]:LoadIcon(BATTLE_COST_ICON, campaign_logic.challenge_num .. "/1")
    end
end

function campaign_event_msgbox:UpdateRewardList()
    local default_desc = lang_constants:Get("campaign_event_msgbox_reward_desc")
    self.reward_list:removeAllChildren()
    self.reward_list:setTouchEnabled(false)
    self.reward_list:setItemsMargin(15)
    self.reward_nodes = {}

    if self.mode == CAMPAIGN_MSGBOX_MODE["normal_cave"] or self.mode == CAMPAIGN_MSGBOX_MODE["boss_cave"] then 
       local reward_data = mining_logic:GetCaveConfigData(self.event_data.cave_type, self.event_data.level)
       if reward_data then 
           for k,v in pairs(reward_data) do
              local reward_node = campaign_icon_node.New()
              reward_node:Init(self.reward_list, k, false)
              reward_node:ToShow(v)
              reward_node:HideText()
              self.reward_nodes[k] = reward_node  
           end
           self.reward_list:setTouchEnabled(true)
           self.reward_list:refreshView()
       end
       default_desc = lang_constants:Get("mining_battle_reward_desc")
    else
        local level_info = self.level_info
        for reward_count = 1, 2 do 
            local reward_node = campaign_icon_node.New()
            reward_node:Init(self.reward_list, reward_count, true)
            self.reward_nodes[reward_count] = reward_node  
        end
        self.reward_list:setTouchEnabled(true)
        self.reward_list:refreshView()
        self.reward_nodes[1]:LoadIcon(POINT_ICON, tostring(level_info.reward_score))
        self.reward_nodes[1]:AddTouchEvent(constants.CAMPAIGN_RESOURCE["score"], self.view_resource_method)
  
        self.reward_nodes[2]:LoadIcon(EXP_ICON, tostring(level_info.reward_exp))
        self.reward_nodes[2]:AddTouchEvent(constants.CAMPAIGN_RESOURCE["exp"], self.view_resource_method)
    end

    self.reward_desc_text:setString(default_desc)
end

function campaign_event_msgbox:ShowCaveEvent()
    local cave_data = self.event_data
    local title_name = cave_data.name
    local cave_desc = cave_data.desc

    self.title_text:setString(title_name)
    self.times_desc_text:setVisible(false)
    self.desc_text:setString(cave_desc)

    self:UpdateRewardList()
    self:UpdateCostNode()
    
    self.skill_list:removeAllChildren()

    self:LoadEnemyInfo(cave_data.monster_id, lang_constants:Get("campaign_event_enemy_skill"))

    --我方阵容
    self:LoadFormationInfo()

    self.switch_type = 0
    self:SwitchPanel()

    self.battle_btn:setColor(panel_util:GetColor4B(0xffffff))
    self.battle_btn:setTitleText(lang_constants:Get("adventure_event_dialogue_finish"))
    
end

function campaign_event_msgbox:ShowCaveBossEvent()
    local cave_data = self.event_data
    local title_name = cave_data.name
    local cave_desc = cave_data.desc

    self.title_text:setString(title_name)
    self.times_desc_text:setVisible(true)
    self.desc_text:setString(cave_desc)

    local begin_time = time_logic:Now() - (mining_logic.cave_boss_end_time - constants["CAVE_BOSS_CHALLANGE_DAY"])
    local days = time_logic:GetDaysBySeconds(begin_time)
    self.times_desc_text:setString(lang_constants:Get("mining_battle_cave_boss_time_desc"))

    self:UpdateRewardList()
    self:UpdateCostNode()

    self.skill_list:removeAllChildren()

    self:LoadEnemyInfo(cave_data.monster_id, lang_constants:Get("campaign_event_enemy_skill"))

    self:LoadSkillLimit(cave_data.skill_limit)

    --我方阵容
    self:LoadFormationInfo()

    self.switch_type = 0
    self:SwitchPanel()

    -- local genre_table = common_function_util.Split(cave_data.genre_limit, '|')
    -- if troop_logic:CheckGenreLimit(genre_table) then
    --     local genre_text = ""
    --     for k, v in ipairs(genre_table) do
    --         local temp_name = lang_constants:Get("mercenary_genre" .. tostring(v))
    --         genre_text = genre_text .. temp_name
    --     end
    --     self.battle_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
    --     self.battle_btn:setTitleText(string.format(lang_constants:Get("mining_battle_cave_boss_genre_limit_text"), genre_text))

    -- else
    self.battle_btn:setColor(panel_util:GetColor4B(0xffffff))
    self.battle_btn:setTitleText(lang_constants:Get("adventure_event_dialogue_finish"))
   
end 

function campaign_event_msgbox:Show(mode, data)
    self.mode = mode
    
    self.root_node:setVisible(true)
    self.is_countdown = false

    if self.mode == CAMPAIGN_MSGBOX_MODE["boss_cave"] then 
        self.event_data = data
        self:ShowCaveBossEvent()

    elseif self.mode == CAMPAIGN_MSGBOX_MODE["normal_cave"] then 
        self.event_data = data  
        self:ShowCaveEvent()

    elseif self.mode == CAMPAIGN_MSGBOX_MODE["campaign"] then
        self:ShowCampaign(data)
    end
end

function campaign_event_msgbox:LoadSkillLimit(skill_limit)
    if skill_limit then 
        local skill_table = common_function_util.Split(skill_limit, '|')
      
        local item = self.skill_template:clone()
        item:setVisible(true)
        local name_text = item:getChildByName("name")
        name_text:setString(lang_constants:Get("skill_limit_title"))
        local desc_text = item:getChildByName("desc")
        local skill_limit_desc = ""
        for k, v in pairs(skill_table) do  
            local desc = tostring(k) .. '.' .. lang_constants:Get("skill_limit" .. tostring(v))
            if k == 1 then 
                skill_limit_desc = desc 
            else
                skill_limit_desc = skill_limit_desc .. "\n" .. desc 
            end
        end
        desc_text:setString(skill_limit_desc)
        self.skill_list:pushBackCustomItem(item)

        local margin_node = ccui.Widget:create()
        local size = self.skill_template:getContentSize()
        size.height = size.height / 2
        margin_node:setContentSize(size)
        self.skill_list:pushBackCustomItem(margin_node)
    end
end 

function campaign_event_msgbox:LoadEnemyInfo(monster_id, desc)
    local enemy_item = self.enemy_template:clone()
    enemy_item:setVisible(true)

    local enemy_property = enemy_item:getChildByName("enemy_property")
    local monster = monster_config[monster_id]
    local battle_point = monster.battle_point

    if self.mode == CAMPAIGN_MSGBOX_MODE["boss_cave"] then 
        battle_point = self.event_data.max_bp
    end

    enemy_property:getChildByName("speed_value"):setString(monster.speed)
    enemy_property:getChildByName("defense_value"):setString(monster.defense)
    enemy_property:getChildByName("dodge_value"):setString(monster.dodge)
    enemy_property:getChildByName("authority_value"):setString(monster.authority)
    enemy_property:getChildByName("bp_value"):setString(panel_util:ConvertUnit(battle_point))

    self.skill_list:pushBackCustomItem(enemy_item)

    -- 敌方技能情报
    local num = 1
    local skill_group = {}
    for skill_id in string.gmatch(monster.skill, "%d+") do
        skill_group[skill_id] = skill_group[skill_id] and skill_group[skill_id] + 1 or 1
    end

    for k, v in pairs(skill_group) do
        local skill_info = panel_util:GetSkillInfo(tonumber(k))
        if skill_info then
            local item = self.skill_template:clone()
            item:setVisible(true)
            local name_text = item:getChildByName("name")
            name_text:setString(string.format(desc .." x"..v, num, skill_info.name))

            local desc_text = item:getChildByName("desc")
            desc_text:setString(skill_info.desc)
            self.skill_list:pushBackCustomItem(item)
            num = num + 1
        end
    end
end

function campaign_event_msgbox:LoadFormationInfo()
    local const_str = lang_constants:Get("mercenary_adjust_formation") .. ": " 
    local formation_str = string.format(lang_constants:Get("mercenary_cur_formation"), troop_logic:GetCurFormationId())
    self.formation_btn:setTitleText(const_str..formation_str)
end

function campaign_event_msgbox:Update(elapsed_time)
    if not self.is_countdown then
        return
    end

    local t_now = time_logic:Now()
    self.battle_btn:setColor(panel_util:GetColor4B(0xffffff))
    if t_now < self.level_info.next_battle_time then
        local diff_time = self.level_info.next_battle_time - t_now
        self.battle_btn:setTitleText(string.format(lang_constants:Get("campaign_level_cd"), math.ceil(diff_time).."s"))
    else
        self.battle_btn:setTitleText(lang_constants:Get("adventure_event_dialogue_finish"))
        self.is_countdown = false
    end
end

-- 选择面板
function campaign_event_msgbox:SwitchPanel()
    self.campaign_node:setVisible(false)
    self.skill_list:setVisible(false)

    local desc_text = self.switch_btn:getChildByName("desc")

    if self.switch_type == 0 then
        self.campaign_node:setVisible(true)
        desc_text:setString(lang_constants:Get("campaign_event_skill"))
        self.switch_type = 1
    else
        desc_text:setString(lang_constants:Get("campaign_event_desc"))
        self.skill_list:setVisible(true)
        self.switch_type = 0
    end
end

function campaign_event_msgbox:RegisterEvent()
    graphic:RegisterEvent("update_campaign_event", function()
        if self.root_node:isVisible() then
           self.cost_node[1]:SetTextString(campaign_logic.challenge_num .. "/1")
        end
    end)

    graphic:RegisterEvent("change_troop_formation", function()
        if not self.root_node:isVisible() then
            return
        end
        
        self:LoadFormationInfo()
    end)

    graphic:RegisterEvent("reload_campaign_cave_event", function()
        if self.root_node:isVisible() and self.mode == CAMPAIGN_MSGBOX_MODE["normal_cave"] then
           self:ShowCaveEvent()
        end
    end)
end

function campaign_event_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.back_btn, self:GetName())

    -- 选择页面
    self.switch_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:SwitchPanel()
        end
    end)

    self.battle_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if self.mode == CAMPAIGN_MSGBOX_MODE["boss_cave"] then 
                mining_logic:ChallengeCaveBoss()

            elseif self.mode == CAMPAIGN_MSGBOX_MODE["normal_cave"] then
                if mining_logic:SolveCaveEvent(self.event_data) then
                    graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
                end

            elseif self.mode == CAMPAIGN_MSGBOX_MODE["campaign"] then
                if time_logic:Now() < self.level_info.next_battle_time then
                    local mode = client_constants.CONFIRM_MSGBOX_MODE["revive_campaign"]
                    graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode, constants.CAMPAIGN_REVIVE_VALUE)

                else
                    campaign_logic:SolveEvent()
                end
            end
        end
    end)

    -- 合战属性描述
    self.view_resource_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            local pos = widget:getTouchBeganPosition()
            local name, desc

            if widget:getTag() == constants.CAMPAIGN_RESOURCE["exp"] then
                name = lang_constants:Get("campaign_res_exp")
                desc = lang_constants:Get("campaign_res_exp_desc")
            
            else
                name = lang_constants:Get("campaign_res_score")
                desc = lang_constants:Get("campaign_res_score_desc")
            end

            graphic:DispatchEvent("show_floating_panel", name, desc, pos.x, pos.y)

        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            graphic:DispatchEvent("hide_floating_panel")
        end
    end

    -- 切换阵容
    self.formation_btn:addTouchEventListener(function (widget, event_type)
        -- body
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local trans_type = constants["SCENE_TRANSITION_TYPE"]["none"]
            local mode = client_constants["FORMATION_PANEL_MODE"]["multi"]
            local back_panel = self:GetName()
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())

            if self.mode == CAMPAIGN_MSGBOX_MODE["boss_cave"] or self.mode == CAMPAIGN_MSGBOX_MODE["normal_cave"]  then 
                local ex_params = { self.mode, self.event_data }
                graphic:DispatchEvent("show_world_sub_scene", "formation_sub_scene", trans_type, true, mode, back_panel, ex_params)   
            else
                local ex_params = { self.mode, self.level_info }
                graphic:DispatchEvent("show_world_sub_scene", "formation_sub_scene", trans_type, true, mode, back_panel, ex_params)  
            end    
        end
    end)

end

return campaign_event_msgbox
