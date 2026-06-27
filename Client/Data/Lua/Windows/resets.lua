local ui = SFUI.ui
local binding = ui.import("binding")
local attributes = ui.import("attributes")
local resets = ui.import("resets")

local function to_number(value, fallback)
    local parsed = tonumber(value)
    if parsed == nil then
        return fallback or 0
    end
    return parsed
end

local function format_number(value)
    local text = tostring(math.floor(to_number(value, 0)))
    local formatted = text

    while true do
        local next_text, count = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1.%2")
        formatted = next_text
        if count == 0 then
            break
        end
    end

    return formatted
end

local function get_current_reset_tab()
    return to_number(binding.get("reset_panel.tab"), 0)
end

local function get_active_reset_info()
    if get_current_reset_tab() == 1 then
        return resets.get_master_reset_info()
    end
    return resets.get_reset_info()
end

local function sync_reset_panel()
    local info = get_active_reset_info() or {}
    local name = info.name or "Reset"
    local enabled = info.enabled == true
    local current = to_number(info.current, 0)
    local max = to_number(info.max, 0)
    local min_level = to_number(info.min_level, 0)
    local min_reset = to_number(info.min_reset, 0)
    local req_money = to_number(info.req_money, 0)
    local reward_point = to_number(info.reward_point, 0)
    local target_count = current + 1
    local reward_label = "Reward"
    local requirements_label = attributes.get_global_text(2809) or "Requirements"
    local inactive_text = enabled and "" or "Sistema no disponible"
    local current_level = to_number(info.current_level, 0)
    local current_reset = to_number(info.current_reset, 0)
    local current_zen = to_number(info.current_zen, 0)
    local met_level = info.met_level == true
    local met_reset = info.met_reset == true
    local met_zen = info.met_zen == true

    binding.set("reset_panel.current_info", info)
    binding.set("reset_panel.required_items", info.required_items or {})
    binding.set("reset_panel.section_title", string.format("%s %d", name, target_count))
    binding.set("reset_panel.progress", string.format("%s: %d / %d", name, current, max))
    binding.set("reset_panel.requirements_title", requirements_label)
    binding.set("reset_panel.level_text", string.format("Level: %s / %s", format_number(current_level), format_number(min_level)))
    binding.set("reset_panel.reset_text", min_reset > 0 and string.format("Reset: %s / %s", format_number(current_reset), format_number(min_reset)) or "")
    binding.set("reset_panel.zen_text", string.format("Zen: %s / %s", format_number(current_zen), format_number(req_money)))
    binding.set("reset_panel.reward_title", reward_label)
    binding.set("reset_panel.reward_text", string.format("Reward Points: %s", format_number(reward_point)))
    binding.set("reset_panel.summary", info.summary or resets.get_summary())
    binding.set("reset_panel.inactive_text", inactive_text)
    binding.set("reset_panel.action_text", enabled and "Listo para revisar requisitos" or "Sin informacion disponible")
    binding.set("reset_panel.level_met", met_level and enabled)
    binding.set("reset_panel.reset_met", met_reset and enabled)
    binding.set("reset_panel.zen_met", met_zen and enabled)
end

binding.set("reset_panel.tab", 0)
sync_reset_panel()

local win = ui.window("windowsresets", {
    title = resets.get_title(),
    rect = ui.rect(600, 80, 292, 408),
    hotkey = "F8",
    fade_time = 0.25,
    closable = true,
    movable = true,
    on_open = function()
        resets.request_refresh()
        sync_reset_panel()
    end
})

win:panel("reset_content", {
    rect = ui.rect(0, 24, 292, 384),
    header_visible = false,
    show_background = false,
    show_border = false,
    padding_left = 0,
    padding_top = 0,
    padding_right = 0,
    padding_bottom = 0
})

win:text("summary", {
    parent = "reset_content",
    rect = ui.rect(16, 40, 252, 18),
    text = resets.get_summary(),
    align = "center",
    font = "bold",
    bind = "reset_panel.summary",
    text_color = 0xFF9AE8FF
})

win:tabs("reset_tabs", {
    parent = "reset_content",
    rect = ui.rect(34, 14, 56, 22),
    spacing = 4,
    current_bind = "reset_panel.tab",
    texture = ui.sprite("Lua\\Texture\\sfui_btn_tab.tga", 0, 0, 224.0, 88.0),
    tabs = {
        { text = "Reset", value = 0 },
        { text = "Master Reset", value = 1 }
    },
    on_change = function(index, value)
        binding.set("reset_panel.tab", value)
        sync_reset_panel()
    end
})

win:text("section_title", {
    parent = "reset_content",
    rect = ui.rect(20, 64, 240, 24),
    text = "Reset 1",
    align = "center",
    font = "big",
    bind = "reset_panel.section_title",
    text_color = 0xFFFFD768
})

win:text("progress", {
    parent = "reset_content",
    rect = ui.rect(20, 92, 240, 18),
    text = "Reset: 0 / 0",
    align = "center",
    font = "bold",
    bind = "reset_panel.progress",
    text_color = 0xFFFFF6B4
})

win:text("inactive_text", {
    parent = "reset_content",
    rect = ui.rect(20, 112, 240, 18),
    text = "",
    align = "center",
    font = "bold",
    bind = "reset_panel.inactive_text",
    text_color = 0xFFFF7A7A
})

win:text("requirements_title", {
    parent = "reset_content",
    rect = ui.rect(20, 130, 240, 18),
    text = attributes.get_global_text(2809),
    font = "bold",
    bind = "reset_panel.requirements_title",
    text_color = 0xFFFFA644,
    background_color = 0x6A000000
})

win:text("level_text", {
    parent = "reset_content",
    rect = ui.rect(20, 152, 240, 18),
    text = "Level: 0",
    bind = "reset_panel.level_text",
    enabled_bind = "reset_panel.level_met",
    text_color = 0xFF59FF7A,
    disabled_text_color = 0xFF9A9A9A
})

win:text("reset_text", {
    parent = "reset_content",
    rect = ui.rect(20, 170, 240, 18),
    text = "",
    bind = "reset_panel.reset_text",
    enabled_bind = "reset_panel.reset_met",
    text_color = 0xFF59FF7A,
    disabled_text_color = 0xFF9A9A9A
})

win:text("zen_text", {
    parent = "reset_content",
    rect = ui.rect(20, 188, 240, 18),
    text = "Zen: 0",
    bind = "reset_panel.zen_text",
    enabled_bind = "reset_panel.zen_met",
    text_color = 0xFF59FF7A,
    disabled_text_color = 0xFF9A9A9A
})

win:text("reward_title", {
    parent = "reset_content",
    rect = ui.rect(20, 218, 240, 18),
    text = "Reward",
    font = "bold",
    bind = "reset_panel.reward_title",
    text_color = 0xFFFFA644,
    background_color = 0x6A000000
})

win:text("reward_text", {
    parent = "reset_content",
    rect = ui.rect(20, 240, 240, 18),
    text = "Reward Points: 0",
    bind = "reset_panel.reward_text",
    text_color = 0xFF59FF7A
})

win:label("required_items_title", {
    parent = "reset_content",
    rect = ui.rect(20, 270, 240, 18),
    text = "Required Items",
    font = "bold",
    text_color = 0xFFFFA644,
    background_color = 0x6A000000
})

win:item_list("required_items", {
    parent = "reset_content",
    rect = ui.rect(20, 292, 240, 54),
    row_height = 26,
    model_size = 22,
    bind = "reset_panel.required_items",
    on_item_selected = function(index)
    end
})

win:button("refresh", {
    parent = "reset_content",
    rect = ui.rect(20, 358, 100, 20),
    text = "Actualizar",
    on_click = function()
        resets.request_refresh()
        sync_reset_panel()
    end
})

win:button("close", {
    parent = "reset_content",
    rect = ui.rect(160, 358, 100, 20),
    text = "Cerrar",
    on_click = function()
        win:close()
    end
})

return win
