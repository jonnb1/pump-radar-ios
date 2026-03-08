// PumpRadarApp.swift
//
// An enhanced SwiftUI application for detecting potential crypto pumps.
//
// This version improves upon the basic MVP by adding configurable
// thresholds, dynamic baseline comparisons for price/volume/social metrics,
// a detailed coin view, and local notifications when a high probability pump
// is detected. API integration and machine-learning logic are still
// placeholders and should be replaced with real implementations.

import SwiftUI
import Combine
import UserNotifications

// MARK: - Data Models

/// Represents a cryptocurrency asset tracked by the pump detector.
/// Represents a cryptocurrency asset tracked by the pump detector.
struct Coin: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    var price: Double
    var volume: Double
    var socialMentions: Int
    var score: Int = 0
    /// Indicates whether the coin is part of the user's watchlist.
    var isFavorite: Bool = false

    /// Returns a formatted price string with up to 6 decimal places.
    var formattedPrice: String {
        String(format: "$%.6f", price)
    }
}

// MARK: - ViewModel

final class PumpDetectorViewModel: ObservableObject {
    // Published properties for the UI
    @Published var coins: [Coin] = []
    @Published var volumeThreshold: Double = 2.0
    @Published var priceThreshold: Double = 2.0
    @Published var socialThreshold: Double = 2.0
    /// Set of symbols representing the user's favorite coins. These values
    /// persist across app launches using UserDefaults.
    @Published var favoriteSymbols: Set<String> = []

    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: Cancellable?

    init() {
        // Request permission for local notifications at initialization time
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }

        // Load saved favorites from UserDefaults. We store an array of strings
        // because Set cannot be stored directly in UserDefaults. If the key
        // doesn't exist, we default to an empty array.
        if let saved = UserDefaults.standard.array(forKey: "favoriteSymbols") as? [String] {
            favoriteSymbols = Set(saved)
        }
    }

    /// Starts periodic monitoring of market and social data. Adjust the interval
    /// to control how frequently the app polls for updates.
    func startMonitoring() {
        // Cancel any existing timer before starting a new one
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchDataAndDetectPumps()
            }
    }

    /// Fetches market and social data, updates the coin list, and computes scores.
    private func fetchDataAndDetectPumps() {
        // Placeholder: replace with real API calls to populate the `coins` array.
        // For demonstration, we simulate three sample coins with randomised metrics.
        let sampleCoins = [
            Coin(symbol: "PEPE", name: "Pepe", price: Double.random(in: 0.000001...0.000003), volume: Double.random(in: 800_000...1_500_000), socialMentions: Int.random(in: 150...300)),
            Coin(symbol: "DOGEAI", name: "Doge AI", price: Double.random(in: 0.0010...0.0015), volume: Double.random(in: 400_000...700_000), socialMentions: Int.random(in: 100...200)),
            Coin(symbol: "ABC", name: "Example Coin", price: Double.random(in: 0.03...0.06), volume: Double.random(in: 80_000...150_000), socialMentions: Int.random(in: 10...50))
        ]

        // Compute scores using dynamic baselines. Baselines would normally be
        // calculated from historical data; here we use illustrative constants.
        let volumeBaselines: [String: Double] = ["PEPE": 500_000, "DOGEAI": 300_000, "ABC": 60_000]
        let priceBaselines: [String: Double] = ["PEPE": 0.000002, "DOGEAI": 0.0011, "ABC": 0.04]
        let socialBaselines: [String: Int] = ["PEPE": 100, "DOGEAI": 80, "ABC": 10]

        var scoredCoins: [Coin] = []

        for var coin in sampleCoins {
            // Reset score for this update cycle
            coin.score = 0
            // Compute volume ratio; add a point if above the threshold
            if let baselineVolume = volumeBaselines[coin.symbol], coin.volume / baselineVolume > volumeThreshold {
                coin.score += 1
            }
            // Compute price ratio; add a point if above the threshold
            if let baselinePrice = priceBaselines[coin.symbol], coin.price / baselinePrice > priceThreshold {
                coin.score += 1
            }
            // Compute social ratio; add a point if above the threshold
            if let baselineSocial = socialBaselines[coin.symbol], Double(coin.socialMentions) / Double(baselineSocial) > socialThreshold {
                coin.score += 1
            }
            // Example extra point for low market cap (not implemented; placeholder)
            if coin.symbol == "PEPE" || coin.symbol == "ABC" {
                coin.score += 1
            }
            // Trigger a local notification if the score exceeds a chosen threshold
            if coin.score >= 3 {
                scheduleLocalNotification(for: coin)
            }
            // Mark as favorite if user has saved it in their watchlist
            coin.isFavorite = favoriteSymbols.contains(coin.symbol)
            scoredCoins.append(coin)
        }

        // Update the published coins list on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.coins = scoredCoins.sorted(by: { (lhs, rhs) -> Bool in
                // Sort favorites to the top, then by score, then by symbol
                if lhs.isFavorite != rhs.isFavorite {
                    return lhs.isFavorite && !rhs.isFavorite
                }
                return lhs.score > rhs.score
            })
        }
    }

    /// Toggles the favorite state of a given coin. If the coin's symbol is
    /// already in the favorites set, it will be removed; otherwise, it will
    /// be added. Changes are persisted to UserDefaults.
    func toggleFavorite(for coin: Coin) {
        if favoriteSymbols.contains(coin.symbol) {
            favoriteSymbols.remove(coin.symbol)
        } else {
            favoriteSymbols.insert(coin.symbol)
        }
        // Persist the updated favorites to UserDefaults
        UserDefaults.standard.set(Array(favoriteSymbols), forKey: "favoriteSymbols")
        // Re-mark coins with new favorites state
        self.coins.indices.forEach { index in
            let symbol = coins[index].symbol
            coins[index].isFavorite = favoriteSymbols.contains(symbol)
        }
    }

    /// Schedules a local notification when a high probability pump is detected.
    private func scheduleLocalNotification(for coin: Coin) {
        let content = UNMutableNotificationContent()
        content.title = "Pump Alert: \(coin.symbol)"
        content.body = "Score: \(coin.score) – Price: \(coin.formattedPrice)"
        content.sound = .default
        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}

// MARK: - Views

/// Shows a detailed view for a selected coin, including score breakdown.
struct CoinDetailView: View {
    let coin: Coin

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(coin.name) (\(coin.symbol))")
                .font(.largeTitle)
            HStack {
                Text("Price: \(coin.formattedPrice)")
                Spacer()
                Text("Volume: \(Int(coin.volume))")
            }
            .font(.headline)
            Text("Social mentions: \(coin.socialMentions)")
                .font(.subheadline)
            Text("Pump score: \(coin.score)")
                .font(.title)
                .bold()
            Spacer()
        }
        .padding()
        .navigationTitle(coin.symbol)
    }
}

/// The main view displaying a list of ranked coins and navigation to detail pages.
struct ContentView: View {
    @StateObject private var viewModel = PumpDetectorViewModel()

    var body: some View {
        NavigationView {
            List {
                // Section for user's watchlist
                let watchlistCoins = viewModel.coins.filter { $0.isFavorite }
                let otherCoins = viewModel.coins.filter { !$0.isFavorite }
                if !watchlistCoins.isEmpty {
                    Section(header: Text("Watchlist")) {
                        ForEach(watchlistCoins) { coin in
                            coinRow(for: coin)
                        }
                    }
                }
                Section(header: Text("All Coins")) {
                    ForEach(otherCoins) { coin in
                        coinRow(for: coin)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Pump Radar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView(viewModel: viewModel)) {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
        }
        .onAppear {
            viewModel.startMonitoring()
        }
    }

    /// Builds a row view for a given coin, including a navigation link and
    /// a star button to add/remove from the watchlist.
    @ViewBuilder
    private func coinRow(for coin: Coin) -> some View {
        NavigationLink(destination: CoinDetailView(coin: coin)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(coin.name) (\(coin.symbol))")
                        .font(.headline)
                    HStack {
                        Text(coin.formattedPrice)
                        Spacer()
                        Text("Score: \(coin.score)")
                            .bold()
                    }
                    .font(.subheadline)
                }
                Spacer()
                Button(action: {
                    viewModel.toggleFavorite(for: coin)
                }) {
                    Image(systemName: coin.isFavorite ? "star.fill" : "star")
                        .foregroundColor(coin.isFavorite ? .yellow : .gray)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Settings View

/// A view allowing the user to adjust detection thresholds. Changes update the
/// shared view model in real time.
struct SettingsView: View {
    @ObservedObject var viewModel: PumpDetectorViewModel

    var body: some View {
        Form {
            Section(header: Text("Volume Threshold")) {
                Slider(value: $viewModel.volumeThreshold, in: 1...10, step: 0.5) {
                    Text("Volume Threshold")
                }
                Text("Current: \(viewModel.volumeThreshold, specifier: "%.1f")x baseline")
            }
            Section(header: Text("Price Threshold")) {
                Slider(value: $viewModel.priceThreshold, in: 1...10, step: 0.5) {
                    Text("Price Threshold")
                }
                Text("Current: \(viewModel.priceThreshold, specifier: "%.1f")x baseline")
            }
            Section(header: Text("Social Threshold")) {
                Slider(value: $viewModel.socialThreshold, in: 1...10, step: 0.5) {
                    Text("Social Threshold")
                }
                Text("Current: \(viewModel.socialThreshold, specifier: "%.1f")x baseline")
            }
            Section(footer: Text("Adjust these values to tune the sensitivity of the pump detector. Higher values make the algorithm more selective.")) {
                EmptyView()
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - App Entry Point

@main
struct PumpRadarApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
