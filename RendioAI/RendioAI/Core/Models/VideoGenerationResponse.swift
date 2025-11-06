//
//  VideoGenerationResponse.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

struct VideoGenerationResponse: Codable {
    let job_id: String
    let status: String      // "pending", "processing", "completed", "failed"
    let credits_used: Int
    
    enum CodingKeys: String, CodingKey {
        case job_id
        case status
        case credits_used
    }
    
    // MARK: - Convenience
    
    var isPending: Bool {
        status == "pending"
    }
    
    var isProcessing: Bool {
        status == "processing"
    }
    
    var isCompleted: Bool {
        status == "completed"
    }
    
    var isFailed: Bool {
        status == "failed"
    }
    
    // MARK: - Preview Data
    
    static var preview: VideoGenerationResponse {
        VideoGenerationResponse(
            job_id: "preview-job-id",
            status: "pending",
            credits_used: 4
        )
    }
}
