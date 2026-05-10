import SwiftUI

@main
struct ArmKeyApp: App {
    var body: some Scene {
        WindowGroup {
            SetupView()
        }
    }
}

// MARK: - SetupView

struct SetupView: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    header
                    stepsCard
                    openSettingsButton
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 48)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "keyboard.fill")
                .font(.system(size: 52))
                .foregroundStyle(.blue)

            Text("Armenian Keyboard")
                .font(.title.bold())

            Text("Follow these steps to enable the keyboard and unlock full functionality.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: Steps card

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepRow(
                number: "1",
                title: "Add the keyboard",
                detail: "Settings → General → Keyboard → Keyboards → Add New Keyboard → ArmKey"
            )

            Divider().padding(.leading, 56)

            stepRow(
                number: "2",
                title: "Enable Full Access",
                detail: "Tap ArmKey in the keyboard list, then turn on Allow Full Access.\n\nThis is required to fix the brief flash that appears when switching to the keyboard.",
                highlight: true
            )
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func stepRow(number: String, title: String, detail: String, highlight: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(highlight ? Color.blue : Color.secondary, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 16)

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: Open Settings button

    private var openSettingsButton: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            Label("Open Settings", systemImage: "gear")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
        }
    }
}
