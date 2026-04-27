import SwiftUI
import SwiftData

struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SessionNote.dateCreated, order: .reverse) private var notes: [SessionNote]
    @State private var showAddNote = false
    @State private var searchText = ""
    @State private var selectedBookFilter: Book?
    @State private var expandedNoteID: UUID?
    @State private var notePendingDeletion: SessionNote?

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
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if notes.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        searchBar
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                        if !uniqueBooks.isEmpty {
                            bookFilterPills
                                .padding(.top, 12)
                        }

                        countLabel
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 12)

                        ScrollView {
                            LazyVStack(spacing: 9) {
                                ForEach(filteredNotes) { note in
                                    noteCard(note)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                modelContext.delete(note)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            NavigationLink(value: note) {
                                                Label("Open", systemImage: "arrow.up.right.square")
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            #if os(iOS)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
            .navigationDestination(for: SessionNote.self) { note in
                NoteDetailView(note: note)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddNote = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.accentLight)
                    }
                }
            }
            .sheet(isPresented: $showAddNote) {
                AddNoteView()
            }
            .confirmationDialog("Delete this note?", isPresented: Binding(
                get: { notePendingDeletion != nil },
                set: { if !$0 { notePendingDeletion = nil } }
            ), titleVisibility: .visible) {
                Button("Delete Note", role: .destructive) {
                    if let notePendingDeletion {
                        modelContext.delete(notePendingDeletion)
                    }
                    notePendingDeletion = nil
                }
                Button("Cancel", role: .cancel) {
                    notePendingDeletion = nil
                }
            } message: {
                Text("This will remove the note from your saved notes.")
            }
        }
    }

    private var header: some View {
        Text("Notes")
            .font(.playfair(26, weight: .bold))
            .foregroundStyle(Theme.textPrimary)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textMuted)
            TextField("Search notes...", text: $searchText)
                .font(.dmSans(14))
                .foregroundStyle(Theme.textPrimary)
                .tint(Theme.accentLight)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .designCard(cornerRadius: 12)
    }

    private var bookFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                FilterPill(label: "All", isSelected: selectedBookFilter == nil) {
                    selectedBookFilter = nil
                }
                ForEach(uniqueBooks) { book in
                    let trimmed = book.title.split(separator: " ").prefix(2).joined(separator: " ")
                    FilterPill(label: trimmed, isSelected: selectedBookFilter?.id == book.id) {
                        selectedBookFilter = book
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var countLabel: some View {
        Text("\(filteredNotes.count) note\(filteredNotes.count == 1 ? "" : "s")")
            .font(.dmSans(11))
            .foregroundStyle(Theme.textMuted)
    }

    // MARK: - Note Card

    private func noteCard(_ note: SessionNote) -> some View {
        let isOpen = expandedNoteID == note.id
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Text(note.title)
                    .font(.dmSans(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Spacer(minLength: 8)
                Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.top, 2)
            }

            Text(note.content)
                .font(.dmSans(13))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .lineLimit(isOpen ? nil : 2)

            HStack(spacing: 5) {
                ForEach(note.tags.prefix(4), id: \.self) { tag in
                    Chip(label: "#\(tag)", color: Theme.accentLight)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    if let book = note.book {
                        let trimmed = book.title.split(separator: " ").prefix(2).joined(separator: " ")
                        Text(trimmed)
                            .font(.dmSans(11, weight: .semibold))
                            .foregroundStyle(Theme.accentLight)
                            .lineLimit(1)
                    }
                    Text(note.dateCreated.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.dmSans(10))
                        .foregroundStyle(Theme.textMuted)
                }
            }

            if isOpen {
                HStack(spacing: 10) {
                    NavigationLink(value: note) {
                        HStack(spacing: 6) {
                            Text("Edit note")
                                .font(.dmSans(11, weight: .semibold))
                            Image(systemName: "pencil")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundStyle(Theme.accentLight)
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive) {
                        notePendingDeletion = note
                    } label: {
                        HStack(spacing: 6) {
                            Text("Delete")
                                .font(.dmSans(11, weight: .semibold))
                            Image(systemName: "trash")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundStyle(.red.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .designCard(cornerRadius: 16, borderColor: isOpen ? Theme.accent.opacity(0.4) : Theme.border)
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.35)) {
                expandedNoteID = isOpen ? nil : note.id
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 18) {
            Text("📝").font(.system(size: 48))
            Text("No Notes Yet")
                .font(.playfair(22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Capture your thoughts and insights from reading sessions.")
                .font(.dmSans(14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button { showAddNote = true } label: {
                Text("Add a note")
            }
            .buttonStyle(PrimaryGradientButtonStyle())
            .frame(maxWidth: 220)
            .padding(.top, 6)
        }
    }
}

#Preview {
    NotesView()
        .modelContainer(for: [Book.self, SessionNote.self])
        .preferredColorScheme(.dark)
}
