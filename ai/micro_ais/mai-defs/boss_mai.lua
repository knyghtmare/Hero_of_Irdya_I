function wesnoth.micro_ais.boss(cfg)
	if (cfg.action ~= 'delete') then
	    if (not cfg.id) and (not wml.get_child(cfg, "filter")) then
			wml.error("Boss [micro_ai] tag requires either id= key or [filter] tag")
        end
		-- LK: We do not need this
		-- the boss will just wander, target, kill, and find another target
		-- AH.get_named_loc_xy('home', cfg, 'Scenario Boss [micro_ai] tag')
	end
	local required_keys = {}
	local optional_keys = { "id", "[filter]", "[filter_location]" }
	-- Tahsin Jahin: So, I had to give the entire path to the CA file
	-- as the add-on procedure for micro AI addition is rather
	-- messy
	local CA_parms = {
		ai_id = 'mai_boss',
		{ ca_id = "move", location = '~add-ons/Hero_of_Irdya_I/ai/micro_ais/cas/ca_boss.lua', score = cfg.ca_score or 300000 }
	}
    return required_keys, optional_keys, CA_parms
end