local awful = require("awful")
local gears_surface = require("gears.surface")
local util = require("lxcommon.util")

local M = {}

-- Normalize stream and player names into a comparable key so applications,
-- browser instances, and playerctl identities can be matched heuristically.
local function normalize_name(s)
    s = (s or ""):lower()

    -- common cleanup
    s = s:gsub("%s*%-+%s*playback$", "")
    s = s:gsub("vlc media player", "vlc")
    s = s:gsub("google chrome", "chrome")
    s = s:gsub("chromium browser", "chromium")
    s = s:gsub("mozilla firefox", "firefox")

    -- strip instance suffixes like chromium.instance1234
    s = s:gsub("%..*$", "")

    -- remove punctuation/spaces
    s = s:gsub("[^%w]", "")

    return s
end

-- Generate candidate lookup keys for mapping a playback stream to an MPRIS
-- player. This is heuristic by design.
local function candidate_names_for_stream(stream)
    local candidates = {}

    local function add(v)
        v = normalize_name(v)
        if v and v ~= "" then
            candidates[v] = true
        end
    end

    add(stream.app_name)
    add(stream.label)
    add(stream.media_name)

    -- browser aliases
    local app = normalize_name(stream.app_name or "")
    local label = normalize_name(stream.label or "")

    if app:find("chrome", 1, true) or label:find("chrome", 1, true) then
        add("chrome")
        add("chromium")
    end

    if app:find("chromium", 1, true) or label:find("chromium", 1, true) then
        add("chromium")
        add("chrome")
    end

    if app:find("firefox", 1, true) or label:find("firefox", 1, true) then
        add("firefox")
    end

    if app:find("mpv", 1, true) or label:find("mpv", 1, true) then
        add("mpv")
    end

    if app:find("vlc", 1, true) or label:find("vlc", 1, true) then
        add("vlc")
    end

    if app:find("spotify", 1, true) or label:find("spotify", 1, true) then
        add("spotify")
    end

    return candidates
end

local art_cache = {}
local art_surface_cache = {}
local ART_CACHE_TTL = 10  -- seconds

-- Cache artwork URLs briefly to avoid repeated playerctl calls during rapid UI
-- rebuilds.
function M.get_player_art_url(player)
    local now = os.time()

    local entry = art_cache[player]
    if entry and (now - entry.timestamp) < ART_CACHE_TTL then
        return entry.url
    end

    local out = util.read_command("playerctl -p " .. util.shell_escape(player) .. " metadata mpris:artUrl 2>/dev/null")

    if out and out ~= "" then
        art_cache[player] = {
            url = out,
            timestamp = now,
        }
        return out
    end

    return nil
end

-- Only `file://` artwork can be loaded into a local Awesome surface.
function M.get_player_art_surface(player)
    local now = os.time()

    local entry = art_surface_cache[player]
    if entry and (now - entry.timestamp) < ART_CACHE_TTL then
        return entry.surface
    end

    local url = M.get_player_art_url(player)
    if not url then
        return nil
    end

    local path = url:match("^file://(.+)$")
    if not path then
        return nil
    end

    local ok, surface = pcall(gears_surface.load_silently, path)
    if not ok or not surface then
        return nil
    end

    art_surface_cache[player] = {
        surface = surface,
        timestamp = now,
    }

    return surface
end

function M.list_players()
    if not util.command_exists("playerctl") then
        return {}
    end

    local players = {}
    for _, line in ipairs(util.split_lines(util.read_command("playerctl -l 2>/dev/null"))) do
        if line ~= "" then
            players[#players + 1] = line
        end
    end

    return players
end

-- Read the small metadata subset used by the popup UI.
function M.get_player_info(player)
    local fmt = "{{playerName}}\t{{status}}\t{{artist}}\t{{title}}"
    local cmd = "playerctl -p " .. util.shell_escape(player) ..
        " metadata --format " .. util.shell_escape(fmt) .. " 2>/dev/null"
    local out = util.read_command(cmd)

    local info = {
        player = player,
        status = nil,
        artist = nil,
        title = nil,
    }

    if not out or out == "" then
        local status = util.read_command("playerctl -p " .. util.shell_escape(player) .. " status 2>/dev/null")
        info.status = status
        return info
    end

    local a, b, c, d = out:match("([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)")
    info.player = (a and a ~= "") and a or player
    info.status = (b and b ~= "") and b or nil
    info.artist = (c and c ~= "") and c or nil
    info.title = (d and d ~= "") and d or nil

    return info
end

-- Best-effort mapping from a playback stream to an MPRIS player name.
function M.player_for_stream(stream)
    return M.player_for_stream_from_players(stream, M.list_players())
end

function M.player_for_stream_from_players(stream, players)
    players = players or {}
    local candidates = candidate_names_for_stream(stream)

    -- exact candidate match first
    for _, player in ipairs(players) do
        local player_key = normalize_name(player)
        if candidates[player_key] then
            return player
        end
    end

    -- substring fallback
    for _, player in ipairs(players) do
        local player_key = normalize_name(player)
        for candidate, _ in pairs(candidates) do
            if candidate ~= "" and player_key ~= "" and (
                candidate:find(player_key, 1, true) or
                player_key:find(candidate, 1, true)
            ) then
                return player
            end
        end
    end

    return nil
end

local function collect_player_info(player, callback)
    local fmt = "{{playerName}}\t{{status}}\t{{artist}}\t{{title}}"
    local metadata_cmd = "playerctl -p " .. util.shell_escape(player) ..
        " metadata --format " .. util.shell_escape(fmt) .. " 2>/dev/null"
    local art_cmd = "playerctl -p " .. util.shell_escape(player) .. " metadata mpris:artUrl 2>/dev/null"

    awful.spawn.easy_async_with_shell(metadata_cmd, function(metadata_stdout)
        awful.spawn.easy_async_with_shell(art_cmd, function(art_stdout)
            local info = {
                player = player,
                status = nil,
                artist = nil,
                title = nil,
                art_url = util.trim(art_stdout or ""),
            }

            local out = util.trim(metadata_stdout or "")
            local a, b, c, d = out:match("([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)")
            if a then
                info.player = (a ~= "") and a or player
                info.status = (b and b ~= "") and b or nil
                info.artist = (c and c ~= "") and c or nil
                info.title = (d and d ~= "") and d or nil
            end

            if info.art_url == "" then
                info.art_url = nil
            else
                art_cache[player] = {
                    url = info.art_url,
                    timestamp = os.time(),
                }
            end

            callback(info)
        end)
    end)
end

function M.collect_stream_player_data_async(streams, callback)
    streams = streams or {}

    awful.spawn.easy_async_with_shell("playerctl -l 2>/dev/null", function(stdout)
        local players = {}
        for _, line in ipairs(util.split_lines(stdout or "")) do
            if line ~= "" then
                players[#players + 1] = line
            end
        end

        local matched = {}
        for _, stream in ipairs(streams) do
            stream._async_player_info = true
            local player = M.player_for_stream_from_players(stream, players)
            if player then
                stream._matched_player = player
                matched[player] = true
            end
        end

        local player_count = 0
        for _ in pairs(matched) do
            player_count = player_count + 1
        end

        if player_count == 0 then
            callback(streams)
            return
        end

        local player_info = {}
        local remaining = player_count
        for player in pairs(matched) do
            collect_player_info(player, function(info)
                player_info[player] = info
                remaining = remaining - 1

                if remaining > 0 then
                    return
                end

                for _, stream in ipairs(streams) do
                    local info_for_stream = stream._matched_player and player_info[stream._matched_player] or nil
                    if info_for_stream then
                        stream._player_info = info_for_stream
                        stream._art_url = info_for_stream.art_url
                        stream._async_player_info = true
                    end
                end

                callback(streams)
            end)
        end
    end)
end

function M.play_pause(player)
    awful.spawn("playerctl -p " .. util.shell_escape(player) .. " play-pause", false)
end

function M.next(player)
    awful.spawn("playerctl -p " .. util.shell_escape(player) .. " next", false)
end

function M.previous(player)
    awful.spawn("playerctl -p " .. util.shell_escape(player) .. " previous", false)
end

return M
