export type InteractiveCenterMode = "search" | "clipboard" | "notifications"
export type PowerModeName = "ultra-eco" | "eco" | "balanced" | "performance"

export type InteractiveCenterRequest = {
  mode: InteractiveCenterMode
  focusInput: boolean
}

type InteractiveCenterListener = (request: InteractiveCenterRequest) => void
type PowerModeListener = (mode: PowerModeName) => void

const listeners = new Set<InteractiveCenterListener>()
const powerModeListeners = new Set<PowerModeListener>()

const requestMap: Record<string, InteractiveCenterRequest> = {
  search: { mode: "search", focusInput: true },
  apps: { mode: "search", focusInput: true },
  clipboard: { mode: "clipboard", focusInput: true },
  clip: { mode: "clipboard", focusInput: true },
  notifications: { mode: "notifications", focusInput: false },
  notification: { mode: "notifications", focusInput: false },
}

const powerModeMap: Record<string, PowerModeName> = {
  "ultra-eco": "ultra-eco",
  ultra_eco: "ultra-eco",
  ultraeco: "ultra-eco",
  ultra: "ultra-eco",
  eco: "eco",
  balanced: "balanced",
  balance: "balanced",
  performance: "performance",
  perf: "performance",
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

export function parsePowerModeRequest(argv: string[]): PowerModeName | null {
  const tokens = argv.map((token) => token.toLowerCase())
  const commandIndex = tokens.findIndex(
    (token) => token === "power-mode" || token === "powermode" || token === "pm",
  )

  if (commandIndex === -1) {
    return null
  }

  const modeToken = tokens[commandIndex + 1]
  if (!modeToken) {
    return null
  }

  return powerModeMap[modeToken] ?? null
}

export function requestInteractiveCenter(request: InteractiveCenterRequest) {
  listeners.forEach((listener) => listener(request))
}

export function requestPowerMode(mode: PowerModeName) {
  powerModeListeners.forEach((listener) => listener(mode))
}

export function subscribeInteractiveCenterRequests(listener: InteractiveCenterListener) {
  listeners.add(listener)
  return () => {
    listeners.delete(listener)
  }
}

export function subscribePowerModeRequests(listener: PowerModeListener) {
  powerModeListeners.add(listener)
  return () => {
    powerModeListeners.delete(listener)
  }
}
