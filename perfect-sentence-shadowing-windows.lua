local utils = require "mp.utils"

local FF  = "ffmpeg"
local MPV = mp.command_native({"expand-path", "~~exe_dir/mpv.exe"})
local RATE = 48000
local tmp  = os.getenv("TEMP") or "/tmp"
local orig = tmp .. "/shadowing-original.wav"
local rec  = tmp .. "/shadowing-recording.wav"
local mix  = tmp .. "/shadowing-mix.wav"
local mic  = nil
local recorder = nil
local rec_t0 = 0
local rec_dur = 0
local finishing = false
local busy = false
local players = {}

local function osd(s) mp.osd_message("Shadowing: " .. s) end
local function exists(f) return utils.file_info(f) ~= nil end
local function cleanup()
    os.remove(orig) os.remove(rec) os.remove(mix) os.remove(rec .. ".n.wav")
end

local function run(args, cb)
    return mp.command_native_async({name = "subprocess", playback_only = false,
        capture_stderr = true, args = args}, cb or function() end)
end

local function ffmpeg(args, cb)
    local a = {FF, "-nostdin", "-loglevel", "error", "-y"}
    for _, v in ipairs(args) do a[#a + 1] = v end
    return run(a, cb)
end

local function play(f, cb)
    local t
    t = run({MPV, "--load-scripts=no", "--keep-open=no", "--no-resume-playback",
         "--volume=" .. (mp.get_property_number("volume") or 100),
         "--really-quiet", "--no-video", "--force-window=no", "--", f},
        function(_, res)
            players[t] = nil
            if res and (res.killed_by_us or res.status ~= 0) then return end
            if cb then cb() end
        end)
    players[t] = true
end

local function stop_players()
    for t in pairs(players) do mp.abort_async_command(t) end
end

local function parse_dshow(out)
    local name, take_alt
    for line in out:gmatch("[^\r\n]+") do
        if take_alt then
            return line:match('Alternative name%s+"([^"]+)"') or name
        end
        name = line:match('"([^"]+)"%s+%(audio%)')
        take_alt = name ~= nil
    end
    return name
end

local function detect_mic(then_)
    osd("Detecting microphone")
    run({FF, "-hide_banner", "-list_devices", "true", "-f", "dshow", "-i", "dummy"},
        function(_, res)
            local dev = parse_dshow(res and res.stderr or "")
            if not dev then return osd("No microphone found") end
            mic = {"-f", "dshow", "-audio_buffer_size", "50", "-i", "audio=" .. dev}
            then_()
        end)
end

local function loudness(f, cb)
    run({FF, "-nostdin", "-hide_banner", "-i", f, "-af", "ebur128", "-f", "null", "-"},
        function(_, res)
            local v
            for m in ((res and res.stderr) or ""):gmatch("I:%s*(%-?[%d%.]+) LUFS") do v = m end
            v = tonumber(v)
            cb(v and v > -60 and v or nil)
        end)
end

local function compare()
    if not (exists(orig) and exists(rec)) then return osd("Record first") end
    play(rec, function() mp.add_timeout(0.2, function() play(orig) end) end)
end

local function overlay()
    if not (exists(orig) and exists(rec)) then return osd("Record first") end
    stop_players()
    ffmpeg({"-i", orig, "-i", rec, "-filter_complex",
            "[1:a]volume=3dB[r];" ..
            "[0:a][r]amix=inputs=2:duration=longest", mix},
        function(_, res)
            if res and res.status == 0 then play(mix) else osd("Overlay failed") end
        end)
end

local function extract(a, b)
    ffmpeg({"-ss", tostring(a), "-to", tostring(b), "-i", mp.get_property("path"),
            "-vn", "-ac", "1", "-ar", tostring(RATE), orig},
        function(_, res)
            if res and res.status == 0 then
                os.remove(rec)
                os.remove(mix)
                osd("Sentence extracted")
            else
                osd("Extract failed")
            end
        end)
end

local function record()
    if recorder then
        if finishing then return end
        finishing = true
        rec_dur = mp.get_time() - rec_t0
        local r = recorder
        local need = rec_dur * RATE * 2 + 100
        local waited = 0
        osd("Finishing")
        local t
        t = mp.add_periodic_timer(0.1, function()
            local i = utils.file_info(rec)
            waited = waited + 0.1
            if (i and i.size >= need) or waited > 5 then
                t:kill()
                mp.abort_async_command(r)
            end
        end)
        return
    end
    if busy then return end
    if not exists(orig) then return osd("Set A-B loop first") end
    if not mic then return detect_mic(record) end
    mp.set_property_bool("pause", true)
    stop_players()
    rec_t0 = mp.get_time()
    osd("● recording")
    local a = {}
    for _, v in ipairs(mic) do a[#a + 1] = v end
    for _, v in ipairs({"-ac", "1", "-ar", tostring(RATE), "-flush_packets", "1", rec}) do a[#a + 1] = v end
    recorder = ffmpeg(a, function()
        recorder = nil
        finishing = false
        if not exists(rec) then return osd("Recording failed, check mic") end
        busy = true
        loudness(rec, function(lr)
            if not lr then busy = false; return osd("Recording is silent, check mic") end
            loudness(orig, function(lo)
                if not lo then busy = false; osd("■ saved"); return compare() end
                ffmpeg({"-i", rec, "-t", ("%.2f"):format(rec_dur),
                        "-af", ("volume=%.1fdB"):format(lo - lr),
                        "-ar", tostring(RATE), rec .. ".n.wav"},
                    function(_, res)
                        if res and res.status == 0 then
                            os.remove(rec)
                            os.rename(rec .. ".n.wav", rec)
                        end
                        busy = false
                        osd("■ saved")
                        compare()
                    end)
            end)
        end)
    end)
end

local function original()
    if exists(orig) then play(orig) else osd("Set A-B loop first") end
end

local function mine()
    if exists(rec) then play(rec) else osd("Record first") end
end

local function next()
    mp.set_property("ab-loop-a", "no")
    mp.set_property("ab-loop-b", "no")
    mp.set_property_bool("pause", false)
end

mp.observe_property("ab-loop-b", "number", function(_, b)
    local a = mp.get_property_number("ab-loop-a")
    if a and b and b > a then
        extract(a, b)
    elseif b == nil then
        cleanup()
    end
end)

mp.add_key_binding("Alt+r", "shadow-record", record)
mp.add_key_binding("Alt+o", "shadow-original", original)
mp.add_key_binding("Alt+m", "shadow-mine", mine)
mp.add_key_binding("Alt+c", "shadow-compare", compare)
mp.add_key_binding("Alt+b", "shadow-overlay", overlay)
mp.add_key_binding("Alt+n", "shadow-next", next)
