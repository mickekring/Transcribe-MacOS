import Foundation
import SwiftUI
import YouTubeKit
import AVFoundation
@MainActor
class YouTubeDownloadService: ObservableObject {
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var videoTitle: String?
    @Published var videoThumbnailURL: URL?
    @Published var videoDuration: String?
    @Published var downloadedFileURL: URL?
    
    func fetchVideoInfo(from urlString: String) async throws -> (title: String, thumbnailURL: URL?, duration: String?) {
        guard let videoID = extractVideoID(from: urlString) else {
            throw YouTubeError.invalidURL
        }
        
        // Get thumbnail URL - try different resolutions
        let thumbnailURL = URL(string: "https://img.youtube.com/vi/\(videoID)/maxresdefault.jpg") ??
                           URL(string: "https://img.youtube.com/vi/\(videoID)/hqdefault.jpg")
        
        // Try to fetch title from YouTube page
        var title = "YouTube Video"
        if let pageTitle = await fetchVideoTitleFromPage(videoID: videoID) {
            title = pageTitle
        }
        
        // Duration is not directly available, return nil for now
        let duration: String? = nil
        
        return (
            title: title,
            thumbnailURL: thumbnailURL,
            duration: duration
        )
    }
    
    private func fetchVideoTitleFromPage(videoID: String) async -> String? {
        let urlString = "https://www.youtube.com/watch?v=\(videoID)"
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            
            // Try to extract title from meta tags
            if let titleRange = html.range(of: "<title>") {
                let afterTitle = html[titleRange.upperBound...]
                if let endRange = afterTitle.range(of: "</title>") {
                    var title = String(afterTitle[..<endRange.lowerBound])
                    // Remove " - YouTube" suffix
                    title = title.replacingOccurrences(of: " - YouTube", with: "")
                    return title
                }
            }
            
            // Alternative: Try meta property
            if let metaRange = html.range(of: "property=\"og:title\" content=\"") {
                let afterMeta = html[metaRange.upperBound...]
                if let endRange = afterMeta.range(of: "\"") {
                    return String(afterMeta[..<endRange.lowerBound])
                }
            }
        } catch {
            print("⚠️ Failed to fetch video title: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    private func formatDuration(seconds: Int?) -> String? {
        guard let seconds = seconds else { return nil }
        
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    func downloadVideoForTranscription(from urlString: String) async throws -> URL {
        guard let videoID = extractVideoID(from: urlString) else {
            throw YouTubeError.invalidURL
        }
        
        await MainActor.run {
            isDownloading = true
            downloadProgress = 0.0
            errorMessage = nil
        }
        
        defer { 
            Task { @MainActor in
                isDownloading = false
            }
        }
        
        // Use only local method, no fallback
        let video = YouTube(videoID: videoID, methods: [.local])
        
        do {
            // Get all available streams
            let streams = try await video.streams
            
            // Debug: print available stream counts
            print("\n📊 Available streams for video ID: \(videoID)")
            print("  - Total streams: \(streams.count)")
            print("  - Audio-only streams: \(streams.filterAudioOnly().count)")
            print("  - Video-only streams: \(streams.filterVideoOnly().count)")
            print("  - Video+Audio streams: \(streams.filterVideoAndAudio().count)")
            
            // List all audio streams with details
            print("\n🎵 Audio-only streams available:")
            for (index, stream) in streams.filterAudioOnly().enumerated() {
                print("  Audio stream \(index):")
                print("    - Format: \(stream.fileExtension.rawValue)")
                print("    - URL length: \(stream.url.absoluteString.count) chars")
            }
            
            // List video streams sorted by resolution
            print("\n📹 Video streams available:")
            let videoStreams = streams.filterVideoOnly() + streams.filterVideoAndAudio()
            for (index, stream) in videoStreams.prefix(5).enumerated() {
                print("  Video stream \(index):")
                print("    - Format: \(stream.fileExtension.rawValue)")
                print("    - Has audio: \(stream.includesVideoAndAudioTrack)")
            }
            
            // Prioritize audio-only streams for fastest download and transcription
            let targetStream: YouTubeKit.Stream
            
            // First try to get audio-only stream (much smaller, faster)
            let audioStreams = streams.filterAudioOnly()
            if !audioStreams.isEmpty {
                // Prefer M4A format for best compatibility
                if let m4aStream = audioStreams.first(where: { $0.fileExtension == .m4a }) {
                    targetStream = m4aStream
                    print("\n✅ SELECTED: M4A audio-only stream")
                } else {
                    // Use any audio stream
                    targetStream = audioStreams.first!
                    print("\n✅ SELECTED: Audio-only stream (\(targetStream.fileExtension.rawValue))")
                }
            } else {
                // If no audio-only, get the lowest resolution video
                // Use the built-in method that finds the lowest resolution
                if let lowestVideo = streams.lowestResolutionStream() {
                    targetStream = lowestVideo
                    print("\n✅ SELECTED: Lowest resolution video stream")
                } else if let anyStream = streams.first {
                    targetStream = anyStream
                    print("\n⚠️ SELECTED: First available stream (fallback)")
                } else {
                    throw YouTubeError.noSuitableStream
                }
            }
            
            print("📥 Download URL: \(targetStream.url.absoluteString.prefix(100))...")
            print("📦 File type: \(targetStream.fileExtension.rawValue)")
            print("🎬 Has video+audio: \(targetStream.includesVideoAndAudioTrack)")
            
            return try await downloadStream(targetStream, videoID: videoID)
            
        } catch {
            // If YouTubeKit fails, it means YouTube changed their API
            throw YouTubeError.noFallbackAllowed
        }
    }
    
    private func downloadStream(_ stream: YouTubeKit.Stream, videoID: String) async throws -> URL {
        // Log stream details for debugging
        print("\n🚀 Starting download:")
        print("  - File extension: \(stream.fileExtension.rawValue)")
        print("  - Has video+audio: \(stream.includesVideoAndAudioTrack)")
        
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("Transcribe")
            .appendingPathComponent("YouTube")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: tempDir, 
                                                withIntermediateDirectories: true, 
                                                attributes: nil)
        
        let fileExtension = stream.fileExtension.rawValue
        let fileName = "youtube_\(videoID).\(fileExtension)"
        let localURL = tempDir.appendingPathComponent(fileName)
        
        // Debug logging
        print("\n📹 ========== YOUTUBE STORAGE DEBUG ==========")
        print("📁 Storage Type: TEMPORARY (auto-cleanup on app quit)")
        print("📍 Full Path: \(localURL.path)")
        print("📂 Directory: \(tempDir.path)")
        print("🗑️ Auto-cleanup: YES - File will be deleted when app quits")
        print("🎬 Video ID: \(videoID)")
        print("📦 File Format: \(fileExtension)")
        print("⏰ Download started: \(Date())")
        print("=============================================\n")
        
        // Remove existing file if present
        try? FileManager.default.removeItem(at: localURL)
        
        // Use simple URLSession without custom headers that might break YouTube
        let session = URLSession.shared
        
        let startTime = Date()
        var lastDownloadedBytes: Int64 = 0
        
        print("⏬ Starting download from: \(stream.url.absoluteString.prefix(100))...")
        
        // First, get the file size with a HEAD request
        var headRequest = URLRequest(url: stream.url)
        headRequest.httpMethod = "HEAD"
        
        let (_, headResponse) = try await session.data(for: headRequest)
        let totalSize = headResponse.expectedContentLength
        
        if totalSize > 0 {
            print("📏 Total file size: \(String(format: "%.2f MB", Double(totalSize) / (1024 * 1024)))")
            
            // Download in 2MB chunks to avoid throttling
            let chunkSize: Int64 = 2 * 1024 * 1024  // 2MB chunks as recommended in GitHub issue
            var downloadedData = Data()
            var currentOffset: Int64 = 0
            
            while currentOffset < totalSize {
                let endOffset = min(currentOffset + chunkSize - 1, totalSize - 1)
                
                // Create range request
                var request = URLRequest(url: stream.url)
                request.setValue("bytes=\(currentOffset)-\(endOffset)", forHTTPHeaderField: "Range")
                
                do {
                    let (chunkData, response) = try await session.data(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...206).contains(httpResponse.statusCode) else {
                        print("❌ Chunk download failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                        throw YouTubeError.downloadFailed
                    }
                    
                    downloadedData.append(chunkData)
                    currentOffset = endOffset + 1
                    
                    // Update progress
                    let progress = Double(currentOffset) / Double(totalSize)
                    await MainActor.run {
                        self.downloadProgress = min(progress, 1.0)
                    }
                    
                    print(String(format: "📊 Progress: %.1f%% (%d/%d bytes)", 
                               progress * 100, currentOffset, totalSize))
                    
                } catch {
                    print("❌ Failed to download chunk at offset \(currentOffset): \(error)")
                    throw error
                }
            }
            
            // Save to file
            try downloadedData.write(to: localURL)
            lastDownloadedBytes = Int64(downloadedData.count)
            
            print("✅ Downloaded file size: \(String(format: "%.2f MB", Double(lastDownloadedBytes) / (1024 * 1024)))")
            
        } else {
            // Fallback to simple download if we can't get file size
            print("⚠️ Could not determine file size, using simple download...")
            
            let (data, response) = try await session.data(from: stream.url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("❌ Download failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                throw YouTubeError.downloadFailed
            }
            
            try data.write(to: localURL)
            lastDownloadedBytes = Int64(data.count)
        }
        
        // Update progress to 100%
        await MainActor.run {
            self.downloadProgress = 1.0
        }
        
        // Final download statistics
        let totalTime = Date().timeIntervalSince(startTime)
        let fileSizeMB = Double(lastDownloadedBytes) / (1024 * 1024)
        let averageSpeed = fileSizeMB / totalTime
        
        print("\n✅ Download complete!")
        print("  - Total size: \(String(format: "%.2f MB", fileSizeMB))")
        print("  - Total time: \(String(format: "%.1f seconds", totalTime))")
        print("  - Average speed: \(String(format: "%.2f MB/s", averageSpeed))")
        print("  - Saved to: \(fileName)")
        
        await MainActor.run {
            downloadedFileURL = localURL
            downloadProgress = 1.0
        }
        
        // Convert to audio format if it's a video file
        if fileExtension != "webm" && fileExtension != "m4a" && fileExtension != "mp3" {
            return try await extractAudio(from: localURL, videoID: videoID)
        }
        
        return localURL
    }
    
    private func extractAudio(from videoURL: URL, videoID: String) async throws -> URL {
        print("🎵 Extracting audio from video file...")
        
        let asset = AVAsset(url: videoURL)
        
        // Check if asset has audio track
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard !audioTracks.isEmpty else {
            print("⚠️ No audio track found, using video file as-is")
            return videoURL
        }
        
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("Transcribe")
            .appendingPathComponent("YouTube")
        let outputURL = tempDir.appendingPathComponent("youtube_\(videoID).m4a")
        
        // Remove existing file if present
        try? FileManager.default.removeItem(at: outputURL)
        
        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            print("⚠️ Failed to create export session, using original file")
            return videoURL
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        
        // Export audio
        await exportSession.export()
        
        if exportSession.status == .completed {
            print("✅ Audio extracted successfully")
            // Clean up original video file
            try? FileManager.default.removeItem(at: videoURL)
            
            await MainActor.run {
                downloadedFileURL = outputURL
            }
            
            return outputURL
        } else {
            print("⚠️ Audio extraction failed: \(exportSession.error?.localizedDescription ?? "Unknown error")")
            return videoURL
        }
    }
    
    func extractVideoID(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        
        // Handle youtu.be format
        if url.host == "youtu.be" || url.host == "www.youtu.be" {
            return url.pathComponents.last
        }
        
        // Handle youtube.com format
        if url.host == "youtube.com" || url.host == "www.youtube.com" || url.host == "m.youtube.com" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value {
                return videoID
            }
            
            // Handle embed format
            if url.pathComponents.contains("embed"),
               let videoID = url.pathComponents.last {
                return videoID
            }
        }
        
        return nil
    }
    
    func cleanup() {
        if let fileURL = downloadedFileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
}

enum YouTubeError: LocalizedError {
    case invalidURL
    case noSuitableStream
    case downloadFailed
    case noFallbackAllowed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ogiltig YouTube-URL. Kontrollera länken och försök igen."
        case .noSuitableStream:
            return "Kunde inte hitta lämpligt format för nedladdning."
        case .downloadFailed:
            return "Nedladdningen misslyckades. Försök igen."
        case .noFallbackAllowed:
            return "YouTube har ändrat sitt API. Vänligen uppdatera appen."
        }
    }
}