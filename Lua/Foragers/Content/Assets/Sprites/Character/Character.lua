-- Character definition file. Place in Content/Assets/Sprites/{Name}/Character.lua
-- tag: string identifier for spawn logic. "player" spawns at screen center.
-- components: array of component definitions. Order matters for initialization.
return {
	tag = "player",
	components = {
		-- AnimatableSprite: renders animated sprites.
		-- spriteSheet: path to PNG file with animation frames.
		-- frameWidth/frameHeight: dimensions of single frame in pixels.
		-- animations: array of animation states.
		--   name: animation identifier (required).
		--   row: row index in spritesheet (default: animation index).
		--   frames: frame count (required).
		--   speed: frames per second (required).
		--   loop: true for looping, false for one-shot (default: false).
		{
			type = "AnimatableSprite",
			spriteSheet = "Content/Assets/Sprites/Character/Character.png",
			frameWidth = 16,
			frameHeight = 16,
			animations = {
				{ name = "Idle", frames = 4, speed = 4, loop = true },
				{ name = "Run", frames = 4, speed = 8, loop = true },
				{ name = "Swim", frames = 4, speed = 6, loop = true },
				{ name = "Death", frames = 4, speed = 5, loop = false },
			},
		},
		-- Controllable: handles keyboard movement.
		-- movementSpeed: pixels per second (default: 64).
		-- keys: custom key bindings { up, down, left, right } (default: WASD).
		{
			type = "Controllable",
			movementSpeed = 64,
		},
	},
}
