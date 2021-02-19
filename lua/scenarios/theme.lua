function wesnoth.interface.game_display.unit_status()
	local u = wesnoth.interface.get_displayed_unit()
	if not u then return {} end
	local s = old_unit_status()

	if u.status.frostbitten then
		table.insert(s, { "element", {
			image = "misc/frostbitten-status.png",
			tooltip = _ "frostbitten: This unit is frostbitten. It will lose 4 HP and have its damage reduced by 1 each turn during the day unless prevented by healers or cured by water at an oasis.\n\nUnits cannot be killed or deal no damage as a result of dehydration."
		} })
	end

    return s
end