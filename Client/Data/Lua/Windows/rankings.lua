local ui = SFUI.ui
local rankings = ui.import("rankings")

local win = ui.window("rankings", {
    title = rankings.get_title(),
    rect = ui.rect(40, 80, 360, 230),
    hotkey = "F6",
    fade_time = 0.15,
    closable = true,
    movable = true,
    show_header = false,
    show_border = false,
    show_background = false,
    header_height = 20,
    title_position = { 180, 0 },
    title_align = "center",
    close_button = ui.rect(345, 3, 13, 14),
    background_texture = ui.sprite("Engine\\HUD\\panel_back08.tga", 0.0, 0.0, 530.0, 344.0),
    close_button_texture = {
        path = "Lua\\Texture\\sfui_btn_exit.jpg",
        state_height = 56,
        default_over = true,
        default_click = true,
        default_disable = true,
        u = 0.0,
        v = 0.0,
        uw = 52.0,
        vh = 56.0
    },
    on_open = function()
        rankings.request_refresh()
    end
})

win:panel("rankings_content", {
    rect = ui.rect(0, 20, 360, 210),
    header_visible = false,
    show_background = false,
    show_border = false,
    padding_left = 0,
    padding_top = 0,
    padding_right = 0,
    padding_bottom = 0
})

win:text("summary", {
    parent = "rankings_content",
    rect = ui.rect(12, 3, 220, 18),
    text = rankings.get_summary(),
    bind = "rankings.summary"
})

win:selector("tabs", {
    parent = "rankings_content",
    rect = ui.rect(140, 186, 94, 22),
    current_bind = "rankings.current_tab",
    max_bind = "rankings.max_tabs",
    wrap = false,
    format_text = function(current, max)
        return string.format("%d / %d", current + 1, max)
    end,
    on_change = function(index)
        rankings.request_tab(index)
    end
})

win:meta_table("ranking_table", {
    parent = "rankings_content",
    rect = ui.rect(20, 16, 220, 160),
    header_height = 18,
    row_height = 16,
    show_header = true,
    source = "rankings.rows",
    columns = {
        { header = "#", field = "{$idx}", width = 26, align = "center" },
        { header = "Personagem:", field = "{$name}", width = 110, align = "left" },
        { header = "Class", field = "{$class}", width = 70, align = "center" },
        { header = "Score", template = "{$score}", width = 60, align = "center" }
    },
    on_row_selected = function(rowIndex)
        rankings.request_character(rowIndex)
    end,
    style = {
        border_color = 0xFF000000,
        selected_row_color = 0xA05A2A14,
        hover_row_color = 0x80383846,
        header_text_color = 0xFFFFE4C0,
        row_text_color = 0xFFF4F4F4
    }
})

win:character_preview("ranking_preview", {
    parent = "rankings_content",
    rect = ui.rect(268, 0, 90, 210),
    interactive = false,
    copy_hero_on_invalid = true,
    angle = 90.0,
    zoom = 0.80,
    bind = "rankings.preview"
})

return win
