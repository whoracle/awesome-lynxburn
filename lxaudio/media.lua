local awful = require("awful")
local gears_surface = require("gears.surface")
local util = require("lxaudio.util")

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
    local players = M.list_players()
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
