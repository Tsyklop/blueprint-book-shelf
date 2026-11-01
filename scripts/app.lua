local books = require("__BlueprintBookShelf__/scripts/books")
local transfer = require("__BlueprintBookShelf__/scripts/transfer")
local app = {}
local FRAME = "bbs-panel"
local BUTTON = "bbs-top-button"

local function state_for(player_index)
  storage.bbs_players = storage.bbs_players or {}
  storage.bbs_players[player_index] = storage.bbs_players[player_index] or {entries = {}}
  return storage.bbs_players[player_index]
end

local function panel(player)
  return player.gui.screen[FRAME]
end

local function add_button(player)
  if player.gui.top[BUTTON] then return end
  player.gui.top.add({
    type = "sprite-button", name = BUTTON, sprite = "item/blueprint-book",
    tooltip = {"bbs.toggle-tooltip"}
  })
end

local function set_status(player, message)
  local frame = panel(player)
  if frame then frame.status.caption = message end
end

local function matches(entry, query)
  if query == "" then return true end
  -- Labels are player text; use literal matching, never Lua patterns.
  local parts = {}
  for _, part in ipairs(entry.path) do
    if type(part) == "string" then parts[#parts + 1] = part end
  end
  return string.find(string.lower(table.concat(parts)), query, 1, true) ~= nil
end

function app.refresh(player)
  local frame = panel(player)
  if not frame then return end
  local state = state_for(player.index)
  state.entries = books.collect(player)
  local list = frame.list
  list.clear()
  local query = string.lower(frame.toolbar.search.text)
  local shown = 0
  for index, entry in ipairs(state.entries) do
    if matches(entry, query) then
      shown = shown + 1
      local button = list.add({
        type = "button", name = "book-" .. index,
        caption = {"", "[item=blueprint-book] ", entry.path, "  (", entry.count, ")"},
        tooltip = {"bbs.book-tooltip", entry.path, entry.count},
        tags = {bbs_entry = index, bbs_number = entry.number}
      })
      button.style.horizontally_stretchable = true
      button.style.width = 370
      button.style.horizontal_align = "left"
      button.style.minimal_height = 36
    end
  end
  if shown == 0 then
    local empty = list.add({type = "label", caption = {#state.entries == 0 and "bbs.empty" or "bbs.no-matches"}})
    empty.style.single_line = false
    empty.style.maximal_width = 360
  end
  frame.total.caption = {"bbs.total", shown, #state.entries}
end

function app.close(player)
  local frame = panel(player)
  if frame then frame.destroy() end
  -- Release LuaItem references while the panel is closed.
  state_for(player.index).entries = {}
end

function app.open(player)
  if panel(player) then return end
  local frame = player.gui.screen.add({type = "frame", name = FRAME, direction = "vertical"})
  frame.style.width = 410
  local title = frame.add({type = "flow", name = "titlebar", direction = "horizontal"})
  title.drag_target = frame
  title.add({type = "label", caption = {"bbs.title"}, style = "frame_title"}).drag_target = frame
  local spacer = title.add({type = "empty-widget", style = "draggable_space_header"})
  spacer.style.horizontally_stretchable = true
  spacer.style.height = 24
  spacer.drag_target = frame
  title.add({type = "sprite-button", name = "bbs-close", sprite = "utility/close", style = "frame_action_button", tooltip = {"gui.close"}})
  local help = frame.add({type = "label", caption = {"bbs.help"}})
  help.style.single_line = false
  help.style.maximal_width = 380
  local toolbar = frame.add({type = "flow", name = "toolbar", direction = "horizontal"})
  local search = toolbar.add({type = "textfield", name = "search", tooltip = {"bbs.search-tooltip"}})
  search.style.horizontally_stretchable = true
  toolbar.add({type = "button", name = "bbs-refresh", caption = {"bbs.refresh"}})
  local list = frame.add({type = "scroll-pane", name = "list", direction = "vertical", horizontal_scroll_policy = "never"})
  list.style.horizontally_stretchable = true
  list.style.maximal_height = math.max(120, math.min(440, player.display_resolution.height / player.display_scale - 280))
  frame.add({type = "label", name = "total", caption = ""})
  local status = frame.add({type = "label", name = "status", caption = {"bbs.ready"}})
  status.style.single_line = false
  status.style.maximal_width = 380
  -- Non-modal: the player's normal inventory remains usable alongside the panel.
  frame.location = {x = 16, y = 80}
  app.refresh(player)
end

function app.on_toggle(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  if panel(player) then app.close(player) else app.open(player) end
end

function app.on_input(event)
  local player = game.get_player(event.player_index)
  if not player or not panel(player) then return end
  local element = event.element
  -- Use the element from this exact keypress, never a cached hover target.
  if not element or not element.valid or element.get_mod() ~= script.mod_name then return end
  local tags = element.tags
  if not tags.bbs_entry then return end
  local ancestor = element.parent
  while ancestor and ancestor ~= panel(player) do ancestor = ancestor.parent end
  if not ancestor then return end
  local entry = state_for(player.index).entries[tags.bbs_entry]
  if not entry or entry.number ~= tags.bbs_number then return end

  -- The panel may be stale after sorting, deletion or another mod's changes.
  -- Resolve the identity again, and require the destination to still be in this
  -- player's inventory tree (never a dropped book or somebody else's inventory).
  local target
  for _, current in ipairs(books.collect(player)) do
    if current.number == entry.number then target = current.item; break end
  end
  if not target then
    set_status(player, {"bbs.invalid-target"})
    app.refresh(player)
    return
  end
  local name = books.label(target)
  local ok, reason = transfer.move(player, target)
  if ok then
    set_status(player, {"bbs.inserted", name})
    app.refresh(player)
  else
    set_status(player, {"bbs." .. reason})
  end
end

function app.on_click(event)
  local element = event.element
  if not element or not element.valid or element.get_mod() ~= script.mod_name then return end
  local player = game.get_player(event.player_index)
  if not player then return end
  if element.name == BUTTON then app.on_toggle(event)
  elseif element.name == "bbs-close" then app.close(player)
  elseif element.name == "bbs-refresh" then
    app.refresh(player)
    set_status(player, {"bbs.ready"})
  end
end

function app.on_search(event)
  if event.element and event.element.valid and event.element.name == "search"
      and event.element.get_mod() == script.mod_name then
    local player = game.get_player(event.player_index)
    if player and panel(player) and event.element.parent == panel(player).toolbar then app.refresh(player) end
  end
end

function app.on_inventory_changed(event)
  local player = game.get_player(event.player_index)
  if player then app.refresh(player) end
end

function app.on_player_created(event)
  local player = game.get_player(event.player_index)
  if player then add_button(player) end
end

function app.on_player_removed(event)
  if storage.bbs_players then storage.bbs_players[event.player_index] = nil end
end

function app.on_init()
  storage.bbs_players = {}
  for _, player in pairs(game.players) do add_button(player) end
end

function app.on_configuration_changed()
  for _, player in pairs(game.players) do
    add_button(player)
    if panel(player) then app.close(player); app.open(player) end
  end
end

return app
