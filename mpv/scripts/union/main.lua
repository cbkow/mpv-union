-- mpv oscf modern
-- by maoiscat
-- github.com/maoiscat/
require 'expansion'
local assdraw = require 'mp.assdraw'


-- user options
opts = {
	scale = 1,              -- osc render scale
	fixedHeight = false,    -- true to allow osc scale with window
	hideTimeout = 0.5,        -- seconds untile osc hides, negative means never
	fadeDuration = 0.5,     -- seconds during fade out, negative means never
	}

-- logo and message works out of box
addToIdleLayout('logo')


-- define styles
local styles = {
	background = {
		color = {'0', '0', '0', '0'},
		alpha = {255, 255, 0, 0},
		border = 140,
		blur = 140,
		},
	tooltip = {
		color = {'FFFFFF', 'FFFFFF', '0', '0'},
		border = 0.5,
		blur = 1,
		fontsize = 18,
		wrap = 2,
		},
	button1 = {
		color1 = {'FFFFFF', 'FFFFFF', 'FFFFFF', 'FFFFFF'},
		color2 = {'999999', '999999', '999999', '999999'},
		fontsize = 36,
		border = 0,
		blur = 0,
		font = 'material-design-iconic-font',
		wrap = 2,
		},
	button2 = {
		color1 = {'FFFFFF', 'FFFFFF', 'FFFFFF', 'FFFFFF'},
		color2 = {'999999', '999999', '999999', '999999'},
		border = 0,
		blur = 0,
		fontsize = 24,
		font = 'material-design-iconic-font',
		wrap = 2,
		},
	button3 = {
		color1 = {'FFFFFF', 'FFFFFF', 'FFFFFF', 'FFFFFF'},
		color2 = {'999999', '999999', '999999', '999999'},
		border = 0,
		blur = 0,
		fontsize = 42,
		font = 'material-design-iconic-font',
		wrap = 2,
		},
	seekbarFg = {
		color1 = {'ffffff', 'ffffff', '0', '0'},
		color2 = {'999999', '999999', '0', '0'},
		border = 0.5,
		blur = 1,
		},
	seekbarBg = {
		color = {'5a5a5a', '5a5a5a', '0', '0'},
		border = 0,
		blur = 0,
		},
	volumeSlider = {
		color = {'ffffff', '0', '0', '0'},
		border = 0,
		blur = 0,
		},
	time = {
		color1 = {'ffffff', 'ffffff', '0', '0'},
		color2 = {'eeeeee', 'eeeeee', '0', '0'},
		border = 0,
		blur = 0,
		fontsize = 17,
		},
	title = {
		color = {'ffffff', '0', '0', '0'},
		border = 0.5,
		blur = 1,
		fontsize = 48,
		wrap = 2,
		},
	winControl = {
		color1 = {'ffffff', 'ffffff', '0', '0'},
		color2 = {'eeeeee', 'eeeeee', '0', '0'},
		border = 0.5,
		blur = 1,
		font = 'mpv-osd-symbols',
		fontsize = 20,
		},
	}


-- enviroment updater
-- this element updates shared vairables, sets active areas and starts event generators
local env
env = newElement('env')
env.layer = 1000
env.visible = false
env.updateTime = function()
	dispatchEvent('time')
end
env.init = function(self)
		self.slowTimer = mp.add_periodic_timer(0.08, self.updateTime)  --use a slower timer to update playtime
		-- event generators
		mp.observe_property('track-list/count', 'native', 
			function(name, val)
				if val==0 then return end
				player.tracks = getTrackList()
				player.playlist = getPlaylist()
				player.chapters = getChapterList()
				player.playlistPos = getPlaylistPos()
				player.duration = mp.get_property_number('duration')
				showOsc()
				dispatchEvent('file-loaded')
			end)
		mp.observe_property('pause', 'bool',
			function(name, val)
				player.paused = val
				dispatchEvent('pause')
			end)
		mp.observe_property('fullscreen', 'bool',
			function(name, val)
				player.fullscreen = val
				dispatchEvent('fullscreen')
			end)
		mp.observe_property('window-maximized', 'bool',
			function(name, val)
				player.maximized = val
				dispatchEvent('window-maximized')
			end)
		mp.observe_property('current-tracks/audio/id', 'number',
			function(name, val)
				if val then player.audioTrack = val
					else player.audioTrack = 0
						end
				dispatchEvent('audio-changed')
			end)
		mp.observe_property('current-tracks/sub/id', 'number',
			function(name, val)
				if val then player.subTrack = val
					else player.subTrack = 0
						end
				dispatchEvent('sub-changed')
			end)
		mp.observe_property('mute', 'bool',
			function(name, val)
				player.muted = val
				dispatchEvent('mute')
			end)
		mp.observe_property('volume', 'number',
			function(name, val)
				player.volume = val
				dispatchEvent('volume')
			end)
	end
env.tick = function(self)
		player.percentPos = mp.get_property_number('percent-pos')
		player.timePos = mp.get_property_number('time-pos')
		player.timeRem = mp.get_property_number('time-remaining')
		player.frame = mp.get_property_osd("estimated-frame-number")
		return ''
	end
env.responder['resize'] = function(self)
		player.geo.refX = player.geo.width / 2
		player.geo.refY = player.geo.height - 40
		setPlayActiveArea('bg1', 0, player.geo.height - 120, player.geo.width, player.geo.height)
		if player.fullscreen then
			setPlayActiveArea('wc1', player.geo.width - 200, 0, player.geo.width, 48)
		else
			setPlayActiveArea('wc1', -1, -1, -1, -1)
		end
		return false
	end
env.responder['pause'] = function(self)
		if player.idle then return end
		if player.paused then
			setVisibility('normal')
		else
			setVisibility('normal')
		end
	end
env.responder['idle'] = function(self)
		if player.idle then
			setVisibility('normal')
		else
			setVisibility('normal')
		end
		return false
	end
env:init()
addToPlayLayout('env')


-- background
local ne
ne = newElement('background', 'box')
ne.geo.h = 1
ne.geo.an = 8
ne.layer = 5
-- DO NOT directly assign a shared style tabe!!
ne.style = clone(styles.background)
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.refX
		self.geo.y = player.geo.height
		self.geo.w = player.geo.width
		self.setPos(self)
		self.render(self)
		return false
	end
ne:init()
addToPlayLayout('background')


-- a shared tooltip
ne = newElement('tip', 'tooltip')
ne.layer = 20
ne.style = clone(styles.tooltip)
ne:init()
addToPlayLayout('tip')
local tooltip = ne


-- playpause button
ne = newElement('btnPlay', 'button')
ne.layer = 10
ne.style = clone(styles.button1)
ne.geo.w = 45
ne.geo.h = 45
ne.geo.an = 5
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.refX
		self.geo.y = player.geo.refY
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('cycle', 'pause')
			return true
		end
		return false
	end
ne.responder['pause'] = function(self)
		if player.paused then
			self.text = '\xEF\x8E\xAA'
		else
			self.text = '\xEF\x8E\xA7'
		end
		self:render()
		return false
	end
ne:init()
addToPlayLayout('btnPlay')


-- back frame button
ne = newElement('btnFrameBack', 'button')
ne.layer = 10
ne.style = clone(styles.button2)
ne.geo.w = 30
ne.geo.h = 24
ne.geo.an = 5
ne.text = '\u{f3c3}'
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.refX - 60
		self.geo.y = player.geo.refY
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('frame-back-step')
			return true
		end
		return false
	end
ne:init()
addToPlayLayout('btnFrameBack')


-- forward frame button
ne = newElement('btnFrameForward', 'button')
ne.layer = 10
ne.style = clone(styles.button2)
ne.geo.w = 30
ne.geo.h = 24
ne.geo.an = 5
ne.text = '\u{f3c5}'
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.refX + 60
		self.geo.y = player.geo.refY
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('frame-step')
			return true
		end
		return false
	end
ne:init()
addToPlayLayout('btnFrameForward')


-- skip back button
ne = newElement('btnBack', 'button')
ne.layer = 10
ne.style = clone(styles.button2)
ne.geo.w = 30
ne.geo.h = 24
ne.geo.an = 5
ne.text = '\xEF\x8E\xA0'
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.refX - 120
		self.geo.y = player.geo.refY
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('seek', -1, 'relative', 'keyframes')
			return true
		end
		return false
	end
ne:init()
addToPlayLayout('btnBack')


-- skip forward button
ne = newElement('btnForward', 'btnBack')
ne.text = '\xEF\x8E\x9F'
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('seek', 1, 'relative', 'keyframes')
			return true
		end
		return false
	end
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.refX + 120
		self.geo.y = player.geo.refY
		self:setPos()
		self:setHitBox()
		return false
	end
ne:init()
addToPlayLayout('btnForward')


-- go to beginning
ne = newElement('btnBegin', 'button')
ne.layer = 10
ne.style = clone(styles.button2)
ne.geo.w = 30
ne.geo.h = 24
ne.geo.an = 5
ne.text = '\xEF\x8E\xB5'
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('seek', 0, 'absolute-percent', 'keyframes')
			return true
		end
		return false
	end
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.refX - 180
		self.geo.y = player.geo.refY
		self:setPos()
		self:setHitBox()
		return false
	end
ne:init()
addToPlayLayout('btnBegin')


-- go to end
ne = newElement('btnEnd', 'btnBegin')
ne.text = '\xEF\x8E\xB4'
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('seek', 100, 'absolute-percent', 'keyframes')
			return true
		end
		return false
	end
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.refX + 180
		self.geo.y = player.geo.refY
		self:setPos()
		self:setHitBox()
		return false
	end
ne:init()
addToPlayLayout('btnEnd')


-- play previous file button
ne = newElement('btnPrev', 'button')
ne.layer = 10
ne.style = clone(styles.button2)
ne.geo.w = 30
ne.geo.h = 24
ne.geo.an = 5
ne.text = '\u{f303}'
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('playlist-prev', 'weak')
			return true
		end
		return false
	end
ne.responder['resize'] = function(self)
		self.geo.x = 308
		self.geo.y = player.geo.refY 
		self.visible = player.geo.width >= 1250
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['file-loaded'] = function(self)
		if player.playlistPos <= 1 and player.loopPlaylist == 'no' then
			self:disable()
		else
			self:enable()
		end
		return false
	end
ne:init()
addToPlayLayout('btnPrev')

-- folder icon
ne = newElement('btnfolder', 'button')
ne.layer = 10
ne.style = clone(styles.button2)
ne.geo.w = 30
ne.geo.h = 24
ne.geo.an = 5
ne.text = '\u{f247}'
ne.responder['mbtn_left_up'] = function(self, pos)
	if self.enabled and self:isInside(pos) then
		mp.commandv('script-message-to', 'dialog', 'open-folder')
		return true
	end
	return false
end
ne.responder['resize'] = function(self)
		self.geo.x = 332
		self.geo.y = player.geo.refY 
		self.visible = player.geo.width >= 1250
		self:setPos()
		self:setHitBox()
		return false
	end
ne:init()
addToPlayLayout('btnfolder')


-- play next file button
ne = newElement('btnNext', 'btnPrev')
ne.text = '\u{f2fe}'
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('playlist-next', 'weak')
			return true
		end
		return false
	end
ne.responder['resize'] = function(self)
		self.geo.x = 358
		self.geo.y = player.geo.refY
		self.visible = player.geo.width >= 1250
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['file-loaded'] = function(self)
		if player.playlistPos >= #player.playlist
			and player.loopPlaylist == 'no' then
			self:disable()
		else
			self:enable()
		end
		return false
	end
ne:init()
addToPlayLayout('btnNext')


-- Screenshot button
ne = newElement('btnScreenshot', 'btnBack')
ne.text = '\u{f28c}'
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('keypress', 'C')
			return true
		end
		return false
	end
ne.responder['resize'] = function(self)
		self.geo.x = 37
		self.geo.y = player.geo.refY
		self.visible = player.geo.width >= 640
		self:setPos()
		self:setHitBox()
		return false
	end
ne:init()
addToPlayLayout('btnScreenshot')


-- Title Safety button
ne = newElement('btnSafety', 'btnBack')
ne.text = '\u{f395}'
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('keypress', 't')
			return true
		end
		return false
	end
ne.responder['resize'] = function(self)
		self.geo.x = 89
		self.geo.y = player.geo.refY
		self.visible = player.geo.width >= 640
		self:setPos()
		self:setHitBox()
		return false
	end
ne:init()
addToPlayLayout('btnSafety')


-- toggle mute
ne = newElement('togMute', 'button')
ne.layer = 10
ne.style = clone(styles.button2)
ne.geo.x = 137
ne.geo.w = 30
ne.geo.h = 24
ne.geo.an = 5
ne.responder['resize'] = function(self)
		self.geo.y = player.geo.refY
		self.visible = player.geo.width >= 730
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('cycle', 'mute')
			return true
		end
		return false
	end
ne.responder['mute'] = function(self)
		if player.muted then
			self.text = '\xEF\x8E\xBB'
		else
			self.text = '\xEF\x8E\xBC'
		end
		self:render()
		return false
	end
ne:init()
addToPlayLayout('togMute', 'button')

-- volume slider
-- background
ne = newElement('volumeSliderBg', 'box')
ne.layer = 9
ne.style = clone(styles.volumeSlider)
ne.geo.r = 0
ne.geo.h = 1
ne.geo.an = 4
ne.responder['resize'] = function(self)
		self.visible = player.geo.width > 880
		self.geo.x = 156
		self.geo.y = player.geo.refY
		self.geo.w = 80
		self:init()
	end
ne:init()
addToPlayLayout('volumeSliderBg')

-- seekbar
ne = newElement('volumeSlider', 'slider')
ne.layer = 10
ne.style = clone(styles.volumeSlider)
ne.geo.an = 4
ne.geo.h = 14
ne.barHeight = 2
ne.barRadius = 0
ne.nobRadius = 4
ne.allowDrag = false
ne.lastSeek = nil
ne.responder['resize'] = function(self)
		self.visible = player.geo.width > 880
		self.geo.an = 4
		self.geo.x = 152
		self.geo.y = player.geo.refY
		self.geo.w = 88
		self:setParam()     -- setParam may change geo settings
		self:setPos()
		self:render()
	end
ne.responder['volume'] = function(self)
		local val = player.volume
		if val then
			if val > 140 then val = 140
				elseif val < 0 then val = 0 end
			self.value = val/1.4
			self.xValue = val/140 * self.xLength
			self:render()
		end
		return false
	end
ne.responder['idle'] = ne.responder['volume']
ne.responder['mouse_move'] = function(self, pos)
		if not self.enabled then return false end
		local vol = self:getValueAt(pos)
		if self.allowDrag then
			if vol then
				mp.commandv('set', 'volume', vol*1.4)
				env.updateTime()
			end
		end
		if self:isInside(pos) then
			local tipText
			if vol then
				tipText = string.format('%d', vol*1.4)
			else
				tipText = 'N/A'
			end
			tooltip:show(tipText, {pos[1], self.geo.y}, self)
			return true
		else
			tooltip:hide(self)
			return false
		end
	end
ne.responder['mbtn_left_down'] = function(self, pos)
		if not self.enabled then return false end
		if self:isInside(pos) then
			self.allowDrag = true
			local vol = self:getValueAt(pos)
			if vol then
				mp.commandv('set', 'volume', vol*1.4)
				return true
			end
		end
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		self.allowDrag = false
		self.lastSeek = nil
	end
ne:init()
addToPlayLayout('volumeSlider')


-- toggle info
ne = newElement('togInfo', 'button')
ne.layer = 10
ne.style = clone(styles.button2)
ne.geo.w = 30
ne.geo.h = 24
ne.geo.an = 5
ne.text = '\xEF\x87\xB7'
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.width - 87
		self.geo.y = player.geo.refY
		self.visible = player.geo.width >= 640
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('keypress', 'y')
			return true
		end
		return false
	end
ne:init()
addToPlayLayout('togInfo')


-- toggle loop
ne = newElement('togLoop', 'button')
ne.layer = 10
ne.style = clone(styles.button2)
ne.geo.w = 30
ne.geo.h = 24
ne.geo.an = 5
ne.text = '\u{f3AE}'
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.width - 139
		self.geo.y = player.geo.refY
		self.visible = player.geo.width >= 730
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('keypress', 'l')
			return true
		end
		return false
	end
ne:init()
addToPlayLayout('togLoop')


-- toggle srgb
ne = newElement('togSRGB', 'button')
ne.layer = 10
ne.style = clone(styles.button3)
ne.geo.w = 30
ne.geo.h = 24
ne.geo.an = 5
ne.text = '\u{f0e2}'
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.width - 430
		self.geo.y = player.geo.refY - 2
		self.visible = player.geo.width >= 1360
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('script-message', 'restart_mpv_srgb')
			return true
		end
		return false
	end
ne:init()
addToPlayLayout('togSRGB')


-- toggle normal
ne = newElement('tognormal', 'button')
ne.layer = 10
ne.style = clone(styles.button3)
ne.geo.w = 30
ne.geo.h = 24
ne.geo.an = 5
ne.text = '\u{f0e4}'
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.width - 380
		self.geo.y = player.geo.refY - 2
		self.visible = player.geo.width >= 1360
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('script-message', 'restart_mpv_normal')
			return true
		end
		return false
	end
ne:init()
addToPlayLayout('tognormal')


-- toggle AgX
ne = newElement('togagx', 'button')
ne.layer = 10
ne.style = clone(styles.button3)
ne.geo.w = 30
ne.geo.h = 24
ne.geo.an = 5
ne.text = '\u{f0e1}'
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.width - 330
		self.geo.y = player.geo.refY - 2
		self.visible = player.geo.width >= 1360
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('script-message', 'restart_mpv_agx')
			return true
		end
		return false
	end
ne:init()
addToPlayLayout('togagx')


-- toggle ACEScg
ne = newElement('togaces', 'button')
ne.layer = 10
ne.style = clone(styles.button3)
ne.geo.w = 30
ne.geo.h = 24
ne.geo.an = 5
ne.text = '\u{f0e0}'
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.width - 280
		self.geo.y = player.geo.refY - 2
		self.visible = player.geo.width >= 1360
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('script-message', 'restart_mpv_aces')
			return true
		end
		return false
	end
ne:init()
addToPlayLayout('togaces')

-- toggle Linear
ne = newElement('toglin', 'button')
ne.layer = 10
ne.style = clone(styles.button3)
ne.geo.w = 30
ne.geo.h = 24
ne.geo.an = 5
ne.text = '\u{f0e3}'
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.width - 230
		self.geo.y = player.geo.refY - 2
		self.visible = player.geo.width >= 1360
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('script-message', 'restart_mpv_linear')
			return true
		end
		return false
	end
ne:init()
addToPlayLayout('toglin')


-- toggle fullscreen
ne = newElement('togFs', 'togInfo')
ne.text = '\xEF\x85\xAD'
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.width - 37
		self.geo.y = player.geo.refY
		self.visible = player.geo.width >= 600
		if (player.fullscreen) then
			self.text = '\xEF\x85\xAC'
		else
			self.text = '\xEF\x85\xAD'
		end
		self:render()
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('cycle', 'fullscreen')
			return true
		end
		return false
	end
ne:init()
addToPlayLayout('togFs')

-- seekbar background
ne = newElement('seekbarBg', 'box')
ne.layer = 9
ne.style = clone(styles.seekbarBg)
ne.geo.r = 0
ne.geo.h = 2
ne.geo.an = 5
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.refX
		self.geo.y = player.geo.refY - 56
		self.geo.w = player.geo.width - 50
		self:init()
	end
ne:init()
addToPlayLayout('seekbarBg')

-- seekbar
ne = newElement('seekbar', 'slider')
ne.layer = 10
ne.style = clone(styles.seekbarFg)
ne.geo.an = 5
ne.geo.h = 20
ne.barHeight = 2
ne.barRadius = 0
ne.nobRadius = 8
ne.allowDrag = false
ne.lastSeek = nil
ne.responder['resize'] = function(self)
		self.geo.an = 5
		self.geo.x = player.geo.refX
		self.geo.y = player.geo.refY - 56
		self.geo.w = player.geo.width - 34
		self:setParam()     -- setParam may change geo settings
		self:setPos()
		self:render()
	end
ne.responder['time'] = function(self)
		local val = player.percentPos
		if val and not self.enabled then
			self:enable()
		elseif not val and self.enabled then
			tooltip:hide(self)
			self:disable()
		end
		if val then
			self.value = val
			self.xValue = val/100 * self.xLength
			self:render()
		end
		return false
	end
ne.responder['mouse_move'] = function(self, pos)
		if not self.enabled then return false end
		if self.allowDrag then
			local seekTo = self:getValueAt(pos)
			if seekTo then
				mp.commandv('seek', seekTo, 'absolute-percent')
				env.updateTime()
			end
		end
		if self:isInside(pos) then
			local tipText
			if player.duration then
				local seconds = self:getValueAt(pos)/100 * player.duration
				if #player.chapters > 0 then
					local ch = #player.chapters
					for i, v in ipairs(player.chapters) do
						if seconds < v.time then
							ch = i - 1
							break
						end
					end
					if ch == 0 then
						tipText = string.format('[0/%d][unknown]\\N%s',
							#player.chapters, mp.format_time(seconds))
					else
						local title = player.chapters[ch].title
						if not title then title = 'unknown' end
						tipText = string.format('[%d/%d][%s]\\N%s',
							ch, #player.chapters, title,
							mp.format_time(seconds))
					end
				else
					tipText = mp.format_time(seconds)
				end
			else
				tipText = '--:--:--'
			end
			tooltip:show(tipText, {pos[1], self.geo.y}, self)
			return true
		else
			tooltip:hide(self)
			return false
		end
	end
ne.responder['mbtn_left_down'] = function(self, pos)
		if not self.enabled then return false end
		if self:isInside(pos) then
			self.allowDrag = true
			local seekTo = self:getValueAt(pos)
			if seekTo then
				mp.commandv('seek', seekTo, 'absolute-percent')
				env.updateTime()
				return true
			end
		end
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		self.allowDrag = false
		self.lastSeek = nil
	end
ne.responder['file-loaded'] = function(self)
		-- update chapter markers
		env.updateTime()
		self.markers = {}
		if player.duration then
			for i, v in ipairs(player.chapters) do
				self.markers[i] = (v.time*100 / player.duration)
			end
			self:render()
		end
		return false
	end
ne:init()
addToPlayLayout('seekbar')

-- time display
ne = newElement('time1', 'button')
ne.layer = 10
ne.style = clone(styles.time)
ne.geo.w = 64
ne.geo.h = 20
ne.geo.an = 7
ne.enabled = true
ne.responder['resize'] = function(self)
		self.geo.x = 25
		self.geo.y = player.geo.refY - 44
		self:setPos()
	end
ne.responder['time'] = function(self)
		if player.timePos then
			self.pack[4] = mp.format_time(player.timePos)
		else
			self.pack[4] = '--:--:--'
		end
	end
ne:init()
addToPlayLayout('time1')

-- frame display
ne = newElement('frame_number', 'button')
ne.layer = 10
ne.style = clone(styles.time)
ne.geo.w = 64
ne.geo.h = 20
ne.geo.an = 7
ne.enabled = true
ne.responder['resize'] = function(self)
		self.geo.x = 120
		self.geo.y = player.geo.refY - 44
		self.visible = player.geo.width >= 640
		self:setPos()
	end
ne.responder['time'] = function(self)
		if player.frame then
			local f_duration = mp.get_property_number("duration")
    		local f_fps = mp.get_property_number("container-fps")
			if f_duration and f_fps then
				local total_frames = math.floor((f_duration * f_fps) + 0.5)
        player.total_frame = total_frames
			else
				player.total_frame = '--'
    	end
			self.pack[4] = "Frame: " .. player.frame .. " / " .. player.total_frame
		else
			self.pack[4] = 'Frame: -- / --'
		end
	end
ne:init()
addToPlayLayout('frame_number')

-- time duration
ne = newElement('time2', 'time1')
ne.geo.an = 9
ne.isDuration = true
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.width - 25
		self.geo.y = player.geo.refY - 44
		self:setPos()
		self:setHitBox()
	end
ne.responder['time'] = function(self)
		if self.isDuration then
			val = player.duration
		else
			val = -player.timeRem
		end
		if val then
			self.pack[4] = mp.format_time(val)
		else
			self.pack[4] = '--:--:--'
		end
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self:isInside(pos) then
			self.isDuration = not self.isDuration
			return true
		end
		return false
	end
ne:init()
addToPlayLayout('time2')

-- window controllers
ne = newElement('winClose', 'button')
ne.layer = 10
ne.style = clone(styles.winControl)
ne.geo.y = 16
ne.geo.w = 40
ne.geo.h = 32
ne.geo.an = 5
ne.text = '\238\132\149'
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.width - 20
		self:init()
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.visible and self:isInside(pos) then
			mp.commandv('quit')
			return true
		end
		return false
	end
ne.responder['fullscreen'] = function(self)
		self.visible = player.fullscreen
	end
ne:init()
addToPlayLayout('winClose')


ne = newElement('winMax', 'winClose')
ne.text = ''
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.width - 60
		if player.maximized or player.fullscreen then
			self.text = '\238\132\148'
		else
			self.text = '\238\132\147'
		end
		self:init()
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.visible and self:isInside(pos) then
			if player.fullscreen then
				mp.commandv('cycle', 'fullscreen')
			else
				mp.commandv('cycle', 'window-maximized')
			end
			return true
		end
		return false
	end
ne:init()
addToPlayLayout('winMax')

ne = newElement('winMin', 'winClose')
ne.text = '\238\132\146'
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.width - 100
		self:init()
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.visible and self:isInside(pos) then
			mp.commandv('cycle', 'window-minimized')
			return true
		end
		return false
	end
ne:init()
addToPlayLayout('winMin')
