cannon = {}

-- Constants for customization.
local CONST_CANNON_SPEED = 50
local CONST_GRAVITY = -10
local Y_OFFSET = 20 -- Increase for easier aiming without having to dig yourself into the ground. Not a constant, modifiable via formspec.

cannon.blacklisted_nodes = { -- Nodes the cannonball can't 'hit'
	["air"] = "match",
	["ignore"] = "match",
	["water"] = "find",
	["lava"] = "find",
	["cannon:cannon"] = "match"
}

cannon.ball_timeout = 5 -- Time in seconds before the cannonball explodes


-- Definition for cannon projectile entity.
minetest.register_entity("cannon:cannonball", {
	hp_max = 1,
	physical = false,
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
		local obj = self.object
		local node_ahead = vector.add(pos, vector.normalize(obj:get_velocity()))

		if not self.timer then
			self.timer = 0
		else
			self.timer = self.timer + dtime
		end

		if minetest.get_node_or_nil(pos) == nil then
			obj:remove()
		end

		if self.timer >= cannon.ball_timeout or cannon.can_hit_node(node_ahead) == true then
			cannon.destroy_nodes_in_radius(pos)
			obj:remove()
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
	vector.y = vector.y * CONST_CANNON_SPEED + Y_OFFSET
	vector.z = vector.z * CONST_CANNON_SPEED
		obj:set_velocity(vector) -- time to whiz across enemy lines
	obj:set_acceleration({x = 0, y = CONST_GRAVITY, z = 0}) -- Every server step, we apply more gravity to the entity.
	end
end

function cannon.can_hit_node(pos)
	local node = minetest.get_node_or_nil(pos)

	if node == nil then
		return false
	end

	for string, method in pairs(cannon.blacklisted_nodes) do
		if method == "find" then
			if node.name:find(string) then
				return false
			end
		else
			if node.name == string then
				return false
			end
		end
	end

	return true
end

function cannon.destroy_nodes_in_radius(pos)
	pos = vector.round(pos)

	minetest.remove_node(pos)
	pos.y = pos.y + 1
	minetest.remove_node(pos)
	pos.y = pos.y - 2
	minetest.remove_node(pos)
	pos.y = pos.y + 1
	pos.x = pos.x + 1
	minetest.remove_node(pos)
	pos.x = pos.x - 2
	minetest.remove_node(pos)
	pos.x = pos.x + 1
	pos.z = pos.z + 1
	minetest.remove_node(pos)
	pos.z = pos.z - 2
	minetest.remove_node(pos)
end

-- Cannon node definition.
-- It directly invokes fire() when punched, and passes the player look vector.
-- It also handles loading the cannon via a formspec.
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
	  end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
	  minetest.show_formspec(player:get_player_name(), "cannon:load",
	  	"size[3,3]" ..
	  	"label[0,0;Load cannon here]" ..
			"button_exit[0,2;2,1;exit;Done]")
	  end
  })
