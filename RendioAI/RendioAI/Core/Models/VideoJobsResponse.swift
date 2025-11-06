//
//  VideoJobsResponse.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

struct VideoJobsResponse: Codable {
    let jobs: [VideoJob]
    
    // MARK: - CodingKeys
    
    enum CodingKeys: String, CodingKey {
        case jobs
    }
    
    // MARK: - Initializer
    
    init(jobs: [VideoJob]) {
        self.jobs = jobs
    }
}

// MARK: - Preview Data

extension VideoJobsResponse {
    static var preview: VideoJobsResponse {
        VideoJobsResponse(jobs: VideoJob.previewList)
    }
}
