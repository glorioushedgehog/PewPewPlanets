//
//  TutorialScene1.swift
//  PewPewPlanets
//
//  Created by Paul Devlin on 12/9/17.
//  Copyright © 2017 Paul Devlin. All rights reserved.
//

import SpriteKit
import GameplayKit
// show enemies shooting the player
// and tell they player that they are
// invulnerable to enemy fire
class TutorialScene1: SKScene {
    // used for choosing locations of stars
    // and the starting and ending positions
    // of enemies that will traverse the screen
    private let random: GKMersenneTwisterRandomSource
    // allows the player to go to the second part of
    // the tutorial
    private let nextButton: SKShapeNode
    // the position which all the enemies will shoot at
    private let playerPosition: CGPoint
    private let enemyBulletSpeed: CGFloat
    private let enemySpeed: CGFloat
    private let enemyRadius: CGFloat
    private let starZPosition: CGFloat = 0
    private let enemyZPosition: CGFloat = 1
    private let playerZPosition: CGFloat = 2
    private let enemyBulletZPosition: CGFloat = 3
    // this will be applied to nextButton and
    // all SKLabelNodes
    private let uiZPosition: CGFloat = 4
    private let playerColor = UIColor(red: 0.4, green: 0.8, blue: 1, alpha: 1)
    private let enemyColor = UIColor(red: 1, green: 1, blue: 0.8, alpha: 1)
    private let enemyBulletColor = UIColor(red: 1, green: 0.2, blue: 0.2, alpha: 1)
    // this constructor is required for SKScene's
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // draw the tutorial scene
    override init(size: CGSize) {
        self.random = GKMersenneTwisterRandomSource()
        self.nextButton = SKShapeNode.init(rectOf: CGSize(width: 0.8 * size.width, height: 0.213 * size.width), cornerRadius: 0.008 * size.width)
        self.playerPosition = CGPoint(x: size.width / 2, y: 5 * size.height / 8)
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
        // spawn enemies that will go from
        // a randomly chosen side of the screen
        // to the opposite side over and over
        // while shooting the player
        for _ in 0...5 {
            chooseEnemyPath()
        }
        // draw the tutorial text
        drawText(toDraw: "Planets are pew pewing you?", atHeight: 7 * size.height / 8)
        drawText(toDraw: "Fools!", atHeight: size.height / 3)
        drawText(toDraw: "You are invincible!", atHeight: size.height / 4)
        // this is just a black rectangle that will be behind the first
        // line of text to make sure it is not obscured by enemies passing
        // beneath it
        let background1 = SKShapeNode.init(rectOf: CGSize(width: 0.8 * size.width, height: 0.15 * size.width), cornerRadius: 0.008 * size.width)
        background1.zPosition = uiZPosition
        background1.position = CGPoint(x: size.width / 2, y: 7 * size.height / 8)
        background1.fillColor = .black
        background1.strokeColor = .black
        addChild(background1)
        // this is another black rectangle that will go behind
        // the second and third line of text to ensure they are
        // legible
        let background2 = SKShapeNode.init(rectOf: CGSize(width: 0.8 * size.width, height: 0.3 * size.width), cornerRadius: 0.008 * size.width)
        background2.zPosition = uiZPosition
        background2.position = CGPoint(x: size.width / 2, y: 0.3 * size.height)
        background2.fillColor = .black
        background2.strokeColor = .black
        addChild(background2)
        // add the button the user
        // will press to go to the
        // second part of the tutorial
        addNextButton()
    }
    // randomly choose a side of the screen
    // which an enemy will start at and randomly
    // choose a position on the opposite side of the screen
    // the enemy will go to
    func chooseEnemyPath() {
        // (x1, y1) is the enemy's starting position,
        // (x2, y2) is the enemy's ending position
        let x1, y1, x2, y2: CGFloat
        if random.nextBool() {
            // this enemy will either be going
            // left to right or right to left, so
            // choose random y values
            y1 = size.height * CGFloat(random.nextUniform())
            y2 = size.height * CGFloat(random.nextUniform())
            if random.nextBool() {
                // the enemy will go from the left side
                // of the screen to the right
                x1 = -2 * enemyRadius
                x2 = size.width + 2 * enemyRadius
            } else {
                // the enemy will go from the right side
                // of the screen to the left
                x1 = size.width + 2 * enemyRadius
                x2 = -2 * enemyRadius
            }
        } else {
            // this enemy will be going top to
            // bottom or bottom to top, so choose random
            // x values
            x1 = size.height * CGFloat(random.nextUniform())
            x2 = size.height * CGFloat(random.nextUniform())
            if random.nextBool() {
                // the enemy will go from the
                // bottom of the screen to the top
                y1 = -2 * enemyRadius
                y2 = size.height + 2 * enemyRadius
            } else {
                // the enemy will go from the top
                // of the screen to the bottom
                y1 = size.height + 2 * enemyRadius
                y2 = -2 * enemyRadius
            }
        }
        let startingPosition = CGPoint(x: x1, y: y1)
        let endingPosition = CGPoint(x: x2, y: y2)
        // make a new enemy that will go from starting position to
        // ending position over and over forever
        addEnemy(startingPosition: startingPosition, endingPosition: endingPosition)
    }
    // define and add an enemy that will go from starting position to
    // endingPosition while shooting the player, then repeat the process
    // again over and over
    func addEnemy(startingPosition: CGPoint, endingPosition: CGPoint) {
        let enemy = SKShapeNode.init(circleOfRadius: enemyRadius)
        enemy.position = startingPosition
        enemy.zPosition = enemyZPosition
        enemy.fillColor = enemyColor
        enemy.strokeColor = enemyColor
        // make the enemy shoot at the player every
        // 0.5 seconds
        let shootSequence = [SKAction.wait(forDuration: 0.5),
                             SKAction.run { self.addEnemyBullet(enemy: enemy) }]
        enemy.run(SKAction.repeatForever(SKAction.sequence(shootSequence)))
        // find the amount of find it should take the enemy to get from
        // starting position to ending position if the enemy is travelling at
        // enemySpeed
        let durationSeconds = duration(from: startingPosition, to: endingPosition, with: enemySpeed)
        // move the enemy from starting position to ending position at enemySpeed, then reset
        // it to starting position so the process can repeat
        let moveSequence = [SKAction.move(to: endingPosition, duration: durationSeconds),
                            SKAction.move(to: startingPosition, duration: 0)]
        enemy.run(SKAction.repeatForever(SKAction.sequence(moveSequence)))
        addChild(enemy)
    }
    // define and add the button the player will tap
    // to go to the second part of the tutorial
    func addNextButton() {
        let nextButtonText = SKLabelNode()
        nextButtonText.fontColor = SKColor.white
        nextButtonText.text = "next"
        nextButtonText.fontSize = 0.08 * size.width
        nextButtonText.fontName = "Avenir-Black"
        // make the text centered vertically in the button
        nextButtonText.verticalAlignmentMode = .center
        nextButton.addChild(nextButtonText)
        nextButton.fillColor = .black
        nextButton.zPosition = uiZPosition
        nextButton.position = CGPoint(x: size.width / 2, y: size.height / 8)
        addChild(nextButton)
    }
    // draw the given string as an SKLabelNode, centered horizontally
    // at the given height
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
    // add a bullet at the position of the given enemy
    // which will move to the player, then be deleted
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
        // rotate the bullet in the direction it will travel
        enemyBullet.zRotation = atan2(dy, dx)
        // make the move from the enemy's position to the player's
        // position take the amount of time such that the bullet moves at
        // enemyBulletSpeed
        let durationSeconds = duration(from: enemy.position, to: playerPosition, with: enemyBulletSpeed)
        // make the bullet move to the player, then be deleted
        let sequence = [SKAction.move(to: playerPosition, duration: durationSeconds),
                        SKAction.removeFromParent()]
        enemyBullet.run(SKAction.sequence(sequence))
        addChild(enemyBullet)
    }
    // determine the amount of time it will take to travel from
    // starting position to ending position if moving at the given speed
    func duration(from startingPosition: CGPoint, to endingPosition: CGPoint, with speed: CGFloat) -> TimeInterval {
        let dx = startingPosition.x - endingPosition.x
        let dy = startingPosition.y - endingPosition.y
        let distance = sqrt(dx * dx + dy * dy)
        let duration = distance / speed
        return TimeInterval(duration)
    }
    // place a star on screen in a random location
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
    // present the second part of the tutorial if
    // the user taps up in the nextButton
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // only consider the first touch
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
