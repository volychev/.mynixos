import app from "ags/gtk4/app"

import Bar from "./widget/bar"
import style from "./style.scss"
import { parseInteractiveCenterRequest, requestInteractiveCenter } from "./widget/bar/components/interactiveCenterControl"

app.start({
  css: style,
  instanceName: "ags",
  requestHandler(argv, respond) {
    const request = parseInteractiveCenterRequest(argv)

    if (!request) {
      respond("unknown request")
      return
    }

    requestInteractiveCenter(request)
    respond("ok")
  },
  main() {
    app.get_monitors().map(Bar)
  },
})
