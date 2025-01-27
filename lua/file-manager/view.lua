local M = {}
local FILE_TYPE = 'file-manager'
local FILE_TYPE_CHECK = 'file-manager-check'
local command = require("file-manager/command")
Current_dir = nil
Win = nil
Lines = nil

function M.rename_action(current_files, lines)
  for i = 1, math.min(#current_files, #lines) do
    local file = string.match(current_files[i], '%S+$')
    local line = string.match(lines[i], '%S+$')
    if file ~= line then
      local path = Current_dir .. '/' .. file
      local new_path = Current_dir .. '/' .. line
      command.rename(path, new_path)
    end
  end
end

function M.delete_action(current_files, lines)
  local delete_files = {}
  for _, file in ipairs(current_files) do
    if not vim.tbl_contains(lines, file) then
      table.insert(delete_files, file)
    end
  end
  for _, file in ipairs(delete_files) do
    local path = Current_dir .. '/' .. file
    if file == '../' then
      return
    end
    command.delete(path)
  end
end

function M.create_action(current_files, lines)
  local create_files = {}
  for _, line in ipairs(lines) do
    if not vim.tbl_contains(current_files, line) then
      table.insert(create_files, line)
    end
  end
  for _, file in ipairs(create_files) do
    local path = Current_dir .. '/' .. file
    command.create(path)
  end
end

function M.cancel_action()
  local current_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, Lines)
  vim.api.nvim_buf_set_option(current_buf, 'filetype', FILE_TYPE)
end
function M.do_action()
  if Lines == nil then
    return
  end
  local current_buf = vim.api.nvim_get_current_buf()
  local current_files = command.ls(Current_dir)
  if #current_files > #Lines then
    M.delete_action(current_files, Lines)
  end
  if #current_files < #Lines then
    M.create_action(current_files, Lines)
  end
  if #current_files == #Lines then
    M.rename_action(current_files, Lines)
  end
  local files = command.ls(Current_dir)
  vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, files)
  vim.api.nvim_buf_set_option(current_buf, 'filetype', FILE_TYPE)
end

function M.on_save()
  local current_buf = vim.api.nvim_get_current_buf()
  Lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
  local msg = 'Do you want to do this action? [y/n]'
  vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, { msg })
  vim.api.nvim_buf_set_option(current_buf, 'filetype', FILE_TYPE_CHECK)
end

vim.api.nvim_create_autocmd("BufWriteCmd", {
  pattern = "*",
  callback = function()
    if vim.api.nvim_buf_get_option(0, 'filetype') == 'file-manager' then
      M.on_save()
    else
      vim.cmd('w')
    end
  end
})

-- ファイルマネージャを開く
function M.open()
  local file_dir = vim.fn.expand('%:p:h')
  Current_dir = file_dir
  local files = command.ls(file_dir)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'acwrite')
  vim.api.nvim_buf_set_option(buf, 'filetype', FILE_TYPE)
  -- set buf name
  vim.api.nvim_buf_set_name(buf, 'file-manager')

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, files)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

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
  -- Enable cursor line highlighting
  vim.api.nvim_win_set_option(Win, 'cursorline', true)
end

-- ファイルマネージャを閉じる
function M.close()
  if Win then
    vim.api.nvim_win_close(Win, true)
  end
  Win = nil
end

function M.change_title()
  if Win then
    vim.api.nvim_win_set_config(Win, { title = Current_dir })
  end
end

-- ファイルマネージャが開かれているかどうか
-- @return boolean
function M.is_open()
  if Win then
    if vim.api.nvim_win_is_valid(Win) then
      return Win ~= nil
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

function M.open_dir_action(path, is_parent_dir)
  local current_buf = vim.api.nvim_get_current_buf()
  local files = nil
  if is_parent_dir then
    local parent_dir = vim.fn.fnamemodify(Current_dir, ':h')
    files = command.ls(parent_dir)
    Current_dir = parent_dir
  else
    files = command.ls(path)
    vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, files)
    Current_dir = path
  end
  vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, files)
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
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'file-manager-check',
  callback = function()
    vim.api.nvim_buf_set_keymap(0, 'n', 'n', ':lua require("file-manager").cancel_action()<CR>',
      { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(0, 'n', 'y', ':lua require("file-manager").do_action()<CR>',
      { noremap = true, silent = true })
  end
})

return M
