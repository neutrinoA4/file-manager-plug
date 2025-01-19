local M = {}
local FILE_TYPE = 'file-manager'
Current_dir = nil


-- ファイルマネージャを開く
-- function M.open()
--   local files = M.ls()
--   vim.cmd('split')
--   vim.cmd('enew')
--   vim.bo.buftype = 'nofile' -- 追加
--   vim.bo.filetype = FILE_TYPE
--   for _, file in ipairs(files) do
--     vim.api.nvim_buf_set_lines(0, -1, -1, false, { file })
--   end
--   -- バッファをタブに表示しない
--   vim.cmd('setlocal nobuflisted')
-- end

function M.open()
  local files = M.ls()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'filetype', FILE_TYPE)

  for _, file in ipairs(files) do
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, { file })
  end

  local width = vim.o.columns
  local height = math.ceil((vim.o.lines) / 2 - 2)
  local row = height
  local col = width

  local opts = {
    style = 'minimal',
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    border = 'single',
  }
  -- set background color
  vim.api.nvim_win_set_option(0, 'winhl', 'Normal:Normal,FloatBorder:MyBorder')

  vim.api.nvim_open_win(buf, true, opts)
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
  local files = vim.fn.systemlist('ls -l ' .. file_dir)
  return files
end

function M.open_dir_action(path)
end

function M.open_file_action(path)
  M.close()
  vim.cmd('edit ' .. path)
end

function M.open_file()
  local line = vim.api.nvim_get_current_line()
  local head = string.match(line, '^%S')
  -- '-' or 'd' 以外の行は無視
  if head ~= '-' and head ~= 'd' then
    return
  end
  local file = string.match(line, '%S+$')
  local path = Current_dir .. '/' .. file
  if head == 'd' then
    M.open_dir_action(path)
  end
  if head == '-' then
    M.open_file_action(path)
  end
end

function M.test()
  print("test called")
end

-- keymap
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'file-manager',
  callback = function()
    -- 例: 'q'キーでファイルマネージャを閉じる
    vim.api.nvim_buf_set_keymap(0, 'n', 'q', ':lua require("file-manager").close()<CR>',
      { noremap = true, silent = true })
    -- 他のキーマップもここに追加できます
    vim.api.nvim_buf_set_keymap(0, 'n', '<CR>', ':lua require("file-manager").open_file()<CR>',
      { noremap = true, silent = true })
  end
})

return M
