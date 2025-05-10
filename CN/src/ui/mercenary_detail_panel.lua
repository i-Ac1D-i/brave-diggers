local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local config_manager = require "logic.config_manager"

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local destiny_logic = require "logic.destiny_weapon"
local resource_logic = require "logic.resource"
local chat_logic = require "logic.chat"
local sns_logic = require "logic.sns"

local spine_manager = require "util.spine_manager"
local platform_manager = require "logic.platform_manager"
local feature_config = require "logic.feature_config"

local channel_info = platform_manager:GetChannelInfo()
local time_logic = require "logic.time"

local panel_prototype = require "ui.panel"
local ui_role_prototype = require "entity.ui_role"

local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local utils = require "util.utils"
local network = require "util.network"

local destiny_forge_config = config_manager.destiny_forge_config
local destiny_skill_config = config_manager.destiny_skill_config
local mercenary_config = config_manager.mercenary_config

local PLIST_TYPE = ccui.TextureResType.plistType
local MERCENARY_DETAIL_MODE = client_constants["MERCENARY_DETAIL_MODE"]

-- 评论类型
local COMMENT_TYPE = constants["COMMENT_TYPE"]["mercenary"]

local MIN_SKILL_BG_HEGHT = 134
local SKILL_DESC_LINE_HEIGHT = 30
local SLOGAN_DESC_LINE_HEIGHT = 35
local MERCENARY_DESC_LINE_HEIGHT = 27
local ARTIFACT_SKILL_DESC_TEXT_MAX_WIDTH = 280
local ARTIFACT_SKILL1_TEXT_DIS_TOP = 62

local SKILL_TYPE =
{
    ["personal_skill"] = 1,   --个人技
    ["coop_skill1"] = 2, --合体技1
    ["coop_skill2"] = 3, --合体技2
    ["artifact_skill"] = 4, --宝具技
    ["destiny_skill"] = 4, --宿命武器技能
}

local LOCAL_ZORDER = { 100, 101, 102, 103, 104, 105,}

--英雄传记
local biography_sub_panel = panel_prototype.New()
biography_sub_panel.__index = biography_sub_panel

function biography_sub_panel.New()
    return setmetatable({}, biography_sub_panel)
end

function biography_sub_panel:Init(root_node)
    self.root_node = root_node
    self.biography_sview = self.root_node:getChildByName("desc_sview")
    self.biography_sview_init_width = self.biography_sview:getContentSize().width
    self.biography_sview_init_height = self.biography_sview:getContentSize().height

    self.mercenary_slogan_text = self.biography_sview:getChildByName("slogan")
    self.mercenary_slogan_text:getVirtualRenderer():setMaxLineWidth(450)
    self.slogan_init_pos_y = self.mercenary_slogan_text:getPositionY()

    self.biography_mercenary_name_text = self.biography_sview:getChildByName("name")
    self.biography_mercenary_desc_text = self.biography_sview:getChildByName("desc")
end

function biography_sub_panel:Load(template_info)
    self.mercenary_slogan_text:setString(template_info.slogan)
    self.biography_mercenary_name_text:setString("--" .. template_info.name)
    self.biography_mercenary_desc_text:setString(template_info.introduction)

    local slogan_render = self.mercenary_slogan_text:getVirtualRenderer()

    local slogan_line_num = slogan_render:getStringNumLines()
    if platform_manager:GetChannelInfo().is_open_system then
        local size = self.mercenary_slogan_text:getAutoRenderSize()
        local content_size = slogan_render:getContentSize()
        slogan_line_num = math.ceil(size.width / content_size.width) + 1
    end 
    local slogan_height = slogan_line_num * SLOGAN_DESC_LINE_HEIGHT

    local desc_render = self.mercenary_slogan_text:getVirtualRenderer()
    local line_num = desc_render:getStringNumLines()
    if platform_manager:GetChannelInfo().is_open_system then
        local size = self.mercenary_slogan_text:getAutoRenderSize()
        local content_size = desc_render:getContentSize()
        line_num = math.ceil(size.width / content_size.width) + 1
    end 
    local desc_height = line_num * MERCENARY_DESC_LINE_HEIGHT

    local sview_container_height = desc_height + 90 + slogan_height

    local height = math.max(sview_container_height, self.biography_sview_init_height)
    self.biography_sview:setInnerContainerSize(cc.size(self.biography_sview_init_width, height))

    local slogan_pos_y = height - 10
    self.mercenary_slogan_text:setPositionY(slogan_pos_y)
    self.biography_mercenary_name_text:setPositionY(slogan_pos_y - slogan_height - 10)
    self.biography_mercenary_desc_text:setPositionY(slogan_pos_y - slogan_height - 50)
end

--佣兵信息
local mercenary_info_sub_panel = panel_prototype.New()
mercenary_info_sub_panel.__index = mercenary_info_sub_panel
function mercenary_info_sub_panel.New()
    return setmetatable({}, mercenary_info_sub_panel)
end

function mercenary_info_sub_panel:Init(root_node)
    self.root_node = root_node
    self.level_text = self.root_node:getChildByName("level_value")
    self.battle_point_text = self.root_node:getChildByName("bp_value")
    self.wakeup_text = self.root_node:getChildByName("wakeup_value")
    self.weapon_lv_text = self.root_node:getChildByName("weapon_forge_lv")
    self.force_lv_text = self.root_node:getChildByName("force_lv")

    self.artifact_name_text = self.root_node:getChildByName("artifact_name")

    self.weapon_desc_text = self.root_node:getChildByName("weapon_forge_desc")
    self.force_desc_text = self.root_node:getChildByName("force_desc")
    self.artifact_desc_text = self.root_node:getChildByName("artifact_desc")

    self.artifact_update_text = self.root_node:getChildByName("artifact_name_0")
    self.artifact_update_desc = self.root_node:getChildByName("artifact_update")
    if self.artifact_update_text then
        self.artifact_update_text:setVisible(feature_config:IsFeatureOpen("artifact_upgrade"))
        self.artifact_update_desc:setVisible(feature_config:IsFeatureOpen("artifact_upgrade"))
    end

    self.root_node:setLocalZOrder(LOCAL_ZORDER[3])
    self.root_node:setVisible(false)

    --r2修改右对齐
    local all_right = channel_info.mercenary_info_sub_panel_all_right
    if all_right then
        --右对齐
        local rightPosx=self.level_text:getPositionX()
        local level_desc_text=self.root_node:getChildByName("level_desc")
        local bp_desc_text=self.root_node:getChildByName("bp_desc")
        local wakeup_desc_text=self.root_node:getChildByName("wakeup_desc")
        local weapon_forge_desc_text=self.root_node:getChildByName("weapon_forge_desc")
        local force_desc_text=self.root_node:getChildByName("force_desc")
        local artifact_desc_text=self.root_node:getChildByName("artifact_desc")

        local offset_x=30
        level_desc_text:setAnchorPoint({x=1,y=0.5})
        level_desc_text:setPositionX(rightPosx-offset_x)
        bp_desc_text:setAnchorPoint({x=1,y=0.5})
        bp_desc_text:setPositionX(rightPosx-offset_x)
        wakeup_desc_text:setAnchorPoint({x=1,y=0.5})
        wakeup_desc_text:setPositionX(rightPosx-offset_x)
        weapon_forge_desc_text:setAnchorPoint({x=1,y=0.5})
        weapon_forge_desc_text:setPositionX(rightPosx-offset_x)
        force_desc_text:setAnchorPoint({x=1,y=0.5})
        force_desc_text:setPositionX(rightPosx-offset_x)
        artifact_desc_text:setAnchorPoint({x=1,y=0.5})
        artifact_desc_text:setPositionX(rightPosx-offset_x)
    end

end

function mercenary_info_sub_panel:LoadMercenaryInfo(mercenary)
    self.force_desc_text:setVisible(true)
    self.force_lv_text:setVisible(true)
    self.artifact_name_text:setVisible(true)
    self.artifact_desc_text:setVisible(true)
    if feature_config:IsFeatureOpen("artifact_upgrade") then
        self.artifact_update_text:setVisible(true)
        self.artifact_update_desc:setVisible(true)
    end
    self.weapon_desc_text:setString(lang_constants:Get("mercenary_weapon_forge"))

    local template = mercenary.template_info

    self.level_text:setString(mercenary.level)
    self.battle_point_text:setString(mercenary.battle_point)
    self.wakeup_text:setString(mercenary.wakeup .. "/" .. template.max_wakeup)

    local weapon_lv_str = tostring(mercenary.weapon_lv) .. "/" .. constants["MAX_WEAPON_LV"] .. "(+ " .. config_manager.weapon_forge_config[mercenary.weapon_lv + 1]["bp_factor"] .. lang_constants:Get("mercenary_info_BP_string")..")"
    self.weapon_lv_text:setString(weapon_lv_str)

    if template.can_upgrade_force then
        if mercenary.force_lv == 0 then
            self.force_lv_text:setString(lang_constants:Get("mercenary_upgrade_force_prompt2"))
        else
            self.force_lv_text:setString("+" .. mercenary.force_lv .. lang_constants:Get("mercenary_info_BP_string"))
        end
    else
        self.force_lv_text:setString(lang_constants:Get("mercenary_upgrade_force_prompt1"))
    end

    --宝具状态
    local artifact_status = troop_logic:GetArtifactStatus(mercenary.instance_id)

    if artifact_status ==  constants["MERCENARY_AETIFACT_STATUS"]["not_have_artifact"] then
        self.artifact_name_text:setString(lang_constants:Get("mercenary_no_artifact"))
    elseif artifact_status ==  constants["MERCENARY_AETIFACT_STATUS"]["weapon_lv_not_enough"] then
        self.artifact_name_text:setString(lang_constants:Get("mercenary_open_artifact_weapon_lv_not_enough"))
    else
        self.artifact_name_text:setString(template.artifact_name)
    end

    if feature_config:IsFeatureOpen("artifact_upgrade") then
        --宝具等级信息
        if template.have_artifact_upgrade then
            local grade_level =  mercenary.artifact_lv or 1
            if not mercenary.is_open_artifact then
                grade_level = 0
            end
            self.artifact_update_text:setString(grade_level..lang_constants:Get("mercenary_artifact_upgrade_text"))
        else
            self.artifact_update_text:setString(lang_constants:Get("mercenary_no_artifact_upgrade"))
        end
    end
end

function mercenary_info_sub_panel:LoadLeaderInfo(mercenary_info, template_info)
    self.weapon_desc_text:setString(lang_constants:Get("mercenary_destiny_forge"))

    self.force_desc_text:setVisible(false)
    self.force_lv_text:setVisible(false)
    self.artifact_name_text:setVisible(false)
    self.artifact_desc_text:setVisible(false)
    if feature_config:IsFeatureOpen("artifact_upgrade") then
        self.artifact_update_text:setVisible(false)
        self.artifact_update_desc:setVisible(false)
    end

    self.level_text:setString(mercenary_info.level)
    self.battle_point_text:setString(mercenary_info.battle_point)
    self.wakeup_text:setString(mercenary_info.wakeup .. "/" .. template_info.max_wakeup)

    local destiny_weapon_lv = destiny_logic:GetWeaponLevel()
    local weapon_lv_str = destiny_weapon_lv .. "/" .. constants["MAX_DESTINY_WEAPON_LV"]
    weapon_lv_str = weapon_lv_str .. "(+ " .. destiny_forge_config[destiny_weapon_lv + 1]["bp_factor"] .. "%BP)"

    self.weapon_lv_text:setString(weapon_lv_str)
end

---
local mercenary_detail_panel = panel_prototype.New(true)
mercenary_detail_panel.__index = mercenary_detail_panel

function mercenary_detail_panel.New()
    return setmetatable({}, mercenary_detail_panel)
end

function mercenary_detail_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mercenary_detail_panel.csb")
    local root_node = self.root_node

    local bg_img = root_node:getChildByName("bg")
    bg_img:setColor(panel_util:GetColor4B(0x7f7f7f))
    bg_img:loadTexture("res/battle_background/aircity.png")

    self.name_text = root_node:getChildByName("title_bg"):getChildByName("name")
    self.race_text = root_node:getChildByName("race_bg"):getChildByName("race")

    --角色图片
    self.role_sprite = cc.Sprite:create()
    self.role_sprite:setPosition(320, 620)
    self.role_sprite:setAnchorPoint(0.5, 0.1)
    self.root_node:addChild(self.role_sprite, 100)
    self.ui_role = ui_role_prototype.New()

    --传记
    self.biography_sub_panel = biography_sub_panel.New()
    self.biography_sub_panel:Init(self.root_node:getChildByName("biography_bg"))
    --佣兵信息
    self.mercenary_info_sub_panel = mercenary_info_sub_panel.New()
    self.mercenary_info_sub_panel:Init(self.root_node:getChildByName("mercenary_info_bg"))

    --技能信息
    self.skill_info_bg_img = root_node:getChildByName("skill_info_bg")
    self.skill_line_img = self.skill_info_bg_img:getChildByName("line")
    self.skill_name_text = self.skill_info_bg_img:getChildByName("name")
    self.skill_desc_text = self.skill_info_bg_img:getChildByName("desc")
    self.skill_desc_text:getVirtualRenderer():setMaxLineWidth(380)

    self.skill_artifact_skill1_name_text = self.skill_info_bg_img:getChildByName("desc_0")
    self.skill_artifact_skill2_name_text = self.skill_info_bg_img:getChildByName("desc_0_0")

    if self.skill_artifact_skill1_name_text then
        self.skill_artifact_skill1_name_text:setVisible(feature_config:IsFeatureOpen("artifact_upgrade"))
        self.skill_artifact_skill2_name_text:setVisible(feature_config:IsFeatureOpen("artifact_upgrade"))
        if feature_config:IsFeatureOpen("artifact_upgrade") then
            self.skill_artifact_skill1_desc_text = self.skill_artifact_skill1_name_text:getChildByName("desc_0_0")
            self.skill_artifact_skill1_desc_text:getVirtualRenderer():setMaxLineWidth(ARTIFACT_SKILL_DESC_TEXT_MAX_WIDTH)
            self.skill_artifact_skill2_desc_text = self.skill_artifact_skill2_name_text:getChildByName("desc_0_0")
            self.skill_artifact_skill2_desc_text:getVirtualRenderer():setMaxLineWidth(ARTIFACT_SKILL_DESC_TEXT_MAX_WIDTH)
        end
    end

    self.skill_info_bg_img:setLocalZOrder(LOCAL_ZORDER[3])
    self.skill_info_bg_img:setVisible(false)

    self.view_info_btn = root_node:getChildByName("view_info_btn")
    self.back_btn = root_node:getChildByName("back_btn")

    self.skill_imgs = {1, 2, 3, 4}
    self.skill_imgs_pos =  {{}, {}, {}, {}, {}}
    for i = 1, 4 do
        local skill_img = root_node:getChildByName("skill_img" ..i)
        skill_img:setTouchEnabled(true)
        skill_img:setTag(i)
        self.skill_imgs[i] = skill_img

        self.skill_imgs_pos[i].x = skill_img:getPositionX()
        self.skill_imgs_pos[i].y = skill_img:getPositionY()
    end

    --宝具技和宿命技icon
    self.artifact_and_destiny_icon_img = ccui.ImageView:create()
    self.artifact_and_destiny_icon_img:setPosition(self.skill_imgs[4]:getPosition())
    root_node:addChild(self.artifact_and_destiny_icon_img, LOCAL_ZORDER[1])

    self.skills_info = { {}, {}, {}, {}}
    self.lead_skill_info = {}
    self.skill_bg_init_width = self.skill_info_bg_img:getContentSize().width

    --合体技和宝具 是否满足发动条件动画
    self.coop_and_artifact_text = ccui.Text:create("", client_constants["FONT_FACE"], 20)
    self.skill_info_bg_img:addChild(self.coop_and_artifact_text, LOCAL_ZORDER[1])
    self.coop_and_artifact_text:setPosition(380, 150)
    self.coop_and_artifact_text:setAnchorPoint(1, 1)
    self.coop_and_artifact_text:setVisible(true)

    --弹窗背景 暗，防止点穿
    self.msgbox_shadow_img = self.root_node:getChildByName("box_shadow")
    self.msgbox_shadow_img:setVisible(false)
    self.msgbox_shadow_img:setTouchEnabled(true)
    self.msgbox_shadow_img:setLocalZOrder(LOCAL_ZORDER[2])

    -- 打开佣兵评论区按钮
    self.open_comment_msgbox_btn = self.root_node:getChildByName("comment")
    self.comment_num_text = self.open_comment_msgbox_btn:getChildByName("value")

    self.cur_count_des_text =  self.root_node:getChildByName("Text_10")
    self.cur_count_des_text:setVisible(false)
    
    -- 调整评论区大小
    local locale = platform_manager:GetLocale()
    if locale == "de" or locale == "es-MX" or locale == "ru" and platform_manager:GetChannelInfo().mercenary_detail_panel_change_comment_size then
        self.open_comment_txtbg = self.open_comment_msgbox_btn:getChildByName("txtbg")
        self.comment_num_text:setPositionX(self.comment_num_text:getPositionX() + 10)
        self.open_comment_txtbg:setContentSize(cc.size(self.open_comment_txtbg:getContentSize().width * 1.15, self.open_comment_txtbg:getContentSize().height))
    end
    
    --底部
    self.bottom_bar_node = self.root_node:getChildByName("bottom_bar")
    self.recruit_btn = self.bottom_bar_node:getChildByName("recruit_btn")
    self.soul_num_text = self.bottom_bar_node:getChildByName("soul_value")
    self.soul_crystal_bg_img = self.bottom_bar_node:getChildByName("soulbg")
    self.soul_crystal_bg_img:setTouchEnabled(true)
    self.soul_icon = self.bottom_bar_node:getChildByName("soul_icon") 
    self.soul_desc = self.bottom_bar_node:getChildByName("soul_desc")

    
    self.magic_gold_icon =  self.bottom_bar_node:getChildByName("Image_14")    

    self.points_btn = self.bottom_bar_node:getChildByName("points_btn") 
    self.magic_cost_text = self.points_btn:getChildByName("value_all_0") 

    self.value_all_text = self.bottom_bar_node:getChildByName("value_all") 
    -- 改名按钮
    self.rename_btn = self.root_node:getChildByName("rename_btn")

    --契约信息
    self.contract_img = self.root_node:getChildByName("contract_tip")
    self.contract_img:setTouchEnabled(true)

    self.fb_share_node = self.root_node:getChildByName("fb_share_panel")
    self.fb_share_btn = self.fb_share_node:getChildByName("fb_share_btn")
    self.fb_share_num = self.fb_share_node:getChildByName("reward_num")

    if platform_manager:GetChannelInfo().facebook_share_not_get_reward then
        self.fb_share_desc = self.fb_share_node:getChildByName("reward_desc")
        self.fb_share_icon = self.fb_share_node:getChildByName("reward_icon")
        self.fb_share_bg = self.fb_share_node:getChildByName("bg")
        self.fb_share_num:setVisible(false)
        self.fb_share_desc:setVisible(false)
        self.fb_share_icon:setVisible(false)
        self.fb_share_bg:setVisible(false)
    end

    self.race_bg_img = self.root_node:getChildByName("race_bg_0")
    self.num_limit_img = self.root_node:getChildByName("limit_bg")
    self.num_limit_text = self.num_limit_img:getChildByName("Text_42_0")

    self.template_id = 0
    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

--若是佣兵已经被招募，则mercenary_id = instance_id, 否则mercenary_id = template_id
function mercenary_detail_panel:Show(mode, mercenary_id, formation_id, cost, limit, magic_count)  
    self.limit = limit 
    self.formation_id = formation_id or troop_logic:GetCurFormationId()
    self.last_template_id = self.template_id

    self.fb_share_node:setVisible(false)
    self.fb_share_num:setString(string.format(lang_constants:Get("share_og_get_reward_count"),constants["SNS_SHARE_REWARD"]["share_mercenary"]))
    
    if mode == MERCENARY_DETAIL_MODE["recruit"] then
        if channel_info.has_sns_share then
            self.fb_share_node:setVisible(sns_logic:CanShare(constants.SNS_EVENT_TYPE["share_mercenary"], mercenary_id))
        end
    end
    --是否是图鉴进来的
    self.is_pokedex = false

    if mode == MERCENARY_DETAIL_MODE["formation"] or mode == MERCENARY_DETAIL_MODE["list"] or mode == MERCENARY_DETAIL_MODE["fire"] then
        self.instance_id = mercenary_id
        self.mercenary_info = troop_logic:GetMercenaryInfo(self.instance_id)
        self.template_info = self.mercenary_info.template_info
        self.template_id = self.template_info.ID

        self.view_info_btn:setVisible(true)

        self.is_leader = self.mercenary_info.is_leader

        if self.is_leader then
            self.name_text:setString(troop_logic:GetLeaderName())
            self.mercenary_info_sub_panel:LoadLeaderInfo(self.mercenary_info, self.template_info)

            self:LoadLeaderSkillInfo()
            self.contract_img:setColor(panel_util:GetColor4B(0xffffff))

        else
            self.name_text:setString(self.template_info.name)
            self.mercenary_info_sub_panel:LoadMercenaryInfo(self.mercenary_info)

            if self.mercenary_info.contract_lv ~= 0 then
                self.contract_img:setColor(panel_util:GetColor4B(0xffffff))
            else
                self.contract_img:setColor(panel_util:GetColor4B(0x7f7f7f))
            end
            self:ParseSkills()
        end

        if self.mercenary_info.expire_time and self.mercenary_info.expire_time ~= 0  then
            self.expire_time_state = true
            self.expire_time = math.max(0, self.mercenary_info.expire_time - time_logic:Now()) 
        else
            self.expire_time = 0
        end
    else
        self.is_pokedex = true
        self.expire_time_state = false
        self.expire_time = 0
        self.contract_img:setVisible(true)
        self.contract_img:setColor(panel_util:GetColor4B(0xffffff))

        self.is_leader = false
        self.template_id = mercenary_id
        self.template_info = mercenary_config[self.template_id]
        self.view_info_btn:setVisible(false)
        self.mercenary_info = nil
        self.name_text:setString(self.template_info.name)

        self:ParseSkills()
    end

    local quality_str =  lang_constants:Get("mercenary_quality" .. self.template_info.quality)
    local race_str = lang_constants:GetRace(self.template_info.race)
    local sex_str = lang_constants:GetSex(self.template_info.sex)
    local job_str = lang_constants:GetJob(self.template_info.job)
    self.race_text:setString(quality_str .. "/" .. race_str .. "/" .. sex_str .. "/" .. job_str)

    self.ui_role:Init(self.role_sprite, self.template_info.sprite)
    self.ui_role:SetScale(4, 4)
    self.ui_role:WalkAnimation(1, 0.3)

    self.biography_sub_panel:Load(self.template_info)
    self.mercenary_info_sub_panel.root_node:setVisible(false)

    self.skill_type = 1
    --图鉴进来的可以重新招募
    self.mode = mode
    if mode == client_constants["MERCENARY_DETAIL_MODE"]["library"] then
        self:SetRecruitMercenaryInfo()
        self.bottom_bar_node:setVisible(true)
        self.rename_btn:setVisible(false)

        utils:hide(self.cur_count_des_text,self.magic_gold_icon,self.value_all_text,self.points_btn) 
        utils:show(self.recruit_btn,self.soul_icon,self.soul_desc,self.soul_num_text)
    elseif mode == "magic_shop" then
        utils:show(self.bottom_bar_node,self.cur_count_des_text,self.magic_gold_icon,self.value_all_text,self.points_btn)
        utils:hide(self.rename_btn,self.recruit_btn,self.soul_icon,self.soul_desc,self.soul_num_text)  
        self.rename_btn:setVisible(false)
        self.magic_cost_text:setString(tostring(cost))

        self.value_all_text:setString(tostring(magic_count))  

    else
        utils:hide(self.cur_count_des_text) 
        self.bottom_bar_node:setVisible(false)
        self.rename_btn:setVisible(self.is_leader)
    end

    -- 如果和上次打开的是不一样的佣兵窗口
    if self.template_id ~= self.last_template_id then
        local count = chat_logic:GetCommentNum(constants.COMMENT_TYPE["mercenary"], self.template_id)
        if count then
            self.comment_num_text:setString(tostring(count))
        else
            self.comment_num_text:setString(tostring(0))
            -- 查询佣兵评论
            chat_logic:QueryCommentNum(constants.COMMENT_TYPE["mercenary"], self.template_id)
        end
    end

    self.num_limit_img:setVisible(false)

    --限时佣兵倒计时显示
    if self.expire_time > 0 then
        if self.race_bg_img and self.race_bg_img:isVisible() == false then
            self.race_bg_img:setVisible(true)
        end
    else
        if self.race_bg_img and self.race_bg_img:isVisible() == true then
            self.race_bg_img:setVisible(false)
        end
        if mercenary_config[self.template_id]["num_limit"] and mercenary_config[self.template_id]["num_limit"] > 0 then
            self.num_limit_img:setVisible(true)
            self.num_limit_text:setString(mercenary_config[self.template_id]["num_limit"])
        end
    end

    self.root_node:setVisible(true)
end

function mercenary_detail_panel:Update(elapsed_time)
    if self.expire_time_state then
        self.expire_time = self.expire_time - elapsed_time
        if self.expire_time < 0 then
            self.expire_time = 0
            self.expire_time_state = false
            if self.race_bg_img and self.race_bg_img:isVisible() == true then
                self.race_bg_img:setVisible(false)
            end
            troop_logic:Query_toop_info()
            --倒计时结束关闭界面
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            graphic:DispatchEvent("hide_floating_panel")
            graphic:DispatchEvent("expire_time_over")
        end
        if self.race_bg_img and self.race_bg_img:isVisible() == true then
            self.race_bg_img:getChildByName("Text_42"):setString(lang_constants:Get("mercenary_detail_panel_race_bg_img_text")..panel_util:GetTimeStr(self.expire_time))
        end
    end
end

--解析佣兵技能
function mercenary_detail_panel:ParseSkills()
    panel_util:ParseSkillInfo(self.template_info.ID, self.skills_info)
    for i = 1, 4 do
        local info = self.skills_info[i]
        self.skill_imgs[i]:loadTexture(info.icon, PLIST_TYPE)

        --显示 技能只能触发一次
        if info.active_num == 1 then
            info.name = string.format(lang_constants:Get("mercenary_skill_active_num"), info.name, info.active_num)
        end

        --宝具技
        if i == 4 then
            self.artifact_and_destiny_icon_img:setVisible(info.has_skill)
            if info.has_skill and info.artifact_icon then
                self.artifact_and_destiny_icon_img:loadTexture(info.artifact_icon, PLIST_TYPE)
                info.can_use = self.mercenary_info and self.mercenary_info.is_open_artifact or false
            end
        end
    end

    --设定技能icon_pos
    local skill_num = 4
    for i = 4, 1, -1 do
        local has_skill = self.skills_info[i].has_skill
        local skill_img = self.skill_imgs[i]
        skill_img:setVisible(has_skill)

        if has_skill then
            --设定位置
            local pos = self.skill_imgs_pos[skill_num]
            skill_img:setPosition(pos.x, pos.y)
            skill_num = skill_num - 1
        end
    end
end

--加载并显示主角宿命武器技能信息
function mercenary_detail_panel:LoadLeaderSkillInfo()
    self.coop_and_artifact_text:setVisible(false)

    local weapon_id = troop_logic:GetFormationWeaponId(self.formation_id)

    if weapon_id ~= 0 then
        local skill_name, skill_desc = "", ""
        self.skill_imgs[SKILL_TYPE["destiny_skill"]]:loadTexture(client_constants["SKILL_BG_IMG_PATH"], PLIST_TYPE)
        self.skill_imgs[SKILL_TYPE["destiny_skill"]]:setVisible(true)

        --已装备宿命武器
        local destiny_skill_info = panel_util:GetSkillInfo(destiny_skill_config[weapon_id]["skill_id"])

        self.artifact_and_destiny_icon_img:setVisible(true)
        self.artifact_and_destiny_icon_img:loadTexture(destiny_skill_config[weapon_id]["icon"], PLIST_TYPE)

        skill_name = string.format(lang_constants:Get("mercenary_destiny_skill_name"), destiny_skill_info.name)
        skill_desc = destiny_skill_info.desc

        self.lead_skill_info.name = skill_name
        self.lead_skill_info.desc = skill_desc

    else
        self.skill_imgs[SKILL_TYPE["destiny_skill"]]:setVisible(false)
        self.artifact_and_destiny_icon_img:setVisible(false)
        self.lead_skill_info.name = nil
        self.lead_skill_info.desc = nil
    end

    for i = 1, 3 do
        self.skill_imgs[i]:setVisible(false)
    end
end

--技能描述
function mercenary_detail_panel:ShowMercenarySkillDesc()
    local skill_type = self.skill_type

    local is_artifact_skill = false

    if feature_config:IsFeatureOpen("artifact_upgrade") then
        self.skill_artifact_skill1_name_text:setVisible(false)
        self.skill_artifact_skill2_name_text:setVisible(false)
    end
        
    if self.is_leader then
        self.skill_name_text:setString(self.lead_skill_info.name)
        self.skill_desc_text:setString(self.lead_skill_info.desc)
    else
        local skill_info = self.skills_info[skill_type]
        if not skill_info.has_skill then
            return
        end
        
        self.skill_name_text:setString(skill_info.name)
        self.skill_desc_text:setString(skill_info.desc)
        self.skill_desc_text:setVisible(true)

        if skill_type == SKILL_TYPE["personal_skill"] then
            self.coop_and_artifact_text:setVisible(false)

        elseif skill_type == SKILL_TYPE["artifact_skill"] then
            local str = ""
            local color
            if skill_info.can_use then
                str = lang_constants:Get("mercenary_open_artifact")
                color = 0x61E622
            else
                str = lang_constants:Get("mercenary_not_open_artifact")
                color = 0xE66221
            end
            self.coop_and_artifact_text:setVisible(true)
            self.coop_and_artifact_text:setString(str)
            self.coop_and_artifact_text:setColor(panel_util:GetColor4B(color))

            --位置偏移一点点
            if channel_info.mercenary_detail_panel_coop_and_artifact_text_pos_x then
               self.coop_and_artifact_text:setPositionX(self.skill_name_text:getPositionX()+self.skill_name_text:getContentSize().width/2+self.coop_and_artifact_text:getContentSize().width) 
            end

            if feature_config:IsFeatureOpen("artifact_upgrade") then
                is_artifact_skill = true
                self.skill_artifact_skill1_name_text:setVisible(true)
                self.skill_artifact_skill2_name_text:setVisible(true)
                self.skill_desc_text:setVisible(false)

                --宝具基础属性
                self.skill_artifact_skill1_name_text:setString(lang_constants:Get("mercenary_artifact_info_desc"))
                self.skill_artifact_skill1_desc_text:setString(skill_info.desc)
                --宝具等级
                if self.is_pokedex then
                    self.skill_artifact_skill2_name_text:setString(lang_constants:Get("mercenary_artifact_updage_full"))
                    if self.template_info.have_artifact_upgrade then
                        --可以升级
                        self.skill_artifact_skill2_desc_text:setString(troop_logic:GetArtifactUpdageInfoDesc(self.template_id))
                    else
                        --无法升级
                        self.skill_artifact_skill2_desc_text:setString(lang_constants:Get("mercenary_not_artifact_updage_desc"))
                    end
                else
                    self.skill_artifact_skill2_name_text:setString(lang_constants:Get("mercenary_artifact_updage_advanced"))
                    self.skill_artifact_skill2_desc_text:setString(troop_logic:GetArtifactUpdageInfo(self.instance_id))
                end
            end
        else
            self.coop_and_artifact_text:setVisible(true)
            local str = ""
            local color

            if skill_info.can_use then
                str = lang_constants:Get("coop_skill_activated")
                color = 0x61E622
            else
                color = 0xE66221
                str = lang_constants:Get("coop_skill_unactivated")
            end

            self.coop_and_artifact_text:setString(str)
            self.coop_and_artifact_text:setColor(panel_util:GetColor4B(color))
            
            --位置偏移一点点
            if channel_info.mercenary_detail_panel_coop_and_artifact_text_pos_x then
               self.coop_and_artifact_text:setPositionX(self.skill_name_text:getPositionX()+self.skill_name_text:getContentSize().width/2+self.coop_and_artifact_text:getContentSize().width) 
            end
        end
    end

    self:SetSkillInfoBgContentSize(is_artifact_skill)

    if self.skill_type == SKILL_TYPE["coop_skill1"] or self.skill_type == SKILL_TYPE["coop_skill2"] then
        local skill_id = self.skills_info[self.skill_type].id
        if skill_id ~= 0 then
            local x = self.skill_info_bg_img:getPositionX() + self.skill_info_bg_img:getContentSize().width / 2
            local y = self.skill_info_bg_img:getPositionY() - self.skill_bg_height
            graphic:DispatchEvent("show_floating_panel", nil, nil, x, y, false, self.formation_id, skill_id)

        end
    end
end

--设定技能描述背景图片的大小
function mercenary_detail_panel:SetSkillInfoBgContentSize(is_artifact)
    local line_num = 0

    if feature_config:IsFeatureOpen("artifact_upgrade") and is_artifact then
        --是宝具升级技能属性展示
        local label_render1 = self.skill_artifact_skill1_desc_text:getVirtualRenderer()
        line_num = label_render1:getStringNumLines()
        local label_render2 = self.skill_artifact_skill2_desc_text:getVirtualRenderer()
        line_num = line_num + label_render2:getStringNumLines()
    else
        local label_render = self.skill_desc_text:getVirtualRenderer()
        line_num = label_render:getStringNumLines()
    
        if platform_manager:GetChannelInfo().is_open_system then
            local size = self.skill_desc_text:getAutoRenderSize()
            local content_size = label_render:getContentSize()
            line_num = math.ceil(size.width / content_size.width) + 1
        end
    end

    local height = MIN_SKILL_BG_HEGHT
    if line_num > 2 then
        height = height + (line_num - 2) * SKILL_DESC_LINE_HEIGHT   --FYD 
    end

    local width = self.skill_bg_init_width
    self.skill_info_bg_img:setContentSize(cc.size(width, height))

    self.skill_name_text:setPositionY(height - 20)
    self.coop_and_artifact_text:setPositionY(height - 20)

    self.skill_line_img:setPositionY(height - 56)
    self.skill_desc_text:setPositionY(height - ARTIFACT_SKILL1_TEXT_DIS_TOP)

    if feature_config:IsFeatureOpen("artifact_upgrade") then
        --设置宝具等级信息位置
        self.skill_artifact_skill1_name_text:setPositionY(height - ARTIFACT_SKILL1_TEXT_DIS_TOP)
        local label_render1 = self.skill_artifact_skill1_desc_text:getVirtualRenderer()
        line_num = label_render1:getStringNumLines()
        self.skill_artifact_skill2_name_text:setPositionY(self.skill_artifact_skill1_name_text:getPositionY() - line_num * SKILL_DESC_LINE_HEIGHT)
    end

    self.skill_info_bg_img:setPositionY(self.skill_imgs[self.skill_type]:getPositionY() + height / 2)
    self.skill_bg_height = height
    --r2 两行显示
     --位置偏移一点点
    if channel_info.mercenary_detail_panel_coop_and_artifact_text_pos_x then
        local offset_y = -5
        self.skill_name_text:setPositionY(height - 20+offset_y)
        self.coop_and_artifact_text:setPositionY(height - 10)
        self.skill_line_img:setPositionY(height - 56+offset_y)
        self.skill_desc_text:setPositionY(height - 62+offset_y)
        self.skill_bg_height = height+5
    end
end

function mercenary_detail_panel:SetRecruitMercenaryInfo()
    local count = troop_logic:GetMercenaryLibraryCount(self.template_info.ID) or 0
    self.soul_num_text:setString(tostring(count))
end

function mercenary_detail_panel:RegisterWidgetEvent()
    --选中并查看某种技能
    local view_skill_info = function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")
            self.skill_type = widget:getTag()
            self.skill_info_bg_img:setVisible(true)
            self:ShowMercenarySkillDesc()

        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            self.skill_info_bg_img:setVisible(false)
            graphic:DispatchEvent("hide_floating_panel")

        end

    end

    for i = 1, 4 do
        local skill_img = self.skill_imgs[i]
        skill_img:setTag(i)
        skill_img:setTouchEnabled(true)
        skill_img:addTouchEventListener(view_skill_info)
    end

    self.contract_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then

            local pos = widget:getTouchBeganPosition()

            local name = lang_constants:Get("mercenary_contract_add")
            local desc = ""

            if self.is_leader then
                name, desc = panel_util:GetLeaderContractInfo()
            else
                if not troop_logic:CanContractLv(self.template_id) then
                    desc = lang_constants:Get("mercenary_cant_sign_contract")
                else
                    if self.mercenary_info then
                        if self.mercenary_info.contract_lv > 0 then
                            desc = panel_util:GetContactPropertyDesc(self.instance_id)
                        else
                            desc = lang_constants:Get("mercenary_contract_state2")
                        end
                    else
                        desc = panel_util:GetMaxContractLvProperty(self.template_id)
                    end
                end
            end

            graphic:DispatchEvent("show_floating_panel", name, desc, pos.x, pos.y - 20)

        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            graphic:DispatchEvent("hide_floating_panel")
        end
    end)


    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            graphic:DispatchEvent("hide_floating_panel")

        end
    end)

    self.view_info_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")
            self.mercenary_info_sub_panel.root_node:setVisible(true)
        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            self.mercenary_info_sub_panel.root_node:setVisible(false)
        end
    end)

    --显示召回面板, 改名面板
    self.recruit_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            -- graphic:DispatchEvent("show_world_sub_panel", "mercenary_soul_stone_panel", self.template_id, "recruit")
            troop_logic:CheckMercenarycCutDownTime(self.template_id)
        end
    end)
    --商城积分兑换
    self.points_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click") 
            local str1 = lang_constants:Get("mercenary_get")
            local str2 = lang_constants:Get("mercenary_desc")
            local str3 = lang_constants:Get("magic_commit")
            local str4 = lang_constants:Get("magic_cancel")

            graphic:DispatchEvent("show_simple_msgbox", str1,
                str2,
                str3,
                str4,
                function() 
                    graphic:DispatchEvent("get_mercenary",self.template_info.ID,self.limit) 
                end)
        end
    end) 

    --灵魂结晶浮层
    self.soul_crystal_bg_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            local pos = widget:getTouchBeganPosition()
            local soul_name = lang_constants:Get("mercenary_soul_crystal_name")
            local soul_desc = lang_constants:Get("mercenary_soul_crystal_desc")
            if self.mode == "magic_shop" then  -- 资源跳转
                 soul_name = lang_constants:Get("mercenary_magic_gold_name")
                 soul_desc = lang_constants:Get("mercenary_magic_gold_desc")
            end
            graphic:DispatchEvent("show_floating_panel", soul_name, soul_desc, 320, pos.y)

        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            graphic:DispatchEvent("hide_floating_panel")
        end
    end)

    -- 打开佣兵评论窗口
    self.open_comment_msgbox_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            chat_logic:QueryCommentList(constants.COMMENT_TYPE["mercenary"], self.template_info.ID)
        end
    end)

    -- 改名面板
    self.rename_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "rename_panel", client_constants["RENAME_PANEL_MODE"]["user"])
        end
    end)

    graphic:RegisterEvent("update_magic_gold", function()    
        local count = resource_logic:GetResourcenNumByName("magic_gold")  
        self.value_all_text:setString(tostring(count))    
    end)
    
    -- 领取奖励
    self.fb_share_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if self.mode == MERCENARY_DETAIL_MODE["recruit"] then
                sns_logic:Share(constants.SNS_EVENT_TYPE["share_mercenary"], self.template_id)
            end
        end
    end)
end

function mercenary_detail_panel:RegisterEvent()
    --图书馆招募成功
    graphic:RegisterEvent("library_recruit_success", function(template_id)
        if not self.root_node:isVisible() then
            return
        end

        local count = troop_logic:GetMercenaryLibraryCount(self.template_info.ID) or 0
        self.soul_num_text:setString(tostring(count))

    end)

    --成功合成一枚灵魂石
    graphic:RegisterEvent("craft_soul_stone_success2", function(template_id)

        if not self.root_node:isVisible() then
            return
        end

        local count = troop_logic:GetMercenaryLibraryCount(self.template_info.ID) or 0
        self.soul_num_text:setString(tostring(count))
    end)

    graphic:RegisterEvent("update_comment_num", function(comment_type, mercenary_id, num)
        if not self.root_node:isVisible() or not self.template_info or comment_type ~= COMMENT_TYPE then
            return
        end

        if tonumber(mercenary_id) ~= self.template_info.ID then
            return
        end

        self.comment_num_text:setString(tostring(num))
    end)

    graphic:RegisterEvent("update_panel_leader_name", function(name)
        if not self.root_node:isVisible() or not self.is_leader then
            return
        end

        self.name_text:setString(name)
    end)

    -- 隐藏FB按钮
    graphic:RegisterEvent("hide_new_mercenary_fb_node", function()
        if self.root_node:isVisible() then
            self.fb_share_node:setVisible(false)
        end
    end)
end

return mercenary_detail_panel
