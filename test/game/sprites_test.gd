extends GdUnitTestSuite
## Character sprites: every look and pose has its own readable picture, sized
## to its character's collider, in its Team's colour with its Seat's marking.
## Driven only through Sprites.image, with Poses made by hand.

const BLUE := Color("2f6fdf")
const GOLD := Color("e8b020")

const Look := Pose.Look
const Action := Pose.Action
const WORKER_LOOKS := [Pose.Look.WORKER, Pose.Look.SPEED_WORKER]
const WINGED_LOOKS := [Pose.Look.WARRIOR, Pose.Look.SPEED_WARRIOR, Pose.Look.QUEEN]


func test_every_sprite_is_its_characters_collider_with_its_feet_on_the_bottom_row() -> void:
	var t := Tuning.load_default()
	var px := 2000
	for look: Look in WORKER_LOOKS + WINGED_LOOKS:
		var winged: bool = look in WINGED_LOOKS
		var collider := Vector2i(t.winged_width, t.winged_height) if winged \
			else Vector2i(t.worker_width, t.worker_height)
		for pose in _poses(look):
			var img := Sprites.image(pose, BLUE, 1)
			assert_vector(img.get_size()).override_failure_message("%s is %s" % [_name(pose), img.get_size()]) \
				.is_equal(collider / px)
		var standing := Sprites.image(_pose(look, Action.STAND), BLUE, 1).get_used_rect()
		assert_int(standing.end.y).is_equal(collider.y / px)


func test_every_look_and_pose_has_its_own_picture() -> void:
	for look: Look in WORKER_LOOKS + WINGED_LOOKS:
		var seen := {}
		for pose in _poses(look):
			var data := Sprites.image(pose, BLUE, 1).get_data()
			assert_bool(seen.has(data)).override_failure_message(
				"%s looks like %s" % [_name(pose), seen.get(data, "")]).is_false()
			seen[data] = _name(pose)
	# Each look differs from every other in the same pose.
	var standing := {}
	for look: Look in WORKER_LOOKS + WINGED_LOOKS:
		standing[Sprites.image(_pose(look, Action.STAND), BLUE, 1).get_data()] = true
	assert_int(standing.size()).is_equal(5)


func test_each_worker_seat_has_its_own_marking_and_each_team_its_colour() -> void:
	for look: Look in [Look.WORKER, Look.SPEED_WORKER, Look.WARRIOR, Look.SPEED_WARRIOR]:
		var marked := {}
		for place in range(1, 5):
			marked[Sprites.image(_pose(look, Action.STAND), BLUE, place).get_data()] = place
		assert_int(marked.size()).override_failure_message("%s markings" % Look.keys()[look]).is_equal(4)
	# The markings differ in colour as well as shape.
	var colours := {}
	for place in range(1, 5):
		colours[_colours(Sprites.image(_pose(Look.WORKER, Action.STAND), BLUE, place))] = place
	assert_int(colours.size()).is_equal(4)
	for look: Look in WORKER_LOOKS + WINGED_LOOKS:
		var pose := _pose(look, Action.STAND)
		assert_bool(Sprites.image(pose, BLUE, 1).get_data() == Sprites.image(pose, GOLD, 1).get_data()).is_false()


func test_wings_spread_to_glide_and_a_dive_tucks_them_and_points_the_legs_down() -> void:
	for look: Look in WINGED_LOOKS:
		var standing := Sprites.image(_pose(look, Action.STAND), BLUE, 1).get_used_rect()
		var gliding := Sprites.image(_pose(look, Action.GLIDE), BLUE, 1).get_used_rect()
		var diving := Sprites.image(_pose(look, Action.DIVE), BLUE, 1).get_used_rect()
		assert_int(gliding.size.x).is_greater(standing.size.x)
		assert_int(diving.size.x).is_less(gliding.size.x)
		# Gliding legs trail; diving ones reach straight down to the bottom row.
		assert_int(gliding.end.y).is_less(standing.end.y)
		assert_int(diving.end.y).is_equal(standing.end.y)


## Every pose a character of `look` takes: each action it can do, every frame
## of it, and carrying a Berry where a Worker can.
func _poses(look: Look) -> Array[Pose]:
	var poses: Array[Pose] = []
	if look in WINGED_LOOKS:
		poses.append(_pose(look, Action.STAND))
		for frame in Pose.RUN_FRAMES:
			poses.append(_pose(look, Action.RUN, frame))
		poses.append_array([_pose(look, Action.FLAP, 0), _pose(look, Action.FLAP, 1), _pose(look, Action.GLIDE),
			_pose(look, Action.DIVE)])
		return poses
	for carrying in [false, true]:
		poses.append(_pose(look, Action.STAND, 0, carrying))
		for frame in Pose.RUN_FRAMES:
			poses.append(_pose(look, Action.RUN, frame, carrying))
		poses.append_array([_pose(look, Action.JUMP, 0, carrying), _pose(look, Action.FALL, 0, carrying)])
	poses.append_array([_pose(look, Action.HOLD_UP, 0, true), _pose(look, Action.RIDE), _pose(look, Action.EAT, 0),
		_pose(look, Action.EAT, 1), _pose(look, Action.EATEN)])
	return poses


func _pose(look: Look, action: Action, frame := 0, carrying := false) -> Pose:
	var pose := Pose.new()
	pose.look = look
	pose.action = action
	pose.frame = frame
	pose.carrying = carrying
	return pose


## The colours `img` uses, sorted, as text.
func _colours(img: Image) -> String:
	var seen := {}
	for y in img.get_height():
		for x in img.get_width():
			seen[img.get_pixel(x, y).to_html()] = true
	var keys := seen.keys()
	keys.sort()
	return ",".join(keys)


func _name(pose: Pose) -> String:
	return "%s %s %d%s" % [Look.keys()[pose.look], Action.keys()[pose.action], pose.frame,
		" carrying" if pose.carrying else ""]
