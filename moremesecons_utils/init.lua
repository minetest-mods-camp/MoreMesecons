moremesecons = {}

function moremesecons.setting(modname, settingname, default, min)
	local setting = "moremesecons_" .. modname .. "." .. settingname

	if type(default) == "boolean" then
		local ret = minetest.setting_getbool(setting)
		if ret == nil then
			ret = default
		end
		return ret
	elseif type(default) == "string" then
		return minetest.setting_get(setting) or default
	elseif type(default) == "number" then
		local ret = tonumber(minetest.setting_get(setting)) or default
		if ret ~= ret then -- NaN
			minetest.log("warning", "[moremesecons_"..modname.."]: setting '"..setting.."' is NaN. Set to default value ("..tostring(default)..").")
			ret = default
		end
		if min and ret < min then
			minetest.log("warning", "[moremesecons_"..modname.."]: setting '"..setting.."' is under minimum value "..tostring(min)..". Set to minimum value ("..tostring(min)..").")
			ret = min
		end
		return ret
	end
end
