local ui = SFUI.ui
local bind = SFUI.bind
local actions = SFUI.actions
local item_catalog = ui.import("data.items")

local WINDOW_ID = "admin_make_panel"
local KEY = "admin_make"
local ITEM_INDEX_SIZE = 512

local colors = {
    panel = ui.color(8, 8, 10, 238),
    panel_soft = ui.color(18, 16, 14, 218),
    panel_dark = ui.color(5, 5, 6, 190),
    line = ui.color(145, 92, 32, 170),
    text = ui.color(236, 230, 214, 255),
    muted = ui.color(166, 156, 132, 255),
    gold = ui.color(255, 212, 82, 255),
    good = ui.color(110, 220, 118, 255),
    warn = ui.color(230, 168, 70, 255),
    bad = ui.color(210, 92, 80, 255),
}

local button_skin = ui.sprite("Lua\\Texture\\simpleui.tga", 756.0, 646.0, 82.0, 84.0)
local button_pressed = ui.sprite("Lua\\Texture\\simpleui.tga", 840.0, 646.0, 82.0, 84.0)

local sections = {
    { id = 0, text = "0 - Sword" },
    { id = 1, text = "1 - Axe" },
    { id = 2, text = "2 - Mace/Scepter" },
    { id = 3, text = "3 - Spear" },
    { id = 4, text = "4 - Bow/Crossbow" },
    { id = 5, text = "5 - Staff" },
    { id = 6, text = "6 - Shield" },
    { id = 7, text = "7 - Helm" },
    { id = 8, text = "8 - Armor" },
    { id = 9, text = "9 - Pants" },
    { id = 10, text = "10 - Gloves" },
    { id = 11, text = "11 - Boots" },
    { id = 12, text = "12 - Wings/Orb" },
    { id = 13, text = "13 - Pets/Rings" },
    { id = 14, text = "14 - Misc/Jewel" },
    { id = 15, text = "15 - Scroll" },
}

local level_items = {}
for value = 0, 15 do
    level_items[#level_items + 1] = { id = value, text = "+" .. value }
end

local option_items = {}
for value = 0, 7 do
    option_items[#option_items + 1] = { id = value, text = "Opt " .. value .. " (+" .. (value * 4) .. ")" }
end

local socket_items = {}
for value = 0, 5 do
    socket_items[#socket_items + 1] = { id = value, text = tostring(value) .. " socket" }
end

local set_items = {
    { id = 0, text = "Sin ancient" },
    { id = 1, text = "Ancient 1" },
    { id = 2, text = "Ancient 2" },
    { id = 3, text = "Ancient 3" },
    { id = 4, text = "Ancient 4" },
    { id = 5, text = "Ancient 5" },
}

local exc_options = {
    { bit = 1, text = "Exc 1" },
    { bit = 2, text = "Exc 2" },
    { bit = 4, text = "Exc 4" },
    { bit = 8, text = "Exc 8" },
    { bit = 16, text = "Exc 16" },
    { bit = 32, text = "Exc 32" },
}

local function k(name)
    return KEY .. "." .. name
end

local function as_number(name, fallback)
    local value = tonumber(bind.get(k(name)))
    if value == nil then
        return fallback or 0
    end
    return value
end

local function as_bool(name)
    local value = bind.get(k(name))
    return value == true or value == 1 or value == "1" or value == "true"
end

local function set_default(name, value)
    if bind.get(k(name)) == nil then
        bind.set(k(name), value)
    end
end

local function clamp(value, min_value, max_value)
    value = tonumber(value) or min_value
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function make_item_index(section, item_type)
    section = clamp(section, 0, 15)
    item_type = clamp(item_type, 0, 511)
    if item_catalog and item_catalog.make_index then
        return item_catalog.make_index(section, item_type)
    end
    return (section * ITEM_INDEX_SIZE) + item_type
end

local function get_item_info(index)
    if item_catalog and item_catalog.get_info then
        local ok, info = pcall(item_catalog.get_info, index)
        if ok and type(info) == "table" then
            return info
        end
    end

    local section = math.floor(index / ITEM_INDEX_SIZE)
    local item_type = index % ITEM_INDEX_SIZE
    return {
        item_index = index,
        index = index,
        section = section,
        type = item_type,
        valid = false,
        name = "",
        display_name = string.format("%d:%d  Item sin catalogo", section, item_type),
        width = 0,
        height = 0,
        require_level = 0,
        kind1 = 0,
        kind2 = 0,
        kind3 = 0,
    }
end

local function get_section_items(section)
    if item_catalog and item_catalog.get_section_items then
        local ok, rows = pcall(item_catalog.get_section_items, section)
        if ok and type(rows) == "table" and #rows > 0 then
            return rows
        end
    end

    return {
        { id = as_number("type", 0), text = "Index manual " .. tostring(as_number("type", 0)) },
    }
end

local function excellent_mask()
    local mask = 0
    for _, option in ipairs(exc_options) do
        if as_bool("exc_" .. option.bit) then
            mask = mask + option.bit
        end
    end
    return mask
end

local function option_summary(level, skill, luck, option, exc, set, socket)
    local parts = { "+" .. tostring(level) }
    if skill == 1 then
        parts[#parts + 1] = "Skill"
    end
    if luck == 1 then
        parts[#parts + 1] = "Luck"
    end
    if option > 0 then
        parts[#parts + 1] = "Opt +" .. tostring(option * 4)
    end
    if exc > 0 then
        parts[#parts + 1] = "Exc mask " .. tostring(exc)
    end
    if set > 0 then
        parts[#parts + 1] = "Ancient " .. tostring(set)
    end
    if socket > 0 then
        parts[#parts + 1] = tostring(socket) .. " socket"
    end
    return table.concat(parts, " | ")
end

local function sync_section_items(select_first_when_missing)
    local section = clamp(as_number("section", 0), 0, 15)
    local current_type = clamp(as_number("type", 0), 0, 511)
    local rows = get_section_items(section)
    bind.set(k("section_items"), rows)

    if not select_first_when_missing then
        return
    end

    local found = false
    for _, row in ipairs(rows) do
        local row_type = tonumber(row.id or row.value or row.index)
        if row_type == current_type then
            found = true
            break
        end
    end

    if not found and rows[1] ~= nil then
        local next_type = tonumber(rows[1].id or rows[1].value or rows[1].index) or 0
        bind.set(k("type"), next_type)
    end
end

local function build_make_command()
    local section = clamp(as_number("section", 0), 0, 15)
    local item_type = clamp(as_number("type", 0), 0, 511)
    local level = clamp(as_number("level", 0), 0, 15)
    local skill = as_bool("skill") and 1 or 0
    local luck = as_bool("luck") and 1 or 0
    local option = clamp(as_number("option", 0), 0, 7)
    local exc = excellent_mask()
    local set = clamp(as_number("set", 0), 0, 255)
    local socket = clamp(as_number("socket", 0), 0, 5)

    return string.format("/make %d %d %d %d %d %d %d %d %d", section, item_type, level, skill, luck, option, exc, set, socket)
end

local function update_preview()
    local section = clamp(as_number("section", 0), 0, 15)
    local item_type = clamp(as_number("type", 0), 0, 511)
    local level = clamp(as_number("level", 0), 0, 15)
    local skill = as_bool("skill") and 1 or 0
    local luck = as_bool("luck") and 1 or 0
    local option = clamp(as_number("option", 0), 0, 7)
    local exc = excellent_mask()
    local set = clamp(as_number("set", 0), 0, 255)
    local socket = clamp(as_number("socket", 0), 0, 5)
    local item_index = make_item_index(section, item_type)
    local info = get_item_info(item_index)
    local name = info.name ~= nil and info.name ~= "" and info.name or ("Item " .. tostring(item_index))
    local command = build_make_command()
    local width = tonumber(info.width) or 0
    local height = tonumber(info.height) or 0
    local require_level = tonumber(info.require_level) or 0
    local kind1 = tonumber(info.kind1) or 0
    local kind2 = tonumber(info.kind2) or 0
    local kind3 = tonumber(info.kind3) or 0

    bind.set(k("command"), command)
    bind.set(k("item_name"), name)
    bind.set(k("item_code"), string.format("ID %d  %d:%d", item_index, section, item_type))
    bind.set(k("option_summary"), option_summary(level, skill, luck, option, exc, set, socket))

    if info.valid == true then
        bind.set(k("item_meta"), string.format("%dx%d | Req %d | Kind %d/%d/%d", width, height, require_level, kind1, kind2, kind3))
        bind.set(k("summary"), "Listo para crear 1 item.")
    else
        bind.set(k("item_meta"), "No aparece con nombre en el catalogo del cliente.")
        bind.set(k("summary"), "Revisa section/index antes de crear.")
    end

    bind.set(k("preview_items"), {
        {
            item_index = item_index,
            level = level * 8,
            option1 = skill,
            ext_option = exc,
            pickup = false,
            count = 0,
            name = " ",
            header = " ",
            footer = "",
            badge = "",
            text_color = colors.text,
        },
    })

    return command
end

set_default("section", 0)
set_default("type", 0)
set_default("level", 15)
set_default("skill", true)
set_default("luck", true)
set_default("option", 7)
set_default("set", 0)
set_default("socket", 0)
set_default("exc_1", false)
set_default("exc_2", false)
set_default("exc_4", false)
set_default("exc_8", false)
set_default("exc_16", false)
set_default("exc_32", false)

actions.register("admin_make.update", function()
    update_preview()
    return true
end)

actions.register("admin_make.update_section", function()
    sync_section_items(true)
    update_preview()
    return true
end)

actions.register("admin_make.send", function()
    local command = update_preview()
    actions.run("client.send_chat_command", command)
    bind.set(k("summary"), "Enviado.")
    return true
end)

actions.register("admin_make.max_excellent", function()
    for _, option in ipairs(exc_options) do
        bind.set(k("exc_" .. option.bit), true)
    end
    update_preview()
    return true
end)

actions.register("admin_make.clear_excellent", function()
    for _, option in ipairs(exc_options) do
        bind.set(k("exc_" .. option.bit), false)
    end
    update_preview()
    return true
end)

actions.register("admin_make.close", function()
    ui.close(WINDOW_ID)
    return true
end)

sync_section_items(true)
update_preview()

local win = ui.window(WINDOW_ID, {
    title = "Admin Make Item",
    rect = ui.rect(60, 70, 280, 280),
    hotkey = { key = "F11", ctrl = true, alt = false, shift = false },
    fade_time = 0.15,
    closable = true,
    movable = true,
    close_button = ui.rect(262, 3, 14, 14),
    header_height = 20,
    title_position = { 14, 2 },
    title_align = "left",
    style = {
        background_color = colors.panel,
        border_color = colors.line,
        title_color = ui.color(72, 18, 12, 235),
        title_text_color = colors.gold,
    },
})


local function label(id, x, y, text, w)
    win:text(id, {
        rect = ui.rect(x, y, w or 74, 12),
        text = text,
        text_color = colors.muted,
        align = "left",
    })
end

local function input(id, x, y, bind_name, width, mode, max_length)
    win:input_text(id, {
        rect = ui.rect(x, y, width or 56, 12),
        bind = k(bind_name),
        input_mode = mode or "integer",
        max_length = max_length or 4,
        text_color = colors.text,
        background_color = ui.color(0, 0, 0, 185),
        border_color = colors.line,
        on_change = function()
            update_preview()
        end,
    })
end

local function combo(id, x, y, bind_name, width, items, action, items_bind)
    win:combobox(id, {
        rect = ui.rect(x, y, width or 94, 12),
        selected_bind = k(bind_name),
        selected = tonumber(bind.get(k(bind_name))) or 0,
        items = items or {},
        items_bind = items_bind,
        action = action or "admin_make.update",
    })
end

local function checkbox(id, x, y, bind_name, text, width)
    win:checkbox(id, {
        rect = ui.rect(x, y, width or 70, 12),
        box_size = 10,
        text_gap = 4,
        text = text,
        checked_bind = k(bind_name),
        checked = as_bool(bind_name),
        action = "admin_make.update",
        style = {
            text_color = colors.text,
            checked_text_color = colors.good,
            unchecked_text_color = colors.muted,
        },
    })
end


label("label_section", 20, 30, "Seccion", 44)
combo("combo_section", 58, 30, "section", 92, sections, "admin_make.update_section")

label("label_item", 20, 50, "Item", 44)
combo("combo_item", 58, 50, "type", 92, {}, "admin_make.update", k("section_items"))



label("label_level", 20, 70, "Level", 44)
combo("combo_level", 58, 70, "level", 92, level_items)

label("label_option", 20, 90, "Option", 44)
combo("combo_option", 58, 90, "option", 92, option_items)

label("label_socket", 20, 110, "Socket", 44)
combo("combo_socket", 58, 110, "socket", 92, socket_items)

label("label_set", 20, 130, "Ancient", 50)
combo("combo_set", 58, 130, "set", 92, set_items)

checkbox("check_skill", 58, 150, "skill", "Skill", 58)
checkbox("check_luck", 128, 150, "luck", "Luck", 58)

label("excellent_title", 20, 170, "Excellent", 50)

checkbox("exc_1", 58, 170, "exc_1", "Exc 1", 58)
checkbox("exc_2", 128, 170, "exc_2", "Exc 2", 58)
checkbox("exc_4", 58, 190, "exc_4", "Exc 4", 58)
checkbox("exc_8", 128, 190, "exc_8", "Exc 8", 58)
checkbox("exc_16", 58, 210, "exc_16", "Exc 16", 62)
checkbox("exc_32", 128, 210, "exc_32", "Exc 32", 62)

win:text("preview_title", {
    rect = ui.rect(180, 30, 70, 12),
    text = "Preview",
    text_color = colors.gold,
    align = "center",
    font = "bold",
})

win:item_list("item_preview", {
    rect = ui.rect(175, 40, 70, 60),
    row_height = 60,
    model_size = 70,
    bind = k("preview_items"),
    text_color = colors.text,
    count_color = colors.gold,
    selected_color = ui.color(0, 0, 0, 0),
    hover_color = ui.color(0, 0, 0, 0),
})

win:text("option_summary", {
    rect = ui.rect(180, 110, 70, 20),
    bind = k("item_name"),
    text_color = colors.text,
    align = "center",
    font = "bold",
})


win:text("command_preview", {
    rect = ui.rect(180, 135, 70, 16),
    bind = k("command"),
    text_color = colors.good,
    align = "left",
})

win:button("send_make", {
    rect = ui.rect(20, 240, 46, 20),
    text = "Crear",
    text_color = colors.text,
    action = "admin_make.send",
})

win:button("close_make", {
    rect = ui.rect(120, 240, 46, 20),
    text = "Cerrar",
    text_color = colors.text,
    action = "admin_make.close",
})

return win
