# Godot AI Agent Team Rules

本文件是本 Godot 项目的根级协作规范，供三名开发成员及其 AI Agent
共同遵守。它同时约束代码结构、命名、场景编辑、Git 协作、验证和交付。

第三方插件目录 `addons/` 不应用本项目代码风格，也不得在没有明确任务时
修改。

## 1. 指令与规则优先级

执行任务时依次遵循：

1. 用户在当前任务中的明确要求。
2. 目标文件所在目录及其父目录中最近的 `AGENTS.md`。
3. 本文件。
4. 当前任务适用的 Skill。
5. 项目已有且仍然有效的实现约定。

规则冲突时采用更具体、优先级更高的规则。会显著影响功能、数据或项目
结构的歧义必须先确认，不得擅自扩大任务范围。

Godot 代码任务同时使用：

```text
.agents/skills/godot-project-conventions/SKILL.md
```

## 2. 三人协作方式

每项任务必须有一名明确的负责人。负责人负责实现、验证和提交；另外两名
成员中至少一人负责评审。

### 2.1 任务认领

- 开始任务前在小组任务板或聊天中声明修改范围。
- 声明将修改的主要场景、脚本和公共接口。
- 同一时间一个 `.tscn` 场景只由一人负责编辑。
- 如果两项工作需要修改同一场景，先拆出子场景或约定编辑顺序。
- 不在其他成员负责的文件中顺手重构无关代码。

### 2.2 分支命名

使用以下分支前缀：

```text
feature/map-building-layer
fix/favorite-marker
refactor/ui-components
docs/agent-rules
chore/project-settings
```

- `feature/`：新增功能。
- `fix/`：修复缺陷。
- `refactor/`：不改变行为的结构调整。
- `docs/`：文档和规范。
- `chore/`：配置、构建和维护工作。

除非三人明确同意，不直接在 `main` 上开发。

### 2.3 提交与评审

- 一个提交只表达一个清晰目的。
- 提交前检查 `git status` 和实际差异。
- 提交信息使用简短动词句，例如：

```text
Add reusable building layer
Fix favorite state persistence
Refactor shop detail UI
```

- 合并前至少由一名其他成员评审。
- 公共接口、Autoload、`project.godot`、主场景和数据格式的修改必须在
  合并请求中明确说明。
- 未经共同确认，不强制推送、不重写共享分支历史。

## 3. 固定目录结构

当前项目使用以下顶层目录。路径大小写必须保持完全一致，因为导出到部分
平台后资源路径区分大小写：

```text
res://
├── Data/       领域数据、数据查询、本地状态与持久化
├── scenes/     游戏场景、地图场景和运行时组件
├── Ui/         UI 场景、UI 脚本和 UI 主题
├── global/     真正需要跨系统共享的常量或服务
├── addons/     第三方插件，不随意修改
└── project.godot
```

约束：

- 不再创建 `Sence/`、`UI/`、`data/` 等拼写或大小写变体。
- 新的子目录统一使用 `snake_case`。
- 新脚本和场景不要散落在项目根目录。
- 已有目录的整体重命名必须作为独立任务，由三人共同确认。
- 删除或移动资源前必须检查所有 `res://` 引用。

## 4. Data、Scene、UI 与 Global 分层

### 4.1 Data 层

`Data/` 负责：

- 店铺、地图、分类等领域数据。
- 数据读取、过滤、查询和格式转换。
- 收藏、拉黑、留言等用户状态。
- 本地保存和恢复。

Data 层不得：

- 创建或操作 UI 控件。
- 直接绘制地图。
- 保存只属于某个 UI 组件的临时视觉状态。

### 4.2 Scene 层

`scenes/` 负责运行时世界和视觉场景，例如：

- 地图主体。
- 水系、道路、建筑、地标等地图图层。
- 根据 Data 数据生成的店铺 Marker。
- 场景内交互、缩放、拖动和节点生命周期。

地图必须保持组件化：

```text
scenes/map/
├── hangzhou_map.tscn
├── shop_marker.tscn
└── layers/
    ├── water_layer.tscn
    ├── road_layer.tscn
    ├── building_layer.tscn
    ├── landmark_layer.tscn
    └── label_layer.tscn
```

美术素材替换应局限在对应图层或组件，不要求改动主地图协调逻辑。

### 4.3 UI 层

`Ui/` 负责浮于游戏场景上方的界面，例如：

- 搜索框。
- 分类筛选。
- 店铺详情。
- 收藏、拉黑、留言操作。
- 导出入口和提示信息。

UI 只负责展示状态和发出用户意图，不拥有店铺数据和用户持久化数据。
可复用、有独立状态或独立视觉生命周期的 UI 必须拆成单独场景。

### 4.4 Global 层

修改功能前先检查 `global/` 和 `project.godot` 中的 Autoload。

- 有语义一致的全局常量或信号时优先复用。
- 没有适合的全局内容时保持局部，不强行全局化。
- 店铺名称、组件状态、临时选择和页面状态不得放入全局。
- 全局常量必须稳定、跨模块共享且具有项目级意义。
- 新增 Autoload 必须经过小组评审。

## 5. 主场景与组件职责

- `scenes/main.gd` 只负责组装模块、连接信号和层间协调。
- 主场景不得保存完整业务数据。
- 主场景不得实现全部地图绘制或全部 UI 构建。
- 父节点可以协调子组件，但不能复制子组件内部逻辑。
- 不允许通过很深的节点路径跨层操作组件内部节点。
- 相邻父子组件可以使用直接引用。
- 独立组件之间优先使用信号或稳定的公开 API。

当脚本同时负责数据、绘制、输入、持久化和 UI 时，必须拆分。

## 6. 文件与资源命名

### 6.1 文件和目录

统一使用 `snake_case`：

```text
shop_detail.gd
shop_detail.tscn
map_data.gd
ui_theme.tres
building_layer/
```

同一个组件的场景和脚本保持同名：

```text
shop_marker.tscn
shop_marker.gd
```

资源后缀：

- 场景：`.tscn`
- GDScript：`.gd`
- Theme/Resource：`.tres`
- Shader：`.gdshader`
- 图片和音频：使用可读的 `snake_case` 文件名

不要使用：

- 空格。
- 中文文件名。
- `NewNode2D`、`test2`、`final_final` 等临时名称。
- 仅靠数字区分的无语义文件名。

### 6.2 场景节点

节点名使用 `PascalCase`：

```text
HangzhouMap
MarkerLayer
ShopDetail
SearchInput
FavoriteButton
```

- 节点名表达职责，不表达当前外观。
- 被脚本通过路径引用的节点不可随意改名。
- 重命名节点后必须检查所有 `$NodePath`、`%UniqueNode` 和动画轨道。

### 6.3 `class_name`

自定义全局类名使用 `PascalCase`：

```gdscript
class_name ShopRecord
class_name MapLayerBase
```

只有需要被多个脚本按类型引用的类才声明 `class_name`，不要给每个脚本
都创建全局类名。

## 7. GDScript 命名规范

### 7.1 变量

普通变量、参数和属性使用 `snake_case`：

```gdscript
var selected_shop_id := ""
var active_category := ""
func _find_shop(shop_id: String) -> Dictionary:
```

布尔变量使用明确前缀：

```gdscript
is_favorite
has_comments
can_export
should_show_marker
```

集合使用复数形式：

```gdscript
shops
comments
favorite_ids
```

稳定标识符统一使用 `_id` 后缀：

```gdscript
shop_id
district_id
selected_shop_id
```

### 7.2 常量

常量使用 `SCREAMING_SNAKE_CASE`：

```gdscript
const SAVE_PATH := "user://traditional_food_map_data.json"
const MARKER_SCENE := preload("res://scenes/map/shop_marker.tscn")
const DETAIL_ZOOM_THRESHOLD := 1.18
```

### 7.3 枚举

枚举类型使用 `PascalCase`，枚举值使用 `SCREAMING_SNAKE_CASE`：

```gdscript
enum ShopState {
	NORMAL,
	FAVORITE,
	BLOCKED,
}
```

### 7.4 信号

信号使用 `snake_case`，名称描述已经发生的事件或明确的请求：

```gdscript
signal shop_selected(shop_id: String)
signal state_changed(shop_id: String)
signal export_requested
signal comment_submitted(text: String)
```

- 信号必须声明参数类型。
- 组件拥有的事件使用本地信号。
- 只有跨独立系统且项目已有相同模式时才使用全局信号。
- 不使用含义模糊的 `updated`、`clicked_event`、`do_action`。

### 7.5 对外函数

有意提供给其他脚本调用的公开函数使用 `PascalCase`，并在上一行添加
`##` 文档注释：

```gdscript
## Shows one shop and refreshes the visible user state.
func ShowShop(shop: Dictionary, favorite: bool, blocked: bool) -> void:
	pass
```

注释应说明：

- 函数对外提供什么能力。
- 重要参数和返回值。
- 非显而易见的副作用或前置条件。

### 7.6 内部函数

仅脚本内部使用的函数采用 `_snake_case`：

```gdscript
func _refresh_markers() -> void:
	pass

func _save_state() -> void:
	pass
```

Godot 生命周期和虚方法保留引擎规定名称：

```gdscript
func _ready() -> void:
func _process(delta: float) -> void:
func _input(event: InputEvent) -> void:
func _draw() -> void:
```

### 7.7 类型

- 新代码尽量声明参数、返回值和成员类型。
- 不使用无法判断内容的裸 `Array` 或 `Dictionary`，能够明确时写成
  `Array[Dictionary]`、`Array[String]` 等。
- 接收可为空的节点前先检查有效性。
- 不通过字符串猜测节点类型或业务状态。

## 8. 场景、资源与 UID 协作

- 场景优先通过 Godot 编辑器编辑。
- 手工修改 `.tscn` 后必须让 Godot 重新加载并验证。
- `.tscn` 冲突不得直接选择整份 “ours” 或 “theirs”，应逐节点合并。
- 不手工修改 `.uid` 文件内容。
- 不删除仍被资源引用的 `.uid` 文件。
- 不提交 `.godot/`、本地缓存、日志和导出产物。
- 资源移动后检查编辑器中的缺失依赖。
- `project.godot` 的 Autoload、输入映射、渲染和窗口配置属于共享配置，
  修改前应通知另外两名成员。
- 插件升级必须单独提交，不能与业务功能混在一起。

## 9. UI 规范

- 游戏世界放在 Scene 层，界面放在 `CanvasLayer` 或等效 UI 根节点中。
- UI 使用统一 Theme，不在多个组件中复制同一套颜色和 StyleBox。
- UI 组件应适配手机和桌面窗口尺寸。
- 不依赖固定分辨率或只在当前电脑正常的绝对坐标。
- 可点击区域要足够大，文字与背景保持可读对比度。
- UI 不直接写入业务数据，应调用 Data 层 API 或发出信号。
- 弹窗和详情页关闭后应清理选择状态和临时输入。

## 10. 数据与本地保存

- 店铺、地图和用户状态从 Data 层读取。
- 收藏、拉黑和留言变更后自动保存，不增加多余保存按钮。
- 本地用户数据保存到 `user://`，不得写入 `res://`。
- 保存文件必须兼容缺失字段和无效旧数据。
- 读取外部数据时进行类型和字段校验。
- 不把本地用户保存文件提交到 Git。
- 数据格式变化时提供迁移或向后兼容策略。

## 11. 修改和安全边界

- 只修改完成当前任务所需文件。
- 不覆盖或撤销其他成员的未提交修改。
- 不使用 `git reset --hard`、强制检出等破坏性命令。
- 删除或移动文件前检查绝对路径和资源引用。
- 不在代码、配置、日志或提交中保存 API Key、密码、Token 或私钥。
- 密钥使用环境变量、本地忽略配置或系统密钥存储。
- 推送公开仓库前检查敏感信息和不应公开的本地文件。

## 12. 验证要求

修改后按任务风险执行：

1. 检查 `git diff --check`。
2. 使用 Godot 重新导入或解析修改过的脚本和场景。
3. 启动最相关的主场景或测试场景。
4. 验证桌面尺寸和手机尺寸下的主要交互。
5. 检查 Output 中由本次修改引入的错误和警告。
6. 验证收藏、拉黑、留言和本地恢复等关键状态。
7. 确认没有临时场景、测试脚本或生成文件进入提交。

不能完整验证时，必须在交付说明中列出未验证项及原因。不得删除测试或
忽略错误来伪造通过。

## 13. AI Agent 沟通规范

- 开始修改前说明准备检查和修改的范围。
- 长任务定期报告完成内容、当前步骤和发现的问题。
- 事实和推测必须明确区分。
- 不要求成员重复提供仓库中可以直接读取的信息。
- 遇到冲突或阻塞时说明原因、已尝试方案和需要的决定。
- 最终回复说明修改文件、功能结果、验证结果和剩余限制。
- 未运行成功的内容不能宣称已经完成。

## 14. 工具断线重连

当工具、Godot 编辑器桥接或 MCP 连接出现临时断线时：

- 等待 20 秒后重新连接。
- 如果仍然失败，继续每隔 20 秒重试。
- 一直重试到连接恢复。
- 不因单次连接失败停止任务。
- 等待期间继续完成不依赖该连接的安全工作。

此规则只约束本项目内的 Agent 行为，不改变工具自身的服务级重试机制。

## 15. 完成交付清单

交付前确认：

1. 任务负责人和修改范围明确。
2. Data、Scene、UI 和 Global 职责没有混淆。
3. 命名符合本文件规范。
4. 主入口没有吸收组件内部实现。
5. 没有重复创建已有常量、信号、服务或组件。
6. 没有覆盖其他成员的修改。
7. Godot 脚本、场景和资源引用已验证。
8. 没有提交缓存、临时文件、用户数据或密钥。
9. 公共接口和共享配置变更已在评审中说明。
10. 最终说明与实际完成和验证状态一致。
