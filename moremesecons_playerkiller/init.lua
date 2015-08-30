local kill_nearest_player = function(pos)
	local MAX_DISTANCE = 8 -- Use this number to set maximal distance to kill
	
	-- Search the nearest player
	local nearest = nil
	local min_distance = math.huge
	local players = minetest.get_connected_players()
	for index, player in pairs(players) do
		local distance = vector.distance(pos, player:getpos())
		if distance < min_distance then
			min_distance = distance
			nearest = player
		end
	end
	
	-- And kill him
	meta = minetest.get_meta(pos)
	owner = meta:get_string("owner")
	if owner then
		if vector.distance(pos, nearest:getpos()) < MAX_DISTANCE and owner ~= nearest:get_player_name() then
			nearest:set_hp(0)
		end
	end
end

minetest.register_craft({
	output = "moremesecons_playerkiller:playerkiller 1",
	recipe = {	{"","default:apple",""},
			{"default:apple","mesecons_detector:object_detector_off","default:apple"},
			{"","default:apple",""}}
})
minetest.register_node("moremesecons_playerkiller:playerkiller", {
	tiles = {"moremesecons_playerkiller_top.png", "moremesecons_playerkiller_top.png", "moremesecons_playerkiller_side.png", "moremesecons_playerkiller_side.png", "moremesecons_playerkiller_side.png", "moremesecons_playerkiller_side.png"},
	paramtype = "light",
	walkable = true,
	groups = {cracky=3},
	description="Player Killer",
	mesecons = {effector = {
		state = mesecon.state.off,
		action_on = kill_nearest_player
	}},
	after_place_node = function(pos, placer)
		meta = minetest.get_meta(pos)
		if placer then
			local meta = minetest.get_meta(pos)
			meta:set_string("owner", placer:get_player_name())
			meta:set_string("infotext", "PlayerKiller owned by " .. meta:get_string("owner"))
		end
	end,
	sounds = default.node_sound_stone_defaults(),
})
