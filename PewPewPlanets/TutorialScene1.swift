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
    
    let nextButton = SKShapeNode.init(rectOf: CGSize(width: 300, height: 80), cornerRadius: 3)
    let playerPosition: CGPoint
    let enemyBulletSpeed: CGFloat = 300
    let enemySpeed: CGFloat
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(size: CGSize) {
        playerPosition = CGPoint(x: size.width/2, y: 5 * size.height / 8)
        enemySpeed = GameScene.shared.enemySpeed
        super.init(size: size)
        
        GameScene.shared = GameScene.init(size: CGSize.zero)
        
        backgroundColor = SKColor.black
        let player = GameScene.shared.player
        player.position = playerPosition
        player.zPosition = 1
        player.physicsBody?.isDynamic = false
        addChild(player)
        let enemyRadius = GameScene.shared.enemyRadius
        var startingPosition: CGPoint
        var endingPosition: CGPoint
        startingPosition = CGPoint(x: -2 * enemyRadius, y: 6 * size.height / 8)
        endingPosition = CGPoint(x: size.width + 2 * enemyRadius, y: 5 * size.height / 8)
        addEnemy(startingPosition: startingPosition, endingPosition: endingPosition)
        startingPosition = CGPoint(x: size.width / 3, y: -2 * enemyRadius)
        endingPosition = CGPoint(x: size.width / 5, y: size.height + 2 * enemyRadius)
        addEnemy(startingPosition: startingPosition, endingPosition: endingPosition)
        startingPosition = CGPoint(x: -2 * enemyRadius, y: 3 * size.height / 8)
        endingPosition = CGPoint(x: size.width + 2 * enemyRadius, y: 6 * size.height / 8)
        addEnemy(startingPosition: startingPosition, endingPosition: endingPosition)
        
        drawText(toDraw: "Planets are shooting you?", atHeight: 7 * size.height / 8)
        drawText(toDraw: "Fools!", atHeight: size.height / 3)
        drawText(toDraw: "You are invincible!", atHeight: size.height / 4)
        
        let nextButtonText = SKLabelNode()
        nextButtonText.fontColor = SKColor.white
        nextButtonText.text = "next"
        nextButtonText.fontSize = 30
        nextButtonText.fontName = "Avenir-Black"
        nextButtonText.verticalAlignmentMode = .center
        nextButton.addChild(nextButtonText)
        nextButton.zPosition = 2
        nextButton.position = CGPoint(x: size.width / 2, y: size.height / 8)
        
        addChild(nextButton)
    }
    func addEnemy(startingPosition: CGPoint, endingPosition: CGPoint) {
        let enemy = GameScene.shared.buildEnemy()
        enemy.position = startingPosition
        enemy.zPosition = 1
        enemy.physicsBody?.isDynamic = false
        let shootSequence = [SKAction.wait(forDuration: 0.5),
                             SKAction.run { self.addEnemyBullet(enemy: enemy) }]
        enemy.run(SKAction.repeatForever(SKAction.sequence(shootSequence)))
        let durationSeconds = duration(from: startingPosition, to: endingPosition, with: enemySpeed)
        let moveSequence = [SKAction.move(to: endingPosition, duration: durationSeconds),
                            SKAction.move(to: startingPosition, duration: 0)]
        enemy.run(SKAction.repeatForever(SKAction.sequence(moveSequence)))
        addChild(enemy)
    }
    func drawText(toDraw: String, atHeight: CGFloat) {
        let text = SKLabelNode()
        text.fontColor = SKColor.white
        text.text = toDraw
        text.fontSize = 20
        text.fontName = "Avenir-Black"
        text.zPosition = 2
        text.position = CGPoint(x: size.width / 2, y: atHeight)
        addChild(text)
    }
    func addEnemyBullet(enemy: SKShapeNode) {
        let enemyBullet = GameScene.shared.buildEnemyBullet()
        enemyBullet.zPosition = 1
        enemyBullet.position = enemy.position
        enemyBullet.zRotation = GameScene.shared.angle(vector: enemy.position.aimVector(point: playerPosition, speed: 1))
        enemyBullet.physicsBody?.isDynamic = false
        let durationSeconds = duration(from: enemy.position, to: playerPosition, with: enemyBulletSpeed)
        let sequence = [SKAction.move(to: playerPosition, duration: durationSeconds),
                        SKAction.removeFromParent()]
        enemyBullet.run(SKAction.sequence(sequence))
        addChild(enemyBullet)
    }
    
    func duration(from startingPosition: CGPoint, to endingPosition: CGPoint, with speed: CGFloat) -> TimeInterval {
        let dx = startingPosition.x - endingPosition.x
        let dy = startingPosition.y - endingPosition.y
        let distance = sqrt(dx * dx + dy * dy)
        let duration = distance / speed
        return TimeInterval(duration)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        guard let firstTouch = touch else { return }
        let touchLocation = firstTouch.location(in: self)
        
        if nextButton.contains(touchLocation) {
            let reveal = SKTransition.moveIn(with: .right, duration: 0.3)
            let tutorialScene2 = TutorialScene2(size: self.size)
            self.view?.presentScene(tutorialScene2, transition: reveal)
        }
    }
}
