local default_arc_root = vim.env.HOME..'/arcadia'

local cs_wrapper = function()
    local plugin_dir = string.sub(debug.getinfo(1).source, 2, string.len('/lua/arc.lua') * -1)
    return plugin_dir..'scripts/cs_wrapper.py'
end

local cs_grep_command = function(pattern, opts)
    local cmd = {'python3', cs_wrapper()}

    if opts.no_junk then
        vim.list_extend(cmd, {'--no-junk'})
    end
    if opts.no_contrib then
        vim.list_extend(cmd, {'--no-contrib'})
    end

    vim.list_extend(cmd, {'--', pattern})
end

local starts_with = function(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end

local pick_choose = function(item, arc_root)
    local prefix = '$(S)'

    if type(item) == 'string' and starts_with(item, prefix) then
        return arc_root..string.sub(item, string.len(prefix) + 1)
    else
        return item
    end
end

local setup_arc_grep = function(opts)
    MiniPick.registry.arc_grep = function(local_opts)
        local_opts = vim.tbl_deep_extend('force', {
            source = {
                name = 'Grep (ya cs)',
                choose = function(item)
                    return MiniPick.default_choose(pick_choose(item, opts.arc_root))
                end
            }
        }, local_opts or {})

        local pattrern = type(local_opts.pattern) == 'string' and local_opts.pattern or vim.fn.input('Grep pattern: ')
        return MiniPick.builtin.cli({ command = cs_grep_command(pattrern, opts.grep) }, local_opts)
    end
end

local M = {}

function M.setup_mini_pick(opts)
    local ok, _ = pcall(require, 'mini.pick')
    if not ok then
        return
    end

    setup_arc_grep(opts)
end

function M.setup(opts)
    local default_opts = {
        arc_root = default_arc_root,
        grep = {
            no_junk = true,
            no_contrib = true,
            max_output = 100
        }
    }
    opts = vim.tbl_deep_extend('force', default_opts, opts or {})

    M.setup_mini_pick(opts)
end

return M
