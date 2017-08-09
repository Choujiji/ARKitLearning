//
//  ViewController.swift
//  ARKit-by-example-2
//
//  Created by mac on 2017/8/9.
//  Copyright © 2017年 jiji. All rights reserved.
//

import UIKit
import ARKit

enum CustomCollisionCategory: Int {
    case CollisionCategoryBottom = 1
    case CollisionCategoryCube
}


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
        
        // add gestures
        addGestures()
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
    
    // MARK: ARSCNViewDelegate方法
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        let plane = Plane(planeAnchor, planeIsHidden: false)
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
    
    // MARK: config gestures
    func addGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapView(_:)))
        sceneView?.addGestureRecognizer(tapGesture)
    }
    
    
    @objc func onTapView(_ gesture: UITapGestureRecognizer) {
        let tapPoint = gesture.location(in: sceneView!)
        
        let hitTestResult = sceneView?.hitTest(tapPoint, types: .existingPlaneUsingExtent)
        guard let resultInstance = hitTestResult?.first else {
            return
        }
        
        insertGeometry(with: resultInstance)
    }
    
    func insertGeometry(with hitTestResult: ARHitTestResult) {
        let dimension = 0.1
        let boxNode = SCNNode(geometry: SCNBox(width: CGFloat(dimension), height: CGFloat(dimension), length: CGFloat(dimension), chamferRadius: 0))
        // add physics body
        boxNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)// use default geometry(box)
        
        boxNode.physicsBody?.mass = 2.0
        boxNode.physicsBody?.categoryBitMask = CustomCollisionCategory.CollisionCategoryCube.rawValue
        
        // postion the box 0.5 meter upon y axis（enable physics engine）
        let deltaY: Float = 0.5
        let worldTransform = SCNMatrix4.init(hitTestResult.worldTransform)// 转换成4X4矩阵对象（下标从1开始，c矩阵是下标从0开始）
        boxNode.position = SCNVector3Make(Float(worldTransform.m41), Float(worldTransform.m42) + deltaY, Float(worldTransform.m43))
        sceneView?.scene.rootNode.addChildNode(boxNode)
        
    }
}

