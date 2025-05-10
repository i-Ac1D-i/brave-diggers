local panel_prototype = require "ui.panel"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local time_logic = require "logic.time"
local user_logic = require "logic.user"
local icon_panel = require "ui.icon_panel"

local item_config = config_manager.item_config
local resource_config = config_manager.resource_config

local client_constants = require "util.client_constants"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"
local panel_util = require "ui.panel_util"
local mine_logic = require "logic.mine"
local troop_logic = require "logic.troop"

local SMALL_QUALITY_BG = client_constants["SMALL_QUALITY_BG"]
local RESOURCE_TYPE = constants["RESOURCE_TYPE"]
local REWARD_TYPE = constants["REWARD_TYPE"]

local PLIST_TYPE = ccui.TextureResType.plistType
local BG_COLOR_MAP = client_constants["BG_QUALITY_COLOR"]
local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]


local mine_plunder_panel = panel_prototype.New(true)
function mine_plunder_panel:Init()
    --加载csb
    self.root_node = cc.CSLoader:createNode("ui/mine_plunder_panel.csb")
    self.template = self.root_node:getChildByName("template")
    self.icon_panel = icon_panel.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(self.template)
    self.icon_panel:SetPosition(60, 60)
    self.name_text = self.template:getChildByName("name")
    self.battle_point_text = self.template:getChildByName("bp_value")
    self.plunder_btn = self.root_node:getChildByName("canel_btn") -- 掠夺按钮
    self.steal_btn = self.root_node:getChildByName("confirm_btn")  --偷窃按钮

    self.close_btn = self.root_node:getChildByName("back_btn")

    self.formation_btn = self.root_node:getChildByName("arrange_mercenary_pos_btn")

    self.remain_count_text = self.root_node:getChildByName("times"):getChildByName("times_0")

    self.mine_level_img = self.template:getChildByName("Image_37")  --矿山等级icon

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function mine_plunder_panel:Show(index)
    self.root_node:setVisible(true)
    self.index = index
    local rob_target_info = mine_logic.rob_target_list
    local rob_conf = rob_target_info[index]
    if rob_conf then
        self.user_id = rob_conf.user_id
        self.mine_index = rob_conf.mine_index
        local template_id = rob_conf.troop_info.template_id_list[1]
        self.icon_panel:Show(constants["REWARD_TYPE"]["mercenary"], template_id, nil, nil, false)
        self.name_text:setString(rob_conf.leader_name)
        self.battle_point_text:setString(rob_conf.battle_point)

        --剩余次数
        self.remain_count = math.max(constants["MINE_BE_ROBBED_MAX_TIMES"] - rob_conf.be_robbed_times, 0)
        self.remain_count_text:setString(self.remain_count)

        self.mine_level_img:loadTexture(client_constants["MINE_TYPE_IMG_PATH"][rob_conf.mine_level], PLIST_TYPE)

    end
end

function mine_plunder_panel:Update(elapsed_time)
    
end

function mine_plunder_panel:RegisterEvent()
    -- graphic:RegisterEvent("buy_limite_success", function()
    --     self.jumpToTop = true
    --     --购买成功后
    --     self:UpdateScrollView() --刷新视图
    --     --关闭掉自己 触发机制用的
    --     graphic:DispatchEvent("hide_world_sub_panel", "time_limit_reward_msgbox_panel")
    -- end)
    -- graphic:RegisterEvent("update_limite_state", function()
    --     self.jumpToTop = true
    --     self:UpdateScrollView()
    -- end)
end

function mine_plunder_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), "mine_plunder_panel")

    self.close_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)

    --掠夺按钮
    self.plunder_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.remain_count > 0 and mine_logic.remain_rob > 0 then
                mine_logic:MineRobTarget(client_constants.ROB_TYPE.rob, self.user_id, self.mine_index)
                graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            elseif mine_logic.remain_rob <= 0 then
                graphic:DispatchEvent("show_prompt_panel", "no_rob_times")
            else
                graphic:DispatchEvent("show_prompt_panel", "target_be_robbed_to_much_times")
            end
        end
    end)

    --偷窃按钮
    self.steal_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.remain_count > 0 then
                mine_logic:MineRobTarget(client_constants.ROB_TYPE.steal, self.user_id, self.mine_index)
                graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            elseif mine_logic.remain_rob <= 0 then
                graphic:DispatchEvent("show_prompt_panel", "no_rob_times")
            else
                graphic:DispatchEvent("show_prompt_panel", "target_be_robbed_to_much_times")
            end
        end
    end)

    --掠夺整容按钮
    self.formation_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if not troop_logic:CheckMercenaryLimiteOverTime() then
                graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
                graphic:DispatchEvent("show_world_sub_scene", "formation_sub_scene", SCENE_TRANSITION_TYPE["none"], client_constants["FORMATION_PANEL_MODE"]["multi"], self:GetName(), {self.index})
            end
        end
    end)
end

return mine_plunder_panel
