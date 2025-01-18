local M = {}
local FILE_TYPE = 'file-manager'
Current_dir = nil


-- ファイルマネージャを開く
function M.open()
  local files = M.ls()
  vim.cmd('split')
  vim.cmd('enew')
  vim.bo.buftype = 'nofile' -- 追加
  vim.bo.filetype = FILE_TYPE
  for _, file in ipairs(files) do
    vim.api.nvim_buf_set_lines(0, -1, -1, false, { file })
  end
  -- バッファをタブに表示しない
  vim.cmd('setlocal nobuflisted')
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

function M.ls()
  local file_dir = vim.fn.expand('%:p:h')
  Current_dir = file_dir
  vim.cmd("cd " .. file_dir)
  local files = vim.fn.systemlist('ls -l ' .. file_dir)
  return files
end

function M.open_file()
  local line = vim.api.nvim_get_current_line()
  local file = string.match(line, '%S+$')
  local path = Current_dir .. '/' .. file
  M.close()
  vim.cmd('edit ' .. path)
end

function M.test()
  print("test called")
end

return M
