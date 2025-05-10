local config_manager = require "logic.config_manager"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local audio_manager = require"util.audio_manager"

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local time_logic = require "logic.time"
local user_logic = require "logic.user"
local destiny_logic = require "logic.destiny_weapon"
local reminder_logic =  require "logic.reminder"
local platform_manager = require "logic.platform_manager"
local mercenary_exp_config = config_manager.mercenary_exp_config

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local spine_manager = require "util.spine_manager"
local lang_constants = require "util.language_constants"
local reuse_scrollview =require "widget.reuse_scrollview"
local JUMP_CONST = client_constants["JUMP_CONST"] 
local RESOURCE_TYPE = constants.RESOURCE_TYPE
local MERCENARY_MSGBOX = client_constants.MERCENARY_MSGBOX
local PLIST_TYPE = ccui.TextureResType.plistType

local SUB_PANEL_HEIGHT = 124
local FIRST_SUB_PANEL_OFFSET = -80
local MAX_SUB_PANEL_NUM = 9
local FORCE_LV_COST_RESOURCE_NUM = constants.FORCE_LV_COST_RESOURCE_NUM
local CHANGE_EX_PROPERTY_RESOURCE = constants.CHANGE_EX_PROPERTY_RESOURCE

local MULTI_LEVEL_BTN_DIE_OUT_DURATION = 0.5
local MULTI_LEVEL_BTN_SHOW_DURATION = 1

local WAKEUP_DESC_OFFSET_Y = 10

local TAB_TYPE =
{
    ["levelup"] = 1,
    ["forge"] = 2,
}

local mercenary_sub_panel = panel_prototype.New()
mercenary_sub_panel.__index = mercenary_sub_panel

function mercenary_sub_panel.New()
    return setmetatable({}, mercenary_sub_panel)
end

function mercenary_sub_panel:Init(root_node, index)
    self.root_node = root_node
    self.role_bg_img = root_node:getChildByName("role_bg")
    self.role_icon_img = self.role_bg_img:getChildByName("role_icon")
    self.role_icon_img:setScale(2, 2)

    self.role_bg_img:setCascadeColorEnabled(false)
    self.role_icon_img:ignoreContentAdaptWithSize(true)

    self.wakeup_text = self.role_bg_img:getChildByName("wakeup_desc")
    self.wakeup_text:setColor(cc.c3b(255,255,255))
    self.wakeup_img = self.role_bg_img:getChildByName("wakeup1")
    panel_util:SetTextOutline(self.wakeup_text)
    
    self.ex_prop_icon_img = self.role_bg_img:getChildByName("property_icon")
    self.ex_prop_val_text = self.role_bg_img:getChildByName("property_value")
    self.force_max_text = self.role_bg_img:getChildByName("property_desc")

    self.level_text = self.role_bg_img:getChildByName("lv")
    self.name_text = root_node:getChildByName("name")

    self.bp_text = root_node:getChildByName("bp")

    self.levelup1_btn = root_node:getChildByName("levelup_btn1")
    self.levelup1_btn:setCascadeColorEnabled(true)

    self.bp_add_text = self.levelup1_btn:getChildByName("bp_add")

    self.desc1_text = self.levelup1_btn:getChildByName("desc1")
    self.desc1_text_y = self.desc1_text:getPositionY()
    
    self.desc2_text = self.levelup1_btn:getChildByName("desc2")
    self.desc3_text = self.levelup1_btn:getChildByName("desc3")
    self.bp_icon_img = self.levelup1_btn:getChildByName("bp_icon")
    self.artifact_btn = root_node:getChildByName("bj_01")  --锻造宝具按钮
    self.artifact_btn:setVisible(false)

    self.levelup2_btn = root_node:getChildByName("levelup_btn2")
    self.levelup2_btn:setCascadeColorEnabled(true)

    self.next_bp_add_text = self.levelup2_btn:getChildByName("bp_add")
    self.next_level_text = self.levelup2_btn:getChildByName("desc1")
    self.next_consume_text = self.levelup2_btn:getChildByName("desc2")

    self.force_btn = root_node:getChildByName("force_btn")
    self.bp_rate_text = self.force_btn:getChildByName("rate")
    self.force_btn_text = self.force_btn:getChildByName("desc1")
    self.force_btn_icon =  self.force_btn:getChildByName("bp_icon")
    self.force_btn:setCascadeColorEnabled(true)

    self.levelup1_btn:setTag(index)
    self.levelup2_btn:setTag(index)
    self.force_btn:setTag(index)

    local bp_text_offset_x = platform_manager:GetChannelInfo().mercenary_sub_panel_bp_text_offset_x
    local language = platform_manager:GetLocale()
    --当等级信息过长会被挡住
    if bp_text_offset_x then
        self.bp_text:setPositionX(self.bp_text:getPositionX()+bp_text_offset_x)
        local bg_icon = root_node:getChildByName("bp_icon")
        bg_icon:setPositionX(bg_icon:getPositionX()+bp_text_offset_x)
    end

    --r2games位置修改
    if platform_manager:GetChannelInfo().mercenary_sub_panel_force_btn_text_ap_center then
        self.force_btn_text:setAnchorPoint(cc.p(0.5,0.5))
        self.force_btn_text:setPositionX(self.force_btn:getContentSize().width/2)
    end

    self.cur_tab_type = TAB_TYPE["levelup"]
    
    self:RegisterWidgetEvent()
end

--SYY
--注册监听事件
function mercenary_sub_panel:RegisterWidgetEvent()
    --打开锻造宝具
    self.artifact_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local mercenary = troop_logic:GetMercenaryInfo(self.mercenary_id)
            if not mercenary.template_info.have_artifact then
                if mercenary.is_leader then
                    panel_util:ShowMercenaryMsgBox(MERCENARY_MSGBOX["weapon"], self.mercenary_id, mercenary.is_leader, troop_logic:GetCurFormationId())
                end
            else
                --开启宝具
                panel_util:ShowMercenaryMsgBox(MERCENARY_MSGBOX["weapon"], self.mercenary_id, mercenary.is_leader, true)
            end
        end
    end)
end

local mercenary_temp = {}
function mercenary_sub_panel:Show(mercenary)
    if mercenary == nil then
        return
    end
    self.root_node:setVisible(true)

    self.mercenary_id = mercenary.instance_id

    local quality = mercenary.template_info.quality
    self.name_text:setString(mercenary.template_info.name)

    self.role_icon_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. mercenary.template_info.sprite .. ".png", PLIST_TYPE)
    self.role_bg_img:setColor(panel_util:GetColor4B(client_constants["BG_QUALITY_COLOR"][quality]))

    self.ex_prop_icon_img:setVisible(false)
    self.ex_prop_val_text:setVisible(false)
    self.force_max_text:setVisible(false)

    local language = platform_manager:GetLocale()
    if language == "de" or language == "fr" and platform_manager:GetChannelInfo().mercenary_levelup_panel_change_desc1_font_size then 
        self.desc1_text:setFontSize(24)
        self.desc1_text:setPositionX(15)
    end

    --r2 隐藏主角两个字，显示自己的名字
    local hide_main_name = platform_manager:GetChannelInfo().mercenary_sub_panel_hide_main_name
    if mercenary.is_leader and hide_main_name then
        self.name_text:setString(troop_logic:GetLeaderName())
    end

    self:Load(mercenary)
    --Tag:
    graphic:DispatchEvent("jump_finish",JUMP_CONST["mercenary_levelup_panel"])  
end

--加载佣兵
function mercenary_sub_panel:Load(mercenary)
    self.bp_text:setString(tostring(mercenary.battle_point))
    self.level_text:setString(lang_constants:Get("level_shot_string") .. tostring(mercenary.level))

    if mercenary.force_lv == constants["MAX_FORCE_LEVEL"] then
        --突破已满
        self.ex_prop_icon_img:setVisible(true)
        self.ex_prop_val_text:setVisible(true)
        self.force_max_text:setVisible(true)
        self.ex_prop_icon_img:loadTexture(client_constants.MERCENARY_PROPERTY_ICON[mercenary.ex_prop_type], PLIST_TYPE)
        self.ex_prop_val_text:setString("+".. mercenary.ex_prop_val * constants["CONTRACT_FORCE_UP"][mercenary.contract_lv])

        self.wakeup_text:setVisible(true)
        self.wakeup_img:setVisible(true)
        self.wakeup_text:setString(mercenary.wakeup .. "/" .. mercenary.template_info.max_wakeup)
        
        self:LoadUpgradeForceInfo(mercenary)

    else
        self.wakeup_text:setVisible(true)
        self.wakeup_img:setVisible(true)
        self.wakeup_text:setString(mercenary.wakeup .. "/" .. mercenary.template_info.max_wakeup)
    end

    mercenary_temp.exp = mercenary.exp
    mercenary_temp.is_leader = mercenary.is_leader
    mercenary_temp.template_info = mercenary.template_info
    mercenary_temp.weapon_lv = mercenary.weapon_lv
    mercenary_temp.force_lv = mercenary.force_lv
    mercenary_temp.is_open_artifact = mercenary.is_open_artifact
    mercenary_temp.ex_prop_type = mercenary.ex_prop_type
    mercenary_temp.template_id = mercenary.template_id
    mercenary_temp.artifact_lv = mercenary.artifact_lv
    mercenary_temp.ex_prop_val = mercenary.ex_prop_val * constants["CONTRACT_FORCE_UP"][mercenary.contract_lv]

    if self.cur_tab_type == TAB_TYPE["levelup"] then
        self:LoadLevelupInfo(mercenary)

    elseif self.cur_tab_type == TAB_TYPE["forge"] then
        self:LoadForgeWeaponInfo(mercenary)
    end
end

--更新佣兵突破信息
function mercenary_sub_panel:LoadUpgradeForceInfo(mercenary)
    if mercenary.wakeup >= 5 and mercenary.template_info.can_upgrade_force and mercenary.force_lv <= constants["MAX_FORCE_LEVEL"] then
        self.force_btn:setVisible(true)
        local config = {}

        if mercenary.force_lv == constants["MAX_FORCE_LEVEL"] then
            config = CHANGE_EX_PROPERTY_RESOURCE
            config.soul_chip = mercenary.template_info.soul_chip * 0.8

            -- 转换属性
            self.force_btn_text:setString(lang_constants:Get("exchange"))
            self.force_btn_icon:loadTexture(client_constants.MERCENARY_PROPERTY_ICON[mercenary.ex_prop_type], PLIST_TYPE)
            self.bp_rate_text:setString("+" .. mercenary.ex_prop_val * constants["CONTRACT_FORCE_UP"][mercenary.contract_lv])
        else
            config = FORCE_LV_COST_RESOURCE_NUM

            -- 突破
            self.force_btn_text:setString(lang_constants:Get("force"))
            self.force_btn_icon:loadTexture(client_constants.MERCENARY_FIGHTING_ICON, PLIST_TYPE)
            self.bp_rate_text:setString(string.format("+%d%%", mercenary.force_lv))
        end

        if not resource_logic:CheckResourceNum(RESOURCE_TYPE["golem"], FORCE_LV_COST_RESOURCE_NUM["golem"]) or
            not resource_logic:GetResourceNum(RESOURCE_TYPE["soul_chip"], FORCE_LV_COST_RESOURCE_NUM["soul_chip"]) then
            self.force_btn:setColor(panel_util:GetColor4B(0x7F7F7F))

        else
            self.force_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
        end
    else
        self.force_btn:setVisible(false)
    end
end

--设定升级信息
function mercenary_sub_panel:LoadLevelupInfo(mercenary)
    self.levelup2_btn:setVisible(false)
    self.can_multi_level = false
    self.multi_level_durantion = 0
    self.artifact_btn:setVisible(false)

    self.desc1_text:setVisible(true)

    self.bp_add_text:setVisible(true)
    self.bp_icon_img:setVisible(true)

    self.desc1_text:setPositionY(self.desc1_text_y)

    self:LoadUpgradeForceInfo(mercenary)

    local is_levelup = false

    if mercenary.level < constants["CAN_WAKEUP_LEVEL"] then
        --计算战力
        is_levelup = true

    elseif mercenary.level <= constants["MAX_LEVEL"] then
        if mercenary.wakeup < mercenary.template_info.max_wakeup then
            --计算觉醒
            self.desc2_text:setString(config_manager.wakeup_info_config[mercenary.wakeup]["golem"])

            local next_wakeup = mercenary.wakeup < mercenary.template_info.max_wakeup and mercenary.wakeup + 1 or mercenary.wakeup
            mercenary_temp.wakeup = next_wakeup

            troop_logic:CalcMercenaryLevel(mercenary_temp)
            troop_logic:CalcMercenaryBP(mercenary_temp)

            self.bp_add_text:setString("+" .. (mercenary_temp.battle_point - mercenary.battle_point))
            is_levelup = false
            self:SetLevelupBtnImgs(false)
            self.desc3_text:setVisible(true)

            local config = config_manager.wakeup_info_config[mercenary.wakeup]
            --local res_conf = config_manager.resource_config[config.resource_id]

            self.desc3_text:setString(string.format(lang_constants:Get("golem_consume_desc"), config.resource_num))

            --检测资源, 设置按钮的颜色
            if not resource_logic:CheckResourceNum(RESOURCE_TYPE["gold_coin"], config.gold_coin,nil,true) then  -- 资源跳转
                self.levelup1_btn:setColor(panel_util:GetColor4B(0x929292))
                return
            end

            if not resource_logic:CheckResourceNum(config.resource_id, config.resource_num,nil,true) then  -- 资源跳转
                self.levelup1_btn:setColor(panel_util:GetColor4B(0x929292))
                return
            end
            self.levelup1_btn:setColor(panel_util:GetColor4B(0xFFFFFF))

        else
            is_levelup = true
            --最高等级 最高觉醒等级
            if mercenary.level == constants["MAX_LEVEL"] then
                self.bp_add_text:setString(lang_constants:Get("level_max"))
                self.desc2_text:setString("0")
                self:SetLevelupBtnImgs(true)
                is_levelup = false
                self.levelup1_btn:setColor(panel_util:GetColor4B(0x929292))
            end
        end
    else
        self.levelup1_btn:setColor(panel_util:GetColor4B(0x929292))
    end

    if is_levelup then
        --升级
        self:SetLevelupBtnImgs(true)
        local need_exp = mercenary_exp_config[mercenary.level]['wakeup_factor'..mercenary.wakeup] - mercenary.exp
        self.desc2_text:setString(string.format("EXP-%s", panel_util:ConvertUnit(need_exp)))

        mercenary_temp.level = mercenary.level + 1
        mercenary_temp.wakeup = mercenary.wakeup
        troop_logic:CalcMercenaryBP(mercenary_temp)

        self.bp_add_text:setString("+" .. (mercenary_temp.battle_point - mercenary.battle_point))

        local exp = resource_logic:GetResourceNum(RESOURCE_TYPE["exp"])
        if need_exp > exp then
            self.levelup1_btn:setColor(panel_util:GetColor4B(0x929292))
        else
            self.levelup1_btn:setColor(panel_util:GetColor4B(0xffffff))
        end
    end
end

--设定levelupbtn1的图片
function mercenary_sub_panel:SetLevelupBtnImgs(levelup)
    local img = ""

    if levelup then
        img = "button/buttonbg_10.png"

        self.desc1_text:setString(lang_constants:Get("level_up"))
        self.desc2_text:setVisible(true)
        self.desc3_text:setVisible(false)

    else
        img = "button/buttonbg_11.png"

        self.desc1_text:setString(lang_constants:Get("wakeup"))
        self.desc2_text:setVisible(false)
    end

    self.levelup1_btn:loadTextures(img, img, img, PLIST_TYPE)
end

--更新强化信息
function mercenary_sub_panel:LoadForgeWeaponInfo(mercenary)
    self.force_btn:setVisible(false)
    self.levelup2_btn:setVisible(false)

    self.desc3_text:setVisible(false)

    --觉醒等级label
    self.wakeup_text:setVisible(true)
    self.wakeup_img:setVisible(true) 

    self.desc1_text:setPositionY(self.desc1_text_y + WAKEUP_DESC_OFFSET_Y)
    self:SetLevelupBtnImgs(true)
    
    if mercenary.is_leader then
        local weapon_lv, weapon_num = destiny_logic:GetCurWeaponInfo()

        self.desc2_text:setString(weapon_lv .. "/" .. constants["MAX_DESTINY_WEAPON_LV"])

        self.bp_add_text:setString(config_manager.destiny_forge_config[weapon_lv + 1]["bp_factor"]  .. "%")
        self.name_text:setString(troop_logic:GetLeaderName())

        local weapon_ids = destiny_logic:GetWeaponIds()

        --当前等级和拥有的武器数量相等
        if weapon_lv == #weapon_ids then
            self.levelup1_btn:setColor(panel_util:GetColor4B(0x929292))
        else
            if destiny_logic:CheckForgeResource() then
                self.levelup1_btn:setColor(panel_util:GetColor4B(0xffffff))
            else
                self.levelup1_btn:setColor(panel_util:GetColor4B(0x929292))
            end
        end

        self:SetWeaponBtnImgs(true)

    else

        local weapon_lv = mercenary.weapon_lv
        self.desc2_text:setString(weapon_lv .. "/" .. constants["MAX_WEAPON_LV"])
        if weapon_lv < constants["MAX_WEAPON_LV"] then
            local config = config_manager.weapon_forge_config[weapon_lv + 1]
            self.bp_add_text:setString("+" .. config.bp_factor .. "%")
        else
            self.bp_add_text:setString(lang_constants:Get("level_max"))
        end

        local is_open_artifact = false
        if weapon_lv == constants["CAN_OPEN_ARTIFACT_WEAPON_LV"] and mercenary.template_info.have_artifact and not mercenary.is_open_artifact then
            --这里是锻造宝具
            is_open_artifact = true
        elseif troop_logic:IsArtifactUpgrade(self.mercenary_id) then
            --这里是升级宝具
            is_open_artifact = true
            local now_level = mercenary.artifact_lv or 1
            local artifact_config = config_manager.mercenary_artifact_config[mercenary.template_id]
            local max_level = #artifact_config  --最大级是
            self:SetArtifactGradgeLevel(now_level,max_level)
        end

        self:SetWeaponBtnImgs(true,is_open_artifact)
        --检测资源
        if troop_logic:CheckForgeWeaponResource(mercenary.weapon_lv) then
            self.levelup1_btn:setColor(panel_util:GetColor4B(0xffffff))
        else
            self.levelup1_btn:setColor(panel_util:GetColor4B(0x929292))
        end
    end
end

--设定武器图片
function mercenary_sub_panel:SetWeaponBtnImgs(state,is_open_artifact)
    self.desc1_text:setVisible(state)
    self.desc2_text:setVisible(state)
    self.bp_add_text:setVisible(state)
    self.bp_icon_img:setVisible(state)

    self.desc1_text:setString(lang_constants:Get("forge"))
    state = is_open_artifact and state 
    self.artifact_btn:setVisible(state)

    if troop_logic:IsArtifactUpgrade(self.mercenary_id) then
        self:ShowArtifactBtnState(true)
    else
        self:ShowArtifactBtnState(false)
    end
end

function mercenary_sub_panel:SetArtifactGradgeLevel(now_level,max_level)
    local str = now_level.."/"..max_level
    self.artifact_btn:getChildByName("rate"):setString(str)
end

--锻造按钮状态
function mercenary_sub_panel:ShowArtifactBtnState(state)
    --锻造
    self.artifact_btn:getChildByName("desc4"):setVisible(not state)
    self.artifact_btn:getChildByName("artifact_icon"):setVisible(not state)
    --升级
    self.artifact_btn:getChildByName("shadow"):setVisible(state)
    self.artifact_btn:getChildByName("rate"):setVisible(state)
    self.artifact_btn:getChildByName("desc1_0"):setVisible(state)

end

--升多级
function mercenary_sub_panel:MultiLevelUp()
    troop_logic:AllocMercenaryExp(self.mercenary_id, self.target_level)
end

--判断是升级还是觉醒
function mercenary_sub_panel:LevelupOrWakeUp()
    local mercenary = troop_logic:GetMercenaryInfo(self.mercenary_id)
    local reach_max_wakeup = (mercenary.wakeup == mercenary.template_info.max_wakeup)
    if mercenary.level == constants["MAX_LEVEL"] and reach_max_wakeup then
        --升至满级
        return
    end

    if mercenary.level < constants["CAN_WAKEUP_LEVEL"] or reach_max_wakeup then
        troop_logic:AllocMercenaryExp(self.mercenary_id, self.level_delta)
    else
        panel_util:ShowMercenaryMsgBox(client_constants.MERCENARY_MSGBOX["wakeup"], self.mercenary_id)
    end
end

function mercenary_sub_panel:Update(elapsed_time)
    --升多级按钮 显示一秒然后在0.5秒内消失
    if self.can_multi_level then
        self.multi_level_durantion = self.multi_level_durantion + elapsed_time

        if self.multi_level_durantion > MULTI_LEVEL_BTN_SHOW_DURATION and self.multi_level_durantion <= (MULTI_LEVEL_BTN_SHOW_DURATION + MULTI_LEVEL_BTN_DIE_OUT_DURATION) then
            local percent = 1.01 * math.exp(- ( 1.2 * ((self.multi_level_durantion - MULTI_LEVEL_BTN_SHOW_DURATION) / MULTI_LEVEL_BTN_DIE_OUT_DURATION) - 1.5) ^ 4)
            percent = math.min(percent, 1)
            self.levelup2_btn:setOpacity(255 * (1 - percent))

        elseif self.multi_level_durantion > (MULTI_LEVEL_BTN_SHOW_DURATION + MULTI_LEVEL_BTN_DIE_OUT_DURATION) then
            self.can_multi_level = false
            self.levelup2_btn:setVisible(false)
            self.levelup2_btn:setOpacity(0)
        end
    end
end

--判断是强化还是开启宝具
function mercenary_sub_panel:ForgeOrOpenArtifact()
    local mercenary = troop_logic:GetMercenaryInfo(self.mercenary_id)
    --强化
    panel_util:ShowMercenaryMsgBox(MERCENARY_MSGBOX["weapon"], self.mercenary_id, mercenary.is_leader, false)
end

--突破
function mercenary_sub_panel:UpgradeForce()
    --显示界限突破界面
    graphic:DispatchEvent("show_world_sub_panel", "force_panel", self.mercenary_id)
end

--检测是否可以升多级
function mercenary_sub_panel:CheckCanMultiLevel(instance_id)
    -- body
    local mercenary = troop_logic:GetMercenaryInfo(instance_id)
    local cur_exp = resource_logic:GetResourceNum(RESOURCE_TYPE["exp"])
    local cur_level = mercenary.level
    local cur_wakeup = mercenary.wakeup
    local max_wakeup = mercenary.template_info.max_wakeup

    local wakeup_factor = 'wakeup_factor'.. cur_wakeup

    --计算最多可以生几级
    local can_level_num = 0
    for i = 1, 10 do
        local need_exp = mercenary_exp_config[cur_level + can_level_num][wakeup_factor] - mercenary.exp
        if need_exp < cur_exp then
            can_level_num = can_level_num + 1
        else
            break
        end
    end

    --计算距离升到可以觉醒的级别所需要的
    if cur_wakeup < max_wakeup then
        local le = constants["CAN_WAKEUP_LEVEL"] - cur_level
        if le == 0 then
            return
        end

        local need_exp = mercenary_exp_config[le][wakeup_factor] - mercenary.exp
        if need_exp < cur_exp then
            can_level_num = math.min(can_level_num, le)
        end
    end

    if can_level_num >= 2 then
        --可以提升多级
        self.levelup2_btn:setVisible(true)
        self.levelup2_btn:setOpacity(255)
        self.can_multi_level = true
        self.multi_level_durantion = 0

        local target_level = cur_level + can_level_num

        local need_exp = mercenary_exp_config[target_level]['wakeup_factor'..mercenary.wakeup] - mercenary.exp
        self.next_consume_text:setString(string.format("EXP-%s", panel_util:ConvertUnit(need_exp)))

        mercenary_temp.level = target_level
        mercenary_temp.wakeup = mercenary.wakeup
        troop_logic:CalcMercenaryBP(mercenary_temp)

        self.next_bp_add_text:setString("+" .. (mercenary_temp.battle_point - mercenary.battle_point))
        self.next_level_text:setString("+" .. can_level_num)

        self.target_level = can_level_num
    end
end

local mercenary_levelup_panel = panel_prototype.New(true)
function mercenary_levelup_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mercenary_levelup_panel.csb")

    local bp_img = self.root_node:getChildByName("title_bg")
    self.troop_bp_text = bp_img:getChildByName("sum_bp")

    self.back_btn = self.root_node:getChildByName("back_btn")

    self.levelup_tab_img = self.root_node:getChildByName("levelup_tab")
    self.levelup_tab_img:getChildByName("remind_tip"):setVisible(false)
    self.levelup_tab_img:setTag(1)

    self.forge_tab_img = self.root_node:getChildByName("weapon_tab")
    self.forge_tab_remind_img = self.forge_tab_img:getChildByName("remind_tip")
    self.forge_tab_remind_img:setVisible(false)
    self.forge_tab_img:setTag(2)

    self.mercenary_list_sview = self.root_node:getChildByName("scroll_view")
    self.mercenary_sub_panels = {}

    self.reuse_scrollview = reuse_scrollview.New(self, self.mercenary_list_sview, self.mercenary_sub_panels, SUB_PANEL_HEIGHT)

    self.reuse_scrollview:RegisterMethod(
        function(self)
            return troop_logic:GetExploringMercenaryNum()
        end,

        function(self, sub_panel, is_up)
            local formation_list = troop_logic:GetFormationMercenaryList()
            if is_up then
                sub_panel:Show(formation_list[self.data_offset + self.sub_panel_num])

            else
                sub_panel:Show(formation_list[self.data_offset+1])
            end
        end
    )

    self:RegisterEvent()
    self:RegisterWidgetEvent()

    self.template = self.mercenary_list_sview:getChildByName("template")
    local sub_panel = mercenary_sub_panel.New()
    sub_panel:Init(self.template, 1)
    --添加监听事件
    sub_panel.levelup1_btn:addTouchEventListener(self.levelup1_method)
    sub_panel.levelup2_btn:addTouchEventListener(self.levelup2_method)
    sub_panel.force_btn:addTouchEventListener(self.force_method)

    self.mercenary_sub_panels[1] = sub_panel
    self.sub_panel_num = 1

    self:CreateSpineNodes()
end

function mercenary_levelup_panel:CreateSpineNodes()
    --升级
    self.levelup_spine_node = spine_manager:GetNode("levelup")
    self.levelup_spine_node:setVisible(false)
    self.is_playing_animation = false

    self.levelup_spine_node:registerSpineEventHandler(function(event)
        self.levelup_spine_node:setVisible(false)
        self.is_playing_animation = false
    end, sp.EventType.ANIMATION_COMPLETE)

    self.root_node:addChild(self.levelup_spine_node, 2)
end

function mercenary_levelup_panel:Show()
    self.troop_bp_text:setString(tostring(troop_logic:GetTroopBP()))

    self:CreateSubPanel()
    self.cur_tab_type = TAB_TYPE["levelup"]

    self:UpdateTabStatus(self.cur_tab_type)

    local cur_explore_num = troop_logic:GetExploringMercenaryNum()
    local formation_list = troop_logic:GetFormationMercenaryList()

    local height = math.max((cur_explore_num + 1) * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

    for i = 1, self.sub_panel_num do
        local sub_panel = self.mercenary_sub_panels[i]
        if i <= cur_explore_num and formation_list[i] ~= nil then
            sub_panel:Show(formation_list[i])
            sub_panel.root_node:setPositionY(height - (i - 1) * SUB_PANEL_HEIGHT)
        else
            sub_panel:Hide()
        end
    end

    self.reuse_scrollview:Show(height, 0)

    -- 检测强化提醒
    reminder_logic:CheckForgeReminder()
    
    self.root_node:setVisible(true)
end


function mercenary_levelup_panel:UpdateTabStatus(tab_type)
    self.cur_tab_type = tab_type

    if tab_type == TAB_TYPE["levelup"] then
        self.levelup_tab_img:setColor(panel_util:GetColor4B(0xFFFFFF))
        self.forge_tab_img:setColor(panel_util:GetColor4B(0x7F7F7F))

    elseif tab_type == TAB_TYPE["forge"] then
        self.forge_tab_img:setColor(panel_util:GetColor4B(0xFFFFFF))
        self.levelup_tab_img:setColor(panel_util:GetColor4B(0x7F7F7F))
    end

    for i = 1, self.sub_panel_num do
        local sub_panel = self.mercenary_sub_panels[i]
        sub_panel.cur_tab_type = tab_type
    end
end

function mercenary_levelup_panel:CreateSubPanel()
    local num = math.min(MAX_SUB_PANEL_NUM, troop_logic:GetFormationCapacity())

    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = mercenary_sub_panel.New()
        sub_panel:Init(self.template:clone(), i)

        self.mercenary_sub_panels[i] = sub_panel
        self.mercenary_list_sview:addChild(sub_panel.root_node)

        sub_panel.levelup1_btn:addTouchEventListener(self.levelup1_method)
        sub_panel.levelup2_btn:addTouchEventListener(self.levelup2_method)
        sub_panel.force_btn:addTouchEventListener(self.force_method)
    end

    self.sub_panel_num = num
end

function mercenary_levelup_panel:Update(elapsed_time)
    for i = 1, self.sub_panel_num do
        local sub_panel = self.mercenary_sub_panels[i]
        sub_panel:Update(elapsed_time)
    end
end

function mercenary_levelup_panel:UpdateMercenayInfo(mercenary_id)
    for i = 1, self.sub_panel_num do
        local sub_panel = self.mercenary_sub_panels[i]

        local mercenary = troop_logic:GetMercenaryInfo(sub_panel.mercenary_id)
        if mercenary then
            sub_panel:Load(mercenary)
        end
    end
end

function mercenary_levelup_panel:PlayAnimation(sub_panel, level_diff)
    local offset = 5
    if level_diff == 1 then
        self.is_playing_animation = true

        self.levelup_spine_node:setSkin("levelup")

        self.levelup_spine_node:setVisible(true)
        self.levelup_spine_node:setToSetupPose()
        self.levelup_spine_node:setAnimation(0, "levelup", false)

        local world_pos = sub_panel.role_bg_img:convertToWorldSpace(cc.p(sub_panel.role_bg_img:getPosition()))
        self.levelup_spine_node:setPosition(world_pos.x + offset, world_pos.y)

    elseif level_diff == 10 then
        self.levelup_spine_node:setSkin("levelup10")
        offset = 30
    end
end
   
--更新强化TAB的提醒
function mercenary_levelup_panel:UpdateForgeRemind(flag)
    if self.forge_tab_remind_img then 
       self.forge_tab_remind_img:setVisible(flag)
    end
end
function mercenary_levelup_panel:RegisterEvent()
    --以后 强化，觉醒，开启宝具等只需要这一个事件
    graphic:RegisterEvent("update_mercenary_info", function(mercenary_id)
        --强化成功， 觉醒成功， 开启宝具， 限界突破
        if not self.root_node:isVisible() then
            return
        end

        self:UpdateMercenayInfo()
        self.troop_bp_text:setString(tostring(troop_logic:GetTroopBP()))
    end)

    graphic:RegisterEvent("upgrade_leader_weapon_lv", function()
        --主角武器强化
        if not self.root_node:isVisible() then
            return
        end
        self:UpdateMercenayInfo()
        self.troop_bp_text:setString(tostring(troop_logic:GetTroopBP()))
    end)

    graphic:RegisterEvent("update_mercenary_level", function(mercenary_id, level_diff)
        if not self.root_node:isVisible() then
            return
        end

        --升级成功
        for i = 1, self.sub_panel_num do
            local sub_panel = self.mercenary_sub_panels[i]

            local mercenary = troop_logic:GetMercenaryInfo(sub_panel.mercenary_id)
            if mercenary then
                sub_panel:Load(mercenary)
                if sub_panel.mercenary_id == mercenary_id then

                    self:PlayAnimation(sub_panel, level_diff)
                    --检测是否可以升多级
                    sub_panel:CheckCanMultiLevel(mercenary_id)
                end
            end
        end

        self.troop_bp_text:setString(tostring(troop_logic:GetTroopBP()))
    end)
    
    --强化提醒
    graphic:RegisterEvent("remind_forge" , function(flag)
        self:UpdateForgeRemind(flag)
    end)

    -- 切换到强化页签
    graphic:RegisterEvent("change_to_forge" , function(flag)
         self.click_tab_method(self.forge_tab_img,ccui.TouchEventType.ended) 
    end)
    --宝具升级
    graphic:RegisterEvent("mercenary_artifact_upgrade" , function(result,mercenary_id)
        if result == "success" then
            self:UpdateMercenayInfo()
            self.troop_bp_text:setString(tostring(troop_logic:GetTroopBP()))
        end
    end)
    
end

function mercenary_levelup_panel:RegisterWidgetEvent()
    local click_tab_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local index = widget:getTag()
            self:UpdateTabStatus(index)

            for i = 1, self.sub_panel_num do
                local sub_panel = self.mercenary_sub_panels[i]

                local mercenary = troop_logic:GetMercenaryInfo(sub_panel.mercenary_id)
                if mercenary then
                    sub_panel:Load(mercenary)
                end
            end
        end
    end
    self.click_tab_method = click_tab_method
    self.levelup_tab_img:addTouchEventListener(click_tab_method)
    self.forge_tab_img:addTouchEventListener(click_tab_method)

    self.levelup1_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            local index = widget:getTag()
            local sub_panel = self.mercenary_sub_panels[index]

            local mercenary = troop_logic:GetMercenaryInfo(sub_panel.mercenary_id)
            local reach_max_wakeup = (mercenary.wakeup == mercenary.template_info.max_wakeup)
            if mercenary.level == constants["MAX_LEVEL"] and reach_max_wakeup then
                --升至满级
                return
            end

            if mercenary.level < constants["CAN_WAKEUP_LEVEL"] or reach_max_wakeup then
                sub_panel.last_click_time = time_logic:Now()
                sub_panel.level_delta = 0

                self.levelup_spine_node:setTimeScale(1.5)
                self.cur_selected_sub_panel = sub_panel
            end

        elseif event_type == ccui.TouchEventType.ended then

            local index = widget:getTag()
            local sub_panel = self.mercenary_sub_panels[index]
            audio_manager:PlayEffect("click")

            if self.cur_tab_type == TAB_TYPE["levelup"] then
                sub_panel.last_click_time = nil
                self.cur_selected_sub_panel = nil

                if sub_panel.level_delta == 0 then
                    sub_panel.level_delta = 1
                end
                self.levelup_spine_node:setTimeScale(1.0)

                --升级或者觉醒
                sub_panel:LevelupOrWakeUp()

            else
                sub_panel:ForgeOrOpenArtifact()
            end
        end
    end

    self.levelup2_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            --升级
            local index = widget:getTag()
            local sub_panel = self.mercenary_sub_panels[index]
            sub_panel:MultiLevelUp()
        end
    end

    --突破
    self.force_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            --突破
            local index = widget:getTag()
            local sub_panel = self.mercenary_sub_panels[index]
            sub_panel:UpgradeForce()
        end
    end

    self.back_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)
end

return mercenary_levelup_panel
