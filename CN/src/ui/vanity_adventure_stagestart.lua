local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"
local troop_logic = require "logic.troop"
local graphic = require "logic.graphic"
local constants = require "util.constants"
local lang_constants = require "util.language_constants"
local config_manager = require "logic.config_manager"
local role_prototype = require "entity.ui_role"
local common_function_util = require "util.common_function"
local icon_template = require "ui.icon_panel"
local utils = require "util.utils"
local client_constants = require "util.client_constants"
local time_logic = require "logic.time"

local vanity_adventure_stagestart = panel_prototype.New(true)
function vanity_adventure_stagestart:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/vanity_adventure_stagestart.csb")
    --调整阵容按钮
    self.formation_btn = self.root_node:getChildByName("formation_btn")
    --开始战斗按钮
    self.start_battle_btn = self.root_node:getChildByName("confirm_btn")

    --boss详情和情报按钮
    self.more_btn = self.root_node:getChildByName("skill_btn")
    self.more_btn_text = self.more_btn:getChildByName("desc")
    self.more_btn_state = 1  --更多按钮状态

    --boss描述
    self.maze_desc_node = self.root_node:getChildByName("boss")
    self.maze_more_desc_node = self.root_node:getChildByName("enemy_template")
    self.maze_desc_node:setVisible(false)
    self.maze_more_desc_node:setVisible(false)

    --boss动画节点
    self.boss_node = self.maze_desc_node:getChildByName("boss")
    self.boss_node:setScale(1)

    --获得奖励
    self.cost_node = self.root_node:getChildByName("cost")
    local cost_icon = self.cost_node:getChildByName("cost1")
    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["with_text1"])
    self.icon_panel:Init(cost_icon, false)

    --剩余多少佣兵可以上阵文本
    self.have_mercenary_num_tips_text = self.root_node:getChildByName("txt_mercenary")
    --boss技能模板
    self.skill_template = self.maze_more_desc_node:getChildByName("skill_template")
    self.skill_template:setVisible(false)
    --boss滚动列表
    self.skill_list = self.maze_more_desc_node:getChildByName("scrol_view")
    self.item_height = self.skill_template:getContentSize().height
    self.list_width = self.skill_list:getContentSize().width
    self.list_height = self.skill_list:getContentSize().height

    --关卡名字文本
    self.title_name_text = self.root_node:getChildByName("title_name")

    self.role =  nil
    self.maze_id = 1
    self:RegisterWidgetEvent()
end

-- maze_id  关卡id
function vanity_adventure_stagestart:Show(maze_id)
	self.maze_id = maze_id or self.maze_id
    self.root_node:setVisible(true)
    self:SetMoreBtnState(1)
    self:LoadMazeId()
end

--加载关卡信息
function vanity_adventure_stagestart:LoadMazeId()
    --关卡配表信息
    local week = utils:getWDay(time_logic:Now())
    local vanity_maze_conf = config_manager.vanity_maze_config[week]
    self.maze_conf = nil
    for k,v in pairs(vanity_maze_conf) do
        if v.map_id == self.maze_id then
            --找到当前关卡
            self.maze_conf = v
            break
        end
    end

    if self.maze_conf then
        --设置关卡npc描述
        local maze_desc = self.maze_desc_node:getChildByName("desc_0")
        maze_desc:setString(self.maze_conf.npc_speak)

        --设置关卡名字
        self.title_name_text:setString(self.maze_conf.name)

        if self.role == nil then
            -- 创建一个boss动画
            self.role = role_prototype.New()
            self.shadow_node = cc.Sprite:create("res/role/shadow.png")
            self.shadow_node:setVisible(false)
            self.boss_node:addChild(self.shadow_node)
            self.boss_sp = cc.Sprite:create()
            self.boss_node:addChild(self.boss_sp)
        end

        --boss配置信息
        local monster_config = config_manager.monster_config[self.maze_conf.boss_id]
        --boss精灵
        local monster_sprites = common_function_util.Split(monster_config.monster_sprites, '|')
        --加载boss到动画上
        self.role:Init(self.boss_sp, monster_sprites[1],self.shadow_node)
        --设置boss的位置
        self.role.sprite:setAnchorPoint(cc.p(0.5,0))
        self.role.sprite:setPosition(cc.p(self.boss_node:getContentSize().width/2,-4))
        self.shadow_node:setPosition(cc.p(self.boss_node:getContentSize().width/2,self.shadow_node:getContentSize().height/4-4))
        self.role:WalkAnimation(1)  --行走动画

        --通关可以获得的奖励
        self.icon_panel:Show(constants["REWARD_TYPE"].resource, constants["RESOURCE_TYPE"].vanity_adventure, self.maze_conf.win_integral)

        --加载boss技能
        self:LoadBossSkill(monster_config)
    end

    --还剩余多少可以上阵的文本显示
    self.have_mercenary_num_tips_text:setString(string.format(lang_constants:Get("have_mercenary_num_tips"),troop_logic:GetVanityCanUseNumber()))

end

--加载boss信息
function vanity_adventure_stagestart:LoadBossSkill(monster_config)
    --四维信息
    local property_node = self.maze_more_desc_node:getChildByName("enemy_property")
    local speed_text = property_node:getChildByName("speed_value")   --先攻
    local defense_text = property_node:getChildByName("defense_value")  --防御
    local dodge_text = property_node:getChildByName("dodge_value")   --闪避
    local authority_text = property_node:getChildByName("authority_value")  --王者
    local battle_text = property_node:getChildByName("bp_value")  --战力

    speed_text:setString(monster_config.speed)
    defense_text:setString(monster_config.defense)
    dodge_text:setString(monster_config.dodge)
    authority_text:setString(monster_config.authority)
    panel_util:ConvertUnit(monster_config.battle_point, battle_text)

    --加载技能之前移除之前的技能节点
    self.skill_list:removeAllChildren()
    if monster_config.skill then
        --有技能
        local num = 0
        local max_height = 0
        local skill_group = {}
        for skill_id in string.gmatch(monster_config.skill, "%d+") do
            if skill_group[skill_id] == nil then
                skill_group[skill_id] = 1
                num = num + 1
                max_height = max_height + self.item_height
            else
                skill_group[skill_id] = skill_group[skill_id] + 1
            end
        end

        local max_num = num
        --将每一个技能添加到滚动容器中
        for k, v in pairs(skill_group) do
            local skill_info = panel_util:GetSkillInfo(tonumber(k))
            if skill_info then
                local item = self.skill_template:clone()
                item:setVisible(true)
                local name_text = item:getChildByName("name")
                name_text:setString(string.format(lang_constants:Get("campaign_event_enemy_skill"), max_num - num + 1, skill_info.name))

                local desc_text = item:getChildByName("desc")
                desc_text:setString(skill_info.desc)
                item:setPositionY(max_height - (max_num - num) * item:getContentSize().height)
                self.skill_list:addChild(item)
                num = num - 1
            end
        end

        --设置滚动容器的大小
        if max_height > self.list_height then
            self.skill_list:setInnerContainerSize(cc.size(self.list_width, max_height))
        else 
            self.skill_list:setInnerContainerSize(cc.size(self.list_width, self.list_height))
        end
    end

end

--设置描述和详情状态
function vanity_adventure_stagestart:SetMoreBtnState(state)
    self.more_btn_state = state
    self.maze_desc_node:setVisible(self.more_btn_state == 1)
    self.maze_more_desc_node:setVisible(self.more_btn_state ~= 1)
    self.more_btn_text:setString(lang_constants:Get(string.format("vanity_more_btn_desc%d",self.more_btn_state)))
    self.cost_node:setVisible(self.more_btn_state == 1)
    self.have_mercenary_num_tips_text:setVisible(self.more_btn_state ~= 1)
end

function vanity_adventure_stagestart:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("back_btn"), self:GetName())

    --阵容按钮
    self.formation_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            graphic:DispatchEvent("show_world_sub_scene", "vanity_adventure_sub_scene", nil, self.maze_id)
        end
    end)

    --详情和描述按钮
    self.more_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.more_btn_state == 1 then
                self:SetMoreBtnState(2)
            else
                self:SetMoreBtnState(1)
            end
        end
    end)

    --开始战斗按钮
    self.start_battle_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local is_null_formation = true
            for i,v in ipairs(troop_logic.vanity_troop) do
                if v ~= 0 then
                    is_null_formation = false
                    break
                end
            end
            --判断阵容是否为空，如果为空直接跳转到阵容调整界面
            if is_null_formation then
                graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
                graphic:DispatchEvent("show_world_sub_scene", "vanity_adventure_sub_scene", nil, self.maze_id)
            else
                graphic:DispatchEvent("show_world_sub_panel", "vanity_adventure_msgbox_boss", self.maze_id)
            end
        end
    end)
end

return vanity_adventure_stagestart

