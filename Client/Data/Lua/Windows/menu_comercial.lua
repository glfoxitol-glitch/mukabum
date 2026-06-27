local ui = SFUI.ui
local actions = SFUI.actions
local events = ui.import("events")
local guild = ui.import("guild")
local invasion = ui.import("invasion")
local jewelbank = ui.import("jewelbank")
local quests = ui.import("quests")
local rankings = ui.import("rankings")
local resets = ui.import("resets")
local seasonpass = ui.import("systems.seasonpass")

local menu_button_normal_sprite = ui.sprite("Lua\\Texture\\simpleui.tga", 756.0, 646.0, 82.0, 84.0)
local menu_button_over_sprite = ui.sprite("Lua\\Texture\\simpleui.tga", 840.0, 646.0, 82.0, 84.0)

local function close_menu()
    ui.close("menu_comercial")
end

local function run_menu_action(action)
    local result = true
    if action then
        result = action()
    end
    close_menu()
    return result
end

local function open_lua_window(window_id, before_open)
    if before_open then
        before_open()
    end
    return ui.toggle(window_id)
end

local function toggle_native_window(before_toggle, toggle_action)
    if before_toggle then
        before_toggle()
    end
    if toggle_action then
        return toggle_action()
    end
    return false
end

actions.register("menu_comercial.close", close_menu)

local win = ui.window("menu_comercial", {
    title = "Menu Comercial",
    rect = ui.rect(240, 100, 216, 196),
    hotkey = { key = "F5", ctrl = true, alt = false, shift = false },
    fade_time = 0.15,
    closable = true,
    movable = true,
    close_button = ui.rect(196, 6, 14, 14),
    header_height = 24,
    title_position = { 12, 5 },
    title_align = "left"
})

win:panel("menu_comercial_content", {
    rect = ui.rect(8, 28, 200, 160),
    header_visible = false,
    show_background = false,
    show_border = false
})

win:text("menu_comercial_subtitle", {
    parent = "menu_comercial_content",
    rect = ui.rect(0, 0, 196, 14),
    text = "Prueba de launcher Lua + MU",
    text_color = 0xFFDDD4C8,
    font = "normal"
})

local function add_menu_button(id, x, y, text, on_click)
    return win:button(id, {
        parent = "menu_comercial_content",
        rect = ui.rect(x, y, 40, 40),
        text = text,
        texture = menu_button_normal_sprite,
        over_texture = menu_button_normal_sprite,
        click_texture = menu_button_over_sprite,
        text_offset_y = 1,
        show_background = false,
        show_border = false,
        text_color = 0xFFF6F1E6,
        disabled_text_color = 0xFF888888,
        font = "bold",
        on_click = function()
            return run_menu_action(on_click)
        end
    })
end

add_menu_button("menu_btn_eventos", 0, 20, "EV", function()
    open_lua_window("eventos", function()
        events.request_refresh()
    end)
end)

add_menu_button("menu_btn_invasion", 50, 20, "IV", function()
    open_lua_window("invasion", function()
        invasion.request_refresh()
    end)
end)

add_menu_button("menu_btn_resets", 100, 20, "RS", function()
    open_lua_window("windowsresets", function()
        resets.request_refresh()
    end)
end)

add_menu_button("menu_btn_rankings", 150, 20, "RK", function()
    open_lua_window("rankings", function()
        rankings.request_refresh()
    end)
end)

add_menu_button("menu_btn_quests_lua", 0, 70, "QL", function()
    open_lua_window("quests_panel", function()
        quests.request_refresh()
        quests.request_detail()
    end)
end)

add_menu_button("menu_btn_quests_native", 50, 70, "QN", function()
    return toggle_native_window(nil, quests.toggle_native_list)
end)

add_menu_button("menu_btn_guild_native", 100, 70, "GD", function()
    return toggle_native_window(function()
        guild.request_refresh()
    end, guild.toggle_native)
end)

add_menu_button("menu_btn_jewel_native", 150, 70, "JB", function()
    return toggle_native_window(function()
        jewelbank.request_refresh()
    end, jewelbank.toggle_native)
end)

add_menu_button("menu_btn_daily_rewards", 0, 118, "DR", function()
    return open_lua_window("daily_rewards")
end)

add_menu_button("menu_btn_admin_make", 50, 118, "MK", function()
    return open_lua_window("admin_make_panel")
end)

add_menu_button("menu_btn_seasonpass", 100, 118, "SP", function()
    return open_lua_window("daily_missions_example", function()
        seasonpass.request_refresh()
    end)
end)

win:button("menu_btn_close", {
    parent = "menu_comercial_content",
    rect = ui.rect(150, 128, 40, 20),
    text = "X",
    action = "menu_comercial.close"
})

return win
