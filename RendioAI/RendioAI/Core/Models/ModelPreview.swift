//
//  ModelPreview.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

struct ModelPreview: Identifiable, Codable {
    let id: String
    let name: String
    let category: String
    let thumbnailURL: URL?
    let isFeatured: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case thumbnailURL = "thumbnail_url"
        case isFeatured = "is_featured"
    }
}

// MARK: - Preview Data
extension ModelPreview {
    static var preview: ModelPreview {
        ModelPreview(
            id: "preview-1",
            name: "FalAI Veo 3.1",
            category: "Text-to-Video",
            thumbnailURL: nil,
            isFeatured: true
        )
    }

    static var previewModels: [ModelPreview] {
        [
            ModelPreview(
                id: "1",
                name: "FalAI Veo 3.1",
                category: "Text-to-Video",
                thumbnailURL: nil,
                isFeatured: true
            ),
            ModelPreview(
                id: "2",
                name: "Sora 2",
                category: "Image-to-Video",
                thumbnailURL: nil,
                isFeatured: true
            ),
            ModelPreview(
                id: "3",
                name: "Runway Gen-3 Alpha",
                category: "Video Generation",
                thumbnailURL: nil,
                isFeatured: false
            ),
            ModelPreview(
                id: "4",
                name: "Pika 2.5",
                category: "Video Editing",
                thumbnailURL: nil,
                isFeatured: false
            )
        ]
    }
}
