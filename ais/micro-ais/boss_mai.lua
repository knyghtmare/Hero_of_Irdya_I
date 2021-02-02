function wesnoth.micro_ais.hunter(cfg)
	if (cfg.action ~= 'delete') then
	    if (not cfg.id) and (not wml.get_child(cfg, "filter")) then
			wml.error("Hunter [micro_ai] tag requires either id= key or [filter] tag")
		end
		AH.get_named_loc_xy('home', cfg, 'Hunter [micro_ai] tag')
	end
	local required_keys = {}
	local optional_keys = { "id", "[filter]", "[filter_location]", "home_loc", "home_x", "home_y", "rest_turns", "show_messages" }
	local CA_parms = {
		ai_id = 'mai_hunter',
		{ ca_id = "move", location = 'ca_hunter.lua', score = cfg.ca_score or 300000 }
	}
    return required_keys, optional_keys, CA_parms
end