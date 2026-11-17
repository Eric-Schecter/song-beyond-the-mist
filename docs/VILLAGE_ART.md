# 晨风村精细像素美术

本轮覆盖晨风村出生区与村东救人小径，沿用房间样板的精细像素方向。房屋、树木、土路、草地与母亲、小诺、罗兰统一；地图碰撞与第一章剧情不变。

主角横向沿用现有动作序列，南北向使用新方向立绘与轻微步态起伏，尚非完整四向逐帧动画。村外区域和敌人美术不在本轮范围。

## 素材与生成方式

使用内置 ImageGen：道具与人物以已有房间/人物图为参考生成透明图集；地形为新建不透明图集。原始生成图保持完整，Godot 运行时读取图集区域。

- `assets/refined/village/props.png`：3×2 道具图集
- `assets/refined/village/terrain.png`：2×2 地面图集
- `assets/refined/village/cast.png`：4×4 人物方向图集
- 实现：`scripts/village_art.gd`、`scripts/refined_atlas.gd`
- 实机录像：`recordings/chapter-01-village-art.mp4`
- 录像驱动：`tests/record_village_art.gd`，实际输入救人、护送、战斗、对话及屋后通道。

## 生成提示词

### village_props

Actual GAME ASSET ATLAS, matching the refined pixel art of the reference mine room. Outdoors village props in low top-down orthographic RPG view, NOT isometric. Exact 3 columns x 2 rows equal square cells, canvas 1536x1024, one isolated object per cell on true transparent background, generous transparent gutters. No ground tiles, no background, no text, no labels, no shadows extending far outside object. Fine crisp pixel clusters, warm ochre/terracotta and slate roofs, pale plaster, dark timber, restrained highlights, 16-bit handcrafted RPG style. Consistent top-down view showing roofs and front facades, light from upper left. ROW 1: cell1 small cozy cottage with terracotta tiled pitched roof, chimney, cream plaster walls, timber beams, dark central door, tiny blue windows, narrow stone doorstep; cell2 matching cottage variant with muted slate teal tiled pitched roof, chimney, ochre plaster, door and flower box; cell3 large rounded oak tree with layered deep sage foliage and visible short twisted trunk, clear leaf clusters, not spherical gradient. ROW 2: cell1 small circular stone-ring campfire with firewood and little orange flame, view from above; cell2 small group of two wooden barrels and a crate with rolled cloth, compact; cell3 compact leafy flowering shrub with cream and pale amber wildflowers and a few small stones. Each object fully visible, no cropping, no surrounding scene. Pixel density equivalent to 64x64 or 96x96 original game props scaled up without blur. Cohesive with supplied cave sample; usable cutout assets, not illustrations.

### village_terrain

Production pixel-art tile atlas, EXACTLY 2 columns x 2 rows with NO gutters, NO lines, NO labels, NO border, 1024x1024 square canvas. Four equal square SEAMLESS texture tiles. Strict overhead flat terrain, not isometric, no horizon, no perspective. Fine 16-bit RPG hand-pixelled texture, clustered hard pixels, original each tile about 32x32 pixels enlarged cleanly. Muted sage and warm ochre palette to match a cozy classic JRPG village. TOP LEFT: muted sage green short meadow grass with sparse dark tufts, no big plants. TOP RIGHT: variation of same grass with a few tiny yellow wildflower specks and little stones. BOTTOM LEFT: warm sandy ochre packed-earth village footpath with sparse small tan pebbles, mostly calm flat surface, no grass. BOTTOM RIGHT: darker worn brown dirt path, tiny stone fragments, no grass. Keep pattern contrast LOW so actors remain readable. Each entire cell filled by its texture; individual tiles must tile seamlessly, all four share same pixel grid. No large cracks, no decorative central objects, no frames.

### village_cast

Production RPG CHARACTER ROTATION ATLAS matching the exact refined pixel-art chibi adventurer style of reference. Transparent RGBA, no ground or shadows, no labels, no grid lines, no weapons. EXACT 4 columns x 4 rows, 16 isolated full-body sprites, equally spaced square cells on 1536x1536 canvas. Every figure entirely inside cell with generous transparent gutters, feet on same baseline, same scale, crisp chunky pixel-art clusters as if original characters were 48 pixels tall enlarged with nearest neighbor, NO smooth illustration. Columns consistently SOUTH facing viewer, EAST facing right, NORTH facing away, WEST facing left. Row1 same HERO as reference: tousled chestnut hair, teal blue tunic, ochre gold shoulder cape, leather belt, dark trousers and brown boots, empty hands; same youthful face/head proportions and outfit as reference exactly. Row2 MOTHER: kind adult woman brown hair tied back, dusty mauve dress, cream apron, brown shoes, same stylized proportions as hero, relaxed empty hands. Row3 CHILD: young boy with short light brown hair, ochre yellow vest over cream shirt, dark shorts, brown shoes, visibly shorter at 75 percent adult height, same rendering style. Row4 KNIGHT: adult male with short dark hair and short beard, steel blue and muted silver armor, burgundy scarf and shoulder cloth, brown boots, no helmet, one forearm bandaged, empty hands no sword or shield. Every row depicts same identity in all four directions, no duplicates mistaken for views. All outfits have readable folds, material shading and clean silhouettes. No backgrounds, no extra accessories beyond described. Keep FOUR BY FOUR regular grid precisely.

