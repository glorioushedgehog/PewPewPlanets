//
//  HighScoreStorage.swift
//  PewPewPlanets
//
//  Created by Paul Devlin on 12/12/17.
//  Copyright © 2017 Paul Devlin. All rights reserved.
//

import Foundation

// Manage local storage of the user's high score
class HighScoreStorage {
    
    // avoid making a new instance of HighScoreStorage for
    // every class that needs to use it
    static var shared = HighScoreStorage()
    
    // return an old high score from UserDefaults or zero if no high score exists
    func getHighScore() -> Int {
        let highScore = UserDefaults.standard.string(forKey: "highScore")
        if let savedHighScore = highScore {
            return Int(savedHighScore) ?? 0
        } else {
            return 0
        }
    }
    
    // save a new high score to UserDefaults
    func saveHighScore(newHighScore: Int) {
        UserDefaults.standard.set(String(newHighScore), forKey: "highScore")
        // ensure that the high score is ready to be retrieved
        UserDefaults.standard.synchronize()
    }
}
