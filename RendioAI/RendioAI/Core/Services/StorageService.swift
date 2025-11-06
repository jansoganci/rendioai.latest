//
//  StorageService.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import Foundation
import Photos
import UIKit

// MARK: - StorageService Protocol

protocol StorageServiceProtocol {
    /// Downloads video from URL to temporary directory
    /// - Parameter url: The video URL to download
    /// - Returns: Local file URL where video is saved
    func downloadVideo(url: URL) async throws -> URL
    
    /// Saves video file to Photos library
    /// - Parameter fileURL: Local file URL of the video
    /// - Throws: Error if permission denied or save fails
    func saveToPhotosLibrary(fileURL: URL) async throws
    
    /// Checks Photos library authorization status
    /// - Returns: Current authorization status
    func checkPhotosAuthorization() -> PHAuthorizationStatus
    
    /// Requests Photos library authorization
    /// - Returns: Authorization status after request
    func requestPhotosAuthorization() async -> PHAuthorizationStatus
}

// MARK: - StorageService Implementation

class StorageService: StorageServiceProtocol {
    static let shared = StorageService()
    
    private init() {}
    
    // MARK: - Download Video
    
    func downloadVideo(url: URL) async throws -> URL {
        // Validate URL
        guard url.scheme == "http" || url.scheme == "https" else {
            throw AppError.invalidResponse
        }
        
        // Create temporary directory if needed
        let tempDir = FileManager.default.temporaryDirectory
        let videoFileName = "video_\(UUID().uuidString).mp4"
        let localURL = tempDir.appendingPathComponent(videoFileName)
        
        // Download video data
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.networkFailure
        }
        
        // Validate data
        guard !data.isEmpty else {
            throw AppError.invalidResponse
        }
        
        // Save to temporary file
        try data.write(to: localURL)
        
        return localURL
    }
    
    // MARK: - Save to Photos Library
    
    func saveToPhotosLibrary(fileURL: URL) async throws {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw AppError.invalidResponse
        }
        
        // Note: Authorization should be checked and requested by the caller
        // before calling this method. We only verify the current status here.
        let status = checkPhotosAuthorization()
        
        guard status == .authorized || status == .limited else {
            throw AppError.unauthorized
        }
        
        // Save to Photos library
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }
    }
    
    // MARK: - Photos Authorization
    
    func checkPhotosAuthorization() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }
    
    func requestPhotosAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    }
}

// MARK: - Mock Service for Testing

class MockStorageService: StorageServiceProtocol {
    var shouldThrowError = false
    var errorToThrow: Error = AppError.networkFailure
    var authorizationStatus: PHAuthorizationStatus = .authorized
    var downloadDelay: TimeInterval = 0.5
    
    func downloadVideo(url: URL) async throws -> URL {
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Simulate download delay
        try await Task.sleep(for: .seconds(downloadDelay))
        
        // Create mock local file URL
        let tempDir = FileManager.default.temporaryDirectory
        let videoFileName = "mock_video_\(UUID().uuidString).mp4"
        let localURL = tempDir.appendingPathComponent(videoFileName)
        
        // Create empty file for testing
        FileManager.default.createFile(atPath: localURL.path, contents: Data(), attributes: nil)
        
        return localURL
    }
    
    func saveToPhotosLibrary(fileURL: URL) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Check authorization
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            throw AppError.unauthorized
        }
        
        // Simulate save delay
        try await Task.sleep(for: .seconds(0.3))
        
        // In real implementation, this would save to Photos library
        // For mock, we just verify the file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw AppError.invalidResponse
        }
    }
    
    func checkPhotosAuthorization() -> PHAuthorizationStatus {
        authorizationStatus
    }
    
    func requestPhotosAuthorization() async -> PHAuthorizationStatus {
        // Simulate authorization delay
        try? await Task.sleep(for: .seconds(0.2))
        return authorizationStatus
    }
}

