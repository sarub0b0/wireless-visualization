import CoreWLAN
import Darwin

func phyModeName(mode: CWPHYMode) -> String {
  switch mode {
  case .mode11a:
    return "802.11a"
  case .mode11ac:
    return "802.11ac"
  case .mode11b:
    return "802.11b"
  case .mode11g:
    return "802.11g"
  case .mode11n:
    return "802.11n"
  case .modeNone:
    return "None"
  default:
    return "Unknown"
  }
}

func ifModeName(mode: CWInterfaceMode?) -> String {

  switch mode {
  case .IBSS:
    return "IBSS"
  case .hostAP:
    return "hostAP"
  case .station:
    return "station"
  case .none:
    return "none"
  default:
    return "Unknown"
  }
}


let client = CWWiFiClient.shared()

guard let iface = client.interface() else { abort() }

let phyMode = iface.activePHYMode()
let bssid = iface.bssid() ?? "none"
let ifname = iface.interfaceName ?? "none"
let ifmode = ifModeName(mode: iface.interfaceMode())

let power = iface.transmitPower()
let rate = iface.transmitRate()

fputs("Phy mode: \(phyModeName(mode: phyMode))\n", stderr)
fputs("Interface mode \(ifmode)\n", stderr)
fputs("bssid \(bssid)\n", stderr)

let ssid = iface.ssid() ?? "none"
let rssi = iface.rssiValue()
let noise = iface.noiseMeasurement()

fputs("ssid \(ssid); rssi \(rssi); noise \(noise);\n", stderr)

fputs("Scanning...\n", stderr)

do {
  let scanSet = try iface.scanForNetworks(withName: nil)

  let assoc: [String: Any] = [
    "iface": ifname, "bssid": bssid, "ssid": ssid, "mode": ifmode, "rssi": rssi, "noise": noise,
    "power": power,
    "rate": rate,
  ]

  var scan = [[String: Any]]()

  for net in scanSet {
    let bssid = net.bssid ?? "none"
    let ssid = net.ssid ?? "none"
    let rssi = net.rssiValue
    let channel = net.wlanChannel?.channelNumber ?? -1

    scan.append(["bssid": bssid, "ssid": ssid, "rssi": rssi, "channel": channel])
  }

  let root: [String: Any] = ["assoc": assoc, "scan": scan]

  /* let jsonData = try JSONSerialization.data(withJSONObject: root, options: .prettyPrinted) */
  let jsonData = try JSONSerialization.data(withJSONObject: root)

  let json = String(bytes: jsonData, encoding: .utf8) ?? ""

  print(json)

} catch let error as NSError {
  print("Error: \(error.localizedDescription)")
  abort()
}
