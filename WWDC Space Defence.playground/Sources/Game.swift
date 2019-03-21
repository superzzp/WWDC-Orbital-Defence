import Foundation

public class Game {
    
    var delegate : GameDelegate?
    
    var portalCreated: Bool? //whether the universe portal is created
    var gameStart: Bool? //whether the game starts
    let cooldown = 0.3 // so the player can't spam bullets
    let power = 1 // how much damage the bullet does
    var health = 5  { // how much health the player has
        didSet{
            delegate?.healthDidChange()
        }
    }
    
    var lastShot : TimeInterval = 0 // last time the player shot
    
    func playerCanShoot() -> Bool {
        // checks to make sure the game has started and cooldown is over before the player shoots again
        if (gameStart != nil) {
            let curTime = Date().timeIntervalSince1970
            if(curTime - lastShot > cooldown) {
                lastShot = curTime
                return true
            }
        }
        return false
    }
    
    var spawnCount = 0 // counter for UFO spawn
    public var spawnFreq = 90 // how often it will attempt to spawn an UFO
    let spawnProb : UInt32 = 2 // how often the UFO will actually be spawned
    public var shotFreq = 60 // how often it will attempt to shoot
    
    public var totalUFOs = 10 // number of UFOs that must be killed to win
    let UFOPower = 1 // how much damage the UFO's bullet does
    let UFOHealth = 1 // how much health the UFO has
    
    var winLoseFlag : Bool? // whether the player won, lost, or still playing
    
    
    
    // current score
    var score = 0 {
        didSet{
            delegate?.scoreDidChange()
        }
    }
    
    //randomizes UFO spawn
    func spawnUFO(numUFOs: Int) -> UFO?{
        guard numUFOs < totalUFOs else { return nil }
        spawnCount += 1
        if(spawnCount == spawnFreq){
            spawnCount = 0
            if(arc4random_uniform(spawnProb) == 0){
                return UFO(health: UFOHealth, power: UFOPower, shotFreq: shotFreq, shotProbHigh: 10, shotProbLow: 2)
            }
        }
        return nil
    }
}

protocol GameDelegate {
    func scoreDidChange()
    func healthDidChange()
}
