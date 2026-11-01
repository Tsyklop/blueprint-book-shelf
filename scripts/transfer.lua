local transfer = {}

function transfer.is_book(item)
  if not item or not item.valid then return false end
  if item.object_name == "LuaItemStack" and not item.valid_for_read then return false end
  return item.is_blueprint_book
end

-- Test the entire source tree, not only its active blueprint. Moving a parent
-- into one of its descendants would create a cycle.
local function contains_book(source, target_number)
  local pending = {source}
  local seen = {}
  while #pending > 0 do
    local book = table.remove(pending)
    local number = book.item_number
    if number == target_number then return true end
    if not seen[number] then
      seen[number] = true
      local inventory = book.get_inventory(defines.inventory.item_main)
      if inventory then
        for index = 1, #inventory do
          local child = inventory[index]
          if child.valid_for_read and child.is_blueprint_book then
            pending[#pending + 1] = child
          end
        end
      end
    end
  end
  return false
end

function transfer.move(player, target)
  if not transfer.is_book(target) then return false, "invalid-target" end

  -- Library records are references, not inventory items. Do not silently copy
  -- or remove records in the player's blueprint library.
  if player.cursor_record then return false, "library-cursor" end
  local source = player.cursor_stack
  if not source or not source.valid_for_read then return false, "empty-hand" end
  if not (source.is_blueprint or source.is_blueprint_book) then
    return false, "unsupported-item"
  end
  if source.is_blueprint_book and contains_book(source, target.item_number) then
    return false, "recursive-book"
  end

  local inventory = target.get_inventory(defines.inventory.item_main)
  if not inventory then return false, "invalid-target" end
  if not inventory.can_insert(source) then return false, "book-full" end
  local was_empty = inventory.is_empty()

  -- The 2.1 transfer API also grows dynamic book inventories. No export/import:
  -- labels, parameters, icons, active indices and nested contents stay attached.
  local succeeded, moved = pcall(function() return inventory.transfer_from_stack(source) end)
  if not succeeded then
    log("Blueprint book transfer rejected: " .. tostring(moved))
    return false, "transfer-failed"
  end
  if moved ~= 1 then return false, "transfer-failed" end
  if was_empty then
    for index = 1, #inventory do
      if inventory[index].valid_for_read then target.active_index = index; break end
    end
  end
  return true
end

return transfer
