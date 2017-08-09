//
//  Plane.swift
//  ARKit-by-example-2
//
//  Created by mac on 2017/8/9.
//  Copyright © 2017年 jiji. All rights reserved.
//

import UIKit
import ARKit

class Plane: SCNNode {
    var planeGeomotry: SCNPlane
    var anchor: ARPlaneAnchor
    
    init(_ anchor: ARPlaneAnchor) {
        self.anchor = anchor
        self.planeGeomotry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        
        super.init()
        
        // render geometry material
        let material = SCNMaterial()
        material.diffuse.contents = UIImage.init(named: "tron_grid.png")
        self.planeGeomotry.materials = [material]
        
        // setting plane node position, same as
        let planeNode = SCNNode(geometry: self.planeGeomotry)
        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        // rotate 90°(as default, SceneKit geometry is vertical)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        
        setTextureScale()
        
        addChildNode(planeNode)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setTextureScale() {
        let width = planeGeomotry.width
        let height = planeGeomotry.height
        
        let material = planeGeomotry.firstMaterial!
        // plane为二维，两面（二维矩阵），直接设置tx,ty即可
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(width), Float(height), 1)
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
    }
    
    /** update size and postion */
    func update(_ anchor:(ARPlaneAnchor)) {
        // geometry size
        planeGeomotry.width = CGFloat(anchor.extent.x)
        planeGeomotry.height = CGFloat(anchor.extent.z)
        
        // node position
        position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        
        // update texture
        setTextureScale()
    }
}
