-- Global SFUI skin.
-- Este archivo carga antes que las ventanas cuando se llama skin.lua.

local UI_ROOT = "Lua\\Texture\\craftpix\\"

local WINDOW_BG = UI_ROOT .. "Window_Background.craftpix"
local WINDOW_HEADER = UI_ROOT .. "Window_Header.craftpix"

local INPUT_BG = UI_ROOT .. "InputField_Background2.craftpix"
local INPUT_FOCUS = UI_ROOT .. "InputField_Focus.craftpix"
local BUTTON_BG = UI_ROOT .. "BottomBar_Background.craftpix"
local BUTTON_CLOSE = "Lua\\Texture\\sfui_btn_exit.jpg"
local CHECKBOX_BG = UI_ROOT .. "Checkbox_Background.craftpix"
local COMBO_ARROW = UI_ROOT .. "Combo_Arrow.craftpix"



local frame64 = 8

local function nine(path, u, v, uw, vh, slice)
    return ui.layers(
        ui.layer.nine(path, ui.region(u, v, uw, vh), slice or frame64)
    )
end

local function sprite(path, u, v, uw, vh)
    return ui.sprite(path, ui.region(u, v, uw, vh))
end

ui.default.style("window", {
    background_color = 0xD60A0A0A,
    title_color = 0xF5292938,
    title_text_color = 0xFFFFE6C8,
    border_color = 0x00000000,
    show_background = true,
    show_border = false,
    show_header = true,
    header_height = 20
})

ui.default.style("window::background",
    nine(WINDOW_BG, 3.0, 3.0, 26.0, 26.0, frame64)
)

ui.default.style("window::header",
    nine(WINDOW_HEADER, 3.0, 3.0, 26.0, 26.0, frame64)
)



ui.default.style("window::close_button", {
    close_button_texture = {
        texture = BUTTON_CLOSE,
        u = 0.0,
        v = 0.0,
        uw = 52.0,
        vh = 56.0,
        state_height = 56,
        default_over = false,
        default_click = true,
        default_disable = false
    },
    close_button = {
        x = 4,
        y = 3,
        width = 14,
        height = 14
    }
})


ui.default.style("textbox:normal",
    nine(INPUT_BG, 3.0, 3.0, 26.0, 26.0, frame64)
)

ui.default.style("textbox:focus::glow",
    nine(INPUT_FOCUS, 0.0, 0.0, 32.0, 32.0, frame64)
)


ui.default.style("combobox", {
    text_color = 0xFFF5B427,
    disabled_text_color = 0xFF777777,
    show_background = true,
    show_border = false,
    padding_x = 4,
    padding_y = 2
})

ui.default.style("combobox::background",
    nine(INPUT_BG, 3.0, 3.0, 26.0, 26.0, frame64)
)

ui.default.style("combobox::arrow", {
    width = 8,
    height = 5,
    slot_width = 0,
    margin_right = 4,
    offset_y = 0
})

ui.default.style("combobox:collapsed",
    sprite(COMBO_ARROW, 0.0, 0.0, 16.0, 10.0)
)

ui.default.style("combobox:expanded",
    sprite(COMBO_ARROW, 0.0, 10.0, 16.0, 10.0)
)


ui.default.style("button", {
    text_color = 0xFFFFE6C0,
    disabled_text_color = 0xFF777777,
    text_offset_y = -1,
    default_over = true,
    default_click = true,
    default_disable = false
})

ui.default.style("button:normal, button:hover, button:active",
    nine(BUTTON_BG, 0.0, 0.0, 32.0, 32.0, frame64)
)



ui.default.style("checkbox", {
    text_color = 0xFFFFE6C0,
    disabled_text_color = 0xFF777777,
    checked_text_color = 0xFFFFE6C0,
    unchecked_text_color = 0xFFB8AA90,
    box_size = 18
})

-- Checkbox: sprite/atlas, no nine-scale.
ui.default.style("checkbox:unchecked",
    sprite(CHECKBOX_BG, 0.0, 0.0, 24.0, 24.0)
)

ui.default.style("checkbox:checked",
    sprite(CHECKBOX_BG, 0.0, 24.0, 24.0, 24.0)
)
