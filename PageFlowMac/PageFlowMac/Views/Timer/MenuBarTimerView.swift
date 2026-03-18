import SwiftUI

struct MenuBarTimerView: View {
    @Environment(TimerService.self) private var timerService
    @Environment(NotificationService.self) private var notificationService

    var body: some View {
        VStack(spacing: 12) {
            if timerService.isRunning || timerService.isPaused {
                activeTimerSection
            } else {
                quickStartSection
            }
        }
        .padding()
        .frame(width: 260)
    }

    // MARK: - Active Timer

    private var activeTimerSection: some View {
        VStack(spacing: 12) {
            Text(timerService.formattedTime)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)

            ProgressBar(
                progress: timerService.progress,
                height: 6,
                foregroundColor: Theme.accent
            )

            Text(timerService.isRunning ? "Running" : "Paused")
                .font(.caption)
                .foregroundStyle(timerService.isRunning ? Theme.success : Theme.streak)

            HStack(spacing: 16) {
                Button {
                    if timerService.isRunning {
                        timerService.pause()
                        notificationService.cancelTimerNotification()
                    } else {
                        timerService.resume()
                        if let endDate = timerService.targetEndDate {
                            notificationService.scheduleTimerCompletion(at: endDate)
                        }
                    }
                } label: {
                    Image(systemName: timerService.isRunning ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Theme.accent)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    timerService.stop()
                    notificationService.cancelTimerNotification()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Theme.error)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Quick Start

    private var quickStartSection: some View {
        VStack(spacing: 12) {
            Text("Quick Timer")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            Text("Select a book in the main window first, then start a timer here.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                ForEach(TimerPreset.allCases, id: \.self) { preset in
                    Button {
                        timerService.selectPreset(preset)
                    } label: {
                        Text(preset.label)
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(timerService.selectedPreset == preset ? Theme.accent : Theme.cardBackground)
                            .foregroundStyle(timerService.selectedPreset == preset ? .white : Theme.textSecondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            if timerService.totalSeconds > 0 {
                Text("\(timerService.totalSeconds / 60) min selected")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }
        }
    }
}
