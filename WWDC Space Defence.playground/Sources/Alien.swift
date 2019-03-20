//
//  Alien.swift
//  RushToWWDC
//
//  Created by Anirudh Natarajan on 3/30/18.
//  Copyright © 2018 Anirudh Natarajan. All rights reserved.
//

import UIKit

public class Alien {
    
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
        
        // to randomize the alien's texture
//        if (Double(arc4random()) / 0xFFFFFFFF > 0.5){
//            self.image = UIImage(named: "alien1")!
//        } else {
//            self.image = UIImage(named: "alien2")!
//        }
        
        
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
