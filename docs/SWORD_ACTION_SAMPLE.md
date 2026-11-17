# 御剑动作样板

F6 进入矿洞样板间；Z 切换近景；J 第一段横斩，再按 J 缓冲第二段反向上挑；Esc 返回原游戏状态。

## 本轮范围

样板间采用新绘制的单侧动作图集：6 帧走路、6 帧横斩指令、6 帧上挑指令，共 18 帧。向左使用镜像；上下移动仍显示侧面，因此不是完成的四向动画。新人物动作只在样板间启用，避免主地图角色朝向不一致。主地图和样板间都使用新的剑刃轨迹、拖尾和命中反馈。

浮空剑由引擎独立绘制：准备 0–0.075 秒，出剑 0.075–0.205 秒，之后收回。伤害触发由 0.08 秒移至 0.14 秒，让命中落在动作中段。输入缓冲、两段连击和武器强化规则保持不变。

尾迹记录实际剑刃位置，区分每一次挥击，避免不同连击之间拉出跨越直线；尾部渐细并在 0.14 秒内消失。第一段为暖金色，第二段为淡青色。命中爆点持续 0.24 秒，命中停顿冻结人物动作和尾迹。剑气外观属于近身挥斩表现，没有新增远程伤害。

原图集保留，不做切片覆盖；Godot 在加载时以实色像素确定各帧裁切范围与脚底基线，避免透明边缘中的低 alpha 噪声引起位置跳动。所有帧使用相同缩放比例，保留蹲身和抬手的高度变化。

## 素材与制作

内置 imagegen 工具生成，2026-11-07。参考：`assets/refined/hero/rotations/east.png`。

最终素材：`assets/refined/hero/east_action_sheet.png`（1774×887 RGBA，6 列 × 3 行）。

最终生成提示：

Create a production animation sprite sheet based on this exact brown-haired, blue/teal tunic, ochre cape, leather boots pixel RPG adventurer. This is actual game art, not a concept poster. Transparent RGBA background, no ground, shadows, labels, lines, panels, text or weapons. ALL figures face EAST / screen-right, side view with slightly top-down RPG perspective, consistent anatomy and clothing. Layout EXACTLY 6 columns by 3 rows of equally spaced square cells, 18 full-body figures. Canvas 1536 x 768, each cell 256x256. Every figure feet baseline at cell y=230, hip at cell x=128. Each figure approximately 180px tall, chunky crisp native pixel-art clusters as if each character was originally 48 pixels tall then nearest scaled. Use clean pixel clusters and restrained original palette, not smooth painting, no antialias gradients. NEVER draw weapons, swords, energy trails or effects because these are rendered separately. Keep each figure within its own cell with clear transparent gutters. Row 1: six sequential looping WALK cycle keyframes east: left foot forward contact, lowered passing, right foot forward contact, right foot planted weight, opposite passing, left foot planted. Clearly distinct natural leg positions, opposing arm swing, cape follows, consistent head size. Row 2: six sequential TELEKINETIC SWORD horizontal slash command poses east: 1 stable relaxed stance empty hands, 2 anticipation bending knees and turning shoulders drawing right hand back, 3 lead foot plants and open right hand sweeps forward horizontally, 4 decisive follow-through open hand extended toward right, 5 recoil hand returning cape trails, 6 settled ready stance. Row 3: six sequential TELEKINETIC reverse rising slash command poses east: 1 ready stance, 2 crouched wind-up with open right hand low beside left hip, 3 rising forward step sweeping open right hand upward, 4 powerful upright followthrough right hand pointing diagonally up-right with back heel raised, 5 settle shoulders and hand lower, 6 relaxed ready pose matching row2 frame1. Dramatic but grounded, never jumping or floating, no weapons in hands. Exact 6x3 regular grid, same scale in every cell, full body boots visible, no fused/extra limbs. Preserve identity of reference. Deliver only the spritesheet on actual transparency.

## 验证

`godot --headless --path . --script tests/sword_visual_regression.gd`

覆盖动作帧有效范围、预备阶段不命中、实际接触帧伤害、命中停顿、拖尾消散、挥空不产生命中爆点与重置清理。
