class_name Tuning
extends RefCounted
## Every movement and timing constant the sim uses, loaded from data/tuning.cfg.
##
## A property named `<section>_<key>` holds the value of `key` under
## `[section]` in the file. Treat a Tuning as immutable: use with_values() to
## get a changed copy.

const DEFAULT_PATH := "res://data/tuning.cfg"

var match_countdown_ticks: int
var famine_countdown_ticks: int
var worker_max_speed: int
var worker_run_accel: int
var worker_run_decel: int
var worker_width: int
var worker_height: int
var worker_gravity: int
var worker_max_fall_speed: int
var worker_jump_speed: int
var worker_jump_release_speed: int
var worker_coyote_ticks: int
var worker_springboard_jump_speed: int
var worker_springboard_ticks: int
var bump_speed: int
var bump_ticks: int
var ceiling_stick_ticks: int
var ceiling_ricochet_threshold: int
var ceiling_speed_ricochet_threshold: int
var ceiling_ricochet_speed: int
var winged_width: int
var winged_height: int
var winged_gravity: int
var winged_max_fall_speed: int
var winged_flap_impulse: int
var winged_max_rise_speed: int
var winged_walk_speed_ratio: int
var winged_air_brake_flaps: int
var winged_air_brake_ticks: int
var queen_dive_gravity: int
var queen_dive_max_fall_speed: int
var respawn_ticks: int
var respawn_invulnerable_ticks: int
var respawn_queen_ticks: int
var joust_height_margin: int
var berry_size: int
var berry_gravity: int
var berry_max_fall_speed: int
var berry_friction: int
var berry_kick_speed: int
var berry_kick_lift: int
var snail_speed: int
var snail_speed_rider_ratio: int
var snail_eat_ticks: int
var snail_speed_rider_eat_ticks: int
var snail_width: int
var snail_height: int
var speed_ratio: int
var gate_width: int
var gate_height: int
var gate_hold_ticks: int
var gate_locked_ticks: int
var gate_invulnerable_ticks: int


static func load_default() -> Tuning:
	return load_file(DEFAULT_PATH)


static func load_file(path: String) -> Tuning:
	var cfg := ConfigFile.new()
	var err := cfg.load(path)
	assert(err == OK, "Could not load tuning file %s (error %d)" % [path, err])
	return from_config(cfg)


static func from_config(cfg: ConfigFile) -> Tuning:
	var values := {}
	for section in cfg.get_sections():
		for key in cfg.get_section_keys(section):
			values["%s_%s" % [section, key]] = cfg.get_value(section, key)
	return from_values(values)


## A Tuning from every constant's value, by property name (as values()
## gives them).
static func from_values(values: Dictionary) -> Tuning:
	var tuning := Tuning.new()
	tuning._apply(values)
	var missing := tuning.names().filter(func(n: String) -> bool: return not values.has(n))
	assert(missing.is_empty(), "Tuning is missing: %s" % ", ".join(missing))
	return tuning


## Every constant's value, by property name.
func values() -> Dictionary:
	var result := {}
	for n in names():
		result[n] = get(n)
	return result


## Names of every constant, in declaration order.
func names() -> Array[String]:
	var result: Array[String] = []
	for prop in get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			result.append(prop.name)
	return result


## A copy of this Tuning with some constants replaced.
func with_values(overrides: Dictionary) -> Tuning:
	var copy := Tuning.new()
	for n in names():
		copy.set(n, get(n))
	copy._apply(overrides)
	return copy


func _apply(values: Dictionary) -> void:
	var known := names()
	for n in values:
		assert(n in known, "Unknown tuning constant: %s" % n)
		assert(typeof(values[n]) == TYPE_INT, "Tuning constant %s must be an integer" % n)
		set(n, values[n])
