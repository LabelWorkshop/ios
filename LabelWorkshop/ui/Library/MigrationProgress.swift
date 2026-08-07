import SwiftUI

struct MigrationProgress: View {
    @State var migrator: LibraryMigrator
    @Binding var closed: Bool
    @State var migrationText: String = "Checking for Migration"
    @State var migrationIcon: String = "questionmark.folder"
    @State var migrationTint: Color = .gray
    
    var body: some View {
        if self.migrator.state != .MigrationNotRequired {
            VStack {
                HStack {
                    Image(systemName: self.migrationIcon)
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(migrationTint)
                    Text(NSLocalizedString(self.migrationText, comment: ""))
                    Button (action: {
                        closed = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .tint(.gray)
                    .symbolRenderingMode(.hierarchical)
                }
                ProgressView(
                    value: max(0, min(self.migrator.percentage, 100)),
                    total: 100
                )
            }
            .padding(16)
            .onChange(of: self.migrator.state) {
                switch self.migrator.state {
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
}
