local default_arc_root = vim.env.HOME..'/arcadia'
local arc_prefix = '$(S)'

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
    if opts.local_only then
        vim.list_extend(cmd, {'--current-folder'})
    end
    if opts.whole_words then
        vim.list_extend(cmd, {'--whole-words'})
    end

    vim.list_extend(cmd, {'--max='..opts.max_output, '--', pattern})

    return cmd
end

local starts_with = function(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end

local pick_choose = function(item, arc_root)
    if type(item) == 'string' and starts_with(item, arc_prefix) then
        return arc_root..string.sub(item, string.len(arc_prefix) + 1)
    else
        return item
    end
end

local local_pick_choose = function(item, arc_root)
    return item
end

local arc_grep = function(opts, pick_chooser)
    return function(local_opts)
        local_opts = vim.tbl_deep_extend('force', {
            source = {
                name = 'Grep (ya cs)',
                choose = function(item)
                    return MiniPick.default_choose(pick_chooser(item, opts.arc_root))
                end
            }
        }, local_opts or {})

        local pattrern = type(local_opts.pattern) == 'string' and local_opts.pattern or vim.fn.input('Grep pattern: ')
        return MiniPick.builtin.cli({ command = cs_grep_command(pattrern, opts.grep) }, local_opts)
    end
end

local arc_grep_live = function(opts, pick_chooser)
    return function(local_opts)
        local_opts = vim.tbl_deep_extend('force', {
            source = {
                name = 'Live Grep (ya cs)',
                choose = function(item)
                    return MiniPick.default_choose(pick_chooser(item, opts.arc_root))
                end
            }
        }, local_opts or {})

        local set_items_opts, spawn_opts = { do_match = false, querytick = MiniPick.get_querytick()}, { cwd = vim.fn.getcwd() }
        local process

        local match = function(_, _, query)
            pcall(vim.loop.process_kill, process)
            if MiniPick.get_querytick() == set_items_opts.querytick then return end
            if #query == 0 then return MiniPick.set_picker_items({}, set_items_opts) end

            set_items_opts.querytick = MiniPick.get_querytick()
            local command = cs_grep_command(table.concat(query), opts.grep)
            process = MiniPick.set_picker_items_from_cli(command, { set_items_opts = set_items_opts, spawn_opts = spawn_opts })
        end

        local_opts = vim.tbl_deep_extend('force', local_opts, { source = { items = {}, match = match }, mappings = {} })

        return MiniPick.start(local_opts)
    end
end

local setup_arc_grep = function(opts)
    opts.grep.local_only = false
    MiniPick.registry.arc_grep = arc_grep(opts, pick_choose)
    MiniPick.registry.arc_grep_live = arc_grep_live(opts, pick_choose)

    opts.grep.local_only = true
    MiniPick.registry.local_arc_grep = arc_grep(opts, local_pick_choose)
    MiniPick.registry.local_arc_grep_live = arc_grep_live(opts, local_pick_choose)
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
            max_output = 100,
            local_only = false,
            whole_words = false
        }
    }
    opts = vim.tbl_deep_extend('force', default_opts, opts or {})

    M.setup_mini_pick(opts)
end

return M
