-- version 1.1

local helper = wesnoth.require "lua/helper.lua"

function sort_ring(ring, radius)
	local result = {}
	
	for i = 1, radius + 1 do
		table.insert(result, ring[i])
	end
	
	for i = 1, 4*radius - 2 do
		local element =  ring[i + radius + 1]
		if i%2 == 1 then
			table.insert(result, 1, element)
		else
			table.insert(result, element)
		end
	end
	
	for i = 5*radius, 6*radius do
		table.insert(result, 1, ring[i])
	end
	
	return result
end

function get_new_index(index, radius)
	local result = index + radius
	if (result > 6*radius) then
		result = result - 6*radius
	end
	
	return result
end

function rotate_ring(ring, radius)
	local result = { }
	
	for i,elem in ipairs(ring) do
		local new_index = get_new_index(i, radius)
		result[new_index] = elem
	end
	
	return result
end

function wesnoth.wml_actions.rotate_area(cfg)

	local radius_ = cfg.radius
	local x_ = cfg.x
	local y_ = cfg.y
	
	local rings = {}
	local excluded_locs = { { x = x_, y = y_} }
	local moved_units = { }
	
	for i = 1, radius_ do
		helper.set_variable_array("__RA_excluded_locs", excluded_locs)
		
		local current_ring = wesnoth.get_locations {
								{"not", { find_in = "__RA_excluded_locs" } },
								{"and", {
											x = x_,
											y = y_,
											radius = i
										}
								}
							}
		
		
		for n=1, 6*i do
			table.insert (excluded_locs, { x = current_ring[n][1], y = current_ring[n][2]})
			current_ring[n][3] = wesnoth.get_terrain(current_ring[n][1], current_ring[n][2])
		end
		
		current_ring = sort_ring(current_ring, i)
		rotated_ring = current_ring
		
		
		for n = 1, cfg.times do
			rotated_ring = rotate_ring(rotated_ring, i)
		end
		
		for n,elem in ipairs(current_ring) do
			wesnoth.set_terrain ( elem[1], elem[2], rotated_ring[n][3] )
			
			local unit = wesnoth.get_unit (elem[1], elem[2])
			if unit ~= nil then
				table.insert(moved_units, {id = unit.id, x = rotated_ring[n][1], y = rotated_ring[n][2]} )
			end
		end

	end
	
	wesnoth.fire "redraw"
	
	if cfg.move_units ~= false then	
		for i,unit in ipairs(moved_units) do
			wesnoth.fire ( "store_unit", { { "filter", { id = unit.id } }, variable = "__RA_stored_units[" .. i .. "]", kill = true } )
		end
		
		for i,unit in ipairs(moved_units) do
			wesnoth.fire ( "unstore_unit", { variable = "__RA_stored_units[" .. i .. "]", x = unit.x, y = unit.y } )
		end
		
		if cfg.fire_event ~= false then
			for i,unit in ipairs(moved_units) do
				wesnoth.fire_event ("moveto", unit.x, unit.y)
			end
		end
	end
	
end
