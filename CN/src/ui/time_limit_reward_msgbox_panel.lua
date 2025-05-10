local panel_prototype = require "ui.panel"
local limite_logic = require "logic.limite"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local time_logic = require "logic.time"
local user_logic = require "logic.user"
local icon_template = require "ui.icon_panel"

local item_config = config_manager.item_config
local resource_config = config_manager.resource_config

local client_constants = require "util.client_constants"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"
local panel_util = require "ui.panel_util"
local SMALL_QUALITY_BG = client_constants["SMALL_QUALITY_BG"]
local RESOURCE_TYPE = constants["RESOURCE_TYPE"]
local REWARD_TYPE = constants["REWARD_TYPE"]

local PLIST_TYPE = ccui.TextureResType.plistType
local BG_COLOR_MAP = client_constants["BG_QUALITY_COLOR"]
local BLOOD_DIAMOND_ICON_PATH = "icon/resource/blood_diamond.png"

local time_limit_reward_msgbox_panel = panel_prototype.New(true)
function time_limit_reward_msgbox_panel:Init()
    --加载csb
    self.root_node = cc.CSLoader:createNode("ui/time_limit_reward_msgbox.csb")
    
    self.buy_btn = self.root_node:getChildByName("comment_box"):getChildByName("comment_btn")

    self.scrollview = self.root_node:getChildByName("comment_box"):getChildByName("list_scrollview_0")

    self.time_label = self.root_node:getChildByName("Text_32"):getChildByName("value") 

    self.original_price_label = self.root_node:getChildByName("Text_34")  --原价标签
    self.original_price_icon = self.root_node:getChildByName("Image_44"):getChildByName("Image_45")

    self.present_price_label = self.buy_btn:getChildByName("Text_35")  --现价价标签
    self.present_price_icon = self.buy_btn:getChildByName("Image_45_0")

    self.present_price_label:setAnchorPoint(cc.p(0,0.5))
    --购买按钮文字位置修改
    self.present_price_label:setPositionX(self.buy_btn:getChildByName("Image_45_0"):getPositionX()+self.buy_btn:getChildByName("Image_45_0"):getContentSize().width/2+5)

    self.buy_btn_desc = self.buy_btn:getChildByName("Text_35_0")
    self.buy_btn_desc:setAnchorPoint(cc.p(0,0.5))


    -- local light_img = self.root_node:getChildByName("template1"):getChildByName("Image_114")
    -- light_img:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeIn:create(0.5),cc.FadeOut:create(0.5))))
    -- light_img:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.ScaleTo:create(0.5,0.8),cc.ScaleTo:create(0.5,0.6))))

    self.template_item = self.scrollview:getChildByName("mercenary_template")
    self.template_item:getChildByName("Text_52"):setRotation(34)
    local template_item_desc_label = self.template_item:getChildByName("Text_50_0")
    template_item_desc_label:setPositionY(template_item_desc_label:getPositionY()-10)
    template_item_desc_label:setTextAreaSize(cc.size(289,49))
    template_item_desc_label:ignoreContentAdaptWithSize(false)
    self.template_item:setVisible(false)

    self.items_panel = {}
    self.items_icon = {}
    self.canBuy = true
    self.jumpToTop = true
    self.show_index = 0
    self.is_open_blood_buy = false
    self.need_cost = 0

    self.time_label:setString("00:00:00")

    self.duration = 3600
    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function time_limit_reward_msgbox_panel:SetPriceDynamic()
    -- 根据语言调整小数点格式
    -- local language = platform_manager:GetLocale()
    -- if language == "de" or language == "fr" or language == "es-MX" or language == "ru" and platform_manager:GetChannelInfo().panel_util_change_language_dot_format then
    --     value = panel_util:SetFormatWithPoint(value)
    -- end
    -- self.price_value_text:setString(value)
end

function time_limit_reward_msgbox_panel:Show()

    self.root_node:setVisible(true)
    self.duration = math.max(limite_logic.over_time - time_logic:Now(),0)

    if self.duration == 0 and limite_logic.is_open_blood_buy then
        --血钻购买开启
        self.is_open_blood_buy = true
    end

    if limite_logic.is_come_in == 0 and not self.is_open_blood_buy then
        limite_logic:SetComeHere(1)
    end
    --判断当前显示的内容是不是和mode中的数据内容标一致不一致，重新导入内容
    if self.show_index ~= limite_logic.show_index and not self.is_open_blood_buy then
        self.show_index = limite_logic.show_index
        self:UpdateScrollView() 
    end

    --血钻购买
    if self.is_open_blood_buy then
        local config = limite_logic:GetBloodBuyConfig()
        if config then
            self.duration = math.max(config.end_time - time_logic:Now(),0)
            self:InitScoreView(config)
            self:InitByBlood(config)
        end
    end
end

--更新奖励列表
function time_limit_reward_msgbox_panel:UpdateScrollView()

    if limite_logic.show_index > limite_logic:GetLimites() then
        return
    end
    local config = limite_logic:GetConfig()
    self:InitScoreView(config)
    self.original_price_label:setString(lang_constants:Get("time_limit_reward_msgbox_panel_usd")..limite_logic:GetOldPrice()) --设置原价
    self.present_price_label:setString(lang_constants:Get("time_limit_reward_msgbox_panel_usd")..limite_logic:GetNowPrice())

    --立即购买文字位置偏移
    --r2立即购买文字位置偏移
    local time_limit_buy_btn_desc_offset_x = platform_manager:GetChannelInfo().time_limit_buy_btn_desc_offset_x or 5
    self.buy_btn_desc:setPositionX(self.present_price_label:getPositionX()+self.present_price_label:getContentSize().width+time_limit_buy_btn_desc_offset_x)

end

function time_limit_reward_msgbox_panel:InitScoreView(config)
    if config.reward_list then
        local i = 1
        local reward_list = config.reward_list[limite_logic.show_index].reward_info
        local max_row = #reward_list --最大行数
        max_height = 0
        
        for k,re in pairs(reward_list) do
            if self.items_panel[i] == nil then
                --这个item没有创建一个
                self.items_panel[i] = self.template_item:clone()
                self.scrollview:addChild(self.items_panel[i])
                if #reward_list >= 3 then
                    --当超过两行后另外计算
                    self.items_panel[i]:setPositionY((i)*self.items_panel[i]:getContentSize().height+(i-1)*10)
                else
                    --当只有两行是就不需要
                    self.items_panel[i]:setPositionY(self.scrollview:getContentSize().height-(i-1)*(self.items_panel[i]:getContentSize().height+10))
                end
                self.items_panel[i]:setVisible(true)
                --加载物品icon
                local sub_panel = icon_template.New()
                sub_panel:Init(self.items_panel[i])
                self.items_icon[i] = sub_panel
                self.items_icon[i].root_node:setPosition(cc.p(58,62))

                max_height = self.items_panel[i]:getPositionY()
            else
                if #reward_list >= 3 then
                    --当超过两行后另外计算
                    self.items_panel[i]:setPositionY((i)*self.items_panel[i]:getContentSize().height+(i-1)*10)
                else
                    --当只有两行是就不需要
                    self.items_panel[i]:setPositionY(self.scrollview:getContentSize().height-(i-1)*(self.items_panel[i]:getContentSize().height+10))
                end
                self.items_panel[i]:setVisible(true)
                max_height = self.items_panel[i]:getPositionY()
            end
            
            local config = self.items_icon[i]:Show(re.reward_type,re.param1, re.param2,  false, false)

            local iconName = self.items_panel[i]:getChildByName("Text_50")
            local icondesc = self.items_panel[i]:getChildByName("Text_50_0")
            if re.reward_type == 6 then
                iconName:setString(lang_constants:Get("limite_figt_5000_title"))
                icondesc:setString(lang_constants:Get("limite_figt_5000_desc"))
            else
                iconName:setString(config.name)
                icondesc:setString(config.desc)
            end

            i = i + 1
        end
        --更改scrollview大小
        for k=i,#self.items_panel do
            if self.items_panel[k] then
                self.items_panel[k]:setVisible(false)
            end
        end

        if max_row >= 3 and max_height >= self.scrollview:getContentSize().height then
            self.scrollview:setInnerContainerSize(cc.size(self.scrollview:getContentSize().width,max_height))
            if self.jumpToTop then
                self.jumpToTop = false
                self.scrollview:jumpToTop()
            end
        else
            self.scrollview:setInnerContainerSize(cc.size(self.scrollview:getContentSize()))
        end
    end
    
end

function time_limit_reward_msgbox_panel:Update(elapsed_time)
    if self.duration and self.duration > 0 then
        self.duration = math.max(self.duration - elapsed_time, 0)
        local duration = math.ceil(self.duration)
        local hour = math.floor(duration / (60 * 60))
        local time_str = ""
        if hour < 24 or self.is_open_blood_buy then
            time_str = panel_util:GetTimeStr(self.duration)
        else
            time_str = string.format("%dday",math.floor(hour/24))
        end

        self.time_label:setString(time_str)
    else
        graphic:DispatchEvent("hide_world_sub_panel", "time_limit_reward_msgbox_panel")
    end
end

--用血钻购买
function time_limit_reward_msgbox_panel:InitByBlood(config)
    self.original_price_label:setString(config.mult_num1[limite_logic.show_index]) --设置原价
    self.present_price_label:setString(config.mult_num2[limite_logic.show_index]) --设置现价
    self.need_cost = config.mult_num2[limite_logic.show_index]

    self.original_price_icon:loadTexture(BLOOD_DIAMOND_ICON_PATH, PLIST_TYPE)
    self.present_price_icon:loadTexture(BLOOD_DIAMOND_ICON_PATH, PLIST_TYPE)

    if limite_logic.find_carnival then
        --立即购买文字
        self.present_price_label:setVisible(true)
        self.present_price_icon:setVisible(true)
        self.buy_btn_desc:setAnchorPoint(cc.p(0,0.5))
        self.buy_btn_desc:setString(lang_constants:Get("limite_buy_now"))
        self.buy_btn:setColor(panel_util:GetColor4B(client_constants["LIGHT_BLEND_COLOR"]))
    else
        --购买完所有的
        self.present_price_label:setVisible(false)
        self.present_price_icon:setVisible(false)
        self.buy_btn_desc:setAnchorPoint(cc.p(0.5,0.5))
        self.buy_btn_desc:setString(lang_constants:Get("limite_buy_all"))
        self.buy_btn:setColor(panel_util:GetColor4B(client_constants["DARK_BLEND_COLOR"]))
    end

end

function time_limit_reward_msgbox_panel:RegisterEvent()
    graphic:RegisterEvent("buy_limite_success", function()
        self.jumpToTop = true
        --购买成功后
        self:UpdateScrollView() --刷新视图
        --关闭掉自己 触发机制用的
        graphic:DispatchEvent("hide_world_sub_panel", "time_limit_reward_msgbox_panel")
    end)

    graphic:RegisterEvent("update_sub_carnival_reward_status", function()
        if not self.root_node:isVisible() then
            return
        end
        if self.is_open_blood_buy then
            local config = limite_logic:GetBloodBuyConfig()
            if config then
                self:InitScoreView(config)
            end
            self:InitByBlood(config)
        end
    end)
end

function time_limit_reward_msgbox_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("back_btn"), "time_limit_reward_msgbox_panel")

    self.buy_btn:addTouchEventListener(function(widiget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if not self.is_open_blood_buy then
                limite_logic:BuyLimite()
            else
                if limite_logic.find_carnival then
                    local mode = client_constants["CONFIRM_MSGBOX_MODE"]["buy_limite_use_blood_tips"]
                    graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode, self.need_cost)
                else
                    graphic:DispatchEvent("show_prompt_panel", "buy_limite_by_blood_over")
                end
            end
        end
    end)

end

return time_limit_reward_msgbox_panel
