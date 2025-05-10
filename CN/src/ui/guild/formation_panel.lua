local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local guild_logic = require "logic.guild"
local user_logic = require "logic.user"
local troop_logic = require "logic.troop"

local panel_prototype = require "ui.panel"
local icon_template = require "ui.icon_panel"
local common_function_util = require "util.common_function"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local spine_manager = require "util.spine_manager"

local bit_extension = require "util.bit_extension"

local config_manager = require "logic.config_manager"

local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]
local PLIST_TYPE = ccui.TextureResType.plistType

local BUFF_TYPE = constants.GUILDWAR_BUFF_TYPE
local BUFF_FACTOR = constants.GUILDWAR_BUFF_FACTOR

local SHOW_BUTTON_TYPE = {
      ["NEW"] = 1,
      ["NORMAL"] = 2
}

local NODE_CELLS = 3

local tip_msgbox_panel = panel_prototype.New()
function tip_msgbox_panel:Init(root_node, parent_panel)
    self.parent_table = parent_panel
    self.root_node = root_node
    self.war_field = nil
    self.close_btn = self.root_node:getChildByName("close1_btn")
    self.desc_text = self.root_node:getChildByName("desc")
    self.change_btn = self.root_node:getChildByName("change_btn")
    self.confirm_btn = self.root_node:getChildByName("confirm_btn")

    self.shadow_bg = self.root_node:getChildByName("shadow")
    self.shadow_bg:setCascadeColorEnabled(true)
end

function tip_msgbox_panel:ShowButton(s_type)
    self.change_btn:setVisible(false)
    self.confirm_btn:setVisible(false)
   
    if s_type == SHOW_BUTTON_TYPE["NEW"] then 
        self.change_btn:setVisible(true)
        self.change_btn:setPositionX(320)
        self.desc_text:setString(lang_constants:Get("guild_war_warfield_new_tip"))

    elseif s_type == SHOW_BUTTON_TYPE["NORMAL"] then 
        self.change_btn:setPositionX(201)
        self.change_btn:setVisible(true)
        self.confirm_btn:setVisible(true)
        self.desc_text:setString(lang_constants:Get("guild_war_warfield_normal_tip"))
    end
end

function tip_msgbox_panel:Show(show_type, war_field)
    self.war_field = war_field
    self:ShowButton(show_type)
    self.root_node:setVisible(true)
end

local cell_panel = panel_prototype.New()

cell_panel.__index = cell_panel

function cell_panel.New()
    local t = {}
    return setmetatable(t, cell_panel)
end

function cell_panel:Init(template_node)
    self.root_node = template_node:getParent()
    self.template_node = template_node

    self.buff_img = self.template_node:getChildByName("buff_icon")
    self.buff_text = self.template_node:getChildByName("buff_value")
    self.buff_text:setLocalZOrder(2)
    self.arm_img = self.template_node:getChildByName("arm_icon")
    self.arm_img:setLocalZOrder(2)
    self.bp_text = self.template_node:getChildByName("bp_value")
    self.name_text = self.template_node:getChildByName("name")
    self.view_img = self.template_node:getChildByName("view_icon")
    self.view_img:setLocalZOrder(2)
    self.kick_img = self.template_node:getChildByName("kick_icon")
    self.mine_img = self.template_node:getChildByName("mine_icon")
    self.role_img = self.template_node:getChildByName("role")

    self.arm_img:setVisible(false)
    self.view_img:setVisible(false)
    self.mine_img:setVisible(false)
    self.kick_img:setVisible(false)

    self.kick_img:setTouchEnabled(true)
    self.arm_img:setTouchEnabled(true)
    self.view_img:setTouchEnabled(true)

    self.kick_flag = false

    self:LoadAnimation()
    self:RegisterWidgetEvent()
end

function cell_panel:LoadAnimation()
    -- self.buff_spine_node = spine_manager:GetNode("buff_ani", 0.32, true)
    -- self.buff_spine_node:setPosition(78, 17)
    -- self.template_node:addChild(self.buff_spine_node)
    -- self.buff_spine_node:setTimeScale(1.0)
    -- self.buff_spine_node:setVisible(true)
    -- self.buff_spine_node:setAnimation(0, "buff", true)

    self.arm_spine_node = spine_manager:GetNode("buff_ani", 0.45, true)
    self.arm_spine_node:setPosition(82, 71)
    self.template_node:addChild(self.arm_spine_node)
    self.arm_spine_node:setTimeScale(1.0)
    self.arm_spine_node:setVisible(false)
    self.arm_spine_node:setAnimation(0, "buff_shield_icon", true)

    self.view_spine_node = spine_manager:GetNode("buff_ani", 0.45, true)
    self.view_spine_node:setPosition(13, 69)
    self.template_node:addChild(self.view_spine_node)
    self.view_spine_node:setTimeScale(1.0)
    self.view_spine_node:setVisible(true)
    self.view_spine_node:setAnimation(0, "buff_rewardbtn_icon", true)
end

function cell_panel:Show(member)
    self.member = member 

    self.name_text:setString(self.member.leader_name)
    local bp = self.member.bp

    local genre_data, factor_data = guild_logic:GetGenreData()
    local all_num, genre_infos = panel_util:GetGenreInfos( self.member.genre_nums )

    local cur_genre = genre_data[self.member.war_field]
    local cur_factor = factor_data[self.member.war_field]

    if genre_infos[cur_genre] and genre_infos[cur_genre] > 0 then
        bp = math.ceil(bp + (bp / all_num) * genre_infos[cur_genre] * cur_factor / 100)
    end

    local has_buff = bit_extension:GetBitNum(self.member.buff_info, BUFF_TYPE["bp"]-1) == 1
    if has_buff then
        bp = math.ceil(bp * (1+BUFF_FACTOR[BUFF_TYPE["bp"]]))
    end

    self.bp_text:setString(tostring(bp))
    self.buff_text:setString(tostring(self.member.buff_num))

    local conf = config_manager.mercenary_config[self.member.template_id]
    self.role_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. conf.sprite .. ".png", PLIST_TYPE)

    self.role_img:setVisible(true)
    self.template_node:setVisible(true)
end

function cell_panel:SwitchKickIcon()
    if self.kick_flag then 
      local arm_visible = self.arm_img:isVisible()
      self.kick_img:setVisible(arm_visible)
      self.arm_img:setVisible(not arm_visible)
      self.arm_spine_node:setVisible(not arm_visible)
    end
end

function cell_panel:SetKickFlag()
    self.kick_flag = true
end

function cell_panel:ShowSelfIcon()
    self.mine_img:setVisible(true)
end

function cell_panel:ShowBuyBuffIcon()
    self.arm_img:setVisible(true)
    self.arm_spine_node:setVisible(true)
end

function cell_panel:ShowViewIcon()
    self.view_img:setVisible(true)
    self.view_spine_node:setVisible(true)
end

function cell_panel:SetPosition(x, y)
    self.template_node:setPosition(cc.p(x, y))
end

function cell_panel:Hide()
    self.template_node:setVisible(false)
end

function cell_panel:GetNode()
    return self.template_node
end

function cell_panel:RemoveSelf()
    self.template_node:removeFromParent()
end

function cell_panel:RegisterWidgetEvent()

    self.kick_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_simple_msgbox", 
              lang_constants:Get("guild_war_kick_msgbox_title"), 
              lang_constants:Get("guild_war_kick_msgbox_tip"), 
              lang_constants:Get("common_confirm"),
              lang_constants:Get("common_cancel"),
              function()
                 guild_logic:UpdateWarField(self.member.user_id, client_constants["NO_WAR_FIELD"])
            end)
        end
    end)
    
    self.arm_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            guild_logic:QueryMemberTroop(self.member.user_id, client_constants["VIEW_GUILD_MEMBER_TROOP_MODE"]["buy_buff"])
        end
    end)

    self.view_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            guild_logic:QueryMemberTroop(self.member.user_id, client_constants["VIEW_GUILD_MEMBER_TROOP_MODE"]["view"])
        end
    end)
end

local formation_panel = panel_prototype.New(true)
function formation_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/guildwar_formation_panel.csb")

    self.war_field = 0

    tip_msgbox_panel:Init(self.root_node:getChildByName("msgbox"), self)
    tip_msgbox_panel:Hide()

    self.join_btn = self.root_node:getChildByName("join_btn")
    self.join_btn:setTag(0)
    self.quit_btn = self.root_node:getChildByName("quit_btn")

    self.genre_text = self.root_node:getChildByName("spec_icon")
    self.genre_text:setVisible(false)

    self.genre_desc_text = self.root_node:getChildByName("spec_desc")
    self.genre_desc_text:setVisible(false)

    self.scroll_view = self.root_node:getChildByName("scrollview")

    local content_size = self.scroll_view:getContentSize()
    self.sview_width, self.sview_height = content_size.width, content_size.height

    self.template_node = self.scroll_view:getChildByName("template")
    self.template_node:setVisible(false)

    self.kick_btn = self.root_node:getChildByName("kick_btn")
    self.kick_btn:setVisible(false)
    self.kick_btn_text = self.kick_btn:getChildByName("kick_txt")
    self.kick_btn_icon = self.kick_btn:getChildByName("kick_icon")

    self.adjust_btn = self.root_node:getChildByName("adjust_btn")
    self.adjust_btn:setVisible(false)

    self.no_member_text = self.root_node:getChildByName("node_txt")
    self.no_member_text:setVisible(false)

    self.members = {}

    self.sub_panels = {}

    self.kick_selected = false

    self.close_btn = self.root_node:getChildByName("close_btn")
    
    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function formation_panel:CheckIsJoin()
    self.join_btn:setVisible(false)
    self.quit_btn:setVisible(false)

    if not troop_logic:IsFirstOperation(constants["GUILD_WAR_TROOP_ID"]) then 
        self.join_btn:setTag(1)
    end

    if self.join_btn:getTag() == 1 then
        self.join_btn:setPositionX(152) 
        self.quit_btn:setPositionX(152)
        self.adjust_btn:setVisible(true)
    end

    self.adjust_btn:setPositionX(487)

    if not guild_logic:IsEnterForCurrentWar() then 
        self.quit_btn:setVisible(false)
        self.join_btn:setVisible(false)
        self.adjust_btn:setPositionX(317) 
    else
        if self.war_field == guild_logic:GetWarField() then 
            self.join_btn:setTag(1)
            self.quit_btn:setVisible(true)
        else
            self.join_btn:setVisible(true)
        end
    end
end

function formation_panel:SetKickBtnStatus(flag)
    local text_pos_add_x = 0
    self.kick_btn_icon:setVisible(flag)
    if self.war_field == guild_logic:GetWarField() then 
        self.quit_btn:setVisible(flag)
    else
        self.quit_btn:setVisible(false)
    end

    if flag then 
        text_pos_add_x = 64
        self.kick_btn_text:setString(lang_constants:Get("guild_war_kick_text"))
    else
        text_pos_add_x = 48
        self.kick_btn_text:setString(lang_constants:Get("guild_war_kick_exit_text"))
    end

    self.kick_btn_text:setPositionX(text_pos_add_x)
end

function formation_panel:Show(war_field)
    self.kick_selected = false
    self:SetKickBtnStatus(true)

    self.war_field = war_field
    self:RefreshGenre()

    self:CheckIsJoin()
    self:RefreshFormation()
    self.root_node:setVisible(true)
end

function formation_panel:RefreshGenre()
    self.genre_desc_text:setVisible(true)
    self.genre_text:setVisible(true)
    
    local genre_data, factor = guild_logic:GetGenreData()
    local cur_genre = genre_data[self.war_field]
    
    if cur_genre == 0 then 
        self.genre_text:setVisible(false)
        self.genre_desc_text:setString(lang_constants:Get("guild_war_warfield_no_bonus"))
    else
        local temp_name = lang_constants:Get("guild_war_genre_add" .. cur_genre)
        local genre_str = lang_constants:Get("mercenary_genre" .. cur_genre)

        local color_value = client_constants["MERCENARY_GENRE_COLOR"][cur_genre]
        self.genre_text:setVisible(true)
        self.genre_text:setColor(panel_util:GetColor4B(color_value))
        self.genre_text:setString(genre_str)
        self.genre_desc_text:setString(lang_constants:GetFormattedStr("guild_war_field_tip", lang_constants:Get("guild_war_genre_add" .. cur_genre)))
    end
end

function formation_panel:CheckMemberRights(cell, my_right, data)
    cell:ShowViewIcon()
    cell:ShowBuyBuffIcon()
    if user_logic:GetUserId() == data.user_id then 
        cell:ShowSelfIcon()
    else
        if my_right == constants.GUILD_GRADE["highstaff"] then 
            if data.grade_type == constants.GUILD_GRADE["staff"] then 
                cell:SetKickFlag()
            end
        elseif my_right == constants.GUILD_GRADE["chairman"] then 
            cell:SetKickFlag()
        end
    end
end

function formation_panel:RefreshFormation()
    for i, sub_panel in ipairs(self.sub_panels) do 
        sub_panel:RemoveSelf()
    end

    self.sub_panels = {}
    self.members = guild_logic:GetFieldMembersByField(self.war_field)

    local sub_start_x = 110
    local sub_x = 0
    local offset_x = 204
    local offset_y = 165
    local SUB_PANEL_HEIGHT = 169
    local my_right = guild_logic:GetMyGuildRight()
    local only_me_flag = false
    local member_nums = #self.members
    
    local height = math.max(self.sview_height, math.ceil(member_nums / 3) * SUB_PANEL_HEIGHT)

    self.scroll_view:setInnerContainerSize(cc.size(self.sview_width, height))
    self.scroll_view:getInnerContainer():setPositionY(self.sview_height - height)

    if member_nums > 0 then 
        table.sort(self.members, function(a,b) return a.bp < b.bp end)
        for k, v in ipairs(self.members) do 
            if k % NODE_CELLS == 1 then 
                sub_x = sub_start_x
                height = height - offset_y
            else
                sub_x = sub_x + offset_x
            end
            local sub_panel = cell_panel.New()
            self.sub_panels[k] = sub_panel

            sub_panel:Init(self.template_node:clone())
            sub_panel:SetPosition(sub_x, height)
            self:CheckMemberRights(sub_panel, my_right, v)
            sub_panel:Show(v)
            if sub_panel.mine_img:isVisible() then 
                only_me_flag = true 
            end
            self.scroll_view:addChild(sub_panel:GetNode())
        end
    end
    
    only_me_flag = #self.members == 1 and only_me_flag 

    self.kick_btn:setVisible( not only_me_flag and #self.members > 0 and my_right > constants["GUILD_GRADE"].staff )
    self.no_member_text:setVisible(#self.members == 0)
end

function formation_panel:RegisterEvent()
    graphic:RegisterEvent("guildwar_formation_refresh", function(user_id, new_field, old_field)
        if not self.root_node:isVisible() then
            return
        end

        if new_field == self.war_field or old_field == self.war_field then
            self:CheckIsJoin()
            self:RefreshFormation()
            if self.kick_selected then 
                self:SwitchSubPanelIcon()
            end
        end
    end)

    graphic:RegisterEvent("update_guild_member_buff", function(member_id, member)
        if not self.root_node:isVisible() then
            return
        end

        if self.war_field ~= member.war_field then
            return
        end

        for i, sub_panel in ipairs(self.sub_panels) do 
            if sub_panel.member.user_id == member_id then
                sub_panel:Show(member)
                break
            end
        end
    end)
end

function formation_panel:SwitchSubPanelIcon()
    for k, v in ipairs(self.sub_panels) do 
        v:SwitchKickIcon()
    end
end

function formation_panel:ClickKickBtn()
    self:SetKickBtnStatus(self.kick_selected)
    self.kick_selected = not self.kick_selected

    self:SwitchSubPanelIcon()
end

function formation_panel:RegisterWidgetEvent()
    self.kick_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")
            self:ClickKickBtn()
        end
    end)

    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())

    self.join_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")
            local s_type = SHOW_BUTTON_TYPE["NORMAL"]
            local button_status = widget:getTag()
            if button_status == 0 then 
                s_type = SHOW_BUTTON_TYPE["NEW"]
                widget:setTag(1)
            end
            if button_status == 0 then 
                tip_msgbox_panel:Show(s_type, self.war_field)
            else
                guild_logic:UpdateWarField(user_logic:GetUserId(), self.war_field)
            end
        end
    end)

    self.quit_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")
            guild_logic:UpdateWarField(user_logic:GetUserId(), client_constants["NO_WAR_FIELD"])
        end
    end)

    self.adjust_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")
            local back_panel = "guild.formation_panel"
            local ex_params = {}
            ex_params[1] = self.war_field
            graphic:DispatchEvent("hide_world_sub_panel", "guild.formation_panel")
            graphic:DispatchEvent("show_world_sub_scene", "formation_sub_scene", SCENE_TRANSITION_TYPE["none"], client_constants["FORMATION_PANEL_MODE"]["guild"], back_panel, ex_params)
            graphic:DispatchEvent("update_battle_point", troop_logic:GetTroopBP(constants["GUILD_WAR_TROOP_ID"]))
        end    
    end)


    tip_msgbox_panel.close_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
           audio_manager:PlayEffect("click")
           tip_msgbox_panel:Hide()
           --self:Show(self.war_field)
        end
    end)

    tip_msgbox_panel.change_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
           audio_manager:PlayEffect("click")
           local back_panel = "guild.formation_panel"
           local ex_params = {}
           ex_params[1] = self.war_field
           graphic:DispatchEvent("hide_world_sub_panel", "guild.formation_panel")
           graphic:DispatchEvent("show_world_sub_scene", "formation_sub_scene", SCENE_TRANSITION_TYPE["none"], client_constants["FORMATION_PANEL_MODE"]["guild"], back_panel, ex_params)
           graphic:DispatchEvent("update_battle_point", troop_logic:GetTroopBP(constants["GUILD_WAR_TROOP_ID"]))
           tip_msgbox_panel:ShowButton(SHOW_BUTTON_TYPE["NORMAL"])
           tip_msgbox_panel:Hide()
           guild_logic:UpdateWarField(user_logic:GetUserId(), self.war_field)
        end
    end)
    
    tip_msgbox_panel.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            tip_msgbox_panel:Hide()
            guild_logic:UpdateWarField(user_logic:GetUserId(), self.war_field)
        end
    end)
end

return formation_panel
