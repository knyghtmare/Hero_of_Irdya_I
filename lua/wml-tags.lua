local helper = wesnoth.require "lua/helper.lua"

wml_actions = wesnoth.wml_actions

-- For the multi-hex shoot special macro

function wesnoth.wml_actions.get_unit_defense(cfg)
	local filter = wesnoth.get_units(cfg)
	local variable = cfg.variable or "defense"

	for index, unit in ipairs(filter) do
		local terrain = wesnoth.get_terrain ( unit.x, unit.y )
		-- it is WML defense: the lower, the better. Converted to normal defense with 100 -
		local defense = 100 - wesnoth.unit_defense ( unit, terrain )
		wesnoth.set_variable ( string.format ( "%s[%d]", variable, index - 1 ), { id = unit.id, x = unit.x, y = unit.y, terrain = terrain, defense = defense } )
	end
end

-- For item dialogues

local T = helper.set_wml_tag_metatable {}

-- support for translatable strings, custom textdomain
local _ = wesnoth.textdomain "wesnoth-Hero_of_Irdya_I"

-- [item_dialog]
-- an alternative interface to pick items
-- could be used in place of [message] with [option] tags
function wml_actions.item_dialog( cfg )
	local image_and_description = T.grid { T.row { T.column { vertical_alignment = "center",
								  horizontal_alignment = "center",
								  border = "all",
								  border_size = 5,
								  T.image { id = "image_name" } },
						       T.column { horizontal_alignment = "left",
								  border = "all",
								  border_size = 5,
								  T.scroll_label { id = "item_description" } }
		                              } }

	local buttonbox = T.grid { T.row { T.column { T.button { id = "take_button", return_value = 1 } },
					   T.column { T.spacer { width = 10 } },
					   T.column { T.button { id = "leave_button", return_value = 2 } }
				  } }

	local item_dialog = { T.helptip { id="tooltip_large" }, -- mandatory field
			      T.tooltip { id="tooltip_large" }, -- mandatory field
			      maximum_height = 320,
			      maximum_width = 480,
			      T.grid { -- Title, will be the object name
				      T.row { T.column { horizontal_alignment = "left",
							  grow_factor = 1, -- this one makes the title bigger and golden
							  border = "all",
							  border_size = 5,
							  T.label { definition = "title", id = "item_name" } } },
				      -- Image and item description
				      T.row { T.column { image_and_description } }, -- grid teminator
				      -- Effect description
				      T.row { T.column { horizontal_alignment = "left",
							  border = "all",
							  border_size = 5,
							  T.label { wrap = true, id = "item_effect" } } }, -- how to format?
				      -- button box
				      T.row { T.column { buttonbox } }
				    }
			    }

	local function item_preshow()
		-- here set all widget starting values
		wesnoth.set_dialog_value ( cfg.name, "item_name" )
		wesnoth.set_dialog_value ( cfg.image or "", "image_name" )
		wesnoth.set_dialog_value ( cfg.description, "item_description" )
		wesnoth.set_dialog_value ( cfg.effect, "item_effect" )
		wesnoth.set_dialog_value ( cfg.take_string or tostring( _"Take it" ), "take_button" )
		wesnoth.set_dialog_value ( cfg.leave_string or tostring( _"Leave it" ), "leave_button" )
	end

	local function sync()
		local function item_postshow()
			-- here get all widget values
		end

		local return_value = wesnoth.show_dialog( item_dialog, item_preshow, item_postshow )

		return { return_value = return_value }
	end

	local return_table = wesnoth.synchronize_choice(sync)
	if return_table.return_value == 1 or return_table.return_value == -1 then
		wesnoth.set_variable ( cfg.variable or "item_picked", "yes" )
	else wesnoth.set_variable ( cfg.variable or "item_picked", "no" )
	end
end