local M = {}
local FILE_TYPE = 'file-manager'
Current_dir = nil
Win = nil


-- ファイルマネージャを開く
function M.open()
  local file_dir = vim.fn.expand('%:p:h')
  Current_dir = file_dir
  local files = M.ls(file_dir)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'filetype', FILE_TYPE)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, files)

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
    border = { '─', '─', ' ', ' ', ' ', ' ', ' ', ' ' }, -- Top border only
    title = Current_dir,
  }
  -- set background color
  vim.api.nvim_win_set_option(0, 'winhl', 'Normal:Normal,FloatBorder:MyBorder')

  Win = vim.api.nvim_open_win(buf, true, opts)
end

-- ファイルマネージャを閉じる
function M.close()
  if Win then
    vim.api.nvim_win_close(Win, true)
    Win = nil
  end
end

function M.change_title()
  if Win then
    vim.api.nvim_win_set_config(Win, { title = Current_dir })
  end
end

-- ファイルマネージャが開かれているかどうか
-- @return boolean
function M.is_open()
  return Win ~= nil
end

function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end

function M.insert_parent_dir(files)
  if #files ~= 0 then
    table.remove(files, 1)
  end
  table.insert(files, 1, '../')
  return files
end

function M.ls(dir)
  local files = vim.fn.systemlist('ls -l ' .. dir)
  return M.insert_parent_dir(files)
end

function M.open_dir_action(path, is_parent_dir)
  local current_buf = vim.api.nvim_get_current_buf()
  if is_parent_dir then
    local parent_dir = vim.fn.fnamemodify(Current_dir, ':h')
    vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, M.ls(parent_dir))
    Current_dir = parent_dir
  else
    vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, M.ls(path))
    Current_dir = path
  end
  M.change_title()
end

function M.open_file_action(path)
  M.close()
  vim.cmd('edit ' .. path)
end

function M.open_file()
  local line = vim.api.nvim_get_current_line()
  local head = string.match(line, '^%S+')
  -- head の先頭の文字を取得
  local top = string.sub(head, 1, 1)
  -- '-' or 'd' 以外の行は無視
  if top ~= '-' and top ~= 'd' and head ~= '../' then
    return
  end
  local file = string.match(line, '%S+$')
  local path = Current_dir .. '/' .. file
  if top == 'd' or head == '../' then
    local is_parent_dir = head == '../'
    M.open_dir_action(path, is_parent_dir)
  end
  if top == '-' then
    M.open_file_action(path)
  end
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
    vim.api.nvim_buf_set_keymap(0, 'n', '<BS>',
      ':lua require("file-manager").open_dir_action(vim.fn.fnamemodify(Current_dir, ":h"), true)<CR>',
      { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', '<C-j>', ':lua require("file-manager").open_file()<CR>',
      { noremap = true, silent = true })
  end
})

return M
