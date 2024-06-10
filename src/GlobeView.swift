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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(model.timeAtOrigin)
                        .font(.title3)
                    Text("Time at \(model.originCity)")
                        .font(.caption)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                VStack(alignment: .leading) {
                    Text(model.flightNumber)
                        .font(.title3)
                    Text("Flight Number")
                        .font(.caption)
                }
                
                VStack(alignment: .leading) {
                    Text(model.timeAtDestination)
                        .font(.title3)
                    Text("Time at \(model.destinationCity)")
                        .font(.caption)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(model.timeToGo)
                        .font(.title3)
                    Text("Time till Landing")
                        .font(.caption)
                }
                
                VStack(alignment: .leading) {
                    Text(model.groundSpeed)
                        .font(.title3)
                    Text("Ground Speed")
                        .font(.caption)
                }
                
                VStack(alignment: .leading) {
                    Text(model.altitude)
                        .font(.title3)
                    Text("Altitude")
                        .font(.caption)
                }
            }
        }
        .padding(10)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, idealHeight: 100, maxHeight: 150)
        .background(FlightInfoBackground)
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
