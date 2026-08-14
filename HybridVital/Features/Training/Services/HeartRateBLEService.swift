import CoreBluetooth
import Foundation

struct DiscoveredHeartRateMonitor: Identifiable, Hashable {
    let id: UUID
    let name: String
    let rssi: Int
}

enum HeartRateMonitorStatus: Equatable {
    case idle
    case unauthorized
    case poweredOff
    case scanning
    case connecting(String)
    case connected(String)
    case unavailable
}

@Observable
@MainActor
final class HeartRateBLEService: NSObject {
    var status: HeartRateMonitorStatus = .idle
    var currentBPM: Double?
    var discovered: [DiscoveredHeartRateMonitor] = []
    var lastError: String?

    private var central: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var lastNotifyAt: Date?

    private let heartRateService = CBUUID(string: "180D")
    private let heartRateMeasurement = CBUUID(string: "2A37")
    private let lastDeviceKey = "lastHeartRateMonitorUUID"

    var isConnected: Bool {
        if case .connected = status { return true }
        return false
    }

    var statusText: String {
        switch status {
        case .idle:
            "Bluetooth is starting…"
        case .unauthorized:
            "Bluetooth access is off. Enable it in Settings → HybridVital."
        case .poweredOff:
            "Turn on Bluetooth to find your COROS band."
        case .scanning:
            "Searching for a heart rate band… Wear it so it wakes up."
        case .connecting(let name):
            "Connecting to \(name)…"
        case .connected(let name):
            "Connected to \(name)"
        case .unavailable:
            "Bluetooth is not available on this device."
        }
    }

    func startScanning() {
        lastError = nil
        if central == nil {
            central = CBCentralManager(
                delegate: self,
                queue: .main,
                options: [CBCentralManagerOptionShowPowerAlertKey: true]
            )
        } else {
            handle(centralState: central?.state ?? .unknown)
        }
    }

    func connect(id: UUID) {
        guard let peripheral = peripherals[id] else { return }
        connect(peripheral)
    }

    func stop() {
        central?.stopScan()
        if let connectedPeripheral {
            central?.cancelPeripheralConnection(connectedPeripheral)
        }
        connectedPeripheral = nil
        currentBPM = nil
        if status != .unauthorized && status != .poweredOff && status != .unavailable {
            status = .idle
        }
    }

    private func handle(centralState: CBManagerState) {
        switch centralState {
        case .unauthorized:
            status = .unauthorized
        case .poweredOff:
            status = .poweredOff
        case .unsupported:
            status = .unavailable
        case .poweredOn:
            beginScan()
        default:
            status = .idle
        }
    }

    private func beginScan() {
        status = .scanning
        discovered = []
        currentBPM = nil
        central?.scanForPeripherals(
            withServices: [heartRateService],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        if let raw = UserDefaults.standard.string(forKey: lastDeviceKey),
           let uuid = UUID(uuidString: raw),
           let known = central?.retrievePeripherals(withIdentifiers: [uuid]).first {
            peripherals[known.identifier] = known
            connect(known)
        }
    }

    private func connect(_ peripheral: CBPeripheral) {
        central?.stopScan()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        status = .connecting(displayName(for: peripheral))
        central?.connect(peripheral, options: nil)
    }

    private func displayName(for peripheral: CBPeripheral) -> String {
        let name = peripheral.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Heart rate band" : name
    }

    fileprivate func didDiscover(peripheral: CBPeripheral, advertisementName: String?, rssi: Int) {
        peripherals[peripheral.identifier] = peripheral
        let name = {
            let advertised = advertisementName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !advertised.isEmpty { return advertised }
            return displayName(for: peripheral)
        }()

        let monitor = DiscoveredHeartRateMonitor(id: peripheral.identifier, name: name, rssi: rssi)
        if let index = discovered.firstIndex(where: { $0.id == monitor.id }) {
            discovered[index] = monitor
        } else {
            discovered.append(monitor)
            discovered.sort { $0.rssi > $1.rssi }
        }

        if connectedPeripheral == nil, discovered.count == 1 {
            connect(peripheral)
        }
    }

    fileprivate func applyHeartRate(_ bpm: Double) {
        currentBPM = bpm
        lastNotifyAt = .now
        if let connectedPeripheral, case .connecting = status {
            status = .connected(displayName(for: connectedPeripheral))
        }
    }
}

extension HeartRateBLEService: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        Task { @MainActor in
            self.handle(centralState: state)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let advertised = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let rssi = RSSI.intValue
        Task { @MainActor in
            self.didDiscover(peripheral: peripheral, advertisementName: advertised, rssi: rssi)
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([CBUUID(string: "180D")])
        let name = peripheral.name
        Task { @MainActor in
            UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: self.lastDeviceKey)
            self.status = .connected(name?.isEmpty == false ? name! : "Heart rate band")
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let message = error?.localizedDescription ?? "Could not connect to the band."
        Task { @MainActor in
            self.lastError = message
            self.connectedPeripheral = nil
            self.beginScan()
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.currentBPM = nil
            if self.connectedPeripheral?.identifier == peripheral.identifier {
                self.connectedPeripheral = nil
                self.beginScan()
            }
        }
    }
}

extension HeartRateBLEService: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral.services?.filter { $0.uuid == CBUUID(string: "180D") }.forEach { service in
            peripheral.discoverCharacteristics([CBUUID(string: "2A37")], for: service)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        service.characteristics?.filter { $0.uuid == CBUUID(string: "2A37") }.forEach { characteristic in
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == CBUUID(string: "2A37"),
              let bpm = Self.parseHeartRate(characteristic.value) else { return }
        Task { @MainActor in
            self.applyHeartRate(bpm)
        }
    }

    nonisolated static func parseHeartRate(_ data: Data?) -> Double? {
        guard let data, data.count >= 2 else { return nil }
        let bytes = [UInt8](data)
        let flags = bytes[0]
        if flags & 0x01 != 0 {
            guard bytes.count >= 3 else { return nil }
            let value = UInt16(bytes[1]) | (UInt16(bytes[2]) << 8)
            return Double(value)
        }
        return Double(bytes[1])
    }
}
