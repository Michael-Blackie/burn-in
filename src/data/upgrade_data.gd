class_name UpgradeData
extends Resource

enum Currency { ASH, PAGES }
enum Stat { ASH_MULTI, BRUSH_SIZE, AUTO_RATE, DRAG_ERASE, ASH_FACTOR }   # ASH_FACTOR multiplies, ASH_MULTI adds

@export var id: StringName
@export var display_name: String
@export var currency: Currency = Currency.ASH
@export var base_cost: float = 10
@export var cost_growth: float = 1.15   # each level costs 15% more
@export var max_level: int = 0          # 0 = unlimited, 1 = one-off unlock
@export var stat: Stat
@export var value_per_level: float = 1.0
@export var requires_pages: int = 0   # stays locked until this many pages burned
@export_multiline var description: String   # flavour line shown in the tooltip

func cost(level: int) -> float:
	return floor(base_cost * pow(cost_growth, level))

## What one level does, for the tooltip.
func effect_text() -> String:
	match stat:
		Stat.ASH_MULTI:  return "+%d%% ash per pixel" % roundi(value_per_level * 100)
		Stat.BRUSH_SIZE: return "+%d brush size" % int(value_per_level)
		Stat.AUTO_RATE:  return "Burns %s pixels/s on its own" % NumFormat.rate(value_per_level)
		Stat.DRAG_ERASE: return "Hold and drag to burn"
		Stat.ASH_FACTOR: return "x%s all ash" % NumFormat.rate(value_per_level)
	return ""

## The total this upgrade gives at a level, e.g. "+40%". Empty for on/off upgrades.
func total_text(level: int) -> String:
	match stat:
		Stat.ASH_MULTI:  return "+%d%%" % roundi(value_per_level * level * 100)
		Stat.BRUSH_SIZE: return "+%d" % (int(value_per_level) * level)
		Stat.AUTO_RATE:  return "%s/s" % NumFormat.rate(value_per_level * level)
		Stat.ASH_FACTOR: return "x%s" % NumFormat.rate(pow(value_per_level, level))
	return ""