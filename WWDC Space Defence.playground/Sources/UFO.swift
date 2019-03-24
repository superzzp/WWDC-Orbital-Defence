import UIKit

public class UFO {
    
    var health : Int
    let power : Int
    var shotCount = 0
    let shotFreq : Int // how often it will attempt to shoot
    var shotProb : Int { // how often it will actually shoot
        return closeQuarters ? shotProbHigh : shotProbLow
    }
    private let shotProbHigh : Int
    private let shotProbLow : Int
    
    var closeQuarters = false // in the "goldilocks zone"
    //let image : UIImage
    
    init(health: Int, power: Int, shotFreq: Int, shotProbHigh: Int, shotProbLow: Int){
        self.health = health
        self.power = power
        self.shotFreq = shotFreq
        self.shotProbLow = shotProbLow
        self.shotProbHigh = shotProbHigh
    }
    
    func shouldShoot() -> Bool {
        // randomize the shooting
        shotCount += 1
        if(shotCount == shotFreq){
            shotCount = 0
            return arc4random_uniform(UInt32(shotProb)) == 0
        }
        return false
    }
}
