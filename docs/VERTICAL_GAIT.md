# 当前版本：原始六帧图集

上下行走已恢复 `assets/refined/hero/vertical_walk.png`（2026-11-07 原始整帧素材），正面、背面各六帧，按原有移动距离时钟播放；停步使用人物待机立绘。`village_art.gd` 直接绘制完整帧，不再调用 `vertical_gait.gd` 或 PixelLab。左右动作、上下攻击、浮空武器和其他玩法未修改。保留当前固定脚下阴影定位。

验证录像：`recordings/original-six-frame.mp4`，近景 `recordings/original-six-frame-closeup.mp4`。

以下为历史记录，非当前实现：

# 当前版本：恢复最初上下行走

按用户要求恢复 `vertical-gait.mp4` 对应的原始 `vertical_gait.gd`：连续轻微摆臂、交替抬脚、轻微披风运动。后续六帧分部重做、小跑与接缝修改均已撤回。PixelLab 仍停用。左右动作、浮空武器和其他玩法保持现状。当前验证录像为 `recordings/original-gait-restored.mp4`。

以下为已撤回版本的历史记录：

# 上下行走与任务标记修正

上下行走已停用 PixelLab，改为使用现有人物素材制作的六个离散步态姿势，与左右方向保持相同造型和步态时钟。

上下行走使用村庄人物图集的正面 / 背面身体部件制作摆臂、交替抬脚和披风运动。每移动 40 单位完成六帧循环；正常速度 67 时约 10 动画帧/秒，完整周期约 0.6 秒，与左右方向一致。双脚交替收腿最大抬高 2.8 单位，身体在腾空帧上提 1.05 单位，完整袖口和手随肩摆动，手腕上提形成收臂姿势，背面手部从披风两侧露出。身体尺寸与头部轮廓保持固定；松开方向键后以 locomotion 权重收回步姿，恢复双脚落地。身后浮空武器和碰撞逻辑保持原流程。

`tests/record_walk_cadence.gd` 实际输入四方向各两次并验证位移，录像为 `recordings/handmade-walk.mp4`，放大版为 `handmade-walk-closeup.mp4`。`tools/render_vertical_poses.gd` 导出六帧正背面姿势检查图。

`scripts/vertical_gait.gd` 负责动画，`village_art.gd` 调用。旧 vertical_walk 图集保留为历史素材，但不再用于主角上下移动。

任务符号从脚底上方 39 单位调整为成人 25 / 儿童 19，字号从 14 调整为 12，浮动幅度从 1.5 缩到 0.6。横向按真实字宽居中，位置跟随实际任务 NPC。靠近时 E 收成无指向箭头的小按键，显示在问号靠玩家的一侧，避免与符号重叠或上移后被任务栏遮住。

`tests/record_vertical_gait.gd` 使用真实方向键展示连续上下走、停步、短步反向，以及远近距离的问号与 E 交互，最后验证能正常触发罗兰对白。录像为局部功能演示，不是完整主线通关。

摆臂接缝修复：手臂由六段连续网格绘制，肩部固定并覆盖到上身下方，位移和旋转逐渐增加到手腕；不再整体平移手臂导致肩袖断开。修复录像：`recordings/walk-arm-fixed-closeup.mp4`。

小跑调整：保持六帧和现有步频，以落地、收腿、腾空三姿势交替双腿；脚部跟随身体腾空，手腕前后摆幅增至 2 单位，肩部仍固定。录像 `recordings/vertical-run-closeup.mp4`。

游离像素修复：删除正面仍停在原处的披风边缘窄条，收紧腿部取样范围，避免抬腿时把披风边角一起旋转带出。六帧正背面检查图与 `recordings/run-pixels-fixed-closeup.mp4` 验证。
