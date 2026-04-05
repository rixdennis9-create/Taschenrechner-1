-- ============================================================
--  ModMenu  –  Feature-rich in-game menu for Luanti/Minetest
--  Author : Dennis
--  License: MIT
-- ============================================================

local modmenu = {}

-- ── Per-player state ─────────────────────────────────────────
local state = {}   -- state[player_name] = { ... }

local function get_state(name)
    if not state[name] then
        state[name] = {
            fly       = false,
            noclip    = false,
            fast      = false,
            infinite_hp = false,
            xray      = false,
            speed     = 1,
        }
    end
    return state[name]
end

-- ── Helpers ──────────────────────────────────────────────────
local function notify(name, msg)
    minetest.chat_send_player(name, minetest.colorize("#00FF7F", "[ModMenu] ") .. msg)
end

local function bool_label(val)
    if val then
        return minetest.colorize("#00FF7F", "AN")
    else
        return minetest.colorize("#FF4444", "AUS")
    end
end

local function apply_privs(name, s)
    local player = minetest.get_player_by_name(name)
    if not player then return end

    -- Privilege-based features (only if server allows)
    local privs = minetest.get_player_privs(name)

    if s.fly then
        privs.fly = true
    else
        privs.fly = nil
    end

    if s.noclip then
        privs.noclip = true
    else
        privs.noclip = nil
    end

    if s.fast then
        privs.fast = true
    else
        privs.fast = nil
    end

    minetest.set_player_privs(name, privs)

    -- Physics override for speed
    player:set_physics_override({
        speed = s.speed,
    })
end

local function apply_hp(name, s)
    local player = minetest.get_player_by_name(name)
    if not player then return end
    if s.infinite_hp then
        player:set_hp(player:get_properties().hp_max or 20)
    end
end

-- ── Formspec builder ─────────────────────────────────────────
local function build_main_formspec(name)
    local s = get_state(name)
    local player = minetest.get_player_by_name(name)

    local pos_text = "Position: ?"
    if player then
        local p = vector.round(player:get_pos())
        pos_text = string.format("Position: X=%d  Y=%d  Z=%d", p.x, p.y, p.z)
    end

    local hp_text = "HP: ?"
    if player then
        hp_text = string.format("HP: %d / %d",
            player:get_hp(),
            player:get_properties().hp_max or 20)
    end

    return table.concat({
        "formspec_version[4]",
        "size[9,10]",
        "bgcolor[#1a1a2e;true]",

        -- ── Header ──
        "box[0,0;9,0.8;#16213e]",
        "label[0.3,0.45;",
            minetest.formspec_escape(
                minetest.colorize("#e94560", "✦ MOD MENU ✦") ..
                "  " ..
                minetest.colorize("#aaaaaa", "by Dennis")
            ),
        "]",

        -- ── Info panel ──
        "box[0,0.9;9,0.6;#0f3460]",
        "label[0.3,1.18;", minetest.formspec_escape(
            minetest.colorize("#ffffff", pos_text)), "]",
        "label[5.0,1.18;", minetest.formspec_escape(
            minetest.colorize("#ffffff", hp_text)), "]",

        -- ── Movement section ──
        "box[0,1.65;9,0.4;#16213e]",
        "label[0.3,1.83;", minetest.formspec_escape(
            minetest.colorize("#e94560", "BEWEGUNG")), "]",

        -- Fly toggle
        "checkbox[0.3,2.3;toggle_fly;Fliegen  [" .. bool_label(s.fly) .. "];" ..
            (s.fly and "true" or "false") .. "]",

        -- Noclip toggle
        "checkbox[3.2,2.3;toggle_noclip;Noclip  [" .. bool_label(s.noclip) .. "];" ..
            (s.noclip and "true" or "false") .. "]",

        -- Fast toggle
        "checkbox[6.1,2.3;toggle_fast;Schnell  [" .. bool_label(s.fast) .. "];" ..
            (s.fast and "true" or "false") .. "]",

        -- Speed slider (via dropdown)
        "label[0.3,3.1;", minetest.formspec_escape(
            minetest.colorize("#cccccc", "Geschwindigkeit:")), "]",
        "dropdown[2.5,2.85;2.2;speed_select;0.5x,1x,2x,3x,5x,10x;" ..
            (({[0.5]=1,[1]=2,[2]=3,[3]=4,[5]=5,[10]=6})[s.speed] or 2) ..
        "]",
        "button[5.0,2.75;1.8,0.6;apply_speed;Anwenden]",

        -- ── Survival section ──
        "box[0,3.7;9,0.4;#16213e]",
        "label[0.3,3.88;", minetest.formspec_escape(
            minetest.colorize("#e94560", "ÜBERLEBEN")), "]",

        "checkbox[0.3,4.35;toggle_hp;Unendliche HP  [" .. bool_label(s.infinite_hp) .. "];" ..
            (s.infinite_hp and "true" or "false") .. "]",

        "button[0.3,4.85;2.8,0.7;heal_now;Jetzt heilen ♥]",
        "button[3.3,4.85;2.8,0.7;fill_inv;Inventar füllen]",
        "button[6.3,4.85;2.4,0.7;clear_inv;Inventar leeren]",

        -- ── Teleport section ──
        "box[0,5.8;9,0.4;#16213e]",
        "label[0.3,5.98;", minetest.formspec_escape(
            minetest.colorize("#e94560", "TELEPORT")), "]",

        "field[0.3,6.65;2.5,0.7;tp_x;X;0]",
        "field[3.0,6.65;2.5,0.7;tp_y;Y;0]",
        "field[5.7,6.65;2.5,0.7;tp_z;Z;0]",
        "button[0.3,7.5;4,0.7;do_teleport;Teleportieren]",
        "button[4.5,7.5;4.2,0.7;tp_spawn;Zum Spawn]",

        -- ── Time section ──
        "box[0,8.4;9,0.4;#16213e]",
        "label[0.3,8.58;", minetest.formspec_escape(
            minetest.colorize("#e94560", "WELT")), "]",

        "button[0.3,9.0;2.5,0.6;time_day;Tag]",
        "button[3.05,9.0;2.5,0.6;time_night;Nacht]",
        "button[5.8,9.0;2.8,0.6;close_menu;Schließen]",
    }, "")
end

-- ── Show / Close menu ─────────────────────────────────────────
local function open_menu(name)
    minetest.show_formspec(name, "modmenu:main", build_main_formspec(name))
end

-- ── Register chat command ─────────────────────────────────────
minetest.register_chatcommand("menu", {
    description = "ModMenu öffnen",
    func = function(name, _)
        open_menu(name)
        return true, ""
    end,
})

minetest.register_chatcommand("mm", {
    description = "ModMenu öffnen (Kurzbefehl)",
    func = function(name, _)
        open_menu(name)
        return true, ""
    end,
})

-- ── Field handler ─────────────────────────────────────────────
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "modmenu:main" then return false end

    local name = player:get_player_name()
    local s    = get_state(name)
    local refresh = false

    -- ── Toggle checkboxes ──
    if fields.toggle_fly ~= nil then
        s.fly = (fields.toggle_fly == "true")
        apply_privs(name, s)
        notify(name, "Fliegen: " .. bool_label(s.fly))
        refresh = true
    end

    if fields.toggle_noclip ~= nil then
        s.noclip = (fields.toggle_noclip == "true")
        apply_privs(name, s)
        notify(name, "Noclip: " .. bool_label(s.noclip))
        refresh = true
    end

    if fields.toggle_fast ~= nil then
        s.fast = (fields.toggle_fast == "true")
        apply_privs(name, s)
        notify(name, "Schnellmodus: " .. bool_label(s.fast))
        refresh = true
    end

    if fields.toggle_hp ~= nil then
        s.infinite_hp = (fields.toggle_hp == "true")
        notify(name, "Unendliche HP: " .. bool_label(s.infinite_hp))
        refresh = true
    end

    -- ── Speed ──
    if fields.apply_speed and fields.speed_select then
        local map = {["0.5x"]=0.5,["1x"]=1,["2x"]=2,["3x"]=3,["5x"]=5,["10x"]=10}
        s.speed = map[fields.speed_select] or 1
        apply_privs(name, s)
        notify(name, "Geschwindigkeit: " .. fields.speed_select)
        refresh = true
    end

    -- ── Heal now ──
    if fields.heal_now then
        local hp_max = player:get_properties().hp_max or 20
        player:set_hp(hp_max)
        notify(name, "HP vollständig aufgefüllt!")
        refresh = true
    end

    -- ── Inventory fill ──
    if fields.fill_inv then
        local inv = player:get_inventory()
        local items = {"default:cobble","default:wood","default:stone",
                       "default:dirt","default:sand","default:gravel"}
        for i = 1, inv:get_size("main") do
            if inv:get_stack("main", i):is_empty() then
                local item = items[math.random(#items)]
                if minetest.registered_items[item] then
                    inv:set_stack("main", i, ItemStack(item .. " 99"))
                end
            end
        end
        notify(name, "Inventar mit Blöcken gefüllt!")
        refresh = true
    end

    -- ── Inventory clear ──
    if fields.clear_inv then
        local inv = player:get_inventory()
        inv:set_list("main", {})
        notify(name, "Inventar geleert!")
        refresh = true
    end

    -- ── Teleport ──
    if fields.do_teleport then
        local x = tonumber(fields.tp_x)
        local y = tonumber(fields.tp_y)
        local z = tonumber(fields.tp_z)
        if x and y and z then
            -- Clamp to reasonable world bounds
            x = math.max(-30912, math.min(30912, x))
            y = math.max(-30912, math.min(30912, y))
            z = math.max(-30912, math.min(30912, z))
            player:set_pos({x=x, y=y, z=z})
            notify(name, string.format("Teleportiert nach X=%d Y=%d Z=%d", x, y, z))
        else
            notify(name, "Ungueltige Koordinaten!")
        end
        refresh = true
    end

    if fields.tp_spawn then
        local spawn = minetest.setting_get_pos("static_spawnpoint") or {x=0,y=0,z=0}
        player:set_pos(spawn)
        notify(name, "Zum Spawn teleportiert!")
        refresh = true
    end

    -- ── Time control ──
    if fields.time_day then
        minetest.set_timeofday(0.5)   -- 12:00 noon
        notify(name, "Zeit auf Tag gesetzt (12:00)")
        refresh = true
    end

    if fields.time_night then
        minetest.set_timeofday(0.0)   -- midnight
        notify(name, "Zeit auf Nacht gesetzt (0:00)")
        refresh = true
    end

    -- ── Close ──
    if fields.close_menu or fields.quit then
        return true
    end

    -- Refresh the menu to reflect new state
    if refresh then
        open_menu(name)
    end

    return true
end)

-- ── Infinite HP loop ──────────────────────────────────────────
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local s    = get_state(name)
        if s.infinite_hp then
            local hp_max = player:get_properties().hp_max or 20
            if player:get_hp() < hp_max then
                player:set_hp(hp_max)
            end
        end
    end
end)

-- ── Cleanup on leave ─────────────────────────────────────────
minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    -- Reset privs to base before cleaning up
    if state[name] then
        local s = state[name]
        s.fly     = false
        s.noclip  = false
        s.fast    = false
        s.speed   = 1
        apply_privs(name, s)
    end
    state[name] = nil
end)

-- ── Welcome message ───────────────────────────────────────────
minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    minetest.after(2, function()
        notify(name, "Tippe  /menu  oder  /mm  um das Mod Menu zu oeffnen!")
    end)
end)

minetest.log("action", "[modmenu] Geladen – /menu oder /mm zum Öffnen")
