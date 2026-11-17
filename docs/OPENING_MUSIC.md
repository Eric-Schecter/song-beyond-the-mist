# 开场分段配乐

- 开始菜单：`mist_title_theme.wav`，96 BPM，16 小节主题，长笛、竖琴、弦乐与大提琴；重复动机、应答、B 段发展与主题再现。
- 三页背景介绍：`mist_history_story.wav`，60 秒、24 小节 6/8，钢琴主题、长笛回应、大提琴暗色桥段、弦乐主题再现；翻页不重播。
- 进入村庄：保留 `morning_adventure.wav`，首领曲不变。

`tools/render_opening_themes.swift` 为原创 MIDI 编曲，使用 macOS 系统音色离线渲染，输出后通过 ffmpeg loudnorm 到 -19 LUFS、16-bit stereo PCM。先前 Python 纯合成两曲已停用。

开场实例在加入场景树之前设置明确的 `music_context=title`，只有开始旅程才改为 history，结束介绍才改为 adventure。播放器每帧遵循这一状态，切换交叉淡化 1.5 秒。

`tests/record_music_stages.gd` 在菜单停留 16 秒后核对实际音频数据为菜单曲（不只检查标签），并检查背景介绍曲数据及进入村庄的音乐状态。录像 `recordings/opening-themes-v2.mp4`。

新版背景曲由 `tools/render_history_story.swift` 独立生成。保留菜单与村庄音频，只替换 history 曲目。新录像 `recordings/history-story-v3.mp4` 展示 6 秒菜单、60 秒背景介绍和 8 秒村庄衔接。
