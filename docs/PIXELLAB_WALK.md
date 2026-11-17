# PixelLab 上下行走动画

状态：已停用，以下仅为历史生成记录。用户认为其与左右动作不一致，当前游戏使用 `vertical_gait.gd` 的本地六帧分部动画，见 `VERTICAL_GAIT.md`。资源保留归档，`village_art.gd` 不再加载或调用 PixelLab 动画。

用户授权将现有主角的正面、背面两张 128×128 参考图上传到 PixelLab，用于生成上下行走。只上传角色图片，不含项目代码。参考图由村庄人物图集导出，保留在 `assets/refined/hero/pixellab_walk/reference_*.png`。

最终正面采用 16 帧，后视采用 16 帧：左右腿交替抬起，手臂反向摆动，后视手部可从披风两侧露出。主角的浮空武器仍独立绘制。站立沿用原参考图，身体使用固定画布原点与尺寸，阴影单独固定在脚下，不随抬腿帧重新定位。

播放节奏调整：上下行走动画按原速的 0.375 倍播放，正常移动时约 10 动画帧/秒，与左右移动的换帧频率一致。上下保留 16 帧，完整循环约 1.6 秒；左右保留原有 6 帧，循环约 0.6 秒。游戏渲染、移动速度和左右行走不变。四方向对比录制：`tests/record_walk_cadence.gd`。

`scripts/pixel_walk.gd` 读取 `clips.json` 中明确列出的帧，`village_art.gd` 只在上下移动 / 站立时使用这些资源；左右移动与攻击保持现有实现。文件不存在时回退到本地步态。录制脚本 `tests/record_pixel_walk.gd` 要求两个方向都完整加载，使用真实方向键验证连续走动、停步、短步反向和 NPC 交谈。

生成来源：

- 初版正面 job `f6f73c0d-a6eb-43bd-b208-befd55d04e70`，8 帧，未采用：主要只有单侧迈步。
- 初版背面 job `d70c6bf0-8ed0-4520-83ed-566c7f18099c`，8 帧，未采用：手臂隐藏。
- 最终正面 job `4b165888-30da-4674-b2a0-4d3674b159f3`，`animate_image`，16 帧，seed 520；gallery `beff066c-6f76-5a39-9181-82229d9c3223`。
- 最终背面 job `4b85204c-27e9-4430-82a8-8b842305eb46`，`animate_image_pixminimax`，16 帧，seed 621；gallery `14eb64f9-7d7b-5a28-a7a0-9815aa55f71a`。
- 背面精修使用 PixelLab `pixelart_workbench`，result `ea341358-5893-42d6-aa78-631d38f5d1bb`：仅删除九帧中靴子旁 610 个颜色为 `#807f7dff` 的杂点，保留衣服、手和靴子；可重放的精确修改记录为 `north_cleanup.json`。

`north_clean_sheet.png` 保存服务返回的完整精修图集（含首个原参考帧）。`tools/import_pixel_walk.gd` 仅切片导入，跳过首个参考帧，不重新绘制图片。初版资源不在最终播放列表中。
