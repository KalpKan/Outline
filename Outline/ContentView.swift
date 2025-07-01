//
//  ContentView.swift
//  Outline
//
//  Created by Kalp Kansara on 2025-06-30.
//

import SwiftUI
import PencilKit

struct ContentView: View {
    @State private var drawing = PKDrawing()
    @State private var tool: PKTool = PKInkingTool(.pen, color: .black, width: 5)
    @State private var session = Session()
    @State private var showingExportSheet = false
    @State private var ghostCircleOpacity: Double = 0.0
    @State private var guideCircleProgress: Double = 0.0
    @State private var showingGuideCircle: Bool = false
    @State private var userHasStartedDrawing: Bool = false
    @State private var showingFatiguePrompt: Bool = false
    @State private var fatigueRating: Int = 5
    @State private var currentMSE: Double? = nil
    @State private var showingMSEFeedback: Bool = false
    @State private var showingSessionManager: Bool = false
    @State private var trialToRename: Trial? = nil
    @State private var renameText: String = ""
    
    // Template circle properties
    let templateRadius: CGFloat = 250
    let templateCenter: CGPoint = CGPoint(x: 384, y: 512) // iPad default size, will scale
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // White background for the entire drawing area
                Rectangle()
                    .fill(Color.white)
                    .cornerRadius(16)
                
                GeometryReader { geo in
                    // Template circle overlay (always visible)
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .foregroundColor(.gray.opacity(0.5))
                        .frame(width: templateRadius * 2, height: templateRadius * 2)
                        .position(x: geo.size.width/2, y: geo.size.height/2)
                    
                    // PencilKit canvas (background layer)
                    CanvasView(drawing: $drawing, tool: tool, onDrawingStarted: {
                        if !userHasStartedDrawing {
                            userHasStartedDrawing = true
                            withAnimation(.easeOut(duration: 0.3)) {
                                showingGuideCircle = false
                            }
                        }
                    })
                    .background(Color.clear) // Make background transparent
                    .clipShape(Rectangle())
                    
                    // Ghost circle for first 5 trials (warm-up)
                    if session.trials.count < 5 {
                        Circle()
                            .stroke(style: StrokeStyle(lineWidth: 3))
                            .foregroundColor(.blue.opacity(ghostCircleOpacity))
                            .frame(width: templateRadius * 2, height: templateRadius * 2)
                            .position(x: geo.size.width/2, y: geo.size.height/2)
                            .animation(.easeInOut(duration: 0.8), value: ghostCircleOpacity)
                    }
                    
                    // Animated guide circle for first 5 trials (top layer)
                    if session.trials.count < 5 && showingGuideCircle && !userHasStartedDrawing {
                        Circle()
                            .trim(from: 0, to: guideCircleProgress)
                            .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .foregroundColor(.blue.opacity(0.7))
                            .frame(width: templateRadius * 2, height: templateRadius * 2)
                            .position(x: geo.size.width/2, y: geo.size.height/2)
                            .rotationEffect(.degrees(-90)) // Start from top
                            .animation(.easeInOut(duration: 1.0), value: guideCircleProgress)
                    }
                }
            }
            .aspectRatio(3/4, contentMode: .fit)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 4)
            .padding()
            
            // MSE Feedback Overlay
            if showingMSEFeedback, let mse = currentMSE {
                VStack {
                    Text("Trial Complete!")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("MSE: \(String(format: "%.1f", mse))")
                        .font(.title2)
                        .foregroundColor(mse < 100 ? .green : mse < 200 ? .orange : .red)
                    Text(mse < 100 ? "Excellent!" : mse < 200 ? "Good!" : "Keep practicing!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .transition(.scale.combined(with: .opacity))
                .animation(.easeInOut(duration: 0.5), value: showingMSEFeedback)
            }
            
            // Controls
            HStack {
                Button("New Trial") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        drawing = PKDrawing()
                        userHasStartedDrawing = false
                        guideCircleProgress = 0.0
                        showingGuideCircle = false
                        showingMSEFeedback = false
                    }
                    // Start guide circle animation after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if session.trials.count < 5 {
                            showingGuideCircle = true
                            withAnimation(.easeInOut(duration: 1.0)) {
                                guideCircleProgress = 1.0
                            }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                Button("Save Trial") {
                    let trial = Trial(drawing: drawing, fatigueRating: session.trials.count >= 5 ? session.fatigueRating : nil)
                    session.trials.append(trial)
                    
                    // Show MSE feedback
                    currentMSE = trial.mseValue
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingMSEFeedback = true
                    }
                    
                    // Hide feedback after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingMSEFeedback = false
                        }
                    }
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        drawing = PKDrawing()
                        userHasStartedDrawing = false
                        guideCircleProgress = 0.0
                        showingGuideCircle = false
                    }
                    // Start guide circle animation for next trial
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if session.trials.count < 5 {
                            showingGuideCircle = true
                            withAnimation(.easeInOut(duration: 1.0)) {
                                guideCircleProgress = 1.0
                            }
                        }
                    }
                }
                .buttonStyle(.bordered)
                Button("Manage Trials") {
                    showingSessionManager = true
                }
                .buttonStyle(.bordered)
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Trials: \(session.trials.count)")
                        .animation(.easeInOut(duration: 0.3), value: session.trials.count)
                    if session.trials.count < 5 {
                        Text("(Practice)")
                            .foregroundColor(.blue)
                            .font(.caption)
                            .transition(.opacity.combined(with: .scale))
                            .animation(.easeInOut(duration: 0.4), value: session.trials.count)
                    } else if let lastTrial = session.trials.last, lastTrial.mseValue != nil {
                        Text("Last MSE: \(lastTrial.mseDisplayString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Button("Export") {
                    showingExportSheet = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportSheet(session: session)
        }
        .sheet(isPresented: $showingSessionManager) {
            SessionManagerView(session: $session, onRename: { trial in
                trialToRename = trial
                renameText = trial.metadata.trial_id // Default to trial_id
            })
        }
        .sheet(item: $trialToRename) { trial in
            RenameTrialView(trial: trial, text: $renameText, onSave: { newName in
                // Update the trial's metadata (simulate rename by changing trial_id)
                if let idx = session.trials.firstIndex(where: { $0.id == trial.id }) {
                    var updatedTrial = session.trials[idx]
                    updatedTrial.metadata = TrialMetadata(
                        trialId: newName,
                        fatigueRating: updatedTrial.metadata.fatigue_rating,
                        mse: updatedTrial.metadata.mse,
                        rawPointsFile: updatedTrial.metadata.raw_points_file
                    )
                    session.trials[idx] = updatedTrial
                }
                trialToRename = nil
            })
        }
        .sheet(isPresented: $showingFatiguePrompt) {
            FatiguePromptView(fatigueRating: $fatigueRating, onComplete: {
                session = Session(trials: session.trials, created: session.created, fatigueRating: fatigueRating)
                showingFatiguePrompt = false
            })
        }
        .onAppear {
            // Show fatigue prompt on first launch
            if session.fatigueRating == nil {
                showingFatiguePrompt = true
            }
            
            // Animate ghost circle in on first appearance
            withAnimation(.easeInOut(duration: 1.2)) {
                ghostCircleOpacity = 0.3
            }
            // Start guide circle animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingGuideCircle = true
                withAnimation(.easeInOut(duration: 1.0)) {
                    guideCircleProgress = 1.0
                }
            }
        }
        .onChange(of: session.trials.count) { newCount in
            // Animate ghost circle out when reaching 5 trials
            if newCount >= 5 {
                withAnimation(.easeInOut(duration: 1.0)) {
                    ghostCircleOpacity = 0.0
                }
            }
        }
    }
}

// Fatigue prompt view
struct FatiguePromptView: View {
    @Binding var fatigueRating: Int
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("How tired are you feeling?")
                .font(.title2)
                .multilineTextAlignment(.center)
            
            Text("Rate your fatigue level from 1 (not tired at all) to 10 (extremely tired)")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            HStack(spacing: 15) {
                ForEach(1...10, id: \.self) { rating in
                    Button(action: {
                        fatigueRating = rating
                    }) {
                        Text("\(rating)")
                            .font(.headline)
                            .frame(width: 40, height: 40)
                            .background(fatigueRating == rating ? Color.blue : Color.gray.opacity(0.3))
                            .foregroundColor(fatigueRating == rating ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            
            Button("Start Session") {
                onComplete()
            }
            .buttonStyle(.borderedProminent)
            .disabled(fatigueRating < 1 || fatigueRating > 10)
        }
        .padding(40)
        .background(Color(UIColor.systemBackground))
    }
}

// ExportSheet for sharing JSON (excludes first 5 practice trials)
struct ExportSheet: UIViewControllerRepresentable {
    let session: Session
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        // Get only non-practice trials
        let exportTrials = session.exportTrials()
        
        // Create temporary directory for all files
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("circle-session-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        var activityItems: [URL] = []
        
        // Export raw stroke points for each trial
        for trial in exportTrials {
            let strokePoints = trial.extractStrokePoints()
            let strokeData = try? encoder.encode(strokePoints)
            let strokeURL = tempDir.appendingPathComponent(trial.metadata.raw_points_file)
            try? strokeData?.write(to: strokeURL)
            activityItems.append(strokeURL)
        }
        
        // Export session metadata
        let sessionMetadata = SessionMetadata(
            session_id: session.id.uuidString,
            created: session.created,
            fatigue_rating: session.fatigueRating,
            trials: exportTrials.map { trial in
                TrialExportMetadata(
                    trial_id: trial.metadata.trial_id,
                    fatigue_rating: trial.metadata.fatigue_rating,
                    mse: trial.metadata.mse,
                    raw_points_file: trial.metadata.raw_points_file
                )
            }
        )
        
        let sessionData = try? encoder.encode(sessionMetadata)
        let sessionURL = tempDir.appendingPathComponent("session-metadata.json")
        try? sessionData?.write(to: sessionURL)
        activityItems.append(sessionURL)
        
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return vc
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Session metadata for export
struct SessionMetadata: Codable {
    let session_id: String
    let created: Date
    let fatigue_rating: Int?
    let trials: [TrialExportMetadata]
}

// Trial metadata for export
struct TrialExportMetadata: Codable {
    let trial_id: String
    let fatigue_rating: Int?
    let mse: Double?
    let raw_points_file: String
}

// SessionManagerView: List of trials with delete and rename
struct SessionManagerView: View {
    @Binding var session: Session
    var onRename: (Trial) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(session.trials) { trial in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(trial.metadata.trial_id)
                                .font(.headline)
                            if let mse = trial.mseValue {
                                Text("MSE: \(String(format: "%.1f", mse))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Button(action: { onRename(trial) }) {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onDelete { indices in
                    session.trials.remove(atOffsets: indices)
                }
            }
            .navigationTitle("Manage Trials")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// RenameTrialView: Simple rename dialog
struct RenameTrialView: View {
    let trial: Trial
    @Binding var text: String
    var onSave: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Rename Trial")) {
                    TextField("Trial Name", text: $text)
                }
            }
            .navigationTitle("Rename Trial")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(text)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
