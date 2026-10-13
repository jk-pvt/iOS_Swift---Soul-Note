import SwiftUI

struct ProfileView: View {
    let person: Person
    @EnvironmentObject var storage: MockDataService
    @State private var showingRecordMemory = false
    @State private var showingWriteLetter = false
    @State private var showingStorybook = false
    @State private var showingAddPhoto = false
    @State private var selectedMemory: Memory?
    @State private var showingDeleteAlert = false
    @State private var showingLegacyTree = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
        ScrollView {
            VStack(spacing: 24) {
                if let photoPath = person.photoPath,
                   let uiImage = UIImage.loadFromAssetOrBundle(photoPath) {
                    ZStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 300)
                            .blur(radius: 20)
                            .opacity(0.3)
                        
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                            .shadow(color: DesignTokens.glowShadow, radius: 20)
                    }
                    .frame(height: 300)
                    .clipped()
                }
                
                VStack(spacing: 8) {
                    Text(person.name)
                        .font(DesignTokens.heroTitle())
                        .foregroundColor(DesignTokens.archiveBrown)
                    
                    Text(person.relationship)
                        .font(DesignTokens.metadata())
                        .foregroundColor(DesignTokens.archiveBrown.opacity(0.7))
                }
                .padding(.top, 16)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    PrimaryActionButton(title: "Record Memory", icon: "mic.fill") {
                        showingRecordMemory = true
                    }
                    
                    PrimaryActionButton(title: "Write Letter", icon: "envelope.fill") {
                        showingWriteLetter = true
                    }
                    
                    PrimaryActionButton(title: "Add Photo", icon: "photo.fill") {
                        showingAddPhoto = true
                    }
                    
                    PrimaryActionButton(title: "Storybook", icon: "book.fill") {
                        HapticService.shared.medium()
                        showingStorybook = true
                    }
                }
                .padding(.horizontal)
                
                if !storage.memories(for: person).isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Memories")
                            .font(DesignTokens.nameDisplay())
                            .foregroundColor(DesignTokens.archiveBrown)
                            .padding(.horizontal)
                        
                        ForEach(storage.memories(for: person)) { memory in
                            Button(action: { selectedMemory = memory }) {
                                MemoryRow(memory: memory)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteMemory(memory)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.top, 24)
                }
                
                if !storage.letters(for: person).isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Letters")
                            .font(DesignTokens.nameDisplay())
                            .foregroundColor(DesignTokens.archiveBrown)
                            .padding(.horizontal)
                        
                        ForEach(storage.letters(for: person)) { letter in
                            LetterRow(letter: letter)
                        }
                    }
                    .padding(.top, 24)
                }
            }
            .padding(.bottom, 40)
        }
        .background(DesignTokens.memoryPaper)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    HapticService.shared.light()
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignTokens.nostalgiaAccent)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    HapticService.shared.light()
                    showingLegacyTree = true
                }) {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(DesignTokens.nostalgiaAccent)
                }
            }
            
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Delete Profile?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePerson()
            }
        } message: {
            Text("This will permanently delete \(person.name)'s profile and all associated memories and letters. This action cannot be undone.")
        }
        .sheet(isPresented: $showingRecordMemory) {
            RecordMemoryView(person: person)
        }
        .sheet(isPresented: $showingWriteLetter) {
            LetterEditorView(person: person)
        }
        .sheet(isPresented: $showingAddPhoto) {
            AddPhotoMemoryView(person: person)
        }
        .sheet(item: $selectedMemory) { memory in
            MemoryDetailView(memory: memory)
        }
        .fullScreenCover(isPresented: $showingStorybook) {
            StorybookPlayerView(person: person)
        }
        .fullScreenCover(isPresented: $showingLegacyTree) {
            LegacyTreeView(centerPerson: person)
        }
        .onChange(of: showingRecordMemory) { isShowing in
            if !isShowing {
            }
        }
        .onChange(of: showingWriteLetter) { isShowing in
            if !isShowing {
            }
        }
    }

    private func deleteMemory(_ memory: Memory) {
        storage.deleteMemory(memory)
    }
    
    private func deletePerson() {
        storage.deletePerson(person)
        dismiss()
    }
}

struct MemoryRow: View {
    let memory: Memory
    
    var body: some View {
        HStack(spacing: 16) {
            if let photoPath = memory.photoPath,
               let uiImage = UIImage.loadFromAssetOrBundle(photoPath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignTokens.nostalgiaAccent.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "waveform")
                            .foregroundColor(DesignTokens.nostalgiaAccent)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(memory.title)
                    .font(DesignTokens.bodyText())
                    .foregroundColor(DesignTokens.archiveBrown)
                
                HStack {
                    Text(memory.emotionTag.rawValue)
                        .font(DesignTokens.metadata())
                        .foregroundColor(DesignTokens.nostalgiaAccent)
                    
                    Text("•")
                        .foregroundColor(DesignTokens.archiveBrown.opacity(0.5))
                    
                    Text(memory.createdAt.relativeString())
                        .font(DesignTokens.metadata())
                        .foregroundColor(DesignTokens.archiveBrown.opacity(0.7))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(DesignTokens.archiveBrown.opacity(0.3))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4)
        )
        .padding(.horizontal)
    }
}

struct LetterRow: View {
    let letter: Letter
    @State private var showUnlockRitual = false
    @EnvironmentObject var storage: MockDataService
    
    var body: some View {
        Button(action: {
            if letter.currentState == .delivered || letter.isReadyForDelivery {
                HapticService.shared.medium()
                showUnlockRitual = true
            }
        }) {
            HStack(spacing: 12) {
                stateIcon
                    .font(.system(size: 24))
                    .foregroundColor(stateColor)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(stateColor.opacity(0.15))
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(letter.isHandwritten ? letter.displayContent : String(letter.content.prefix(100)) + (letter.content.count > 100 ? "..." : ""))
                        .font(DesignTokens.letterText())
                        .foregroundColor(DesignTokens.archiveBrown)
                        .lineLimit(2)
                    
                    stateSubtitle
                        .font(DesignTokens.metadata())
                        .foregroundColor(stateColor)
                }
                
                Spacer()
                
                if letter.currentState == .delivered || letter.isReadyForDelivery {
                    Image(systemName: "chevron.right")
                        .foregroundColor(DesignTokens.amberGlow)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            )
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showUnlockRitual) {
            if let person = storage.people.first(where: { $0.id == letter.personId }) {
                LetterDeliveryUnlockView(
                    letter: letter,
                    personName: person.name,
                    onComplete: {
                        showUnlockRitual = false
                    }
                )
            }
        }
    }
    
    // MARK: - State UI Components
    
    private var stateIcon: Image {
        switch letter.currentState {
        case .scheduled:
            return Image(systemName: "clock.fill")
        case .delivered:
            return Image(systemName: "envelope.badge.fill")
        case .opened:
            return Image(systemName: "envelope.open.fill")
        case .preserved:
            return Image(systemName: "archivebox.fill")
        }
    }
    
    private var stateColor: Color {
        switch letter.currentState {
        case .scheduled:
            return DesignTokens.nostalgiaAccent
        case .delivered:
            return DesignTokens.amberGlow
        case .opened:
            return DesignTokens.archiveBrown.opacity(0.7)
        case .preserved:
            return DesignTokens.archiveBrown.opacity(0.5)
        }
    }
    
    private var stateSubtitle: Text {
        switch letter.currentState {
        case .scheduled:
            if let days = letter.daysUntilDelivery {
                if days == 0 {
                    return Text("Delivers today")
                } else if days == 1 {
                    return Text("Delivers tomorrow")
                } else {
                    return Text("Delivers in \(days) days")
                }
            } else if let deliveryDate = letter.deliveryDate {
                return Text("Delivers on \(deliveryDate.timelineString())")
            }
            return Text("Scheduled")
            
        case .delivered:
            return Text("Ready to open • Tap to unlock")
            
        case .opened:
            if let openedAt = letter.openedAt {
                return Text("Opened \(openedAt.relativeString())")
            }
            return Text("Opened")
            
        case .preserved:
            return Text("Preserved memory")
        }
    }
}

