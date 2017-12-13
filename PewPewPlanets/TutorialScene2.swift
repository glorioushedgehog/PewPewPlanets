//
//  TutorialScene2.swift
//  PewPewPlanets
//
//  Created by Paul Devlin on 12/9/17.
//  Copyright © 2017 Paul Devlin. All rights reserved.
//

import SpriteKit
import GameplayKit

class TutorialScene2: SKScene, SKPhysicsContactDelegate {
    private let random: GKMersenneTwisterRandomSource
    private let playButton: SKShapeNode
    private let playerPosition: CGPoint
    private let playerBulletSpeed: CGFloat
    private let enemySpeed: CGFloat
    private let enemyRadius: CGFloat
    private let starZPosition: CGFloat = 0
    private let particleZPosition: CGFloat = 1
    private let enemyZPosition: CGFloat = 2
    private let playerZPosition: CGFloat = 3
    private let playerBulletZPosition: CGFloat = 4
    private let uiZPosition: CGFloat = 5
    
    private let playerColor = UIColor(red: 0.4, green: 0.8, blue: 1, alpha: 1)
    private let enemyColor = UIColor(red: 1, green: 1, blue: 0.8, alpha: 1)
    private let enemyBulletColor = UIColor(red: 1, green: 0.2, blue: 0.2, alpha: 1)
    private let enemyName = "enemy"
    private let playerBulletCategory: UInt32 = 0x1 << 0
    private let enemyCategory: UInt32 = 0x1 << 1
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(size: CGSize) {
        self.random = GKMersenneTwisterRandomSource()
        self.playButton = SKShapeNode.init(rectOf: CGSize(width: 0.8 * size.width, height: 0.213 * size.width), cornerRadius: 0.008 * size.width)
        self.playerPosition = CGPoint(x: size.width/2, y: 5 * size.height / 8)
        self.playerBulletSpeed = 2.67 * size.width
        self.enemySpeed = 0.533 * size.width
        self.enemyRadius = 0.0533 * size.width
        super.init(size: size)
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector.zero
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
            addEnemy()
        }
        startTimers()
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
        playButton.fillColor = .black
        playButton.zPosition = uiZPosition
        playButton.position = CGPoint(x: size.width / 2, y: size.height / 8)
        addChild(playButton)
    }
    func startTimers() {
        let enemySpawnSequence = [SKAction.run({ self.addEnemy() }),
                                  SKAction.wait(forDuration: 0.1)]
        run(SKAction.repeatForever(SKAction.sequence(enemySpawnSequence)))
        let firePlayerBulletSequence = [SKAction.run({ self.addPlayerBullet() }),
                                        SKAction.wait(forDuration: 0.2)]
        run(SKAction.repeatForever(SKAction.sequence(firePlayerBulletSequence)))
    }
    func addPlayerBullet() {
        var shortestDistance = CGFloat.infinity
        var closestEnemy: SKShapeNode?
        enumerateChildNodes(withName: enemyName) { (enemy, stop) in
            let thisDistance = self.distanceFromPlayer(enemy: enemy)
            if thisDistance < shortestDistance {
                shortestDistance = thisDistance
                closestEnemy = enemy as? SKShapeNode
            }
        }
        guard let enemyToShoot = closestEnemy else { return }
        let playerBullet = SKShapeNode.init(circleOfRadius: 0.0267 * size.width)
        playerBullet.fillColor = playerColor
        playerBullet.strokeColor = playerColor
        playerBullet.position = playerPosition
        playerBullet.zPosition = playerBulletZPosition
        playerBullet.physicsBody = SKPhysicsBody(circleOfRadius: 0.0267 * size.width)
        playerBullet.physicsBody?.velocity = playerAimVector(enemy: enemyToShoot)
        playerBullet.physicsBody?.linearDamping = 0
        playerBullet.physicsBody?.fieldBitMask = 0
        playerBullet.physicsBody?.categoryBitMask = playerBulletCategory
        playerBullet.physicsBody?.collisionBitMask = 0
        let timeOutSequence = [SKAction.wait(forDuration: 5),
                               SKAction.removeFromParent()]
        playerBullet.run(SKAction.sequence(timeOutSequence))
        addChild(playerBullet)
    }
    func playerAimVector(enemy: SKShapeNode) -> CGVector {
        let dx = enemy.position.x - playerPosition.x
        let dy = enemy.position.y - playerPosition.y
        let distance = distanceFromPlayer(enemy: enemy)
        if let enemyVelocity = enemy.physicsBody?.velocity {
            let aimDx = playerBulletSpeed * dx / distance + enemyVelocity.dx
            let aimDy = playerBulletSpeed * dy / distance + enemyVelocity.dy
            return CGVector.init(dx: aimDx, dy: aimDy)
        } else {
            let aimDx = playerBulletSpeed * dx / distance
            let aimDy = playerBulletSpeed * dy / distance
            return CGVector.init(dx: aimDx, dy: aimDy)
        }
    }
    func distanceFromPlayer(enemy: SKNode) -> CGFloat {
        let dx = enemy.position.x - playerPosition.x
        let dy = enemy.position.y - playerPosition.y
        return sqrt(dx * dx + dy * dy)
    }
    func addEnemy() {
        let enemy = SKShapeNode.init(circleOfRadius: enemyRadius)
        let x: CGFloat
        let y: CGFloat
        let velocity: CGVector
        if random.nextBool() {
            y = size.height * CGFloat(random.nextUniform())
            if random.nextBool() {
                x = -2 * enemyRadius
                let dx = enemySpeed * CGFloat(random.nextUniform())
                let dy = sqrt(enemySpeed * enemySpeed - dx * dx)
                velocity = CGVector(dx: dx, dy: dy)
            } else {
                x = size.width + 2 * enemyRadius
                let dx = -enemySpeed * CGFloat(random.nextUniform())
                let dy = sqrt(enemySpeed * enemySpeed - dx * dx)
                velocity = CGVector(dx: dx, dy: dy)
            }
        } else {
            x = size.height * CGFloat(random.nextUniform())
            if random.nextBool() {
                y = size.height + 2 * enemyRadius
                let dy = -enemySpeed * CGFloat(random.nextUniform())
                let dx = sqrt(enemySpeed * enemySpeed - dy * dy)
                velocity = CGVector(dx: dx, dy: dy)
            } else {
                y = -2 * enemyRadius
                let dy = enemySpeed * CGFloat(random.nextUniform())
                let dx = sqrt(enemySpeed * enemySpeed - dy * dy)
                velocity = CGVector(dx: dx, dy: dy)
            }
        }
        enemy.position = CGPoint(x: x, y: y)
        enemy.zPosition = enemyZPosition
        enemy.name = enemyName
        enemy.fillColor = enemyColor
        enemy.strokeColor = enemyColor
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemyRadius)
        enemy.physicsBody?.velocity = velocity
        enemy.physicsBody?.linearDamping = 0
        enemy.physicsBody?.categoryBitMask = enemyCategory
        enemy.physicsBody?.contactTestBitMask = playerBulletCategory
        enemy.physicsBody?.collisionBitMask = 0
        let timeOutSequence = [SKAction.wait(forDuration: 5),
                               SKAction.removeFromParent()]
        enemy.run(SKAction.sequence(timeOutSequence))
        addChild(enemy)
    }
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil {
            return
        }
        var nodes = [contact.bodyA.node, contact.bodyB.node]
        let nodeCategories = [contact.bodyA.categoryBitMask, contact.bodyB.categoryBitMask]
        if nodeCategories.contains(enemyCategory) && nodeCategories.contains(playerBulletCategory) {
            if nodeCategories[0] == playerBulletCategory {
                nodes = nodes.reversed()
            }
            let enemy = nodes[0] as? SKShapeNode
            let playerBullet = nodes[1] as? SKShapeNode
            guard let deadEnemy = enemy else { return }
            guard let usedPlayerBullet = playerBullet else { return }
            usedPlayerBullet.removeFromParent()
            deadEnemy.removeFromParent()
            addExplosion(at: deadEnemy.position)
        }
    }
    func addExplosion(at position: CGPoint) {
        let deadEnemyEmitter = newEnemyDeathEmitter()
        guard let deadEnemyExplosion = deadEnemyEmitter else { return }
        deadEnemyExplosion.position = position
        deadEnemyExplosion.zPosition = particleZPosition
        deadEnemyExplosion.targetNode = self
        let sequence = [SKAction.wait(forDuration: 0.1),
                        SKAction.run { deadEnemyExplosion.particleBirthRate = 0; },
                        SKAction.wait(forDuration: 2),
                        SKAction.removeFromParent()]
        deadEnemyExplosion.run(SKAction.sequence(sequence))
        addChild(deadEnemyExplosion)
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
    func newEnemyDeathEmitter() -> SKEmitterNode? {
        return SKEmitterNode(fileNamed: "EnemyDeath.sks")
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
