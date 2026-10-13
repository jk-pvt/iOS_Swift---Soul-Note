import SwiftUI

struct MemoryTimelineView: View {
    @EnvironmentObject var storage: MockDataService
    @State private var searchText = ""
    @State private var selectedEmotion: EmotionTag?
    @State private var selectedMemory: Memory?
    
    var filteredMemories: [Memory] {
        var memories = storage.allMemories
        
        if !searchText.isEmpty {
            memories = memories.filter { memory in
                memory.title.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let emotion = selectedEmotion {
            memories = memories.filter { $0.emotionTag == emotion }
        }
        
        return memories.sorted { $0.createdAt > $1.createdAt }
    }
    
    var groupedMemories: [(String, [Memory])] {
        let grouped = Dictionary(grouping: filteredMemories) { memory in
            memory.createdAt.formatted(date: .abbreviated, time: .omitted)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        ZStack {
            DesignTokens.archiveBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.6))
                    
                    TextField("Search memories...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .accentColor(DesignTokens.amberGlow)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.horizontal)
                .padding(.top, 8)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button(action: {
                            HapticService.shared.light()
                            selectedEmotion = nil
                        }) {
                            Text("All")
                                .font(DesignTokens.metadata())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedEmotion == nil ? DesignTokens.amberGlow : Color.white.opacity(0.15))
                                )
                                .foregroundColor(selectedEmotion == nil ? Color(red: 0.08, green: 0.08, blue: 0.08) : .white.opacity(0.7))
                        }
                        
                        ForEach(EmotionTag.allCases, id: \.self) { emotion in
                            Button(action: {
                                HapticService.shared.light()
                                selectedEmotion = emotion
                            }) {
                                Text(emotion.rawValue)
                                    .font(DesignTokens.metadata())
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedEmotion == emotion ? DesignTokens.amberGlow.opacity(0.8) : Color.white.opacity(0.15))
                                    )
                                    .foregroundColor(selectedEmotion == emotion ? Color(red: 0.08, green: 0.08, blue: 0.08) : .white.opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                
                if filteredMemories.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(filteredMemories.enumerated()), id: \.element.id) { index, memory in
                                MemorySpineItem(
                                    memory: memory,
                                    isFirst: index == 0,
                                    isLast: index == filteredMemories.count - 1
                                ) {
                                    selectedMemory = memory
                                }
                            }
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $selectedMemory) { memory in
            MemoryDetailView(memory: memory)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: searchText.isEmpty ? "clock.arrow.circlepath" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(DesignTokens.amberGlow.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Memories Yet" : "No Results")
                    .font(DesignTokens.nameDisplay())
                    .foregroundColor(.white)
                
                Text(searchText.isEmpty ? "Start recording memories to see them here" : "Try a different search term")
                    .font(DesignTokens.bodyText())
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    MemoryTimelineView()
        .environmentObject(MockDataService.shared)
}

struct MemorySpineItem: View {
    let memory: Memory
    let isFirst: Bool
    let isLast: Bool
    let action: () -> Void
    @EnvironmentObject var storage: MockDataService
    
    var person: Person? {
        storage.people.first { $0.id == memory.personId }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(DesignTokens.softSepia)
                        .frame(width: 2, height: 30)
                }
                
                Circle()
                    .fill(DesignTokens.amberGlow)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(DesignTokens.archiveBackground, lineWidth: 3)
                    )
                
                if !isLast {
                    Rectangle()
                        .fill(DesignTokens.softSepia)
                        .frame(width: 2)
                        .frame(minHeight: 80)
                }
            }
            .frame(width: 40)
            .padding(.leading, 24)
            
            Button(action: {
                HapticService.shared.light()
                action()
            }) {
                HStack(spacing: 12) {
                    if let photoPath = memory.photoPath,
                       let uiImage = UIImage.loadFromAssetOrBundle(photoPath) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignTokens.ivoryPaper.opacity(0.1))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "waveform")
                                    .font(.system(size: 24))
                                    .foregroundColor(DesignTokens.amberGlow.opacity(0.6))
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(memory.title)
                            .font(DesignTokens.bodyText().weight(.medium))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        if let person = person {
                            Text(person.name)
                                .font(DesignTokens.metadata())
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        HStack(spacing: 6) {
                            Text(memory.emotionTag.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("•")
                                .foregroundColor(.white.opacity(0.4))
                            
                            Text(memory.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius)
                        .fill(Color.white.opacity(0.08))
                )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 24)
            .padding(.bottom, isLast ? 0 : 8)
        }
    }
}

struct TimelineMemoryCard: View {
    let memory: Memory
    let action: () -> Void
    @EnvironmentObject var storage: MockDataService
    
    var person: Person? {
        storage.people.first { $0.id == memory.personId }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if let photoPath = memory.photoPath,
                   let uiImage = UIImage.loadFromAssetOrBundle(photoPath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "waveform")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(memory.title)
                        .font(DesignTokens.bodyText().weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    if let person = person {
                        Text(person.name)
                            .font(DesignTokens.metadata())
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    HStack(spacing: 8) {
                        Text(memory.emotionTag.rawValue)
                            .font(DesignTokens.metadata())
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text(memory.createdAt.formatted(date: .omitted, time: .shortened))
                            .font(DesignTokens.metadata())
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.15))
            )
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}
