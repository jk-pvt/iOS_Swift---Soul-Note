import SwiftUI

/// Legacy Family Tree - Spatial constellation of preserved voices
struct LegacyTreeView: View {
    @EnvironmentObject var storage: MockDataService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPerson: Person?
    @State private var showingContextSheet = false
    @State private var navigateToProfile: Person?
    @State private var navigateToStorybook: Person?
    
    let centerPerson: Person? // Optional center focus
    
    init(centerPerson: Person? = nil) {
        self.centerPerson = centerPerson
    }
    
    var body: some View {
        ZStack {
            LegacyTreeBackground()
            
            GeometryReader { geometry in
                ZStack {
                    ForEach(Array(nodePositions(in: geometry.size).enumerated()), id: \.offset) { index, position in
                        if index > 0 {
                            LegacyConnectorView(
                                startPoint: nodePositions(in: geometry.size)[0].position,
                                endPoint: position.position
                            )
                        }
                    }
                    
                    ForEach(nodePositions(in: geometry.size), id: \.person.id) { item in
                        LegacyNodeView(
                            person: item.person,
                            isSelected: selectedPerson?.id == item.person.id,
                            onTap: {
                                selectedPerson = item.person
                                showingContextSheet = true
                            }
                        )
                        .position(item.position)
                    }
                }
                .id(storage.people.count) // Force refresh when people count changes
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        HapticService.shared.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: Color.black.opacity(0.3), radius: 4)
                    }
                    .padding(24)
                    .padding(.top, 20)
                }
                Spacer()
            }
            
            VStack {
                Text("Legacy Tree")
                    .font(DesignTokens.heroTitle())
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 8)
                    .padding(.top, 60)
                Spacer()
            }
        }
        .sheet(isPresented: $showingContextSheet) {
            if let person = selectedPerson {
                LegacyContextSheet(
                    person: person,
                    onOpenMemories: {
                        navigateToProfile = person
                    },
                    onPlayStorybook: {
                        navigateToStorybook = person
                    }
                )
                .presentationDetents([.height(450)])
                .presentationDragIndicator(.hidden)
            }
        }
        .fullScreenCover(item: $navigateToProfile) { person in
            NavigationStack {
                ProfileView(person: person)
            }
        }
        .fullScreenCover(item: $navigateToStorybook) { person in
            NavigationStack {
                StorybookPlayerView(person: person)
            }
        }
    }
    
    // MARK: - Layout System
    
    private func nodePositions(in size: CGSize) -> [(person: Person, position: CGPoint)] {
        let people = storage.people
        guard !people.isEmpty else { return [] }
        
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        let center = centerPerson ?? people.first!
        
        let others = people.filter { $0.id != center.id }
        
        var positions: [(person: Person, position: CGPoint)] = []
        
        positions.append((person: center, position: CGPoint(x: centerX, y: centerY)))
        
        // Radial layout for others (max 11 additional nodes)
        let maxNodes = min(others.count, 11)
        let radius: CGFloat = 180
        let angleStep = (2 * .pi) / CGFloat(maxNodes)
        
        for (index, person) in others.prefix(maxNodes).enumerated() {
            let angle = angleStep * CGFloat(index) - .pi / 2 // Start from top
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * sin(angle)
            
            let offsetX = CGFloat.random(in: -15...15)
            let offsetY = CGFloat.random(in: -15...15)
            
            positions.append((
                person: person,
                position: CGPoint(x: x + offsetX, y: y + offsetY)
            ))
        }
        
        return positions
    }
}
