import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var storage: MockDataService
    @State private var showAddPersonSheet = false
    @State private var selectedPerson: Person?
    @State private var showingTimeline = false
    @State private var showingLegacyTree = false
    @State private var animateCards = false
    
    private let rotations: [Double] = [-3, 2, -1, 3, -2, 1, -4, 2]
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.archiveBackground
                    .ignoresSafeArea()
                
                FilmGrainTexture(opacity: 0.08)
                    .blur(radius: 3)
                    .ignoresSafeArea()
                    .blendMode(.softLight)
                
                VStack(spacing: 0) {
                    VStack(spacing: 6) {
                        Text("SoulNote")
                            .font(DesignTokens.appName())
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 4, y: 2)
                        
                        Text("Heartfelt thoughts from the soul")
                            .font(DesignTokens.tagline())
                            .foregroundColor(.white.opacity(0.8))
                            .italic()
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity)
                    .background(
                        DesignTokens.glassMaterial(opacity: 0.15)
                            .edgesIgnoringSafeArea(.top)
                    )
                    
                    if storage.people.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            LazyVGrid(
                                columns: [
                                    GridItem(.adaptive(minimum: 280, maximum: 280), spacing: 20)
                                ],
                                spacing: 20
                            ) {
                                ForEach(Array(storage.people.enumerated()), id: \.element.id) { index, person in
                                    ArchivalMemoryCard(
                                        person: person,
                                        index: index
                                    ) {
                                        selectedPerson = person
                                    }
                                    .opacity(animateCards ? 1 : 0.01) // 0.01 instead of 0 for safety
                                    .offset(y: animateCards ? 0 : 15)
                                    .scaleEffect(animateCards ? 1 : 0.95)
                                    .animation(
                                        DesignTokens.gentleSpring.delay(Double(index) * 0.15),
                                        value: animateCards
                                    )
                                }
                            }
                            .padding(24)
                            .padding(.bottom, 40)
                        }
                    }
                }
                
            }
            .onAppear {
                // Use a small delay to ensure the view transition is stable before animating
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateCards = true
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        HapticService.shared.light()
                        showAddPersonSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        HapticService.shared.light()
                        showingTimeline = true
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        HapticService.shared.light()
                        showingLegacyTree = true
                    }) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .sheet(isPresented: $showAddPersonSheet) {
                AddPersonView()
            }
            .sheet(isPresented: $showingTimeline) {
                NavigationStack {
                    MemoryTimelineView()
                }
            }
            .sheet(item: $selectedPerson) { person in
                NavigationStack {
                    ProfileView(person: person)
                }
            }
            .fullScreenCover(isPresented: $showingLegacyTree) {
                LegacyTreeView()
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
    
    @State private var iconFloat = false
    
    private var emptyStateView: some View {
        VStack(spacing: 36) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(DesignTokens.amberGlow.opacity(0.12))
                    .frame(width: 140, height: 140)
                    .blur(radius: 24)
                
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 80))
                    .foregroundColor(DesignTokens.amberGlow.opacity(0.9))
                    .shadow(color: DesignTokens.amberGlow.opacity(0.4), radius: 12)
                    .offset(y: iconFloat ? -8 : 8)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: iconFloat)
            }
            .onAppear { iconFloat = true }
            
            VStack(spacing: 16) {
                Text("Your Soul Collection")
                    .font(DesignTokens.heroTitle())
                    .foregroundColor(.white)
                
                Text("Preserve the voices and stories\nof your loved ones")
                    .font(DesignTokens.bodyText())
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            
            Button(action: { 
                HapticService.shared.light()
                showAddPersonSheet = true 
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Add Your First Memory")
                        .font(DesignTokens.bodyText().weight(.semibold))
                }
                .foregroundColor(Color(red: 0.18, green: 0.16, blue: 0.15))
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(DesignTokens.ivoryPaper)
                        .shadow(color: Color.black.opacity(0.3), radius: 15, y: 8)
                )
            }
            .padding(.top, 8)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
}

struct AddPersonView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storage: MockDataService
    
    @State private var name = ""
    @State private var relationship = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button(action: { showingImagePicker = true }) {
                        HStack {
                            Spacer()
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.system(size: 60))
                                        .foregroundColor(DesignTokens.nostalgiaAccent)
                                    Text("Add Photo")
                                        .font(DesignTokens.metadata())
                                        .foregroundColor(DesignTokens.nostalgiaAccent)
                                }
                                .frame(height: 120)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(Color.clear)
                
                Section("Details") {
                    TextField("Name", text: $name)
                        .font(DesignTokens.bodyText())
                    
                    TextField("Relationship (e.g., Grandfather)", text: $relationship)
                        .font(DesignTokens.bodyText())
                }
            }
            .scrollContentBackground(.hidden)
            .background(DesignTokens.memoryPaper)
            .navigationTitle("Add Loved One")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { savePerson() }
                        .disabled(name.isEmpty || relationship.isEmpty)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
    
    private func savePerson() {
        var photoPath: String?
        
        if let image = selectedImage,
           let data = image.jpegData(compressionQuality: 0.7) {
            let path = FileManager.generatePhotoPath()
            try? data.write(to: URL(fileURLWithPath: path))
            photoPath = path
        }
        
        let person = Person(name: name, photoPath: photoPath, relationship: relationship)
        storage.addPerson(person)
        dismiss()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
