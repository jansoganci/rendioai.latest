//
//  VideoGenerationRequest.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

struct VideoGenerationRequest: Codable {
    let user_id: String
    let theme_id: String  // Changed from model_id
    let prompt: String
    let image_url: String?  // Required for Sora 2 (image-to-video models)
    let settings: VideoSettings
    
    enum CodingKeys: String, CodingKey {
        case user_id
        case theme_id  // Changed from model_id
        case prompt
        case image_url
        case settings
    }
    
    // MARK: - Preview Data
    
    static var preview: VideoGenerationRequest {
        VideoGenerationRequest(
            user_id: "preview-user-id",
            theme_id: "preview-theme-id",
            prompt: "A beautiful sunset over the ocean",
            image_url: nil,
            settings: VideoSettings.default
        )
    }
}
