//
//  image to ai .swift
//  SkyCipher dirary
//
//  Created by Owner on 7/29/25.
//



import SwiftUI
import CryptoKit

struct SecureStorageItem: Identifiable, Codable, Hashable {
    enum ItemType: String, Codable, CaseIterable, Identifiable {
        case bitcoinWallet = "Bitcoin Wallet"
        case accessPin = "Access PIN / Code"
        case secureText = "Secure Text Snippet"
        case loginCredentials = "Login Credentials"
        case idDocument = "ID Document Info"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .bitcoinWallet: return "bitcoinsign.circle.fill"
            case .accessPin: return "key.fill"
            case .secureText: return "text.quote"
            case .loginCredentials: return "person.crop.rectangle"
            case .idDocument: return "doc.text.fill"
            }
        }

        var color: Color {
            switch self {
            case .bitcoinWallet: return .orange
            case .accessPin: return .blue
            case .secureText: return .purple
            case .loginCredentials: return .green
            case .idDocument: return .pink
            }
        }
    }

    let id: UUID
    var type: ItemType
    var label: String
    var fields: [String: String]

    init(type: ItemType, label: String, fields: [String: String]) {
        self.id = UUID()
        self.type = type
        self.label = label
        self.fields = fields
    }
}

struct SecureStorageTab: View {
    @State private var items: [SecureStorageItem] = []
    @State private var showingAddType: SecureStorageItem.ItemType? = nil
    @AppStorage("didSkipSecurity") private var didSkipSecurity: Bool = false

    private var groupedItems: [SecureStorageItem.ItemType: [SecureStorageItem]] {
        Dictionary(grouping: items, by: { $0.type })
    }

    var body: some View {
        NavigationView {
            List {
                if items.isEmpty {
                    Text("No vault contents yet. Tap + to add something secure.")
                        .foregroundColor(.gray)
                        .italic()
                        .padding(.vertical, 60)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(SecureStorageItem.ItemType.allCases) { type in
                        if let itemsForType = groupedItems[type] {
                            Section(header: HStack {
                                Image(systemName: type.iconName)
                                    .foregroundColor(type.color)
                                Text(type.rawValue)
                                    .font(.headline)
                                    .foregroundColor(type.color)
                            }) {
                                ForEach(itemsForType) { item in
                                    NavigationLink(destination: SecureItemDetailView(item: item)) {
                                        HStack {
                                            Image(systemName: type.iconName)
                                                .foregroundColor(type.color)
                                            VStack(alignment: .leading) {
                                                Text(item.label)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                                Text(itemPreview(item: item))
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                }
                                .onDelete { indexSet in
                                    deleteItems(at: indexSet, for: type)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Secure Vault")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(SecureStorageItem.ItemType.allCases) { type in
                            Button {
                                showingAddType = type
                            } label: {
                                Label(type.rawValue, systemImage: type.iconName)
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                    .accessibilityLabel("Add Secure Item")
                }
            }
            .onAppear(perform: loadItems)
            .sheet(item: $showingAddType) { type in
                switch type {
                case .bitcoinWallet:
                    AddBitcoinWalletView { newItem in
                        addItem(newItem)
                    }
                case .accessPin:
                    AddAccessPinView { newItem in
                        addItem(newItem)
                    }
                case .secureText:
                    AddSecureTextView { newItem in
                        addItem(newItem)
                    }
                case .loginCredentials:
                    AddLoginCredentialsView { newItem in
                        addItem(newItem)
                    }
                case .idDocument:
                    AddIdDocumentView { newItem in
                        addItem(newItem)
                    }
                }
            }
        }
    }

    private func addItem(_ item: SecureStorageItem) {
        items.append(item)
        saveItems()
        showingAddType = nil
    }

    private func deleteItems(at offsets: IndexSet, for type: SecureStorageItem.ItemType) {
        let itemsForType = groupedItems[type] ?? []
        for index in offsets {
            if let idx = items.firstIndex(where: { $0.id == itemsForType[index].id }) {
                items.remove(at: idx)
            }
        }
        saveItems()
    }

    private func itemPreview(item: SecureStorageItem) -> String {
        item.fields.values.first(where: { !$0.isEmpty }) ?? "No details"
    }

    private func saveItems() {
        do {
            let data = try JSONEncoder().encode(items)
            if didSkipSecurity {
                UserDefaults.standard.set(data, forKey: "secureStorage")
            } else {
                let key = try KeychainHelper.shared.getOrCreateKey()
                let sealedBox = try AES.GCM.seal(data, using: key)
                if let combined = sealedBox.combined {
                    UserDefaults.standard.set(combined, forKey: "secureStorage")
                }
            }
        } catch {
            print("Failed to save secure items: \(error.localizedDescription)")
        }
    }

    private func loadItems() {
        do {
            guard let savedData = UserDefaults.standard.data(forKey: "secureStorage") else {
                items = []
                return
            }

            if didSkipSecurity {
                let decoded = try JSONDecoder().decode([SecureStorageItem].self, from: savedData)
                items = decoded
            } else {
                let key = try KeychainHelper.shared.getOrCreateKey()
                let sealedBox = try AES.GCM.SealedBox(combined: savedData)
                let decryptedData = try AES.GCM.open(sealedBox, using: key)
                let decoded = try JSONDecoder().decode([SecureStorageItem].self, from: decryptedData)
                items = decoded
            }
        } catch {
            print("Failed to load secure items: \(error.localizedDescription)")
            items = []
        }
    }
}

struct SecureItemDetailView: View {
    let item: SecureStorageItem

    var body: some View {
        Form {
            Section(header: Text("Label")) {
                Text(item.label)
                    .font(.headline)
            }
            ForEach(item.fields.sorted(by: { $0.key < $1.key }), id: \.0) { key, value in
                Section(header: Text(key)) {
                    Text(value.isEmpty ? "(empty)" : value)
                        .foregroundColor(value.isEmpty ? .gray : .primary)
                        .contextMenu {
                            Button(action: {
                                UIPasteboard.general.string = value
                            }) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                }
            }
        }
        .navigationTitle(item.type.rawValue)
    }
}

struct AddBitcoinWalletView: View {
    var onSave: (SecureStorageItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var walletAddress = ""
    @State private var privateKey = ""
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Label") {
                    TextField("give it a name...", text: $label)
                }
                Section("Wallet Address") {
                    TextField("1A1zP1...", text: $walletAddress)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                Section("Private Key") {
                    SecureField("Private Key", text: $privateKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Bitcoin Wallet")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let fields = [
                            "Wallet Address": walletAddress,
                            "Private Key": privateKey,
                            "Notes": notes
                        ]
                        let item = SecureStorageItem(type: .bitcoinWallet, label: label, fields: fields)
                        onSave(item)
                        dismiss()
                    }
                    .disabled(label.isEmpty || walletAddress.isEmpty || privateKey.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct AddAccessPinView: View {
    var onSave: (SecureStorageItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var pin = ""
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Label") {
                    TextField("type of acces pin...", text: $label)
                }
                Section("PIN / Code") {
                    SecureField("1234", text: $pin)
                        .keyboardType(.numberPad)
                }
                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Access PIN")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let fields = [
                            "PIN / Code": pin,
                            "Notes": notes
                        ]
                        let item = SecureStorageItem(type: .accessPin, label: label, fields: fields)
                        onSave(item)
                        dismiss()
                    }
                    .disabled(label.isEmpty || pin.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct AddSecureTextView: View {
    var onSave: (SecureStorageItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var secretText = ""
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Label") {
                    TextField("give it a name...", text: $label)
                }
                Section("Secret Text") {
                    TextEditor(text: $secretText)
                        .frame(height: 150)
                }
                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Secure Text")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let fields = [
                            "Secret Text": secretText,
                            "Notes": notes
                        ]
                        let item = SecureStorageItem(type: .secureText, label: label, fields: fields)
                        onSave(item)
                        dismiss()
                    }
                    .disabled(label.isEmpty || secretText.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct AddLoginCredentialsView: View {
    var onSave: (SecureStorageItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var usernameOrEmail = ""
    @State private var password = ""
    @State private var url = ""
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Label") {
                    TextField("type of login credential", text: $label)
                }
                Section("Username or Email") {
                    TextField("enter email or username ", text: $usernameOrEmail)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                Section("Password") {
                    SecureField("Password", text: $password)
                }
                Section("URL") {
                    TextField("https://", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Login Credentials")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let fields = [
                            "Username or Email": usernameOrEmail,
                            "Password": password,
                            "URL": url,
                            "Notes": notes
                        ]
                        let item = SecureStorageItem(type: .loginCredentials, label: label, fields: fields)
                        onSave(item)
                        dismiss()
                    }
                    .disabled(label.isEmpty || usernameOrEmail.isEmpty || password.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}


struct AddIdDocumentView: View {
    var onSave: (SecureStorageItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var fullName = ""
    @State private var idNumber = ""
    @State private var expirationDate = ""
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Label") {
                    TextField("type of id...", text: $label)
                }
                Section("Full Name") {
                    TextField("your full name ", text: $fullName)
                        .autocapitalization(.words)
                }
                Section("ID Number") {
                    TextField("the number on the id ", text: $idNumber)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                }
                Section("Expiration Date") {
                    TextField("MM/DD/YYYY", text: $expirationDate)
                        .keyboardType(.numberPad)
                        .onChange(of: expirationDate) { newValue in
                            expirationDate = formatDateInput(newValue)
                        }
                }
                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add ID Document")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let fields = [
                            "Full Name": fullName,
                            "ID Number": idNumber,
                            "Expiration Date": expirationDate,
                            "Notes": notes
                        ]
                        let item = SecureStorageItem(type: .idDocument, label: label, fields: fields)
                        onSave(item)
                        dismiss()
                    }
                    .disabled(label.isEmpty || fullName.isEmpty || idNumber.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // Helper function to format MM/DD/YYYY with slashes as user types
    private func formatDateInput(_ input: String) -> String {
        // Remove all non-digit characters
        let digits = input.filter { $0.isNumber }
        var result = ""

        for (index, char) in digits.enumerated() {
            if index == 2 || index == 4 {
                result.append("/")
            }
            if index >= 8 { break } // max 8 digits for MMDDYYYY
            result.append(char)
        }
        return result
    }
}
