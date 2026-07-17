local utils = require "mp.utils"

local orig = "/tmp/shadowing-original.wav"
local rec  = "/tmp/shadowing-recording.wav"
local mix  = "/tmp/shadowing-mix.wav"
local mic  = {"-f", "pulse", "-i", "default"}
local recording = false
local busy = false

local function osd(s) mp.osd_message("Shadowing: " .. s) end
local function exists(f) return utils.file_info(f) ~= nil end
local function cleanup()
    os.remove(orig) os.remove(rec) os.remove(mix) os.remove(rec .. ".n.wav")
end

local function run(args, cb)
    mp.command_native_async({name = "subprocess", playback_only = false,
        capture_stderr = true, args = args}, cb or function() end)
end

local function ffmpeg(args, cb)
    local a = {"ffmpeg", "-nostdin", "-loglevel", "error", "-y"}
    for _, v in ipairs(args) do a[#a + 1] = v end
    run(a, cb)
end

local function play(f, cb)
    run({"mpv", "--load-scripts=no", "--keep-open=no", "--no-resume-playback",
         "--volume=" .. (mp.get_property_number("volume") or 100),
         "--really-quiet", "--no-video", "--force-window=no", "--", f}, cb)
end

local function loudness(f, cb)
    run({"ffmpeg", "-nostdin", "-hide_banner", "-i", f, "-af", "ebur128", "-f", "null", "-"},
        function(_, res)
            local v
            for m in ((res and res.stderr) or ""):gmatch("I:%s*(%-?[%d%.]+) LUFS") do v = m end
            v = tonumber(v)
            cb(v and v > -60 and v or nil)
        end)
end

local function compare()
    if not (exists(orig) and exists(rec)) then return osd("Record first") end
    play(rec, function(_, res)
        if res and res.status ~= 0 then return end
        mp.add_timeout(0.3, function() play(orig) end)
    end)
end

local function overlay()
    if not (exists(orig) and exists(rec)) then return osd("Record first") end
    run({"pkill", "-f", "^mpv --load-scripts=no"})
    ffmpeg({"-i", orig, "-i", rec, "-filter_complex",
            "[1:a]volume=3dB[r];" ..
            "[0:a][r]amix=inputs=2:duration=longest", mix},
        function(_, res)
            if res and res.status == 0 then play(mix) else osd("Overlay failed") end
        end)
end

local function extract(a, b)
    ffmpeg({"-ss", tostring(a), "-to", tostring(b), "-i", mp.get_property("path"),
            "-vn", "-ac", "1", "-ar", "48000", orig},
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
    if recording then return run({"pkill", "-INT", "-f", rec}) end
    if busy then return end
    if not exists(orig) then return osd("Set A-B loop first") end
    mp.set_property_bool("pause", true)
    run({"pkill", "-f", "^mpv --load-scripts=no"})
    recording = true
    osd("● recording")
    local a = {}
    for _, v in ipairs(mic) do a[#a + 1] = v end
    for _, v in ipairs({"-ac", "1", "-ar", "48000", rec}) do a[#a + 1] = v end
    ffmpeg(a, function()
        recording = false
        if not exists(rec) then return osd("Recording failed, check mic") end
        busy = true
        loudness(rec, function(lr)
            if not lr then busy = false; return osd("Recording is silent, check mic") end
            loudness(orig, function(lo)
                if not lo then busy = false; osd("■ saved"); return compare() end
                ffmpeg({"-i", rec, "-af", ("volume=%.1fdB"):format(lo - lr),
                        "-ar", "48000", rec .. ".n.wav"},
                    function(_, res)
                        if res and res.status == 0 then
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
