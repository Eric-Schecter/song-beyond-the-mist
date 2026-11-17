extends RefCounted
# Collision uses the foot plane, not the sprite's head or floating sword.
const PLAYER_RADIUS := 5.0
const GUARDIAN_RADIUS := 10.0
const GAP := PLAYER_RADIUS + GUARDIAN_RADIUS

static func slide(origin: Vector2, candidate: Vector2, other: Vector2, gap: float = GAP) -> Vector2:
	var before := origin-other
	var after := candidate-other
	if after.length_squared() >= gap*gap:return candidate
	# Recover from old checkpoints/test placements without teleporting either actor.
	if before.length_squared()<gap*gap-.01:
		return candidate if after.length_squared()>before.length_squared() else origin
	if after.length_squared()<.0001:return origin
	# Keep the tangential part of movement: walking around the body remains smooth.
	return other+after.normalized()*(gap+.001)

static func allows(origin: Vector2, candidate: Vector2, other: Vector2, gap: float = GAP) -> bool:
	var distance := candidate.distance_squared_to(other)
	if distance >= gap*gap-.001:return true
	var previous := origin.distance_squared_to(other)
	return previous < gap*gap-.01 and distance > previous+.0001
