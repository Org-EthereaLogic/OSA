import SwiftUI

struct OnboardingFlowView: View {
    let onComplete: () -> Void

    @Environment(\.handbookRepository) private var handbookRepository
    @Environment(\.quickCardRepository) private var quickCardRepository
    @Environment(\.checklistRepository) private var checklistRepository

    @AppStorage(UserProfileSettings.regionKey) private var regionRawValue = UserProfileSettings.regionDefault.rawValue
    @AppStorage(UserProfileSettings.householdSizeKey) private var householdSize = UserProfileSettings.householdSizeDefault
    @AppStorage(UserProfileSettings.hazardsKey) private var hazardsRawValue = UserProfileSettings.encode(hazards: [])
    @AppStorage(UserProfileSettings.onboardingCompletedKey) private var onboardingCompleted = UserProfileSettings.onboardingCompletedDefault
    @AppStorage(PinnedContentSettings.pinnedQuickCardIDsKey) private var pinnedQuickCardIDsRawValue = PinnedContentSettings.encode(ids: [])
    @AppStorage(PinnedContentSettings.pinnedSectionIDsKey) private var pinnedSectionIDsRawValue = PinnedContentSettings.encode(ids: [])

    @State private var selectedHazards: Set<HazardScenario> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    hero
                    formCard
                    saveButton
                }
                .padding(Spacing.lg)
            }
            .background(.osaBackground)
            .navigationTitle("Getting Started")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                selectedHazards = Set(UserProfileSettings.hazards(from: hazardsRawValue))
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            BrandWordmarkView(height: 32)
            Text("Make Lantern fit your household before you need it.")
                .font(.brandSubheadline)
                .foregroundStyle(Color.white.opacity(0.82))
            Text("Your choices stay on this device and only shape local organization, suggestions, and emergency shortcuts.")
                .font(.metadataCaption)
                .foregroundStyle(Color.white.opacity(0.72))
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.osaCanopy, Color.osaPine, Color.osaNight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: CornerRadius.xl)
        )
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(Color.osaPrimary.opacity(0.24), lineWidth: 1)
        }
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Region")
                    .font(.sectionHeader)
                Picker("Region", selection: $regionRawValue) {
                    ForEach(PreparednessRegion.allCases) { region in
                        Text(region.displayName).tag(region.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Household Size")
                    .font(.sectionHeader)
                Stepper(value: $householdSize, in: 1...12) {
                    Text("\(householdSize) \(householdSize == 1 ? "person" : "people")")
                }
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Primary Hazards")
                    .font(.sectionHeader)
                Text("Choose the situations you want surfaced first.")
                    .font(.metadataCaption)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: Spacing.sm)], spacing: Spacing.sm) {
                    ForEach(HazardScenario.allCases) { hazard in
                        HazardSelectionButton(
                            hazard: hazard,
                            isSelected: selectedHazards.contains(hazard)
                        ) {
                            toggle(hazard)
                        }
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.xl))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(Color.osaHairline, lineWidth: 1)
        }
    }

    private var saveButton: some View {
        Button {
            let hazards = Array(selectedHazards).sorted { $0.rawValue < $1.rawValue }
            hazardsRawValue = UserProfileSettings.encode(hazards: hazards)
            seedPinnedContent(for: hazards)
            seedGettingStartedChecklist()
            onboardingCompleted = true
            onComplete()
        } label: {
            Label("Finish Setup", systemImage: "checkmark.circle.fill")
                .frame(maxWidth: .infinity)
                .font(.headline)
        }
        .buttonStyle(.borderedProminent)
        .tint(.osaPrimary)
    }

    private func toggle(_ hazard: HazardScenario) {
        if selectedHazards.contains(hazard) {
            selectedHazards.remove(hazard)
        } else {
            selectedHazards.insert(hazard)
        }
    }

    private func seedPinnedContent(for hazards: [HazardScenario]) {
        let targetTags = Set((hazards.isEmpty ? [HazardScenario.powerOutage] : hazards).map(\.tag))

        if PinnedContentSettings.ids(from: pinnedQuickCardIDsRawValue).isEmpty,
           let quickCardRepository {
            let cards = (try? quickCardRepository.listQuickCards()) ?? []
            let pinnedCards = cards
                .filter { !targetTags.isDisjoint(with: Set($0.tags)) }
                .prefix(2)
                .map(\.id)

            if !pinnedCards.isEmpty {
                pinnedQuickCardIDsRawValue = PinnedContentSettings.encode(ids: Array(pinnedCards))
            }
        }

        if PinnedContentSettings.ids(from: pinnedSectionIDsRawValue).isEmpty,
           let handbookRepository {
            let chapters = (try? handbookRepository.listChapters()) ?? []
            let matchingChapters = chapters.filter { !targetTags.isDisjoint(with: Set($0.tags)) }

            for chapterSummary in matchingChapters {
                guard let chapter = try? handbookRepository.chapter(id: chapterSummary.id),
                      let section = chapter.sections.first else {
                    continue
                }

                pinnedSectionIDsRawValue = PinnedContentSettings.encode(ids: [section.id])
                break
            }
        }
    }

    private func seedGettingStartedChecklist() {
        guard let checklistRepository else { return }

        do {
            let activeRuns = try checklistRepository.activeRuns()
            guard !activeRuns.contains(where: { $0.title == "Getting Started Household Setup" }) else {
                return
            }

            guard let template = try checklistRepository.template(slug: "getting-started-household-setup") else {
                return
            }

            _ = try checklistRepository.startRun(
                from: template.id,
                title: template.title,
                contextNote: "Seeded during onboarding"
            )
        } catch {
            // First-run setup should not block onboarding completion.
        }
    }
}

private struct HazardSelectionButton: View {
    let hazard: HazardScenario
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                Text(hazard.displayName)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                isSelected ? Color.osaPrimary.opacity(0.14) : Color.osaElevatedSurface,
                in: RoundedRectangle(cornerRadius: CornerRadius.md)
            )
            .foregroundStyle(isSelected ? Color.osaPrimary : .primary)
        }
        .buttonStyle(.plain)
    }
}
