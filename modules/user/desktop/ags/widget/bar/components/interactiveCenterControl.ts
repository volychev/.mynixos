export type InteractiveCenterMode = "search" | "clipboard" | "notifications"

export type InteractiveCenterRequest = {
  mode: InteractiveCenterMode
  focusInput: boolean
}

type InteractiveCenterListener = (request: InteractiveCenterRequest) => void

const listeners = new Set<InteractiveCenterListener>()

const requestMap: Record<string, InteractiveCenterRequest> = {
  search: { mode: "search", focusInput: true },
  apps: { mode: "search", focusInput: true },
  clipboard: { mode: "clipboard", focusInput: true },
  clip: { mode: "clipboard", focusInput: true },
  notifications: { mode: "notifications", focusInput: false },
  notification: { mode: "notifications", focusInput: false },
}

export function parseInteractiveCenterRequest(argv: string[]): InteractiveCenterRequest | null {
  const tokens = argv.map((token) => token.toLowerCase())
  const commandIndex = tokens.findIndex((token) => token === "interactive-center" || token === "ic")

  if (commandIndex === -1) {
    return null
  }

  const modeToken = tokens[commandIndex + 1]
  if (!modeToken) {
    return null
  }

  const request = requestMap[modeToken]
  return request ? { ...request } : null
}

export function requestInteractiveCenter(request: InteractiveCenterRequest) {
  listeners.forEach((listener) => listener(request))
}

export function subscribeInteractiveCenterRequests(listener: InteractiveCenterListener) {
  listeners.add(listener)
  return () => {
    listeners.delete(listener)
  }
}
