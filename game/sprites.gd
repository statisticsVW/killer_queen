class_name Sprites
extends RefCounted
## Placeholder character sprites, original to this project: humanoid bees
## drawn below as text, one character per art pixel (a logical 960x540
## pixel), in parts layered by Pose and coloured by Team, upgrade and Seat.
## Each sprite faces right and is exactly its character's collider; draw it
## mirrored to face left.
##
## Palette: k outline, T Team colour, t its shade, L its light, s stripe
## (white on Speed characters), w white, Q and W wing edge and wing, c and C
## crown, r sword, m the Seat's marking. '.' is transparent.

## Sprite sizes in art pixels: the Worker and winged colliders.
const WORKER_SIZE := Vector2i(16, 20)
const WINGED_SIZE := Vector2i(20, 24)

const OUTLINE := Color("1b1426")
const STRIPE := Color("241c1c")
const SPEED_STRIPE := Color("f4f4f4")
const WING := Color(0.92, 0.97, 1.0)
const WING_EDGE := Color("8aa4bf")
const CROWN := Color("ffd23f")
const CROWN_SHADE := Color("b8860b")
const SWORD := Color("dfe6ee")
## Each Worker Seat's marking colour, by its place in its Team (1-4). The
## marking's shape is its hat (HATS).
const MARKINGS := [Color.WHITE, Color("e04848"), Color("48c048"), Color("f4f4f4"), Color("40d8e0")]

## Each part: the art-pixel row and column of its top-left, then its rows.

const HEAD := [4, 0, [
	"......kkkk",
	".....kLLLLk",
	".....kLLwkk",
	".....kLLwkk",
	".....kLLLLk",
	"......kkkk"]]
const HEAD_HURT := [4, 0, [
	"......kkkk",
	".....kLLLLk",
	".....kLLkLk",
	".....kLLLkk",
	".....kLLLLk",
	"......kkkk"]]

const WORKER_TORSO := [10, 0, [
	"......kTTk",
	"....kTTTTTTk",
	"...kssssssssk",
	"...kTTTTTTTTk",
	"...kssssssssk",
	"....kTTTTTTk"]]
const WORKER_ARMS_DOWN := [11, 0, [
	"..k..........k",
	"..k..........k",
	"..k..........k"]]
const WORKER_ARMS_UP := [2, 0, [
	"...k........k",
	"...k........k",
	"...k........k",
	"...k........k",
	"...k........k",
	"...k........k",
	"...k........k",
	"...k........k",
	"...k........k"]]
const WORKER_ARMS_FORWARD := [11, 0, [
	"..k..........kkk",
	"..k"]]
const WORKER_LEGS_STAND := [16, 0, [
	"......k..k",
	"......k..k",
	"......k..k",
	".....kk..kk"]]
const WORKER_LEGS_RUN := [
	[16, 0, [
		"......k..k",
		".....k....k",
		"....k......k",
		"...kk......kk"]],
	[16, 0, [
		"......k..k",
		"......k..kkk",
		"......k",
		".....kk"]],
	[16, 0, [
		"......k..k",
		"......k...k",
		".....k.....k",
		"....kk.....kk"]],
	[16, 0, [
		"......k..k",
		"....kkk..k",
		".........k",
		".........kk"]],
]
const WORKER_LEGS_JUMP := [16, 0, [
	".....kk..kk",
	"....k....k"]]
const WORKER_LEGS_FALL := [16, 0, [
	"......k..k",
	".....k....k",
	".....k....k"]]
const WORKER_LEGS_TIPTOE := [16, 0, [
	"......kkkk",
	".......kk",
	".......kk",
	".......kk"]]
const WORKER_LEGS_SIT := [16, 0, [
	"......kkkk",
	"......kkkkkk",
	"...........k",
	"...........kk"]]

## Each Worker Seat's hat, by its place in its Team (1-4), on a Worker's head.
const HATS := [
	[0, 0, []],
	[1, 0, [
		".....m....m",
		"......k..k",
		"......k..k"]],
	[2, 0, [
		"......mmmm",
		".....mmmmmmmm"]],
	[1, 0, [
		"........m",
		"......mmmm",
		".....mmmmmm"]],
	[4, 0, [
		"...m",
		"...mmmmmmmm",
		"...m"]],
]

## Winged characters' heads and hats are a Worker's, two pixels further right.
const WINGED_OFFSET := 2

const WINGED_TORSO := [10, 0, [
	"........kTTk",
	".......kTTTTk",
	"......kTTTTTTk",
	"......kssssssk",
	"......kTTTTTTk",
	"......kssssssk",
	".......kTTTTk",
	"........kTTk"]]
const QUEEN_STINGER := [17, 0, [
	".....kk",
	"....k"]]
const QUEEN_CROWN := [1, 0, [
	".......c.cc.c",
	".......cccccc",
	".......cCcCcc"]]
const WARRIOR_HELMET := [3, 0, [
	"........tttt",
	".......tttttt",
	".......t....t"]]
const WINGED_ARMS := [11, 0, [
	".....k........k",
	".....k........k",
	".....k........k"]]
const WARRIOR_ARMS := [11, 0, [
	".....k........k",
	".....k........krrrrr",
	".....k"]]
const WINGED_LEGS_STAND := [18, 0, [
	"........k..k",
	"........k..k",
	"........k..k",
	"........k..k",
	"........k..k",
	".......kk..kk"]]
const WINGED_LEGS_WALK := [
	[18, 0, [
		"........k..k",
		"........k..k",
		".......k....k",
		"......k......k",
		".....k........k",
		"....kk........kk"]],
	[18, 0, [
		"........k..k",
		"........k..k",
		"........k..kk",
		"........k...k",
		"........k...kk",
		".......kk"]],
	[18, 0, [
		"........k..k",
		"........k..k",
		"........k...k",
		".......k.....k",
		"......k.......k",
		".....kk.......kk"]],
	[18, 0, [
		"........k..k",
		"........k..k",
		".......kk..k",
		"......k....k",
		".....kk....k",
		"...........kk"]],
]
const WINGED_LEGS_AIR := [18, 0, [
	"........k..k",
	".......k..k",
	"......k..k",
	".....k..k"]]
const WINGED_LEGS_DIVE := [18, 0, [
	"........kkkk",
	".........kk",
	".........kk",
	".........kk",
	".........kk",
	"..........k"]]
const WINGS_FOLDED := [9, 0, [
	"....QQ",
	"...QWWQ",
	"...QWWWQ",
	"....QWWQ",
	".....QQ"]]
const WINGS_UP := [0, 0, [
	".Q",
	".QQ",
	".QWQ",
	"..QWQ",
	"..QWWQ",
	"...QWWQ",
	"...QWWWQ",
	"....QWWWQ",
	".....QWWQ",
	"......QQ"]]
const WINGS_DOWN := [11, 0, [
	"......QQ",
	"....QQWWQ",
	"..QQWWWWQ",
	".QWWWWWQ",
	"QWWWWQQ",
	"QWWQQ",
	"QQ"]]
const WINGS_SPREAD := [8, 0, [
	"..QQQQ",
	".QWWWWQQ",
	"QWWWWWWWQ",
	".QQWWWWQ",
	"...QQQQ"]]
const WINGS_TUCKED := [5, 0, [
	".....Q",
	".....QQ",
	".....QWQ",
	"......QWQ",
	"......QWQ",
	".......Q"]]

const Look := Pose.Look
const Action := Pose.Action

## Textures built so far, by pose, Team colour and Seat marking.
var _textures := {}


## The sprite for `pose` in a Team's colour, `team`, with the marking of the
## Seat at `place` in its Team (its Queen's 0, its Workers' 1-4), as a
## texture.
func texture(pose: Pose, team: Color, place: int) -> Texture2D:
	var key := "%d %d %d %d %s %d" % [pose.look, pose.action, pose.frame, int(pose.carrying), team.to_html(),
		place]
	if not _textures.has(key):
		_textures[key] = ImageTexture.create_from_image(image(pose, team, place))
	return _textures[key]


## The sprite for `pose` in a Team's colour, `team`, with the marking of the
## Seat at `place` in its Team, as an image.
static func image(pose: Pose, team: Color, place: int) -> Image:
	var winged := pose.look in [Look.WARRIOR, Look.SPEED_WARRIOR, Look.QUEEN]
	var size := WINGED_SIZE if winged else WORKER_SIZE
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var colours := _palette(pose, team, place)
	for part: Array in (_winged_parts(pose, place) if winged else _worker_parts(pose, place)):
		var rows: Array = part[2]
		for y in rows.size():
			var row: String = rows[y]
			for x in row.length():
				if row[x] != ".":
					img.set_pixel(part[1] + x, part[0] + y, colours[row[x]])
	return img


static func _palette(pose: Pose, main: Color, place: int) -> Dictionary:
	var speed := pose.look in [Look.SPEED_WORKER, Look.SPEED_WARRIOR]
	return {
		"k": OUTLINE, "T": main, "t": main.darkened(0.35), "L": main.lightened(0.45),
		"s": SPEED_STRIPE if speed else STRIPE, "w": Color.WHITE, "Q": WING_EDGE, "W": WING,
		"c": CROWN, "C": CROWN_SHADE, "r": SWORD, "m": MARKINGS[place % MARKINGS.size()],
	}


## A Worker's parts, back to front.
static func _worker_parts(pose: Pose, place: int) -> Array:
	var legs: Array = WORKER_LEGS_STAND
	match pose.action:
		Action.RUN:
			legs = WORKER_LEGS_RUN[pose.frame]
		Action.JUMP:
			legs = WORKER_LEGS_JUMP
		Action.FALL, Action.EATEN:
			legs = WORKER_LEGS_FALL
		Action.HOLD_UP:
			legs = WORKER_LEGS_TIPTOE
		Action.RIDE, Action.EAT:
			legs = WORKER_LEGS_SIT
	var arms: Array = WORKER_ARMS_DOWN
	if pose.carrying or pose.action in [Action.HOLD_UP, Action.EATEN] \
			or (pose.action == Action.EAT and pose.frame == 0):
		arms = WORKER_ARMS_UP
	elif pose.action == Action.EAT:
		arms = WORKER_ARMS_FORWARD
	var head: Array = HEAD_HURT if pose.action == Action.EATEN else HEAD
	return [legs, WORKER_TORSO, arms, head, HATS[place % HATS.size()]]


## A Queen's or Warrior's parts, back to front.
static func _winged_parts(pose: Pose, place: int) -> Array:
	var wings: Array = WINGS_FOLDED
	var legs: Array = WINGED_LEGS_STAND
	match pose.action:
		Action.RUN:
			legs = WINGED_LEGS_WALK[pose.frame]
		Action.FLAP:
			wings = WINGS_UP if pose.frame == 0 else WINGS_DOWN
			legs = WINGED_LEGS_AIR
		Action.GLIDE:
			wings = WINGS_SPREAD
			legs = WINGED_LEGS_AIR
		Action.DIVE:
			wings = WINGS_TUCKED
			legs = WINGED_LEGS_DIVE
	var parts := [wings, legs]
	if pose.look == Look.QUEEN:
		parts.append_array([QUEEN_STINGER, WINGED_TORSO, WINGED_ARMS, _shifted(HEAD), QUEEN_CROWN])
	else:
		parts.append_array([WINGED_TORSO, WARRIOR_ARMS, _shifted(HEAD), WARRIOR_HELMET,
			_shifted(HATS[place % HATS.size()])])
	return parts


static func _shifted(part: Array) -> Array:
	return [part[0], part[1] + WINGED_OFFSET, part[2]]


## The Snail's sprite, facing right: its collider's size in art pixels (`size`),
## a pink body under a red shell, its mouth open while it eats.
static func snail_image(size: Vector2i, eating: bool) -> Image:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var body := Color("e86aa8")
	var shell := Color("c8384a")
	var w := size.x
	var h := size.y
	# The foot along the ground, the neck and head rising at the front.
	_fill(img, func(x: int, y: int) -> bool:
		return (y >= h * 3 / 4 and x >= 1 and x < w - 2) \
			or (x >= w * 2 / 3 and x < w - 2 and y >= h / 3 and Vector2(x - (w - 7), y - (h / 3 + 3)).length() < 6.5) \
			or (x >= w * 2 / 3 and x < w - 3 and y >= h / 3 + 3), body)
	# The shell over the back: a disc with a spiral.
	var centre := Vector2(w * 0.36, h * 0.48)
	var radius := h * 0.46
	_fill(img, func(x: int, y: int) -> bool: return Vector2(x, y).distance_to(centre) < radius, shell)
	_outline(img)
	for i in 140:
		var turn := i / 140.0 * 2.6 * TAU
		var r := radius * (0.12 + 0.8 * i / 140.0)
		var at := centre + Vector2(cos(turn), sin(turn)) * r
		img.set_pixelv(Vector2i(at), OUTLINE)
	# Eye stalks and eyes; the mouth, a gaping wedge while eating.
	for stalk in [w - 9, w - 5]:
		for y in range(h / 3 - 6, h / 3):
			img.set_pixel(stalk, y, OUTLINE)
		img.set_pixel(stalk, h / 3 - 7, Color.WHITE)
		img.set_pixel(stalk + 1, h / 3 - 7, OUTLINE)
	var mouth := Vector2i(w - 4, h / 3 + 7)
	if eating:
		for y in range(-2, 3):
			for x in range(0, 3 - absi(y)):
				img.set_pixel(mouth.x - x + 1, mouth.y + y, OUTLINE)
	else:
		img.set_pixel(mouth.x, mouth.y, OUTLINE)
		img.set_pixel(mouth.x - 1, mouth.y, OUTLINE)
	return img


## Colours every pixel of `img` where `inside` holds.
static func _fill(img: Image, inside: Callable, colour: Color) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if inside.call(x, y):
				img.set_pixel(x, y, colour)


## Outlines everything drawn on `img`: each drawn pixel next to an undrawn one,
## or the edge, turns the outline colour.
static func _outline(img: Image) -> void:
	var edge: Array[Vector2i] = []
	var size := img.get_size()
	for y in size.y:
		for x in size.x:
			if img.get_pixel(x, y).a == 0:
				continue
			for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var n := Vector2i(x, y) + d
				if not Rect2i(Vector2i.ZERO, size).has_point(n) or img.get_pixelv(n).a == 0:
					edge.append(Vector2i(x, y))
					break
	for p in edge:
		img.set_pixelv(p, OUTLINE)
