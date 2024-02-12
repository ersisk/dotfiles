return {
  "goolord/alpha-nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },

  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.startify")
    dashboard.section.header.val = {
      [[oooooooooooo ooooooooo.    .oooooo..o ooooo      ooo oooooo     oooo ooooo ooo        ooooo ]],
      [[`888'     `8 `888   `Y88. d8P'    `Y8 `888b.     `8'  `888.     .8'  `888' `88.       .888' ]],
      [[888          888   .d88' Y88bo.       8 `88b.    8    `888.   .8'    888   888b     d'888  ]],
      [[ 888oooo8     888ooo88P'   `"Y8888o.   8   `88b.  8     `888. .8'     888   8 Y88. .P  888  ]],
      [[ 888    "     888`88b.         `"Y88b  8     `88b.8      `888.8'      888   8  `888'   888  ]],
      [[888       o  888  `88b.  oo     .d8P  8       `888       `888'       888   8    Y     888  ]],
      [[o888ooooood8 o888o  o888o 8""88888P'  o8o        `8        `8'       o888o o8o        o888o ]]
    }

    alpha.setup(dashboard.opts)
  end,
}
