

import ARKit
import UIKit

public class UFONode : SCNNodeContainer{
    
    var node : SCNNode!
    var UFO : UFO
    var lastAxis = SCNVector3Make(0, 0, 0)
    
    var spawnCount = 0
    
    // setup initial UFO values
    init(UFO: UFO, position: SCNVector3, cameraPosition: SCNVector3) {

        self.UFO = UFO
        self.node = createNode()
        self.node.position = position
        self.node.rotation = SCNVector4Make(0, 1, 0, 0)
        
        let deltaRotation = getXZRotation(towardsPosition: cameraPosition)
        if deltaRotation > 0 {
            node.rotation.w -= deltaRotation
        }else if deltaRotation < 0 {
            node.rotation.w -= deltaRotation
        }
    }
    
    // returns what angle the UFO has to rotate to face the given position
    func getXZRotation(towardsPosition toPosition: SCNVector3) -> Float {
        
        // creates the normalized vector for the position
        var unitDistance = (toPosition - node.position).negate()
        unitDistance.y = 0
        unitDistance = unitDistance.normalized()
        
        // creates the normalized vector for the UFO
        var unitDirection = self.node.convertPosition(SCNVector3Make(0, 0, -1), to: nil) - self.node.position
        unitDirection.y = 0
        unitDirection = unitDirection.normalized()
        
        // returns the angle it has to rotate
        let axis = unitDistance.cross(vector: unitDirection).normalized() //cross product
        let angle = acos(unitDistance.dot(vector: unitDirection))
        return angle * axis.y
        
    }
    
    private func createNode() -> SCNNode{
        let UFOScene = SCNScene(named: "UFOModel.scn")
        let UFONode = (UFOScene?.rootNode.childNode(withName: "Sphere", recursively: true))!
        UFONode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: UFONode, options: nil))
        UFONode.physicsBody?.categoryBitMask = PhysicsMask.enemy
        UFONode.physicsBody?.contactTestBitMask = PhysicsMask.playerBullet
        UFONode.physicsBody?.isAffectedByGravity = false
        return UFONode
    }
    
    func move(towardsPosition toPosition : SCNVector3) -> Bool{
        
        // distance between UFO and the position
        let deltaPos = (toPosition - node.position)
        
        // if UFO is too close to move, it won't
        guard deltaPos.length() > 0.05 else { return false }
        let normDeltaPos = deltaPos.normalized()
        
        // move the Y so its closer to the player
        node.position.y += normDeltaPos.y/50

        // distance on XZ plane
        let length = deltaPos.xzLength()
        
        // if UFO is really close to the player, it crashes into the player
        if length > 0.5 || length < 0.1 {
            node.position.x += normDeltaPos.x/250
            node.position.z += normDeltaPos.z/250
            UFO.closeQuarters = false
        }else{
            UFO.closeQuarters = true
        }
        
        // angle it must rotate to face player
        let goalRotation = getXZRotation(towardsPosition: toPosition)
        
        // slowly rotate in that direction
        if goalRotation > 0 {
            node.rotation.w -= min(Float.pi/180, goalRotation)
        }else if goalRotation < 0 {
            node.rotation.w -= max(-Float.pi/180, goalRotation)
        }
        
        return true
    }
}
