//
//  ViewController.swift
//  ARKit-by-example-2
//
//  Created by mac on 2017/8/9.
//  Copyright © 2017年 jiji. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    var sceneView: ARSCNView?
    var planes: Dictionary<UUID, Plane> = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        sceneView = ARSCNView(frame: view.bounds)
        sceneView?.scene = SCNScene()
        sceneView?.automaticallyUpdatesLighting = true
        view.addSubview(sceneView!)
        
        // debug options
        sceneView?.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        sceneView?.showsStatistics = true
        
        // delegate
        sceneView?.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // run AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView?.session.run(configuration)
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        let plane = Plane(planeAnchor)
        node.addChildNode(plane)
        
        // add to dictionary
        planes[anchor.identifier] = plane
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let plane = planes[anchor.identifier], let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        plane.update(planeAnchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        planes.removeValue(forKey: anchor.identifier)
    }
}

