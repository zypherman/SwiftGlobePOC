import Foundation
import SceneKit
import SwiftUI

// The SwiftUI view that contains the SceneView and the GroupBox
struct GlobeView: View {
    @EnvironmentObject var globe: SwiftGlobe
    @ObservedObject var model: FlightInfoModel
    @State private var userAgreed = false
    
    let agreementText = "This is the end-user agreement text that will be displayed inside the GroupBox."
    
    var body: some View {
        ZStack {
            SceneView(scene: globe.scene, options: [.allowsCameraControl])
                .edgesIgnoringSafeArea(.all)
        }
        .overlay(FlightInfoOverlay, alignment: .bottom)
        .onAppear {
            globe.setupInSceneView(globe.gestureHost ?? SCNView(), forARKit: false, enableAutomaticSpin: false)
            globe.setupFlightInfo(with: model.$flightInfo)
        }
        .task {
            await model.fetchFlightInfo()
        }
    }
    
    var FlightInfoOverlay: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading) {
                Text(model.timeAtOrigin)
                    .font(.title3)
                Text("Time At Origin")
                    .font(.caption)
                    .padding(.bottom, 10)
                
                Text(model.timeToGo)
                    .font(.title3)
                Text("Time till Landing")
                    .font(.caption)
            }
            
            VStack(alignment: .leading) {
                Text(model.flightNumber)
                    .font(.title3)
                Text("Flight Number")
                    .font(.caption)
                    .padding(.bottom, 10)
                
                Text(model.groundSpeed)
                    .font(.title3)
                Text("Ground Speed")
                    .font(.caption)
            }
            
            VStack(alignment: .leading) {
                Text(model.timeAtDestination)
                    .font(.title3)
                Text("Time at Destination")
                    .font(.caption)
                    .padding(.bottom, 10)
                
                Text(model.altitude)
                    .font(.title3)
                Text("Altitude")
                    .font(.caption)
            }
            
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, idealHeight: 100, maxHeight: 150)
        .background(FlightInfoBackground)
        .padding(7)
    }
    
    var FlightInfoBackground: some View {
        ZStack {
            Color.black.opacity(0.7)
                    .background(.ultraThinMaterial)
                    .blur(radius: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
    }
}

struct ContentView: View {
    @StateObject var globe: SwiftGlobe = SwiftGlobe(alignment: .poles)
    @StateObject var flightInfoModel = FlightInfoModel()
    
    var body: some View {
        GlobeView(model: flightInfoModel).environmentObject(globe)
    }
}

@main
struct GlobeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
