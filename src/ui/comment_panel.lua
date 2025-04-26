local graphic = require "logic.graphic"
local panel_util = require "ui.panel_util"
local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"
local spine_manager = require "util.spine_manager"
local lang_constants = require "util.language_constants"
local constants = require "util.constants"
local chat_logic = require "logic.chat"

-- 评论类型
local COMMENT_TYPE = constants["COMMENT_TYPE"]

local comment_panel = panel_prototype.New(true)

local sub_panel = panel_prototype.New()
sub_panel.__index = sub_panel

function sub_panel.New()
    return setmetatable({}, sub_panel)
end

function sub_panel:Init(root_node, comment_data)
    self.root_node = root_node
    self.root_node:setVisible(true)

    self.bg = root_node:getChildByName("bg")
    self.like_value = self.bg:getChildByName("value")
    self.author = self.bg:getChildByName("author")
    self.like_bg = self.bg:getChildByName("likebg")
    self.likeicon = self.bg:getChildByName("likeicon")
    self.click_area = self.bg:getChildByName("click")

    self.desc = root_node:getChildByName("desc")
    self.border = root_node:getChildByName("border")

    self.comment_data = comment_data
end

function sub_panel:UpdatePanel()
    if not self.comment_data then return end

    local comment_one = self.comment_data
    self.like_value:setString(tostring(comment_one.like_num))
    self.author:setString(comment_one.role)
    self.desc:setString(comment_one.comment)

    if self.comment_data.is_like then
        self.likeicon:setColor(panel_util:GetColor4B(0xFFFFFF))
    else
        self.likeicon:setColor(panel_util:GetColor4B(0xA0A0A0))
    end

    -- 单行字体的模版高度
    local height = 96

    local text_render = self.desc:getVirtualRenderer()
    local line_num = math.ceil(text_render:getContentSize().width / 390)
    -- 多行文本重置模版高度  26字体高度
    if line_num > 1 then
        local tmp = 26 * (line_num - 1)
        height = height + tmp

        self.desc:setPositionY(self.desc:getPositionY() + tmp)
        self.bg:setPositionY(self.bg:getPositionY() + tmp)
    end

    -- 点赞行为
    self.click_area:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:CommentLike(comment_panel.comment_id, comment_one.id, self.root_node:getPositionY())
        end
    end)

    return height
end

-- 点赞行为 记录容器位置
function sub_panel:CommentLike(template_id, id, template_pos_y)
    if not chat_logic:IsAuthorized() then
        return
    end

    local inner_pos_y = comment_panel.comment_list_view:getInnerContainer():getPositionY()
    local view_distance = template_pos_y - math.abs(inner_pos_y)

    comment_panel.thumbs_up_spine:setPosition(cc.p(460, view_distance+445))
    comment_panel.thumbs_up_spine:setAnimation(0, "animation", false)


    if self.comment_data then
        self.comment_data.is_like = not self.comment_data.is_like
        if self.comment_data.is_like then
            self.comment_data.like_num = self.comment_data.like_num + 1
            self.likeicon:setColor(panel_util:GetColor4B(0xFFFFFF))
        else
            self.comment_data.like_num = self.comment_data.like_num - 1
            self.likeicon:setColor(panel_util:GetColor4B(0xA0A0A0))
        end
        self.like_value:setString(tostring(self.comment_data.like_num))
    end

    chat_logic:LikeComment(id)
end


function comment_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/comment_panel.csb")

    --佣兵评论区
    self.comment_msgbox = self.root_node:getChildByName("comment_box")
    -- 关闭按钮
    self.close_btn = self.comment_msgbox:getChildByName("close_btn")
    -- 评论按钮
    self.comment_btn = self.comment_msgbox:getChildByName("comment_btn")
    -- 评论内容的scrollview
    self.comment_list_view = self.comment_msgbox:getChildByName("list_scrollview")
    -- 评论内容模版
    self.comment_template = self.root_node:getChildByName("comment_template")
    -- 默认文本
    self.default_txt1_text = self.comment_msgbox:getChildByName("default_txt1")
    self.default_txt2_text = self.comment_msgbox:getChildByName("default_txt2")

    self.title_txt = self.comment_msgbox:getChildByName("title")

    self.comment_template:setVisible(false)

    -- 点赞动画
    self.thumbs_up_spine = spine_manager:GetNode("thumbs_up", 1.0, true)
    self.root_node:addChild(self.thumbs_up_spine, 10)

    -- 评论窗口size
    self.comment_msgbox_view_size = self.comment_list_view:getContentSize()
    self.comment_template_height = self.comment_template:getContentSize().height
    self.comment_list_children = {}
    self.comment_inner_height = 0

    self.comment_type = 0
    self.comment_id = 0

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function comment_panel:Show(comment_type, id)

    self.root_node:setVisible(true)

    if self.comment_type ~= comment_type then

        if comment_type == COMMENT_TYPE["mercenary"] then
            self.title_txt:setString(lang_constants:Get("mercenary_comment_title"))
            self.comment_btn:setTitleText(lang_constants:Get("mercenary_comment_btn"))
            self.default_txt2_text:setString(lang_constants:Get("mercenary_comment_default_text"))

        elseif comment_type == COMMENT_TYPE["maze"] then
            self.title_txt:setString(lang_constants:Get("maze_comment_title"))
            self.comment_btn:setTitleText(lang_constants:Get("maze_comment_btn"))
            self.default_txt2_text:setString(lang_constants:Get("maze_comment_default_text"))
        end
    end

    local update_panel = false
    local comment_data = chat_logic:GetCommentList(comment_type, id)

    if self.comment_type == comment_type and self.comment_id == id then
        if comment_data and #comment_data ~= #self.comment_list_children then
            update_panel = true
        end
    end

    if self.comment_type ~= comment_type or self.comment_id ~= id then
        self.comment_id = id
        self.comment_type = comment_type

        update_panel = true
    end

    if update_panel then
        self:UpdateCommentBox(comment_data)
    end
end

-- 刷新佣兵评论窗口
function comment_panel:UpdateCommentBox(data)
    self.comment_list_view:removeAllChildren()
    self.comment_list_children = {}
    self.comment_list_update_idx = 1

    if not data or table.getn(data) == 0 then
        self.default_txt1_text:setVisible(true)
        self.default_txt2_text:setVisible(true)
        return
    end

    self.default_txt1_text:setVisible(false)
    self.default_txt2_text:setVisible(false)

    local comment_template_height, count = 96, #data
    local pos_y, inner_height, update_idx_pos_y = 0, 0, 0

    for idx = count, 1, -1 do
        -- 每一条评论
        local comment_one = data[idx]
        if comment_one then
            local child_panel = sub_panel.New()
            child_panel:Init(self.comment_template:clone(), comment_one)
            child_panel.root_node:setPosition(231, pos_y)

            self.comment_list_view:addChild(child_panel.root_node)
            self.comment_list_children[idx] = child_panel

            if self.comment_list_update_idx and self.comment_list_update_idx == idx then
                update_idx_pos_y = pos_y
            end

            local template_height = child_panel:UpdatePanel()
            pos_y = pos_y + template_height
            inner_height = inner_height + template_height
        end
    end

    -- inner height 小于容器高度, 重置children position
    if inner_height <= self.comment_msgbox_view_size.height then
        local dis = self.comment_msgbox_view_size.height - inner_height

        for _, child_panel in pairs(self.comment_list_children) do
            if child_panel then
                child_panel.root_node:setPositionY(child_panel.root_node:getPositionY() + dis)
            end
        end

        inner_height = self.comment_msgbox_view_size.height
    end

    -- 重置容器container
    self.comment_list_view:setInnerContainerSize(cc.size(462, inner_height))
    local top_pos_y = inner_height * -1 + self.comment_msgbox_view_size.height
    self.comment_list_view:getInnerContainer():setPositionY(top_pos_y)

    -- 调整容器位置
    if self.comment_list_update_idx and self.comment_list_update_idx > 0 then
        local distance = self.comment_msgbox_view_size.height/2
        if self.view_distance then
            distance = self.view_distance
            self.view_distance = nil
        end
        pos_y = update_idx_pos_y * -1 + distance

        local top_pos_y = inner_height * -1 + self.comment_msgbox_view_size.height

        if pos_y <  top_pos_y then
            pos_y = top_pos_y
        elseif pos_y > 0 then
            pos_y = 0
        end

        self.comment_list_view:getInnerContainer():setPositionY(pos_y)
        self.comment_list_update_idx = nil
    end
end

function comment_panel:RegisterWidgetEvent()
    -- 佣兵评论窗口关闭
    self.close_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", "comment_panel")
        end
    end)

    -- 添加佣兵评论按钮
    self.comment_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if not chat_logic:IsAuthorized() then
                return
            end

            graphic:DispatchEvent("hide_world_sub_panel", "comment_panel")
            graphic:DispatchEvent("show_world_sub_panel", "bbs_reply_panel", {["ID"] = self.comment_id}, self.comment_type)
        end
    end)
end


function comment_panel:RegisterEvent()
    graphic:RegisterEvent("update_comment_panel", function(comment_type, template_id, data)
        if not self.root_node:isVisible() then
            return
        end

        if comment_type ~= self.comment_type or tonumber(template_id) ~= self.comment_id then
            return
        end

        --更新窗口显示数据
        if data then
            self:UpdateCommentBox(data)
        end
    end)
end

return comment_panel
