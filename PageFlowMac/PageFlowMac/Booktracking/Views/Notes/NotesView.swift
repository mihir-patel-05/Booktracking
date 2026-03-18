import SwiftUI
import SwiftData

struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SessionNote.dateCreated, order: .reverse) private var notes: [SessionNote]
    @State private var showAddNote = false
    @State private var searchText = ""
    @State private var selectedBookFilter: Book?

    private var uniqueBooks: [Book] {
        var seen = Set<UUID>()
        return notes.compactMap { $0.book }.filter { seen.insert($0.id).inserted }
    }

    private var filteredNotes: [SessionNote] {
        var result = notes

        if let book = selectedBookFilter {
            result = result.filter { $0.book?.id == book.id }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                ($0.book?.title.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return result
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if notes.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Book filter pills
                    if !uniqueBooks.isEmpty {
                        bookFilterPills
                    }

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredNotes) { note in
                                NavigationLink(value: note) {
                                    noteCard(note)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        modelContext.delete(note)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Notes")
        .searchable(text: $searchText, prompt: "Search notes...")
        .navigationDestination(for: SessionNote.self) { note in
            NoteDetailView(note: note)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddNote = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .sheet(isPresented: $showAddNote) {
            AddNoteView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .addNewNote)) { _ in
            showAddNote = true
        }
    }

    // MARK: - Book Filter Pills

    private var bookFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    selectedBookFilter = nil
                } label: {
                    Text("All")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedBookFilter == nil ? Theme.accent : Theme.cardBackground)
                        .foregroundStyle(selectedBookFilter == nil ? .white : Theme.textSecondary)
                        .clipShape(Capsule())
                }

                ForEach(uniqueBooks) { book in
                    Button {
                        selectedBookFilter = book
                    } label: {
                        Text(book.title)
                            .font(.caption.bold())
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedBookFilter?.id == book.id ? Theme.accent : Theme.cardBackground)
                            .foregroundStyle(selectedBookFilter?.id == book.id ? .white : Theme.textSecondary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Note Card

    private func noteCard(_ note: SessionNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title)
                .font(.subheadline.bold())
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)

            Text(note.content)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)

            HStack {
                if let book = note.book {
                    Text(book.title)
                        .font(.caption2.bold())
                        .foregroundStyle(Theme.accentLight)
                        .lineLimit(1)
                }
                Spacer()
                Text(note.dateCreated.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(12)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)

            Text("No Notes Yet")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)

            Text("Capture your thoughts and insights from reading sessions.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
