# 精细像素人物与矿洞样板

主游戏按 F6 进入样板间，Esc / F6 返回并保留原场景状态。
样板间：方向键移动；J 短剑连击 / 长矛按住蓄力；K 震地；Q 闪避；1 / 2 换武器；Z 1.5 倍近看。

人物使用 48×48 透明方向素材，保留蓝衣、赭金披肩、棕发和浮空武器。
四个正交方向接入主游戏。步态是 Godot 运行时分层位移，待机使用轻微呼吸；不是生成的逐帧走路序列。生成动画时 PixelLab 试用额度不足，未生成动画文件。

样板背景为 384×256 单张像素场景，有匹配的地面活动范围；暂不是可铺设的完整地形图集。木桩复用原战斗命中逻辑，用于验证攻击、反馈和武器比例，不代表新任务地图。

渲染改用 canvas_items，保持 320×224 逻辑坐标及原碰撞单位，在 960×672 窗口中保留素材像素细节。

## 素材来源

PixelLab 生成，2026-11-07。
- 人物 ID：6dd77654-f078-4d09-bdd5-9a08e1f8a157，48×48，8 方向，主游戏使用四向。
- 场景 job ID：3f3f64d9-535c-46dc-9025-37f0d115865a，384×256。
- 本地素材：assets/refined/hero/rotations/、assets/refined/mine_sample.png。

人物提示：Young fantasy explorer, tousled chestnut brown hair, short ochre gold shoulder cape, teal blue tunic, brown leather belt and small satchel, dark trousers, leather boots, empty hands no weapons, readable expressive face, refined handcrafted pixel art RPG sprite with restrained highlights and clean clustered shading, three head tall proportions.

场景提示：Top down orthographic RPG mine camp room, walkable wide central grey slate stone floor occupying middle two thirds, layered irregular blue slate cliff walls around edges, small ochre canvas tent and warm lantern at upper left, turquoise crystal cluster upper right, abandoned wooden cart and short rails left edge, dark cave crevices, no characters, no text no UI, refined 16 bit pixel art, crisp pixel clusters, muted teal navy and warm amber palette, flat overhead game map not isometric.

## 动画打磨

步态按实际位移推进，停止时平滑回到站姿；侧面补出遮挡的后腿，前后腿交替摆动，正背面抬脚并轻微缩短摆动腿。身体有落脚起伏，披肩下摆稍滞后。短剑两段攻击有相反的转身重心，长矛有蓄力后坐、直刺前倾与收势；命中停顿仍沿用战斗计时。浮空武器平滑跟随转向，收招返回身后。仍为运行时分层动画，未生成新的逐帧贴图。
