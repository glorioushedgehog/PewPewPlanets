//
//  TutorialScene1.swift
//  PewPewPlanets
//
//  Created by Paul Devlin on 12/9/17.
//  Copyright © 2017 Paul Devlin. All rights reserved.
//

import SpriteKit
import GameplayKit

class TutorialScene1: SKScene {
    private let random: GKMersenneTwisterRandomSource
    private let nextButton: SKShapeNode
    private let playerPosition: CGPoint
    private let enemyBulletSpeed: CGFloat
    private let enemySpeed: CGFloat
    private let enemyRadius: CGFloat
    private let starZPosition: CGFloat = 0
    private let enemyZPosition: CGFloat = 1
    private let playerZPosition: CGFloat = 2
    private let enemyBulletZPosition: CGFloat = 3
    private let uiZPosition: CGFloat = 4
    private let playerColor = UIColor(red: 0.4, green: 0.8, blue: 1, alpha: 1)
    private let enemyColor = UIColor(red: 1, green: 1, blue: 0.8, alpha: 1)
    private let enemyBulletColor = UIColor(red: 1, green: 0.2, blue: 0.2, alpha: 1)
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(size: CGSize) {
        self.random = GKMersenneTwisterRandomSource()
        self.nextButton = SKShapeNode.init(rectOf: CGSize(width: 0.8 * size.width, height: 0.213 * size.width), cornerRadius: 0.008 * size.width)
        self.playerPosition = CGPoint(x: size.width/2, y: 5 * size.height / 8)
        self.enemyBulletSpeed = 0.8 * size.width
        self.enemySpeed = 0.533 * size.width
        self.enemyRadius = 0.0533 * size.width
        super.init(size: size)
        
        backgroundColor = SKColor.black
        let player = SKShapeNode.init(circleOfRadius: 0.0267 * size.width)
        player.position = playerPosition
        player.zPosition = playerZPosition
        player.fillColor = playerColor
        player.strokeColor = playerColor
        addChild(player)
        for _ in 0...20 {
            addStar()
        }
        for _ in 0...5 {
            chooseEnemyPath()
        }
        
        drawText(toDraw: "Planets are pew pewing you?", atHeight: 7 * size.height / 8)
        drawText(toDraw: "Fools!", atHeight: size.height / 3)
        drawText(toDraw: "You are invincible!", atHeight: size.height / 4)
        
        let background1 = SKShapeNode.init(rectOf: CGSize(width: 0.8 * size.width, height: 0.15 * size.width), cornerRadius: 0.008 * size.width)
        background1.zPosition = uiZPosition
        background1.position = CGPoint(x: size.width / 2, y: 7 * size.height / 8)
        background1.fillColor = .black
        background1.strokeColor = .black
        addChild(background1)
        
        let background2 = SKShapeNode.init(rectOf: CGSize(width: 0.8 * size.width, height: 0.3 * size.width), cornerRadius: 0.008 * size.width)
        background2.zPosition = uiZPosition
        background2.position = CGPoint(x: size.width / 2, y: 0.3 * size.height)
        background2.fillColor = .black
        background2.strokeColor = .black
        addChild(background2)
        
        addNextButton()
    }
    func chooseEnemyPath() {
        let x1, y1, x2, y2: CGFloat
        if random.nextBool() {
            y1 = size.height * CGFloat(random.nextUniform())
            y2 = size.height * CGFloat(random.nextUniform())
            if random.nextBool() {
                x1 = -2 * enemyRadius
                x2 = size.width + 2 * enemyRadius
            } else {
                x1 = size.width + 2 * enemyRadius
                x2 = -2 * enemyRadius
            }
        } else {
            x1 = size.height * CGFloat(random.nextUniform())
            x2 = size.height * CGFloat(random.nextUniform())
            if random.nextBool() {
                y1 = -2 * enemyRadius
                y2 = size.height + 2 * enemyRadius
            } else {
                y1 = size.height + 2 * enemyRadius
                y2 = -2 * enemyRadius
            }
        }
        let startingPosition = CGPoint(x: x1, y: y1)
        let endingPosition = CGPoint(x: x2, y: y2)
        addEnemy(startingPosition: startingPosition, endingPosition: endingPosition)
    }
    func addEnemy(startingPosition: CGPoint, endingPosition: CGPoint) {
        let enemy = SKShapeNode.init(circleOfRadius: enemyRadius)
        enemy.position = startingPosition
        enemy.zPosition = enemyZPosition
        enemy.fillColor = enemyColor
        enemy.strokeColor = enemyColor
        let shootSequence = [SKAction.wait(forDuration: 0.5),
                             SKAction.run { self.addEnemyBullet(enemy: enemy) }]
        enemy.run(SKAction.repeatForever(SKAction.sequence(shootSequence)))
        let durationSeconds = duration(from: startingPosition, to: endingPosition, with: enemySpeed)
        let moveSequence = [SKAction.move(to: endingPosition, duration: durationSeconds),
                            SKAction.move(to: startingPosition, duration: 0)]
        enemy.run(SKAction.repeatForever(SKAction.sequence(moveSequence)))
        addChild(enemy)
    }
    func addNextButton() {
        let nextButtonText = SKLabelNode()
        nextButtonText.fontColor = SKColor.white
        nextButtonText.text = "next"
        nextButtonText.fontSize = 0.08 * size.width
        nextButtonText.fontName = "Avenir-Black"
        nextButtonText.verticalAlignmentMode = .center
        nextButton.addChild(nextButtonText)
        nextButton.fillColor = .black
        nextButton.zPosition = uiZPosition
        nextButton.position = CGPoint(x: size.width / 2, y: size.height / 8)
        addChild(nextButton)
    }
    func drawText(toDraw: String, atHeight: CGFloat) {
        let text = SKLabelNode()
        text.fontColor = SKColor.white
        text.text = toDraw
        text.fontSize = 0.053 * size.width
        text.fontName = "Avenir-Black"
        text.zPosition = uiZPosition
        text.position = CGPoint(x: size.width / 2, y: atHeight)
        addChild(text)
    }
    func addEnemyBullet(enemy: SKShapeNode) {
        let width = 0.0533 * size.width
        let height = 0.0267 * size.width
        let enemyBullet = SKShapeNode.init(rectOf: CGSize(width: width, height: height), cornerRadius: 0.008 * size.width)
        enemyBullet.zPosition = enemyBulletZPosition
        enemyBullet.fillColor = enemyBulletColor
        enemyBullet.strokeColor = enemyBulletColor
        enemyBullet.position = enemy.position
        let dx = playerPosition.x - enemy.position.x
        let dy = playerPosition.y - enemy.position.y
        enemyBullet.zRotation = atan2(dy, dx)
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
    func addStar() {
        let star = SKShapeNode.init(rectOf: CGSize(width: 0.005 * size.width, height: 0.005 * size.width))
        star.fillColor = .white
        star.strokeColor = .white
        let x = size.width * CGFloat(random.nextUniform())
        let y = size.height * CGFloat(random.nextUniform())
        let pos = CGPoint(x: x, y: y)
        star.position = pos
        star.zPosition = starZPosition
        addChild(star)
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
