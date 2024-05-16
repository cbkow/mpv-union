# mpv-union
 mpv setup and config for VFX

![mpv-union](img/mpv-union_001.jpg)

## Install guide

### Manually (not recommended)

#### 1. Download and Install
- Download the latest *shinchiro* release: https://mpv.io/installation/

- Extract the package and move it to a `mpv' folder in a permanent location--anywhere is fine.  

- Right-click on `mpv/installer/mpv-install.bat` in your new mpv folder. Select *"Run as administrator"* from the Windows context menu. This helps register all the file types for your new player.

#### 2. Add mpv to your Windows Path.
 **IMPORTANT!** Don't skip this step. Many of the additional plugins and scripts require having **mpv's** location in your system path. *See notes at the end for more info.*

- Edit your environment variables

![mpv-union](img/mpv-union_003.jpg)

- Edit your system paths

![mpv-union](img/mpv-union_004.jpg)

- Add mpv to your system path and save. This will be the full directory path to the executable, but it does not include the executable itself.   

![mpv-union](img/mpv-union_005.jpg)

#### 3. Install plugins and extensions
 - Download the "mpv" folder above. In Windows Explorer, type in `%appdata%` and press enter. Alternately, browse to `C:\Users\Username\AppData\Roaming` where *Username* is your user name. 
 
 - If an 'mpv' folder does not already exist in this location, create one. If you already have one, delete its entire contents. 

 - Copy all the files from the downloaded `mpv` folder to the `mpv` folder in appdata. 

---
### Using Chocolatey (recommended)
 Chocolatey is a package manager for Windows. The advantage of installing MPV this way is two-fold: (1) It will automatically add MPV to your path. (2) Updates are effortless.

#### 1. Install Chocolatey
 - Open an Admin Powershell window and paste the following. Press enter. When you're finished, it will ask you to enter two more lines. Do them one by one and press enter after copy-pasting each line individually. Don't forget this last step.

```
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

#### 2. Install mpv
 - In a new Admin CMD window, enter `choco install mpv` —press enter, then "y" or "a" when asked. 

#### 3. Install plugins and extensions
 - Download the "mpv" folder above. In Windows Explorer, type in `%appdata%` and press enter. Alternately, browse to `C:\Users\Username\AppData\Roaming` where *Username* is your user name. 
 
 - If an 'mpv' folder does not already exist in this location, create one. If you already have one, delete its entire contents. 

 - Copy all the files from the downloaded `mpv` folder to the `mpv` folder in appdata. 
 


## Find mpv...
  ...and pin to your tasbar or start menu.

- Press the Windows key on your keyboard,search for MPV, and click "Show Location." This will show you the location of mpv.exe. You can right-click on that executable and pin it to the start menu or taskbar. 

## Usage

### Player controls

![mpv-union](img/mpv-union_006.jpg)

1. Saves screenshot to clipboard
2. Toggles broadcast title/action safety guides
3. Estimated frame count - *See notes*
4. Loads a folder to playlist + navigate up/down that list
5. Moves to beginning (end) of clip
6. Moves back (ahead) 1 second.
7. Moves back (ahead) 1 frame.
8. Play/Pause
9. Toggles playback color space `rec,709 to sRGB`, `No transforms`, `AgX to sRGB`, `ACEScg to sRGB`, `Linear sRGB/rec.709 to sRGB`
10. Loops file
11. Info
12. Full screen

### User-input is often needed

![mpv-union](img/mpv-union_009.jpg)

 - Many menu options require user input, such as image-sequence playback, video transcoding, and EXR-layer extraction. A dialog will appear in the bottom left corner of the window. Enter a selection from the menu or type out the requested data, then press enter. 

### Right-click menu - Social media title safety guides

![mpv-union](img/mpv-union_007.jpg)

### Right-click menu - Video extras

![mpv-union](img/mpv-union_008.jpg)

- **Find After Effects Project** - Looks for metadata in a video that points to a source After Effects project. If it finds the metadata, it will present options to reveal the project in Windows Explorer, open it in After Effects, or copy the file path to the clipboard. NOTE: Natively, this metadata is only written to certain file formats like Quicktime *.mov.

- **Find Premiere Project** - Same as above, but for Premiere.

- **Transcode options** - Transcodes an MP4 into the same folder as the source video. Provides options for common color space conversions. This transcoder will also look for After Effects metadata in the source file and copy it to the MP4 if it finds it. 

### Right-click menu - Image extras

![mpv-union](img/mpv-union_010.jpg)

- **Play Image Sequence** - Load one image from a sequence into the play and then click this button to play the whole sequence as a video. It will ask you for a framerate first. Type the framerate in as a response (numerals only like `24`, `25`, or `23.976`), then press enter to play the sequence. 

- **EXR Extract** — These menu options will extract a layer from a multi-layer EXR file as a proxy for previews. First, it asks you to select a layer for extraction (deliberately ignoring Cryptomattes). Once the extraction is complete, it will ask you for a framerate and play down that proxy sequence as a video. If the plugin sees an alpha channel in the layer, it will write a PNG sequence into a subdirectory in your render folder. It will write a JPG sequence into that subdirectory if it does not see an alpha channel. **Notes:** (A) From what I can tell (I am not a Redshift user) Redshift doesn't save alpha data on AOVs and passes (it only saves alpha data on the main RGBA pass), so it will always extract JPGs. Only Octane and Cycles will output PNGs. (B) This plugin may not work as expected if you don't have clean render folders. It doesn't yet accommodate multiple sequences in the same folder. It's still a work-in-progress. (D) The proxy extraction outputs frames that are 1080px(with the width generating a value that respects the native aspect ratio). This resizing allows for frame-accurate animation review of larger 4k+ renders that may otherwise playback in real-time. 

- **Transcode to MP4** — This menu option functions like the video transcoding options but for image sequences. It works if you have loaded the whole sequence or only one image from that sequence. Before transcoding, the plugin will request a frame rate and a starting frame number. The starting frame number is essential for it to function as intended. Like the EXR extracting plugins, clean folder structures are needed--the plugin makes some assumptions about folder structure. It will render an MP4 to the sequence's parent folder so that it's not lost in a sequence folder. 

## Additional notes
- This mpv setup uses several external binaries for transcoding (FFMPEG), EXR extraction (OIIO), and reading metadata (ExifTool). The mpv config folder includes the binaries to simplify an install (hence the large download size). 

- The After Effects and Premiere Finder plugins rely on optional software-written metadata. To use them, check your render templates and program preferences to ensure they are enabled. 

- MPV isn't aware of frames in videos, so the frame count is generated on the fly by multiplying fps and duration--hence the "estimation." It then rounds up/down the frame values to a whole number. It can occasionally be one frame off compared to a DCC or NLE in framerates, such as 23.976 or 29.97. Most video players are like this, but it's worth mentioning. 

- The EXR extraction uses ACES 1.2 or Blender 4.1 OCIO configs directly in OpenImageIO. The transcoding, playback, and playback color space transforms use LUTs, which are generated with ociotools using those same configurations. 

- The LUT workflow could be more efficient for a few reasons. Quality is one of them, but also MPV doesn't allow for on-the-fly LUT swapping. I am getting around that by launching another instance of MPV and closing the old one--attempting to capture playback and window size/positions and transferring that to the new MPV instance. This process is a can of worms. To capture mpv's positioning, the plugin has to account for DPI-scaling and then calculate that location. There is a performance penalty to it that I don't love. 

- Additionally, this may not work well in dual-monitor setups where different panels use different DPI scaling. Is it worth the hit? Switching colorspaces is lightning fast without it, and it may be better to just let the player load in the middle of the screen each time it swaps LUTs. 

- Because of the LUT workflow, these tools are meant for quick reviews and fast client postings. Please don't use them for any final deliveries. Under certain circumstances, they don't have exact perceptual parity to a fully color-managed workflow in compositing. 

- With all that said, GLSL shaders would be a better method than using LUTs in playback and transcoding. It would increase the quality of the outputs and also eliminate the need to relaunch mpv on LUT changes. Check out natural-harmonia-groupius' hdr-toys project: https://github.com/natural-harmonia-gropius/hdr-toys. The ACES shaders in hdr-toys work great. I would need rec.1886 to sRGB and AgX shaders to complete the package and shift strategies. 

- The final note: I have a very strict naming convention for files that only include letters, dashes, and underscores without spaces. I tried to avoid possible issues by escaping paths to accommodate other workflows, but YMMV. I am sure I missed something. 

## Credits
 Included binaries and mpv plugins:

- https://github.com/ObserverOfTime/mpv-scripts/blob/master/clipshot.lua
- https://exiftool.org/
- https://ffmpeg.org/
- https://github.com/CogentRedTester/mpv-user-input
- https://github.com/tsl0922/mpv-menu-plugin
- https://github.com/maoiscat/mpv-osc-framework
- https://opencolorio.org/
- https://github.com/AcademySoftwareFoundation/OpenImageIO

