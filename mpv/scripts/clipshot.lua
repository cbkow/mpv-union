---Screenshot the video and copy it to the clipboard
---@author ObserverOfTime
---@license 0BSD

--[[
Copyright (c) 2019-2021 ObserverOfTime

Permission to use, copy, modify, and/or distribute this software
for any purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

]]

---@class ClipshotOptions
---@field name string
---@field type string
local o = {
    name = 'mpv-screenshot.jpeg',
    type = '' -- defaults to jpeg
}
require('mp.options').read_options(o, 'clipshot')

local file, cmd

local platform = mp.get_property_native('platform')
if platform == 'windows' then
    file = os.getenv('TEMP')..'\\'..o.name
    cmd = {
        'powershell', '-NoProfile', '-Command',
        'Add-Type -Assembly System.Windows.Forms, System.Drawing;',
        string.format(
            "[Windows.Forms.Clipboard]::SetImage([Drawing.Image]::FromFile('%s'))",
            file:gsub("'", "''")
        )
    }
elseif platform == 'darwin' then
    file = os.getenv('TMPDIR')..'/'..o.name
    -- png: «class PNGf»
    local type = o.type ~= '' and o.type or 'JPEG picture'
    cmd = {
        'osascript', '-e', string.format(
            'set the clipboard to (read (POSIX file %q) as %s)',
            file, type
        )
    }
else
    file = '/tmp/'..o.name
    if os.getenv('XDG_SESSION_TYPE') == 'wayland' then
        cmd = {'sh', '-c', ('wl-copy < %q'):format(file)}
    else
        local type = o.type ~= '' and o.type or 'image/jpeg'
        cmd = {'xclip', '-sel', 'c', '-t', type, '-i', file}
    end
end

---@param arg string
---@return fun()
local function clipshot(arg)
    return function()
        mp.commandv('screenshot-to-file', file, arg)
        mp.command_native_async({'run', unpack(cmd)}, function(suc, _, err)
            mp.osd_message(suc and 'Copied screenshot to clipboard' or err, 1)
        end)
    end
end

mp.add_key_binding('c',     'clipshot-subs',   clipshot('subtitles'))
mp.add_key_binding('C',     'clipshot-video',  clipshot('video'))
mp.add_key_binding('Alt+c', 'clipshot-window', clipshot('window'))
