local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local constants = require "util.constants"
local campaign_logic = require "logic.campaign"
local config_manager = require "logic.config_manager"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"
local lang_constants = require "util.language_constants"
local graphic = require "logic.graphic"
local icon_template = require "ui.icon_panel"

local guild_logic = require "logic.guild"



local PLIST_TYPE = ccui.TextureResType.plistType

local guild_search_panel = panel_prototype.New(true)
function guild_search_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/social_msgbox.csb")
    local root_node = self.root_node

    self.search_msgbox = root_node:getChildByName("search_msgbox")
    local invite_player_msgbox = root_node:getChildByName("invite_player_msgbox")
    invite_player_msgbox:setVisible(false)
    local deal_invitation_msgbox = root_node:getChildByName("deal_invitation_msgbox")
    deal_invitation_msgbox:setVisible(false)

    local title_txt = self.search_msgbox:getChildByName("title_bg"):getChildByName("title")
    title_txt:setString(lang_constants:Get("guild_search_title"))

    local input_bg_img = self.search_msgbox:getChildByName("input_bg")
    input_bg_img:setCascadeOpacityEnabled(false)

    self.user_id_textfield = self.search_msgbox:getChildByName("user_id")

    self.desc_text = self.search_msgbox:getChildByName("desc")
    self.desc_text:setString(lang_constants:Get("guild_search_input"))

    local desc_tips_text = self.search_msgbox:getChildByName("desc2")
    desc_tips_text:setVisible(true)
    desc_tips_text:setString(lang_constants:Get("guild_join_count_txt"))

    self.search_result_text = self.search_msgbox:getChildByName("search_status")

    self.friend_info_img = self.search_msgbox:getChildByName("friend_info_bg")
    self.player_name_text = self.friend_info_img:getChildByName("name")
    self.login_time_text = self.friend_info_img:getChildByName("login_time")
    self.login_time_text:setVisible(false)

    self.cant_invite_btn = self.friend_info_img:getChildByName("cancel_btn")
    self.invite_btn = self.friend_info_img:getChildByName("invite_btn")
    self.invite_btn:setTitleText(lang_constants:Get("guild_join_member"))
    self.search_btn = self.search_msgbox:getChildByName("search_btn")

    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(self.friend_info_img)
    self.icon_panel:SetPosition(80, 90)
    self.icon_panel.root_node:setTouchEnabled(true)

    self.guild_num_txt = self.friend_info_img:getChildByName("guild_num")
    self.guild_num_txt:setVisible(true)

    self.guild_bp_condition_txt = self.guild_num_txt:getChildByName("guild_bp_condition")

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function guild_search_panel:Show()
    self.root_node:setVisible(true)

    self.user_id_textfield:setString("")
    self.search_result_text:setVisible(true)

    self.search_result_text:setString(lang_constants:Get("cant_search"))
    self.search_result_text:setColor(panel_util:GetColor4B(0x9b8d5b))

    self.friend_info_img:setVisible(false)
    self.desc_text:setVisible(true)
end

function guild_search_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.search_msgbox:getChildByName("close_btn"), "guild_search_panel")

    self.search_btn:addTouchEventListener(function (sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local search_guild = self.user_id_textfield:getString()
            self.search_guild = search_guild
            guild_logic:SearchGuild(search_guild)
        end
    end)

    self.invite_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            -- local search_guild = self.user_id_textfield:getString()
            if self.member_num > constants["GUILD_MAX_MEMBER"] then
                graphic:DispatchEvent("show_prompt_panel", "guild_member_max")
                return
            end
            local battle_point = constants["GUILD_JOIN_THRESHOLD"][self.bp_limit_idx]
            local achievement_logic = require "logic.achievement"
            if battle_point > achievement_logic:GetStatisticValue(constants.ACHIEVEMENT_TYPE["max_bp"]) then
                graphic:DispatchEvent("show_prompt_panel", "guild_req_battle_point_less")
                return
            end

            graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("confirm_join_guild_title"),
                        lang_constants:Get("confirm_join_guild_desc"),
                        lang_constants:Get("common_confirm"),
                        lang_constants:Get("common_cancel"),
            function()
                 guild_logic:JoinGuild(self.search_guild)
            end)
        end
    end)

    self.cant_invite_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:Show()
        end
    end)

    self.user_id_textfield:addEventListener(function(sender, event_type)
        if event_type == ccui.TextFiledEventType.attach_with_ime then
            self.desc_text:setVisible(false)
        elseif event_type == ccui.TextFiledEventType.detach_with_ime then
        end
    end)
end

function guild_search_panel:RegisterEvent()
        -- 搜索结果
    graphic:RegisterEvent("search_guild_result", function(data)
        if not self.root_node:isVisible() then
            return
        end
        local result = data.result
        local guild_name = data.guild_name
        local template_id = data.template_id
        self.member_num = data.member_num
        self.bp_limit_idx = data.bp_limit_idx
        if "success" == result then
            self.friend_info_img:setVisible(true)
            self.player_name_text:setString(guild_name)
            self.icon_panel:Show(constants.REWARD_TYPE["mercenary"], template_id, nil, nil, true)
            self.guild_num_txt:setString(string.format(lang_constants:Get("guild_total_num"),data.member_num))
            local battle_point = constants["GUILD_JOIN_THRESHOLD"][self.bp_limit_idx]
            if battle_point == 0 then
                self.guild_bp_condition_txt:setVisible(false)
            else
                self.guild_bp_condition_txt:setVisible(true)
                self.guild_bp_condition_txt:setString(string.format(lang_constants:Get("guild_req_battle_point_txt"),panel_util:ConvertUnit(battle_point)))
            end
            self.search_result_text:setVisible(false)
        else
            self.search_result_text:setVisible(true)
            self.search_result_text:setString(lang_constants:Get(result))
        end
    end)
end

return guild_search_panel
