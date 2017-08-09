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
    var planeGeomotry: SCNBox
    var anchor: ARPlaneAnchor
    
    init(_ anchor: ARPlaneAnchor,
         planeIsHidden isHidden: Bool) {
        let planeHeight = 0.01
        
        self.anchor = anchor
        self.planeGeomotry = SCNBox(width: CGFloat(anchor.extent.x), height: CGFloat(planeHeight), length: CGFloat(anchor.extent.z), chamferRadius: 0)
        
        super.init()
        
        // render geometry material
        let material = SCNMaterial()
        material.diffuse.contents = UIImage.init(named: "tron_grid.png")
        
        let hiddenMaterial = SCNMaterial()
        hiddenMaterial.diffuse.contents = UIColor(white: 1.0, alpha: 0)
        
        if isHidden {
            // hide all material
            self.planeGeomotry.materials = [
                hiddenMaterial,
                hiddenMaterial,
                hiddenMaterial,
                hiddenMaterial,
                hiddenMaterial,
                hiddenMaterial
            ]
        } else {
            self.planeGeomotry.materials = [
                hiddenMaterial,
                hiddenMaterial,
                hiddenMaterial,
                hiddenMaterial,
                material,
                hiddenMaterial
            ]
        }
        
        // setting plane node position, same as
        let planeNode = SCNNode(geometry: self.planeGeomotry)
        planeNode.position = SCNVector3Make(0, Float(-planeHeight / 2), 0)
        
        // set physics body
        let physicsShape = SCNPhysicsShape(geometry: planeGeomotry, options: nil)
        planeNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: physicsShape)
        
        setTextureScale()
        
        addChildNode(planeNode)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setTextureScale() {
        let width = planeGeomotry.width
        let height = planeGeomotry.length// box的length
        
        // 由于只显示顶部，只重新渲染顶面即可
        let material = planeGeomotry.materials[4]// top
        
        
        // plane为二维，两面（二维矩阵），直接设置tx,ty即可
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(width), Float(height), 1)
        
        
        
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
    }
    
    /** update size and postion */
    func update(_ anchor:(ARPlaneAnchor)) {
        // geometry size
        planeGeomotry.width = CGFloat(anchor.extent.x)
        planeGeomotry.length = CGFloat(anchor.extent.z)// box的length
        
        // node position（只设置self自身节点即可，planeNode相对self来说位置没有变化）
        position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        
        // physics body
        let physicsShape = SCNPhysicsShape(geometry: planeGeomotry, options: nil)
        let planeNode = childNodes.first!
        planeNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: physicsShape)
        
        // update texture
        setTextureScale()
    }
    
    func hide() {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(white: 1.0, alpha: 0.0)
        planeGeomotry.materials = [
            material,
            material,
            material,
            material,
            material,
            material
        ]
    }
}
