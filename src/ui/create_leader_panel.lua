local user_logic = require "logic.user"
local graphic = require "logic.graphic"
local panel_prototype = require "ui.panel"

local platform_manager = require "logic.platform_manager"

local config_manager = require "logic.config_manager"
local mercenary_config = config_manager.mercenary_config

local spine_manager = require "util.spine_manager"
local client_constants = require "util.client_constants"

local random_name = require "util.random_name"

local PLIST_TYPE = ccui.TextureResType.plistType
local ROLE_PATH = client_constants["MERCENARY_ROLE_IMG_PATH"]

local create_leader_panel = panel_prototype.New()

function create_leader_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/create_panel.csb")

    self.role_img = self.root_node:getChildByName("role")
    self.role_img:setScale(3, 3)
    self.role_img:ignoreContentAdaptWithSize(true)

    self.left_btn = self.root_node:getChildByName("left_btn")
    self.right_btn = self.root_node:getChildByName("right_btn")

    self.name_bg_img = self.root_node:getChildByName("name_bg")
    self.name_bg_img:setCascadeOpacityEnabled(false)

    self.name_textfield = self.name_bg_img:getChildByName("name_textfield")
    self.name_textfield:setTouchAreaEnabled(true)
    self.name_textfield:setTouchSize({width = 450, height = 97})
    self.name_textfield:setTextHorizontalAlignment(1)

    self.random_name_btn = self.root_node:getChildByName("name_btn")

    self.name_desc_text = self.root_node:getChildByName("name_desc")

    self.create_btn = self.root_node:getChildByName("confirm_btn")

    self.role2_img = ccui.ImageView:create()
    self.role2_img:ignoreContentAdaptWithSize(true)
    self.role2_img:setScale(3, 3)
    self.role2_img:setPositionY(self.role_img:getPositionY() + 30)
    self.root_node:addChild(self.role2_img)

    self.role_pos_x = self.role_img:getPositionX()
    self.role_pos_y = self.role_img:getPositionY()

    self.role2_img:setPosition(self.role_pos_x, self.role_pos_y)

    self.template_ids = {99000001, 99000002, 99000003, 99000004, 99000005, 99000006}

    self.cur_role_index = 0
    self.last_role_index = 0

    self.spine_node = sp.SkeletonAnimation:create("res/spine/choose_focus.json", "res/spine/choose_focus.atlas", 1.0)
    self.root_node:addChild(self.spine_node)

    self.spine_node:setVisible(false)
    self.focus_tracker = spine_manager:CreateFocusTracker(self.spine_node, "create_input_box")

    local plist_path = string.format("res/language/%s/role/mercenary.plist", platform_manager:GetLocale())
    if not cc.FileUtils:getInstance():isFileExist(plist_path) then
        plist_path = "res/role/mercenary.plist"
    end
    cc.SpriteFrameCache:getInstance():addSpriteFrames(plist_path)

    local texture_path = string.format("res/language/%s/role/mercenary.png", platform_manager:GetLocale())
    if not cc.FileUtils:getInstance():isFileExist(texture_path) then
        texture_path = "res/role/mercenary.png"
    end
    local tex = cc.Director:getInstance():getTextureCache():getTextureForKey(texture_path)
    if tex then
        tex:setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
    end

    self.init_y = self.root_node:getPositionY()

    self:RegisterWidgetEvent()
end

function create_leader_panel:Show()

    self.cur_role_index = 1
    self.last_role_index = 1

    local icon = mercenary_config[self.template_ids[self.cur_role_index]].sprite
    self.role_img:loadTexture(ROLE_PATH .. icon .. ".png", PLIST_TYPE)
    self.role_img:setPosition(self.role_pos_x, self.role_pos_y)
    self.role2_img:setVisible(false)

    self.root_node:setPositionY(self.init_y)

    self:CheckLeftBtn()
    self:CheckRightBtn()

    self.move_index = 1
end

function create_leader_panel:Update(elapsed_time)
    if not self.move then
        return
    end

    if self.cur_role_index < self.last_role_index then
        --左滑动
        local role_x = self.role_img:getPositionX()
        self.role_img:setPositionX(role_x - 30)

        local role2_x = self.role2_img:getPositionX()
        self.role2_img:setPositionX(role2_x - 30)

        if self.move_index == 1 then
            if role2_x <= self.role_pos_x then
                self.role2_img:setPositionX(self.role_pos_x)
                self.move = false
                self.move_index = 2
                self.role_img:setVisible(false)
            end
        else
            if role_x <= self.role_pos_x then
                self.role_img:setPositionX(self.role_pos_x)
                self.move = false
                self.move_index = 1
                self.role2_img:setVisible(false)

            end
        end

    elseif self.cur_role_index > self.last_role_index then
        --右滑动
        local role_x = self.role_img:getPositionX()
        self.role_img:setPositionX(role_x + 30)

        local role2_x = self.role2_img:getPositionX()
        self.role2_img:setPositionX(role2_x + 30)

        if self.move_index == 1 then
            if role2_x >= self.role_pos_x then
                self.role2_img:setPositionX(self.role_pos_x)
                self.move = false
                self.move_index = 2
                self.role_img:setVisible(false)

            end
        else
            if role_x >= self.role_pos_x then
                self.role_img:setPositionX(self.role_pos_x)
                self.move = false
                self.move_index = 1
                self.role2_img:setVisible(false)
            end
        end
    end
end

function create_leader_panel:CheckRightBtn()
    if self.cur_role_index == 6 then
        self.right_btn:setOpacity(255 * 0.3)
    else
        self.right_btn:setOpacity(255)
    end
end

function create_leader_panel:CheckLeftBtn()
    if self.cur_role_index == 1 then
        self.left_btn:setOpacity(255 * 0.3)
    else
        self.left_btn:setOpacity(255)
    end
end

function create_leader_panel:LoadRoleTexture(pos_x)
    if self.move_index == 1 then
        --role2_img, 在外面
        local icon = mercenary_config[self.template_ids[self.cur_role_index]].sprite
        self.role2_img:loadTexture(ROLE_PATH .. icon .. ".png", PLIST_TYPE)

        self.role2_img:setPositionX(pos_x)
        self.role2_img:setPositionY(650)
        self.role2_img:setVisible(true)
    else
        --role_img, 在外面
        local icon = mercenary_config[self.template_ids[self.cur_role_index]].sprite
        self.role_img:loadTexture(ROLE_PATH .. icon .. ".png", PLIST_TYPE)
        self.role_img:setPositionX(pos_x)
        self.role_img:setVisible(true)
    end
    self.move = true

end

function create_leader_panel:RegisterWidgetEvent()

    self.name_textfield:addEventListener(function(sender, event_type)
        if event_type == ccui.TextFiledEventType.attach_with_ime then
            self.name_desc_text:setVisible(false)
            local x, y = self.name_bg_img:getPosition()
            self.focus_tracker:Bind("create_input", x, y, self.name_bg_img)
            self.root_node:setPositionY(self.init_y + 220)

        elseif event_type == ccui.TextFiledEventType.detach_with_ime then
            self.focus_tracker:Hide()
            self.root_node:setPositionY(self.init_y)
        end
    end)

    self.create_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            local leader_name = self.name_textfield:getString()
            cc.Director:getInstance():getOpenGLView():setIMEKeyboardState(false)
            user_logic:CreateLeader(leader_name, self.template_ids[self.cur_role_index])
        end
    end)

    self.left_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            self.last_role_index = self.cur_role_index

            if self.cur_role_index > 1 then
                self.cur_role_index = self.cur_role_index - 1
                self:LoadRoleTexture(560)
            end
            self:CheckLeftBtn()
            self:CheckRightBtn()

        end
    end)

    self.right_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            self.last_role_index = self.cur_role_index

            if self.cur_role_index < #self.template_ids then
                self.cur_role_index = self.cur_role_index + 1
                self:LoadRoleTexture(90)
            end

            self:CheckRightBtn()
            self:CheckLeftBtn()
        end
    end)

    self.random_name_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            self.name_desc_text:setVisible(false)
            local leader_name = random_name:GetRandomName()
            self.name_textfield:setString(leader_name)
        end
    end)
end

return create_leader_panel
