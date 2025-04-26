local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local campaign_logic = require "logic.campaign"
local client_constants = require "util.client_constants"
local json = require "util.json"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"

local PLIST_TYPE = ccui.TextureResType.plistType

local campaign_rule_msgbox = panel_prototype.New(true)
function campaign_rule_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/campaign_rule_msgbox.csb")

    local scrol_view = self.root_node:getChildByName("scrol_view")

    self.bp_value = scrol_view:getChildByName("bp_value")

    self.mercenary_desc = scrol_view:getChildByName("mercenary_desc2")

    self.buff_icon = {}
    self.buff_value = {}

    self.buff_icon[1] = scrol_view:getChildByName("bp_buff")
    self.buff_value[1] = self.buff_icon[1]:getChildByName("bp_value")

    self.buff_icon[2] = scrol_view:getChildByName("property1_buff")
    self.buff_value[2] = self.buff_icon[2]:getChildByName("bp_value")

    self.buff_icon[3] = scrol_view:getChildByName("property2_buff")
    self.buff_value[3] = self.buff_icon[3]:getChildByName("bp_value")

    -- self.rank_num_texts = {}
    -- self.rank_title_texts = {}
    -- for i = 1, 7 do
    --     local widget = scrol_view:getChildByName("reward"..i)
    --     self.rank_title_texts[i] = widget:getChildByName("rank")
    --     self.rank_num_texts[i] = widget:getChildByName("num")
    -- end
    
    self:Composing()

    scrol_view:jumpToTop()

    self:RegisterWidgetEvent()
end

--界面排版
--在设置好文字之后排版
function campaign_rule_msgbox:Composing()
    local offsetY = 25;
    local scrol_view = self.root_node:getChildByName("scrol_view")

    local desc9 = scrol_view:getChildByName("desc9")
    local old_desc9_pos_y = desc9:getPositionY();
    local desc9_height = self:getLines(desc9:getString(),18*3) * desc9:getVirtualRendererSize().height
    desc9:setContentSize({width = 360, height = desc9_height })
    desc9:setPositionY(desc9_height+offsetY-10)

    local offset_desc9 = desc9:getPositionY() - old_desc9_pos_y

    local mercenary_tip_iconbg_1 = scrol_view:getChildByName("mercenary_tip_iconbg_1")
    mercenary_tip_iconbg_1:setPositionY(desc9:getPositionY() - mercenary_tip_iconbg_1:getContentSize().height/2)

    local desc8 = scrol_view:getChildByName("desc8")
    local desc8_height = self:getLines(desc8:getString(),18*3) * desc8:getVirtualRendererSize().height
    desc8:setContentSize({width = 461, height = desc8_height })
    desc8:setPositionY(desc9:getPositionY() + desc8_height + offsetY+10)

    local border8 = scrol_view:getChildByName("border9")
    local new_border8_pos_y = desc8:getPositionY()+(2+offsetY-10)
    border8:setPositionY(new_border8_pos_y)

    local title8 = scrol_view:getChildByName("title8")
    local new_title8_pos_y = border8:getPositionY()+(title8:getContentSize().height/2+5)
    title8:setPositionY(new_title8_pos_y)

    local desc7 = scrol_view:getChildByName("desc7")
    local desc7_height = self:getLines(desc7:getString(),18*3) * desc7:getVirtualRendererSize().height
    desc7:setContentSize({width = 461, height = desc7_height })
    desc7:setPositionY(title8:getPositionY() + desc7_height + offsetY+10)

    local border7 = scrol_view:getChildByName("border8")
    local new_border7_pos_y = desc7:getPositionY()+(2+offsetY-10)
    border7:setPositionY(new_border7_pos_y)

    local title7 = scrol_view:getChildByName("title7")
    local new_title7_pos_y = border7:getPositionY()+(title7:getContentSize().height/2+5)
    title7:setPositionY(new_title7_pos_y)

    local desc6 = scrol_view:getChildByName("desc6")
    local desc6_height = self:getLines(desc6:getString(),18*3) * desc6:getVirtualRendererSize().height
    desc6:setContentSize({width = 461, height = desc6_height })
    desc6:setPositionY(title7:getPositionY() + desc6_height + offsetY+10)

    local border6 = scrol_view:getChildByName("border6")
    local new_border6_pos_y = desc6:getPositionY()+(2+offsetY-10)
    border6:setPositionY(new_border6_pos_y)

    local title6 = scrol_view:getChildByName("title6")
    local new_title6_pos_y = border6:getPositionY()+(title6:getContentSize().height/2+5)
    title6:setPositionY(new_title6_pos_y)

    local desc5 = scrol_view:getChildByName("desc5")
    local desc5_height = self:getLines(desc5:getString(),18*3) * desc5:getVirtualRendererSize().height
    desc5:setContentSize({width = 461, height = desc5_height })
    desc5:setPositionY(title6:getPositionY() + desc5_height + offsetY+10)

    local border5 = scrol_view:getChildByName("border5")
    local new_border5_pos_y = desc5:getPositionY()+(2+offsetY-10)
    border5:setPositionY(new_border5_pos_y)

    local title5 = scrol_view:getChildByName("title5")
    local new_title5_pos_y = border5:getPositionY()+(title5:getContentSize().height/2+5)
    title5:setPositionY(new_title5_pos_y)

    local desc4 = scrol_view:getChildByName("desc4")
    local desc4_height = self:getLines(desc4:getString(),18*3) * desc4:getVirtualRendererSize().height
    desc4:setContentSize({width = 461, height = desc4_height })
    desc4:setPositionY(title5:getPositionY() + desc4_height + offsetY+10)

    local border4 = scrol_view:getChildByName("border4")
    local new_border4_pos_y = desc4:getPositionY()+(2+offsetY-10)
    border4:setPositionY(new_border4_pos_y)

    local title4 = scrol_view:getChildByName("title4")
    local new_title4_pos_y = border4:getPositionY()+(title4:getContentSize().height/2+5)
    title4:setPositionY(new_title4_pos_y)

    local mercenary_desc2 = scrol_view:getChildByName("mercenary_desc2")
    local old_mercenary_desc2_pos_y = mercenary_desc2:getPositionY()
    mercenary_desc2:setPositionY(title4:getPositionY() + title4:getContentSize().height+mercenary_desc2:getContentSize().height+offsetY)
    
    local mercenary_desc2_offset_y = mercenary_desc2:getPositionY() -old_mercenary_desc2_pos_y 

    local mercenary_desc3 = scrol_view:getChildByName("mercenary_desc3")
    mercenary_desc3:setPositionY(mercenary_desc3:getPositionY() + mercenary_desc2_offset_y)

    local mercenary_tip_iconbg = scrol_view:getChildByName("mercenary_tip_iconbg")
    mercenary_tip_iconbg:setPositionY(mercenary_tip_iconbg:getPositionY() + mercenary_desc2_offset_y)

    local mercenary_tip_iconbg_0 = scrol_view:getChildByName("mercenary_tip_iconbg_0")
    mercenary_tip_iconbg_0:setPositionY(mercenary_tip_iconbg_0:getPositionY() + mercenary_desc2_offset_y)
    
    local bp_buff = scrol_view:getChildByName("bp_buff")
    bp_buff:setPositionY(bp_buff:getPositionY() + mercenary_desc2_offset_y)

    local property1_buff = scrol_view:getChildByName("property1_buff")
    property1_buff:setPositionY(property1_buff:getPositionY() + mercenary_desc2_offset_y)

    local property2_buff = scrol_view:getChildByName("property2_buff")
    property2_buff:setPositionY(property2_buff:getPositionY() + mercenary_desc2_offset_y)

    local mercenary_bg1 = scrol_view:getChildByName("mercenary_bg1")
    mercenary_bg1:setPositionY(mercenary_bg1:getPositionY() + mercenary_desc2_offset_y)

    self.desc3 = scrol_view:getChildByName("desc3")
    local old_desc3_pos_y = self.desc3:getPositionY()
    local desc3_height = self:getLines(self.desc3:getString(),18*3) * self.desc3:getVirtualRendererSize().height
    self.desc3:setContentSize({width = 461, height = desc3_height })
    self.desc3:setPositionY(mercenary_bg1:getPositionY() + desc3_height+offsetY+10)
    
    local desc3_offset_y = self.desc3:getPositionY() - old_desc3_pos_y

    local bp_bg1 = scrol_view:getChildByName("bp_bg1")
    bp_bg1:setPositionY(bp_bg1:getPositionY() + desc3_offset_y)

    local bp_buff_0 = scrol_view:getChildByName("bp_buff_0")
    bp_buff_0:setPositionY(bp_buff_0:getPositionY() + desc3_offset_y)

    local bp_value = scrol_view:getChildByName("bp_value")
    bp_value:setPositionY(bp_value:getPositionY() + desc3_offset_y)


    local bp_bg2 = scrol_view:getChildByName("bp_bg2")
    bp_bg2:setPositionY(bp_bg2:getPositionY() + desc3_offset_y)

    self.desc2 = scrol_view:getChildByName("desc2")
    local desc2_height = self:getLines(self.desc2:getString(),18*3) * self.desc2:getVirtualRendererSize().height
    self.desc2:setContentSize({width = 461, height = desc2_height })
    local new_desc2_pos_y = bp_bg2:getPositionY()+(2+desc2_height +bp_bg2:getContentSize().height/2+offsetY+10)
    self.desc2:setPositionY(new_desc2_pos_y)

    local border3 = scrol_view:getChildByName("border3")
    local new_border3_pos_y = self.desc2:getPositionY()+(2+offsetY-10)
    border3:setPositionY(new_border3_pos_y)

    local title3 = scrol_view:getChildByName("title3")
    local new_title3_pos_y = border3:getPositionY()+(title3:getContentSize().height/2+5)
    title3:setPositionY(new_title3_pos_y)

    local mercenary_desc1 = scrol_view:getChildByName("mercenary_desc1")
    local mercenary_desc1_height = self:getLines(mercenary_desc1:getString(),18*3) * mercenary_desc1:getVirtualRendererSize().height
    mercenary_desc1:setContentSize({width = 461, height = mercenary_desc1_height })
    local new_mercenary_desc1_pos_y = title3:getPositionY()+(title3:getContentSize().height+mercenary_desc1_height+offsetY)
    mercenary_desc1:setPositionY(new_mercenary_desc1_pos_y)

    local border2 = scrol_view:getChildByName("border2")
    local new_border2_pos_y = mercenary_desc1:getPositionY()+(2+offsetY-10)
    border2:setPositionY(new_border2_pos_y)

    local title2 = scrol_view:getChildByName("title2")
    local new_title2_pos_y = border2:getPositionY()+(title2:getContentSize().height/2+5)
    title2:setPositionY(new_title2_pos_y)

    self.bp_desc = scrol_view:getChildByName("bp_desc")
    local bp_desc_height = self:getLines(self.bp_desc:getString(),18*3) * self.bp_desc:getVirtualRendererSize().height
    self.bp_desc:setContentSize({width = 461, height = bp_desc_height })
    local new_bp_desc_pos_y = title2:getPositionY()+(title2:getContentSize().height+bp_desc_height+offsetY+10)
    self.bp_desc:setPositionY(new_bp_desc_pos_y)    
        
    local border1 = scrol_view:getChildByName("border1")
    local new_border1_pos_y = self.bp_desc:getPositionY()+(2+offsetY-10)
    border1:setPositionY(new_border1_pos_y)

    local title1 = scrol_view:getChildByName("title1")
    local new_title1_pos_y = border1:getPositionY()+(title1:getContentSize().height/2+5)
    title1:setPositionY(new_title1_pos_y)

    local scorl_view_height = scrol_view:getContentSize().height+desc9:getPositionY()+desc9_height+ offsetY
    local inner = scrol_view:getInnerContainer()

    inner:setContentSize({width = scrol_view:getContentSize().width, height = new_title1_pos_y + 60})
end

function campaign_rule_msgbox:getLines(str,size)
   return math.ceil(string.len(str)/size) 
end

function campaign_rule_msgbox:Show()
    self.root_node:setVisible(true)

    local rule_info = campaign_logic.rule_info

    self.bp_value:setString(rule_info.defalut_battle_point)

    local desc2_str = self.desc2:getString()
    
    self.desc2:setString(string.format(desc2_str,rule_info.defalut_battle_point))

    if campaign_logic.title then
        local bp_desc_str = self.bp_desc:getString()
        self.bp_desc:setString(string.format(bp_desc_str,campaign_logic.title)) 
    end
    -- [1] =  mercenary_sort_type1--战力图标
    -- [2] =  mercenary_speed--速度图标
    -- [3] =  mercenary_property2--防御图标
    -- [4] =  mercenary_dodge--闪避图标
    -- [5] = mercenary_authority --王者图标
    local icon_descs = {
        [1] =  lang_constants:Get("mercenary_sort_type1"), --战力
        [2] =  lang_constants:Get("mercenary_speed"), --速度
        [3] =  lang_constants:Get("mercenary_property2"), --防御
        [4] =  lang_constants:Get("mercenary_dodge"), --闪避
        [5] =  lang_constants:Get("mercenary_authority"), --王者
    }
    local icon_desc_str = ""
    local idx = 1
    for i = 1, 5 do
        local evo = rule_info.evo_list[i]
        if evo ~= 0 then
            self.buff_icon[idx]:loadTexture(client_constants["CAMPAIGN_PROPERTY_ICON"][i],PLIST_TYPE)
            self.buff_value[idx]:setString(evo)
            icon_desc_str = icon_desc_str..evo.." "..icon_descs[i]..", "
            idx = idx + 1
            if idx > 3 then --只能显示3个
                break
            end
        end
    end

    icon_desc_str = string.sub(icon_desc_str,1,string.len(icon_desc_str)-2)

    local specail_desc_str = ""
    for k, v in pairs(campaign_logic.special_cond_list) do
        for i, vv in ipairs(v.and_list) do
            specail_desc_str = lang_constants:GetCampaignCond(vv.type,vv.value)
            self.mercenary_desc:setString(specail_desc_str)
            break
        end
    end

    if icon_desc_str ~= "" then
        local desc3_str = self.desc3:getString()
        self.desc3:setString(string.format(desc3_str,icon_desc_str,specail_desc_str))
    end

end

function campaign_rule_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), "campaign_rule_msgbox")
end

return campaign_rule_msgbox
