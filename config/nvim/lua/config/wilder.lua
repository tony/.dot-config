local M = {}

function M.setup()
  local wilder = require('wilder')
  wilder.setup({
    modes = { ':', '/', '?' },
    use_python_remote_plugin = 0,
  })

  wilder.set_option('pipeline', {
    wilder.branch(wilder.cmdline_pipeline({ fuzzy = 2 }), wilder.search_pipeline()),
  })

  wilder.set_option(
    'renderer',
    wilder.renderer_mux({
      [':'] = wilder.popupmenu_renderer({
        pumblend = 15,
        highlighter = wilder.basic_highlighter(),
        left = {
          ' ',
          wilder.popupmenu_devicons(),
        },
        right = {
          ' ',
          wilder.popupmenu_scrollbar(),
        },
      }),
      ['/'] = wilder.wildmenu_renderer({
        highlighter = wilder.basic_highlighter(),
      }),
    })
  )
end

return M
