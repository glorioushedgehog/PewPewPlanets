//
//  GameOverScene.swift
//  PewPewPlanets
//
//  Created by Paul Devlin on 12/12/17.
//  Copyright © 2017 Paul Devlin. All rights reserved.
//

import SpriteKit

class GameOverScene: SKScene {
    
    let menuButton: SKShapeNode
    
    override init(size: CGSize) {
        self.menuButton = SKShapeNode.init(rectOf: CGSize(width: 0.267 * size.width, height: 0.133 * size.width), cornerRadius: 3)
        super.init(size: size)
    }
    func configure(numKills: Int) {
        backgroundColor = SKColor.black
        var highScore = HighScoreStorage.shared.getHighScore()
        if numKills > highScore {
            HighScoreStorage.shared.saveHighScore(newHighScore: numKills)
            highScore = numKills
        }
        drawText(text: "You died.", fontSize: 0.16 * size.width, atHeight: 7 * size.height / 8)
        drawText(text: "planets pewed: " + String(numKills), fontSize: 0.053 * size.width, atHeight: 16 * size.height / 20)
        drawText(text: "high score: " + String(highScore), fontSize: 0.053 * size.width, atHeight: 15 * size.height / 20)
        drawText(text: "tap screen to play again", fontSize: 0.053 * size.width, atHeight: size.height / 8)
        let menuButtonText = SKLabelNode()
        menuButtonText.text = "menu"
        menuButtonText.fontColor = SKColor.white
        menuButtonText.fontSize = 0.053 * size.width
        menuButtonText.fontName = "Avenir-Black"
        menuButtonText.verticalAlignmentMode = .center
        menuButton.addChild(menuButtonText)
        menuButton.zPosition = 1
        menuButton.position = CGPoint(x: size.width / 2, y: 2 * size.height / 8)
        addChild(menuButton)
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
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        guard let firstTouch = touch else { return }
        let touchLocation = firstTouch.location(in: self)
        
        if menuButton.contains(touchLocation) {
            let reveal = SKTransition.moveIn(with: .left, duration: 0.3)
            let menuScene = MenuScene(size: self.size)
            self.view?.presentScene(menuScene, transition: reveal)
        } else {
            let reveal = SKTransition.doorsOpenVertical(withDuration: 0.2)
            let gameScene = GameScene(size: self.size)
            self.view?.presentScene(gameScene, transition: reveal)
        }
    }
}