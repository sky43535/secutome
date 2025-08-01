import SwiftUI
import CryptoKit
import CoreML

struct LoadingError: Identifiable {
    let id = UUID()
    let message: String
}

struct DiaryView: View {
    @AppStorage("didSkipSecurity") private var didSkipSecurity: Bool = false
    
    @State private var notes: [DiaryNote] = []
    @State private var loadingError: LoadingError? = nil
    @State private var showingNewNote = false

    // Group notes by topic string (or "Untagged" if none)
    private var groupedNotes: [String: [DiaryNote]] {
        Dictionary(grouping: notes) { $0.topic ?? "Untagged" }
    }
    
    // Sorted topic keys (optional: you can customize order)
    private var sortedTopics: [String] {
        groupedNotes.keys.sorted()
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(sortedTopics, id: \.self) { topic in
                    Section(header: Text(topic).font(.headline)) {
                        ForEach(groupedNotes[topic] ?? []) { note in
                            NavigationLink(destination: NoteDetailView(note: binding(for: note))) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Label(note.title, systemImage: "note.text")
                                        .font(.headline)
                                    Text(note.preview)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    HStack {
                                        Image(systemName: "clock")
                                        Text(note.timestampFormatted)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                        .onDelete { indexSet in
                            deleteNote(at: indexSet, in: topic)
                        }
                    }
                }
            }
            .navigationTitle("📓 Your Diary")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewNote = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel("New Note")
                }
            }
            .sheet(isPresented: $showingNewNote) {
                NewNoteView { newNote in
                    var noteWithTopic = newNote
                    noteWithTopic.topic = predictTopic(for: newNote.content)
                    notes.append(noteWithTopic)
                    saveNotes()
                }
            }
            .alert(item: $loadingError) { error in
                Alert(
                    title: Text("Error"),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear(perform: loadNotes)
    }

    func binding(for note: DiaryNote) -> Binding<DiaryNote> {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else {
            fatalError("Note not found")
        }
        return $notes[index]
    }

    func loadNotes() {
        do {
            if didSkipSecurity {
                // Load plaintext notes
                if let data = UserDefaults.standard.data(forKey: "notes") {
                    let savedNotes = try JSONDecoder().decode([DiaryNote].self, from: data)
                    notes = savedNotes
                } else {
                    notes = []
                }
            } else {
                // Load encrypted notes
                guard let combinedData = UserDefaults.standard.data(forKey: "notes") else {
                    notes = []
                    return
                }

                let key = try KeychainHelper.shared.getOrCreateKey()
                let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
                let decryptedData = try AES.GCM.open(sealedBox, using: key)

                let savedNotes = try JSONDecoder().decode([DiaryNote].self, from: decryptedData)
                notes = savedNotes
            }
        } catch {
            loadingError = LoadingError(message: "Failed to load notes securely.")
            notes = []
        }
    }

    func saveNotes() {
        do {
            if didSkipSecurity {
                // Save plaintext notes
                let data = try JSONEncoder().encode(notes)
                UserDefaults.standard.set(data, forKey: "notes")
            } else {
                // Save encrypted notes
                let key = try KeychainHelper.shared.getOrCreateKey()
                let data = try JSONEncoder().encode(notes)
                let sealedBox = try AES.GCM.seal(data, using: key)
                if let combined = sealedBox.combined {
                    UserDefaults.standard.set(combined, forKey: "notes")
                }
            }
        } catch {
            print("Failed to save notes: \(error.localizedDescription)")
        }
    }
    
    func deleteNote(at offsets: IndexSet, in topic: String) {
        guard var notesInTopic = groupedNotes[topic] else { return }
        notesInTopic.remove(atOffsets: offsets)
        
        // Remove those notes from main notes array
        notes.removeAll(where: { note in
            !notesInTopic.contains(where: { $0.id == note.id })
        })
        saveNotes()
    }
    
    // MARK: - Topic Prediction (single label only)
    func predictTopic(for text: String) -> String? {
        do {
            let model = try topic_grouper_2(configuration: MLModelConfiguration())
            let input = topic_grouper_2Input(text: text)
            let output = try model.prediction(input: input)
            return output.label
        } catch {
            print("Prediction error: \(error.localizedDescription)")
            return nil
        }
    }
}

struct DiaryNote: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    let timestamp: Date
    var topic: String? = nil

    init(id: UUID = UUID(), title: String, content: String, timestamp: Date = Date(), topic: String? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.timestamp = timestamp
        self.topic = topic
    }

    var preview: String {
        let limit = 60
        return content.count > limit ? String(content.prefix(limit)) + "…" : content
    }

    var timestampFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}




import SwiftUI

struct NewNoteView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var content = ""
    @State private var topic = ""
    var onSave: (DiaryNote) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Label("Title", systemImage: "textformat")) {
                    TextField("Enter a title", text: $title)
                }
                Section(header: Label("Content", systemImage: "doc.plaintext")) {
                    TextEditor(text: $content)
                        .frame(height: 200)
                }
                Section(header: Label("Topic (optional)", systemImage: "tag")) {
                    TextField("Enter or edit topic", text: $topic)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                }
            }
            .navigationTitle(" New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newNote = DiaryNote(title: title, content: content, topic: topic.isEmpty ? nil : topic)
                        onSave(newNote)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
}

import SwiftUI

struct NoteDetailView: View {
    @Binding var note: DiaryNote

    var body: some View {
        Form {
            Section(header: Label("Title", systemImage: "text.book.closed")) {
                TextField("Note Title", text: $note.title)
            }
            Section(header: Label("Content", systemImage: "text.justify.left")) {
                TextEditor(text: $note.content)
                    .frame(minHeight: 200)
            }
            Section(header: Label("Topic (optional)", systemImage: "tag")) {
                TextField("Enter or edit topic", text: $note.topic.bound)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
            }
            Section(footer: Label(note.timestampFormatted, systemImage: "calendar.badge.clock")
                        .font(.footnote)
                        .foregroundColor(.gray)) {
                EmptyView()
            }
        }
        .navigationTitle(" Edit Note")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension Optional where Wrapped == String {
    /// Helper to bind optional String for TextField usage
    var bound: String {
        get { self ?? "" }
        set { self = newValue.isEmpty ? nil : newValue }
    }
}
