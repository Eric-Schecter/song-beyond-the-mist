# 四向翻滚

Q 闪避使用压低重心、蜷身、倒转、落地四帧动作。左右共用侧向图并正确镜像，上下各有一组图。武器保持独立浮空，滚动时添加轻微尘土。

沿用原来的 0.22 秒位移、1 秒冷却和无敌窗口；0.30 秒视觉动作末尾只表现起身，可被攻击打断。阴影以每帧最低实像素锚定地面，翻转不改变碰撞体。

- 素材：`assets/refined/hero/roll.png`，内置 ImageGen 生成，参考现有村庄角色图集，保留透明原图。
- 实现：`scripts/hero_roll.gd`。
- 验证/录制：`tests/record_roll.gd`，检查正常速度与慢动作四向翻滚、短剑/长矛浮空、冷却、接攻击与撞墙。
- 流程验证通过；已回看翻转、落地和左向镜像。录像：`recordings/hero-dodge-roll.mp4`。

## 生成提示词

Production refined pixel-art RPG dodge-roll animation sheet. EXACT 4 columns x 3 rows equal cells on transparent RGBA. Use ONLY the young male hero in the TOP ROW of supplied reference: tousled brown hair, teal tunic, ochre short cape, brown boots, same chibi proportions and crisp pixel clusters. NO weapons, no shadows, no floor, no text, generous gutters. Each row is the SAME character performing a forward somersault at four phases. Row1 facing EAST/right side view: column1 deeply crouched preparation leaning right hands forward; column2 compact tucked ball head down right shoulder touching ground, knees to chest; column3 upside down tucked somersault, rounded back contacting ground, boots above head, cape wrapped close; column4 low landing squat ready to stand facing right. Row2 facing SOUTH toward camera: column1 frontal deep crouch; column2 head tucked forward top of brown hair visible and shoulders forward; column3 upside down curled roll viewed from front, boots raised and rounded cape back below; column4 frontal low landing squat face visible. Row3 facing NORTH away camera: column1 back-facing deep crouch; column2 tucked roll with ochre cape rounding over back, head low; column3 tucked upside down somersault viewed from behind, brown boots up and cape against ground; column4 back-facing low landing squat. All poses fully contained, anatomically coherent with exactly two legs and two arms, cape stays short. Same character physical size across frames, crouching height about 60-75 percent of standing reference, actual rolled ball height 45-55 percent. No standing idle frames. Match reference colors and refined pixel shading. Transparent background.
