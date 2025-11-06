//
//  ImagePickerView.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import SwiftUI
import PhotosUI

struct ImagePickerView: View {
    @Binding var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    let isRequired: Bool
    let isEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Label
            HStack {
                Text(NSLocalizedString("model_detail.image_label", comment: "Image"))
                    .font(.headline)
                    .foregroundColor(Color("TextPrimary"))
                
                if isRequired {
                    Text("*")
                        .foregroundColor(Color("AccentError"))
                }
            }
            
            // Image picker button or preview
            if let image = selectedImage {
                // Show selected image with remove option
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                    
                    // Remove button
                    Button(action: {
                        selectedImage = nil
                        selectedItem = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(8)
                    .disabled(!isEnabled)
                }
            } else {
                // Show picker button
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                            .font(.title3)
                            .foregroundColor(Color("BrandPrimary"))
                        
                        Text(NSLocalizedString("model_detail.select_image", comment: "Select Image"))
                            .font(.body)
                            .foregroundColor(Color("TextPrimary"))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Color("TextSecondary"))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color("SurfaceCard"))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isRequired ? Color("AccentError").opacity(0.3) : Color("BorderDefault").opacity(0.3),
                                lineWidth: 1
                            )
                    )
                }
                .disabled(!isEnabled)
            }
            
            // Helper text
            if isRequired && selectedImage == nil {
                Text(NSLocalizedString("model_detail.image_required", comment: "Image is required"))
                    .font(.caption)
                    .foregroundColor(Color("AccentError"))
            }
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            Task {
                if let newValue = newValue {
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImage = image
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("No Image Selected") {
    ImagePickerView(
        selectedImage: .constant(nil),
        isRequired: true,
        isEnabled: true
    )
    .padding()
    .background(Color("SurfaceBase"))
}

#Preview("Image Selected") {
    ImagePickerView(
        selectedImage: .constant(UIImage(systemName: "photo")),
        isRequired: true,
        isEnabled: true
    )
    .padding()
    .background(Color("SurfaceBase"))
}

