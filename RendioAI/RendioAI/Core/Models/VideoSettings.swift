//
//  VideoSettings.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

struct VideoSettings: Codable {
    let duration: Int?      // Duration in seconds (8, 15, 30)
    let resolution: String? // Resolution: "720p" or "1080p"
    let aspect_ratio: String? // Aspect ratio: "auto", "9:16", "16:9"
    let fps: Int?           // Frames per second (24, 30, 60) - Frontend only, not sent to backend
    
    enum CodingKeys: String, CodingKey {
        case duration
        case resolution
        case aspect_ratio
        case fps
    }
    
    // MARK: - Default Values
    
    static var `default`: VideoSettings {
        VideoSettings(
            duration: 15,
            resolution: "720p",
            aspect_ratio: "auto",
            fps: 30
        )
    }
    
    // MARK: - Preview Data
    
    static var preview: VideoSettings {
        VideoSettings(
            duration: 15,
            resolution: "720p",
            aspect_ratio: "auto",
            fps: 30
        )
    }
}
