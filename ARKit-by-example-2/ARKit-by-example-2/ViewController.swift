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
    var boxes: Array<SCNNode> = []

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
        tapGesture.numberOfTapsRequired = 1
        sceneView?.addGestureRecognizer(tapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressView(_:)))
        longPressGesture.minimumPressDuration = 1
        sceneView?.addGestureRecognizer(longPressGesture)
        
        let doubleLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(onDoubleLongPressView(_:)))
        doubleLongPressGesture.numberOfTouchesRequired = 2
        doubleLongPressGesture.minimumPressDuration = 1
        sceneView?.addGestureRecognizer(doubleLongPressGesture)
    }
    
    // MARK: single tap
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
        boxes.append(boxNode)
    }
    
    // MARK: long press
    @objc func onLongPressView(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else {
            return
        }
        
        let point = gesture.location(in: sceneView!)
        let hitTestResult = sceneView?.hitTest(point, types: .existingPlaneUsingExtent)
        guard let resultInstance = hitTestResult?.first else {
            return
        }
        // call explode
        explode(resultInstance)
    }
    
    func explode(_ hitTestResult: ARHitTestResult) {
        let explodeYOffset: Float = 0.1
        
        let worldTransform = SCNMatrix4(hitTestResult.worldTransform)
        let position = SCNVector3Make(worldTransform.m41,
                                      worldTransform.m42 + explodeYOffset,
                                      worldTransform.m43)
        
        // loop each geometry node to simulate explode
        for boxNode in boxes  {
            // get explode vector
            let explodeVector = SCNVector3Make(boxNode.worldPosition.x - position.x,
                                               boxNode.worldPosition.y - position.y,
                                               boxNode.worldPosition.z - position.z)
            // get explode distance
            let distance = sqrtf(explodeVector.x * explodeVector.x + explodeVector.y * explodeVector.y + explodeVector.z * explodeVector.z)
            
            let maxDistance: Float = 2
            
            // get force scale
            var scale = max(0, (maxDistance - distance))
            scale = scale * scale * 2
            
            // set force vector(cause force has direction and strength)
            // explodeVector.x / distance 为每米上面的向量（力） * scale 为比例
            let forceX = explodeVector.x / distance * scale
            let forceY = explodeVector.y / distance * scale
            let forceZ = explodeVector.z / distance * scale
            
            let forceVector = SCNVector3Make(forceX, forceY, forceZ)
            
            guard let box = boxNode.geometry as? SCNBox else {
                return
            }
            let boxCenterVector = SCNVector3Make(Float(box.width / 2), Float(box.height / 2), Float(box.length / 2))
            // add force(add to geometry center)
            boxNode.physicsBody?.applyForce(forceVector, at: boxCenterVector, asImpulse: true)
        }
    }
    
    // MARK: long double press
    @objc func onDoubleLongPressView(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else {
            return
        }
        
        // hide all planes
        for plane in planes.values {
            plane.hide()
        }
        
        // stop plane ditection
        let configuration = ARWorldTrackingConfiguration()
        sceneView?.session.run(configuration)
    }
}

