local M = {}

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

function M.rename(old_name, new_name)
  vim.fn.system('mv ' .. old_name .. ' ' .. new_name)
end

function M.delete(name)
  vim.fn.system('rm -rf ' .. name)
end

function M.create(name)
  vim.fn.system('touch ' .. name)
end

return M
