local default_arc_root = vim.env.HOME..'/arcadia'

local M = {}

function M.setup(opts)
    local default_opts = {
        arc_root = default_arc_root
    }
    opts = vim.tbl_deep_extend('force', default_opts, opts or {})

    print("hello, ARC_ROOT="..opts.arc_root)
end

return M
