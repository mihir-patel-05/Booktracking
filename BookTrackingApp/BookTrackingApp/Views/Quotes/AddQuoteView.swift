import SwiftUI
import SwiftData

struct AddQuoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService

    @State private var text = ""
    @State private var selectedBook: Book?
    @State private var showBookPicker = false

    var preselectedBook: Book?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        bookCard
                        quoteField
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Quote")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accentLight)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveQuote() }
                        .foregroundStyle(Theme.accentLight)
                        .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty || selectedBook == nil)
                }
            }
            .sheet(isPresented: $showBookPicker) {
                BookPickerSheet(filterStatus: nil) { book in
                    selectedBook = book
                }
            }
            .onAppear {
                if let preselectedBook {
                    selectedBook = preselectedBook
                }
            }
        }
    }

    private var bookCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel("Book", bottomPadding: 0)
            Button { showBookPicker = true } label: {
                HStack(spacing: 12) {
                    if let book = selectedBook {
                        BookCoverView(book: book, size: .sm)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(book.title)
                                .font(.dmSans(14, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)
                            Text(book.author)
                                .font(.dmSans(11))
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text("Select a book")
                            .font(.dmSans(14))
                            .foregroundStyle(Theme.textMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(14)
                .designCard(cornerRadius: 14)
            }
            .buttonStyle(.plain)
        }
    }

    private var quoteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel("Quote", bottomPadding: 0)
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .font(.playfair(15, weight: .regular))
                .italic()
                .foregroundStyle(Theme.textPrimary)
                .tint(Theme.accentLight)
                .frame(minHeight: 140)
                .padding(10)
                .designCard(cornerRadius: 14)
        }
    }

    private func saveQuote() {
        guard let book = selectedBook else { return }
        let quote = Quote(book: book, text: text.trimmingCharacters(in: .whitespaces))
        quote.supabaseUserId = authService.currentUserId
        modelContext.insert(quote)
        dismiss()
    }
}
