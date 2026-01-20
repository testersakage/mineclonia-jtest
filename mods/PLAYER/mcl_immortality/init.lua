local mod_name = core.get_current_modname()
local S = core.get_translator(mod_name)

mcl_immortality = {}

-- Check whether the player is immortal.
-- Encapsulating the simple logic because it may be changed.
-- Return bool if success, nil on error
function mcl_immortality.is_immortal(player)
    local flag = player:get_meta():get_int("immortal")
    if flag == 0 then return false end
    return true
end

-- Sets (or flips) immortality setting for a player.
-- Accepts ObjectRef to a player and a flag.
-- DOES NOT check any privileges.
-- If the flag is nil, flips the setting.
function mcl_immortality.set_immortal(player, flag, set_player_setting)
    if set_player_setting == nil then
        set_player_setting = true
    end
    local pmeta = player:get_meta()
    if flag == nil then
        flag = not mcl_immortality.is_immortal(player)
    end
    if set_player_setting then
        mcl_player.set_player_setting(player, "mcl_immortality:immortal", flag)
    end

    local p_armor_groups = player:get_armor_groups()
    p_armor_groups["immortal"] = flag and 1 or nil
    player:set_armor_groups(p_armor_groups)
    pmeta:set_int("immortal", flag and 1 or 0)


    if flag then
        for _, hudbar_name in ipairs({ "hunger", "health", "breath", "armor" }) do
            hb.hide_hudbar(player, hudbar_name)
        end

        core.chat_send_player(player:get_player_name(), S("You are now immortal."))
    else
        for _, hudbar_name in ipairs({ "hunger", "health", "breath", "armor" }) do
            hb.unhide_hudbar(player, hudbar_name)
        end

        core.chat_send_player(player:get_player_name(), S("You are now mortal."))
    end
end

core.register_privilege("immortality", {
    description = S("Grants an ability to make self (im)mortal"),
    give_to_singleplayer = false,
    give_to_admin = true,
    on_grant = function(name, granter)
        if not granter then return end

        core.chat_send_player(name,
            S("You have received a privilege for granting immortality for self."))
        return nil
    end,
    on_revoke = function(name, revoker)
        if not revoker then return end

        local player = core.get_player_by_name(name)
        local privs = core.get_player_privs(name)
        -- Revoke "others" permission variation.
        -- What's the point of revoking just this if they could
        -- continue changing immortality using "others" privilege?
        if privs["immortality_others"] then
            core.change_player_privs(name, {
                ["immortality_others"] = false
            })
        end
        mcl_immortality.set_immortal(player, false)

        core.chat_send_player(name, S("Your privilege for immortality was revoked. You are now mortal."))
        return nil
    end
})

core.register_privilege("immortality_others", {
    description = S("Grants an ability to make self and others (im)mortal"),
    give_to_singleplayer = false,
    give_to_admin = true,
    on_grant = function(name, granter)
        if not granter then return end
        local privs = core.get_player_privs(name)
        if not privs["immortality"] then
            core.change_player_privs(name, {
                ["immortality"] = true
            })
        end
        core.chat_send_player(name,
            S("You have received a privilege for granting immortality for others and self."))
    end,
    on_revoke = function(name, revoker)
        if not revoker then return end
        core.chat_send_player(name,
            S("Your privilege for others immortality was revoked. You cannot change immortality of others now."))
    end
})

core.register_chatcommand("immortal", {
    description = S("Turn immortality on and off for self or listed player(s) (requires additional priv)"),
    params = "[<name1>[, <name2> [<...>]]]",
    privs = { ["immortality"] = true },
    func = function(name, param)
        local names = param:split(",")
        local player = core.get_player_by_name(name)
        if #names == 0 then
            mcl_immortality.set_immortal(player)
            return true
        end

        if not (core.check_player_privs(player, "immortal_others")) then
            return false, S("You do not have the privilege for setting others' immortality.")
        end

        for _, victim_name in ipairs(names) do
            mcl_immortality.set_immortal(core.get_player_by_name(victim_name))
        end
        return true, S("Player(s) received their (im)mortality")
    end
})

core.register_on_joinplayer(function(player)
    if mcl_immortality.is_immortal(player) then
        mcl_immortality.set_immortal(player, true)
    end
end)

mcl_player.register_player_setting("mcl_immortality:immortal", {
	type = "boolean",
	section = "Gameplay",
	short_desc = S("Enable immortality"),
	long_desc = S([[Enables immortality. You won't receive any damage. 
Stays on when you turn off creative mode. Requires 'immortality' or 'immortality_others' privilege.
On its revoke, immortality turns off automatically.]]),
	ui_default = function(player)
        if player == nil then return end
        return mcl_immortality.is_immortal(player)
    end,
	on_change = function(player, _, flag)
        if player == nil then return end
        if flag == nil then flag = false end
        mcl_immortality.set_immortal(player, flag, false)
    end,
    settings_ui_default = false
})