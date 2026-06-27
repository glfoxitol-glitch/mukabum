local ui = SFUI.ui
local binding = ui.import("binding")
local actions = SFUI.actions
local seasonpass = ui.import("systems.seasonpass")

local VIEW = "seasonpass.panel"

local colors = {
    back = ui.color(8, 8, 8, 232),
    title = ui.color(55, 16, 12, 240),
    text = ui.color(230, 220, 200, 255),
    muted = ui.color(165, 165, 165, 255),
    gold = ui.color(255, 220, 90, 255),
    good = ui.color(120, 220, 90, 255),
    warning = ui.color(255, 170, 70, 255),
    blue = ui.color(190, 210, 230, 255),
}

local function rows()
    if seasonpass and seasonpass.get_rows then
        local value = seasonpass.get_rows()
        if type(value) == "table" then
            return value
        end
    end

    return {}
end

local function to_number(value, fallback)
    local parsed = tonumber(value)
    if parsed == nil then
        return fallback or 0
    end
    return parsed
end

local function is_true(value)
    return value == true or value == 1 or value == "1"
end

local function status_text(row)
    if not row then
        return "Sin datos"
    end

    if not is_true(row.available) and not is_true(row.completed) and not is_true(row.claimed) then
        return "Bloqueada"
    end

    return row.state_text or "Esperando"
end

local function progress_text(row)
    if not row then
        return ""
    end

    if row.progress_text and row.progress_text ~= "" then
        return row.progress_text
    end

    local current = to_number(row.progress, 0)
    local required = to_number(row.required, 0)
    if required > 0 then
        return current .. "/" .. required
    end

    return tostring(current)
end

local function progress_ratio(row)
    if not row then
        return 0
    end

    local ratio = tonumber(row.progress_ratio)
    if ratio ~= nil then
        return ratio
    end

    local current = to_number(row.progress, 0)
    local required = to_number(row.required, 0)
    if required <= 0 then
        return 0
    end

    return math.max(0, math.min(1, current / required))
end

local function selected_index()
    local index = to_number(binding.get(VIEW .. ".selected_index"), 1)
    if index < 1 then
        index = 1
    end
    return index
end

local function selected_row()
    local list = rows()
    local index = selected_index()
    if list[index] then
        return list[index]
    end

    if list[1] then
        binding.set(VIEW .. ".selected_index", 1)
        return list[1]
    end

    return nil
end

local function reward_rows(row)
    local reward = row and row.reward_text or ""
    local state = row and status_text(row) or ""

    if reward == nil or reward == "" then
        reward = "Sin recompensa visible"
    end

    return {
        columns = {
            { key = "display", title = "Contenido de mision", width = 172, align = "left" },
            { key = "type", title = "Tipo", width = 54, align = "center" },
            { key = "status", title = "Estado", width = 76, align = "center" },
        },
        rows = {
            { display = reward, type = "server", status = state },
        },
    }
end

local function info_rows(row)
    if not row then
        return {
            columns = {
                { key = "label", title = "Campo", width = 120, align = "left" },
                { key = "value", title = "Informacion", width = 330, align = "left" },
            },
            rows = {
                { label = "Estado", value = "Esperando paquete SeasonPass desde el GameServer." },
                { label = "Ruta GS", value = "Data\\Lua\\SeasonPass.lua" },
                { label = "UI", value = "Esta ventana ya no usa datos de ejemplo." },
            },
        }
    end

    return {
        columns = {
            { key = "label", title = "Campo", width = 120, align = "left" },
            { key = "value", title = "Informacion", width = 330, align = "left" },
        },
        rows = {
            { label = "ID", value = row.id or "" },
            { label = "Mision", value = row.title or "" },
            { label = "Nivel requerido", value = tostring(row.mission_level or 1) },
            { label = "Estado", value = status_text(row) },
            { label = "Disponible", value = is_true(row.available) and "Si" or "No" },
            { label = "Periodo", value = row.period or "daily" },
            { label = "Periodo activo", value = row.period_key or "" },
            { label = "Premium", value = is_true(row.premium) and "Si" or "No" },
            { label = "Objetivo", value = row.objective_type or "" },
            { label = "Progreso", value = progress_text(row) },
            { label = "EXP de pase", value = tostring(row.exp or 0) },
            { label = "Premio", value = row.reward_text or "" },
            { label = "Descripcion", value = row.description or "" },
            { label = "Validacion", value = "El GameServer valida progreso, EXP y premios." },
        },
    }
end

local function set_view(name)
    local detail = name == "detail"
    binding.set(VIEW .. ".show_main_panel", detail and 0 or 1)
    binding.set(VIEW .. ".show_detail_panel", detail and 1 or 0)
end

local function publish_selected(row)
    row = row or selected_row()

    binding.set(VIEW .. ".selected_title", row and row.title or "SeasonPass sin datos")
    binding.set(VIEW .. ".selected_status", status_text(row))
    binding.set(VIEW .. ".selected_progress_ratio", progress_ratio(row))
    binding.set(VIEW .. ".selected_progress", progress_text(row))
    binding.set(VIEW .. ".selected_exp", row and ("EXP " .. tostring(row.exp or 0)) or "EXP 0")
    binding.set(VIEW .. ".selected_hint", row and (row.description or "") or "Si el GS ya cargo el Lua, revisa que llegue el paquete SeasonPass al cliente.")
    binding.set(VIEW .. ".selected_info_table", info_rows(row))
    binding.set(VIEW .. ".selected_rewards_table", reward_rows(row))
end

local function refresh()
    if seasonpass and seasonpass.request_refresh then
        seasonpass.request_refresh()
    end

    binding.set(VIEW .. ".page_index", 0)
    binding.set(VIEW .. ".page_count", 1)

    if binding.get(VIEW .. ".selected_index") == nil then
        binding.set(VIEW .. ".selected_index", 1)
    end

    binding.set(VIEW .. ".detail_click_index", 0)

    publish_selected()
end

actions.register("seasonpass_panel.select", function(payload)
    local index = tonumber(payload)
    if index ~= nil then
        local selectedBefore = selected_index()
        local clickedIndex = index + 1
        local armedIndex = to_number(binding.get(VIEW .. ".detail_click_index"), 0)
        local openDetail = clickedIndex == selectedBefore and clickedIndex == armedIndex

        binding.set(VIEW .. ".selected_index", clickedIndex)
        binding.set(VIEW .. ".detail_click_index", clickedIndex)

        publish_selected()

        if openDetail then
            set_view("detail")
        else
            set_view("main")
        end

        return
    end

    publish_selected()
end)

actions.register("seasonpass_panel.open_selected_info", function()
    publish_selected()
    set_view("detail")
end)

actions.register("seasonpass_panel.back_to_list", function()
    publish_selected()
    set_view("main")
end)

actions.register("seasonpass_panel.refresh", function()
    refresh()
    set_view("main")
end)

local function claim_selected_reward()
    local row = selected_row()
    publish_selected(row)

    if not row or not row.id then
        binding.set(VIEW .. ".selected_hint", "Selecciona una mision antes de reclamar.")
        return
    end

    if not is_true(row.completed) then
        binding.set(VIEW .. ".selected_hint", "Completa la mision antes de reclamar el premio.")
        return
    end

    if is_true(row.claimed) then
        binding.set(VIEW .. ".selected_hint", "El premio de esta mision ya fue reclamado.")
        return
    end

    if seasonpass and seasonpass.claim and seasonpass.claim(row.id) then
        binding.set(VIEW .. ".selected_hint", "Solicitud de premio enviada al GameServer.")
    else
        binding.set(VIEW .. ".selected_hint", "No se pudo enviar la solicitud de premio.")
    end
end

actions.register("seasonpass_panel.accept_selected", function()
    local row = selected_row()
    if row and is_true(row.completed) and not is_true(row.claimed) then
        claim_selected_reward()
        return
    end

    publish_selected(row)
    binding.set(VIEW .. ".selected_hint", "La mision se sigue automaticamente desde el GameServer.")
end)

actions.register("seasonpass_panel.claim_selected", function()
    claim_selected_reward()
end)

local win = ui.window("daily_missions_example", {
    title = "SeasonPass",
    rect = ui.rect(52, 30, 640, 460),
    hotkey = "F8",
    start_open = false,
    show_border = true,
    show_header = true,
    background_color = colors.back,
    title_color = colors.title,
    on_open = function()
        refresh()
    end,
})

win:circle_progress("pass_ring", {
    rect = ui.rect(18, 34, 64, 64),
    bind = "seasonpass.pass_ratio",
    ring_thickness = 8,
    background_color = ui.color(52, 48, 35, 230),
    fill_color = ui.color(220, 166, 42, 255),
})

win:text("pass_level", {
    rect = ui.rect(18, 50, 64, 22),
    bind = "seasonpass.level",
    align = "center",
    font = "big",
    color = colors.gold,
})

win:text("pass_exp_text", {
    rect = ui.rect(18, 72, 64, 14),
    bind = "seasonpass.pass_exp_text",
    align = "center",
    color = ui.color(230, 210, 150, 255),
})

win:text("summary", {
    rect = ui.rect(96, 36, 250, 18),
    bind = "seasonpass.summary",
    color = ui.color(255, 220, 170, 255),
})

win:text("completed_count", {
    rect = ui.rect(374, 34, 120, 18),
    text = "Completadas",
    color = colors.text,
})

win:text("completed_value", {
    rect = ui.rect(500, 34, 42, 18),
    bind = "seasonpass.completed_count",
    align = "right",
    color = colors.gold,
})

win:text("progress_count", {
    rect = ui.rect(374, 54, 120, 18),
    text = "En progreso",
    color = colors.text,
})

win:text("progress_value", {
    rect = ui.rect(500, 54, 42, 18),
    bind = "seasonpass.in_progress_count",
    align = "right",
    color = colors.gold,
})

win:text("daily_count", {
    rect = ui.rect(374, 74, 120, 18),
    text = "Logros diarios",
    color = colors.text,
})

win:text("daily_value", {
    rect = ui.rect(500, 74, 42, 18),
    bind = "seasonpass.achievement_count",
    align = "right",
    color = colors.gold,
})

win:text("acquired_exp_label", {
    rect = ui.rect(552, 34, 70, 18),
    text = "EXP total",
    color = colors.text,
})

win:text("acquired_exp", {
    rect = ui.rect(552, 54, 70, 18),
    bind = "seasonpass.acquired_exp",
    align = "right",
    color = colors.gold,
})

win:panel("main_panel", {
    rect = ui.rect(0, 0, 640, 460),
    visible_bind = VIEW .. ".show_main_panel",
    show_background = false,
    show_border = false,
    header_visible = false,
})

win:table("missions", {
    rect = ui.rect(76, 126, 488, 176),
    bind = "seasonpass.table",
    row_height = 24,
    action = "seasonpass_panel.select",
    parent = "main_panel",
    style = {
        background_color = ui.color(5, 5, 5, 205),
        header_color = ui.color(40, 26, 20, 235),
        selected_row_color = ui.color(70, 112, 34, 150),
        hover_row_color = ui.color(70, 70, 70, 130),
        row_text_color = ui.color(235, 235, 230, 255),
    },
})

win:selector("page_selector", {
    rect = ui.rect(282, 310, 76, 18),
    current_bind = VIEW .. ".page_index",
    max_bind = VIEW .. ".page_count",
    action = "seasonpass_panel.refresh",
    parent = "main_panel",
    wrap = true,
})

win:text("selected_title", {
    rect = ui.rect(76, 340, 330, 18),
    bind = VIEW .. ".selected_title",
    parent = "main_panel",
    color = ui.color(255, 230, 160, 255),
})

win:text("selected_status", {
    rect = ui.rect(420, 340, 144, 18),
    bind = VIEW .. ".selected_status",
    align = "right",
    parent = "main_panel",
    color = ui.color(255, 205, 120, 255),
})

win:progress_bar("selected_progress_bar", {
    rect = ui.rect(76, 364, 250, 14),
    bind = VIEW .. ".selected_progress_ratio",
    background_color = ui.color(20, 22, 24, 210),
    parent = "main_panel",
    fill_color = ui.color(236, 148, 48, 255),
})

win:text("selected_progress_text", {
    rect = ui.rect(338, 361, 86, 18),
    bind = VIEW .. ".selected_progress",
    align = "right",
    parent = "main_panel",
    color = ui.color(230, 230, 230, 255),
})

win:text("selected_exp", {
    rect = ui.rect(438, 361, 126, 18),
    bind = VIEW .. ".selected_exp",
    align = "right",
    parent = "main_panel",
    color = ui.color(255, 220, 120, 255),
})

win:text("selected_hint", {
    rect = ui.rect(76, 384, 488, 18),
    bind = VIEW .. ".selected_hint",
    parent = "main_panel",
    color = colors.blue,
})

win:button("accept_mission", {
    rect = ui.rect(76, 414, 104, 24),
    text = "Recibir mision",
    action = "seasonpass_panel.accept_selected",
    parent = "main_panel",
})

win:button("claim_reward", {
    rect = ui.rect(190, 414, 104, 24),
    text = "Recibir premio",
    action = "seasonpass_panel.claim_selected",
    parent = "main_panel",
})

win:button("open_info", {
    rect = ui.rect(304, 414, 88, 24),
    text = "Ver info",
    action = "seasonpass_panel.open_selected_info",
    parent = "main_panel",
})

win:button("refresh", {
    rect = ui.rect(404, 414, 104, 24),
    text = "Actualizar",
    action = "seasonpass_panel.refresh",
    parent = "main_panel",
})

win:panel("detail_panel", {
    rect = ui.rect(0, 0, 640, 460),
    visible_bind = VIEW .. ".show_detail_panel",
    show_background = false,
    show_border = false,
    header_visible = false,
})

win:text("detail_title", {
    rect = ui.rect(76, 126, 360, 18),
    bind = VIEW .. ".selected_title",
    parent = "detail_panel",
    color = ui.color(255, 230, 160, 255),
})

win:text("detail_status", {
    rect = ui.rect(438, 126, 126, 18),
    bind = VIEW .. ".selected_status",
    align = "right",
    parent = "detail_panel",
    color = ui.color(255, 205, 120, 255),
})

win:table("selected_info", {
    rect = ui.rect(76, 152, 488, 176),
    bind = VIEW .. ".selected_info_table",
    row_height = 22,
    parent = "detail_panel",
    style = {
        background_color = ui.color(5, 5, 5, 205),
        header_color = ui.color(40, 26, 20, 235),
        selected_row_color = ui.color(60, 42, 22, 150),
        hover_row_color = ui.color(50, 50, 50, 120),
    },
})

win:table("selected_rewards", {
    rect = ui.rect(76, 338, 306, 58),
    bind = VIEW .. ".selected_rewards_table",
    row_height = 20,
    parent = "detail_panel",
    style = {
        background_color = ui.color(5, 5, 5, 185),
        header_color = ui.color(45, 28, 20, 235),
        selected_row_color = ui.color(60, 42, 22, 150),
        hover_row_color = ui.color(50, 50, 50, 120),
    },
})

win:button("detail_accept_mission", {
    rect = ui.rect(394, 338, 112, 24),
    text = "Recibir mision",
    action = "seasonpass_panel.accept_selected",
    parent = "detail_panel",
})

win:button("detail_claim_reward", {
    rect = ui.rect(394, 370, 112, 24),
    text = "Recibir premio",
    action = "seasonpass_panel.claim_selected",
    parent = "detail_panel",
})

win:button("back_to_list", {
    rect = ui.rect(394, 414, 112, 24),
    text = "Volver",
    action = "seasonpass_panel.back_to_list",
    parent = "detail_panel",
})

refresh()
set_view("main")

return win
