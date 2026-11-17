# 矿洞精细像素风

岩壁、支架灯、矿车、营地、晶簇、裂岩、双碑及宝箱采用与石场一致的精细像素素材。地面复用现有石质与泥土纹理，以世界坐标采样，入口逐渐转为洞内冷灰色。墙脚添加接触暗部和碎石；外围暗岩延伸至相机之外，避免地图底端出现水面或黑色矩形。

通行格、碰撞、机关范围、敌人和奖励逻辑保持原样。

## 素材

- 内置 ImageGen，透明图集：`assets/refined/mine/props.png`。
- 参考：`assets/refined/wild/props.png`，原图保留，运行时按图集区域绘制。
- 实现：`scripts/mine_art.gd`，机关接入 `scripts/mine.gd` 与 `scripts/valley.gd`。
- 录制脚本：`tests/record_mine_art.gd`。从第一章完成后的石场检查点开始，之后使用真实按键开启入口、探索、战斗、激活机关和修复升降梯。

## 验证与录像

验证记录：矿洞录制流程已通过入口破岩、回声核心、震地开路、营地手记、晶核支路、双碑、宝库奖励及升降梯往返。实机回看检查入口地面、墙脚、断桥、东侧晶核台与宝库外围；最终录像为 `recordings/chapter-01-refined-mine.mp4`，包含游戏音频。

## 生成提示词

Create a production game sprite atlas matching the supplied refined pixel JRPG props style. Exact 3 columns x 3 rows equal cells, 1536x1536, TRUE TRANSPARENT background. Nine isolated sprites, crisp hand-pixelled clusters equivalent 64px objects, warm gray limestone and muted blue slate shadows, worn brown timber, warm lantern gold, subtle turquoise mineral accents. Orthographic low top-down RPG view, not isometric. ROW1: 1 broad rugged cave cliff rock face with uneven top and layered fractured strata, no vegetation; 2 smaller irregular rubble/boulders; 3 wooden mine support arch with warm hanging lantern, fully open doorway. ROW2: 1 small abandoned ochre canvas miner tent with rolled bedroll; 2 wooden mine cart filled with gray ore; 3 turquoise crystal cluster on stone base. ROW3: 1 cracked upright blocking boulder with subtle gold fissure; 2 small ancient rune stone obelisk with turquoise inset; 3 closed wood treasure chest with iron bands. Same visual fidelity and lighting as reference, restrained natural palette. No floor plane, no contact shadows, no text, no grid lines, no background haze, generous transparent gutters, objects must stay entirely within their cell. Broad cliff rock should be wider than tall; prop silhouettes readable.
