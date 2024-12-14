return {
  getWords = function()
    local wordcount = vim.fn.wordcount()
    if wordcount.visual_words ~= nil then
      return tostring(wordcount.visual_words) .. "/" .. tostring(wordcount.words) .. " W"
    end
    return tostring(wordcount.words) .. " W"
  end
}
