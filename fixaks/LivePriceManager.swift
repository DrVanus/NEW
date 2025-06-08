import Foundation
import Combine

/// Simple wrapper around Binance’s trade-stream WS endpoint
final class LivePriceManager {
    /// Shared singleton instance
    static let shared = LivePriceManager()
    /// The current WebSocket URL for reconnect
    private var wsURL: URL?
    private var socket: URLSessionWebSocketTask?
    private let priceSubject = PassthroughSubject<Double, Never>()

    /// Emits each incoming trade price as a `Double`
    var pricePublisher: AnyPublisher<Double, Never> {
        priceSubject.eraseToAnyPublisher()
    }

    /// Are we currently connected?
    private(set) var isConnected = false

    /// Open (or reopen) the WS for a given symbol (e.g. "btcusdt")
    func connect(symbol: String) {
        disconnect()
        guard let wsURL = URL(string: "wss://stream.binance.com:9443/ws/\(symbol.lowercased())@trade") else { return }
        self.wsURL = wsURL
        socket = URLSession.shared.webSocketTask(with: wsURL)
        socket?.resume()
        isConnected = true
        listen()
    }

    /// Close down the socket
    func disconnect() {
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
        isConnected = false
    }

    /// Recursively listen for incoming messages
    private func listen() {
        socket?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure:
                self.isConnected = false
                // try reconnect
                DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                    if let wsURL = self.wsURL {
                        self.socket = URLSession.shared.webSocketTask(with: wsURL)
                        self.socket?.resume()
                        self.isConnected = true
                        self.listen()
                    }
                }

            case .success(let msg):
                if case .string(let text) = msg,
                   let data = text.data(using: .utf8),
                   let trade = try? JSONDecoder().decode(BinanceTrade.self, from: data),
                   let price = Double(trade.p)
                {
                    self.priceSubject.send(price)
                }
                // keep listening
                self.listen()
            }
        }
    }
}

// Keep your BinanceTrade model right here:
private struct BinanceTrade: Codable {
    let p: String
    let T: TimeInterval

    enum CodingKeys: String, CodingKey {
        case p, T
    }
}
