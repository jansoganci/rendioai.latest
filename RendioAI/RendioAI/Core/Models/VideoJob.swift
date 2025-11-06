//
//  VideoJob.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation

struct VideoJob: Identifiable, Codable {
    let job_id: String
    let prompt: String
    let model_name: String
    let credits_used: Int
    let status: JobStatus
    let video_url: String?
    let thumbnail_url: String?
    let created_at: Date
    
    // MARK: - Identifiable
    
    var id: String {
        job_id
    }
    
    // MARK: - JobStatus Enum
    
    enum JobStatus: String, Codable {
        case pending = "pending"
        case processing = "processing"
        case completed = "completed"
        case failed = "failed"
    }
    
    // MARK: - CodingKeys
    
    enum CodingKeys: String, CodingKey {
        case job_id
        case prompt
        case model_name
        case credits_used
        case status
        case video_url
        case thumbnail_url
        case created_at
    }
    
    // MARK: - Convenience Properties
    
    var isPending: Bool {
        status == .pending
    }
    
    var isProcessing: Bool {
        status == .processing
    }
    
    var isCompleted: Bool {
        status == .completed
    }
    
    var isFailed: Bool {
        status == .failed
    }
    
    // MARK: - Date Decoding
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        job_id = try container.decode(String.self, forKey: .job_id)
        prompt = try container.decode(String.self, forKey: .prompt)
        model_name = try container.decode(String.self, forKey: .model_name)
        credits_used = try container.decode(Int.self, forKey: .credits_used)
        status = try container.decode(JobStatus.self, forKey: .status)
        video_url = try container.decodeIfPresent(String.self, forKey: .video_url)
        thumbnail_url = try container.decodeIfPresent(String.self, forKey: .thumbnail_url)
        
        // Decode date with ISO8601 format
        let dateString = try container.decode(String.self, forKey: .created_at)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            created_at = date
        } else {
            // Fallback to standard ISO8601
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                created_at = date
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: .created_at,
                    in: container,
                    debugDescription: "Invalid date format: \(dateString)"
                )
            }
        }
    }
    
    // MARK: - Initializer
    
    init(
        job_id: String,
        prompt: String,
        model_name: String,
        credits_used: Int,
        status: JobStatus,
        video_url: String? = nil,
        thumbnail_url: String? = nil,
        created_at: Date = Date()
    ) {
        self.job_id = job_id
        self.prompt = prompt
        self.model_name = model_name
        self.credits_used = credits_used
        self.status = status
        self.video_url = video_url
        self.thumbnail_url = thumbnail_url
        self.created_at = created_at
    }
}

// MARK: - Preview Data

extension VideoJob {
    static var previewCompleted: VideoJob {
        VideoJob(
            job_id: "preview-job-1",
            prompt: "A beautiful sunset over the ocean with waves crashing on the shore",
            model_name: "FalAI Veo 3.1",
            credits_used: 4,
            status: .completed,
            video_url: "https://cdn.supabase.com/video123.mp4",
            thumbnail_url: "https://cdn.supabase.com/thumb123.jpg",
            created_at: Date().addingTimeInterval(-86400) // 1 day ago
        )
    }
    
    static var previewProcessing: VideoJob {
        VideoJob(
            job_id: "preview-job-2",
            prompt: "Neon city lights reflecting on wet streets at night",
            model_name: "Sora 2",
            credits_used: 6,
            status: .processing,
            created_at: Date().addingTimeInterval(-3600) // 1 hour ago
        )
    }
    
    static var previewFailed: VideoJob {
        VideoJob(
            job_id: "preview-job-3",
            prompt: "A peaceful forest waterfall with birds flying",
            model_name: "Runway Gen-3 Alpha",
            credits_used: 5,
            status: .failed,
            created_at: Date().addingTimeInterval(-172800) // 2 days ago
        )
    }
    
    static var previewPending: VideoJob {
        VideoJob(
            job_id: "preview-job-4",
            prompt: "Aerial view of a mountain range at sunrise",
            model_name: "Pika 2.5",
            credits_used: 4,
            status: .pending,
            created_at: Date().addingTimeInterval(-1800) // 30 minutes ago
        )
    }
    
    static var previewList: [VideoJob] {
        [
            previewCompleted,
            previewProcessing,
            previewFailed,
            previewPending
        ]
    }
}
