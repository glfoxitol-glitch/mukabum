local ui = SFUI.v2
local data = SFUI.data
local bind = SFUI.bind
local actions = SFUI.actions

local WINDOW_ID = "daily_rewards"
local SYSTEM_ID = "daily_rewards"
local KEY = "systems." .. SYSTEM_ID

local colors = {
    panel = ui.color(8, 8, 10, 235),
    panel_soft = ui.color(18, 16, 14, 210),
    panel_line = ui.color(145, 92, 32, 180),
    selected = ui.color(225, 174, 48, 230),
    text = ui.color(235, 228, 208, 255),
    muted = ui.color(165, 154, 128, 255),
    gold = ui.color(255, 212, 82, 255),
    good = ui.color(115, 220, 112, 255),
    warn = ui.color(230, 168, 70, 255),
    bad = ui.color(185, 88, 70, 255),
}

local chest_closed = ui.sprite("Interface\\InGameShop\\ingame_gift_icon.tga")
local chest_open = ui.sprite("Interface\\InGameShop\\ingame_Bt_Gift.tga")
local button_skin = ui.sprite("Lua\\Texture\\simpleui.tga", 756.0, 646.0, 82.0, 84.0)
local button_pressed = ui.sprite("Lua\\Texture\\simpleui.tga", 840.0, 646.0, 82.0, 84.0)

local function key(name)
    return KEY .. "." .. name
end

local function day_key(day, name)
    return string.format("%s.day_%02d_%s", KEY, day, name)
end

local function reward(name, count, kind)
    return {
        name = name,
        count = count or 1,
        kind = kind or "item",
        display = name .. " x" .. tostring(count or 1),
    }
end

local function build_demo_rows()
    local names = {
        "Jewel of Bless", "Jewel of Soul", "Goblin Point", "Ruud", "Box of Luck",
        "Jewel of Life", "Guardian Potion", "Bless of Light", "Mastery Box", "Chaos Card",
    }

    local rows = {}
    for day = 1, 30 do
        local index = ((day - 1) % #names) + 1
        rows[day] = {
            id = "day_" .. day,
            day = day,
            title = "Premio diario " .. day,
            description = "Recompensa por conexion diaria. El servidor SQL decide si el cofre esta abierto o cerrado.",
            available = day <= 6,
            opened = day <= 3,
            claimed = day <= 3,
            rewards = {
                reward(names[index], day % 5 + 1, "item"),
                reward("Zen", 100000 * day, "currency"),
            },
        }
    end
    return rows
end

local function normalize_row(row, day)
    row = row or {}
    row.day = row.day or day
    row.title = row.title or ("Premio diario " .. tostring(row.day))
    row.description = row.description or "Sin descripcion."
    row.rewards = row.rewards or {}
    row.claimed = row.claimed == true or row.opened == true or row.open == true
    row.opened = row.claimed
    row.available = row.available ~= false
    row.claimable = row.available and not row.claimed

    if row.claimed then
        row.status = "claimed"
        row.status_text = "Reclamado"
    elseif row.claimable then
        row.status = "claimable"
        row.status_text = "Disponible"
    else
        row.status = "locked"
        row.status_text = "Bloqueado"
    end

    for _, item in ipairs(row.rewards) do
        item.display = item.display or ((item.name or item.title or "Premio") .. " x" .. tostring(item.count or 1))
        item.kind = item.kind or item.type or "item"
    end

    return row
end

local function reward_summary(row)
    local parts = {}
    for _, item in ipairs(row.rewards or {}) do
        parts[#parts + 1] = item.display or item.name or item.title or "Premio"
    end
    return #parts > 0 and table.concat(parts, ", ") or "Sin premio definido"
end

local function reward_table(row)
    return {
        columns = {
            { key = "display", title = "Premio", width = 160, align = "left" },
            { key = "kind", title = "Tipo", width = 58, align = "center" },
        },
        rows = row and row.rewards or {},
        selected_index = 1,
    }
end

local daily = data.define(SYSTEM_ID, {
    title = "Recompensa diaria",
    summary = "30 dias de premios por conexion.",
    selected_index = 1,
    rows = build_demo_rows(),
})

local function get_row(day)
    return daily.rows[day]
end

local function publish_selected(row)
    row = row or get_row(daily.selected_index or 1) or {}

    bind.set(key("selected_day"), row.day or 0)
    bind.set(key("selected_title"), row.title or "")
    bind.set(key("selected_status"), row.status_text or "")
    bind.set(key("selected_description"), row.description or "")
    bind.set(key("selected_reward"), reward_summary(row))
    bind.set(key("selected_claimable"), row.claimable and 1 or 0)
    bind.set(key("selected_claim_text"), row.claimed and "Reclamado" or "Reclamar")
    bind.set(key("selected_rewards_table"), reward_table(row))
end

local function publish_days()
    for day = 1, 30 do
        local row = normalize_row(get_row(day), day)
        daily.rows[day] = row

        local selected = (daily.selected_index or 1) == day
        bind.set(day_key(day, "open_visible"), row.claimed and 1 or 0)
        bind.set(day_key(day, "closed_visible"), row.claimed and 0 or 1)
        bind.set(day_key(day, "selected_visible"), selected and 1 or 0)
        bind.set(day_key(day, "enabled"), row.available and 1 or 0)
        bind.set(day_key(day, "status"), row.status_text)
    end

    daily:publish()
    publish_selected(get_row(daily.selected_index or 1))
end

local function select_day(day)
    day = tonumber(day) or 1
    if day < 1 then
        day = 1
    elseif day > 30 then
        day = 30
    end

    daily.selected_index = day
    daily:select(day)
    publish_days()
end

actions.register("daily_rewards.claim_selected", function()
    local row = get_row(daily.selected_index or 1)
    if row == nil then
        bind.set(key("selected_description"), "No hay premio seleccionado.")
        return false
    end

    if row.claimed then
        bind.set(key("selected_description"), "Este premio ya fue reclamado.")
        return false
    end

    if not row.available then
        bind.set(key("selected_description"), "Este dia aun no esta disponible.")
        return false
    end

    row.claimed = true
    row.opened = true
    row.claimable = false
    row.status = "claimed"
    row.status_text = "Reclamado"
    publish_days()
    bind.set(key("selected_description"), "Premio reclamado localmente. En produccion aqui se confirma contra SQL/servidor.")
    return true
end)

actions.register("daily_rewards.refresh", function()
    publish_days()
    return true
end)

actions.register("daily_rewards.close", function()
    ui.close(WINDOW_ID)
    return true
end)

publish_days()
select_day(1)

local win = ui.window(WINDOW_ID, {
    title = "Recompensa diaria",
    rect = ui.rect(170, 70, 560, 390),
    hotkey = "F10",
    fade_time = 0.15,
    closable = true,
    movable = true,
    close_button = ui.rect(540, 6, 14, 14),
    header_height = 24,
    title_position = { 14, 5 },
    title_align = "left",
    style = {
        background_color = colors.panel,
        border_color = colors.panel_line,
        title_color = ui.color(72, 18, 12, 235),
        title_text_color = colors.gold,
    },
})

win:panel("rewards_grid_panel", {
    rect = ui.rect(12, 34, 326, 332),
    header_visible = false,
    background_color = colors.panel_soft,
    border_color = colors.panel_line,
})

win:text("grid_title", {
    rect = ui.rect(24, 44, 292, 18),
    text = "Calendario de 30 dias",
    text_color = colors.gold,
    align = "center",
    font = "bold",
})

local function add_day(day)
    local columns = 6
    local cell_w = 50
    local cell_h = 52
    local start_x = 26
    local start_y = 70
    local col = (day - 1) % columns
    local row = math.floor((day - 1) / columns)
    local x = start_x + col * cell_w
    local y = start_y + row * cell_h

    win:panel("daily_day_" .. day .. "_selected", {
        rect = ui.rect(x - 2, y - 2, 44, 48),
        visible_bind = day_key(day, "selected_visible"),
        header_visible = false,
        show_background = false,
        border_color = colors.selected,
    })

    win:button("daily_day_" .. day .. "_closed", {
        rect = ui.rect(x, y, 40, 38),
        visible_bind = day_key(day, "closed_visible"),
        texture = chest_closed,
        over_texture = chest_closed,
        click_texture = chest_closed,
        text = tostring(day),
        text_offset_y = 12,
        text_color = colors.text,
        disabled_text_color = colors.muted,
        show_background = false,
        show_border = false,
        on_click = function()
            select_day(day)
        end,
    })

    win:button("daily_day_" .. day .. "_open", {
        rect = ui.rect(x, y, 40, 38),
        visible_bind = day_key(day, "open_visible"),
        texture = chest_open,
        over_texture = chest_open,
        click_texture = chest_open,
        text = tostring(day),
        text_offset_y = 12,
        text_color = colors.gold,
        disabled_text_color = colors.muted,
        show_background = false,
        show_border = false,
        on_click = function()
            select_day(day)
        end,
    })

    win:text("daily_day_" .. day .. "_status", {
        rect = ui.rect(x - 4, y + 38, 48, 12),
        bind = day_key(day, "status"),
        align = "center",
        text_color = colors.muted,
    })
end

for day = 1, 30 do
    add_day(day)
end

win:panel("reward_detail_panel", {
    rect = ui.rect(350, 34, 198, 332),
    header_visible = false,
    background_color = colors.panel_soft,
    border_color = colors.panel_line,
})

win:text("selected_day_title", {
    rect = ui.rect(362, 48, 174, 22),
    bind_text = function()
        local day = tonumber(bind.get(key("selected_day"))) or 0
        return "Dia " .. day
    end,
    align = "center",
    text_color = colors.gold,
    font = "bold",
})

win:text("selected_title", {
    rect = ui.rect(362, 78, 174, 18),
    bind = key("selected_title"),
    align = "center",
    text_color = colors.text,
})

win:text("selected_status", {
    rect = ui.rect(362, 102, 174, 18),
    bind = key("selected_status"),
    align = "center",
    text_color = colors.warn,
})

win:text("selected_description", {
    rect = ui.rect(362, 128, 174, 54),
    bind = key("selected_description"),
    align = "left",
    text_color = colors.muted,
})

win:text("reward_caption", {
    rect = ui.rect(362, 190, 174, 16),
    text = "Premios",
    align = "left",
    text_color = colors.gold,
    font = "bold",
})

win:table("selected_rewards_table", {
    rect = ui.rect(362, 210, 174, 70),
    bind = key("selected_rewards_table"),
    show_header = true,
    header_height = 18,
    row_height = 18,
    style = {
        background_color = ui.color(0, 0, 0, 165),
        header_color = ui.color(45, 28, 16, 220),
        text_color = colors.text,
        header_text_color = colors.gold,
        selected_row_color = ui.color(74, 48, 20, 130),
    },
})

win:button("claim_selected", {
    rect = ui.rect(370, 292, 80, 24),
    text = "Reclamar",
    enabled_bind = key("selected_claimable"),
    texture = button_skin,
    over_texture = button_skin,
    click_texture = button_pressed,
    text_color = colors.text,
    disabled_text_color = colors.muted,
    action = "daily_rewards.claim_selected",
})

win:button("refresh_rewards", {
    rect = ui.rect(458, 292, 70, 24),
    text = "Refresh",
    texture = button_skin,
    over_texture = button_skin,
    click_texture = button_pressed,
    text_color = colors.text,
    action = "daily_rewards.refresh",
})

win:text("server_note", {
    rect = ui.rect(362, 322, 174, 28),
    text = "SQL debe enviar opened/claimed y rewards por dia.",
    align = "center",
    text_color = colors.muted,
})

return win
