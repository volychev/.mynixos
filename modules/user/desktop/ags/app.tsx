import app from "ags/gtk4/app"

import Bar from "./widget/bar"
import style from "./style.scss"
import {
  parseInteractiveCenterRequest,
  parsePowerModeRequest,
  requestInteractiveCenter,
  requestPowerMode,
} from "./widget/bar/components/interactiveCenterControl"

app.start({
  css: style,
  instanceName: "ags",
  requestHandler(argv, respond) {
    const powerModeRequest = parsePowerModeRequest(argv)
    if (powerModeRequest) {
      requestPowerMode(powerModeRequest)
      respond("ok")
      return
    }

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
