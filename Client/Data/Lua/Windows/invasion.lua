local ui = SFUI.ui
local binding = ui.import("binding")
local invasion = ui.import("invasion")

local function create_item_list_bridge(def)
    local function get_rows()
        local rows = def.rows_provider()
        if type(rows) ~= "table" then
            return {}
        end
        return rows
    end

    local bridge = {}

    function bridge.get_rows()
        return get_rows()
    end

    function bridge.get_count()
        return #get_rows()
    end

    function bridge.build_items()
        local items = {}
        for _, row in ipairs(get_rows()) do
            items[#items + 1] = def.item_builder(row)
        end
        return items
    end

    function bridge.clear_selection()
        binding.set(def.selected_index_bind, -1)
        binding.set(def.selected_value_bind, -1)
    end

    function bridge.sync_selected(preferred_index)
        local rows = get_rows()
        if #rows == 0 then
            bridge.clear_selection()
            return nil
        end

        local selected_index = preferred_index
        if selected_index == nil then
            selected_index = tonumber(binding.get(def.selected_index_bind)) or -1
        end

        if selected_index < 0 or selected_index >= #rows then
            selected_index = 0
        end

        local row = rows[selected_index + 1]
        binding.set(def.selected_index_bind, selected_index)
        binding.set(def.selected_value_bind, def.selected_value_getter(row))
        return row
    end

    function bridge.get_selected()
        return bridge.sync_selected(nil)
    end

    return bridge
end

local function get_invasion_rows()
    local rows = invasion.get_rows()
    if type(rows) ~= "table" then
        return {}
    end
    return rows
end

local invasion_list_bridge
local monster_list_bridge

local function get_selected_invasion()
    return invasion_list_bridge.get_selected()
end

local function get_monster_rows()
    local invasion_row = get_selected_invasion()
    if not invasion_row or type(invasion_row.monsters) ~= "table" then
        return {}
    end
    return invasion_row.monsters
end

local function get_invasion_badge(row)
    if not row then
        return ""
    end
    return row.active and "[ON]" or "[WAIT]"
end

local function get_invasion_footer(row)
    if not row then
        return ""
    end
    if row.active then
        return "Tiempo restante: " .. (row.time or "--:--:--")
    end
    return "Estado actual: OFFLINE"
end

local function get_invasion_color(row)
    if not row then
        return 0xFFF0F0F0
    end
    return row.active and 0xFF8BFF98 or 0xFFFFB0A0
end

local function build_invasion_item(row)
    return {
        item_index = -1,
        header = "Invasion",
        name = row.name or "Sin nombre",
        footer = get_invasion_footer(row),
        badge = get_invasion_badge(row),
        count = tonumber(row.monster_count) or 0,
        text_color = get_invasion_color(row)
    }
end

local function build_monster_item(row)
    local kills = tonumber(row and row.monster_kill) or 0
    local total = tonumber(row and row.monster_count) or 0
    local remaining = tonumber(row and row.remaining) or math.max(total - kills, 0)

    return {
        item_index = -1,
        header = "Monster",
        name = string.format("Monster #%d", tonumber(row and row.monster_index) or -1),
        footer = string.format("Kills: %d / %d", kills, total),
        badge = string.format("[%d]", remaining),
        count = total,
        text_color = remaining > 0 and 0xFFFFE0A0 or 0xFF89FF9E
    }
end

invasion_list_bridge = create_item_list_bridge({
    rows_provider = get_invasion_rows,
    item_builder = build_invasion_item,
    selected_index_bind = "invasion_panel.selected_index",
    selected_value_bind = "invasion_panel.selected_value",
    selected_value_getter = function(row)
        return row and row.index or -1
    end
})

monster_list_bridge = create_item_list_bridge({
    rows_provider = get_monster_rows,
    item_builder = build_monster_item,
    selected_index_bind = "invasion_panel.monster_selected_index",
    selected_value_bind = "invasion_panel.monster_selected_value",
    selected_value_getter = function(row)
        return row and row.monster_index or -1
    end
})

local function sync_monster_selection()
    if monster_list_bridge.get_count() == 0 then
        monster_list_bridge.clear_selection()
        return nil
    end
    return monster_list_bridge.sync_selected(nil)
end

local function sync_invasion_selection(preferred_index)
    local row = invasion_list_bridge.sync_selected(preferred_index)
    sync_monster_selection()
    return row
end

local function get_selected_invasion_name()
    local row = get_selected_invasion()
    return row and row.name or "Sin invasiones"
end

local function get_selected_invasion_time()
    local row = get_selected_invasion()
    return row and row.time or "--:--:--"
end

local function get_selected_invasion_status()
    local row = get_selected_invasion()
    if not row then
        return "Estado: Sin datos"
    end
    return row.active and "Estado: Activa" or "Estado: En espera"
end

local function get_selected_invasion_meta()
    local row = get_selected_invasion()
    if not row then
        return "Indice: -- | Monstruos: --"
    end

    return string.format(
        "Indice: %d | Monstruos: %d",
        tonumber(row.index) or -1,
        tonumber(row.monster_count) or 0
    )
end

local function get_selected_invasion_description()
    local row = get_selected_invasion()
    if not row then
        return "Selecciona una invasion en la lista lateral."
    end

    if row.active then
        return "La invasion se encuentra activa. El detalle inferior muestra el progreso por monstruo para este ciclo."
    end

    return "La invasion no esta activa actualmente. El sistema queda listo para extender horario, zonas, recompensas y reglas."
end

local function get_selected_invasion_footer()
    local row = get_selected_invasion()
    if not row then
        return "Sin informacion adicional."
    end
    if row.active then
        return "Monitorea aqui los objetivos pendientes y el tiempo restante."
    end
    return "Espera la siguiente actualizacion del sistema o la activacion de la invasion."
end

local function get_selected_monster_text()
    local row = monster_list_bridge.get_selected()
    if not row then
        return "Selecciona un monstruo en la lista inferior."
    end

    local kills = tonumber(row.monster_kill) or 0
    local total = tonumber(row.monster_count) or 0
    local remaining = tonumber(row.remaining) or math.max(total - kills, 0)

    return string.format(
        "Monster #%d | Kills: %d / %d | Restantes: %d",
        tonumber(row.monster_index) or -1,
        kills,
        total,
        remaining
    )
end

binding.set("invasion_panel.selected_index", -1)
binding.set("invasion_panel.selected_value", -1)
binding.set("invasion_panel.monster_selected_index", -1)
binding.set("invasion_panel.monster_selected_value", -1)
sync_invasion_selection(nil)

local win = ui.window("invasion", {
    title = invasion.get_title(),
    rect = ui.rect(290, 72, 472, 316),
    hotkey = { key = "F7", ctrl = true, alt = false, shift = false },
    closable = true,
    movable = true,
    on_open = function()
        invasion.request_refresh()
        sync_invasion_selection(nil)
    end,
    on_close = function()
        invasion_list_bridge.clear_selection()
        monster_list_bridge.clear_selection()
    end
})

win:panel("invasion_content", {
    rect = ui.rect(0, 24, 472, 292),
    header_visible = false,
    show_background = false,
    show_border = false,
    padding_left = 0,
    padding_top = 0,
    padding_right = 0,
    padding_bottom = 0
})

win:text("summary", {
    parent = "invasion_content",
    rect = ui.rect(12, 8, 324, 18),
    text = invasion.get_summary(),
    font = "bold",
    align = "left",
    bind = "invasion.summary",
    text_color = 0xFFB8D7FF
})

win:text("stats", {
    parent = "invasion_content",
    rect = ui.rect(338, 8, 122, 18),
    text = "",
    align = "right",
    bind_text = function()
        return string.format(
            "Activas: %d / %d",
            tonumber(invasion.get_active_count()) or 0,
            tonumber(invasion.get_total_count()) or 0
        )
    end,
    text_color = 0xFFFFE8A0
})

win:panel("invasion_list_frame", {
    parent = "invasion_content",
    rect = ui.rect(12, 34, 126, 208),
    header_visible = false,
    show_background = true,
    show_border = true,
    background_color = 0x700A0A0A,
    border_color = 0xFF000000,
    padding_left = 0,
    padding_top = 0,
    padding_right = 0,
    padding_bottom = 0
})

win:item_list("invasion_list", {
    parent = "invasion_list_frame",
    rect = ui.rect(2, 2, 122, 204),
    current_bind = "invasion_panel.selected_index",
    bind_items = function()
        return invasion_list_bridge.build_items()
    end,
    row_height = 48,
    model_size = 0,
    text_color = 0xFFF0F0F0,
    count_color = 0xFFE0E0E0,
    hover_color = 0xD0181E28,
    selected_color = 0xD04A2412,
    on_item_selected = function(index)
        sync_invasion_selection(index)
    end
})

win:panel("invasion_detail_panel", {
    parent = "invasion_content",
    rect = ui.rect(150, 34, 310, 140),
    header_visible = false,
    show_background = true,
    show_border = true,
    background_color = 0xC0101014,
    border_color = 0xFF000000,
    padding_left = 0,
    padding_top = 0,
    padding_right = 0,
    padding_bottom = 0
})

win:text("detail_name", {
    parent = "invasion_detail_panel",
    rect = ui.rect(12, 12, 286, 24),
    text = "Sin invasiones",
    font = "big",
    align = "left",
    bind_text = get_selected_invasion_name,
    text_color = 0xFFFFD768
})

win:text("detail_time", {
    parent = "invasion_detail_panel",
    rect = ui.rect(12, 42, 176, 18),
    text = "--:--:--",
    font = "bold",
    align = "left",
    bind_text = function()
        return "Tiempo: " .. get_selected_invasion_time()
    end,
    text_color = 0xFFFFF6B4
})

win:text("detail_status", {
    parent = "invasion_detail_panel",
    rect = ui.rect(188, 42, 110, 18),
    text = "Estado: --",
    font = "bold",
    align = "right",
    bind_text = get_selected_invasion_status,
    text_color = 0xFF9AE8FF
})

win:text("detail_meta", {
    parent = "invasion_detail_panel",
    rect = ui.rect(12, 66, 286, 18),
    text = "Indice: -- | Monstruos: --",
    align = "left",
    bind_text = get_selected_invasion_meta,
    text_color = 0xFFD0D0D0
})

win:label("detail_description_title", {
    parent = "invasion_detail_panel",
    rect = ui.rect(12, 92, 286, 18),
    text = "Informacion de la Invasion",
    font = "bold",
    align = "left",
    text_color = 0xFFFFA644,
    background_color = 0x6A000000
})

win:text("detail_description", {
    parent = "invasion_detail_panel",
    rect = ui.rect(12, 116, 286, 30),
    text = "Selecciona una invasion en la lista lateral.",
    align = "left",
    bind_text = get_selected_invasion_description,
    text_color = 0xFFF0F0F0
})

win:text("detail_footer", {
    parent = "invasion_detail_panel",
    rect = ui.rect(12, 146, 286, 18),
    text = "Sin informacion adicional.",
    align = "left",
    bind_text = get_selected_invasion_footer,
    text_color = 0xFFB0B0B0
})

win:panel("invasion_monster_panel", {
    parent = "invasion_content",
    rect = ui.rect(150, 182, 310, 60),
    header_visible = false,
    show_background = true,
    show_border = true,
    background_color = 0xC0101014,
    border_color = 0xFF000000,
    padding_left = 0,
    padding_top = 0,
    padding_right = 0,
    padding_bottom = 0
})

win:label("monsters_title", {
    parent = "invasion_monster_panel",
    rect = ui.rect(12, 8, 286, 18),
    text = "Objetivos de Monstruos",
    font = "bold",
    align = "left",
    text_color = 0xFFFFA644,
    background_color = 0x6A000000
})

win:item_list("monster_list", {
    parent = "invasion_monster_panel",
    rect = ui.rect(12, 28, 286, 28),
    current_bind = "invasion_panel.monster_selected_index",
    bind_items = function()
        return monster_list_bridge.build_items()
    end,
    row_height = 34,
    model_size = 0,
    text_color = 0xFFF0F0F0,
    count_color = 0xFFE0E0E0,
    hover_color = 0xD0181E28,
    selected_color = 0xD04A2412,
    on_item_selected = function(index)
        monster_list_bridge.sync_selected(index)
    end
})

win:text("monster_hint", {
    parent = "invasion_content",
    rect = ui.rect(150, 246, 310, 18),
    text = "Selecciona un monstruo en la lista inferior.",
    align = "left",
    bind_text = get_selected_monster_text,
    text_color = 0xFF9AE8FF
})

win:button("refresh", {
    parent = "invasion_content",
    rect = ui.rect(150, 264, 100, 22),
    text = "Actualizar",
    on_click = function()
        invasion.request_refresh()
        sync_invasion_selection(nil)
    end
})

win:button("close", {
    parent = "invasion_content",
    rect = ui.rect(262, 264, 100, 22),
    text = "Cerrar",
    on_click = function()
        win:close()
    end
})

win:text("empty_hint", {
    parent = "invasion_content",
    rect = ui.rect(16, 126, 118, 24),
    text = "No hay invasiones cargadas.",
    align = "center",
    bind_text = function()
        if invasion_list_bridge.get_count() > 0 then
            return ""
        end
        return "No hay invasiones cargadas."
    end,
    text_color = 0xFFFF7A7A
})

return win
