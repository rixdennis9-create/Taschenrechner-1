-- ============================================================
--  Mod Menu V2  –  by Shelby Cooper
--  Luanti / Minetest  |  License: MIT
-- ============================================================

-- ── Per-player state ─────────────────────────────────────────
local state = {}

local function get_state(name)
    if not state[name] then
        state[name] = {
            minimized   = false,   -- popup collapsed?
            fly         = false,
            noclip      = false,
            fast        = false,
            infinite_hp = false,
            speed       = 1,
            -- last TP coords (remembered across open/close)
            tp_x = "0", tp_y = "0", tp_z = "0",
        }
    end
    return state[name]
end

-- ── Helpers ──────────────────────────────────────────────────
local function notify(name, msg)
    minetest.chat_send_player(name,
        minetest.colorize("#e94560", "[MM] ") .. msg)
end

local function on_off(val)
    return val
        and minetest.colorize("#00FF7F", "● AN ")
        or  minetest.colorize("#FF4444", "○ AUS")
end

local function apply_privs(name, s)
    local player = minetest.get_player_by_name(name)
    if not player then return end
    local privs = minetest.get_player_privs(name)
    privs.fly    = s.fly    or nil
    privs.noclip = s.noclip or nil
    privs.fast   = s.fast   or nil
    minetest.set_player_privs(name, privs)
    player:set_physics_override({ speed = s.speed })
end

-- ── Minimised popup (top-left corner, tiny) ──────────────────
--  Just a small button that re-opens the full menu.
local function build_mini(name)
    return table.concat({
        "formspec_version[4]",
        "size[3,0.7]",
        "position[0,0]",
        "anchor[0,0]",
        "no_prepend[]",
        "bgcolor[#1a1a2eCC;false]",
        "box[0,0;3,0.7;#16213e]",
        "button[0,0;2.4,0.7;expand;",
            minetest.formspec_escape("▶  Mod Menu V2"),
        "]",
    }, "")
end

-- ── Full popup (top-left, scrollable sections) ───────────────
local function build_full(name)
    local s = get_state(name)
    local player = minetest.get_player_by_name(name)

    -- Live info
    local pos_str, hp_str = "X=? Y=? Z=?", "HP: ?"
    if player then
        local p = vector.round(player:get_pos())
        pos_str = string.format("X=%d  Y=%d  Z=%d", p.x, p.y, p.z)
        hp_str  = string.format("HP: %d/%d",
            player:get_hp(), player:get_properties().hp_max or 20)
    end

    -- Speed dropdown index
    local speed_idx = ({[0.5]=1,[1]=2,[2]=3,[3]=4,[5]=5,[10]=6})[s.speed] or 2

    return table.concat({
        "formspec_version[4]",
        "size[8.4,12.2]",
        "position[0,0]",
        "anchor[0,0]",
        "no_prepend[]",
        "bgcolor[#1a1a2eCC;false]",

        -- ══ HEADER ══
        "box[0,0;8.4,1.0;#0d0d1a]",
        -- Title
        "label[0.25,0.38;",
            minetest.formspec_escape(
                minetest.colorize("#e94560","✦ Mod Menu V2") ..
                minetest.colorize("#888888","  by Shelby Cooper")
            ),
        "]",
        -- Minimise button (top-right of header)
        "button[7.55,0.08;0.75,0.75;minimize;–]",

        -- ══ WELCOME BANNER ══
        "box[0,1.05;8.4,0.65;#0f3460]",
        "label[0.3,1.37;",
            minetest.formspec_escape(
                minetest.colorize("#ffffff",
                    "Willkommen im Mod Menu V2 von Shelby Cooper")
            ),
        "]",

        -- ══ INFO BAR ══
        "box[0,1.75;8.4,0.55;#16213e]",
        "label[0.3,2.02;",
            minetest.formspec_escape(minetest.colorize("#aaddff", pos_str)),
        "]",
        "label[5.3,2.02;",
            minetest.formspec_escape(minetest.colorize("#ffdd88", hp_str)),
        "]",

        -- ══ SECTION: BEWEGUNG ══
        "box[0,2.38;8.4,0.38;#e9456022]",
        "label[0.3,2.55;",
            minetest.formspec_escape(minetest.colorize("#e94560","BEWEGUNG")),
        "]",

        -- Toggle row
        "button[0.2,2.85;2.5,0.65;toggle_fly;",
            minetest.formspec_escape("Fliegen  " .. on_off(s.fly)),
        "]",
        "button[2.85,2.85;2.5,0.65;toggle_noclip;",
            minetest.formspec_escape("Noclip   " .. on_off(s.noclip)),
        "]",
        "button[5.5,2.85;2.65,0.65;toggle_fast;",
            minetest.formspec_escape("Schnell  " .. on_off(s.fast)),
        "]",

        -- Speed row
        "label[0.3,3.78;",
            minetest.formspec_escape(minetest.colorize("#cccccc","Geschwindigkeit:")),
        "]",
        "dropdown[2.8,3.55;2.4;speed_select;0.5x,1x,2x,3x,5x,10x;" ..
            speed_idx .. "]",
        "button[5.35,3.55;2.8,0.65;apply_speed;Anwenden ✓]",

        -- ══ SECTION: ÜBERLEBEN ══
        "box[0,4.35;8.4,0.38;#e9456022]",
        "label[0.3,4.52;",
            minetest.formspec_escape(minetest.colorize("#e94560","ÜBERLEBEN")),
        "]",

        "button[0.2,4.85;4.0,0.65;toggle_hp;",
            minetest.formspec_escape("Unendliche HP  " .. on_off(s.infinite_hp)),
        "]",
        "button[4.35,4.85;3.8,0.65;heal_now;Jetzt heilen ♥]",

        "button[0.2,5.65;3.9,0.65;fill_inv;Inventar füllen]",
        "button[4.35,5.65;3.8,0.65;clear_inv;Inventar leeren]",

        -- ══ SECTION: TELEPORT ══
        "box[0,6.45;8.4,0.38;#e9456022]",
        "label[0.3,6.62;",
            minetest.formspec_escape(minetest.colorize("#e94560","TELEPORT")),
        "]",

        "field[0.2,7.15;2.5,0.65;tp_x;X;" ..
            minetest.formspec_escape(s.tp_x) .. "]",
        "field[2.9,7.15;2.5,0.65;tp_y;Y;" ..
            minetest.formspec_escape(s.tp_y) .. "]",
        "field[5.6,7.15;2.6,0.65;tp_z;Z;" ..
            minetest.formspec_escape(s.tp_z) .. "]",

        "button[0.2,7.95;4.0,0.65;do_teleport;Teleportieren ➤]",
        "button[4.35,7.95;3.8,0.65;tp_spawn;Zum Spawn ⌂]",

        -- ══ SECTION: WELT ══
        "box[0,8.75;8.4,0.38;#e9456022]",
        "label[0.3,8.92;",
            minetest.formspec_escape(minetest.colorize("#e94560","WELT & ZEIT")),
        "]",

        "button[0.2,9.25;2.6,0.65;time_day;☀  Tag]",
        "button[3.0,9.25;2.6,0.65;time_night;☽  Nacht]",
        "button[5.8,9.25;2.4,0.65;time_dawn;🌅  Morgen]",

        -- ══ SECTION: NOCLIP / XRAY INFO ══
        "box[0,10.05;8.4,0.38;#e9456022]",
        "label[0.3,10.22;",
            minetest.formspec_escape(minetest.colorize("#e94560","SONSTIGES")),
        "]",

        "button[0.2,10.55;4.0,0.65;kill_self;Selbst töten ☠]",
        "button[4.35,10.55;3.8,0.65;respawn;Respawn ↺]",

        -- ══ FOOTER ══
        "box[0,11.4;8.4,0.7;#0d0d1a]",
        "button[0.2,11.48;3.8,0.55;refresh_menu;Aktualisieren ↻]",
        "button[4.35,11.48;3.8,0.55;close_menu;Schließen ✕]",
    }, "")
end

-- ── Show helpers ─────────────────────────────────────────────
local function show_popup(name)
    local s = get_state(name)
    if s.minimized then
        minetest.show_formspec(name, "modmenu:popup", build_mini(name))
    else
        minetest.show_formspec(name, "modmenu:popup", build_full(name))
    end
end

-- ── Chat commands ─────────────────────────────────────────────
for _, cmd in ipairs({"menu", "mm", "modmenu"}) do
    minetest.register_chatcommand(cmd, {
        description = "Mod Menu V2 öffnen",
        func = function(name, _)
            get_state(name).minimized = false
            show_popup(name)
            return true, ""
        end,
    })
end

-- ── Field handler ─────────────────────────────────────────────
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "modmenu:popup" then return false end

    local name = player:get_player_name()
    local s    = get_state(name)

    -- ── Minimize / Expand ──
    if fields.minimize then
        s.minimized = true
        show_popup(name)
        return true
    end
    if fields.expand then
        s.minimized = false
        show_popup(name)
        return true
    end

    -- ── Close / Quit ──
    if fields.close_menu or fields.quit then
        return true
    end

    -- ── Refresh ──
    if fields.refresh_menu then
        show_popup(name)
        return true
    end

    -- ── Fly ──
    if fields.toggle_fly then
        s.fly = not s.fly
        apply_privs(name, s)
        notify(name, "Fliegen: " .. on_off(s.fly))
        show_popup(name)
        return true
    end

    -- ── Noclip ──
    if fields.toggle_noclip then
        s.noclip = not s.noclip
        apply_privs(name, s)
        notify(name, "Noclip: " .. on_off(s.noclip))
        show_popup(name)
        return true
    end

    -- ── Fast ──
    if fields.toggle_fast then
        s.fast = not s.fast
        apply_privs(name, s)
        notify(name, "Schnellmodus: " .. on_off(s.fast))
        show_popup(name)
        return true
    end

    -- ── Speed ──
    if fields.apply_speed then
        local map = {["0.5x"]=0.5,["1x"]=1,["2x"]=2,["3x"]=3,["5x"]=5,["10x"]=10}
        local sel = fields.speed_select or "1x"
        s.speed = map[sel] or 1
        apply_privs(name, s)
        notify(name, "Geschwindigkeit: " .. sel)
        show_popup(name)
        return true
    end

    -- ── Unendliche HP toggle ──
    if fields.toggle_hp then
        s.infinite_hp = not s.infinite_hp
        notify(name, "Unendliche HP: " .. on_off(s.infinite_hp))
        show_popup(name)
        return true
    end

    -- ── Sofort heilen ──
    if fields.heal_now then
        local hp_max = player:get_properties().hp_max or 20
        player:set_hp(hp_max)
        notify(name, "HP vollständig aufgefüllt!")
        show_popup(name)
        return true
    end

    -- ── Inventar füllen ──
    if fields.fill_inv then
        local inv   = player:get_inventory()
        local items = {
            "default:cobble","default:wood","default:stone",
            "default:dirt","default:sand","default:gravel",
            "default:torch","default:chest","default:furnace",
        }
        for i = 1, inv:get_size("main") do
            if inv:get_stack("main", i):is_empty() then
                local item = items[math.random(#items)]
                if minetest.registered_items[item] then
                    inv:set_stack("main", i, ItemStack(item .. " 99"))
                end
            end
        end
        notify(name, "Inventar gefüllt!")
        show_popup(name)
        return true
    end

    -- ── Inventar leeren ──
    if fields.clear_inv then
        player:get_inventory():set_list("main", {})
        notify(name, "Inventar geleert!")
        show_popup(name)
        return true
    end

    -- ── Teleport ──
    if fields.do_teleport then
        -- Save entered coords in state
        s.tp_x = fields.tp_x or "0"
        s.tp_y = fields.tp_y or "0"
        s.tp_z = fields.tp_z or "0"
        local x = tonumber(s.tp_x)
        local y = tonumber(s.tp_y)
        local z = tonumber(s.tp_z)
        if x and y and z then
            x = math.max(-30912, math.min(30912, x))
            y = math.max(-30912, math.min(30912, y))
            z = math.max(-30912, math.min(30912, z))
            player:set_pos({x=x, y=y, z=z})
            notify(name, string.format("Teleportiert → X=%d Y=%d Z=%d", x, y, z))
        else
            notify(name, "Ungültige Koordinaten!")
        end
        show_popup(name)
        return true
    end

    if fields.tp_spawn then
        local spawn = minetest.setting_get_pos("static_spawnpoint") or {x=0,y=0,z=0}
        player:set_pos(spawn)
        notify(name, "Zum Spawn teleportiert!")
        show_popup(name)
        return true
    end

    -- ── Zeit ──
    if fields.time_day then
        minetest.set_timeofday(0.5)
        notify(name, "Zeit → Tag (12:00)")
        show_popup(name)
        return true
    end

    if fields.time_night then
        minetest.set_timeofday(0.0)
        notify(name, "Zeit → Nacht (0:00)")
        show_popup(name)
        return true
    end

    if fields.time_dawn then
        minetest.set_timeofday(0.23)  -- ~5:30
        notify(name, "Zeit → Morgengrauen (5:30)")
        show_popup(name)
        return true
    end

    -- ── Selbst töten ──
    if fields.kill_self then
        player:set_hp(0)
        notify(name, "Du wurdest getötet.")
        return true
    end

    -- ── Respawn ──
    if fields.respawn then
        local spawn = minetest.setting_get_pos("static_spawnpoint") or {x=0,y=2,z=0}
        player:set_pos(spawn)
        player:set_hp(player:get_properties().hp_max or 20)
        notify(name, "Respawn!")
        show_popup(name)
        return true
    end

    return false
end)

-- ── Infinite HP globalstep ────────────────────────────────────
minetest.register_globalstep(function(_)
    for _, player in ipairs(minetest.get_connected_players()) do
        local s = get_state(player:get_player_name())
        if s.infinite_hp then
            local max = player:get_properties().hp_max or 20
            if player:get_hp() < max then
                player:set_hp(max)
            end
        end
    end
end)

-- ── Auto-open popup on join ───────────────────────────────────
minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    -- Short delay so world has time to load
    minetest.after(1.5, function()
        local p = minetest.get_player_by_name(name)
        if p then
            get_state(name).minimized = false
            show_popup(name)
        end
    end)
end)

-- ── Cleanup on leave ─────────────────────────────────────────
minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    if state[name] then
        local s = state[name]
        s.fly = false; s.noclip = false; s.fast = false; s.speed = 1
        apply_privs(name, s)
    end
    state[name] = nil
end)

minetest.log("action", "[Mod Menu V2] Geladen – by Shelby Cooper")
