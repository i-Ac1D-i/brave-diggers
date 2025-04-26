local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"

local client_constants = require "util.client_constants"
local configuration = require "util.configuration"
local lang_constants = require "util.language_constants"
local resource_template = require "ui.icon_panel"

local mercenary_config = config_manager.mercenary_config
local mercenary_soul_stone_config = config_manager.mercenary_soul_stone_config

local panel_prototype = require "ui.panel"
local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]
local MERCENARY_CHOOSE_SHOW_MODE = client_constants["MERCENARY_CHOOSE_SHOW_MODE"]
local PLIST_TYPE = ccui.TextureResType.plistType

local SOUL_STONE_IMG = "icon/item/8000001.png"
local LOCK_IMG = "icon/global/lock.png"
local MAX_SUB_PANEL_NUM = 3

local panel_util = require "ui.panel_util"
local mercenary_contract_msgbox = panel_prototype.New(true)

local cost_sub_panel = panel_prototype.New()
cost_sub_panel.__index = cost_sub_panel

function cost_sub_panel.New()
    return setmetatable({}, cost_sub_panel)
end

function cost_sub_panel:Init(root_node, tag)
    self.root_node = root_node

    self.bg_img = root_node:getChildByName("txtbg1")
    self.bg_img:setTouchEnabled(true)

    self.desc_text = root_node:getChildByName("soul_desc")
    self.root_node:getChildByName("soul_value"):setPositionX(390)
    self.desc_text:getChildByName("shadow"):setVisible(false)
    self.desc_text:getChildByName("arrow"):setVisible(false)
    self.val_text = root_node:getChildByName("soul_value")
    self.icon_img = root_node:getChildByName("soulicon")
    self.tip_img = root_node:getParent():getChildByName("tip" .. tag)
    self.icon_img:ignoreContentAdaptWithSize(true)
end

function cost_sub_panel:Load(conf, tag)
    local template_id = conf["soul_type" .. tag]
    self.template_id = template_id
    if template_id ~= 0 then
        self.icon_img:loadTexture(SOUL_STONE_IMG, PLIST_TYPE)
        self.desc_text:setString(string.format(lang_constants:Get("mercenary_whos_soul_cyrstal"), mercenary_config[template_id].name))
        self.desc_text:setVisible(true)
        
        local cur_num = troop_logic:GetMercenaryLibraryCount(template_id) or 0
        self.val_text:setString(cur_num .. "/" .. conf["soul_num" .. tag])

        local is_enough = cur_num >= conf["soul_num" .. tag]
        self.val_text:setColor(is_enough and panel_util:GetColor4B(0xDDF037) or panel_util:GetColor4B(0xFF7A43))

        local is_enough_soul_stone = self:CheckSoulStone(template_id, conf["soul_num" .. tag] - cur_num)
        self.tip_img:setVisible(is_enough_soul_stone)

        return is_enough

    elseif  mercenary_contract_msgbox.contract_lv == 1  and tag == 2 then
        for type_id, num in string.gmatch(conf["soul_bone_num1"], "(%d+)|(%d+)") do
            local res_type = 44
            local resource_type = tonumber(type_id)
            local need_num = tonumber(num)
            local conf_1 = config_manager.resource_config[resource_type]
            local conf_2 = config_manager.resource_config[name]
            self.icon_img:loadTexture(conf_1.icon, PLIST_TYPE)
            
            self.desc_text:setString(conf_1.name)
            self.desc_text:setVisible(true)
            
            self.desc_text:setVisible(true)
            local res_name = "soul_bone" .. (resource_type -res_type)
            local cur_num =  resource_logic:GetResourcenNumByName(res_name) 

            local is_enough = cur_num >= need_num
            self.val_text:setColor(is_enough and panel_util:GetColor4B(0xDDF037) or panel_util:GetColor4B(0xFF7A43))
            self.val_text:setString(cur_num .. "/" .. num)

            local is_enough_soul_stone = self:CheckSoulBone(template_id, need_num - cur_num)
            self.tip_img:setVisible(is_enough_soul_stone)

            return is_enough
        end
    elseif  mercenary_contract_msgbox.contract_lv == 2  and tag ~= 3 then
            local confs 
            if tag == 1 then 
                confs = conf["soul_bone_num1"]
            elseif tag == 2 then
                confs = conf["soul_bone_num2"]
            end
            
            if confs == nil then
                return false
            end

        for type_id, num in string.gmatch(confs, "(%d+)|(%d+)") do
            local res_type = 44

            local resource_type = tonumber(type_id)
            local need_num = tonumber(num)
            local conf_1 = config_manager.resource_config[resource_type]
            local conf_2 = config_manager.resource_config[name]
            self.icon_img:loadTexture(conf_1.icon, PLIST_TYPE)
            
            self.desc_text:setString(conf_1.name)
            self.desc_text:setVisible(true)
            
            self.desc_text:setVisible(true)
            local res_name = "soul_bone" .. (resource_type -res_type)
            local cur_num =  resource_logic:GetResourcenNumByName(res_name) or 0

            local is_enough = cur_num >= need_num
            self.val_text:setColor(is_enough and panel_util:GetColor4B(0xDDF037) or panel_util:GetColor4B(0xFF7A43))
            self.val_text:setString(cur_num .. "/" .. num)

            local is_enough_soul_stone = self:CheckSoulBone(template_id, need_num - cur_num)
            self.tip_img:setVisible(is_enough_soul_stone)

            return is_enough

        end
    else
        self.icon_img:loadTexture(LOCK_IMG, PLIST_TYPE)
        self.desc_text:setVisible(false)
        self.val_text:setString("")
        self.tip_img:setVisible(false)

        return true
    end
end


-- 检测资源是否可以召唤足够的灵魂石
function cost_sub_panel:CheckSoulStone(template_id, check_num)

    if check_num <= 0 then
        -- 已经有足够的灵魂石
        return false
    end

    if not troop_logic:GetMercenaryLibraryCount(template_id) then
        -- 图鉴中没有此佣兵
        return false
    end

    local soul_stone_conf  = mercenary_soul_stone_config[template_id]

    if not soul_stone_conf then
        return false
    end

    local is_enough = true
    for i = 1, 7 do
        local resource_name = client_constants["CRAFT_COST_RESOURCE"][i]

        local cost_resource = soul_stone_conf[resource_name] or 0
        if not resource_logic:CheckResourceNum(constants.RESOURCE_TYPE[resource_name], cost_resource * check_num, false) then
           is_enough = is_enough and false
        end
    end

    return is_enough
end
-- 检测资源是否可以召唤足够的魂骨
function cost_sub_panel:CheckSoulBone(template_id, check_num)

    if check_num <= 0 then
        -- 已经有足够的魂骨
        return false
    end

    if not troop_logic:GetMercenaryLibraryCount(template_id) then
        -- 图鉴中没有此佣兵
        return false
    end
    
    local soul_bone_conf  = mercenary_soul_stone_config[template_id]

    if not soul_bone_conf then
        return false
    end
    
    local is_enough = true
    for i = 1, #client_constants["CRAFT_COST_RESOURCE"] do
        local resource_name = client_constants["CRAFT_COST_RESOURCE"][i]
        
        local cost_resource = soul_bone_conf[resource_name] or 0
        if not resource_logic:CheckResourceNum(constants.RESOURCE_TYPE[resource_name], cost_resource * check_num, false) then
           is_enough = is_enough and false
        end
    end

    return is_enough
end
function mercenary_contract_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/mercenary_contract_msgbox.csb")
    local recruit_box = self.root_node:getChildByName("recruit_box")
    self.cost_sub_panels = {}

    self.title_text = recruit_box:getChildByName("title")

    for i = 1, constants["MAX_CONTRACT_SOUL_TYPE"] do
        self.cost_sub_panels[i] = cost_sub_panel.New()
        self.cost_sub_panels[i]:Init(recruit_box:getChildByName("soul" .. i), i)
    end

    self.cost_bg = self.root_node:getChildByName("consume_bg")

    self.resource_sub_panels = {}
    for i = 1, MAX_SUB_PANEL_NUM do
        local sub_panel = resource_template.New()
        sub_panel:Init(self.cost_bg)
        self.resource_sub_panels[i] = sub_panel
        self.resource_sub_panels[i].root_node:setPositionY(0)
    end

    self.close_btn = recruit_box:getChildByName("close_btn")
    self.confirm_btn = recruit_box:getChildByName("confirm_btn")

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function mercenary_contract_msgbox:Load(conf)
    conf = conf or self.conf
    local center_x = self.cost_bg:getContentSize().width / 2

    local _, resource_is_enough = panel_util:LoadCostResourceInfo(conf, self.resource_sub_panels, 50, MAX_SUB_PANEL_NUM, center_x)

    for i = 1, constants["MAX_CONTRACT_SOUL_TYPE"] do
        resource_is_enough = self.cost_sub_panels[i]:Load(conf, i) and resource_is_enough
    end

    if resource_is_enough then
        self.confirm_btn:setTitleText(lang_constants:Get("common_confirm"))
        self.confirm_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
    else
        self.confirm_btn:setTitleText(lang_constants:Get("resource_general_not_enough"))
        self.confirm_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
    end

    local mercenary = troop_logic:GetMercenaryInfo(self.mercenary_id)
    if mercenary then
        if not troop_logic:CanContractLv(mercenary.template_info.ID, self.contract_lv) then
            self.confirm_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
            self.confirm_btn:setTitleText(string.format(lang_constants:Get("mercenary_not_contract_lv"), self.contract_lv))
        else
            --未签订一阶
            if mercenary.contract_lv == 0 and self.contract_lv == constants["MAX_CONTRACT_LV"] then
                self.confirm_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
                self.confirm_btn:setTitleText(string.format(lang_constants:Get("mercenary_canot_contract_lv1"), self.contract_lv))
            end
        end
    end
end

function mercenary_contract_msgbox:Show(mercenary_id, contract_lv)
    self.mercenary_id = mercenary_id
    self.contract_lv = contract_lv
    local conf = troop_logic:GetContractConf(mercenary_id, contract_lv)
    if not conf then
        return
    end

    self.conf = conf

    self:Load(conf)
    self.root_node:setVisible(true)

    self.title_text:setString(lang_constants:Get("mercenary_sign_contract_" .. contract_lv))
end

function mercenary_contract_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())

    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local mercenary = troop_logic:GetMercenaryInfo(self.mercenary_id)

            if not troop_logic:CanContractLv(mercenary.template_info.ID, self.contract_lv) then
                graphic:DispatchEvent("show_prompt_panel", "mercenary_cant_sign_contract")
                return
            end

            if mercenary.contract_lv == 0 and self.contract_lv == constants["MAX_CONTRACT_LV"] then
                graphic:DispatchEvent("show_prompt_panel", "mercenary_not_contract_lv1")
                return
            end

            if troop_logic:CheckContractResource(self.mercenary_id) then
                graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            end
            
            troop_logic:SignContract(self.mercenary_id, self.contract_lv)

        end
    end)

    for i = 1, constants["MAX_CONTRACT_SOUL_TYPE"] do
        self.cost_sub_panels[i].bg_img:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                local template_id = self.cost_sub_panels[i].template_id
                if template_id and  template_id ~= 0 then
                    -- if i == 1 then
                    --     graphic:DispatchEvent("show_world_sub_panel", "mercenary_soul_stone_panel", template_id,  "craft")
                    -- else
                    --     graphic:DispatchEvent("show_world_sub_panel", "mercenary_soul_stone_panel", template_id,  "res")
                    -- end
                
                end
            end
        end)
    end
end

function mercenary_contract_msgbox:RegisterEvent()
    graphic:RegisterEvent("sign_mercenary_contract", function(mercenary_id)
        if not self.root_node:isVisible() then
            return
        end

        if self.mercenary_id ~= mercenary_id then
            return
        end

        local conf = troop_logic:GetContractConf(mercenary_id)
        if not conf then
            return
        end

        self:Load(conf)
        graphic:DispatchEvent("hide_world_sub_panel", self:GetName())

    end)

    --图书馆招募成功
    graphic:RegisterEvent("library_recruit_success", function(template_id)
        if not self.root_node:isVisible() then
            return
        end

        self:Load()

    end)

    --成功合成一枚灵魂石
    graphic:RegisterEvent("craft_soul_stone_success2", function(template_id)

        if not self.root_node:isVisible() then
            return
        end

        self:Load()
    end)

end

return mercenary_contract_msgbox
