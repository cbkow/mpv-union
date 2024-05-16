-- Uses the drawbox FFMPEG filter to apply title safety guides to video

--[[
Copyright (c) 2024 CBkow

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

-- 16x9

local broadcast16x9_filter_enabled = false
local broadcast16x9_filter_string = "lavfi=[drawbox=x=(iw-((iw*0.9)))/2:y=(ih-((ih*0.9)))/2:w=iw*.9:h=ih*.9:color=yellow@1, drawbox=x=(iw-((iw*0.93)))/2:y=(ih-((ih*0.93)))/2:w=iw*.93:h=ih*.93:color=red@1]"

local tiktok16x9_filter_enabled = false
local tiktok16x9_filter_string = "lavfi=[drawbox=x=iw*0.1041666666666667:y=(ih-((ih*1)))/2:w=iw*0.6770833333333333:h=ih*1:color=yellow@1]"

local twitter16x9_filter_enabled = false
local twitter_filter_string = "lavfi=[drawbox=x=iw*0.05:y=ih*0.2:w=iw*0.9:h=2:color=yellow@1, drawbox=x=iw*0.95:y=ih*.20:w=2:h=ih*0.42:color=yellow@1, drawbox=x=iw*0.70:y=ih*0.62:w=iw*0.25:h=2:color=yellow@1, drawbox=x=iw*0.70:y=ih*0.62:w=2:h=ih*0.38:color=yellow@1, drawbox=x=iw*0.28:y=ih*0.81:w=2:h=ih*0.19:color=yellow@1, drawbox=x=iw*0.05:y=ih*0.81:w=iw*0.23:h=2:color=yellow@1, drawbox=x=iw*0.05:y=ih*0.2:w=2:h=ih*0.61:color=yellow@1, drawbox=x=iw*0.28:y=ih*0.99999:w=iw*.42:h=2:color=yellow@1]"

local youtube16x9_filter_enabled = false
local youtube16x9_filter_string = "lavfi=[drawbox=x=iw*0.0197916666666667:y=ih*0.1694444444444444:w=iw*0.2385416666666667:h=2:color=yellow@1, drawbox=x=iw*0.2583333333333333:y=ih*0.0351851851851852:w=2:h=ih*0.1342592592592593:color=yellow@1, drawbox=x=iw*0.2583333333333333:y=ih*0.0351851851851852:w=iw*0.4942708333333333:h=2:color=yellow@1, drawbox=x=iw*0.7526041666666667:y=ih*0.0351851851851852:w=2:h=ih*0.087962962962963:color=yellow@1, drawbox=x=iw*0.7526041666666667:y=ih*0.1231481481481481:w=iw*0.1630208333333333:h=2:color=yellow@1, drawbox=x=iw*0.915625:y=ih*0.1231481481481481:w=2:h=ih*0.5185185185185185:color=yellow@1, drawbox=x=iw*0.0197916666666667:y=ih*0.6416666666666667:w=iw*0.8958333333333333:h=2:color=yellow@1, drawbox=x=iw*0.0197916666666667:y=ih*0.1694444444444444:w=2:h=ih*0.4722222222222222:color=yellow@1]"

function toggleyoutube16x9()
    youtube16x9_filter_enabled = not youtube16x9_filter_enabled
    if youtube16x9_filter_enabled then
        mp.set_property("vf", youtube16x9_filter_string)
    else
        mp.set_property("vf", "")
    end
end
mp.add_key_binding("", "toggleyoutube16x9", toggleyoutube16x9)

function togglebroadcast16x9()
    broadcast16x9_filter_enabled = not broadcast16x9_filter_enabled
    if broadcast16x9_filter_enabled then
        mp.set_property("vf", broadcast16x9_filter_string)
    else
        mp.set_property("vf", "")
    end
end
mp.add_key_binding("", "togglebroadcast16x9", togglebroadcast16x9)

function toggletiktok16x9()
    tiktok16x9_filter_enabled = not tiktok16x9_filter_enabled
    if tiktok16x9_filter_enabled then
        mp.set_property("vf", tiktok16x9_filter_string)
    else
        mp.set_property("vf", "")
    end
end
mp.add_key_binding("", "toggletiktok16x9", toggletiktok16x9)

function toggletwitter16x9() 
    twitter16x9_filter_enabled = not twitter16x9_filter_enabled
    if twitter16x9_filter_enabled then
        mp.set_property("vf", twitter_filter_string)
    else
        mp.set_property("vf", "")
    end
end
mp.add_key_binding("", "toggletwitter16x9", toggletwitter16x9)

-- 9x16

local metareels9x16_enabled = false
local metareels9x16_filter_string = "lavfi=[drawbox=x=(iw-((iw*0.88)))/2:y=ih*0.14:w=iw*0.88:h=4:color=yellow@1, drawbox=x=(iw-((iw*0.88)))/2:y=ih*0.14:w=4:h=ih*0.51:color=yellow@1, drawbox=x=(iw-((iw*0.88)))/2:y=ih*0.65:w=iw*0.73:h=4:color=yellow@1, drawbox=x=iw*0.79:y=ih*0.6:w=4:h=ih*0.05:color=yellow@1, drawbox=x=iw*0.94:y=ih*0.14:w=4:h=ih*0.46:color=yellow@1, drawbox=x=iw*0.79:y=ih*0.6:w=4:h=ih*0.05:color=yellow@1, drawbox=x=iw*0.79:y=ih*0.60:w=iw*0.15:h=4:color=yellow@1]"

local metapharmareels9x16_enabled = false
local metapharmareels9x16_filter_string = "lavfi=[drawbox=x=(iw-((iw*0.880555555555555)))/2:y=ih*0.140625:w=iw*0.880555555555555:h=ih*0.459375:color=yellow@1]"

local metastories9x16_enabled = false
local metastories9x16_filter_string = "lavfi=[drawbox=x=(iw-((iw*1)))/2:y=ih*0.14:w=iw*1:h=ih*.66:color=yellow@1]"

local metafeed9x16_enabled = false
local metafeed9x16_filter_string = "lavfi=[drawbox=x=(iw-((iw*1)))/2:y=ih*0.1486979166666667:w=iw*1:h=ih*0.703125:color=yellow@1]"

local snapchat9x16_enabled = false
local snapchat9x16_filter_string = "lavfi=[drawbox=x=(iw-((iw*1)))/2:y=ih*0.078125:w=iw*1:h=ih*0.84375:color=yellow@1]"

local tiktok9x16_enabled = false
local tiktok9x16_filter_string = "lavfi=[drawbox=x=iw*0.11111111111:y=ih*0.13125:w=iw*0.777777778:h=4:color=yellow@1, drawbox=x=iw*0.11111111111:y=ih*0.13125:w=4:h=ih*0.5020833333333333:color=yellow@1, drawbox=x=iw*0.11111111111:y=ih*0.6333333333333333:w=iw*0.6666666666666667:h=4:color=yellow@1, drawbox=x=iw*0.7777777777777778:y=ih*0.1875:w=iw*0.1111111111111111:h=4:color=yellow@1, drawbox=x=iw*0.7777777777777778:y=ih*0.1875:w=4:h=ih*0.4458333333333333:color=yellow@1, drawbox=x=iw*0.8888888888888889:y=ih*0.13125:w=4:h=ih*0.05625:color=yellow@1]"

local youtube9x16_enabled = false
local youtube9x16_filter_string = "lavfi=[drawbox=x=iw*0.0444444444444444:y=ih*0.15:w=iw*0.77777777777777781:h=ih*0.5:color=yellow@1]"

function toggleyoutube9x16()
    youtube9x16_enabled = not youtube9x16_enabled
    if youtube9x16_enabled then
        mp.set_property("vf", youtube9x16_filter_string)
    else
        mp.set_property("vf", "")
    end
end
mp.add_key_binding("", "toggleyoutube9x16", toggleyoutube9x16)

function toggletiktok9x16()
    tiktok9x16_enabled = not tiktok9x16_enabled
    if tiktok9x16_enabled then
        mp.set_property("vf", tiktok9x16_filter_string)
    else
        mp.set_property("vf", "")
    end
end
mp.add_key_binding("", "toggletiktok9x16", toggletiktok9x16)

function togglemetareels9x16()
    metareels9x16_enabled = not metareels9x16_enabled
    if metareels9x16_enabled then
        mp.set_property("vf", metareels9x16_filter_string)
    else
        mp.set_property("vf", "")
    end
end
mp.add_key_binding("", "togglemetareels9x16", togglemetareels9x16)

function togglemetapharmareels9x16()
    metapharmareels9x16_enabled = not metapharmareels9x16_enabled
    if metapharmareels9x16_enabled then
        mp.set_property("vf", metapharmareels9x16_filter_string)
    else
        mp.set_property("vf", "")
    end
end
mp.add_key_binding("", "togglemetapharmareels9x16", togglemetapharmareels9x16)

function togglemetastories9x16()
    metastories9x16_enabled = not metastories9x16_enabled
    if metastories9x16_enabled then
        mp.set_property("vf", metastories9x16_filter_string)
    else
        mp.set_property("vf", "")
    end
end
mp.add_key_binding("", "togglemetastories9x16", togglemetastories9x16)

function togglemetafeed9x16()
    metafeed9x16_enabled = not metafeed9x16_enabled
    if metafeed9x16_enabled then
        mp.set_property("vf", metafeed9x16_filter_string)
    else
        mp.set_property("vf", "")
    end
end
mp.add_key_binding("", "togglemetafeed9x16", togglemetafeed9x16)

function togglesnapchat9x16()
    snapchat9x16_enabled = not filter_snapchat9x16_enabledenabled
    if snapchat9x16_enabled then
        mp.set_property("vf", snapchat9x16_filter_string)
    else
        mp.set_property("vf", "")
    end
end
mp.add_key_binding("", "togglesnapchat9x16", togglesnapchat9x16)

-- 1x1

local tiktok1x1_enabled = false
local tiktok1x1_filter_string = "lavfi=[drawbox=x=iw*0.09375:y=1:w=iw*0.6875:h=ih*0.768757:color=yellow@1]"

local twitter1x1_enabled = false
local twitter1x1_filter_string = "lavfi=[drawbox=x=1:y=ih*0.13:w=iw*1:h=2:color=yellow@1, drawbox=x=1:y=ih*0.89:w=iw*0.28:h=2:color=yellow@1, drawbox=x=iw*0.28:y=ih*0.89:w=2:h=ih*0.11:color=yellow@1, drawbox=x=iw*0.70:y=ih*0.79:w=iw*0.30:h=2:color=yellow@1, drawbox=x=iw*0.70:y=ih*0.79:w=2:h=ih*0.21:color=yellow@1]"

function toggletiktok1x1()
    tiktok1x1_enabled = not tiktok1x1_enabled
    if tiktok1x1_enabled then
        mp.set_property("vf", tiktok1x1_filter_string)
    else
        mp.set_property("vf", "")
    end
end
mp.add_key_binding("", "toggletiktok1x1", toggletiktok1x1)

function toggletwitter1x1()
    twitter1x1_enabled = not twitter1x1_enabled
    if twitter1x1_enabled then
        mp.set_property("vf", twitter1x1_filter_string)
    else
        mp.set_property("vf", "")
    end
end
mp.add_key_binding("", "toggletwitter1x1", toggletwitter1x1)



