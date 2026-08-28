import AVFoundation
import MobileWhipWhepClient
import SwiftUI
import WebRTC

private let authToken = "example"
private let broadcasterServerUrl = URL(string: "https://broadcaster.elixir-webrtc.org/api/whep")!

/// `MobileWhipWhepClient` ships its renderer as a `UIViewController`, so SwiftUI needs a wrapper.
struct VideoView: UIViewControllerRepresentable {
    let player: ClientBase

    func makeUIViewController(context: Context) -> VideoViewController {
        let controller = VideoViewController()
        controller.player = player
        return controller
    }

    func updateUIViewController(_ controller: VideoViewController, context: Context) {}
}

enum PlayerType: CaseIterable, Identifiable {
    case whepBroadcaster
    case whep
    case whip

    var id: Self { self }

    var title: String {
        switch self {
        case .whepBroadcaster: return "WHEP (broadcaster)"
        case .whep: return "WHEP"
        case .whip: return "WHIP"
        }
    }

    var connectButtonTitle: String {
        self == .whip ? "Connect WHIP" : "Connect WHEP"
    }
}

enum DemoError: LocalizedError {
    case missingServerUrl(String)
    case noCaptureDevice

    var errorDescription: String? {
        switch self {
        case .missingServerUrl(let key):
            return "\(key) is missing or invalid. Fill in ServerSettings.xcconfig and rebuild."
        case .noCaptureDevice:
            return "No camera available on this device."
        }
    }
}

@MainActor
final class PlayerModel: ObservableObject {
    @Published var selectedPlayerType = PlayerType.whepBroadcaster {
        didSet { select(selectedPlayerType) }
    }

    /// Held strongly here - `VideoViewController.player` is a weak reference.
    @Published private(set) var client: ClientBase?
    @Published private(set) var isConnecting = false
    @Published private(set) var isConnected = false
    @Published private(set) var message: String?

    private var connectOptions: ClientConnectOptions?

    /// Switching players tears the current one down before building the next. Chaining the tasks
    /// keeps two quick taps from interleaving and nulling out the client the final tab needs.
    private var switchTask: Task<Void, Never>?

    /// Tracked so that a player switch cancels a connect that is still in flight - otherwise it
    /// would report back after the teardown and leave `isConnected` set for the next client,
    /// which keeps the Connect button disabled for good.
    private var connectTask: Task<Void, Never>?

    func select(_ playerType: PlayerType) {
        let previousSwitch = switchTask
        switchTask = Task { [weak self] in
            await previousSwitch?.value
            guard let self else { return }
            await self.tearDown()
            await self.makeClient(for: playerType)
        }
    }

    func connect() {
        guard let client, let connectOptions else { return }

        isConnecting = true
        message = nil
        connectTask = Task { [weak self] in
            // Cleared on every path, cancellation included, so the spinner and the disabled
            // Connect button can never outlive the attempt.
            defer { self?.isConnecting = false }
            do {
                try await client.connect(connectOptions)
                guard !Task.isCancelled else { return }
                self?.isConnected = true
            } catch {
                guard !Task.isCancelled else { return }
                self?.message = "Connection failed: \(error.localizedDescription)"
            }
        }
    }

    /// `disconnect()` only closes the session; `cleanup()` is what releases the peer connection and,
    /// for WHIP, stops the camera capture. Dropping the reference without it leaks both.
    func tearDown() async {
        connectTask?.cancel()
        connectTask = nil

        switch client {
        case let whep as WhepClient:
            whep.disconnect()
            // `WhepClient.disconnect()` finishes its teardown on the main queue 0.1s later and
            // only captures `self` weakly, so the client has to stay alive across that hop -
            // otherwise the peer connection is never actually closed.
            try? await Task.sleep(nanoseconds: 150_000_000)
            whep.cleanup()
        case let whip as WhipClient:
            // Best-effort: `disconnect()` throws when the client was never connected, and the
            // resource DELETE it issues is not implemented by every server (the ex_webrtc demo
            // server answers 404). An uncaught throw here would take the whole switch down.
            do {
                try await whip.disconnect()
            } catch {
                print("Error when disconnecting the WHIP client: \(error)")
            }
            whip.cleanup()
        default:
            break
        }

        client = nil
        connectOptions = nil
        isConnected = false
        isConnecting = false
    }

    private func makeClient(for playerType: PlayerType) async {
        do {
            switch playerType {
            case .whepBroadcaster:
                connectOptions = ClientConnectOptions(
                    serverUrl: broadcasterServerUrl, authToken: authToken)
                client = try WhepClient(configOptions: WhepConfigurationOptions(stunServerUrl: nil))
            case .whep:
                connectOptions = ClientConnectOptions(
                    serverUrl: try serverUrl(forInfoPlistKey: "WhepServerUrl"), authToken: authToken)
                client = try WhepClient(configOptions: WhepConfigurationOptions(stunServerUrl: nil))
            case .whip:
                connectOptions = ClientConnectOptions(
                    serverUrl: try serverUrl(forInfoPlistKey: "WhipServerUrl"), authToken: authToken)
                guard let captureDevice = WhipClient.getCaptureDevices().first else {
                    throw DemoError.noCaptureDevice
                }
                // The capture device is no longer a constructor argument - capture is started
                // explicitly so the local preview is live before `connect()`.
                let whipClient = WhipClient(
                    configOptions: WhipConfigurationOptions(
                        videoParameters: .presetHD169, stunServerUrl: nil))
                whipClient.startCapture(captureDevice)
                client = whipClient
            }
            observeConnectionState(of: client)
            message = nil
        } catch {
            client = nil
            connectOptions = nil
            message = error.localizedDescription
        }
    }

    /// The peer-connection state only reaches the app through this callback, so without it a
    /// mid-stream drop would leave `isConnected` - and with it the disabled Connect button -
    /// stuck until the player is switched away and back.
    private func observeConnectionState(of client: ClientBase?) {
        guard let client else { return }
        client.onConnectionStateChanged = { [weak self, weak client] state in
            Task { @MainActor in
                // The callback arrives on a WebRTC thread and can outlive a teardown, so only
                // apply it while this is still the client the model is showing.
                guard let self, let client, self.client === client else { return }
                switch state {
                case .connected:
                    self.isConnected = true
                    self.isConnecting = false
                case .disconnected, .failed, .closed:
                    self.isConnected = false
                    self.isConnecting = false
                default:
                    break
                }
            }
        }
    }

    private func serverUrl(forInfoPlistKey key: String) throws -> URL {
        guard let value = Bundle.main.infoDictionary?[key] as? String, !value.isEmpty,
            let url = URL(string: value)
        else {
            throw DemoError.missingServerUrl(key)
        }
        return url
    }
}

struct ContentView: View {
    @StateObject private var model = PlayerModel()

    var body: some View {
        VStack {
            Picker("Choose Player", selection: $model.selectedPlayerType) {
                ForEach(PlayerType.allCases) { playerType in
                    Text(playerType.title).tag(playerType)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            VStack {
                if let client = model.client {
                    VideoView(player: client)
                        .id(ObjectIdentifier(client))
                        .frame(width: 200, height: 200)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))
                        .padding([.top, .bottom], 50)
                }

                if let message = model.message {
                    Text(message)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button(model.selectedPlayerType.connectButtonTitle) {
                    model.connect()
                }
                .disabled(model.client == nil || model.isConnecting || model.isConnected)

                if model.isConnecting {
                    ProgressView()
                }
            }
        }
        .padding()
        .task {
            model.select(model.selectedPlayerType)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
