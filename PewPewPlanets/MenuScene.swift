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
    
    let tutorialButton = SKLabelNode()
    
    override init(size: CGSize) {
        super.init(size: size)
        
        backgroundColor = SKColor.black
        let playInstruction = SKLabelNode()
        playInstruction.fontColor = SKColor.white
        playInstruction.text = "tap anywhere to play"
        playInstruction.fontSize = 30
        playInstruction.fontName = "Avenir-Black"
        playInstruction.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(playInstruction)
        
        tutorialButton.fontColor = SKColor.white
        tutorialButton.text = "tutorial"
        tutorialButton.fontSize = 30
        tutorialButton.fontName = "Avenir-Black"
        tutorialButton.position = CGPoint(x: size.width / 2, y: size.height / 2 * 0.8)
        
        addChild(tutorialButton)
    }
    
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let touchLocation = touch!.location(in: self)
        
        if tutorialButton.contains(touchLocation) {
            let reveal = SKTransition.moveIn(with: .right, duration: 0.3)
            let tutorialScene1 = TutorialScene1(size: self.size)
            self.view?.presentScene(tutorialScene1, transition: reveal)
        } else {
            let reveal = SKTransition.doorsOpenVertical(withDuration: 0.2)
            let gameScene = GameScene(size: self.size)
            self.view?.presentScene(gameScene, transition: reveal)
        }
        
    }
}
