import Foundation
import CoreGraphics
import PencilKit

struct MSECalculator {
    
    /// Calculate shape-only Mean Squared Error for a circle drawing
    /// - Parameters:
    ///   - points: Array of stroke points with x, y coordinates
    ///   - targetRadius: Target radius for normalization (default: 250)
    ///   - nAngles: Number of angles to sample (default: 360)
    /// - Returns: MSE value representing shape deviation from perfect circle
    static func calculateMSE(from points: [StrokePoint], targetRadius: Double = 250.0, nAngles: Int = 360) -> Double {
        guard points.count >= 3 else { return Double.infinity }
        
        // Step 1: Convert to array of CGPoint
        let cgPoints = points.map { CGPoint(x: $0.x, y: $0.y) }
        
        // Step 2: Remove translation (center at origin)
        let centroid = calculateCentroid(points: cgPoints)
        let centeredPoints = cgPoints.map { CGPoint(x: $0.x - centroid.x, y: $0.y - centroid.y) }
        
        // Step 3: Normalize radius
        let radii = centeredPoints.map { sqrt($0.x * $0.x + $0.y * $0.y) }
        let meanRadius = radii.reduce(0, +) / Double(radii.count)
        let scale = targetRadius / meanRadius
        let normalizedPoints = centeredPoints.map { CGPoint(x: $0.x * scale, y: $0.y * scale) }
        
        // Step 4: Resample to uniform angles
        let rTheta = resampleToUniformAngles(points: normalizedPoints, nAngles: nAngles, targetRadius: targetRadius)
        
        // Step 5 & 6: Compute MSE
        let squaredErrors = rTheta.map { ($0 - targetRadius) * ($0 - targetRadius) }
        let mse = squaredErrors.reduce(0, +) / Double(squaredErrors.count)
        
        return mse
    }
    
    /// Calculate centroid of points
    private static func calculateCentroid(points: [CGPoint]) -> CGPoint {
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        let count = Double(points.count)
        return CGPoint(x: sumX / count, y: sumY / count)
    }
    
    /// Resample points to uniform angles
    private static func resampleToUniformAngles(points: [CGPoint], nAngles: Int, targetRadius: Double) -> [Double] {
        let angles = (0..<nAngles).map { Double($0) * 2.0 * .pi / Double(nAngles) }
        let radii = points.map { sqrt($0.x * $0.x + $0.y * $0.y) }
        let thetas = points.map { atan2($0.y, $0.x) }
        
        var rTheta: [Double] = []
        
        for angle in angles {
            // Find nearest point with angle ≈ current angle
            var minDistance = Double.infinity
            var bestRadius = targetRadius
            
            for (index, theta) in thetas.enumerated() {
                let distance = abs(unwrapAngle(theta - angle))
                if distance < minDistance {
                    minDistance = distance
                    bestRadius = radii[index]
                }
            }
            
            rTheta.append(bestRadius)
        }
        
        return rTheta
    }
    
    /// Unwrap angle to handle discontinuity at ±π
    private static func unwrapAngle(_ angle: Double) -> Double {
        var unwrapped = angle
        while unwrapped > .pi {
            unwrapped -= 2.0 * .pi
        }
        while unwrapped < -.pi {
            unwrapped += 2.0 * .pi
        }
        return unwrapped
    }
    
    /// Calculate MSE for a PKDrawing
    static func calculateMSE(for drawing: PKDrawing, targetRadius: Double = 250.0) -> Double {
        let points = extractPointsFromDrawing(drawing)
        return calculateMSE(from: points, targetRadius: targetRadius)
    }
    
    /// Extract points from PKDrawing
    private static func extractPointsFromDrawing(_ drawing: PKDrawing) -> [StrokePoint] {
        var points: [StrokePoint] = []
        
        for stroke in drawing.strokes {
            for point in stroke.path {
                points.append(StrokePoint(
                    x: point.location.x,
                    y: point.location.y,
                    t: point.timeOffset
                ))
            }
        }
        
        return points
    }
} 