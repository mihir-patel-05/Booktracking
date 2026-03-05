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
                    VStack(alignment: .leading, spacing: 20) {
                        // Book Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Book")
                                .font(.subheadline.bold())
                                .foregroundStyle(Theme.textSecondary)

                            Button {
                                showBookPicker = true
                            } label: {
                                HStack {
                                    Text(selectedBook?.title ?? "Select a book")
                                        .foregroundStyle(selectedBook != nil ? Theme.textPrimary : Theme.textMuted)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(Theme.textMuted)
                                }
                                .padding(12)
                                .background(Theme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        // Quote Text
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quote")
                                .font(.subheadline.bold())
                                .foregroundStyle(Theme.textSecondary)

                            TextEditor(text: $text)
                                .scrollContentBackground(.hidden)
                                .foregroundStyle(Theme.textPrimary)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(Theme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveQuote() }
                        .foregroundStyle(Theme.accent)
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

    private func saveQuote() {
        guard let book = selectedBook else { return }
        let quote = Quote(book: book, text: text.trimmingCharacters(in: .whitespaces))
        quote.supabaseUserId = authService.currentUserId
        modelContext.insert(quote)
        dismiss()
    }
}
