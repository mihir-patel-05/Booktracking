import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var book: Book

    @State private var pageInput = ""
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    coverSection
                    infoSection
                    progressSection
                    statusSection
                    deleteSection
                }
                .padding()
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Delete Book?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(book)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(book.title)\" and all associated sessions, notes, and quotes.")
        }
        .onAppear {
            pageInput = String(book.currentPage)
        }
    }

    private var coverSection: some View {
        HStack {
            Spacer()
            Group {
                if let urlString = book.coverURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fit)
                        default:
                            coverPlaceholder
                        }
                    }
                } else {
                    coverPlaceholder
                }
            }
            .frame(width: 120, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: Theme.accent.opacity(0.3), radius: 10)
            Spacer()
        }
    }

    private var coverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Theme.cardBackgroundLight)
            .overlay(
                Image(systemName: "book.closed.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Theme.textMuted)
            )
    }

    private var infoSection: some View {
        VStack(spacing: 8) {
            Text(book.title)
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text(book.author)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            Text("\(book.totalPages) pages")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            ProgressBar(progress: book.progressPercentage, height: 8)

            Text("\(Int(book.progressPercentage * 100))% complete")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 12) {
                TextField("Page", text: $pageInput)
                    .keyboardType(.numberPad)
                    .padding(10)
                    .background(Theme.cardBackground)
                    .foregroundStyle(Theme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(width: 100)

                Text("of \(book.totalPages)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)

                Spacer()

                Button("Update") {
                    updateProgress()
                }
                .font(.subheadline.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.accent)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            Picker("Status", selection: Binding(
                get: { book.status },
                set: { newStatus in
                    book.status = newStatus
                    book.needsSync = true
                    if newStatus == .completed && book.dateCompleted == nil {
                        book.dateCompleted = Date()
                    }
                    if newStatus != .completed {
                        book.dateCompleted = nil
                    }
                }
            )) {
                ForEach(BookStatus.allCases, id: \.self) { status in
                    Label(status.rawValue, systemImage: status.icon)
                        .tag(status)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var deleteSection: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Book")
            }
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.error.opacity(0.15))
            .foregroundStyle(Theme.error)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func updateProgress() {
        guard let newPage = Int(pageInput) else { return }
        let clamped = min(max(0, newPage), book.totalPages)
        book.currentPage = clamped
        book.needsSync = true
        pageInput = String(clamped)

        if clamped == book.totalPages && book.status != .completed {
            book.status = .completed
            book.dateCompleted = Date()
        }
    }
}
