# 四向移动、脚底阴影与外围地形

- 新增 `assets/refined/hero/vertical_walk.png`，正面/背面各六帧，按实际移动距离推进；停止移动使用原有待机立绘。身后浮空武器保留。
- `refined_atlas.gd` 与 `hero_action_clips.gd` 从不透明脚部提取锚点，消除图集留白造成的脚底/阴影错位。主角阴影缩小、减淡，并使用与人物相同的连续世界坐标。
- 河床改用纹理，西岸增加不规则分层岸沿与石块；石场南侧延伸地表并添加岩石边界，避免画面中露出地面矩形截断。原有行走碰撞、桥梁和矿洞入口保留。
- `tests/record_motion_edges.gd` 从正式入口完成剧情准备，再展示四向移动、停步、北林河岸、石场南缘、战斗与双钥匙。

## 素材生成

使用内置 ImageGen，以已有角色方向图和横向动作图作为风格/身份参考；保存原始透明图集，运行时取区域绘制，没有修改原始图像。

完整提示词：

Use case: stylized-concept. Production pixel-art walking animation atlas of EXACT same hero in reference images: tousled chestnut hair, teal tunic, golden ochre shoulder cape, brown belt and boots, youthful chibi proportions. Reference1 first row provides front/back identity; reference2 provides pixel density and walk style. EXACT 6 columns x 2 rows equal cells, 1536x1024 transparent RGBA, generous gutters. Row1 SIX sequential frames of walking SOUTH toward viewer, face visible. Row2 SIX sequential frames of walking NORTH away from viewer, back of hair and flowing ochre cape visible. Every row a coherent looping six-frame walk cycle: left foot contact, passing, right leg forward, right contact, passing, left leg forward. Clearly alternate legs with opposite arm swing and subtle cape sway. Same body size/head proportions and pixel density across ALL frames, feet on consistent baseline and body centered, no rotations or side views. Crisp hand-pixelled clusters like reference, NOT smooth illustration. Empty hands, no weapon, NO ground or cast shadow, no glow, no text or grid. Full body within every cell, no cropping.

补充外围修复：矿洞外部不再以纯黑矩形直接贴住村庄和石场，改用深色岩石地表及表层岩脊收边，保留原裂岩入口。此处仅处理外缘衔接，矿洞内部场景未重做。

验证：第一章剧情回归和短剑动作/命中时机检查通过；录制路线覆盖上下左右行走、停步阴影、北林右岸、石场南缘及双钥匙开桥。最终交付录像为 `recordings/chapter-01-motion-shadow-edges.mp4`。

## 脚底阴影二次修复

此前阴影仍单独绘制在 `player + offset`，脚部锚点取底部12%的包围范围，不能保证阴影中心落在当前帧真正接触地面的鞋底上。现在保留姿态定位，另取底部2.5%的不透明鞋底接触锚点；阴影和人物使用同一个源区域、目标矩形及翻转变换。主角与NPC的旧独立阴影已移除，避免重复绘制。阴影内层与最后一行鞋底重叠，不留悬空缝隙。

`tests/shadow_contact_regression.gd` 检查16个方向姿态、12帧纵向行走、18帧横向/攻击动作以及镜像接触映射。`tests/record_shadow_contact.gd` 通过实际输入展示四向行走、停步和挥剑；录像：`recordings/shadow-contact-fix.mp4`。

## 向左镜像实际渲染修复

复现了关键差异：Godot `draw_texture_rect_region` 对 `Rect2(40,20,-10,10)` 实际画在逻辑x=40..49；原阴影映射认为它在x=30..39。三倍窗口实测分别是120..149与期望90..119。仅测试接触点数学公式不足以覆盖这个渲染差异。

现在使用正尺寸四边形与显式镜像UV，人物和阴影映射共享同一目标几何。`tests/shadow_mirror_render.gd` 在实际渲染窗口读取像素，验证修复后的x范围为90..119；短剑回归检查通过。`tests/record_shadow_left.gd` 专门验证左右反复走停与向左攻击。
