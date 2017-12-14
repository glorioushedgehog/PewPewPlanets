//
//  GameViewController.swift
//  PewPewPlanets
//
//  Created by Paul Devlin on 11/29/17.
//  Copyright © 2017 Paul Devlin. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        if let view = self.view as? SKView {
            let menuScene = MenuScene(size: view.bounds.size)
            // we want drawing order to be based on
            // the zPositions given to nodes, not
            // their relationships in the tree
            view.ignoresSiblingOrder = true
            view.presentScene(menuScene)
        }
    }
    // since this is a game, hide the status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
