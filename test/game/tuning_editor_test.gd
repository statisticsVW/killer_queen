extends GdUnitTestSuite
## Dev builds' live tuning editor: a panel, opened by its key, that picks a
## constant and steps its value up or down. Its edits go to the Match in the
## next tick's input, and can be written back into the tuning file with its
## comments kept. Driven only through TuningEditor's keys, shown(), take() and
## rewrite().

var _file: Tuning


func before_test() -> void:
	_file = Tuning.load_default()


func test_a_normal_build_ignores_every_editor_key() -> void:
	var editor := TuningEditor.of(false)
	for key in [TuningEditor.OPEN_KEY, TuningEditor.NEXT_KEY, TuningEditor.PREVIOUS_KEY, KEY_EQUAL, KEY_MINUS]:
		assert_bool(editor.key(key, false, _file)).is_false()

	assert_bool(editor.open).is_false()
	assert_object(editor.take()).is_null()


func test_the_open_key_opens_and_closes_the_panel_which_takes_its_keys_only_while_open() -> void:
	var editor := TuningEditor.of(true)
	assert_bool(editor.key(KEY_EQUAL, false, _file)).is_false()
	assert_bool(editor.key(TuningEditor.NEXT_KEY, false, _file)).is_false()

	assert_bool(editor.key(TuningEditor.OPEN_KEY, false, _file)).is_true()
	assert_bool(editor.open).is_true()
	assert_bool(editor.key(TuningEditor.NEXT_KEY, false, _file)).is_true()
	assert_bool(editor.key(KEY_SPACE, false, _file)).is_false()
	editor.key(TuningEditor.OPEN_KEY, false, _file)
	assert_bool(editor.open).is_false()
	assert_object(editor.take()).is_null()


func test_page_keys_pick_each_constant_in_the_tuning_files_order_and_wrap_round() -> void:
	var editor := _opened()
	var names := _file.names()
	assert_str(editor.selected_name()).is_equal(names[0])

	editor.key(TuningEditor.NEXT_KEY, false, _file)
	editor.key(TuningEditor.NEXT_KEY, false, _file)
	assert_str(editor.selected_name()).is_equal(names[2])
	editor.key(TuningEditor.PREVIOUS_KEY, false, _file)
	assert_str(editor.selected_name()).is_equal(names[1])
	editor.key(TuningEditor.PREVIOUS_KEY, false, _file)
	editor.key(TuningEditor.PREVIOUS_KEY, false, _file)
	assert_str(editor.selected_name()).is_equal(names[-1])
	assert_int(editor.selected).is_equal(names.size() - 1)
	editor.key(TuningEditor.NEXT_KEY, false, _file)
	assert_str(editor.selected_name()).is_equal(names[0])


func test_plus_raises_the_picked_constant_by_its_step_for_the_next_tick_only() -> void:
	var editor := _opened_at("worker_max_speed")
	var speed := _file.worker_max_speed

	assert_bool(editor.key(KEY_EQUAL, false, _file)).is_true()

	var step := TuningEditor.step_for(speed)
	assert_int(editor.shown(_file).worker_max_speed).is_equal(speed + step)
	var change := editor.take()
	var expected := _file.values()
	expected.worker_max_speed = speed + step
	assert_dict(change.values()).is_equal(expected)
	# Taken once: the Match has it from then on.
	assert_object(editor.take()).is_null()
	assert_int(editor.shown(change).worker_max_speed).is_equal(speed + step)


func test_minus_lowers_it_and_shift_moves_ten_steps_but_never_below_zero() -> void:
	var editor := _opened_at("worker_gravity")
	var gravity := _file.worker_gravity
	var step := TuningEditor.step_for(gravity)

	editor.key(KEY_MINUS, false, _file)
	assert_int(editor.shown(_file).worker_gravity).is_equal(gravity - step)
	editor.key(KEY_KP_ADD, true, _file)
	assert_int(editor.shown(_file).worker_gravity).is_equal(gravity - step + 10 * step)
	for press in 20:
		editor.key(KEY_KP_SUBTRACT, true, _file)
	assert_int(editor.shown(_file).worker_gravity).is_equal(0)


func test_edits_before_the_next_tick_add_up_on_the_matchs_current_tuning() -> void:
	var editor := _opened_at("worker_max_speed")
	# The Match's tuning, already changed from the file's.
	var current := _file.with_values({"worker_gravity": 700})

	editor.key(KEY_EQUAL, false, current)
	editor.key(TuningEditor.NEXT_KEY, false, current)
	editor.key(KEY_EQUAL, false, current)

	var change := editor.take()
	var names := _file.names()
	var next_name := names[names.find("worker_max_speed") + 1]
	assert_int(change.worker_gravity).is_equal(700)
	assert_int(change.worker_max_speed).is_equal(_file.worker_max_speed + TuningEditor.step_for(_file.worker_max_speed))
	assert_int(change.get(next_name)).is_equal(_file.get(next_name) + TuningEditor.step_for(_file.get(next_name)))


func test_a_constants_step_is_a_power_of_ten_between_a_hundredth_and_a_tenth_of_its_value() -> void:
	var steps := {0: 1, 1: 1, 25: 1, 99: 1, 100: 10, 500: 10, 999: 10, 5000: 100, 12500: 1000, 100000: 10000}
	for value in steps:
		assert_int(TuningEditor.step_for(value)).override_failure_message(str(value)).is_equal(steps[value])


func test_rewriting_the_tuning_file_changes_only_the_values_and_keeps_every_comment() -> void:
	var text := FileAccess.get_file_as_string(Tuning.DEFAULT_PATH)
	assert_str(TuningEditor.rewrite(text, _file)).is_equal(text)

	var edited := _file.with_values({"worker_max_speed": 6100, "winged_gravity": 1, "bot_hard_mistake_percent": 3})
	var rewritten := TuningEditor.rewrite(text, edited)

	var cfg := ConfigFile.new()
	assert_int(cfg.parse(rewritten)).is_equal(OK)
	assert_dict(Tuning.from_config(cfg).values()).is_equal(edited.values())
	var before := text.split("\n")
	var after := rewritten.split("\n")
	assert_int(after.size()).is_equal(before.size())
	var changed := []
	for i in before.size():
		if before[i] != after[i]:
			changed.append(after[i])
	assert_array(changed).contains_exactly_in_any_order(
		["max_speed=6100", "gravity=1", "hard_mistake_percent=3"])


func _opened() -> TuningEditor:
	var editor := TuningEditor.of(true)
	editor.key(TuningEditor.OPEN_KEY, false, _file)
	return editor


## An open editor with `name` picked.
func _opened_at(name: String) -> TuningEditor:
	var editor := _opened()
	for press in _file.names().size():
		if editor.selected_name() == name:
			break
		editor.key(TuningEditor.NEXT_KEY, false, _file)
	assert_str(editor.selected_name()).is_equal(name)
	return editor
