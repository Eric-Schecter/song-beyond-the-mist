# 泉岛与石像首领美术

泉岛使用连续的草地、石质空地和沙土过渡，圆角不规则岸线包含原有全部可行走格；桥头路面连接西岸小径，桥面覆盖原有拼接缝。岸边使用苔石、芦苇与水花植物，保留清晰的战斗空地。恢复泉水后浅滩与泉眼切换为水景。

首领图集对应待机、蓄力、冲撞、恢复破绽、受击、死亡与残骸。保留原有碰撞、攻击/受击时机、双冲撞、预警、粒子与音效，使用已修正的镜像与脚底阴影绘制。神官艾琳使用新的四向立绘。

## 素材和实现

- `assets/refined/island/props.png`：3×2 透明泉眼与遗迹图集。
- `assets/refined/island/warden.png`：4×2 透明石像首领图集。
- `assets/refined/island/priest.png`：2×2 透明神官方向图集。
- `scripts/island_art.gd`：地面网格、岸线、桥梁、场景道具与角色绘制。
- `tests/record_island_art.gd`：实际按键从第一章入口推进双钥匙，再进入泉岛、击败首领、恢复泉眼并沿东岸和南岸行走。录像不修改血量或跳过战斗。

## 验证与录像

- 第一章剧情回归和实际按键录制流程通过：双钥匙、桥头、神官对话、双冲撞首领、恢复泉水、东岸与南岸巡视。
- 已回看实机画面，检查桥头连接、草石过渡、首领状态和恢复泉水后的岸线。
- 成片：`recordings/chapter-01-island-warden.mp4`（960×672，含游戏音频）。

## 生成提示词

使用内置 ImageGen，以现有角色和石场道具为参考生成，原始图集保存在项目中；地面复用现有纹理并在运行时混合，没有修改原图。

### island_props

Production game asset atlas, refined hand-pixelled JRPG art exactly matching supplied stone/forest props reference. True transparent RGBA, isolated sprites, no halo or background. EXACT 3 columns x 2 rows equal square cells,1536x1024. Orthographic low top-down RPG perspective, NOT isometric. Restrained sage, warm limestone, aged gold, turquoise accents. ROW1 cell1 ancient round stone spring fountain, empty dry basin and short carved central spout, moss on weathered cream-gray rim, fully visible; cell2 EXACT same fountain identical dimensions and perspective, restored turquoise water filling basin and modest flowing jet, no tall spray; cell3 small ruined mossy stone arch with two short columns, cracked lintel and modest gold sigil. ROW2 cell1 broken stone pillar with ivy on one side; cell2 compact shore boulder group with reeds and moss, no ground plane; cell3 compact tuft of reeds and pale water flowers with several flat stones, no puddle. Crisp pixel clusters equivalent64px sprites enlarged, upper-left warm light, dark soft outlines. Generous transparent gutters, full objects within cells, no text, no grid, no ground tiles.

### stone_warden

Production pixel-art boss animation atlas in the refined chibi JRPG style of references (hero scale/style reference1, stone material reference2). EXACT 4 columns x 2 rows,1536x1024, true transparent RGBA. One consistent ancient STONE WARDEN: stocky humanoid guardian carved from weathered warm gray limestone, huge block forearms, short sturdy legs, angular masked face, moss patches on shoulders, a small turquoise crystal embedded in chest and eye slits. Height about1.5x hero; no weapons. Same three-quarter front view facing right, same scale and ground baseline. ROW1: neutral standing; lowered stance fists drawn back charging power; forward leaning shoulder charge both feet visible; exhausted kneeling recovery with exposed glowing chest. ROW2: recoil from hit with chipped stone; cracked-body dying kneeling pose; collapsing broken chunks still clearly guardian silhouette; settled pile of rubble with dim crystal. No effects, no floor or cast shadows, no text, no grid, no glow beyond creature. Every sprite fully contained in equal cell with generous margins. Crisp hand-pixelled clusters, readable clean silhouettes; no smooth painted gradients. Match detailed pixel rendering of reference sprites.

### island_priest

Production RPG character rotation atlas matching EXACT pixel density and chibi proportions of reference cast. New NPC priestess Eileen, kind young adult woman, long dark chestnut hair tied low, ivory robe with sage green shoulder mantle, aged gold trim and waist sash, brown shoes, simple small turquoise pendant, empty hands. EXACT 2 columns x 2 rows equal square cells on1024x1024 transparent RGBA. Top left SOUTH front view, top right EAST right view, bottom left NORTH back view, bottom right WEST left view. Full body, same scale and grounded baseline in all cells, generous clear gutters. Crisp hand-pixelled clusters like reference, no smooth painting, no weapon/staff, no background, no glow, no cast shadow, no text or grid. Warm muted palette compatible with limestone spring shrine.

