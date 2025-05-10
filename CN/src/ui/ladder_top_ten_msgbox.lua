local constants = require "util.constants"
local client_constants = require "util.client_constants"
local ladder_logic = require "logic.ladder"
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local platform_manager = require "logic.platform_manager"

local PLIST_TYPE = ccui.TextureResType.plistType

local icon_template = require "ui.icon_panel"
local WORLD_RANK_TOP_TEN = 10

--玩家信息panel
local rival_info_sub_panel = panel_prototype.New()
rival_info_sub_panel.__index = rival_info_sub_panel

function rival_info_sub_panel.New()
    local t = {}
    return setmetatable(t, rival_info_sub_panel)
end

function rival_info_sub_panel:Init(root_node)
    self.root_node = root_node

    self.name_text = root_node:getChildByName("name")

    self.rank_num_text = root_node:getChildByName("rank")

    self.bp_text = root_node:getChildByName("bp_value")
    self.reward_num_text = root_node:getChildByName("reward_num")

    self.rank_bg_img = root_node:getChildByName("rank_bg")

    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(root_node)
    self.icon_panel:SetPosition(120, 66)
    root_node:getChildByName("role"):setVisible(false)
end


function rival_info_sub_panel:ReLoadInfo(pos)
    local rival_info = ladder_logic:GetTopTenPlayerInfo(pos)

    self.name_text:setString(rival_info.leader_name)
    self.bp_text:setString(rival_info.battle_point)

    local cur_rank_reward_num = 0
    local cur_rank = rival_info.rank

    local reward_rank = constants.LADDER_REWARD_RANK

    for i = 1, #reward_rank do
        if cur_rank >= reward_rank[i] then
            cur_rank_reward_num = constants.LADDER_REWARD[reward_rank[i]]
        else
            break
        end
    end

    self.rank_num_text:setString(rival_info.rank)

    self.reward_num_text:setString(cur_rank_reward_num)
    local template_id = rival_info.template_id
    self.icon_panel:Show(constants.REWARD_TYPE["mercenary"], template_id, nil, nil, false)

    if pos == 1 then
        self.rank_bg_img:setColor(panel_util:GetColor4B(0xFFDD00))
    elseif pos >= 3 then
        self.rank_bg_img:setColor(panel_util:GetColor4B(0xCBB48A))
    end
end

--排名前10的玩家
local ladder_top_ten_msgbox = panel_prototype.New(true)

function ladder_top_ten_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/ladder_top_ten_msgbox.csb")

    self.list_view = self.root_node:getChildByName("list_view")

    --多语言调整文本大小
    local language = platform_manager:GetLocale()
    if language == "fr" or language == "ru" and platform_manager:GetChannelInfo().ladder_top_ten_msgbox_change_desc_size then
        self.desc_text = self.root_node:getChildByName("desc")
        self.desc_text:setPositionY(self.desc_text:getPositionY() + 10)
        self.desc_text:setContentSize(self.desc_text:getContentSize().width, self.desc_text:getContentSize().height + 30)
    end

    local template = self.root_node:getChildByName("template")

    self.top_ten_players = {}

    for i = 1, WORLD_RANK_TOP_TEN  do
        local sub_panel = rival_info_sub_panel.New()
        sub_panel:Init(template:clone())
        self.list_view:addChild(sub_panel.root_node)
        self.top_ten_players[i] = sub_panel
    end

    template:setVisible(false)
    self:RegisterWidgetEvent()
end

function ladder_top_ten_msgbox:Show()
    self.root_node:setVisible(true)
    self.list_view:scrollToTop(0.2, true)
    for i = 1, WORLD_RANK_TOP_TEN do
        self.top_ten_players[i]:ReLoadInfo(i)
    end
end

function ladder_top_ten_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), "ladder_top_ten_msgbox")
end

return ladder_top_ten_msgbox
