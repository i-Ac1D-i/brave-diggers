local network = require "util.network"
local graphic = require "logic.graphic"
local platform_manager = require "logic.platform_manager"
local json = require "util.json"
local config_manager = require "logic.config_manager"
local http_client = require "logic.http_client"
local bit_extension = require "util.bit_extension"
local constants = require "util.constants"
local carnival_logic = require "logic.carnival"

local SNS_EVENT_TYPE = constants.SNS_EVENT_TYPE
local ACHIEVEMENT_TYPE = constants.ACHIEVEMENT_TYPE
local BLOCK_TYPE = constants.BLOCK_TYPE

local achievement_config = config_manager.achievement_config

local achievement_logic
local daily_logic
local ladder_logic
local user_logic
local user_login 
local FB_LIKE_URL =
{
    ["r2games"] = "https://www.facebook.com/bravediggers",
}

local ACTION_TYPE = 
{
    [SNS_EVENT_TYPE["share_mercenary"]] = "brave_diggers:get",
    [SNS_EVENT_TYPE["share_ladder"]] = "brave_diggers:obtain",
    [SNS_EVENT_TYPE["share_mining"]] = "brave_diggers:defeat",
    [SNS_EVENT_TYPE["share_achievement"]] = "brave_diggers:reach",
}

local OBJECT_TYPE = 
{
    [SNS_EVENT_TYPE["share_mercenary"]] = "pixel_hero",
    [SNS_EVENT_TYPE["share_ladder"]] = "match",
    [SNS_EVENT_TYPE["share_mining"]] = "boss",
    [SNS_EVENT_TYPE["share_achievement"]] = "achievement",
}

local R2_OPEN_GRAPH_TOKEN = 
{
    ["mercenary_22000001"] = "115666808838579", --魔化吕布
    ["mercenary_19000022"] = "1730147883908218", --神关羽
    ["mercenary_19000023"] = "1744138465798018", --魔化信长
    ["mercenary_19000026"] = "1100267023372602", --神张飞
    ["mercenary_19000027"] = "596015680555335", --亚瑟·戴恩
    ["mercenary_19000031"] = "498424377015229", --纳兹古王
    ["mercenary_19000032"] = "469987259878255", --蜀王刘备
    ["mercenary_19000034"] = "1160678407284899", --普京
    ["mercenary_19000038"] = "1696327527303245", --梦魇狂三
    ["mercenary_19000040"] = "219484401764141", --草泥马
    ["mercenary_19000041"] = "154883924912834", --曹操
    ["mercenary_19000043"] = "2040151676209134", --骑士王
    ["mercenary_19000044"] = "1588519104792224", --两仪shiki
    ["mercenary_19000046"] = "1075597849180083", --死鱼眼兵长
    ["mercenary_19000048"] = "827027817401170", --猴子
    ["mercenary_19000052"] = "231540497209178", --夫子
    ["mercenary_19000053"] = "1683226835263644", --老子
    ["mercenary_19000056"] = "269713393372042", --丰臣秀吉
    ["mercenary_19000059"] = "715310351905146", --电磁炮少女
    ["mercenary_19000060"] = "234434243585346", --朱雀
    ["mercenary_19000068"] = "589854694517000", --庞麦郎
    ["mercenary_19000076"] = "268958873443549", --船首图腾
    ["mercenary_19000077"] = "221696344874174", --暴走音乐家
    ["mercenary_19000080"] = "214615198919508", --漂浮者
    ["mercenary_19000088"] = "228946097473589", --玉兔
    ["mercenary_19000090"] = "937364659695470", --垃垃
    ["mercenary_19000093"] = "581612858667921", --草帽小子
    ["mercenary_19000094"] = "224802091243898", --皮神
    ["mercenary_19000095"] = "468389190025217", --小苍
    ["mercenary_19000097"] = "596054397239953", --小北
    ["mercenary_19000098"] = "1265101356851771", --皇家私掠者
    ["mercenary_19000101"] = "1594188460898174", --大明李提督
    ["mercenary_19000102"] = "1708749952701285", --火拳
    ["mercenary_19000103"] = "268565506820418", --蛇姬
    ["mercenary_22000002"] = "1738341026377790", --贝尔菲高尔
    ["mercenary_22000003"] = "1715569745395236", --哈迪斯
    ["mercenary_22000004"] = "1323719244312121", --金身泰坦
    ["mercenary_25000004"] = "264121860594989", --真.圣诞老人
    ["mercenary_25000005"] = "575373785969241", --小雪球
    ["mercenary_25000006"] = "1545118555785056", --真.圣诞驯鹿
    ["mercenary_55000004"] = "1717944198458594", --时尚侠
    ["mercenary_19000108"] = "1730104227274102", --小鞭炮
    ["mercenary_19000110"] = "1158654350835853", --龙牧
    ["mercenary_19000111"] = "1090225614351859", --WCG
    ["mercenary_19000114"] = "1714211652186694", --小黑
    ["mercenary_19000115"] = "1703448283253772", --冰女
    ["mercenary_19000116"] = "1555285744772029", --半人马
    ["mercenary_24000013"] = "1735066536769569", --猴年年兽
    ["mercenary_19000119"] = "616221025195533", --真·生化魔王

    ["mining_" .. BLOCK_TYPE["red_king"]] = "1140384415992888",--赤之王
    ["mining_" .. BLOCK_TYPE["green_king"]] = "893502674109757",--碧之王
    ["mining_" .. BLOCK_TYPE["light_king"]] = "1080432315337100",--光之王
    ["mining_" .. BLOCK_TYPE["dark_king"]] = "1599589843694539",--影之王
    ["mining_" .. BLOCK_TYPE["ether_hunting_group"]] = "232076347156639",--真以太狩猎团
    ["mining_" .. BLOCK_TYPE["golem_dark"]] = "232933520400294",--黑色魔铁巨像
    ["mining_" .. BLOCK_TYPE["earth_angel"]] = "1115911191802123",--大地天使
    ["mining_" .. BLOCK_TYPE["time_emissary"]] = "379438695560186",--时间使者
    ["mining_" .. BLOCK_TYPE["doom_lord"]] = "1799989403555990",--末日之主
    ["mining_" .. BLOCK_TYPE["fountain_god"]] = "479268375601878",--烬之泉神
    ["mining_" .. BLOCK_TYPE["seven_doom"]] = "1615076265481673",--森文督姆

    ["achievement_" .. ACHIEVEMENT_TYPE["arena_win1"]] = "776713365763612", --在竞技场获得过1胜奖励超过X次
    ["achievement_" .. ACHIEVEMENT_TYPE["strength_pt"]] = "499049820268527", --需要积累挖矿点数X
    ["achievement_" .. ACHIEVEMENT_TYPE["arena_win4"]] = "782454481856057", --在竞技场获得过4胜奖励超过X次
    ["achievement_" .. ACHIEVEMENT_TYPE["send_gift"]] = "1694102504184331", --需要送礼X次
    ["achievement_" .. ACHIEVEMENT_TYPE["forge_pt"]] = "1777133105850535", --需要积累锻造点数X
    ["achievement_" .. ACHIEVEMENT_TYPE["destiny"]] = "848213198616911", --需要积累宿命点数X
    ["achievement_" .. ACHIEVEMENT_TYPE["max_bp"]] = "1154775061240263", --总战力达到X
    ["achievement_" .. ACHIEVEMENT_TYPE["mining_boss_kill"]] = "1789193554647000", --在矿区中弄死bossX次
    ["achievement_" .. ACHIEVEMENT_TYPE["soul_chip"]] = "546170465562214", --到手过的荣誉碎片达到X
    ["achievement_" .. ACHIEVEMENT_TYPE["recruit"]] = "1341421935884940", --招募佣兵当小弟X次
    ["achievement_" .. ACHIEVEMENT_TYPE["wakeup"]] = "947205858730574", --觉醒X次
    ["achievement_" .. ACHIEVEMENT_TYPE["maze"]] = "231765847199094", --解决关卡X（简单）
    ["achievement_" .. ACHIEVEMENT_TYPE["arena_win"]] = "215263282191394", --在竞技场扑倒对手X次
    ["achievement_" .. ACHIEVEMENT_TYPE["friendship_pt"]] = "1093126860731245", --获得过的友情点数超过X
    ["achievement_" .. ACHIEVEMENT_TYPE["library"]] = "997908860298586", --图鉴点亮个数超过X

    ["ladder_100"] = "247943652225171", --天梯前100
    ["ladder_50"] = "1701097500134998", --天梯前50
    ["ladder_20"] = "835811253191916", --天梯前20
    ["ladder_10"] = "1633133660345061", --天梯前10
    ["ladder_9"] = "863728730420703", --天梯前9
    ["ladder_8"] = "1324778354203058", --天梯前8
    ["ladder_7"] = "1698797063712828", --天梯前7
    ["ladder_6"] = "1068484979884784", --天梯前6
    ["ladder_5"] = "168501156878605", --天梯前5
    ["ladder_4"] = "945976225515386", --天梯前4
    ["ladder_3"] = "236432523389858", --天梯前3
    ["ladder_2"] = "567745723393341", --天梯前2
    ["ladder_1"] = "864214013724698", --天梯前1
}

local sns = {}
function sns:Init(user_id)
    daily_logic = require "logic.daily"
    achievement_logic = require "logic.achievement"
    ladder_logic = require "logic.ladder"
    user_logic = require "logic.user"
    user_login = require("logic.login")
    self.channel = platform_manager:GetChannelInfo()

    self.has_sns_share = self.channel.has_sns_share

    self.app_link_url = self.channel.app_link_url

    self.game_request_title = self.channel.game_request_title

    self.game_request_message = self.channel.game_request_message

    self.sns_platform = self.channel.sns_platform

    self.user_id =  user_id
    self.cur_mining_boss_type = nil

    self.has_game_bind_fb = false
    self.has_share_game = false

    self:RegisterEvent()
end

function sns:UpdateSNSInfo(event_type, param1)
    if event_type == SNS_EVENT_TYPE["share_mining"] then
        local bit_index = constants.SNS_SHARE_MINING[param1]
        if bit_index then
            self.cur_mining_boss_type = param1
            self.mining_share_state = bit_extension:SetBitNum(self.mining_share_state, bit_index, true)
        end
    end
end

function sns:CanShare(event_type, param1)
    if not self.has_sns_share then
        return false
    end

    if event_type >= SNS_EVENT_TYPE["share_mercenary"] and event_type <= SNS_EVENT_TYPE["share_mining"] and not self.channel.enable_sns_og_share then
        return false
    end

    if event_type == SNS_EVENT_TYPE["share_link"] then
        if daily_logic:GetDailyTag(constants.DAILY_TAG["share_event1"]) then
            return false
        end
        if not self.has_share_game then
            return false
        end

        graphic:DispatchEvent("remind_sns_reward")

    elseif event_type == SNS_EVENT_TYPE["share_mercenary"] then
        if self.mercenary_share_state[param1] == 1 then
            return false
        end

        if not R2_OPEN_GRAPH_TOKEN["mercenary_" .. param1] then
            return false
        end

    elseif event_type == SNS_EVENT_TYPE["share_ladder"] then
        local cur_rank = ladder_logic:GetCurRank()
        local bit_index 
        for k, v in pairs(constants.SNS_SHARE_LADDER) do
            if cur_rank <= v and cur_rank > 0 and bit_extension:GetBitNum(self.ladder_share_state, k-1) == 0 then
                bit_index = k - 1
                break
            end
        end

        if not bit_index then
            return false
        end

    elseif event_type == SNS_EVENT_TYPE["share_achievement"] then
        if not R2_OPEN_GRAPH_TOKEN["achievement_" .. param1] then
            return false
        end

        if self.achievement_share_state[param1] == 1 or achievement_logic:GetCurStep(param1) ~= #achievement_config[param1] then
            return false
        end

    elseif event_type == SNS_EVENT_TYPE["share_mining"] then
        local bit_index = constants.SNS_SHARE_MINING[param1]
        if not bit_index or bit_extension:GetBitNum(self.mining_share_state, bit_index) == 0 then
            return false
        end
    end

    return true
end

function sns:CanShareMining()
    if not self.cur_mining_boss_type then
        return false
    end

    return self:CanShare(SNS_EVENT_TYPE["share_mining"], self.cur_mining_boss_type)
end

function sns:CanShareLadder()
    return self:CanShare(SNS_EVENT_TYPE["share_ladder"], 0)
end

function sns:ShareMining()
    if not self.cur_mining_boss_type then
        return false
    end
    self:Share(SNS_EVENT_TYPE["share_mining"], self.cur_mining_boss_type)
end

function sns:ShareLadder()
    self:Share(SNS_EVENT_TYPE["share_ladder"], 10)
end

function sns:ShareLink(sns_platform)
    PlatformSDK.shareLinkContent(json:encode({event_type = SNS_EVENT_TYPE["share_link"], sns_platform = sns_platform, app_link_url = self.app_link_url}))
end

function sns:IsPublishActionGranted()
    return PlatformSDK:isPublishActPermissionGrant()
end

function sns:Share(event_type, param1)
    if not self:CanShare(event_type, param1) then
        graphic:DispatchEvent("show_prompt_panel", "")
        return
    end

    local action_type, object_type = ACTION_TYPE[event_type], OBJECT_TYPE[event_type]

    local object_id
    if event_type == SNS_EVENT_TYPE["share_mercenary"] then
        object_id = R2_OPEN_GRAPH_TOKEN["mercenary_" .. param1]

    elseif event_type == SNS_EVENT_TYPE["share_ladder"] then
        local cur_rank = ladder_logic:GetCurRank()
        for k, v in pairs(constants.SNS_SHARE_LADDER) do
            if cur_rank <= v and bit_extension:GetBitNum(self.ladder_share_state, k-1) == 0 then
                object_id = R2_OPEN_GRAPH_TOKEN["ladder_" .. v]
                break
            end
        end

    elseif event_type == SNS_EVENT_TYPE["share_mining"] then
        object_id = R2_OPEN_GRAPH_TOKEN["mining_" .. param1]

    elseif event_type == SNS_EVENT_TYPE["share_achievement"] then
        object_id = R2_OPEN_GRAPH_TOKEN["achievement_" .. param1]
    end

    if not object_id then
        return
    end

    -- open graph分享需要检查分享权限
    if not PlatformSDK.isPublishActPermissionGrant() then 
        PlatformSDK.loginFromViewWithPermissions(json:encode({ event_type = event_type, param1 = param1, action_type = action_type, object_type = object_type, object_id = object_id}))
        return
    end

    PlatformSDK.shareOpenGraphStory(json:encode({ event_type = event_type, param1 = param1, action_type = action_type, object_type = object_type, object_id = object_id}))
end

function sns:CanTakeBindReward()
    if not user_logic:GetPermanentMark(constants.PERMANENT_MARK["bind_third_account"]) and self.has_game_bind_fb then
        graphic:DispatchEvent("remind_sns_reward")
        return true
    end

    return false
end

function sns:AlreadyTakeBindReward()
    if user_logic:GetPermanentMark(constants.PERMANENT_MARK["bind_third_account"]) then
        return true
    end

    return false
end

function sns:AlreadyTakeShareReward()
    if daily_logic:GetDailyTag(constants.DAILY_TAG["share_event1"]) then
        return true
    end

    return false
end

function sns:HaveRewardsToTake()
    if not user_logic:GetPermanentMark(constants.PERMANENT_MARK["bind_third_account"]) and self.has_game_bind_fb then
        return true
    elseif not daily_logic:GetDailyTag(constants.DAILY_TAG["share_event1"]) and self.has_share_game then
        return true
    end
    
    return false
end


function sns:TakeBindReward()
    if not self:CanTakeBindReward() then
        return
    end

    network:Send({ take_sns_event_reward = { event_type = SNS_EVENT_TYPE["bind_account"], param1 = 0 }})
end

function sns:TakeShareLinkReward()
    if not self:CanShare(SNS_EVENT_TYPE["share_link"]) then 
        return
    end

    network:Send({ take_sns_event_reward = { event_type = SNS_EVENT_TYPE["share_link"], param1 = 0 }})
end

function sns:SendGameRequest()
    PlatformSDK.sendGameRequest(json:encode({ user_id = self.user_id,
        sns_platform = self.sns_platform,
        title = self.game_request_title,
        message = self.game_request_message}))
end
--FYD 获取所有的邀请过我的人并传递到服务器
function sns:GetAllGameRequests()
    local channel_info = platform_manager:GetChannelInfo()
    if channel_info.meta_channel == "txwy" then
        local utils =  require("util/utils") 
 
        utils:getNetIP(function(ip) 
               local uid = user_logic:GetUserId()
               local url = string.format(channel_info.get_invite_list_url,ip,uid) 
               utils:sendXMLHTTPrequrestByGet(url,function(msg)  
                      msg = '{ "value" : '..msg..'}'  --将返回的JSON数组包装成一个JSON对象，否则JSONManager无法解析。。。
                     local msg_table =  JSONManager:decodeJSON(msg) 
                     local invite_ls = ""
                     for k,v in pairs(msg_table.value) do 
                         invite_ls = invite_ls .. v.id 
                         if k ~= #msg_table.value then
                            invite_ls = invite_ls.."|"
                         end
                     end
                     local platform = platform_manager:GetChannelInfo().meta_channel
                      --FYD TODO --content.inviter_list, content.sns_uid, content.sns_platform   platform "txwy"  openid  txwy平台id
                     platform_manager:DispatchEvent("sns_query_game_request_result",0,{inviter_list = invite_ls,sns_platform = channel_info.meta_channel,sns_uid = user_login.openid})  
               end)  
            end)
    else
        if not PlatformSDK.hasFBLoggedIn()  then
            if self.channel.third_party_account then
                --state == 0 是登陆状态
                PlatformSDK.bindThirdPartyAccount(self.channel.third_party_account, 0)
                return
            end
        end
        PlatformSDK.getAllGameRequests(json:encode({sns_platform = self.sns_platform}))
    end

    
end
--FYD 11
function sns:ShowFBLikeBtn(pos)
    if not PlatformSDK.showFBLikeBtn then
        return false
    end

    return PlatformSDK.showFBLikeBtn(pos)
end

function sns:RemoveFBLikeBtn()
    if PlatformSDK.removeFBLikeBtn() then
        return false
    end

    return PlatformSDK.removeFBLikeBtn()
end

function sns:FBLike()
    PlatformSDK.fbLike(FB_LIKE_URL[self.channel.meta_channel])
end

function sns:RegisterEvent()

    platform_manager:RegisterEvent("sns_login_result", function(status)
        print("sns_login_result ",status)
        if status == 0 then
            if self.channel.need_refresh_setting_bind then
                graphic:DispatchEvent("update_setting_bind_state")
            end
            PlatformSDK.getAllGameRequests(json:encode({sns_platform = self.sns_platform}))
        end
    end)

    platform_manager:RegisterEvent("sns_permiss_result", function(status, json_data)
        print("sns_permiss_result",status)
        if status == 0 then
            PlatformSDK.shareOpenGraphStory(json_data)
        end
    end)
    --FYD  查询回调事件
    platform_manager:RegisterEvent("sns_query_game_request_result", function(status, content)
        self.sns_platform = content.sns_platform
        carnival_logic:QueryInviteeProgress(content.inviter_list, content.sns_uid, content.sns_platform)
    end)

    platform_manager:RegisterEvent("sns_share_result", function(status, json_data)
        if status == 0 then
            local content = json:decode(json_data)

            if self.channel.meta_channel == "r2games" and content.event_type == SNS_EVENT_TYPE["share_link"] then
                self.has_share_game = true
                graphic:DispatchEvent("update_share_sub_panel")
                graphic:DispatchEvent("remind_sns_reward")
                return
            end
          
            if content.event_type then
                --content中包含event_type才需要领取分享奖励
                print("sns_share_result",status,content.event_type,content.param1)
                network:Send({ take_sns_event_reward = { event_type = content.event_type, param1 = content.param1 or 0}})
            end

            graphic:DispatchEvent("update_sns_panel")
        else

        end
    end)

    network:RegisterEvent("query_sns_info_ret", function(recv_msg)
        self.mining_share_state = recv_msg.mining_share_state  
        self.ladder_share_state = recv_msg.ladder_share_state       
        self.achievement_share_state = recv_msg.achievement_share_state       

        self.mercenary_share_state = {}
        if recv_msg.mercenary_id_list then
            for i, template_id in ipairs(recv_msg.mercenary_id_list) do
                self.mercenary_share_state[template_id] = recv_msg.mercenary_share_state[i]
            end
        end

        self.bind_reward_info = recv_msg.bind_reward_info
        self.share_link_reward_info = recv_msg.share_link_reward_info
    end)

    network:RegisterEvent("take_sns_event_reward_ret", function(recv_msg)
        print("take_sns_event_reward_ret",json:encode(recv_msg))
        if recv_msg.result == "success" then
            local event_type = recv_msg.event_type
            if event_type == SNS_EVENT_TYPE["share_link"] then
                daily_logic:SetDailyTag(constants.DAILY_TAG["share_event1"], true)

            elseif event_type == SNS_EVENT_TYPE["share_mercenary"] then
                self.mercenary_share_state[recv_msg.param1] = 1
                graphic:DispatchEvent("hide_new_mercenary_fb_node")

            elseif event_type == SNS_EVENT_TYPE["share_ladder"] then
                self.ladder_share_state = bit_extension:SetBitNum(self.ladder_share_state, recv_msg.param1, true)
                graphic:DispatchEvent("hide_battle_panel_fb_node")

            elseif event_type == SNS_EVENT_TYPE["share_achievement"] then
                self.achievement_share_state[recv_msg.param1] = 1
                graphic:DispatchEvent("hide_achieve_panel_fb_node",param1)

            elseif event_type == SNS_EVENT_TYPE["share_mining"] then
                self.cur_mining_boss_type = nil
                self.mining_share_state = bit_extension:SetBitNum(self.mining_share_state, recv_msg.param1, false)
                graphic:DispatchEvent("hide_battle_panel_fb_node")

            elseif event_type == SNS_EVENT_TYPE["bind_account"] then
                user_logic:SetPermanentMark(constants.PERMANENT_MARK["bind_third_account"], true)
            end

            --FB不接受利诱玩家分享
            if self.channel.facebook_share_not_get_reward then
                if event_type ~= SNS_EVENT_TYPE["share_link"] and
                    event_type ~= SNS_EVENT_TYPE["share_mercenary"] and
                    event_type ~= SNS_EVENT_TYPE["share_ladder"] and
                    event_type ~= SNS_EVENT_TYPE["share_achievement"] and
                    event_type ~= SNS_EVENT_TYPE["share_mining"] then
                    graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
                end
            else
                graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
            end
            
            graphic:DispatchEvent("update_sns_panel")
        else

        end
    end)
end

return sns
