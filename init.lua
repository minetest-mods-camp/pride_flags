--------------------------------------------------------
-- Minetest :: Pride Flags Mod (pride_flags)
--
-- See README.txt for licensing and other information.
-- Copyright (c) 2022, Leslie E. Krause
--------------------------------------------------------

local wind_noise = PerlinNoise( 204, 1, 0, 500 )
-- Check whether the new `get_2d` Perlin function is available,
-- otherwise use `get2d`. Needed to suppress deprecation
-- warning in newer Minetest versions.
local old_get2d = true
if wind_noise.get_2d then
	old_get2d = false
end
local active_flags = { }

local pi = math.pi
local rad_180 = pi
local rad_90 = pi / 2

local flag_list = { "rainbow", "lesbian", "bisexual", "transgender", "genderqueer", "nonbinary", "pansexual", "asexual" }

local S
if minetest.get_translator then
	S = minetest.get_translator("pride_flags")
else
	S = function(s) return s end
end

minetest.register_entity( "pride_flags:wavingflag", {
	initial_properties = {
		physical = false,
		visual = "mesh",
		visual_size = { x = 8.5, y = 8.5 },
		collisionbox = { -0.1, -0.85, -0.1, 0.1, 0.85, 0.1 },
		backface_culling = false,
		pointable = false,
		mesh = "pride_flags_wavingflag.b3d",
		textures = { "prideflag_rainbow.png" },
		use_texture_alpha = false,
	},

	on_activate = function ( self, staticdata, dtime )
		self:reset_animation( true )
		self.object:set_armor_groups( { immortal = 1 } )

		if staticdata ~= "" then
			local data = minetest.deserialize( staticdata )
			self.flag_idx = data.flag_idx
			self.node_idx = data.node_idx

			if not self.flag_idx or not self.node_idx then
				self.object:remove( )
				return
			end

			self:reset_texture( self.flag_idx )

			active_flags[ self.node_idx ] = self.object
		else
			self.flag_idx = 1
		end

		-- Delete entity if there is already one for this pos
		local objs = minetest.get_objects_inside_radius( self.object:get_pos(), 0.5 )
		for o=1, #objs do
			local obj = objs[o]
			local lua = obj:get_luaentity( )
			if lua and self ~= lua and lua.name == "pride_flags:wavingflag" then
				if lua.node_idx == self.node_idx then
					self.object:remove( )
					return
				end
			end
		end
	end,

	on_deactivate = function ( self )
		if self.sound_id then
			minetest.sound_stop( self.sound_id )
		end
	end,

	on_step = function ( self, dtime )
		self.anim_timer = self.anim_timer - dtime

		if self.anim_timer <= 0 then
			minetest.sound_stop( self.sound_id )
			self:reset_animation( )
		end
	end,

	reset_animation = function ( self, initial )
		local coords = { x = os.time( ) % 65535, y = 0 }
		local cur_wind
		if old_get2d then
			cur_wind = wind_noise:get2d(coords)
		else
			cur_wind = wind_noise:get_2d(coords)
		end
		cur_wind = cur_wind * 30 + 30
		minetest.log("verbose", "[pride_flags] Current wind: " .. cur_wind)
		local anim_speed
		local wave_sound

		cur_wind = math.random(0, 50)
		cur_wind = 30

		if cur_wind < 10 then
			anim_speed = 10	-- 2 cycle
			wave_sound = "pride_flags_flagwave1"
		elseif cur_wind < 20 then
			anim_speed = 20  -- 4 cycles
			wave_sound = "pride_flags_flagwave1"
		elseif cur_wind < 40 then
			anim_speed = 40  -- 8 cycles
			wave_sound = "pride_flags_flagwave2"
		else
			anim_speed = 80  -- 16 cycles
			wave_sound = "pride_flags_flagwave3"
		end
		-- slightly anim_speed change to desyncronize flag waving
		anim_speed = anim_speed + math.random(0, 200) * 0.01

		if self.object then
			if initial or (not self.object.set_animation_frame_speed) then
				self.object:set_animation( { x = 1, y = 575 }, anim_speed, 0, true )
			else
				self.object:set_animation_frame_speed(anim_speed)
			end
			self.sound_id = minetest.sound_play( wave_sound, { object = self.object, gain = 1.0, loop = true } )
		end

		self.anim_timer = 115 + math.random(-10, 10) -- time to reset animation
	end,

	reset_texture = function ( self, flag_idx )
		if not flag_idx then
			-- next flag
			self.flag_idx = self.flag_idx % #flag_list + 1	-- this automatically increments
		elseif flag_idx == -1 then
			-- previous flag
			self.flag_idx = self.flag_idx - 1
			if self.flag_idx < 1 then
				self.flag_idx = #flag_list
			end
		else
			-- set flag directly
			self.flag_idx = flag_idx
		end

		-- Fallback flag
		if not flag_list[ self.flag_idx ] then
			self.flag_idx = 1
		end

		local texture = string.format( "prideflag_%s.png", flag_list[ self.flag_idx ] )
		self.object:set_properties( { textures = { texture } } )
		return self.flag_idx
	end,

	get_staticdata = function ( self )
		return minetest.serialize( {
			node_idx = self.node_idx,
			flag_idx = self.flag_idx,
		} )
	end,
} )

local metal_sounds
if minetest.get_modpath("default") ~= nil then
	if default.node_sound_metal_defaults then
		metal_sounds = default.node_sound_metal_defaults()
	end
end

minetest.register_node( "pride_flags:lower_mast", {
        description = S("Flag Pole"),
        drawtype = "mesh",
        paramtype = "light",
        mesh = "pride_flags_mast_lower.obj",
        paramtype2 = "facedir",
        tiles = { "pride_flags_baremetal.png", "pride_flags_baremetal.png" },
        wield_image = "pride_flags_pole_bottom_inv.png",
        inventory_image = "pride_flags_pole_bottom_inv.png",
        groups = { cracky = 1, level = 2 },
        sounds = metal_sounds,

        selection_box = {
                type = "fixed",
                fixed = { { -3/32, -1/2, -3/32, 3/32, 1/2, 3/32 } },
        },
        collision_box = {
                type = "fixed",
                fixed = { { -3/32, -1/2, -3/32, 3/32, 1/2, 3/32 } },
        },

	on_rotate = function(pos, node, user, mode, new_param2)
		if mode == screwdriver.ROTATE_AXIS then
			return false
		end
	end,
} )

local function get_flag_pos( pos, param2 )
	local facedir_to_pos = {
		[0] = { x = 0, y = 0.6, z = -0.1 },
		[1] = { x = -0.1, y = 0.6, z = 0 },
		[2] = { x = 0, y = 0.6, z = 0.1 },
		[3] = { x = 0.1, y = 0.6, z = 0 },
	}
	return vector.add( pos, vector.multiply( facedir_to_pos[ param2 ], 1 ) )
end

local function rotate_flag_by_param2( flag, param2 )
	local facedir_to_yaw = {
		[0] = rad_90,
		[1] = 0,
		[2] = -rad_90,
		[3] = rad_180,
	}
	local baseyaw = facedir_to_yaw[ param2 ]
	if not baseyaw then
		minetest.log("warning", "[pride_flags] Unsupported flag pole node param2: "..tostring(param2))
		return
	end
	flag:set_yaw( baseyaw - rad_180 )
end

local function spawn_flag( pos )
	local node_idx = minetest.hash_node_position( pos )
	local param2 = minetest.get_node( pos ).param2

	local flag_pos = get_flag_pos( pos, param2 )
	local obj = minetest.add_entity( flag_pos, "pride_flags:wavingflag" )
	if not obj or not obj:get_luaentity( ) then
		return
	end

	obj:get_luaentity( ).node_idx = node_idx
	rotate_flag_by_param2( obj, param2 )

	active_flags[ node_idx ] = obj
	return obj
end

local function spawn_flag_and_set_texture( pos )
	local flag = spawn_flag( pos )
	if flag and flag:get_luaentity() then
		local meta = minetest.get_meta( pos )
		local flag_idx = meta:get_int("flag_idx")
		flag:get_luaentity():reset_texture( flag_idx )
	end
	return flag
end

local function cycle_flag( pos, player, cycle_backwards )
	local node_idx = minetest.hash_node_position( pos )

	if minetest.check_player_privs( player:get_player_name( ), "server" ) then
		local aflag = active_flags[ node_idx ]
		local flag
		if aflag then
			flag = aflag:get_luaentity( )
		end
		if flag then
			local flag_idx
			if cycle_backwards then
				flag_idx = flag:reset_texture( -1 )
			else
				flag_idx = flag:reset_texture( )
			end
			local meta = minetest.get_meta( pos )
			meta:set_int("flag_idx", flag_idx)
		else
			spawn_flag_and_set_texture( pos )
		end
	end
end

minetest.register_node( "pride_flags:upper_mast", {
	description = S("Flag Pole with Flag"),
	drawtype = "mesh",
	paramtype = "light",
	mesh = "pride_flags_mast_upper.obj",
	paramtype2 = "facedir",
	tiles = { "pride_flags_baremetal.png", "pride_flags_baremetal.png" },
	wield_image = "pride_flags_pole_top_inv.png",
	inventory_image = "pride_flags_pole_top_inv.png",
	groups = { cracky = 1, level = 2 },
	sounds = metal_sounds,

        selection_box = {
                type = "fixed",
                fixed = { { -3/32, -1/2, -3/32, 3/32, 27/16, 3/32 } },
        },
        collision_box = {
                type = "fixed",
                fixed = { { -3/32, -1/2, -3/32, 3/32, 27/16, 3/32 } },
        },

	on_rightclick = function ( pos, node, player )
		cycle_flag( pos, player )
	end,

	on_punch = function ( pos, node, player )
		cycle_flag( pos, player, -1 )
	end,

	on_construct = function ( pos )
		local flag = spawn_flag ( pos )
		if flag and flag:get_luaentity() then
			local meta = minetest.get_meta( pos )
			meta:set_int("flag_idx", flag:get_luaentity().flag_idx)
		end
	end,

	on_destruct = function ( pos )
		local node_idx = minetest.hash_node_position( pos )
		if active_flags[ node_idx ] then
			active_flags[ node_idx ]:remove( )
		end
	end,

	on_rotate = function(pos, node, user, mode, new_param2)
		if mode == screwdriver.ROTATE_AXIS then
			return false
		end
		local node_idx = minetest.hash_node_position( pos )
		local aflag = active_flags[ node_idx ]
		if aflag then
			local lua = aflag:get_luaentity( )
			if not lua then
				aflag = spawn_flag_and_set_texture( pos )
				if aflag then
					lua = aflag:get_luaentity()
					if not lua then
						 return
					 end
				 end
			end
			local flag_pos_idx = lua.node_idx
			local flag_pos = minetest.get_position_from_hash( flag_pos_idx )
			flag_pos = get_flag_pos( flag_pos, new_param2 )
			rotate_flag_by_param2( aflag, new_param2 )
			aflag:set_pos( flag_pos )
		end
	end,
} )

minetest.register_lbm({
	name = "pride_flags:respawn_flags",
	label = "Respawn flags",
	nodenames = {"pride_flags:upper_mast"},
	run_at_every_load = true,
	action = function(pos, node)
		local node_idx = minetest.hash_node_position( pos )
		local aflag = active_flags[ node_idx ]
		if aflag then
			return
		end
		spawn_flag_and_set_texture( pos )
	end
})
