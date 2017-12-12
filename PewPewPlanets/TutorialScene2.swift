//
//  TutorialScene2.swift
//  PewPewPlanets
//
//  Created by Paul Devlin on 12/9/17.
//  Copyright © 2017 Paul Devlin. All rights reserved.
//

import SpriteKit
//import GameplayKit

class TutorialScene2: SKScene {
    
    let playButton = SKShapeNode.init(rectOf: CGSize(width: 300, height: 80), cornerRadius: 3)
    
    override init(size: CGSize) {
        super.init(size: size)
        
        GameScene.shared = GameScene.init(size: CGSize.zero)
        
        backgroundColor = SKColor.black
        drawText(toDraw: "Shoot back by tapping the screen!", atHeight: 7 * size.height / 8)
        drawText(toDraw: "(it doesn't matter where you tap)", atHeight: 6 * size.height / 8)
        drawText(toDraw: "Be careful:", atHeight: 3 * size.height / 8)
        drawText(toDraw: "When shooting, you can DIE!", atHeight: 2 * size.height / 8)
        
        let playButtonText = SKLabelNode()
        playButtonText.fontColor = SKColor.white
        playButtonText.text = "play"
        playButtonText.fontSize = 30
        playButtonText.fontName = "Avenir-Black"
        playButtonText.verticalAlignmentMode = .center
        playButton.addChild(playButtonText)
        playButton.position = CGPoint(x: size.width / 2, y: size.height / 8)
        addChild(playButton)
    }
    
    func drawText(toDraw: String, atHeight: CGFloat) {
        let text = SKLabelNode()
        text.fontColor = SKColor.white
        text.text = toDraw
        text.fontSize = 20
        text.fontName = "Avenir-Black"
        text.position = CGPoint(x: size.width / 2, y: atHeight)
        addChild(text)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        guard let firstTouch = touch else { return }
        let touchLocation = firstTouch.location(in: self)
        if playButton.contains(touchLocation) {
            let reveal = SKTransition.moveIn(with: .right, duration: 0.5)
            let gameScene = GameScene(size: self.size)
            self.view?.presentScene(gameScene, transition: reveal)
        }
    }
}
