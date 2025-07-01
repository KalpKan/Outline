import Foundation
import PencilKit

// Raw stroke point data for export
struct StrokePoint: Codable {
    let x: Double
    let y: Double
    let t: Double // timestamp in seconds from stroke start
    
    init(x: CGFloat, y: CGFloat, t: Double) {
        self.x = Double(x)
        self.y = Double(y)
        self.t = t
    }
}

// Trial metadata for analysis
struct TrialMetadata: Codable {
    let trial_id: String // ISO timestamp
    let fatigue_rating: Int? // Optional, 1-10 scale
    let mse: Double? // Shape-only MSE (calculated later)
    let raw_points_file: String // Filename for stroke data
    
    init(trialId: String, fatigueRating: Int? = nil, mse: Double? = nil, rawPointsFile: String) {
        self.trial_id = trialId
        self.fatigue_rating = fatigueRating
        self.mse = mse
        self.raw_points_file = rawPointsFile
    }
}

struct Trial: Identifiable, Codable {
    let id: UUID
    let drawing: Data // PKDrawing archived as Data for Codable
    let timestamp: Date
    var metadata: TrialMetadata
    
    init(drawing: PKDrawing, timestamp: Date = Date(), fatigueRating: Int? = nil) {
        self.id = UUID()
        self.drawing = drawing.dataRepresentation()
        self.timestamp = timestamp
        
        // Create ISO timestamp for trial_id
        let formatter = ISO8601DateFormatter()
        let trialId = formatter.string(from: timestamp)
        
        // Create filename for raw points
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmm"
        let filename = "circle-\(dateFormatter.string(from: timestamp)).json"
        
        // Calculate MSE for the drawing
        let mse = MSECalculator.calculateMSE(for: drawing)
        
        self.metadata = TrialMetadata(
            trialId: trialId,
            fatigueRating: fatigueRating,
            mse: mse.isFinite ? mse : nil, // Only store finite MSE values
            rawPointsFile: filename
        )
    }
    
    func pkDrawing() -> PKDrawing? {
        try? PKDrawing(data: drawing)
    }
    
    // Extract raw stroke points in the required format
    func extractStrokePoints() -> [StrokePoint] {
        guard let pkDrawing = pkDrawing() else { return [] }
        
        var points: [StrokePoint] = []
        let startTime = timestamp.timeIntervalSince1970
        
        for stroke in pkDrawing.strokes {
            for point in stroke.path {
                let timeOffset = point.timeOffset
                let absoluteTime = startTime + timeOffset
                
                points.append(StrokePoint(
                    x: point.location.x,
                    y: point.location.y,
                    t: timeOffset // Use timeOffset as relative time from stroke start
                ))
            }
        }
        
        return points
    }
    
    // Get MSE value for display
    var mseValue: Double? {
        return metadata.mse
    }
    
    // Get formatted MSE string for UI
    var mseDisplayString: String {
        guard let mse = metadata.mse else { return "N/A" }
        return String(format: "%.1f", mse)
    }
}

struct Session: Identifiable, Codable {
    let id: UUID
    var trials: [Trial]
    let created: Date
    let fatigueRating: Int? // Session-level fatigue rating
    
    init(trials: [Trial] = [], created: Date = Date(), fatigueRating: Int? = nil) {
        self.id = UUID()
        self.trials = trials
        self.created = created
        self.fatigueRating = fatigueRating
    }
    
    // Export only non-practice trials (after first 5)
    func exportTrials() -> [Trial] {
        return Array(trials.dropFirst(5))
    }
} 
