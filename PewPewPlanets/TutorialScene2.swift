//
//  TutorialScene2.swift
//  PewPewPlanets
//
//  Created by Paul Devlin on 12/9/17.
//  Copyright © 2017 Paul Devlin. All rights reserved.
//

import SpriteKit

class TutorialScene2: SKScene {
    
    let playButton: SKShapeNode
    
    override init(size: CGSize) {
        self.playButton = SKShapeNode.init(rectOf: CGSize(width: 0.8 * size.width, height: 0.213 * size.width), cornerRadius: 0.008 * size.width)
        super.init(size: size)
        
        backgroundColor = SKColor.black
        
        let player = GameScene.shared.player
        player.position = CGPoint(x: size.width/2, y: size.height/2)
        player.zPosition = 1
        player.physicsBody?.affectedByGravity = false
        player.removeFromParent()
        addChild(player)
        
        drawText(toDraw: "Shoot back by tapping the screen!", atHeight: 18 * size.height / 20)
        drawText(toDraw: "(it doesn't matter where you tap)", atHeight: 17 * size.height / 20)
        drawText(toDraw: "Be careful:", atHeight: 6 * size.height / 20)
        drawText(toDraw: "when shooting, you ARE", atHeight: 5 * size.height / 20)
        drawText(toDraw: "VULNERABLE to enemy fire!", atHeight: 4 * size.height / 20)
        
        let playButtonText = SKLabelNode()
        playButtonText.fontColor = SKColor.white
        playButtonText.text = "play"
        playButtonText.fontSize = 0.08 * size.width
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
        text.fontSize = 0.053 * size.width
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
