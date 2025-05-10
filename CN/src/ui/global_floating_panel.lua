local config_manager = require "logic.config_manager"
local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local troop_logic = require "logic.troop"
local user_logic = require "logic.user"
local panel_util = require "ui.panel_util"
local platform_manager = require "logic.platform_manager"

local cooperative_skill_config = config_manager.cooperative_skill_config
local mercenary_config = config_manager.mercenary_config

local INTERVAL_Y = 94
local INTERVAL_X = 200

local PLIST_TYPE = ccui.TextureResType.plistType
local MIN_BG_HEGHT = 134
local DESC_LINE_HEIGHT = 30

local mercenary_sub_panel = panel_prototype.New(t)
mercenary_sub_panel.__index = mercenary_sub_panel

function mercenary_sub_panel.New()
    return setmetatable({}, mercenary_sub_panel)
end

function mercenary_sub_panel:Init(root_node)
    self.root_node = root_node

    --root_node 为人物背景图
    self.role_icon_img = root_node:getChildByName("icon")
    self.is_in_formation_text = root_node:getChildByName("is_in_formation_text")
    self.in_formation_bg_img = root_node:getChildByName("in_formation_bg")
    self.num_text = root_node:getChildByName("num")

    self.name_text = root_node:getChildByName("name")

    self.root_node:setCascadeColorEnabled(false)
    self.in_formation_bg_img:setCascadeColorEnabled(false)

    self.root_node:ignoreContentAdaptWithSize(true)
    self.role_icon_img:ignoreContentAdaptWithSize(true)
    self.role_icon_img:setScale(2, 2)
end

function mercenary_sub_panel:Show(template_id, need_num)
    -- body
    local mercenary_template_info = mercenary_config[template_id]

    local quality = mercenary_template_info.quality
    --FYD update
    if need_num and (need_num == 1) then
        self.name_text:setString(mercenary_template_info.name)
    elseif need_num and (need_num >1) then
       self.name_text:setString(need_num.."x "..mercenary_template_info.name)
    end  

    local font_height = platform_manager:GetChannelInfo().coop_skill_mercenary_list_name_font_height
    if font_height then
       self.name_text:setFontSize(font_height)   
    end
    local two_line_height = platform_manager:GetChannelInfo().coop_skill_mercenary_list_name_height
    if two_line_height then
        local originWidth = self.name_text:getContentSize().width
        self.name_text:setContentSize(originWidth, two_line_height)
    end
    
    self.name_text:setColor(panel_util:GetColor4B(client_constants["TEXT_QUALITY_COLOR"][quality]))

    self.role_icon_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. mercenary_template_info.sprite .. ".png", PLIST_TYPE)
    self.root_node:setColor(panel_util:GetColor4B(client_constants["BG_QUALITY_COLOR"][quality]))

    self.root_node:setVisible(true)
end

function mercenary_sub_panel:IsInFormation(can_coop, need_num, cur_num)
    --未招募
    if can_coop == 1 then
        self.in_formation_bg_img:setColor(panel_util:GetColor4B(0xe34c1d))
        self.num_text:setVisible(false)
        self.is_in_formation_text:setVisible(true)
        self.is_in_formation_text:setString(lang_constants:Get("coop_mercenarys_not_recruit"))

    --已招募但没有在阵容中
    elseif can_coop == 2 then
        self.in_formation_bg_img:setColor(panel_util:GetColor4B(0xf7d620))

        if cur_num == 0 then
            self.num_text:setVisible(false)
            --self.num_text:setString(cur_num)
            self.is_in_formation_text:setString(lang_constants:Get("coop_mercenarys_not_in_formation"))
        else
            self.num_text:setVisible(true)
            self.num_text:setString(cur_num)
            self.is_in_formation_text:setString(lang_constants:Get("coop_mercenarys_all_in_formation"))
        end

    --在阵容中
    elseif can_coop == 3 then
        self.in_formation_bg_img:setColor(panel_util:GetColor4B(0xb1e03f))
        self.num_text:setVisible(true)
        self.num_text:setString(cur_num)
        self.is_in_formation_text:setString(lang_constants:Get("coop_mercenarys_all_in_formation"))
    end
end

--合体技佣兵名单浮层
local coop_mercenary_list_sub_panel = panel_prototype.New()

function coop_mercenary_list_sub_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/coop_skill_mercenary_list_panel.csb")
    local root_node = self.root_node

    self.bg_img = root_node:getChildByName("bg")
    self.bg_img:setAnchorPoint(0.5, 1)
    self.template_panel = self.bg_img:getChildByName("role_bg")

    self.mercenary_sub_panels = {}

    local sub_panel = mercenary_sub_panel.New()
    sub_panel:Init(self.template_panel)
    self.mercenary_sub_panels[1] = sub_panel

    self.sub_panel_num = 1

    self.template_panel:setVisible(false)
    self.cur_mercenary_tempalte_ids = {}
end

function coop_mercenary_list_sub_panel:CreateMercenarySubPanels(mercenary_type_num)
    if self.sub_panel_num < mercenary_type_num  then
        for i = (self.sub_panel_num + 1), mercenary_type_num do
            local sub_panel = mercenary_sub_panel.New()
            sub_panel:Init(self.template_panel:clone())
            self.bg_img:addChild(sub_panel.root_node)

            self.mercenary_sub_panels[i] = sub_panel
        end
        self.sub_panel_num = #self.mercenary_sub_panels
    end
end

function coop_mercenary_list_sub_panel:Show(formation_id, skill_id, x, y)
    self.formation_id = formation_id or troop_logic:GetCurFormationId()
    local coop_skill = cooperative_skill_config[skill_id]

    if not coop_skill then
        return
    end

    local mercenary_type_num = coop_skill.mercenary_type_num
    local coop_mercenary_ids = coop_skill.mercenary_ids

    --判断是否要创建panel
    self:CreateMercenarySubPanels(mercenary_type_num)

    --判断阵容中的佣兵
    local mercenary_list = troop_logic:GetFormationMercenaryList(self.formation_id)
    local cur_mercenary_num = #mercenary_list

    for id, _ in pairs(self.cur_mercenary_tempalte_ids) do
        self.cur_mercenary_tempalte_ids[id] = nil
    end

    for i, mercenary in ipairs(mercenary_list) do
        local template_id = mercenary.template_id
        self.cur_mercenary_tempalte_ids[template_id] = self.cur_mercenary_tempalte_ids[template_id] and (self.cur_mercenary_tempalte_ids[template_id] + 1) or 1
    end

    local index = 1
    for mercenary_template_id, need_num in pairs(coop_mercenary_ids) do
        self.mercenary_sub_panels[index]:Show(mercenary_template_id, need_num)

        local cur_num = self.cur_mercenary_tempalte_ids[mercenary_template_id]
        cur_num = cur_num and cur_num or 0

        local can_coop = 0 --(1:没有招募到此佣兵，2：阵容中的佣兵数量 < 需要的佣兵数量 3：满足发动条件)

        if cur_num < need_num then
            --未招募到佣兵
            if not troop_logic:MercenaryIsInMercenaryList(mercenary_template_id) then
                can_coop = 1
            else
                --佣兵数量 < 需要的佣兵数量
                can_coop = 2
            end
        else
            --上阵人数 > 需要人数
            can_coop = 3
        end

        self.mercenary_sub_panels[index]:IsInFormation(can_coop, need_num, cur_num)

        index = index + 1
    end

    --设定大小和位置
    local max_row = math.ceil(mercenary_type_num / 2)
    local height = max_row * INTERVAL_Y + 20

    self.bg_img:setContentSize(cc.size(430, height))

    for i = 1, self.sub_panel_num do
        local sub_panel = self.mercenary_sub_panels[i]
        if i <= mercenary_type_num then
            local x, y = 20, 0
            if i % 2 == 0 then
                x = 20 + INTERVAL_X
            end

            local row = math.ceil(i / 2)
            y = height - (row -1) * INTERVAL_Y - 20

            sub_panel.root_node:setPosition(x, y)
            sub_panel.root_node:setVisible(true)
        else
            sub_panel.root_node:setVisible(false)
        end
    end

    self.root_node:setLocalZOrder(2000)

    local x = x or 10
    local y = y or 800
    self.bg_img:setPosition(x, y)
    self.root_node:setVisible(true)
end

--名称和描述浮层
local name_and_desc_floating_sub_panel = panel_prototype.New()

function name_and_desc_floating_sub_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/global_floating_panel.csb")

    self.bg_img = self.root_node:getChildByName("skill_info_bg")
    self.name_text = self.bg_img:getChildByName("name")
    self.bg_init_width = self.bg_img:getContentSize().width

    self.desc_text = self.bg_img:getChildByName("desc")
    self.line_img = self.bg_img:getChildByName("line")

    self.bg_img:setAnchorPoint(0, 0)
    self.bg_img:setPosition(0, 0)

    self.root_node:setAnchorPoint(0.5, 0)

    self.root_node:setPosition(0, 0)
end

--最后一个参数：浮层是否显示在下面
function name_and_desc_floating_sub_panel:Show(name, desc, pos_x, pos_y, is_bottom)
    self.name_text:setString(name)
    self.desc_text:setString(desc)

    self.desc_text:getVirtualRenderer():setMaxLineWidth(380)

    self.bg_height = self:SetBgContentSize(pos_x, pos_y, is_bottom)

    self.root_node:setVisible(true)
end

function name_and_desc_floating_sub_panel:Hide()
    self.root_node:setVisible(false)
end

function name_and_desc_floating_sub_panel:SetBgContentSize(pos_x, pos_y, is_bottom)
    local label_render = self.desc_text:getVirtualRenderer()
    local line_num = label_render:getStringNumLines()
    if platform_manager:GetChannelInfo().is_open_system then
        local size = self.desc_text:getAutoRenderSize()
        local content_size = label_render:getContentSize()
        line_num = math.ceil(size.width / content_size.width) + 1
    end 
    local height = MIN_BG_HEGHT

 
    local min_height = platform_manager:GetChannelInfo().gloabal_floating_res_detail_min_height 
    if min_height then
       height = min_height
    end

    if line_num > 2 then
        height = height + (line_num - 2) * DESC_LINE_HEIGHT
    end

    self.root_node:setContentSize(cc.size(self.bg_init_width, height))
    self.bg_img:setContentSize(cc.size(self.bg_init_width, height))

    self.name_text:setPositionY(height - 20)

    self.line_img:setPositionY(height - 56)
    self.desc_text:setPositionY(height - 62)

    if pos_x < (self.bg_init_width / 2) then
        pos_x = (self.bg_init_width / 2)
    elseif pos_x + (self.bg_init_width / 2) > 640 then
        pos_x = 640 - (self.bg_init_width / 2)
    end

    if is_bottom then
        self.root_node:setPosition(pos_x, pos_y - self.bg_img:getContentSize().height - 20)
    else
        self.root_node:setPosition(pos_x, pos_y + 40)
    end

    return height
end

--浮层
local global_floating_panel = panel_prototype.New()

function global_floating_panel:Init()
    self.root_node = cc.Node:create()

    self.coop_mercenary_list_sub_panel = coop_mercenary_list_sub_panel
    self.coop_mercenary_list_sub_panel:Init()
    self.root_node:addChild(self.coop_mercenary_list_sub_panel.root_node)

    self.name_and_desc_floating_sub_panel = name_and_desc_floating_sub_panel
    self.name_and_desc_floating_sub_panel:Init()
    self.root_node:addChild(self.name_and_desc_floating_sub_panel.root_node)

    self.name_and_desc_floating_sub_panel.root_node:setVisible(false)
    self.coop_mercenary_list_sub_panel.root_node:setVisible(false)
    self.root_node:setVisible(false)
end

--默认显示名称和描述浮层
function global_floating_panel:Show(name, desc, pos_x, pos_y, is_bottom, formation_id, skill_id)
    if name then
        self.name_and_desc_floating_sub_panel:Show(name, desc, pos_x, pos_y, is_bottom)
    end

    if formation_id then
        local y = name and (pos_y - self.name_and_desc_floating_sub_panel.bg_height) or pos_y
        self.coop_mercenary_list_sub_panel:Show(formation_id, skill_id, pos_x, y - 20)
    end

    self.root_node:setVisible(true)
end

function global_floating_panel:Hide()
    self.name_and_desc_floating_sub_panel.root_node:setVisible(false)
    self.coop_mercenary_list_sub_panel.root_node:setVisible(false)
    self.root_node:setVisible(false)
end

return global_floating_panel
