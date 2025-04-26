local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"
local lang_constants = require "util.language_constants"
local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local achievement_logic = require "logic.achievement"
local constants = require "util.constants"

local SORT_TYPE = client_constants["SORT_TYPE"]
local PLIST_TYPE = ccui.TextureResType.plistType
local ROLE_IMG_ID = "11000014"
local formation_recommend_panel = panel_prototype.New(true)

local BOTTOM_BUTTON_Y = 689

local BG_SIZE_HEIGHT_SHORT = 328
local BG_SIZE_HEIGHT_LONG = 497

function formation_recommend_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/formation_recommend_panel.csb")
    self.bg_img = self.root_node:getChildByName("bg")
    self.bg_width = self.bg_img:getContentSize().width
    --head section
    self.role_img = self.root_node:getChildByName("role_icon")
    self.role_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] ..ROLE_IMG_ID .. ".png", PLIST_TYPE)
    self.shadow_img = self.root_node:getChildByName("shadow")
    self.text_img = self.root_node:getChildByName("txtbg")
    self.desc_text = self.root_node:getChildByName("desc")

    self.cancel_btn = self.root_node:getChildByName("cancel_btn")
    self.confirm_btn = self.root_node:getChildByName("confirm_btn")
    self.confirm_btn.recommend_type = 0
    self.crit_btn = self.root_node:getChildByName("crit_btn")
    self.crit_btn.recommend_type = 1
    self.recovery_btn = self.root_node:getChildByName("recovery_btn")
    self.recovery_btn.recommend_type = 2
    self.pure_btn = self.root_node:getChildByName("pure_btn")
    self.pure_btn.recommend_type = 3

    self.use_mode = 1
    self:RegisterWidgetEvent()
end

function formation_recommend_panel:FixHeadSectionPositionY()
    self.role_img = self.root_node:getChildByName("role_icon")
    self.role_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] ..ROLE_IMG_ID .. ".png", PLIST_TYPE)
    self.shadow_img = self.root_node:getChildByName("shadow")
    self.text_img = self.root_node:getChildByName("txtbg")
    self.desc_text = self.root_node:getChildByName("desc")
end

function formation_recommend_panel:FixView()
     local bg_size_height 
     if self.use_mode == 1 then 
         self:FixBottomButton()
         self:SwitchGenreButtonStatus(false)
         bg_size_height = BG_SIZE_HEIGHT_SHORT

     elseif self.use_mode == 2 then 
         self:SwitchGenreButtonStatus(true)
         bg_size_height = BG_SIZE_HEIGHT_LONG
     end

     self.bg_img:setContentSize(cc.size(self.bg_width, bg_size_height))
end

function formation_recommend_panel:SwitchGenreButtonStatus(flag)
    self.crit_btn:setVisible(flag)
    self.recovery_btn:setVisible(flag)
    self.pure_btn:setVisible(flag)
    self.cancel_btn:setVisible(not flag)
    self.confirm_btn:setVisible(not flag)
end

function formation_recommend_panel:FixBottomButton()
    self.cancel_btn:setPositionY(BOTTOM_BUTTON_Y)
    self.confirm_btn:setPositionY(BOTTOM_BUTTON_Y)
end

function formation_recommend_panel:Show(formation_id)
    self.formation_id = formation_id

    if achievement_logic:GetStatisticValue(constants.ACHIEVEMENT_TYPE["max_bp"]) >= 1000000 then 
       self.use_mode = 2
    else
       self.use_mode = 1
    end 
    self:FixView()
    self.root_node:setVisible(true)
end

function formation_recommend_panel:Hide()
   self.root_node:setVisible(false)
end

-- 0 是综合 1 先攻 2 回复 3 王者
function formation_recommend_panel:CheckRecommendLogic(recommend_type)
    --是否只有主角
    local check_flag = false
    if troop_logic:GetCurMercenaryNum() == 1 then 
       graphic:DispatchEvent("show_prompt_panel", "mercenary_recommend_only_leader")
       return check_flag 
    end

    --排序
    local mercenary_number = 0
    local list = {}
    local need_capacity = troop_logic:GetFormationCapacity()
    local mercenary_list = troop_logic:GetMercenaryList()
    for _, mercenary in pairs(mercenary_list) do
        if recommend_type == 0 or (recommend_type > 0 and mercenary.template_info.genre == recommend_type) then 
           mercenary_number = mercenary_number + 1
           list[mercenary_number] = mercenary
        end
    end

    if mercenary_number <= need_capacity then 
        panel_util:SortMercenary(SORT_TYPE["recommend_by_skill"], list)
    else
        local skill_mercenary_list = {}
        local passive_mercenary_list = {}
        local other_mercenary_list = {}
        local skill_percents = 0

        for _, mercenary in pairs(list) do 
            if mercenary.is_leader then 
               table.insert(skill_mercenary_list, mercenary)

            elseif mercenary.template_info.use_skill_percent > 0 then 
               table.insert(skill_mercenary_list, mercenary)

            elseif mercenary.template_info.is_passive > 0 then 
               table.insert(passive_mercenary_list, mercenary)

            else
               table.insert(other_mercenary_list, mercenary)
            end
        end
        list = {} 
        local commands_table = {}
        commands_table[1] = { sort_name = "strength", to_list = skill_mercenary_list }
        commands_table[2] = { sort_name = "passive_strength", to_list = passive_mercenary_list }
        commands_table[3] = { sort_name = "strength", to_list = other_mercenary_list }

        local check_skill_percent = false
        --step 1 优先 2 被动 3剩余
        for step = 1, 3 do 
            if #list < need_capacity then 
               panel_util:SortMercenary(SORT_TYPE[commands_table[step]["sort_name"]], commands_table[step]["to_list"])
               for _, mercenary in ipairs(commands_table[step]["to_list"]) do 
                   if #list == need_capacity then 
                       break
                   end

                   if step == 1 then 
                       if  not check_skill_percent then 
                           skill_percents = skill_percents + mercenary.template_info.use_skill_percent
                           if  skill_percents >= 100 then 
                               check_skill_percent = true
                           end
                           table.insert(list, mercenary)
                       else
                           table.insert(passive_mercenary_list, mercenary)
                       end
                   else
                       table.insert(list, mercenary)
                   end
               end
            end
        end
    end


    -- panel_util:SortMercenary(SORT_TYPE["recommend"], list)
    local instance_id_list = {}
    for k, v in ipairs(list) do
        instance_id_list[k] = v.instance_id 
        if k == need_capacity then 
            break
        end
    end

    troop_logic:RecommendMercenaryFormation(self.formation_id, instance_id_list)
end

function formation_recommend_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.cancel_btn, self:GetName())
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close1_btn"), self:GetName())

    local recommendListenerEvent = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local recommend_type = widget.recommend_type
            self:CheckRecommendLogic(recommend_type)
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName()) 
        end
    end

    self.confirm_btn:addTouchEventListener(recommendListenerEvent)
    self.crit_btn:addTouchEventListener(recommendListenerEvent)
    self.recovery_btn:addTouchEventListener(recommendListenerEvent)
    self.pure_btn:addTouchEventListener(recommendListenerEvent)
end

return formation_recommend_panel
