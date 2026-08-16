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

    var prefill: GoogleBookItem?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if !coverURL.isEmpty, let url = URL(string: coverURL) {
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
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: .black.opacity(0.5), radius: 12, y: 8)
                                Spacer()
                            }
                        }

                        textCard(label: "Title", value: $title)
                        textCard(label: "Author", value: $author)
                        textCard(label: "Total Pages", value: $totalPages, keyboard: .number)
                        textCard(label: "Cover URL (Optional)", value: $coverURL, keyboard: .url)

                        VStack(alignment: .leading, spacing: 8) {
                            SectionLabel("Status", bottomPadding: 0)
                            Picker("Status", selection: $selectedStatus) {
                                ForEach(BookStatus.allCases, id: \.self) { status in
                                    Text(status.rawValue).tag(status)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(prefill != nil ? "Add Book" : "New Book")
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
                    Button("Save") { saveBook() }
                        .foregroundStyle(Theme.accentLight)
                        .disabled(!isValid)
                }
            }
            .onAppear {
                if let prefill {
                    title = prefill.volumeInfo.title
                    author = prefill.authorDisplay
                    totalPages = prefill.pageCount > 0 ? String(prefill.pageCount) : ""
                    coverURL = prefill.coverURL ?? ""
                }
            }
        }
    }

    enum FieldKeyboard { case standard, number, url }

    private func textCard(label: String, value: Binding<String>, keyboard: FieldKeyboard = .standard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(label, bottomPadding: 0)
            field(value: value, keyboard: keyboard)
        }
    }

    @ViewBuilder
    private func field(value: Binding<String>, keyboard: FieldKeyboard) -> some View {
        let view = TextField("", text: value)
            .font(.dmSans(14))
            .foregroundStyle(Theme.textPrimary)
            .tint(Theme.accentLight)
            .padding(14)
            .designCard(cornerRadius: 14)

        #if os(iOS)
        switch keyboard {
        case .standard:
            view
        case .number:
            view.keyboardType(.numberPad)
        case .url:
            view.keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        #else
        view
        #endif
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
