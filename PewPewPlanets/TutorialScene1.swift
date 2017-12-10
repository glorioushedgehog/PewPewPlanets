//
//  TutorialScene1.swift
//  PewPewPlanets
//
//  Created by Paul Devlin on 12/9/17.
//  Copyright © 2017 Paul Devlin. All rights reserved.
//

import SpriteKit
//import GameplayKit

class TutorialScene1: SKScene {
    
    let nextButton = SKLabelNode()
    
    override init(size: CGSize) {
        super.init(size: size)
        
        backgroundColor = SKColor.black
        
        let playInstruction = SKLabelNode()
        playInstruction.fontColor = SKColor.white
        playInstruction.text = "enemies shoot you, you no vincible"
        playInstruction.fontSize = 30
        playInstruction.fontName = "Avenir-Black"
        playInstruction.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(playInstruction)
        
        nextButton.fontColor = SKColor.white
        nextButton.text = "next"
        nextButton.fontSize = 30
        nextButton.fontName = "Avenir-Black"
        nextButton.position = CGPoint(x: size.width / 2, y: size.height / 2 * 0.8)
        
        addChild(nextButton)
    }
    
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let touchLocation = touch!.location(in: self)
        
        if nextButton.contains(touchLocation) {
            let reveal = SKTransition.moveIn(with: .right, duration: 0.3)
            let tutorialScene2 = TutorialScene2(size: self.size)
            self.view?.presentScene(tutorialScene2, transition: reveal)
        }
    }
}
