local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local config_manager = require "logic.config_manager"

local troop_logic = require "logic.troop"
local bit = require "bit"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local MERCENARY_BG_SPRITE = client_constants["MERCENARY_BG_SPRITE"]

local MERCENARY_TEMPLATE_PANEL_SOURCE = client_constants["MERCENARY_TEMPLATE_PANEL_SOURCE"]
local SORT_TYPE = client_constants["SORT_TYPE"]

local PLIST_TYPE = ccui.TextureResType.plistType

local MAX_CONTRACT_LV = constants["MAX_CONTRACT_LV"]

local INTERVAL_X = 124
local INTERVAL_Y = 124

local MERCENARY_GENRE_TEXT = client_constants["MERCENARY_GENRE_TEXT"]
local MERCENARY_GENRE_COLOR = client_constants["MERCENARY_GENRE_COLOR"]

--佣兵信息
local mercenary_template_panel = panel_prototype.New()
mercenary_template_panel.__index = mercenary_template_panel

function mercenary_template_panel.New()
    return setmetatable({}, mercenary_template_panel)
end

--创建一行佣兵 5个 (佣兵列表， 解雇佣兵，选择佣兵界面使用到)
--参数说明：父节点，要初始化的个数，哪个界面，第一个位置x，位置y， 第几行，回调函数
function mercenary_template_panel.Create(source, parent_node, sub_node, sub_panel_num, begin_x, begin_y, row, func)
    local mercenary_sub_panels = {}
    for i = 1, sub_panel_num do
        local sub_panel = mercenary_template_panel.New()
        sub_panel:Init(sub_node:clone(), source)
        parent_node:addChild(sub_panel.root_node)

        local x = begin_x + (i - 1) * INTERVAL_X
        local tag = (row - 1) * 5 + i

        sub_panel.root_node:setPosition(x, begin_y)
        sub_panel.root_node:setTag(tag)
        sub_panel.root_node:setTouchEnabled(true)

        if func then
            sub_panel.root_node:addTouchEventListener(func)
        end

        mercenary_sub_panels[i] = sub_panel
    end

    return mercenary_sub_panels
end

function mercenary_template_panel:SetSource(source)
    self.source = source
end

function mercenary_template_panel:Init(root_node, source)
    --formation 使用的模板跟其他的不太一致
    if source == MERCENARY_TEMPLATE_PANEL_SOURCE["formation"] then
        self.root_node = root_node

        self.role_img = root_node:getChildByName("role_img")
        self.level_text = root_node:getChildByName("level")
        panel_util:SetTextOutline(self.level_text)

        self.vacant_text = root_node:getChildByName("empty")
        self.desc_text = root_node:getChildByName("desc")
        self.maze_text = root_node:getChildByName("maze")

        self.vacant_text:setVisible(false)
        self.desc_text:setVisible(false)
        self.maze_text:setVisible(false)
    elseif source == MERCENARY_TEMPLATE_PANEL_SOURCE["vanity_adventure_formation"] or source == MERCENARY_TEMPLATE_PANEL_SOURCE["vanity_adventure_list"] then
        self.root_node = root_node
        self.level_text = root_node:getChildByName("type")
        self.role_img = root_node:getChildByName("role_img")
        self.pos_text = root_node:getChildByName("level_and_bp")
        self.empty_text = root_node:getChildByName("empty")
        self.role_level_bg = root_node:getChildByName("bg_label")
        self.residue_text = root_node:getChildByName("desc_myskill_title")
    else
        self.root_node = root_node
        self.level_text = root_node:getChildByName("level_and_bp")
        panel_util:SetTextOutline(self.level_text)
        self.role_img = root_node:getChildByName("role_img")
        self.fight_img = root_node:getChildByName("fight_icon")
        self.contract_img = root_node:getChildByName("contract_icon")

        self.fight_img:setVisible(false)
        self.contract_img:setVisible(false)
    end

    self.root_node:setCascadeColorEnabled(true)

    self.role_img:ignoreContentAdaptWithSize(true)
    self.role_img:setScale(2, 2)
    self.level_text:setLocalZOrder(12)
    self.source = source
    self.is_unlock = false -- 阵容专用
    self.template_id = 0
end

--加载数据   is_mine_formation_select  -->矿山开采阵容 因为这个阵容特殊每个阵容要和英雄绑定
function mercenary_template_panel:Load(mercenary, status, is_mine_formation_select)
    if not mercenary then
        return
    end

    self.mercenary = mercenary

    self.root_node:setColor(cc.c3b(255,255,255))
    if self.fight_img then
        self.fight_img:setVisible(true)
    end

    if self.contract_img then
        self.contract_img:setVisible(false)
    end

    if mercenary.instance_id ~= self.mercenary_id or self.template_id ~= mercenary.template_id then
        self.template_id = mercenary.template_id
        self.role_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. mercenary.template_info.sprite .. ".png", PLIST_TYPE)
        self.role_img:setVisible(true)
    end
    local mine_status1, mine_status2 = false,true   --矿山的状态
    if is_mine_formation_select then
        --是否在矿山阵容中
         mine_status1, mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary)
    end
    if self.source == MERCENARY_TEMPLATE_PANEL_SOURCE["vanity_adventure_formation"] then
        self.level_text:setString(lang_constants:Get(MERCENARY_GENRE_TEXT[mercenary.template_info.genre]))
        self.level_text:setColor(panel_util:GetColor4B(MERCENARY_GENRE_COLOR[mercenary.template_info.genre]))
        self.level_text:setVisible(true)
        self.pos_text:setColor(panel_util:GetColor4B(0xffffff))
        panel_util:SetTextOutline(self.pos_text)
        self.role_level_bg:setVisible(true)
        self.residue_text:setVisible(true)
        self.residue_text:setString(string.format(lang_constants:Get("vainty_adventure_can_battle_desc"),mercenary.battle_num))
        self.empty_text:setVisible(false)
        self.cant_touch = false
        if mercenary.battle_num <= 0 then
            self.cant_touch = true
            self.root_node:setColor(cc.c3b(180,180,180))
        end
    elseif self.source == MERCENARY_TEMPLATE_PANEL_SOURCE["vanity_adventure_list"] then
        self.level_text:setString(lang_constants:Get(MERCENARY_GENRE_TEXT[mercenary.template_info.genre]))
        self.level_text:setColor(panel_util:GetColor4B(MERCENARY_GENRE_COLOR[mercenary.template_info.genre]))
        self.level_text:setVisible(true)
        self.pos_text:setVisible(false)
        self.role_level_bg:setVisible(true)
        self.residue_text:setVisible(true)
        self.residue_text:setString(string.format(lang_constants:Get("vainty_adventure_can_battle_desc"),mercenary.battle_num))
        self.empty_text:setVisible(false)
        self.cant_touch = false
        if mercenary.battle_num <= 0 then
            self.cant_touch = true
            self.root_node:setColor(cc.c3b(180,180,180))
        end
    elseif self.source ~= MERCENARY_TEMPLATE_PANEL_SOURCE["formation"] then
        local img_path = "icon/mercenarylist/fighting_capacity.png"
        local found = false
        
        if troop_logic:IsMercenaryInFormation(mercenary, constants["GUILD_WAR_TROOP_ID"]) then 
           img_path = "button/listicon_2.png"
           found = true
        elseif troop_logic:IsMercenaryInFormation(mercenary, troop_logic:GetClientFormationId()) then
           found = true
        end
        --矿山阵容选择
        if mine_status1 then
            --矿山开采阵容选择是要显示在某个阵容中
            local mine_img_path = client_constants["MINE_ICON_IMG_PATH"]
            self.contract_img:loadTexture(mine_img_path, PLIST_TYPE)
            self.contract_img:setScale(1)
            self.contract_img:setVisible(true)
            self.root_node:setColor(cc.c3b(180,180,180))
        end

        self.fight_img:loadTexture(img_path, PLIST_TYPE)
        self.fight_img:setVisible(found)
    else
        self.vacant_text:setVisible(false)
        self.desc_text:setVisible(false)
        self.maze_text:setVisible(false)
    end

    self.root_node:loadTexture(MERCENARY_BG_SPRITE[mercenary.template_info.quality], PLIST_TYPE)
    
    if self.source ~= MERCENARY_TEMPLATE_PANEL_SOURCE["vanity_adventure_formation"] and self.source ~= MERCENARY_TEMPLATE_PANEL_SOURCE["vanity_adventure_list"] then
        local genre_text = ""
        local color = 0xFFFFFF

        if not mercenary.is_leader then
            genre_text = lang_constants:Get(MERCENARY_GENRE_TEXT[mercenary.template_info.genre])
            color = MERCENARY_GENRE_COLOR[mercenary.template_info.genre]
        end
        self.level_text:setString("Lv" .. mercenary.level .. genre_text)
        self.level_text:setColor(panel_util:GetColor4B(color))

        self.mercenary_id = mercenary.instance_id
        self.is_vacant = false
        self.is_unlock = false

        self:ShowStatus(status)

        --矿山阵容选择
        if self.source ~= MERCENARY_TEMPLATE_PANEL_SOURCE["formation"] and not mine_status2 then
            --矿山开采阵容选择是要显示在某个阵容中
            self.root_node:setColor(cc.c3b(180,180,180))
        end
    else
        self.mercenary_id = mercenary.instance_id
    end

    self.root_node:setVisible(true)
end

--解锁位置
function mercenary_template_panel:UnLockPosition(is_vacant, pos)
    if not pos then
        self.root_node:setVisible(false)
        return
    end

    if self.source == MERCENARY_TEMPLATE_PANEL_SOURCE["formation"] then
        self.root_node:loadTexture(MERCENARY_BG_SPRITE["formation_vacant"], PLIST_TYPE)
        self.vacant_text:setVisible(false)
        self.level_text:setString("")
        self.desc_text:setVisible(true)
        self.maze_text:setVisible(true)
        self.maze_text:setString(string.format(lang_constants:Get("troop_unlock_explore_num_maze_desc"), pos))
    elseif self.source == MERCENARY_TEMPLATE_PANEL_SOURCE["vanity_adventure_formation"] or self.source ~= MERCENARY_TEMPLATE_PANEL_SOURCE["vanity_adventure_list"] then
        self.empty_text:setVisible(false)
        self.level_text:setVisible(false)
        -- self.pos_text
        self.role_level_bg:setVisible(false)
        self.residue_text:setVisible(false)
    end

    self.is_vacant = is_vacant
    self.mercenary_id = 0
    self.role_img:setVisible(false)
    self.is_unlock = true

    self.root_node:setVisible(true)
end

function mercenary_template_panel:SetRoleTipVisible(flag)
    if self.fight_img then
        self.fight_img:setVisible(flag)
    end

    if self.contract_img then
        self.contract_img:setVisible(flag)
    end
end

function mercenary_template_panel:SetIndex(index)
    if self.pos_text then
        self.pos = index
        self.pos_text:setString(index)
    end
end

--空位置
function mercenary_template_panel:Clear(is_vacant)
    --没有佣兵
    if self.source == MERCENARY_TEMPLATE_PANEL_SOURCE["formation"] then
        self.root_node:loadTexture(MERCENARY_BG_SPRITE["formation_vacant"], PLIST_TYPE)
        self.vacant_text:setVisible(true)
        self.maze_text:setVisible(false)
        self.desc_text:setVisible(false)
    elseif self.source == MERCENARY_TEMPLATE_PANEL_SOURCE["vanity_adventure_formation"] or self.source == MERCENARY_TEMPLATE_PANEL_SOURCE["vanity_adventure_list"] then
        self.root_node:loadTexture(MERCENARY_BG_SPRITE["formation_vacant"], PLIST_TYPE)
        self.empty_text:setVisible(true)
        self.level_text:setVisible(false)
        if self.pos_text then
            self.pos_text:setColor(panel_util:GetColor4B(0xFFF2BE))
            panel_util:disableEffect(self.pos_text)
        end
        self.role_level_bg:setVisible(false)
        self.residue_text:setVisible(false)
    else
        self.root_node:loadTexture(MERCENARY_BG_SPRITE["empty"], PLIST_TYPE)
        self:SetRoleTipVisible(false)
    end
    self.is_vacant = is_vacant
    self.level_text:setString("")
    self.mercenary_id = 0
    self.role_img:setVisible(false)
    self.is_unlock = false

    self.root_node:setVisible(true)
end

--根据排序类型，选择info_sub_panel的显示状态
function mercenary_template_panel:ShowStatus(status)
    if self.mercenary_id == 0 then
        return
    end

    local mercenary = troop_logic:GetMercenaryInfo(self.mercenary_id)
    if mercenary == nil then
        return
    end
    local genre_text = ""
    local color = 0xFFFFFF

    if not mercenary.is_leader then
        genre_text = lang_constants:Get(MERCENARY_GENRE_TEXT[mercenary.template_info.genre])
        color = MERCENARY_GENRE_COLOR[mercenary.template_info.genre]
    end

    self.root_node:setColor(panel_util:GetColor4B(0xffffff))

    if status == SORT_TYPE["bp"] then
        local battle_point = panel_util:ConvertUnit(mercenary.battle_point)
        self.level_text:setString(battle_point .. genre_text)

    elseif status == SORT_TYPE["wakeup"] then
        self.level_text:setString(mercenary.wakeup .. "/" .. mercenary.template_info.max_wakeup .. genre_text)

    elseif status == SORT_TYPE["quality"] then
        local battle_point = panel_util:ConvertUnit(mercenary.battle_point)
        self.level_text:setString(battle_point .. genre_text)

    elseif status == SORT_TYPE["level"] then
        self.level_text:setString(lang_constants:Get("level_shot_string") .. mercenary.level .. genre_text)

    elseif status == SORT_TYPE["contract"] then
        if mercenary.is_leader then
            local leader_contract_lv  = troop_logic:GetLeaderContractConfIndex()
            if leader_contract_lv == 0 then
                self.level_text:setString(lang_constants:Get("leader_contract_num_is_0"))
            else
                self.level_text:setString(string.format(lang_constants:Get("mercenary_contract_desc"), leader_contract_lv))
            end
        else
            if troop_logic:CanContractLv(mercenary.template_info.ID) then
                self.level_text:setString(string.format(lang_constants:Get("mercenary_contract_desc"), mercenary.contract_lv) .. genre_text)
            else
                self.level_text:setString(lang_constants:Get("mercenary_can_not_contract") .. genre_text)
            end

            local is_in_formation = troop_logic:IsMercenaryInFormation(mercenary, troop_logic:GetClientFormationId())
            local resouce_is_enough = troop_logic:CheckContractResource(self.mercenary_id, mercenary.contract_lv + 1)
            local is_max_lv = troop_logic:CanContractLv(mercenary.template_info.ID, mercenary.contract_lv + 1)

            if is_in_formation then
                self.fight_img:loadTexture("icon/mercenarylist/fighting_capacity.png", PLIST_TYPE)

                if resouce_is_enough and is_max_lv then
                    self:SetRoleTipVisible(true)
                else
                    self.fight_img:setVisible(true)
                end
            else
                if resouce_is_enough and is_max_lv then
                    self.contract_img:setVisible(true)
                end
            end
        end

    elseif status == SORT_TYPE["genre"] then
        local battle_point = panel_util:ConvertUnit(mercenary.battle_point)
        self.level_text:setString(battle_point .. genre_text)
    end

    self.level_text:setColor( panel_util:GetColor4B(color))
    self.root_node:setVisible(true)
end

return mercenary_template_panel
