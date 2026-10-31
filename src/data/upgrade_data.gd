class_name UpgradeData
extends Resource

enum Currency { ASH, PAGES }
enum Stat { ASH_MULTI, BRUSH_SIZE, AUTO_RATE, DRAG_ERASE }

@export var id: StringName
@export var display_name: String
@export var currency: Currency = Currency.ASH
@export var base_cost: float = 10
@export var cost_growth: float = 1.15   # each level costs 15% more
@export var max_level: int = 0          # 0 = unlimited, 1 = one-off unlock
@export var stat: Stat
@export var value_per_level: float = 1.0
@export var requires_pages: int = 0   # stays locked until this many pages burned

func cost(level: int) -> float:
	return floor(base_cost * pow(cost_growth, level))