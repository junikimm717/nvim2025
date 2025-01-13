local M = {}

M.getWords = function()
  local wordcount = vim.fn.wordcount()
  if wordcount.visual_words ~= nil then
    return tostring(wordcount.visual_words) .. "/" .. tostring(wordcount.words) .. " W"
  end
  return tostring(wordcount.words) .. " W"
end

M.read_json = function(filename)
  filename = vim.fs.normalize(filename)
  if not vim.fn.filereadable(filename) then
    return nil
  end
  local content = vim.fn.readfile(filename)
  if not content or #content == 0 then
    return nil
  end
  content = table.concat(content, "\n")
  local success, res = pcall(vim.json.decode, content)
  if not success then
    return nil
  else
    return res
  end
end

return M
