-- Constants for customization.
local CONST_CANNON_SPEED = 50
local CONST_GRAVITY = -10
local CONST_Y_OFFSET = 20 -- Increase for easier aiming without having to dig yourself into the ground.

-- Definition for cannon projectile entity.
minetest.register_entity("cannon:cannonball", {
	hp_max = 1,
	physical = true,
	weight = 0,
	collisionbox = {1, 1, 1, 1, 1, 1},
	visual = "sprite",
	visual_size = {x=1, y=1},
	textures = {"cannon_cannonball.png"},
	spritediv = {x=1, y=1},
	initial_sprite_basepos = {x=0, y=0},
	is_visible = true,
	makes_footstep_sound = false,
	automatic_rotate = false,
	on_step = function(self, dtime)
		local pos = self.object:get_pos()
		local node = minetest.get_node_or_nil(pos)
		if node ~= nil then
			if node.name ~= "air" then
				minetest.remove_node({x=round(pos.x), y=round(pos.y), z=round(pos.z)})
				minetest.chat_send_all("Hit target!")
				self.object:remove()
			end
		end
	end
})

-- Fire function, an abstraction to make for easier debugging
-- "entity" is a string, such as "cannon:cannonball". "position" is a normal position array; so is "vector".
-- Example use: fire("cannon:cannon_cannonball", {0,0,0}, {0,10,20})
local function fire(entity, position, vector)
  obj = minetest.add_entity(position, entity)
  if obj then -- If adding the entity was a success
	vector.x = vector.x * CONST_CANNON_SPEED
	vector.y = vector.y * CONST_CANNON_SPEED + CONST_Y_OFFSET
	vector.z = vector.z * CONST_CANNON_SPEED
    obj:set_velocity(vector) -- time to whiz across enemy lines
	obj:set_acceleration({x = 0, y = CONST_GRAVITY, z = 0}) -- Every server step, we apply more gravity to the entity.
	end
  end

-- Rounding function to help in getting the node impacted.
function round(n)
  return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
  end

-- Cannon node definition.
-- It directly invokes fire() when punched, and passes the player look vector.
minetest.register_node("cannon:cannon", {
    description = "Cannon",
	tiles = {
		{name = "cannon_machinery.png"},{name = "cannon_machinery.png"},{name = "cannon_barrel.png"},{name = "cannon_barrel.png"},{name="cannon_wood.png"},{name="cannon_wheels.png"}
		},
	groups = {cracky = 3},
	drawtype = "mesh",
	mesh = "cannon_cannon.obj",
	paramtype = "light",
	paramtype2 = "facedir",
    on_punch = function(pos, node, player, pointed_thing)
      firingVector = player:get_look_dir()
      fire("cannon:cannonball", pos, firingVector)
	  end
  })
