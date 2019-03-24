import Foundation
import SceneKit

public class Animation {

    public func animatePathwayOpacity(node: SCNNode) {
        let changeOpacity = CABasicAnimation(keyPath: "opacity")
        changeOpacity.fromValue = 0.4
        changeOpacity.toValue = 1
        changeOpacity.repeatCount = .infinity
        changeOpacity.duration = 2
        changeOpacity.autoreverses = true
        node.addAnimation(changeOpacity, forKey: "opacity")
    }
    
    
    public func animatePortalScale(node: SCNNode) {
        let upScale = CABasicAnimation(keyPath: "transform.scale")
        upScale.fromValue = 1
        upScale.toValue = 2
        upScale.duration = 2
        node.addAnimation(upScale, forKey: "transform.scale")
    }
    
    public func animateUFOWhenHit(node: SCNNode) {
        let spin = CABasicAnimation(keyPath: "position")
        spin.fromValue = node.presentation.position
        spin.toValue = SCNVector3(node.presentation.position.x - 0.2 ,node.presentation.position.y - 0.2, node.presentation.position.z - 0.2)
        spin.duration = 0.03
        spin.repeatCount = 5
        spin.autoreverses = true
        node.addAnimation(spin, forKey: "postion")
    }
    
    
    public func animatePortalMovement(node: SCNNode) {
        let move = CABasicAnimation(keyPath: "position")
        move.fromValue = node.presentation.position
        move.toValue = SCNVector3(node.presentation.position.x,node.presentation.position.y, node.presentation.position.z - 2)
        move.duration = 1.5
        move.repeatCount = 1
        move.fillMode = CAMediaTimingFillMode.forwards
        move.isRemovedOnCompletion = false
        node.addAnimation(move, forKey: "position")
    }

}
