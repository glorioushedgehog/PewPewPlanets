//
//  MenuScene.swift
//  PewPewPlanets
//
//  Created by Paul Devlin on 12/8/17.
//  Copyright © 2017 Paul Devlin. All rights reserved.
//

import SpriteKit
//import GameplayKit

class MenuScene: SKScene {
    
    let playButton = SKLabelNode()
    
    override init(size: CGSize) {
        super.init(size: size)
        
        backgroundColor = SKColor.black
        
        playButton.fontColor = SKColor.white
        playButton.text = "play"
        playButton.fontSize = 60
        playButton.fontName = "Avenir-Black"
        playButton.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        addChild(playButton)
    }
    
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let touchLocation = touch!.location(in: self)
        
        if playButton.contains(touchLocation) {
            let reveal = SKTransition.doorsOpenVertical(withDuration: 0.1)
            let gameScene = GameScene(size: self.size)
            self.view?.presentScene(gameScene, transition: reveal)
        }
        
    }
    
    
}
