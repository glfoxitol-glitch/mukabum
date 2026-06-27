local ui = SFUI.ui
local bind = ui.import("binding")
local actions = SFUI.actions
local quests = ui.import("quests")

local EXPANDED_ID = "quests.expanded_id"
local ONLY_MAP = "quests.only_map"

local visible_rows = {}

local function as_table(value)
    if type(value) == "table" then
        return value
    end
    return {}
end

local function get_active_rows()
    return as_table(quests.get_active_quests())
end

local function get_expanded_id()
    return tonumber(bind.get(EXPANDED_ID)) or tonumber(bind.get("quests.selected_id")) or 0
end

local function make_progress_text(line)
    local value = tonumber(line.value) or 0
    local current = tonumber(line.current) or 0
    if value <= 0 then
        return ""
    end
    return string.format("%d/%d", current, value)
end

local function get_detail_lines()
    local result = {}
    local selected = quests.get_selected()

    if type(selected) == "table" then
        if selected.summary and selected.summary ~= "" then
            result[#result + 1] = {
                text = "  " .. selected.summary,
                progress = "",
                status = "Info",
                row_type = "detail"
            }
        end

        for _, line in ipairs(as_table(selected.lines)) do
            result[#result + 1] = {
                text = "  " .. (line.text or ""),
                progress = "",
                status = line.kind or "",
                row_type = "detail"
            }
        end

        for _, request in ipairs(as_table(selected.requests)) do
            result[#result + 1] = {
                text = "    " .. (request.item_name or request.type_name or "Objetivo"),
                progress = make_progress_text(request),
                status = request.met and "OK" or "Pendiente",
                row_type = "objective"
            }
        end

        for _, reward in ipairs(as_table(selected.rewards)) do
            result[#result + 1] = {
                text = "    Premio: " .. (reward.item_name or reward.type_name or "Reward"),
                progress = "",
                status = "",
                row_type = "reward"
            }
        end
    end

    if #result == 0 then
        result[1] = {
            text = "  Sin informacion adicional para esta quest.",
            progress = "",
            status = "",
            row_type = "detail"
        }
    end

    return result
end

local function build_quest_rows()
    visible_rows = {}
    local output = {}
    local expanded_id = get_expanded_id()

    for _, row in ipairs(get_active_rows()) do
        local quest_id = tonumber(row.quest_index) or 0
        local expanded = quest_id > 0 and quest_id == expanded_id
        local arrow = expanded and "v" or ">"
        local subject = row.subject or "Quest"
        local status = expanded and "Abierta" or "Cerrada"

        output[#output + 1] = {
            text = arrow .. " " .. subject,
            progress = "",
            status = status,
        }
        visible_rows[#visible_rows + 1] = {
            type = "quest",
            quest_index = quest_id,
            source = row
        }

        if expanded then
            for _, detail in ipairs(get_detail_lines()) do
                output[#output + 1] = detail
                visible_rows[#visible_rows + 1] = {
                    type = detail.row_type or "detail",
                    quest_index = quest_id,
                    source = detail
                }
            end
        end
    end

    if #output == 0 then
        output[1] = {
            text = "No hay quests activas.",
            progress = "",
            status = ""
        }
        visible_rows[1] = { type = "empty", quest_index = 0 }
    end

    return output
end

local function expand_quest(quest_index)
    quest_index = tonumber(quest_index) or 0
    if quest_index <= 0 then
        return
    end

    local current = get_expanded_id()
    if current == quest_index then
        bind.set(EXPANDED_ID, 0)
        return
    end

    bind.set(EXPANDED_ID, quest_index)
    quests.select_by_id(quest_index)
    quests.request_detail(quest_index)
end

local function expand_first()
    local rows = get_active_rows()
    local first = rows[1]
    local quest_index = first and tonumber(first.quest_index) or 0
    if quest_index > 0 then
        bind.set(EXPANDED_ID, quest_index)
        quests.select_by_id(quest_index)
        quests.request_detail(quest_index)
    else
        bind.set(EXPANDED_ID, 0)
    end
end

bind.set(ONLY_MAP, bind.get(ONLY_MAP) or false)
bind.set(EXPANDED_ID, bind.get(EXPANDED_ID) or 0)

actions.register("quests.refresh_v2", function()
    quests.request_refresh()
    expand_first()
end)

actions.register("quests.toggle_row", function(index)
    build_quest_rows()
    local item = visible_rows[(tonumber(index) or 0) + 1]
    if item and item.type == "quest" then
        expand_quest(item.quest_index)
    end
end)

actions.register("quests.expand_selected", function()
    local quest_index = tonumber(bind.get("quests.selected_id")) or get_expanded_id()
    expand_quest(quest_index)
end)

local win = ui.window("quests_panel", {
    title = quests.get_title(),
    rect = ui.rect(560, 84, 336, 364),
    hotkey = "F8",
    fade_time = 0.25,
    closable = true,
    movable = true,
    show_header = false,
    header_height = 0,
    title_position = { 18, 8 },
    close_button = ui.rect(306, 10, 16, 16),
    show_border = false,
    on_open = function()
        quests.request_refresh()
        expand_first()
    end
})

win:label("quests_panel_caption", {
    rect = ui.rect(18, 12, 220, 16),
    text = "Quest Tracker",
    text_color = 0xFFEFEFEF,
    font = "bold"
})

win:text("quests_summary", {
    rect = ui.rect(18, 32, 286, 16),
    bind = "quests.summary",
    text_color = 0xFF9CA9BE,
    font = "normal"
})

win:checkbox("quests_only_map", {
    rect = ui.rect(18, 56, 204, 16),
    text = "Mostrar quests de este mapa",
    checked_bind = ONLY_MAP,
    checked = false,
    text_color = 0xFFD7D7D7,
    checked_text_color = 0xFFFFD266,
    unchecked_text_color = 0xFF9CA9BE
})

win:panel("quests_list_frame", {
    rect = ui.rect(18, 78, 300, 218),
    header_visible = false,
    show_background = true,
    show_border = true,
    background_color = 0x76000000,
    border_color = 0xFF000000,
    padding_left = 0,
    padding_top = 0,
    padding_right = 0,
    padding_bottom = 0
})

win:table("quests_accordion", {
    parent = "quests_list_frame",
    rect = ui.rect(2, 2, 296, 214),
    row_height = 22,
    show_header = false,
    columns = {
        { key = "text", title = "", width = 214, align = "left" },
        { key = "progress", title = "", width = 44, align = "center", type = "progress" },
        { key = "status", title = "", width = 38, align = "right" },
    },
    bind_rows = build_quest_rows,
    action = "quests.toggle_row",
    style = {
        show_background = false,
        show_border = false,
        show_header_background = false,
        selected_row_color = 0x663F8CCF,
        hover_row_color = 0x553C3C48,
        row_text_color = 0xFFF0F0F0,
        header_text_color = 0xFFFFE4C0,
    }
})

win:text("quests_selected_status", {
    rect = ui.rect(18, 306, 300, 16),
    bind = "quests.selected_status",
    text_color = 0xFFCFCFCF,
    font = "normal",
    align = "left"
})

win:button("quests_refresh", {
    rect = ui.rect(18, 332, 84, 20),
    text = "Refresh",
    action = "quests.refresh_v2"
})

win:button("quests_open", {
    rect = ui.rect(110, 332, 84, 20),
    text = "Open",
    on_click = function()
        quests.open_selected()
    end
})

win:button("quests_native", {
    rect = ui.rect(202, 332, 84, 20),
    text = "Native",
    on_click = function()
        quests.open_native_list()
    end
})

return win
