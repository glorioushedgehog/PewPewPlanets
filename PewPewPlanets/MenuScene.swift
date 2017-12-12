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
    
    let tutorialButton = SKShapeNode.init(rectOf: CGSize(width: 100, height: 50), cornerRadius: 3)
    
    override init(size: CGSize) {
        super.init(size: size)
        
        backgroundColor = SKColor.black
        
        let starEmitter = newStarEmitter()
        if let starFallEmitter = starEmitter {
            starFallEmitter.position = CGPoint(x: size.width / 2, y: size.height)
            starFallEmitter.particlePositionRange = CGVector(dx: size.width, dy: 0)
            starFallEmitter.zPosition = 0
            starFallEmitter.targetNode = self
            addChild(starFallEmitter)
        }
        
        let pewPewText = SKLabelNode()
        pewPewText.fontColor = SKColor.white
        pewPewText.text = "PEW PEW"
        pewPewText.fontSize = 60
        pewPewText.fontName = "Avenir-Black"
        pewPewText.zPosition = 1
        pewPewText.position = CGPoint(x: size.width / 2, y: 7 * size.height / 8)
        addChild(pewPewText)
        let planetsText = SKLabelNode()
        planetsText.fontColor = SKColor.white
        planetsText.text = "PLANETS"
        planetsText.fontSize = 60
        planetsText.fontName = "Avenir-Black"
        planetsText.zPosition = 1
        planetsText.position = CGPoint(x: size.width / 2, y: 6 * size.height / 8)
        addChild(planetsText)
        
        let tutorialButtontext = SKLabelNode()
        tutorialButtontext.text = "tutorial"
        tutorialButtontext.fontColor = SKColor.white
        tutorialButtontext.fontSize = 20
        tutorialButtontext.fontName = "Avenir-Black"
        tutorialButtontext.verticalAlignmentMode = .center
        tutorialButton.addChild(tutorialButtontext)
        tutorialButton.zPosition = 1
        tutorialButton.position = CGPoint(x: size.width / 2, y: 3 * size.height / 8)
        addChild(tutorialButton)
        
        let toPlayText = SKLabelNode()
        toPlayText.fontColor = SKColor.white
        toPlayText.text = "tap screen to play"
        toPlayText.fontSize = 20
        toPlayText.fontName = "Avenir-Black"
        toPlayText.zPosition = 1
        toPlayText.position = CGPoint(x: size.width / 2, y: size.height / 8)
        addChild(toPlayText)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func newStarEmitter() -> SKEmitterNode? {
        return SKEmitterNode(fileNamed: "StarFall.sks")
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        guard let firstTouch = touch else { return }
        let touchLocation = firstTouch.location(in: self)
        
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
