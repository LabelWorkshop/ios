import SwiftUI

struct MigrationProgress: View {
    @StateObject var library: Library
    @Binding var closed: Bool
    @State var migrationText: String = "Checking for Migration"
    @State var migrationIcon: String = "questionmark.folder"
    @State var migrationTint: Color = .gray
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: self.migrationIcon)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(migrationTint)
                Text(self.migrationText)
                Button (action: {
                    closed = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                }
                .tint(.gray)
                .symbolRenderingMode(.hierarchical)
            }
            ProgressView(
                value: max(0, min(self.library.migrationPercentage, 100)),
                total: 100
            )
        }
        .padding(16)
        .onChange(of: self.library.migrationState) {
            switch self.library.migrationState {
                case .MigrationInProgress:
                    migrationText = "Migration in Progress"
                    migrationIcon = "arrow.trianglehead.2.clockwise.rotate.90"
                    migrationTint = .yellow
                case .MigrationComplete:
                    migrationText = "Migration Complete"
                    migrationIcon = "checkmark"
                    migrationTint = .green
                case .MigrationFailed:
                    migrationText = "Migration Failed"
                    migrationIcon = "xmark.octagon"
                    migrationTint = .red
                case .Unknown:
                    migrationText = "Checking for Migration"
                    migrationIcon = "questionmark.folder"
                    migrationTint = .gray
                case .MigrationNotRequired: break
            }
        }
    }
}
