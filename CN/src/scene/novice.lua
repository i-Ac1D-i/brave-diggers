local graphic = require "logic.graphic"
local mining_logic = require "logic.mining"
local troop_logic = require "logic.troop"
local adventure_logic = require "logic.adventure"
local platform_manager = require "logic.platform_manager"

local spine_manager = require "util.spine_manager"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local audio_manager = require "util.audio_manager"
local config_manager = require "logic.config_manager"
local feature_config = require "logic.feature_config"

local sub_scene = require "scene.sub_scene"

local PLIST_TYPE = ccui.TextureResType.plistType


local MASK_ORIGIN = { x = 0, y = 0 }
local MASK_DESTINATION = { x = 640, y = 1136 }

local DEFAULT_MASK_ALPHA = 0.7
local MASK_COLOR = { a = 0.70, r = 0.0, g = 0.0, b = 0.0 }

local DEFAULT_TRANSITION_TIME = 0.25

--普通文本
local TEXT_COLOR_ONE = {a = 255, r = 255, g = 255, b = 255}
--对话文本
local TEXT_COLOR_TWO = {a = 255, r = 0, g = 0, b = 0}

local FONT_SIZE_ONE = 28
local FONT_SIZE_TWO = 28
local FONT_SIZE_ONE_EN = 22
local FONT_SIZE_TWO_EN = 22
local TEXT_WIDTH = 580
local TEXT_HEIGHT = 200
local VISIBLE_SIZE_WIDTH = cc.Director:getInstance():getVisibleSize().width
local VISIBLE_SIZE_HEIGHT = cc.Director:getInstance():getVisibleSize().height
local NOVICE_TRIGGER_TYPE = client_constants["NOVICE_TRIGGER_TYPE"]
local BATTLE_TYPE = client_constants["BATTLE_TYPE"]
local NOVICE_TYPE = client_constants["NOVICE_TYPE"]
local NOVICE_MARK = client_constants["NOVICE_MARK"]

local novice_sub_scene = sub_scene.New()

local novice_step = {}
novice_step.__index = novice_step

function novice_step:Play()
end

function novice_step:Stop()
end

function novice_step:Update(elapsed_time)
end

function novice_step:IsFinish()
    return true
end

function novice_step:OnTouch()
    audio_manager:PlayEffect("click")
end

function novice_step:OnRecvMsg(msg_name, msg_content)
end

local animation_step = setmetatable({}, novice_step)
animation_step.__index = animation_step

function animation_step.New(data)
    data.is_loop = data.is_loop or false
    data.scale = data.scale or 1.0
    setmetatable(data, animation_step)
end

function animation_step:Play()
    local spine_node = novice_sub_scene.animation_spine_node
    spine_node:setVisible(true)
    --spine_node:setToSetupPose()
    spine_node:setPosition(self.x, self.y)
    spine_node:setAnimation(0, self.animation_name, self.is_loop)
    spine_node:setRotation(self.rotation)
    spine_node:setScale(self.scale)

    novice_sub_scene.cur_animation_step = self
    if not self.is_loop then
        self.is_finish = false
    else
        self.is_finish = true
    end
end

function animation_step:Stop()
    local spine_node = novice_sub_scene.animation_spine_node
    spine_node:setVisible(false)
    spine_node:clearTrack(0)
end

local text_step = setmetatable({}, novice_step)
text_step.__index = text_step

function text_step.New(data)
    setmetatable(data, text_step)
end

function text_step:Play()
    local text = novice_sub_scene.text1
    text:setVisible(true)
    text:setPosition(self.x, self.y)
    text:setContentSize(self.width, self.height)

    text:setString(lang_constants.NOVICE_STR[self.content_id])
end

function text_step:Stop()
    novice_sub_scene.text1:setVisible(false)
end

local color = {}
local dialogue_step = setmetatable({}, novice_step)
dialogue_step.__index = dialogue_step

function dialogue_step.New(data)
    data.is_loop = data.is_loop or false
    setmetatable(data, dialogue_step)
end

function dialogue_step:Play()
    local spine_node = novice_sub_scene.dialogue_spine_node
    --spine_node:setToSetupPose()
    spine_node:setVisible(true)
    spine_node:setAnimation(0, self.animation_name, self.is_loop)

    novice_sub_scene.cur_dialogue_step = self
    if not self.is_loop then
        self.is_finish = false
    else
        self.is_finish = true
    end

    spine_node:setPosition(320, 0)

    local text = novice_sub_scene.text2
    text:setVisible(true)
    text:setString(lang_constants.NOVICE_STR[self.content_id])
end

function dialogue_step:Stop()
    local spine_node = novice_sub_scene.dialogue_spine_node
    spine_node:setVisible(false)
    spine_node:clearTrack(0)

    novice_sub_scene.text2:setVisible(false)
end

function dialogue_step:Update(elapsed_time)
    local spine_node = novice_sub_scene.dialogue_spine_node
    local widget = novice_sub_scene.text2

    local x, y, scale_x, scale_y, alpha, rotation, r, g, b = spine_node:getSlotTransform("txt1")
    widget:setPosition(320 + x, y)
    widget:setScale(scale_x, scale_y)
    color.r = r
    color.b = b
    color.g = g
    widget:setColor(color)
end

function dialogue_step:IsFinish()
    return self.is_finish
end

local talker_step = setmetatable({}, novice_step)
talker_step.__index = talker_step

function talker_step.New(data)
    data.is_loop = data.is_loop or false

    if type(data.mercenary_id) == "string" then
        data.mercenary_id = troop_logic:GetLeader().template_info.ID
    end

    setmetatable(data, talker_step)
end

function talker_step:Play()
    local spine_node = novice_sub_scene.talker_spine_node
    --spine_node:setToSetupPose()
    spine_node:setVisible(true)
    spine_node:setAnimation(0, self.animation_name, self.is_loop)

    self.hide_spine_node = self.animation_name == "talker_exit"

    novice_sub_scene.cur_talker_step = self
    if not self.is_loop then
        self.is_finish = false
    else
        self.is_finish = true
    end

    novice_sub_scene.mercenary_img:setVisible(true)
    local conf = config_manager.mercenary_config[self.mercenary_id]
    novice_sub_scene.mercenary_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. conf.sprite .. ".png", PLIST_TYPE)
end

function talker_step:Stop()
    if self.hide_spine_node then
        novice_sub_scene.talker_spine_node:setVisible(false)
        novice_sub_scene.mercenary_img:setVisible(false)
    end
    novice_sub_scene.talker_spine_node:clearTrack(0)
end

function talker_step:Update(elapsed_time)
    local spine_node = novice_sub_scene.talker_spine_node
    local widget = novice_sub_scene.mercenary_img

    local x, y, scale_x, scale_y, alpha, rotation, r, g, b = spine_node:getSlotTransform("talker")
    widget:setPosition(320 + x, y)
    widget:setScale(scale_x*2, scale_y*2)

    color.r = r
    color.b = b
    color.g = g
    widget:setColor(color)
end

function dialogue_step:IsFinish()
    return self.is_finish
end

--打开界面
--参数：
--界面名称name
local open_panel_step = setmetatable({}, novice_step)
open_panel_step.__index = open_panel_step

function open_panel_step.New(data)
    setmetatable(data, open_panel_step)
end

function open_panel_step:Play()
    graphic:DispatchEvent("show_world_sub_panel", self.name)
end

function open_panel_step:Stop()
end

--打开场景
--参数：
--场景名称name
local open_sub_scene_step = setmetatable({}, novice_step)
open_sub_scene_step.__index = open_sub_scene_step

function open_sub_scene_step.New(data)
    setmetatable(data, open_sub_scene_step)
end

function open_sub_scene_step:Play()
    graphic:DispatchEvent("show_world_sub_scene", self.name)
end

function open_sub_scene_step:Stop()
end

--升级
local sim_levelup_step = setmetatable({}, novice_step)
sim_levelup_step.__index = sim_levelup_step

function sim_levelup_step.New(data)
    setmetatable(data, sim_levelup_step)
end

function sim_levelup_step:Play()
    troop_logic:AllocMercenaryExp(troop_logic:GetLeader().instance_id, 1)
end

function sim_levelup_step:Stop()
end

--挖矿
local sim_dig_block_step = setmetatable({}, novice_step)
sim_dig_block_step.__index = sim_dig_block_step

function sim_dig_block_step.New(data)
    setmetatable(data, sim_dig_block_step)
end

function sim_dig_block_step:Play()
    mining_logic:DigOrCollectBlock(self.block_x, self.block_y)
end

--战斗
local sim_battle_step = setmetatable({}, novice_step)
sim_battle_step.__index = sim_battle_step

function sim_battle_step.New(data)
    setmetatable(data, sim_battle_step)
end

function sim_battle_step:Play()
    if self.battle_type == BATTLE_TYPE["vs_monster"] then
        adventure_logic:SolveEvent(self.event_id)
    end
end

--进入下一关
local sim_enter_maze_step = setmetatable({}, novice_step)
sim_enter_maze_step.__index = sim_enter_maze_step

function sim_enter_maze_step.New(data)
    setmetatable(data, sim_enter_maze_step)
end

function sim_enter_maze_step:Play()
    adventure_logic:EnterNextMaze()
end

--模拟点击
local sim_touch_step = setmetatable({}, novice_step)
sim_touch_step.__index = sim_touch_step

local glview = cc.Director:getInstance():getOpenGLView()

local real_size = glview:getFrameSize()
local viewport_rect = glview:getViewPortRect()

local scale_x = glview:getScaleX()
local scale_y = glview:getScaleY()

function sim_touch_step.New(data)

    data.x = data.x * scale_x+ viewport_rect.x
    data.y = real_size.height - data.y  * scale_y + viewport_rect.y

    setmetatable(data, sim_touch_step)
end

function sim_touch_step:Play()
    novice_sub_scene.can_swallow_touch_event = false
    aandm.simTouch(self.x, self.y)
    novice_sub_scene.can_swallow_touch_event = true
end

function sim_touch_step:OnTouch()

end

--网络同步
local network_sync_step = setmetatable({}, novice_step)
network_sync_step.__index = network_sync_step

function network_sync_step.New(data)
    setmetatable(data, network_sync_step)
end

function network_sync_step:Play()
    self.is_finish = false
end

function network_sync_step:OnRecvMsg(msg_name, msg_content)
    if msg_name ~= self.msg_name then
        return
    end

    --矿区数据分块传输
    if self.msg_name == "query_mining_block_info_ret" then
        self.is_finish = msg_content.is_finish_query
    else
        self.is_finish = true
    end
end

function network_sync_step:IsFinish()
    return self.is_finish
end

local novice_group = {}
novice_group.__index = novice_group

function novice_group.New()
    return setmetatable({}, novice_group)
end

function novice_group:Play()
    local last_steps = self.cur_steps

    if last_steps then
        for i, step in ipairs(last_steps) do
            step:Stop()
        end
    end

    self.cur_steps = self[self.cur_step_index]
    if not self.cur_steps then
        return true
    end

    self.cur_alpha = last_steps and last_steps.mask_info.alpha or 0
    self.next_alpha = self.cur_steps.mask_info.alpha

    self.last_mask_info = last_steps and last_steps.mask_info or nil

    self.transition_time = self.cur_steps.mask_info.transition_time
    self.delta_time = 0

    self.auto_play_next_step = self.cur_steps.auto_play_next_step
    novice_sub_scene.enable_forward = false

    self.waiting_transition = self.cur_steps.mask_info.waiting_transition
    self.cur_step_index = self.cur_step_index + 1

    self.is_playing = false
    self.is_cur_step_finish = false

    if not self.last_mask_info or not self.last_mask_info.x then
        local mask_info = self.cur_steps.mask_info
        if mask_info.x then
            self:SetMaskSize(mask_info.x, mask_info.y, mask_info.width, mask_info.height, mask_info.padding)
        else
            novice_sub_scene.mask_node:setVisible(false)
            novice_sub_scene.fuzzy_node:setVisible(false)
        end
    end

    --判读是否会和跳过按钮重合
    local skip_btn = novice_sub_scene.skip_btn 
    if skip_btn and mask_info then
        local skip_btn_width = skip_btn:getContentSize().width*skip_btn:getScale()
        local skip_btn_height = skip_btn:getContentSize().height*skip_btn:getScale()
        local mask_info_x = mask_info.x  or 0
        local mask_info_width = mask_info.width or 0
        local mask_info_y = mask_info.y  or 0
        local mask_info_height = mask_info.height  or 0
        if mask_info_x ~= VISIBLE_SIZE_WIDTH/2 and mask_info_x + mask_info_width/2 >= VISIBLE_SIZE_WIDTH - skip_btn_width and mask_info_y + mask_info_height/2 >= VISIBLE_SIZE_HEIGHT - skip_btn_height then
            skip_btn:setPosition({x = skip_btn_width/2, y = VISIBLE_SIZE_HEIGHT - skip_btn_height/2-10})
        else
            skip_btn:setPosition({x = VISIBLE_SIZE_WIDTH - skip_btn_width/2, y = VISIBLE_SIZE_HEIGHT - skip_btn_height/2-10})
        end
    end

    if not self.waiting_transition then
        self:DoPlay()
    end

    return false
end


local mask_color = { a = 0.75, r = 0.0, g = 0.0, b = 0.0 }
function novice_group:Update(elapsed_time)
    if not self.cur_steps then
        return
    end

    if self.is_playing then
        local finish_num = 0

        for i, step in ipairs(self.cur_steps) do
            step:Update(elapsed_time)

            if step:IsFinish() then
                finish_num = finish_num + 1
            end
        end

        if #self.cur_steps == finish_num then
            self.is_cur_step_finish = true

            if self.auto_play_next_step then
                novice_sub_scene.enable_forward = true
            end
        end
    end

    self.delta_time = self.delta_time + elapsed_time
    if self.delta_time <= self.transition_time then
        --过渡
         local percent = 1.01 * math.exp(- ( 1.2 * (self.delta_time/self.transition_time)  -1.5) ^ 4) - 0.15 * math.sin((self.delta_time/self.transition_time) * 6.28 )
        mask_color.a = self.cur_alpha + (self.next_alpha - self.cur_alpha) * percent
        if mask_color.a < 0 then
            mask_color.a = 0

        elseif mask_color.a > 1 then
            mask_color.a = 1
        end

        novice_sub_scene.black_node:clear()
        novice_sub_scene.black_node:drawSolidRect(MASK_ORIGIN, MASK_DESTINATION, mask_color)

        local mask_info = self.cur_steps.mask_info
        if self.last_mask_info and self.last_mask_info.x and mask_info.x then
            local x = self.last_mask_info.x + (mask_info.x - self.last_mask_info.x) * percent
            local y = self.last_mask_info.y + (mask_info.y - self.last_mask_info.y) * percent
            local width = self.last_mask_info.width + (mask_info.width - self.last_mask_info.width) * percent
            local height = self.last_mask_info.height + (mask_info.height - self.last_mask_info.height) * percent
            self:SetMaskSize(x, y, width, height, mask_info.padding)
        end

    else
        if not self.is_playing then
            --过渡结束
            self:DoPlay()
        end
    end
end

function novice_group:DoPlay()
    self.is_playing = true

    for i, step in ipairs(self.cur_steps) do
        step:Play()
    end
end

local rect = cc.rect(0, 0, 0, 0)
function novice_group:SetMaskSize(x, y, width, height, padding)
    local node = novice_sub_scene.fuzzy_node
    padding = padding or 0

    rect.x = padding
    rect.y = padding
    rect.width = novice_sub_scene.raw_mask_width - padding * 2
    rect.height = novice_sub_scene.raw_mask_height - padding * 2

    node:setContentSize(width, height)
    node:setCapInsets(rect)
    node:setPosition(x, y)

    node:setVisible(true)

    novice_sub_scene.mask_node:setPosition(x, y)
    novice_sub_scene.mask_node:setContentSize(width, height)
    novice_sub_scene.mask_node:setCapInsets(rect)

    novice_sub_scene.mask_node:setVisible(true)
end

function novice_group:Stop()
    if not self.cur_steps then
        return
    end

    for i, step in ipairs(self.cur_steps) do
        step:Stop()
    end
end

function novice_group:OnTouch()
    if self.is_playing then
        for i, step in ipairs(self.cur_steps) do
            step:OnTouch()
        end

        if self.is_cur_step_finish and not self.auto_play_next_step and self.delta_time >= self.transition_time then
            novice_sub_scene.enable_forward = true
        end
    end
end

function novice_group:OnRecvMsg(msg_name, msg_content)
    if self.is_playing then
        for i, step in ipairs(self.cur_steps) do
            step:OnRecvMsg(msg_name, msg_content)
        end

        if self.is_cur_step_finish and not self.auto_play_next_step and self.delta_time >= self.transition_time then
            novice_sub_scene.enable_forward = true
        end
    end

end

function novice_sub_scene:InitMeta()
    self.prototypes = {}
    self.groups = {}

    self.prototypes[NOVICE_TYPE["animation"]] = animation_step
    self.prototypes[NOVICE_TYPE["text"]] = text_step
    self.prototypes[NOVICE_TYPE["dialogue"]] = dialogue_step
    self.prototypes[NOVICE_TYPE["talker"]] = talker_step
    self.prototypes[NOVICE_TYPE["open_panel"]] = open_panel_step
    self.prototypes[NOVICE_TYPE["open_sub_scene"]] = open_sub_scene_step
    self.prototypes[NOVICE_TYPE["sim_levelup"]] = sim_levelup_step
    self.prototypes[NOVICE_TYPE["sim_dig_block"]] = sim_dig_block_step
    self.prototypes[NOVICE_TYPE["sim_enter_maze"]] = sim_enter_maze_step
    self.prototypes[NOVICE_TYPE["sim_battle"]] = sim_battle_step
    self.prototypes[NOVICE_TYPE["sim_touch"]] = sim_touch_step
    self.prototypes[NOVICE_TYPE["network_sync"]] = network_sync_step
end

function novice_sub_scene:Init()

    self.__name = "novice_sub_scene"

    self.cur_group = nil
    self.cur_step_index = nil
    self.is_finish = false
    self.can_swallow_touch_event = false

    self.root_node = cc.Node:create()
    self.black_node = cc.DrawNode:create()
    self.black_node:setVisible(true)
    self.black_node:drawSolidRect(MASK_ORIGIN, MASK_DESTINATION, MASK_COLOR)

    self.mask_node = ccui.Scale9Sprite:create("res/ui/novice_mask.png")
    self.raw_mask_width = self.mask_node:getSprite():getTexture():getPixelsWide()
    self.raw_mask_height = self.mask_node:getSprite():getTexture():getPixelsHigh()
    self.fuzzy_node = ccui.Scale9Sprite:create("res/ui/novice_mask.png")

    self.stencil_node = cc.Node:create()
    self.stencil_node:addChild(self.mask_node)

    self.clipping_node = cc.ClippingNode:create(self.stencil_node)
    self.clipping_node:addChild(self.black_node)
    self.clipping_node:setInverted(true)

    self.clipping_node:setVisible(true)

    self.root_node:addChild(self.clipping_node)
    self.root_node:addChild(self.fuzzy_node)

    self.text1 = ccui.Text:create("", client_constants["FONT_FACE"], platform_manager:GetLocale() == "en-US" and FONT_SIZE_ONE_EN or FONT_SIZE_ONE)
    self.text2 = ccui.Text:create("", client_constants["FONT_FACE"], platform_manager:GetLocale() == "en-US" and FONT_SIZE_TWO_EN or FONT_SIZE_TWO)
    self.text2:ignoreContentAdaptWithSize(false)
    self.text2:setContentSize(cc.size(TEXT_WIDTH, TEXT_HEIGHT))
    self.text2:setTextVerticalAlignment(1)

    if platform_manager:GetChannelInfo().novice_change_text_size and platform_manager:GetLocale() == "fr" then 
        self.text1:setFontSize(FONT_SIZE_ONE_EN)
    end

    self.text1:setVisible(false)
    self.text1:setColor(TEXT_COLOR_ONE)

    self.text2:setVisible(false)
    self.text2:setColor(TEXT_COLOR_TWO)
    self.text2:setAnchorPoint(cc.p(0.0, 0.5))

    self.dialogue_spine_node = spine_manager:GetNode("novice_dialogue")
    self.animation_spine_node = spine_manager:GetNode("novice_gesture")
    self.talker_spine_node = spine_manager:GetNode("novice_talker")

    self.dialogue_spine_node:setVisible(false)
    self.animation_spine_node:setVisible(false)
    self.talker_spine_node:setVisible(false)

    self.mercenary_img = ccui.ImageView:create()

    self.root_node:addChild(self.dialogue_spine_node, 2)
    self.root_node:addChild(self.animation_spine_node, 1)
    self.root_node:addChild(self.talker_spine_node, 1)

    self.root_node:addChild(self.text1, 3)
    self.root_node:addChild(self.text2, 3)

    self.root_node:addChild(self.mercenary_img, 1)

    self.root_node:setVisible(false)

    --跳过按钮
    if feature_config:IsFeatureOpen("novice_can_skip") then 
        self.skip_btn = ccui.ImageView:create()
        self.skip_btn:loadTexture("button/buttonbg_1.png", PLIST_TYPE)
        self.skip_btn:setScale9Enabled(true)
        
        self.skip_btn:setCapInsets({x=76,y=24,width=76,height=24})
        self.skip_btn:setContentSize({width=220,height=100})
        self.skip_btn:setScale(0.6)
        local skip_btn_width = self.skip_btn:getContentSize().width*self.skip_btn:getScale()
        local skip_btn_height = self.skip_btn:getContentSize().height*self.skip_btn:getScale()
        self.skip_btn:setPosition({x = VISIBLE_SIZE_WIDTH - skip_btn_width/2, y = VISIBLE_SIZE_HEIGHT - skip_btn_height/2-10})
        self.root_node:addChild(self.skip_btn)

        ----跳过文字
        local btn_text 
        local channel_info = platform_manager:GetChannelInfo()
        if not channel_info.is_open_system then
            btn_text = cc.Label:createWithTTF(lang_constants:Get("novice_sub_scene_skip_btn_desc"), "ui/fonts/general.ttf", 36)
        else
            btn_text = cc.Label:createWithSystemFont(lang_constants:Get("novice_sub_scene_skip_btn_desc"), "Arial", 36)
        end
        btn_text:setColor({r=0,g=0,b=0})
        btn_text:setPosition({x = self.skip_btn:getContentSize().width/2,y = self.skip_btn:getContentSize().height/2})
        self.skip_btn:addChild(btn_text)
    end    

    self:RegisterWidgetEvent()
end

function novice_sub_scene:AddGroup(group_id, trigger_cond, ...)
    local datas = {...}

    local group = novice_group.New()
    assert(not self.groups[group_id], string.format("repeat group_id %d", group_id))
    self.groups[group_id] = group

    group.trigger_cond = trigger_cond

    for i = 1, #datas do
        local steps = datas[i]

        local mask_info = steps.mask_info
        mask_info.alpha = mask_info.alpha or DEFAULT_MASK_ALPHA
        mask_info.transition_time = mask_info.transition_time or DEFAULT_TRANSITION_TIME

        for j = 1, #steps do
            local step = steps[j]
            local prototype = self.prototypes[step.type]
            assert(prototype)

            step.step_id = i
            prototype.New(step)
        end

        group[i] = steps
    end
end

function novice_sub_scene:Trigger(type, param)
    if _G["AUTH_MODE"] or platform_manager:IsAdmin() then
        return false
    end
    
    for group_id, group in pairs(self.groups) do
        local cond = group.trigger_cond
        if cond.type == type and cond:Check(param) then
            group.cur_steps = nil
            group.cur_step_index = 1

            self.cur_group = group
            self.is_finish = false
            return true
        end
    end

    return false
end

function novice_sub_scene:Show()
    if not self.root_node:isVisible() then
        self.root_node:setVisible(true)
    end

    self.can_swallow_touch_event = true

    graphic:DispatchEvent("guide_open");
    
    if self.cur_group then
        self.cur_group:Play()
    end
end

function novice_sub_scene:Hide()
    self.can_swallow_touch_event = false
    self.is_finish = false
    self.root_node:setVisible(false)
end

function novice_sub_scene:CanSwallowTouchEvent()
    return self.can_swallow_touch_event
end

function novice_sub_scene:IsVisbile()
    return self.root_node:isVisible()
end

function novice_sub_scene:Forward()
    if not self.cur_group then
        return
    end

    self.is_finish = self.cur_group:Play()
end

function novice_sub_scene:GoComment()
    graphic:DispatchEvent("show_simple_msgbox", 
    lang_constants:Get("comment_msgbox_title"),
    lang_constants:Get("comment_msgbox_content"),
    lang_constants:Get("comment_msgbox_btn2"),
    lang_constants:Get("comment_msgbox_btn1"),
    function()
        --去好评发奖
        --local carnival_logic = require "logic.carnival"
        --carnival_logic:TakeReward({},1)
        local channel_info = platform_manager:GetChannelInfo()
        cc.Application:getInstance():openURL(channel_info.appraise_url)
    end, 
    function()
        --去吐槽开网页
        local channel_info = platform_manager:GetChannelInfo()
        local user_logic = require "logic.user"
        graphic:DispatchEvent("show_world_sub_panel", "web_panel", channel_info.other_url[1] .. user_logic:GetUserId(), "comment_panel_title")
    end)
end

function novice_sub_scene:Update(elapsed_time)
    if not self.cur_group or not self.root_node:isVisible() then
        return
    end

    self.cur_group:Update(elapsed_time)

    if not self.is_finish and self.enable_forward and self.cur_group.delta_time >= self.cur_group.transition_time then
        self:Forward()
    end

    if self.is_finish then
        self:Hide()

        local cond = self.cur_group.trigger_cond
        local channel_info = platform_manager:GetChannelInfo()
        if cond.type == NOVICE_TRIGGER_TYPE["solve_event"] and cond.event_id == 1000012 and channel_info.meta_channel == "qikujp" then
            self:GoComment()
        end
    end
end

function novice_sub_scene:OnTouch()

    if not self.is_finish then
        self.cur_group:OnTouch()
    end
end

function novice_sub_scene:OnTouchBegan(touch)
    if touch ~= nil and self.skip_btn then
        local size_width = self.skip_btn:getContentSize().width*self.skip_btn:getScale()
        local size_height = self.skip_btn:getContentSize().height*self.skip_btn:getScale()
        local posx = self.skip_btn:getPositionX()
        local posy = self.skip_btn:getPositionY()
        local touchPosx = touch:getLocation().x
        local touchPosy = touch:getLocation().y
        if touchPosx >=posx-size_width/2 and  touchPosx <=posx+size_width  and touchPosy >= posy-size_height/2 and touchPosy <= posy+size_height then
            self.onTouchBegan = true
            self.skip_btn:setScale(0.5)
        end
    end
end

function novice_sub_scene:OnTouchEned(touch)
    local canTouch = true
    if self.skip_btn then
        if touch ~= nil then
            local size_width = self.skip_btn:getContentSize().width*self.skip_btn:getScale()
            local size_height = self.skip_btn:getContentSize().height*self.skip_btn:getScale()
            local posx = self.skip_btn:getPositionX()
            local posy = self.skip_btn:getPositionY()
            local touchPosx = touch:getLocation().x
            local touchPosy = touch:getLocation().y
            if touchPosx >=posx-size_width/2 and  touchPosx <=posx+size_width and touchPosy >= posy-size_height/2 and touchPosy <= posy+size_height then
                if self.onTouchBegan then
                    self.is_finish=true
                    canTouch = false
                end
            end
        end
        self.skip_btn:setScale(0.6)
    end
    self.onTouchBegan = false

    if not self.is_finish and canTouch then
        self.cur_group:OnTouch()
    end
end


function novice_sub_scene:OnRecvMsg(msg_name, msg_content)
    if self.cur_group then
        self.cur_group:OnRecvMsg(msg_name, msg_content)
    end
end

function novice_sub_scene:RegisterWidgetEvent()
    self.dialogue_spine_node:registerSpineEventHandler(function(event)
        self.cur_dialogue_step.is_finish = true
    end, sp.EventType.ANIMATION_END)

    self.animation_spine_node:registerSpineEventHandler(function(event)
        self.cur_animation_step.is_finish = true
    end, sp.EventType.ANIMATION_END)

    self.talker_spine_node:registerSpineEventHandler(function(event)
        self.cur_talker_step.is_finish = true
    end, sp.EventType.ANIMATION_END)
end

novice_sub_scene:InitMeta()

--TAG:MASTER_MERGE
local data_loader = require(string.format("scene.novice_data.%s", platform_manager:GetChannelInfo().region))
data_loader(novice_sub_scene)

return novice_sub_scene
