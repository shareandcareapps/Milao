import SwiftUI
import Supabase

// MARK: - Sign-in prompt (explore mode)
// Guests can browse everything, but any action that writes data funnels here.

struct SignInPromptModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Environment(AuthService.self) private var auth

    func body(content: Content) -> some View {
        content.alert("Sign in to continue", isPresented: $isPresented) {
            Button("Sign In") {
                // Leaving explore mode returns to the login screen.
                Task { await auth.signOut() }
            }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("You're browsing as a guest. Create a free account to post, message, and join the community.")
        }
    }
}

extension View {
    func signInPrompt(isPresented: Binding<Bool>) -> some View {
        modifier(SignInPromptModifier(isPresented: isPresented))
    }
}

// MARK: - Report Sheet
// Writes to the `reports` table. Exactly one of listingId / rideId / reportedUserId
// gives the report its context; reportedUserId may accompany either.

struct ReportSheet: View {
    let reporterId: UUID
    var reportedUserId: UUID? = nil
    var listingId: UUID? = nil
    var rideId: UUID? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var reason = "Spam or scam"
    @State private var notes = ""
    @State private var isSubmitting = false
    @State private var didFail = false

    private let reasons = [
        "Spam or scam",
        "Inappropriate content",
        "Harassment or abuse",
        "Misleading or false info",
        "Safety concern",
        "Other",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Picker("Reason", selection: $reason) {
                    ForEach(reasons, id: \.self) { Text($0).tag($0) }
                }
                Section("Details (optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 110)
                }
                Section {
                    Text("Reports are reviewed by the Milao team. The person you report won't be notified.")
                        .font(.inter(.regular, size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("Submit") { Task { await submit() } }
                    }
                }
            }
            .alert("Couldn't send report", isPresented: $didFail) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please check your connection and try again.")
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        var payload: [String: AnyJSON] = [
            "reporter_id": .string(reporterId.uuidString),
            "reason":      .string(reason),
            "status":      .string("open"),
        ]
        if !notes.isEmpty { payload["notes"] = .string(notes) }
        if let reportedUserId { payload["reported_user_id"] = .string(reportedUserId.uuidString) }
        if let listingId { payload["listing_id"] = .string(listingId.uuidString) }
        if let rideId { payload["ride_id"] = .string(rideId.uuidString) }
        do {
            try await supabase.from("reports").insert(payload).execute()
            dismiss()
        } catch {
            didFail = true
        }
    }
}
