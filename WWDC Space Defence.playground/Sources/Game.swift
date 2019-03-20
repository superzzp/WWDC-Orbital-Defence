import Foundation

public class Game {
    
    var delegate : GameDelegate?
    
    let cooldown = 0.3 // so the player can't spam bullets
    let power = 1 // how much damage the bullet does
    var health = 5  { // how much health the player has
        didSet{
            delegate?.healthDidChange()
        }
    }
    
    var lastShot : TimeInterval = 0 // last time the player shot
    
    func playerCanShoot() -> Bool {
        // checks to make sure the cooldown is over before the player shoots again
        let curTime = Date().timeIntervalSince1970
        if(curTime - lastShot > cooldown){
            lastShot = curTime
            return true
        }
        return false
    }
    
    var spawnCount = 0 // counter for alien spawn
    public var spawnFreq = 90 // how often it will attempt to spawn an alien
    let spawnProb : UInt32 = 2 // how often the alien will actually be spawned
    public var shotFreq = 60 // how often it will attempt to shoot
    
    public var totalAliens = 10 // number of aliens that must be killed to win
    let alienPower = 1 // how much damage the alien's bullet does
    let alienHealth = 1 // how much health the alien has
    
    var winLoseFlag : Bool? // whether the player won, lost, or still playing
    
    // current score
    var score = 0 {
        didSet{
            delegate?.scoreDidChange()
        }
    }
    
    //randomizes Alien spawn
    func spawnAlien(numAliens: Int) -> Alien?{
        guard numAliens < totalAliens else { return nil }
        spawnCount += 1
        if(spawnCount == spawnFreq){
            spawnCount = 0
            if(arc4random_uniform(spawnProb) == 0){
                return Alien(health: alienHealth, power: alienPower, shotFreq: shotFreq, shotProbHigh: 10, shotProbLow: 2)
            }
        }
        return nil
    }
}

protocol GameDelegate {
    func scoreDidChange()
    func healthDidChange()
}
