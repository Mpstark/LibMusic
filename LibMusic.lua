--------------
-- LIBMUSIC --
--------------
local MAJOR, MINOR = "LibMusic-1.0", 1;
LibMusic = LibStub:NewLibrary(MAJOR, MINOR);

if (not LibMusic) then
    return;
end

local LibEasing = LibStub("LibEasing-1.0");
LibMusic.callbacks = LibMusic.callbacks or LibStub("CallbackHandler-1.0"):New(LibMusic, "RegisterEvent", "UnregisterEvent", "UnregisterAllEvents");


-------------------
-- LOCAL HELPERS --
-------------------
local function getVolume()
    return tonumber(GetCVar("Sound_MusicVolume"));
end

local function setVolume(volume)
    SetCVar("Sound_MusicVolume", volume);
end

local function disableMusic()
    SetCVar("Sound_EnableMusic", 0);
end

local function enableMusic()
    SetCVar("Sound_EnableMusic", 1);
end

local function isLooping()
    return GetCVar("Sound_ZoneMusicNoDelay") == "1";
end

local function isEnabled()
    return GetCVar("Sound_EnableMusic") == "1";
end


-----------
-- STATE --
-----------
local registry = {};
local tagsRegistry = {};

local playingHandle;
local playingHandleStartTime;

local playingQueue = {};
local function queueSong(handle)
    table.insert(playingQueue, handle);

    print("LibMusic: SONG_QUEUED");
    LibMusic.callbacks:Fire("SONG_QUEUED", handle);
end

local function queueHasSongs()
    return #playingQueue > 0;
end

local function popQueue()
    local next = table.remove(playingQueue, 1);

    if (not queueHasSongs()) then
        print("LibMusic: QUEUE_EMPTY");
        LibMusic.callbacks:Fire("QUEUE_EMPTY");
    end

    return next;
end

local function emptyQueue()
    if (queueHasSongs()) then
        playingQueue = {};
        print("LibMusic: QUEUE_EMPTY");
        LibMusic.callbacks:Fire("QUEUE_EMPTY");
    end
end

local playingTimer;
local function destroyPlayingTimer()
    if (playingTimer) then
        playingTimer:Cancel();
        playingTimer = nil;
    end
end

local startSong;
local endSong;
local songTimeout;

songTimeout = function()
    endSong(true);
end

endSong = function(timeout)
    if (playingHandle) then
        print("LibMusic: SONG_ENDED.");
        LibMusic.callbacks:Fire("SONG_ENDED", playingHandle);
    end

    if (playingHandle and timeout) then
        if (queueHasSongs()) then
            -- play next song in queue
            PlayMusic(popQueue());
            return;
        elseif (isLooping()) then
            -- will call this function again, but that's fine
            -- since it won't be a timeout, it'll fall through
            StopMusic();
            return;
        end
    end

    -- didn't timeout or nothing in queue and not looping
    playingHandle = nil;
    playingHandleStartTime = nil;
    emptyQueue();
    destroyPlayingTimer();
end

startSong = function(handle)
    handle = string.lower(handle);

    if (registry[handle] and registry[handle].length) then
        playingHandle = handle;
        playingHandleStartTime = GetTime();

        destroyPlayingTimer();
        playingTimer = C_Timer.NewTimer(registry[handle].length, songTimeout);

        print("LibMusic: SONG_STARTED", playingHandle, registry[handle].length);
        LibMusic.callbacks:Fire("SONG_STARTED", playingHandle, registry[handle].length);
    end
end


-----------------------
-- REGISTERING MUSIC --
-----------------------
function LibMusic:Register(handle, length, title, composer, tags)
    if not (handle and length and type(length) == 'number' and not registry[handle]) then
        return;
    end

    handle = string.lower(handle);

    -- meta information
    registry[handle] = {};
    registry[handle].length = length;
    registry[handle].title = title;
    registry[handle].composer = composer;

    -- tags
    registry[handle].tags = {};
    if (tags and type(tags) == 'table') then
        for tag, value in pairs(tags) do
            registry[handle].tags[tag] = value;

            tagsRegistry[tag] = tagsRegistry[tag] or {};
            tagsRegistry[tag][handle] = true;
        end
    end

    print("LibMusic: SONG_REGISTERED.", handle, length);
    LibMusic.callbacks:Fire("SONG_REGISTERED", handle, length);
end

function LibMusic:AddTag(handle, tag, value)
    handle = string.lower(handle);

    if (not registry[handle]) then
        return;
    end

    if (not value) then
        value = true;
    end

    registry[handle].tags[tag] = value;

    tagsRegistry[tag] = tagsRegistry[tag] or {};
    tagsRegistry[tag][handle] = true;
end


-----------------------
-- CVAR MANIPULATION --
-----------------------
function LibMusic:IsEnabled()
    return isEnabled();
end

function LibMusic:IsLooping()
    return isLooping();
end

function LibMusic:EnableMusic()
    enableMusic();
end

function LibMusic:DisableMusic()
    disableMusic();
end

function LibMusic:EnableLooping()
    SetCVar("Sound_ZoneMusicNoDelay", 1);
end

function LibMusic:DisableLooping()
    SetCVar("Sound_ZoneMusicNoDelay", 0);
end

function LibMusic:SetVolume(volume)
    if not (volume and type(volume) == 'number' and volume <= 100) then
        return;
    end

    if (volume > 1) then
        volume = volume / 100;
    end

    setVolume(volume);
end

function LibMusic:GetVolume()
    return getVolume();
end


-------------------
-- PLAYING MUSIC --
-------------------
function LibMusic:StartAndPlay(handle)
    self:EnableMusic();
    PlayMusic(handle);
end

function LibMusic:AddToQueue(handle, ...)
    if (not handle) then
        return;
    end

    -- TODO: what happens when we queue a song after a song that has no length is playing?
    if (not playingHandle) then
        PlayMusic(handle);
    else
        queueSong(handle);
    end

    -- queue up additional songs if provided
    if (...) then
        for i, extraHandle in ipairs(...) do
            queueSong(extraHandle);
        end
    end
end

function LibMusic:SkipToNext(crossfade)
    if (queueHasSongs()) then
        self:CrossfadeTo(popQueue(), crossfade or 4);
    else
        StopMusic();
    end
end

function LibMusic:ClearQueue()
    emptyQueue();
end


------------
-- EASING --
------------
local easing;
local easingEndTime;
function LibMusic:EaseVolume(newVolume, time, easingFunc, callback)
    if (not LibEasing) then
        setVolume(newVolume);
        return;
    end

    if (easing) then
        LibEasing:StopEasing(easing);
    end

    local oldVolume = getVolume();
    if (newVolume == oldVolume) then
        return;
    end

    if (not easingFunc) then
        if (newVolume > oldVolume) then
            -- getting louder
            easingFunc = LibEasing.InSine;
        else
            -- getting softer
            easingFunc = LibEasing.OutSine;
        end
    end

    easing = LibEasing:Ease(setVolume, oldVolume, newVolume, time, easingFunc, callback);
    easingEndTime = GetTime() + time;

    print("LibMusic: VOLUME_CHANGED", newVolume);
    LibMusic.callbacks:Fire("VOLUME_CHANGED", newVolume);
end

function LibMusic:FadeMusicOut(time, easingFunc)
    time = time or 2.5;

    local oldVolume = getVolume();
    local function disableAndResetVolume()
        disableMusic();
        setVolume(oldVolume)
    end

    self:EaseVolume(0, time, easingFunc, disableAndResetVolume);
end

function LibMusic:FadeMusicIn(handle, time, newVolume, easingFunc)
    newVolume = newVolume or 1;
    time = time or 2.5;

    setVolume(0);
    enableMusic();

    if (handle) then
        PlayMusic(handle);
    end

    self:EaseVolume(newVolume, time, easingFunc);
end

function LibMusic:CrossfadeTo(handle, time)
    if (not handle) then
        return;
    end

    time = time or 1;

    local oldVolume = getVolume();
    local function fadeInNextSong()
        PlayMusic(handle);
        self:EaseVolume(oldVolume, 3*time/4);
    end

    self:EaseVolume(0, time/4, nil, fadeInNextSong);
end


-----------------
-- INFORMATION --
-----------------
function LibMusic:GetPlayingSong()
    if (playingHandle) then
        return playingHandle;
    else
        if (isEnabled()) then
            return "zone";
        end
    end
end

-- returns progress, length, startTime, endTime
function LibMusic:GetSongProgress()
    if (playingHandle and registry[playingHandle] and registry[playingHandle].length) then
        local endTime = playingHandleStartTime + registry[playingHandle].length;
        local progress = GetTime() - playingHandleStartTime;

        return progress, registry[playingHandle].length, playingHandleStartTime, endTime;
    end
end

-- returns the actual queue, changes made there will affect the actual queue
-- TODO: is this desirable?
function LibMusic:GetQueue()
    return playingQueue;
end

-- returns length, title, composer, tags
function LibMusic:GetSongInfo(handle)
    handle = string.lower(handle);
    if (registry[handle]) then
        return registry[handle].length, registry[handle].title, registry[handle].composer, registry[handle].tags;
    end
end

function LibMusic:GetAllSongs()
    local handles;

    for handle, _ in pairs(registry) do
        handles = handles or {};
        table.insert(handles, handle);
    end

    return handles;
end

function LibMusic:GetSongsByTag(tag, tagValue)
    local handles;

    if (tagsRegistry[tag]) then
        for handle, _ in pairs(tagsRegistry[tag]) do
            handles = handles or {};

            -- if provided tagValue, check if the tagValue matches
            if (tagValue and registry[handle].tags[tag] == tagValue) then
                table.insert(handles, handle);
            else
                table.insert(handles, handle);
            end
        end
    end

    return handles;
end


-------------
-- HOOKING --
-------------
local function _StopMusic()
    endSong();
end

local function _PlayMusic(handle)
    if (not isEnabled()) then
        print("LibMusic: PlayMusic failed, music not enabled");
        return;
    end

    startSong(handle);
end

local function _SetCVar(cvar, value)
    if (cvar == "Sound_EnableMusic") then
        if (tostring(value) == "0") then
            endSong();

            print("LibMusic: MUSIC_DISABLED");
            LibMusic.callbacks:Fire("MUSIC_DISABLED");
        elseif (tostring(value) == "1") then
            print("LibMusic: MUSIC_ENABLED");
            LibMusic.callbacks:Fire("MUSIC_ENABLED");
        end
    elseif (cvar == "Sound_MusicVolume") then
        if not (easingEndTime and easingEndTime >= GetTime()) then
            print("LibMusic: VOLUME_CHANGED", tonumber(value));
            LibMusic.callbacks:Fire("VOLUME_CHANGED", tonumber(value));
        end
    elseif (cvar == "Sound_ZoneMusicNoDelay") then
        if (tostring(value) == "1") then
            print("LibMusic: LOOPING_ENABLED");
            LibMusic.callbacks:Fire("LOOPING_ENABLED");
        elseif (tostring(value) == "0") then
            print("LibMusic: LOOPING_DISABLED");
            LibMusic.callbacks:Fire("LOOPING_DISABLED");
        end
    end
end

hooksecurefunc("PlayMusic", _PlayMusic);
hooksecurefunc("StopMusic", _StopMusic);
hooksecurefunc("SetCVar", _SetCVar);
