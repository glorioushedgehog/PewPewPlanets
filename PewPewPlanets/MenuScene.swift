//
//  MenuScene.swift
//  PewPewPlanets
//
//  Created by Paul Devlin on 12/8/17.
//  Copyright © 2017 Paul Devlin. All rights reserved.
//

import SpriteKit

// display the menu, which gives the
// player the option of seeing the tutorial
// or playing the game. it also shows the player's
// high score
class MenuScene: SKScene {
    // the button the player will press
    // to see the tutorial
    let tutorialButton: SKShapeNode
    // this contrstuctor is required for SKScenes
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // draw the menu
    override init(size: CGSize) {
        self.tutorialButton = SKShapeNode.init(rectOf: CGSize(width: 0.267 * size.width, height: 0.133 * size.width), cornerRadius: 3)
        super.init(size: size)
        backgroundColor = SKColor.black
        // the star emitter spawns particles
        // that look like stars on the top of the
        // screen. the particles fall down with varying
        // speeds.
        let starEmitter = newStarEmitter()
        if let starFallEmitter = starEmitter {
            // make the stars fall from the top of the screen
            starFallEmitter.position = CGPoint(x: size.width / 2, y: size.height)
            // make the stars fall from all across the top of the screen
            starFallEmitter.particlePositionRange = CGVector(dx: size.width, dy: 0)
            starFallEmitter.zPosition = 0
            addChild(starFallEmitter)
        }
        // get the user's high score from UserDefaults
        let highScore = HighScoreStorage.shared.getHighScore()
        // draw the title of the game
        drawText(text: "PEW PEW", fontSize: 0.16 * size.width, atHeight: 7 * size.height / 8)
        drawText(text: "PLANETS", fontSize: 0.16 * size.width, atHeight: 6 * size.height / 8)
        // draw the user's high score if it is not zero
        if highScore != 0 {
            drawText(text: "high score: " + String(highScore), fontSize: 0.053 * size.width, atHeight: 5 * size.height / 8)
        }
        // tell the user how to launch the game
        drawText(text: "tap screen to play", fontSize: 0.053 * size.width, atHeight: size.height / 8)
        // draw the button that would take
        // the user to the tutorial
        let tutorialButtontext = SKLabelNode()
        tutorialButtontext.text = "tutorial"
        tutorialButtontext.fontColor = SKColor.white
        tutorialButtontext.fontSize = 0.053 * size.width
        tutorialButtontext.fontName = "Avenir-Black"
        // make the text centered verticalled in the
        // button
        tutorialButtontext.verticalAlignmentMode = .center
        tutorialButton.addChild(tutorialButtontext)
        tutorialButton.zPosition = 1
        tutorialButton.position = CGPoint(x: size.width / 2, y: 3 * size.height / 8)
        addChild(tutorialButton)
    }
    // draw the given string as an SKLabelNode, centered
    // horizontally at the given height with the given font size
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
    // get the star emitter for the background
    func newStarEmitter() -> SKEmitterNode? {
        return SKEmitterNode(fileNamed: "StarFall.sks")
    }
    // launch the game if the user taps up outside
    // tutorial button, go to the tutorial otherwise
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // only consider the first touch
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
