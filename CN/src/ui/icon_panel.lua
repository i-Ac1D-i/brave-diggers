--带有文本的icon_panel
local config_manager = require "logic.config_manager"

local resource_config = config_manager.resource_config
local item_config = config_manager.item_config
local destiny_skill_config = config_manager.destiny_skill_config
local rune_config = config_manager.rune_config

local graphic = require "logic.graphic"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local audio_manager = require "util.audio_manager"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local RESOURCE_TYPE = constants["RESOURCE_TYPE"]
local REWARD_TYPE = constants["REWARD_TYPE"]
local BIG_QUALITY_BG_IMG_PATH = client_constants["MERCENARY_BG_SPRITE"]
local ICON_TEMPLATE_MODE = client_constants["ICON_TEMPLATE_MODE"]

local SMALL_QUALITY_BG = client_constants["SMALL_QUALITY_BG"]
local BG_COLOR_MAP = client_constants["BG_QUALITY_COLOR"]
local MERCENARY_GENRE_TEXT = client_constants["MERCENARY_GENRE_TEXT"]
local MERCENARY_GENRE_COLOR = client_constants["MERCENARY_GENRE_COLOR"]

local PLIST_TYPE = ccui.TextureResType.plistType

--佣兵信息
local icon_panel = panel_prototype.New()
icon_panel.__index = icon_panel

function icon_panel.New(root_node, style)
    local new_item = {}
    style = style or ICON_TEMPLATE_MODE["with_text1"]

    if not root_node then
        new_item.root_node = icon_panel.meta_root_nodes[style]:clone()
        new_item.__is_add = true
    else
        new_item.root_node = root_node
        new_item.__is_add = false
    end

    new_item.mode = style
    return setmetatable(new_item, icon_panel)
end

function icon_panel:InitMeta()
    if self.is_meta_init then
        return
    end
    self.node1 = cc.CSLoader:createNode("ui/icon_template_with_text.csb")
    self.node1:retain()

    self.node2 = cc.CSLoader:createNode("ui/icon_template_with_text2.csb")
    self.node2:retain()

    self.node3 = cc.CSLoader:createNode("ui/icon_template_without_text.csb")
    self.node3:retain()

    self.meta_root_nodes = {}

    self.meta_root_nodes[1] = self.node1:getChildByName("bg")
    self.meta_root_nodes[2] = self.node2:getChildByName("bg")
    self.meta_root_nodes[3] = self.node3:getChildByName("bg")
    self.is_meta_init = true
end

function icon_panel:ClearMeta()
    if not self.is_meta_init then
        return
    end
    self.node1:release()
    self.node2:release()
    self.node3:release()
    self.is_meta_init = false
end


function icon_panel:Init(parent_node, hide_tooltip)
    self.root_node:setCascadeColorEnabled(false)
    self.root_node:setCascadeOpacityEnabled(false)
    self.icon_img = self.root_node:getChildByName("icon")
    self.icon_img:setAnchorPoint(0.5, 0.5)

    self.icon_img:ignoreContentAdaptWithSize(true)
    self.root_node:ignoreContentAdaptWithSize(true)

    if self.mode ~= ICON_TEMPLATE_MODE["no_text"] then
        self.text_bg_img = self.root_node:getChildByName("text_bg")
        self.num_text = self.root_node:getChildByName("num")
    end

    if self.__is_add then
        parent_node:addChild(self.root_node)
    end

    if not hide_tooltip then
        self:RegisterWidgetEvent()
    end

    self.conf = {}
end

function icon_panel:SetColor(color)
    self.icon_img:setColor(panel_util:GetColor4B(color))
    self.num_text:setColor(panel_util:GetColor4B(color))
end

--参数：if mode == no_text param1 = icon, param2 = quality
--else param1= need_num, param2 = show_cur_num(是否显示当前值)
function icon_panel:Show(source_type, template_id, param1, param2, is_big)

    self.template_id = template_id
    self.param1 = param1
    self.param2 = param2
    self.source_type = source_type

    local scale = 1
    if source_type == REWARD_TYPE["item"] then
        self.conf = item_config[template_id]

    elseif source_type == REWARD_TYPE["mercenary"] then
        self.conf = config_manager.mercenary_config[template_id]
        self.conf.icon = client_constants["MERCENARY_ROLE_IMG_PATH"] .. self.conf.sprite .. ".png"
        self.conf.desc = panel_util:GetMercenaryIntroduction(self.conf)
        scale = 2

    elseif source_type == REWARD_TYPE["soul_stone"] then
        self.conf = config_manager.mercenary_config[template_id]
        self.conf.icon = client_constants["MERCENARY_ROLE_IMG_PATH"] .. self.conf.sprite .. ".png"
        self.conf.desc = panel_util:GetMercenaryIntroduction(self.conf)
        scale = 2

    elseif source_type == REWARD_TYPE["resource"] then
        self.conf = resource_config[template_id]

    elseif source_type == REWARD_TYPE["camp_capacity"] then
        self:InitConfig("button/listicon_3.png", 1, lang_constants:Get("camp_capacity_name"), lang_constants:Get("camp_capacity_desc"))
        param1 = template_id

    elseif source_type == REWARD_TYPE["carnival_token"] then
        self.conf = config_manager.carnival_token_config[template_id]

    elseif source_type == REWARD_TYPE["destiny_weapon"] then
        self.conf = destiny_skill_config[template_id]
        self.conf.quality = 6
        param1 = 1

    elseif source_type == REWARD_TYPE["leader_bp"] then
        self:InitConfig("icon/mercenarylist/fighting_capacity.png", 1, nil, nil)
        param1 = template_id
        self.conf.quality = 5

    elseif source_type == REWARD_TYPE["campaign"] then
        --当季合战赛点
        if template_id == constants.CAMPAIGN_RESOURCE.score then
            self:InitConfig(client_constants.CAMPAIGN_RESOURCE_ICON.score, 1, lang_constants:Get("campaign_res_score"), lang_constants:Get("campaign_res_score_desc"))

        elseif template_id == constants.CAMPAIGN_RESOURCE.exp then
            self:InitConfig(client_constants.CAMPAIGN_RESOURCE_ICON.exp, 1, lang_constants:Get("campaign_res_exp"), lang_constants:Get("campaign_res_exp_desc"))
        end
    elseif source_type == REWARD_TYPE["rune"] then
        self.conf = rune_config[template_id]

    else
        if self.mode == ICON_TEMPLATE_MODE["no_text"] then
            self:InitConfig(param1, param2)
        end
    end

    self.icon_img:loadTexture(self.conf.icon, PLIST_TYPE)
    self.icon_img:setScale(scale, scale)

    self:LoadQualityBgImg(self.conf.quality or 1, is_big)
    self:SetTextStatus(template_id, param1 or 1, param2, is_big)

    self.root_node:setVisible(true)

    return self.conf
end

function icon_panel:GetIconResourceType()
    return self.conf.ID
end

--初始化配置(有些数据没有默认的csv表格，要手动构造一下)
function icon_panel:InitConfig(icon, quality, name, desc)
    local conf = {}
    conf.icon = icon
    conf.quality = quality
    conf.name = name
    conf.desc = desc
    self.conf = conf
end

--
function icon_panel:Load(source_type, icon, quality, num, name, desc, is_big)
    self.source_type = source_type
    self.icon_img:loadTexture(icon, PLIST_TYPE)
    self.num_text:setString(tostring(num))
    self:LoadQualityBgImg(quality, is_big)

    self:InitConfig(icon, quality, name, desc)
    self.root_node:setVisible(true)
end

function icon_panel:ShowTextBg(visible)
    self.text_bg_img:setVisible(visible)
    self.num_text:setVisible(visible)
end

function icon_panel:LoadQualityBgImg(quality, is_big)
    if is_big then
        self.root_node:loadTexture(BIG_QUALITY_BG_IMG_PATH[quality], PLIST_TYPE)
    else
        self.root_node:loadTexture(SMALL_QUALITY_BG, PLIST_TYPE)
        self.root_node:setColor(panel_util:GetColor4B(BG_COLOR_MAP[quality]))
    end

    local content_size = self.root_node:getContentSize()
    self.icon_img:setPosition(content_size.width / 2, content_size.height / 2)
end

--设定文本状态
function icon_panel:SetTextStatus(template_id, param1, param2, is_big)

    if self.mode == ICON_TEMPLATE_MODE["no_text"] then
        return
    end

    if self.text_bg_img then
        self.text_bg_img:setVisible(true)
    end

    self.num_text:setVisible(true)
    if self.source_type == REWARD_TYPE["mercenary"] then
        self.num_text:setString(lang_constants:Get(MERCENARY_GENRE_TEXT[self.conf.genre]))
        self.num_text:setColor(panel_util:GetColor4B(MERCENARY_GENRE_COLOR[self.conf.genre]))
        self.num_text:setVisible(true)
        return
    end

    if self.source_type == REWARD_TYPE["destiny_weapon"] then
        self.text_bg_img:setVisible(false)
        self.num_text:setVisible(false)
        return
    end

    local content_size = self.root_node:getContentSize()
    if is_big then
        self.text_bg_img:setContentSize(cc.size(content_size.width - 16, 28))
    else
        self.text_bg_img:setContentSize(cc.size(content_size.width - 16, 18))
    end

    local num_str
    param1 = param1 or self.param1 
    param2 = param2 or self.param2
    if param1 then
        num_str = tostring(panel_util:ConvertUnit(param1))

        self.cur_num = resource_logic:GetResourceNum(template_id)
        if param2 then
            if self.cur_num >= param1 then
                self.num_text:setColor(panel_util:GetColor4B(0xa1e01b))
            else
                self.num_text:setColor(panel_util:GetColor4B(0xf87f26))
            end

            local cur_num_str =   panel_util:ConvertUnit(self.cur_num)
            num_str = cur_num_str .. "/" .. num_str

        else
            self.num_text:setColor(panel_util:GetColor4B(0xffffff))
        end
    end

    --金币只显示消耗的
    if template_id == RESOURCE_TYPE["gold_coin"] or template_id == RESOURCE_TYPE["soul_chip"] then
        panel_util:ConvertUnit(param1, self.num_text)
    else
        self.num_text:setString(num_str)
    end
end

function icon_panel:SetPosition(x, y)
    self.root_node:setPosition(x, y)
    self.root_x = x
    self.root_y = y
end

--弹出详细信息
function icon_panel:RegisterWidgetEvent()
    self.root_node:setTouchEnabled(true)
    self.root_node:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")
            if self.source_type == REWARD_TYPE["mercenary"] then
                local mode = client_constants["MERCENARY_DETAIL_MODE"]["icon_template"]
                graphic:DispatchEvent("show_world_sub_panel", "mercenary_detail_panel", mode, self.template_id)
            else
                local pos = widget:getTouchBeganPosition()
                graphic:DispatchEvent("show_floating_panel", self.conf.name, self.conf.desc, pos.x, pos.y)
            end

        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            if self.source_type ~= REWARD_TYPE["mercenary"]then
                graphic:DispatchEvent("hide_floating_panel")
            end
        end
    end)
end

return icon_panel
