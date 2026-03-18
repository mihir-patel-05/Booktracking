#if os(macOS)
import SwiftUI
import SwiftData

struct MenuBarTimerView: View {
    @Environment(TimerService.self) private var timerService

    var body: some View {
        VStack(spacing: 12) {
            // Header
            Text("PageFlow Timer")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            Divider()

            if timerService.isRunning || timerService.isPaused {
                // Active timer display
                VStack(spacing: 8) {
                    Text(timerService.formattedTime)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)

                    Text(timerService.isRunning ? "Reading..." : "Paused")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)

                    HStack(spacing: 12) {
                        Button {
                            if timerService.isRunning {
                                timerService.pause()
                            } else {
                                timerService.resume()
                            }
                        } label: {
                            Image(systemName: timerService.isRunning ? "pause.fill" : "play.fill")
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent)

                        Button {
                            timerService.stop()
                        } label: {
                            Image(systemName: "stop.fill")
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.bordered)
                        .tint(Theme.error)
                    }
                }
            } else {
                // Quick-start presets
                Text("Quick Start")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)

                HStack(spacing: 8) {
                    ForEach(TimerPreset.allCases, id: \.self) { preset in
                        Button(preset.label) {
                            timerService.selectPreset(preset)
                            timerService.start()
                        }
                        .buttonStyle(.bordered)
                        .tint(Theme.accent)
                    }
                }

                Text("Select a book in the main window first")
                    .font(.caption2)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding()
        .frame(width: 280)
    }
}
#endif
