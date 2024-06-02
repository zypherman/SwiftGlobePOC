//
//  DemoMarkers.swift
//  SwiftGlobe
//
//  Created by David Mojdehi on 4/21/20.
//  Copyright © 2020 David Mojdehi. All rights reserved.
//

import Foundation
import SwiftAstro

extension SwiftGlobe {
    public func addSunMarker() {
        let currentTime = SwiftAstro.Time(date: Date())
        let subsolarPoint = SwiftAstro.sun.subsolarPoint(t: currentTime)
        let lat = Float(subsolarPoint.latitude)
        let long = Float(subsolarPoint.longitude)
        
        let sun = GlowingMarker(lat: lat, lon: long, altitude: kGlobeRadius, markerZindex: 0, style: .dot)
        sun.addPulseAnimation()
        self.addMarker(sun)
    }
}
