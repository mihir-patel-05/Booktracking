import Foundation

// MARK: - Timer State

enum TimerState: Equatable {
    case idle
    case running(targetEndDate: Date)
    case paused(remainingSeconds: Int)
    case completed
}

// MARK: - Timer Service

@Observable
final class TimerService {

    // MARK: Public State

    private(set) var state: TimerState = .idle
    var totalSeconds: Int = 25 * 60
    private(set) var remainingSeconds: Int = 25 * 60
    var selectedPreset: TimerPreset? = .twentyFive

    // MARK: Private

    private var displayTimer: Foundation.Timer?

    // MARK: Computed

    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    var isPaused: Bool {
        if case .paused = state { return true }
        return false
    }

    var isCompleted: Bool {
        state == .completed
    }

    var isIdle: Bool {
        state == .idle
    }

    var targetEndDate: Date? {
        if case .running(let date) = state { return date }
        return nil
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var elapsedSeconds: Int {
        totalSeconds - remainingSeconds
    }

    var formattedTime: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    var formattedElapsedTime: String {
        let elapsed = elapsedSeconds
        let mins = elapsed / 60
        let secs = elapsed % 60
        if mins > 0 {
            return "\(mins) min \(secs) sec"
        }
        return "\(secs) sec"
    }

    // MARK: Configuration

    func selectPreset(_ preset: TimerPreset) {
        selectedPreset = preset
        totalSeconds = preset.rawValue * 60
    }

    func setCustomMinutes(_ input: String) {
        guard let mins = Int(input), mins > 0, mins <= 180 else { return }
        totalSeconds = mins * 60
        selectedPreset = nil
    }

    // MARK: Timer Controls

    func start() {
        remainingSeconds = totalSeconds
        let endDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
        state = .running(targetEndDate: endDate)
        startDisplayTimer()
    }

    func pause() {
        guard case .running(let endDate) = state else { return }
        stopDisplayTimer()
        let remaining = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
        remainingSeconds = remaining
        state = .paused(remainingSeconds: remaining)
    }

    func resume() {
        guard case .paused(let remaining) = state else { return }
        remainingSeconds = remaining
        let endDate = Date().addingTimeInterval(TimeInterval(remaining))
        state = .running(targetEndDate: endDate)
        startDisplayTimer()
    }

    func stop() {
        stopDisplayTimer()
        if case .running(let endDate) = state {
            remainingSeconds = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
        }
        state = .completed
    }

    func reset() {
        stopDisplayTimer()
        state = .idle
        totalSeconds = 25 * 60
        remainingSeconds = 25 * 60
        selectedPreset = .twentyFive
    }

    // MARK: Background / Foreground

    func handleBackground() {
        stopDisplayTimer()
    }

    func handleForeground() {
        guard case .running(let endDate) = state else { return }
        let remaining = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
        remainingSeconds = remaining
        if remaining <= 0 {
            state = .completed
        } else {
            startDisplayTimer()
        }
    }

    // MARK: Private

    private func startDisplayTimer() {
        stopDisplayTimer()
        displayTimer = Foundation.Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            guard case .running(let endDate) = self.state else {
                self.stopDisplayTimer()
                return
            }
            let remaining = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
            self.remainingSeconds = remaining
            if remaining <= 0 {
                self.stopDisplayTimer()
                self.state = .completed
            }
        }
    }

    private func stopDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }
}
