local accepted_commands = {"say", "tell"} -- Authorized commands. Any to accept all.

local function initialize_data(meta)
	local commands = meta:get_string("commands")
	meta:set_string("formspec",
		"invsize[9,5;]" ..
		"textarea[0.5,0.5;8.5,4;commands;Commands;"..commands.."]" ..
		"label[1,3.8;@nearest, @farthest, and @random are replaced by the respective player names]" ..
		"button_exit[3.3,4.5;2,1;submit;Submit]")
	local owner = meta:get_string("owner")
	if owner == "" then
		owner = "not owned"
	else
		owner = "owned by " .. owner
	end
	meta:set_string("infotext", "Command Block\n" ..
		"(" .. owner .. ")\n" ..
		"Commands: "..commands)
end

local function construct(pos)
	local meta = minetest.get_meta(pos)

	meta:set_string("commands", "tell @nearest Commandblock unconfigured")

	meta:set_string("owner", "")

	initialize_data(meta)
end

local function after_place(pos, placer)
	if placer then
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name())
		initialize_data(meta)
	end
end

local function receive_fields(pos, formname, fields, sender)
	if not fields.submit then
		return
	end
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	if owner ~= "" and sender:get_player_name() ~= owner then
		return
	end
	meta:set_string("commands", fields.commands)

	initialize_data(meta)
end

local function resolve_commands(commands, pos)
	local nearest, farthest = nil, nil
	local min_distance, max_distance = math.huge, -1
	local players = minetest.get_connected_players()
	for index, player in pairs(players) do
		local distance = vector.distance(pos, player:getpos())
		if distance < min_distance then
			min_distance = distance
			nearest = player:get_player_name()
		end
		if distance > max_distance then
			max_distance = distance
			farthest = player:get_player_name()
		end
	end
	local random = players[math.random(#players)]:get_player_name()
	commands = commands:gsub("@nearest", nearest)
	commands = commands:gsub("@farthest", farthest)
	commands = commands:gsub("@random", random)
	return commands
end

local function commandblock_action_on(pos, node)
	if node.name ~= "moremesecons_commandblock:commandblock_off" then
		return
	end

	minetest.swap_node(pos, {name = "moremesecons_commandblock:commandblock_on"})

	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	if owner == "" then
		return
	end

	local commands = resolve_commands(meta:get_string("commands"), pos)
	for _, command in pairs(commands:split("\n")) do
		local pos = command:find(" ")
		local cmd, param = command, ""
		if pos then
			cmd = command:sub(1, pos - 1)
			param = command:sub(pos + 1)
		end
		local cmddef = minetest.chatcommands[cmd]
		local is_an_authorized_command = false
		for i = 1, #accepted_commands do
			if cmd == accepted_commands[i] then
				is_an_authorized_command = true
				break
			end
		end
		if not is_an_authorized_command and #accepted_commands ~= 0 then
			minetest.chat_send_player(owner, "You can not execute this command with a craftable command block ! This event will be reported.")
			minetest.log("action", "Player "..owner.." tryed to execute an unauthorized command with a craftable command block.")
			return
		end
		if not cmddef then
			minetest.chat_send_player(owner, "The command "..cmd.." does not exist")
			return
		end
		local has_privs, missing_privs = minetest.check_player_privs(owner, cmddef.privs)
		if not has_privs then
			minetest.chat_send_player(owner, "You don't have permission "
					.."to run "..cmd
					.." (missing privileges: "
					..table.concat(missing_privs, ", ")..")")
			return
		end
		cmddef.func(owner, param)
	end
end

local function commandblock_action_off(pos, node)
	if node.name == "moremesecons_commandblock:commandblock_on" then
		minetest.swap_node(pos, {name = "moremesecons_commandblock:commandblock_off"})
	end
end

local function can_dig(pos, player)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	return owner == "" or owner == player:get_player_name()
end

minetest.register_node("moremesecons_commandblock:commandblock_off", {
	description = "Craftable Command Block",
	tiles = {"moremesecons_commandblock_off.png"},
	groups = {cracky=2, mesecon_effector_off=1},
	on_construct = construct,
	after_place_node = after_place,
	on_receive_fields = receive_fields,
	can_dig = can_dig,
	sounds = default.node_sound_stone_defaults(),
	mesecons = {effector = {
		action_on = commandblock_action_on
	}}
})

minetest.register_node("moremesecons_commandblock:commandblock_on", {
	tiles = {"moremesecons_commandblock_on.png"},
	groups = {cracky=2, mesecon_effector_on=1, not_in_creative_inventory=1},
	light_source = 10,
	drop = "moremesecons_commandblock:commandblock_off",
	on_construct = construct,
	after_place_node = after_place,
	on_receive_fields = receive_fields,
	can_dig = can_dig,
	sounds = default.node_sound_stone_defaults(),
	mesecons = {effector = {
		action_off = commandblock_action_off
	}}
})

minetest.register_craft({
	output = "moremesecons_commandblock:commandblock_off",
	recipe = {
		{"group:mesecon_conductor_craftable","default:mese_crystal","group:mesecon_conductor_craftable"},
		{"default:mese_crystal","group:mesecon_conductor_craftable","default:mese_crystal"},
		{"group:mesecon_conductor_craftable","default:mese_crystal","group:mesecon_conductor_craftable"}
	}
})
