local books = {}

function books.label(book)
  local label = book.label
  if label and label ~= "" then return label end
  return {"bbs.unnamed-book"}
end

-- Iterative traversal keeps deep nesting out of the Lua call stack. LuaItem
-- references follow the actual book even when inventory sorting moves its slot.
function books.collect(player)
  local main = player.get_main_inventory()
  if not main then return {} end
  local result, pending, seen = {}, {}, {}
  local function add_inventory(inventory, path)
    for index = #inventory, 1, -1 do
      local stack = inventory[index]
      if stack.valid_for_read and stack.is_blueprint_book then
        pending[#pending + 1] = {item = stack.item, path = path}
      end
    end
  end
  add_inventory(main, {})
  while #pending > 0 do
    local entry = table.remove(pending)
    local book = entry.item
    local number = book.item_number
    if not seen[number] then
      seen[number] = true
      local path = {""}
      for _, part in ipairs(entry.path) do
        path[#path + 1] = part
        path[#path + 1] = " / "
      end
      path[#path + 1] = books.label(book)
      local inventory = book.get_inventory(defines.inventory.item_main)
      local count = 0
      for index = 1, #inventory do
        if inventory[index].valid_for_read then count = count + 1 end
      end
      result[#result + 1] = {item = book, number = number, path = path, count = count}
      local child_path = {}
      for index, part in ipairs(entry.path) do child_path[index] = part end
      child_path[#child_path + 1] = books.label(book)
      add_inventory(inventory, child_path)
    end
  end
  return result
end

return books
