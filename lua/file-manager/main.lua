local M = {}
local FILE_TYPE = 'file-manager'


-- ファイルマネージャを開く
function M.open()
  vim.cmd('split')
  vim.cmd('enew')
  vim.bo.filetype = FILE_TYPE
end

-- ファイルマネージャを閉じる
function M.close()
  local bufs = vim.api.nvim_list_bufs()
  for _, buf in ipairs(bufs) do
    if vim.bo[buf].filetype == FILE_TYPE then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end

-- ファイルマネージャが開かれているかどうか
-- @return boolean
function M.is_open()
  local bufs = vim.api.nvim_list_bufs()
  for _, buf in ipairs(bufs) do
    if vim.bo[buf].filetype == FILE_TYPE then
      return true
    end
  end
  return false
end

function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end

function M.test()
  print("test called")
end

return M
