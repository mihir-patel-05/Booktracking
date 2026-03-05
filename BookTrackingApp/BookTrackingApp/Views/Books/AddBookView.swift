import SwiftUI
import SwiftData

struct AddBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService

    @State private var title = ""
    @State private var author = ""
    @State private var totalPages = ""
    @State private var coverURL = ""
    @State private var selectedStatus: BookStatus = .wantToRead

    var prefill: OpenLibraryDoc?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                Form {
                    Section {
                        TextField("Title", text: $title)
                        TextField("Author", text: $author)
                        TextField("Total Pages", text: $totalPages)
                            .keyboardType(.numberPad)
                        TextField("Cover URL (optional)", text: $coverURL)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .listRowBackground(Theme.cardBackground)
                    .foregroundStyle(Theme.textPrimary)

                    Section("Status") {
                        Picker("Status", selection: $selectedStatus) {
                            ForEach(BookStatus.allCases, id: \.self) { status in
                                Label(status.rawValue, systemImage: status.icon)
                                    .tag(status)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.accent)
                    }
                    .listRowBackground(Theme.cardBackground)
                    .foregroundStyle(Theme.textPrimary)

                    if let urlString = coverURL.isEmpty ? nil : coverURL,
                       let url = URL(string: urlString) {
                        Section("Cover Preview") {
                            HStack {
                                Spacer()
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image.resizable().aspectRatio(contentMode: .fit)
                                    default:
                                        ProgressView().tint(Theme.accent)
                                    }
                                }
                                .frame(height: 150)
                                Spacer()
                            }
                        }
                        .listRowBackground(Theme.cardBackground)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(prefill != nil ? "Add Book" : "New Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveBook() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                if let prefill {
                    title = prefill.title
                    author = prefill.authorDisplay
                    totalPages = prefill.pageCount > 0 ? String(prefill.pageCount) : ""
                    coverURL = prefill.coverURL ?? ""
                }
            }
        }
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
        && !author.trimmingCharacters(in: .whitespaces).isEmpty
        && (Int(totalPages) ?? 0) > 0
    }

    private func saveBook() {
        let book = Book(
            title: title.trimmingCharacters(in: .whitespaces),
            author: author.trimmingCharacters(in: .whitespaces),
            coverURL: coverURL.isEmpty ? nil : coverURL,
            totalPages: Int(totalPages) ?? 0,
            status: selectedStatus
        )
        book.supabaseUserId = authService.currentUserId
        modelContext.insert(book)
        dismiss()
    }
}
