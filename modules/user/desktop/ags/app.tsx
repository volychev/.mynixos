import app from "ags/gtk4/app"

import Bar from "./widget/bar"
import style from "./style.scss"

app.start({
  css: style,
  instanceName: "ags",
  main() {
    app.get_monitors().map(Bar)
  },
})