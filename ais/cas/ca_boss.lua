local H = wesnoth.require "helper"
local AH = wesnoth.require "ai/lua/ai_helper.lua"
local MAIUV = wesnoth.require "ai/micro_ais/micro_ai_unit_variables.lua"
local M = wesnoth.map

local function boss_attack_weakest_adj_enemy(ai, boss_unit)
    -- Attack the enemy with the fewest hitpoints adjacent to 'boss', if there is one
    -- Returns status of the attack:
    --   'attacked': if a unit was attacked
    --   'killed': if a unit was killed
    --   'no_attack': if no unit was attacked

    if (boss_unit.attacks_left == 0) then return 'no_attack' end

    local min_hp, target = math.huge
    for xa,ya in H.adjacent_tiles(boss_unit.x, boss_unit.y) do
        local enemy = wesnoth.units.get(xa, ya)
        if AH.is_attackable_enemy(enemy) then
            if (enemy.hitpoints < min_hp) then
                min_hp, target = enemy.hitpoints, enemy
            end
        end
    end

    if target then
        AH.checked_attack(ai, boss_unit, target)
        if target and target.valid then
            return 'attacked'
        else
            return 'killed'
        end
    end

    return 'no_attack'
end

local function get_level_boss(cfg)
    local filter = wml.get_child(cfg, "filter") or { id = cfg.id }
    local boss_unit = AH.get_units_with_moves {
        side = wesnoth.current.side,
        { "and", filter }
    }[1]
    return boss_unit
end

local ca_boss = {}

function ca_boss:evaluation(cfg)
    if get_level_boss(cfg) then return cfg.ca_score end
    return 0
end

function ca_boss:execution(cfg)
    -- Scenario Boss does a random wander in area given by @cfg.wandering_ground until it finds
    -- and kills an enemy unit
    -- and then rinse and repeat
    -- note most of this is just a subset of the hunter Micro AI
    -- but with no home/returning things
    -- the boss kills and eliminates anything in the defined arena

    local boss = get_level_boss(cfg)
    local boss_vars = MAIUV.get_mai_unit_variables(boss, cfg.ai_id)

    -- If boss_status is not set for the boss -> default behavior -> random wander
    if (not boss_vars.boss_status) then
        -- boss gets a new goal if none exist or on any move with 10% random chance
        local rand = math.random(10)
        if (not boss_vars.goal_x) or (rand == 1) then
            -- 'locs' includes border hexes, but that does not matter here
            locs = AH.get_passable_locations((wml.get_child(cfg, "filter_location") or {}), boss)
            local rand = math.random(#locs)

            boss_vars.goal_x, boss_vars.goal_y = locs[rand][1], locs[rand][2]
            MAIUV.set_mai_unit_variables(boss, cfg.ai_id, boss_vars)
        end

        local reach_map = AH.get_reachable_unocc(boss)

        -- Now find the one of these hexes that is closest to the goal
        local max_rating, best_hex = - math.huge
        reach_map:iter( function(x, y, v)
            -- Distance from goal is first rating
            local rating = -M.distance_between(x, y, boss_vars.goal_x, boss_vars.goal_y)

            -- Huge rating bonus if this is next to an enemy
            local enemy_hp = 500
            for xa,ya in H.adjacent_tiles(x, y) do
                local enemy = wesnoth.units.get(xa, ya)
                if AH.is_attackable_enemy(enemy) then
                    if (enemy.hitpoints < enemy_hp) then enemy_hp = enemy.hitpoints end
                end
            end
            rating = rating + 500 - enemy_hp  -- prefer attack on weakest enemy

            if (rating > max_rating) then
                max_rating, best_hex = rating, { x, y }
            end
        end)

        if (best_hex[1] ~= boss.x) or (best_hex[2] ~= boss.y) then
            AH.checked_move(ai, boss, best_hex[1], best_hex[2])  -- partial move only
            if (not boss) or (not boss.valid) then return end
        else  -- If boss did not move, we need to stop it (also delete the goal)
            AH.checked_stopunit_moves(ai, boss)
            if (not boss) or (not boss.valid) then return end
            boss_vars.goal_x, boss_vars.goal_y = nil, nil
            MAIUV.set_mai_unit_variables(boss, cfg.ai_id, boss_vars)
        end

        -- If this gets the boss to the goal, we delete the goal
        if (boss.x == boss_vars.goal_x) and (boss.y == boss_vars.goal_y) then
            boss_vars.goal_x, boss_vars.goal_y = nil, nil
            MAIUV.set_mai_unit_variables(boss, cfg.ai_id, boss_vars)
        end

        -- Finally, if the boss ended up next to enemies, attack the weakest of those
        local attack_status = boss_attack_weakest_adj_enemy(ai, boss)

        -- If the enemy was killed, boss returns home
        if boss and boss.valid and (attack_status == 'killed') then
            boss_vars.goal_x, boss_vars.goal_y = nil, nil
            --boss_vars.boss_status = 'returning'
            -- Lord-Knightmare: here, we just set it back to nil
            -- so that the boss_status is not set and then repeats
            -- from exterior if condition (line 62)
            boss_vars.boss_status = nil
            MAIUV.set_mai_unit_variables(boss, cfg.ai_id, boss_vars)

            --if cfg.show_messages then
            --    wesnoth.wml_actions.message { speaker = boss.id, message = 'Now that I have eaten, I will go back home.' }
            --end
        end

        return
    end

    -- If we got here, this means the boss is either returning, or resting
    --[[
    if (boss_vars.boss_status == 'returning') then
        local home_loc = AH.get_named_loc_xy('home', cfg)
        goto_x, goto_y = wesnoth.find_vacant_tile(home_loc[1], home_loc[2], boss)

        local next_hop = AH.next_hop(boss, goto_x, goto_y)
        if next_hop then
            AH.movefull_stopunit(ai, boss, next_hop)
            if (not boss) or (not boss.valid) then return end

            -- If there's an enemy on the 'home' hex and we got right next to it, attack that enemy
            if (M.distance_between(home_loc[1], home_loc[2], boss.x, boss.y) == 1) then
                local enemy = wesnoth.units.get(home_loc[1], home_loc[2])
                if AH.is_attackable_enemy(enemy) then
                    if cfg.show_messages then
                        wesnoth.wml_actions.message { speaker = boss.id, message = 'Get out of my home!' }
                    end

                    AH.checked_attack(ai, boss, enemy)
                    if (not boss) or (not boss.valid) then return end
                end
            end
        end

        -- We also attack the weakest adjacent enemy, if still possible
        boss_attack_weakest_adj_enemy(ai, boss)
        if (not boss) or (not boss.valid) then return end

        -- If the boss got home, start the resting counter
        if (boss.x == home_loc[1]) and (boss.y == home_loc[2]) then
            boss_vars.boss_status = 'resting'
            boss_vars.resting_until = wesnoth.current.turn + (cfg.rest_turns or 3)
            MAIUV.set_mai_unit_variables(boss, cfg.ai_id, boss_vars)

            if cfg.show_messages then
                wesnoth.wml_actions.message { speaker = boss.id, message = 'I made it home - resting now until the end of Turn ' .. boss_vars.resting_until .. ' or until fully healed.' }
            end
        end

        return
    end

    -- If we got here, the only remaining action should be resting
    if (boss_vars.boss_status == 'resting') then
        AH.checked_stopunit_moves(ai, boss)
        if (not boss) or (not boss.valid) then return end

        -- We also attack the weakest adjacent enemy
        boss_attack_weakest_adj_enemy(ai, boss)
        if (not boss) or (not boss.valid) then return end

        -- If this is the last turn of resting, we remove the status and turn variable
        if (boss.hitpoints >= boss.max_hitpoints) and (boss_vars.resting_until <= wesnoth.current.turn) then
            boss_vars.boss_status = nil
            boss_vars.resting_until = nil
            MAIUV.set_mai_unit_variables(boss, cfg.ai_id, boss_vars)

            if cfg.show_messages then
                wesnoth.wml_actions.message { speaker = boss.id, message = 'I am done resting. It is time to go boss again next turn.' }
            end
        end
        return
    end
    ]]

    -- In principle we should never get here, but just in case something got changed in WML:
    -- Reset variable, so that boss goes boss on next turn
    boss_vars.boss_status = nil
    MAIUV.set_mai_unit_variables(boss, cfg.ai_id, boss_vars)
end

return ca_boss