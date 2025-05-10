local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local constants = require "util.constants"
local campaign_logic = require "logic.campaign"
local config_manager = require "logic.config_manager"
local client_constants = require "util.client_constants"
local platform_manager = require "logic.platform_manager"

local PLIST_TYPE = ccui.TextureResType.plistType

local RANK_COLOR_BLEND = {0xFFDD00, 0xffffff}
--玩家信息panel
local rank_info_sub_panel = panel_prototype.New()
rank_info_sub_panel.__index = rank_info_sub_panel

function rank_info_sub_panel.New()
    local t = {}
    return setmetatable(t, rank_info_sub_panel)
end

function rank_info_sub_panel:Init(root_node)
    self.root_node = root_node

    self.role = root_node:getChildByName("role")
    self.role:setScale(2, 2)

    self.name = root_node:getChildByName("name")
    self.point_value = root_node:getChildByName("point_value")
    self.reward_num = root_node:getChildByName("reward_num")
    self.rank = root_node:getChildByName("rank")
    self.rank_bg = root_node:getChildByName("rank_bg")

    --锚点居右紧挨icon
    if platform_manager:GetChannelInfo().campaign_rank_msgbox_rank_info_exp_desc_ap_right then
        local exp_desc = root_node:getChildByName("exp_desc")
        local reward_icon = root_node:getChildByName("reward_icon")
        exp_desc:setAnchorPoint({x=1,y=0.5})
        exp_desc:setPositionX(reward_icon:getPositionX()-reward_icon:getContentSize().width/2*0.6-5)
    end

end

function rank_info_sub_panel:ReLoadInfo(data)
    if data == nil then
        return
    end

    self.root_node:setVisible(true)

    self.rank:setString(data.rank)
    self.name:setString(data.leader_name)
    self.point_value:setString(data.score)

    for i,v in ipairs(campaign_logic.top_score_list) do
        if v.min<=data.rank and v.max >= data.rank then
            self.reward_num:setString(v.value)
        end
    end

    local blend_color = RANK_COLOR_BLEND[data.rank] or 0xCBB48A
    self.rank_bg:setColor(panel_util:GetColor4B(blend_color))


    local conf = config_manager.mercenary_config[data.template_id]
    self.role:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. conf.sprite .. ".png", PLIST_TYPE)
end

local campaign_rank_msgbox = panel_prototype.New(true)
function campaign_rank_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/campaign_top_ten_panel.csb")

    local root_node = self.root_node

    self.list_view = root_node:getChildByName("list_view")

    local template = root_node:getChildByName("template")
    template:setVisible(false)

    self.top_ten_players = {}

    for i = 1, 10  do
        local sub_panel = rank_info_sub_panel.New()
        sub_panel:Init(template:clone())
        self.list_view:addChild(sub_panel.root_node)
        self.top_ten_players[i] = sub_panel
    end

    self:RegisterWidgetEvent()
end

function campaign_rank_msgbox:Show()
    self.root_node:setVisible(true)
    if not campaign_logic.top_rank_list then
        return 
    end
    for k,v in pairs(campaign_logic.top_rank_list) do
        self.top_ten_players[v.rank]:ReLoadInfo(v)
    end
end

function campaign_rank_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), "campaign_rank_msgbox")
end

return campaign_rank_msgbox
