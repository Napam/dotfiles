--- Deep merge that appends and deduplicates lists, and recurses into dicts.
--- Semantics:
---   - vim.NIL as a value removes the key from base.
---   - Empty `{}` at a dict position replaces it (vim.islist({}) is true, so
---     it's treated as a list and overwrites the dict).
---   - Override values are deepcopied into base, so later mutations of either
---     side do not leak across.
--- WARN: table-valued list items are always appended (not idempotent).
--- Re-merging duplicates them.
---@param base table
---@param override table
---@return table
local function merge(base, override)
  for k, v in pairs(override) do
    if v == vim.NIL then
      base[k] = nil
    elseif type(v) == "table" then
      local bv = base[k]
      if type(bv) ~= "table" then
        base[k] = vim.deepcopy(v)
      elseif vim.islist(v) then
        --- WARN: if bv is a dict and v is a list at the same key, base is replaced.
        if not vim.islist(bv) then
          base[k] = vim.deepcopy(v)
        else
          for _, item in ipairs(v) do
            --- WARN: tables are always appended (structural dedup is too expensive).
            if type(item) == "table" then
              bv[#bv + 1] = vim.deepcopy(item)
            elseif not vim.list_contains(bv, item) then
              bv[#bv + 1] = item
            end
          end
        end
      else
        merge(bv, v)
      end
    else
      base[k] = v
    end
  end
  return base
end

return merge
