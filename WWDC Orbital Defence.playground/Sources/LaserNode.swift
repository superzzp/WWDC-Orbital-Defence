//
//  LaserNode.swift
//
//
//  Created by Zhipian Zhang on 2019-03-01.
//

import UIKit
import ARKit

public class LaserNode: SCNNodeContainer{
    
    var initialPosition : SCNVector3!
    var direction : SCNVector3!
    var type : LaserType
    var node : SCNNode!
    
    init(initialPosition: SCNVector3, direction: SCNVector3, type: LaserType){
        self.initialPosition = initialPosition
        self.direction = direction.normalized() // makes sure the direction is 1 meter
        self.type = type
        self.node = createNode()
        self.node.position = initialPosition
    }
    
    func createNode() -> SCNNode{
        
        // makes a sphere and uses the appropriate texture
        let geometry = SCNSphere(radius: 0.01)
        let material = SCNMaterial()
        if(type == .player){
            material.diffuse.contents = "playerBullet.png"
        } else {
            material.diffuse.contents = "enemyBullet.jpg"
        }
        
        geometry.materials = [material]
        let sphereNode = SCNNode(geometry: geometry)
        sphereNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        sphereNode.physicsBody?.contactTestBitMask = type == .player ? PhysicsMask.enemy : PhysicsMask.player
        sphereNode.physicsBody?.isAffectedByGravity = false
        return sphereNode
    }
    
    func move() -> Bool{
        self.node.position += direction/60 // speed of the bullet
        if self.node.position.distance(vector: initialPosition) > 3 {
            return false
        }
        return true
    }
}
