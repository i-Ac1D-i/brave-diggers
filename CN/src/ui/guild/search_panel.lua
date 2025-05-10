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
local search_panel = panel_prototype.New(true)
local item_sub_panel = panel_prototype.New()
item_sub_panel.__index = item_sub_panel

function item_sub_panel.New()
    return setmetatable({}, item_sub_panel)
end

function item_sub_panel:Init(cell,guild_cells,index)
    
    self.btn_guild_id={}
    self.guild_member_num = {}
    self.root_node = cell
    local guild_id = guild_cells.guild_id
    self.root_node:getChildByName("number"):setString(tostring(guild_cells.guild_num) .. "/" .. constants["GUILD_MAX_MEMBER"])
    self.root_node:getChildByName("guild_name"):setString(guild_cells.guild_name)
    self.root_node:getChildByName("bg"):setVisible(false)
    self.root_node:getChildByName("full"):setVisible(false)

    if guild_logic:alreadyJoin(guild_id) and guild_logic.guild_id == guild_id then -- 是否已加入
        self.root_node:getChildByName("bg"):setVisible(true)
        self.root_node:getChildByName("add_btn"):setVisible(false)
        self.root_node:getChildByName("full"):setVisible(false)

        local done = ccui.Text:create(lang_constants:Get("guild_jion"), client_constants["FONT_FACE"], 18)
        self.root_node:addChild(done,100)
        done:setPosition(436.81,67.27)
        done:setRotation(33)
        
    elseif guild_cells.guild_num > constants["GUILD_MAX_MEMBER"] then --是否满人
        self.root_node:getChildByName("add_btn"):setVisible(true)
    else

    end
    
    local cell_btn = self.root_node:getChildByName("add_btn")
    self.btn_guild_id[index] = guild_id
    cell_btn:setTag(index)
    self.guild_member_num[index] = guild_cells.guild_num

    cell_btn:addTouchEventListener(function (sender, event_type)   --加入按钮
        
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            if guild_logic:alreadyJoin(self.btn_guild_id[sender:getTag()]) then --是否已加入该工会
                graphic:DispatchEvent("show_prompt_panel", "guild_already_join")
                return 
            end

            if self.guild_member_num[sender:getTag()] > constants["GUILD_MAX_MEMBER"] then --是否满人
                graphic:DispatchEvent("show_prompt_panel", "guild_member_max")
                return
            end
           graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("confirm_join_guild_title"),
                        lang_constants:Get("confirm_join_guild_desc"),
                        lang_constants:Get("common_confirm"),
                        lang_constants:Get("common_cancel"),
            function()
                 search_panel.search_msgbox:getChildByName("close_btn"):setTouchEnabled(true)
                 guild_logic:JoinGuild(self.btn_guild_id[sender:getTag()])                   --确认 加入公会
            end)
        end
    end)

end


function search_panel:Init()

    self.guild_cells = {}
    self.btn_guild_id = {}
    self.guild_member_num = {}
    self.guild_num = 0
    self.root_node = cc.CSLoader:createNode("ui/guild_select_panel.csb")

    local root_node = self.root_node

    self.search_msgbox = root_node:getChildByName("search_msgbox")
    self.back_top_btn  = root_node:getChildByName("back_top_btn")                

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

    self.friend_node = self.root_node:getChildByName("Node_1")

    self.friend_info_img = self.friend_node:getChildByName("friend_info_bg")
    self.player_name_text = self.friend_info_img:getChildByName("name")
    self.login_time_text = self.friend_info_img:getChildByName("login_time")
    self.login_time_text:setVisible(false)

    self.cant_invite_btn = self.friend_info_img:getChildByName("cancel_btn")
    self.invite_btn = self.friend_info_img:getChildByName("invite_btn")
    self.search_btn = self.search_msgbox:getChildByName("search_btn")
    
    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(self.friend_info_img)
    self.icon_panel:SetPosition(80, 90)
    self.icon_panel.root_node:setTouchEnabled(true)
    
    self.guild_num_txt = self.friend_info_img:getChildByName("guild_num")
    self.guild_num_txt:setVisible(true)
    
    self.guild_bp_condition_txt = self.guild_num_txt:getChildByName("guild_bp_condition")
    self.scroll_view = self.search_msgbox:getChildByName("ScrollView_4")
    self.cell_template = self.scroll_view:getChildByName("guild_info_bg")
    self.cell_template:setTag(1001)
    self.item_sub_panels = {}
        --向服务端拉取数据
    guild_logic:GetGuildShowList()
    
    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function search_panel:CreateCell()

    self.scroll_view:setInnerContainerSize(cc.size(self.scroll_view:getContentSize().width,self.cell_template:getContentSize().height*self.guild_num))

    self.cell_template:setVisible(true)
    for i =1 ,#self.item_sub_panels do
        self.scroll_view:removeChildByTag(i)
    end

    for i = 1 ,#self.guild_cells do 
        local hight = i - 1
        local cell_panel = item_sub_panel.New()
        cell_panel:Init(self.cell_template:clone(),self.guild_cells[i],i)
        cell_panel.root_node:setPosition(cell_panel.root_node:getContentSize().width/2,self.scroll_view:getInnerContainerSize().height -(cell_panel.root_node:getContentSize().height/2) -  hight*cell_panel.root_node:getContentSize().height)
        self.item_sub_panels[i] = cell_panel.root_node
        self.scroll_view:addChild(cell_panel.root_node)
        cell_panel.root_node:setTag(i)
    end

    
    self.cell_template:setVisible(false)

end

function search_panel:Show()

    guild_logic:GetGuildShowList()
    self.root_node:setVisible(true)
    self.user_id_textfield:setString("")
    self.friend_node:setVisible(false)
    self.desc_text:setVisible(true)

end 

function search_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.search_msgbox:getChildByName("close_btn"), self:GetName())
    
    self.back_top_btn:addTouchEventListener(function (sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            self.scroll_view:scrollToTop(0.5,true)
        end
    end)

    self.search_btn:addTouchEventListener(function (sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local search_guild = self.user_id_textfield:getString()
            self.search_guild = search_guild
            guild_logic:SearchGuild(search_guild)
        end
    end)

    self.invite_btn:addTouchEventListener(function(sender, event_type)  -- 搜索工会
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
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

function search_panel:RegisterEvent()
    --搜索结果
    graphic:RegisterEvent("search_guild_result", function(data)
        if not self.root_node:isVisible() then
            return
        end
        local result = data.result
        local guild_name = data.guild_name
        local template_id = data.template_id
        self.member_num = data.member_num
        self.bp_limit_idx = data.bp_limit_idx
        if result == "success" then
            self.friend_node:setVisible(true)
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
        else

        end
    end)

    graphic:RegisterEvent("join_guild", function()
        if not self.root_node:isVisible() then
            return
        end
        graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
    end)

    --拉取工会列表
    graphic:RegisterEvent("get_guild_list_result",function (data)
        local result = data.result
        if result == "success" then
            self.guild_cells = data.guild_show_list

            if self.guild_cells then
                self.guild_num = #self.guild_cells
                self:CreateCell()
            else
                self.cell_template:setVisible(false)
            end
            
        end
    end)

end

return search_panel
