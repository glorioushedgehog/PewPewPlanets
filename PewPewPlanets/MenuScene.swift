//
//  MenuScene.swift
//  PewPewPlanets
//
//  Created by Paul Devlin on 12/8/17.
//  Copyright © 2017 Paul Devlin. All rights reserved.
//

import SpriteKit

class MenuScene: SKScene {
    
    let tutorialButton: SKShapeNode
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(size: CGSize) {
        self.tutorialButton = SKShapeNode.init(rectOf: CGSize(width: 0.267 * size.width, height: 0.133 * size.width), cornerRadius: 3)
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
        let highScore = HighScoreStorage.shared.getHighScore()
        drawText(text: "PEW PEW", fontSize: 0.16 * size.width, atHeight: 7 * size.height / 8)
        drawText(text: "PLANETS", fontSize: 0.16 * size.width, atHeight: 6 * size.height / 8)
        if highScore != 0 {
            drawText(text: "high score: " + String(highScore), fontSize: 0.053 * size.width, atHeight: 5 * size.height / 8)
        }
        drawText(text: "tap screen to play", fontSize: 0.053 * size.width, atHeight: size.height / 8)
        let tutorialButtontext = SKLabelNode()
        tutorialButtontext.text = "tutorial"
        tutorialButtontext.fontColor = SKColor.white
        tutorialButtontext.fontSize = 0.053 * size.width
        tutorialButtontext.fontName = "Avenir-Black"
        tutorialButtontext.verticalAlignmentMode = .center
        tutorialButton.addChild(tutorialButtontext)
        tutorialButton.zPosition = 1
        tutorialButton.position = CGPoint(x: size.width / 2, y: 3 * size.height / 8)
        addChild(tutorialButton)
    }
    func drawText(text: String, fontSize: CGFloat, atHeight: CGFloat) {
        let labelNode = SKLabelNode()
        labelNode.fontColor = SKColor.white
        labelNode.text = text
        labelNode.fontSize = fontSize
        labelNode.fontName = "Avenir-Black"
        labelNode.zPosition = 1
        labelNode.position = CGPoint(x: size.width / 2, y: atHeight)
        addChild(labelNode)
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
