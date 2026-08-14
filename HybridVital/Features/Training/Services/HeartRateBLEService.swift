import CoreBluetooth
import Foundation

nonisolated struct DiscoveredHeartRateMonitor: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let rssi: Int
}

nonisolated enum HeartRateMonitorStatus: Equatable, Sendable {
    case idle
    case unauthorized
    case poweredOff
    case scanning
    case connecting(String)
    case connected(String)
    case unavailable

    var text: String {
        switch self {
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

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

nonisolated struct HeartRateSnapshot: Equatable, Sendable {
    var bpm: Double?
    var status: HeartRateMonitorStatus
    var discovered: [DiscoveredHeartRateMonitor]
    var lastError: String?
}

/// Owns the COROS/BLE connection. Callbacks stay on a private queue.
/// The UI must not observe this type — pull `snapshot()` on the session clock.
final class HeartRateBLEService: NSObject, @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.hybridvital.ble.hr")
    private let lock = NSRecursiveLock()

    private var central: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var latestBPM: Double?
    private var status: HeartRateMonitorStatus = .idle
    private var discovered: [DiscoveredHeartRateMonitor] = []
    private var lastError: String?

    private let heartRateService = CBUUID(string: "180D")
    private let lastDeviceKey = "lastHeartRateMonitorUUID"

    func snapshot() -> HeartRateSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return HeartRateSnapshot(
            bpm: latestBPM,
            status: status,
            discovered: discovered,
            lastError: lastError
        )
    }

    func startScanning() {
        queue.async { [weak self] in
            self?.startScanningOnQueue()
        }
    }

    func connect(id: UUID) {
        queue.async { [weak self] in
            guard let self, let peripheral = self.peripherals[id] else { return }
            self.connectOnQueue(peripheral)
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            self.central?.stopScan()
            if let connectedPeripheral = self.connectedPeripheral {
                self.central?.cancelPeripheralConnection(connectedPeripheral)
            }
            self.connectedPeripheral = nil
            self.write {
                $0.latestBPM = nil
                if $0.status != .unauthorized && $0.status != .poweredOff && $0.status != .unavailable {
                    $0.status = .idle
                }
            }
        }
    }

    private func startScanningOnQueue() {
        write { $0.lastError = nil }
        if snapshot().status.isConnected { return }
        if central == nil {
            central = CBCentralManager(
                delegate: self,
                queue: queue,
                options: [CBCentralManagerOptionShowPowerAlertKey: true]
            )
        } else if let central {
            handle(centralState: central.state)
        }
    }

    private func handle(centralState: CBManagerState) {
        switch centralState {
        case .unauthorized:
            write { $0.status = .unauthorized }
        case .poweredOff:
            write { $0.status = .poweredOff }
        case .unsupported:
            write { $0.status = .unavailable }
        case .poweredOn:
            if !snapshot().status.isConnected {
                beginScanOnQueue()
            }
        default:
            write { $0.status = .idle }
        }
    }

    private func beginScanOnQueue() {
        write {
            $0.status = .scanning
            $0.discovered = []
            $0.latestBPM = nil
        }
        central?.scanForPeripherals(
            withServices: [heartRateService],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        if let raw = UserDefaults.standard.string(forKey: lastDeviceKey),
           let uuid = UUID(uuidString: raw),
           let known = central?.retrievePeripherals(withIdentifiers: [uuid]).first {
            peripherals[known.identifier] = known
            connectOnQueue(known)
        }
    }

    private func connectOnQueue(_ peripheral: CBPeripheral) {
        central?.stopScan()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        write { $0.status = .connecting(self.displayName(for: peripheral)) }
        central?.connect(peripheral, options: nil)
    }

    private func displayName(for peripheral: CBPeripheral) -> String {
        let name = peripheral.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Heart rate band" : name
    }

    private func write(_ update: (HeartRateBLEService) -> Void) {
        lock.lock()
        update(self)
        lock.unlock()
    }
}

extension HeartRateBLEService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        handle(centralState: central.state)
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        if snapshot().status.isConnected { return }
        peripherals[peripheral.identifier] = peripheral

        let advertised = (advertisementData[CBAdvertisementDataLocalNameKey] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = advertised.isEmpty ? displayName(for: peripheral) : advertised
        let monitor = DiscoveredHeartRateMonitor(id: peripheral.identifier, name: name, rssi: RSSI.intValue)

        write { service in
            if let index = service.discovered.firstIndex(where: { $0.id == monitor.id }) {
                service.discovered[index] = monitor
            } else {
                service.discovered.append(monitor)
                service.discovered.sort { $0.rssi > $1.rssi }
            }
        }

        if connectedPeripheral == nil, snapshot().discovered.count == 1 {
            connectOnQueue(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([CBUUID(string: "180D")])
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: lastDeviceKey)
        let name = displayName(for: peripheral)
        write { $0.status = .connected(name) }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        write {
            $0.lastError = error?.localizedDescription ?? "Could not connect to the band."
        }
        connectedPeripheral = nil
        beginScanOnQueue()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        write { $0.latestBPM = nil }
        if connectedPeripheral?.identifier == peripheral.identifier {
            connectedPeripheral = nil
            beginScanOnQueue()
        }
    }
}

extension HeartRateBLEService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral.services?.filter { $0.uuid == CBUUID(string: "180D") }.forEach { service in
            peripheral.discoverCharacteristics([CBUUID(string: "2A37")], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        service.characteristics?.filter { $0.uuid == CBUUID(string: "2A37") }.forEach { characteristic in
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == CBUUID(string: "2A37"),
              let bpm = Self.parseHeartRate(characteristic.value) else { return }
        lock.lock()
        latestBPM = bpm
        if case .connecting(let name) = status {
            status = .connected(name)
        }
        lock.unlock()
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
