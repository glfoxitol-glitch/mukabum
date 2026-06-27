local ui = SFUI.v2

local colors = {
    panel = ui.color(8, 9, 13, 150),
    panel_line = ui.color(220, 170, 60, 90),
    text = ui.color(245, 238, 218, 255),
    muted = ui.color(190, 178, 150, 255),
    gold = ui.color(255, 210, 70, 255),
    hp = ui.color(190, 38, 38, 245),
    hp_track = ui.color(42, 10, 10, 220),
    mp = ui.color(42, 92, 210, 245),
    mp_track = ui.color(10, 16, 45, 220),
    shield = ui.color(245, 194, 39, 220),
    shield_track = ui.color(34, 34, 46, 200),
    exp = ui.color(194, 245, 39, 255),
    exp_track = ui.color(48, 40, 26, 210),
}

local win = ui.window {
    id = "player_hud_example",
    rect = ui.rect(18, 0, 356, 100),
    title = "",
    start_open = true,
    closable = false,
    movable = true,
    hotkey = { key = "H", ctrl = true, alt = false, shift = false },
    style = {
        border_visible = false,
        background_visible = false,
        header_visible = false,
        title_visible = false,
    },
}

win:panel("hud_back", {
    rect = ui.rect(0, 0, 356, 100),
    background_color = colors.panel,
    border_color = colors.panel_line,
    header_visible = false,
})

win:circle_progress("exp_ring", {
    rect = ui.rect(12, 10, 78, 78),
    bind = "player.exp_ratio",
    ring_thickness = 8,
    background_color = colors.exp_track,
    fill_color = colors.exp,
})

win:label("level_caption", {
    rect = ui.rect(12, 27, 78, 14),
    text = "LV",
    align = "center",
    text_color = colors.muted,
})

win:label("level_value", {
    rect = ui.rect(12, 40, 78, 24),
    text_bind = "player.level",
    align = "center",
    text_color = colors.gold,
})

win:label("exp_text", {
    rect = ui.rect(12, 66, 78, 14),
    text_bind = "player.exp_text",
    align = "center",
    text_color = colors.muted,
})

win:label("name", {
    rect = ui.rect(104, 10, 224, 18),
    text_bind = "player.name",
    align = "left",
    text_color = colors.text,
})

win:progress_bar("hp_bar", {
    rect = ui.rect(100, 32, 120, 12),
    bind = "player.hp_ratio",
    background_color = colors.hp_track,
    fill_color = colors.hp,
})

win:label("hp_text", {
    rect = ui.rect(100, 32, 120, 12),
    text_bind = "player.hp_text",
    align = "center",
    text_color = colors.text,
})

win:label("hp_caption", {
    rect = ui.rect(104, 32, 34, 14),
    text = "HP",
    align = "left",
    text_color = colors.muted,
})

win:progress_bar("mp_bar", {
    rect = ui.rect(100, 44, 120, 12),
    bind = "player.mp_ratio",
    background_color = colors.mp_track,
    fill_color = colors.mp,
})

win:label("mp_text", {
    rect = ui.rect(100, 44, 120, 12),
    text_bind = "player.mp_text",
    align = "center",
    text_color = colors.text,
})

win:label("mp_caption", {
    rect = ui.rect(104, 44, 34, 14),
    text = "MP",
    align = "left",
    text_color = colors.muted,
})

win:progress_bar("shield_bar", {
    rect = ui.rect(100, 56, 120, 8),
    bind = "player.shield_ratio",
    background_color = colors.shield_track,
    fill_color = colors.shield,
})

return win
