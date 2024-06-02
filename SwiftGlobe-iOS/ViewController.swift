//
//  ViewController.swift
//  SwiftGlobe
//
//  Created by David Mojdehi on 4/6/17.
//  Copyright © 2017 David Mojdehi. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit


class ViewController: UIViewController {

    @IBOutlet weak var sceneView : SCNView!
    
    var swiftGlobe = SwiftGlobe(alignment: .poles)
    var updateTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        swiftGlobe.setupInSceneView(sceneView, forARKit: false, enableAutomaticSpin: false)
        updateSunMarker()
        
        startPositionUpdateTimer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func startPositionUpdateTimer() {
        updateTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(updateSunMarker), userInfo: nil, repeats: true)
    }
    
    @objc func updateSunMarker() {
        print("Update sun marker")
        swiftGlobe.addSunMarker()
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}
