local AudioManager = AudioManager

local EFFECT =
{
    ["click"] = "res/sound/se_click.ogg",
    ["dig_block"] = "res/sound/se_dig.ogg",
    ["collect_mine"] = "res/sound/se_collect_mine.ogg",
    ["equip"] = "res/sound/se_equip.ogg",
    ["forge_success"] = "res/sound/se_forge_success.ogg",
    ["forge_failure"] = "res/sound/se_forge_failure.ogg",
    ["wakeup"]      = "res/sound/se_awake.ogg",
    ["unlock_maze"]  = "res/sound/se_new_feature.ogg",
    ["levelup"] = "res/sound/se_levelup.ogg",
    ["checkin"] = "res/sound/se_checkin.ogg",
    ["pray_normal"] = "res/sound/se_pray1.ogg",
    ["pray_better"] = "res/sound/se_pray2.ogg",
    ["alchemy_normal"] = "res/sound/se_alchemy1.ogg",
    ["alchemy_better"] = "res/sound/se_alchemy3.ogg",
    ["contract_success"] = "res/sound/se_contract.ogg",
    ["guild_build_success"] = "res/sound/se_build.ogg",
    ["guild_notice"] = "res/sound/se_notice.ogg",
    ["campaign_exchange_success"] = "res/sound/se_prize.ogg",
    ["soul_stone_success"] = "res/sound/se_craft.ogg",
    ["battle_win"] = "res/sound/win_sword.ogg",
    ["battle_lose"] = "res/sound/lose_shield.ogg",
}

local MUSIC =
{
    ["arena_battle"] = "res/sound/battle.ogg",
    ["mining_battle"] = "res/sound/mining_battle.mp3",
    ["maze_battle"] = "res/sound/battle.ogg",

    ["battle_win"] = "res/sound/se_win.ogg",
    ["battle_lose"] = "res/sound/se_lose.ogg",
}

local audio_manager = {}
function audio_manager:PlayMusic(music_type, loop)
    if loop == nil then
        loop = false
    end

    if self.cur_music == music_type then
        return
    end

    if self.cur_music then
        AudioManager.stopMusic(MUSIC[self.cur_music] or ("res/sound/" .. self.cur_music .. ".ogg"))
    end

    self.cur_music = music_type 
    AudioManager.playMusic(MUSIC[music_type] or ("res/sound/" .. music_type .. ".ogg"), loop)
end

function audio_manager:PlayEffect(effect_type, loop)
    if loop == nil then
        loop = false
    end

    local effect = EFFECT[effect_type] or ("res/sound/" .. effect_type .. ".ogg")
    AudioManager.playEffect(effect, loop)
end

function audio_manager:StopMusic(music_type)
    if MUSIC[music_type] then
        self.cur_music = nil
        AudioManager.stopMusic(MUSIC[music_type])
    end
end

function audio_manager:StopEffect(effect_type)
    AudioManager.stopEffect(EFFECT[effect_type])
end

function audio_manager:SetMusicMute(mute)
    AudioManager.setMusicMute(mute)
end

function audio_manager:SetEffectMute(mute)
    AudioManager.setEffectMute(mute)
end

function audio_manager:GetCurrentMusic()
    return self.cur_music
end

function audio_manager:StopCurrentMusic()
    if self.cur_music then
        AudioManager.stopMusic(MUSIC[self.cur_music] or ("res/sound/" .. self.cur_music .. ".ogg"))
        self.cur_music = nil
    end
end

do
    AudioManager.setMusicVolume(0.7)
end


return audio_manager




