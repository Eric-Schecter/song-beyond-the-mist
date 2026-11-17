# 北林与石场美术统一

北林、石场及连接入口使用精细像素地面和道具，保持原有碰撞、地图连接与双钥匙条件。北林巡林人复用已有角色图集并作绿色衣装配色。蝙蝠、赤花、骸骨兵全局使用新敌人图集，保留攻击预警、受击/死亡效果、音效和战斗参数。每种敌人四个姿态，不是完整四向动画。

## 实现与素材

- `scripts/wild_art.gd`：地形、道具、树冠遮挡、钥匙基座与敌人姿态。
- `assets/refined/wild/props.png`：3×2 透明场景道具。
- `assets/refined/wild/enemies.png`：4×3 透明敌人图集。
- `assets/refined/wild/terrain.png`：2×2 地面纹理。
- `tests/record_wild_art.gd`：从正式入口用按键经过救人、护送、北林与石场战斗并获得双钥匙，不修改血量或跳过战斗。
- `recordings/chapter-01-forest-quarry.mp4`：截取取得罗兰指引之后的连续实机段落。

## 生成方式和完整提示词

验证：第一章回归、短剑动作/命中时机回归通过；实际窗口录制 4609 帧（76.82 秒），截取第 47.82 秒起的约 29 秒探索段落。回看北林树冠、赤花发射、石场敌人、双钥匙对话及河桥开启；录制日志无脚本错误。

使用内置 ImageGen；道具参考晨风村道具图，敌人参考已有角色图；地面为新生成。保留原始生成图，通过 Godot 图集区域读取。

### wild_props

Use case: stylized-concept. Production game asset atlas in exactly the same refined crisp pixel RPG style as reference village props. True transparent RGBA, no glow, no ground background. EXACT 3 columns x 2 rows equal square cells, each object isolated centered fully visible with generous gutters. 1536x1024. Orthographic low top-down JRPG perspective (not isometric), warm upper-left light, dark blue-gray outlines, muted sage/ochre palette. Row1: cell1 large layered moss-green forest oak tree with exposed short trunk, similar to reference tree but denser forest foliage; cell2 low compact cluster of ferns, roots, mushrooms and mossy stump; cell3 weathered gray quarry boulder with distinct stratified planes and pale warm edges. Row2: cell1 modest stack of quarried stone blocks and small gravel, no floor plane; cell2 old wooden quarry lifting gantry with triangular timber supports, rope and small pulley, compact no hanging boulder; cell3 ancient small circular stone pedestal with carved rim and moss cracks, EMPTY top for gameplay key. Crisp clean hand-pixelled clusters, equivalent 64px original sprites enlarged. No characters, no text, no grid lines, no backdrop or blurry shadows.

### enemy_cast

Use case: stylized-concept. Production ENEMY animation sprite atlas matching reference refined chibi pixel-art JRPG characters. EXACT 4 columns x 3 rows, equally sized cells, 1536x1024 transparent RGBA background. Generous transparent gutters; every creature fully inside its cell. Crisp hand-pixelled clusters equivalent to original 48px sprites enlarged, dark outlines, restrained highlights. Consistent three-quarter front view facing right; same scale and identity across each row. ROW1 purple-winged bat: col1 wings raised, col2 wings extended sideways, col3 wings down, col4 tucked wings forward lunging attack, cute threatening amber eyes and tiny fangs, gray purple fur. ROW2 red carnivorous flower monster rooted in curled sage leaves: col1 closed relaxed red flower maw, col2 slightly open idle mouth, col3 visibly inflated charging open mouth, col4 forward spitting wide mouth; cream little thorns and dark mouth, short stem, stay anchored same feet baseline. ROW3 skeleton swordsman: ivory skull and ribs, weathered teal shoulder armor, brown belt, torn ochre waistcloth, rusty short sword; col1 ready stance, col2 walking alternate step, col3 clear sword raised windup, col4 sword forward slash followthrough. All poses aligned body centers and baseline. Do not add particles or attack arcs. No text, no grid, no ground, no glow. Same detailed pixel density and shading as reference heroes, readable silhouettes, not vector or smooth painting.

### wild_terrain

Use case: stylized-concept. Actual pixel-art seamless RPG ground texture atlas EXACT 2 columns x 2 rows without gutters or borders. Square1024x1024. Strict overhead flat surface, crisp fine hand-pixelled clusters equivalent32px original per tile enlarged, muted low-contrast natural colors. Top left: shaded sage forest floor, scattered small moss tufts and brown leaf specks. Top right: warm ochre packed forest dirt, sparse tiny pebbles. Bottom left: warm gray-beige quarry limestone ground, small subdued cracks and tiny gravel. Bottom right: darker gray rocky quarry dust with scattered thin sediment lines. Four equally sized seamless textures fill entire cells; restrained contrast lets characters stand out. No objects, no grass borders, no scene, no perspective, no labels. Match warm classic refined pixel JRPG village style.

