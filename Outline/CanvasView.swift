import SwiftUI
import PencilKit

struct CanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let tool: PKTool
    let onDrawingStarted: (() -> Void)?
    
    init(drawing: Binding<PKDrawing>, tool: PKTool, onDrawingStarted: (() -> Void)? = nil) {
        self._drawing = drawing
        self.tool = tool
        self.onDrawingStarted = onDrawingStarted
    }
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.tool = tool
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.delegate = context.coordinator
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
        uiView.tool = tool
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasView
        var hasStartedDrawing = false
        var lastDrawingBounds: CGRect = .zero
        
        init(_ parent: CanvasView) { self.parent = parent }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let currentDrawing = canvasView.drawing
            let currentBounds = currentDrawing.bounds
            
            DispatchQueue.main.async {
                // Check if user has started drawing by comparing bounds
                if !self.hasStartedDrawing && !currentBounds.isEmpty && currentBounds != self.lastDrawingBounds {
                    self.hasStartedDrawing = true
                    self.lastDrawingBounds = currentBounds
                    self.parent.onDrawingStarted?()
                }
                // Update the drawing binding
                if self.parent.drawing != currentDrawing {
                    self.parent.drawing = currentDrawing
                }
            }
        }
    }
} 
