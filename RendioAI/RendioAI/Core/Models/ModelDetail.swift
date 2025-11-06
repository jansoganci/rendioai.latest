//
//  ModelDetail.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

struct ModelDetail: Identifiable, Codable {
    let id: String
    let name: String
    let category: String
    let description: String?
    let thumbnailURL: URL?
    let isFeatured: Bool
    let costPerGeneration: Int?
    let requiredFields: ModelRequirements?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case description
        case thumbnailURL = "thumbnail_url"
        case isFeatured = "is_featured"
        case costPerGeneration = "cost_per_generation"
        case requiredFields = "required_fields"
    }
    
    // MARK: - Convenience Initializer from ModelPreview
    
    init(from preview: ModelPreview, description: String? = nil, costPerGeneration: Int? = nil, requiredFields: ModelRequirements? = nil) {
        self.id = preview.id
        self.name = preview.name
        self.category = preview.category
        self.description = description
        self.thumbnailURL = preview.thumbnailURL
        self.isFeatured = preview.isFeatured
        self.costPerGeneration = costPerGeneration
        self.requiredFields = requiredFields
    }
    
    // MARK: - Full Initializer
    
    init(
        id: String,
        name: String,
        category: String,
        description: String?,
        thumbnailURL: URL?,
        isFeatured: Bool,
        costPerGeneration: Int?,
        requiredFields: ModelRequirements? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.thumbnailURL = thumbnailURL
        self.isFeatured = isFeatured
        self.costPerGeneration = costPerGeneration
        self.requiredFields = requiredFields
    }
    
    // MARK: - Preview Data
    
    static var preview: ModelDetail {
        ModelDetail(
            id: "preview-1",
            name: "FalAI Veo 3.1",
            category: "Text-to-Video",
            description: "Generate realistic cinematic videos from simple text prompts. Perfect for creating stunning visual narratives with AI-powered video generation.",
            thumbnailURL: nil,
            isFeatured: true,
            costPerGeneration: 4
        )
    }
}
