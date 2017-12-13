//
//  GameScene.swift
//  PewPewPlanets
//
//  Created by Paul Devlin on 11/29/17.
//  Copyright © 2017 Paul Devlin. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    private let player: SKShapeNode
    private let random: GKMersenneTwisterRandomSource
    private let playerGravityCategory: UInt32 = 0x1 << 0
    private let enemyGravityCategory: UInt32 = 0x1 << 1
    private let playerBulletCategory: UInt32 = 0x1 << 2
    private let enemyCategory: UInt32 = 0x1 << 3
    private let enemyBulletCategory: UInt32 = 0x1 << 4
    private let playerCategory: UInt32 = 0x1 << 5
    
    private let enemyName = "enemy"
    private let enemyBulletName = "enemyBullet"
    private let playerBulletName = "playerBullet"
    private let starName = "star"
    
    private let playerBulletSpeed: CGFloat
    private let enemyBulletSpeed: CGFloat
    private let enemySpeed: CGFloat
    private let maxDistanceFromPlayer: CGFloat
    private let screenCenter: CGPoint
    private let enemyRadius: CGFloat
    private var playerIsVulnerable: Bool
    
    private let starZPosition: CGFloat = 0
    private let particleZPosition: CGFloat = 1
    private let enemyZPosition: CGFloat = 2
    private let playerBulletZPosition: CGFloat = 3
    private let enemyBulletZPosition: CGFloat = 4
    private let playerZPosition: CGFloat = 5
    private let uiZPosition: CGFloat = 6
    
    private let playerColor = UIColor(red: 0.4, green: 0.8, blue: 1, alpha: 1)
    private let enemyColor = UIColor(red: 1, green: 1, blue: 0.8, alpha: 1)
    private let enemyBulletColor = UIColor(red: 1, green: 0.2, blue: 0.2, alpha: 1)
    
    private let pauseButton: SKShapeNode
    private let menuButton: SKShapeNode
    private let resumeInstruction: SKShapeNode
    private let pausedBanner: SKShapeNode
    private let killCounter: SKLabelNode
    
    private var numKills = 0
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(size: CGSize) {
        self.player = SKShapeNode.init(circleOfRadius: 0.0267 * size.width)
        self.random = GKMersenneTwisterRandomSource()
        self.playerIsVulnerable = false
        self.screenCenter = CGPoint(x: size.width / 2, y: size.height / 2)
        self.maxDistanceFromPlayer = max(size.width, size.height) * 0.71
        self.playerBulletSpeed = 2.67 * size.width
        self.enemyBulletSpeed = 0.533 * size.width
        self.enemySpeed = 0.533 * size.width
        self.enemyRadius = 0.0533 * size.width
        self.pauseButton = SKShapeNode.init(rectOf: CGSize(width: 0.16 * size.width, height: 0.16 * size.width))
        self.menuButton = SKShapeNode.init(rectOf: CGSize(width: 0.267 * size.width, height: 0.133 * size.width), cornerRadius: 0.008 * size.width)
        self.resumeInstruction = SKShapeNode.init(rectOf: CGSize(width: 0.6 * size.width, height: 0.133 * size.width), cornerRadius: 0.008 * size.width)
        self.pausedBanner = SKShapeNode.init(rectOf: CGSize(width: 0.4 * size.width, height: 0.133 * size.width), cornerRadius: 0.008 * size.width)
        self.killCounter = SKLabelNode()
        super.init(size: size)
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector.zero
        buildPlayer()
    }
    override func didMove(to view: SKView) {
        backgroundColor = .black
        let cameraNode = SKCameraNode()
        player.position = screenCenter
        player.addChild(cameraNode)
        camera = cameraNode
        addChild(player)
        for _ in 0...50 {
            addStar()
        }
        for _ in 0...5 {
            addEnemy()
        }
        buildUI()
    }
    func buildUI() {
        menuButton.zPosition = uiZPosition
        menuButton.position = CGPoint(x: 0, y: -size.height / 4)
        menuButton.fillColor = .black
        let menuButtonText = buildTextNode(text: "quit", fontSize: 0.053 * size.width)
        menuButton.addChild(menuButtonText)
        
        resumeInstruction.zPosition = uiZPosition
        resumeInstruction.position = CGPoint(x: 0, y: -size.height / 2.5)
        resumeInstruction.fillColor = .black
        resumeInstruction.strokeColor = .black
        let resumeInstructionText = buildTextNode(text: "tap screen to resume", fontSize: 0.053 * size.width)
        resumeInstruction.addChild(resumeInstructionText)
        
        pausedBanner.zPosition = uiZPosition
        pausedBanner.position = CGPoint(x: 0, y: size.height / 4)
        pausedBanner.fillColor = .black
        pausedBanner.strokeColor = .black
        let pausedBannerText = buildTextNode(text: "paused", fontSize: 0.107 * size.width)
        pausedBanner.addChild(pausedBannerText)
        
        guard let cameraNode = camera else { return }
        buildPauseButton()
        cameraNode.addChild(pauseButton)
        buildKillCounter()
        cameraNode.addChild(killCounter)
    }
    func buildPauseButton() {
        let bar1 = SKShapeNode.init(rectOf: CGSize(width: 0.0267 * size.width, height: 0.08 * size.width))
        pauseButton.addChild(bar1)
        bar1.position = CGPoint(x: -0.0267 * size.width, y: 0)
        let bar2 = SKShapeNode.init(rectOf: CGSize(width: 0.0267 * size.width, height: 0.08 * size.width))
        pauseButton.addChild(bar2)
        bar2.position = CGPoint(x: 0.0267 * size.width, y: 0)
        pauseButton.strokeColor = .clear
        pauseButton.zPosition = uiZPosition
        pauseButton.position = CGPoint(x: 0.08 * size.width - size.width / 2, y: size.height / 2 - 0.08 * size.width)
    }
    func buildKillCounter() {
        killCounter.text = String(numKills)
        killCounter.zPosition = uiZPosition
        killCounter.fontColor = SKColor.white
        killCounter.fontSize = 0.133 * size.width
        killCounter.fontName = "Avenir-Black"
        killCounter.horizontalAlignmentMode = .right
        killCounter.verticalAlignmentMode = .top
        killCounter.position = CGPoint(x: size.width / 2 - 0.08 * size.width, y: size.height / 2 - 0.08 * size.width)
    }
    func buildTextNode(text: String, fontSize: CGFloat) -> SKLabelNode {
        let labelNode = SKLabelNode()
        labelNode.text = text
        labelNode.fontColor = SKColor.white
        labelNode.fontSize = fontSize
        labelNode.fontName = "Avenir-Black"
        labelNode.zPosition = uiZPosition
        labelNode.verticalAlignmentMode = .center
        return labelNode
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
            addEnemy()
            addExplosion(at: deadEnemy.position)
            numKills += 1
            killCounter.text = String(numKills)
        } else if nodeCategories.contains(playerCategory) && nodeCategories.contains(enemyBulletCategory) {
            if playerIsVulnerable {
                if nodeCategories[0] == playerCategory {
                    nodes = nodes.reversed()
                }
                let enemyBullet = nodes[0] as? SKShapeNode
                guard let killerBullet = enemyBullet else { return }
                endGame(killerBullet: killerBullet)
            }
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
    func shootEnemy() {
        if let bodiesTouchingPlayer = player.physicsBody?.allContactedBodies() {
            for body in bodiesTouchingPlayer {
                if body.categoryBitMask == enemyBulletCategory {
                    guard let killerBullet = body.node as? SKShapeNode else { return }
                    endGame(killerBullet: killerBullet)
                }
            }
        }
        playerIsVulnerable = true
        addPlayerBullet()
    }
    
    func addPlayerBullet() {
        var shortestDistance = CGFloat.infinity
        var closestEnemy: SKShapeNode?
        enumerateChildNodes(withName: enemyName) { (enemy, stop) in
            let thisDistance = self.distanceToPlayer(from: enemy)
            if thisDistance < shortestDistance {
                shortestDistance = thisDistance
                closestEnemy = enemy as? SKShapeNode
            }
        }
        guard let enemyToShoot = closestEnemy else { return }
        let playerBullet = SKShapeNode.init(circleOfRadius: 0.0267 * size.width)
        playerBullet.name = playerBulletName
        playerBullet.fillColor = playerColor
        playerBullet.strokeColor = playerColor
        playerBullet.position = player.position
        playerBullet.zPosition = playerBulletZPosition
        playerBullet.physicsBody = SKPhysicsBody(circleOfRadius: 0.0267 * size.width)
        playerBullet.physicsBody?.velocity = playerAimVector(enemy: enemyToShoot)
        playerBullet.physicsBody?.linearDamping = 0
        playerBullet.physicsBody?.fieldBitMask = 0
        playerBullet.physicsBody?.categoryBitMask = playerBulletCategory
        playerBullet.physicsBody?.collisionBitMask = 0
        addChild(playerBullet)
    }
    
    func buildPlayer() {
        player.fillColor = playerColor
        player.strokeColor = playerColor
        player.zPosition = playerZPosition
        
        let playerGravity = SKFieldNode.radialGravityField()
        playerGravity.strength = Float(0.00000711 * size.width * size.width)
        playerGravity.falloff = 2
        playerGravity.categoryBitMask = playerGravityCategory
        playerGravity.minimumRadius = Float(0.133 * size.width)
        player.addChild(playerGravity)
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: 0.0267 * size.width)
        player.physicsBody?.fieldBitMask = enemyGravityCategory
        player.physicsBody?.categoryBitMask = playerCategory
        player.physicsBody?.contactTestBitMask = 0
        player.physicsBody?.collisionBitMask = 0
        let playerTrailEmitter = newPlayerTrailEmitter()
        if let playerTrail = playerTrailEmitter {
            playerTrail.zPosition = particleZPosition
            playerTrail.targetNode = self
            player.addChild(playerTrail)
        }
    }
    func buildEnemy() -> SKShapeNode {
        let enemy = SKShapeNode.init(circleOfRadius: enemyRadius)
        enemy.name = enemyName
        enemy.fillColor = enemyColor
        enemy.strokeColor = enemyColor
        enemy.zPosition = enemyZPosition
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemyRadius)
        let sequence = [SKAction.wait(forDuration: 0.5),
                        SKAction.run {
                            self.addEnemyBullet(enemy: enemy)}]
        enemy.run(SKAction.repeatForever(SKAction.sequence(sequence)))
        enemy.physicsBody?.fieldBitMask = playerGravityCategory
        enemy.physicsBody?.linearDamping = 0
        enemy.physicsBody?.categoryBitMask = enemyCategory
        enemy.physicsBody?.contactTestBitMask = playerBulletCategory
        enemy.physicsBody?.collisionBitMask = 0
        let enemyGravity = SKFieldNode.radialGravityField()
        enemyGravity.strength = Float(0.00000711 * size.width * size.width)
        enemyGravity.falloff = 2
        enemyGravity.minimumRadius = Float(0.133 * size.width)
        enemyGravity.categoryBitMask = enemyGravityCategory
        enemy.addChild(enemyGravity)
        return enemy
    }
    func addEnemy() {
        let enemy = buildEnemy()
        if random.nextBool() {
            if random.nextBool() {
                let x = -2 * enemyRadius + player.position.x - screenCenter.x
                let y = size.height * CGFloat(random.nextUniform()) + player.position.y - screenCenter.y
                enemy.position = CGPoint(x: x, y: y)
                enemy.physicsBody?.velocity = CGVector.init(dx: enemySpeed, dy: 0)
            } else {
                let x = size.width + 2 * enemyRadius + player.position.x - screenCenter.x
                let y = size.height*CGFloat(random.nextUniform()) + player.position.y - screenCenter.y
                enemy.position = CGPoint(x: x, y: y)
                enemy.physicsBody?.velocity = CGVector.init(dx: -enemySpeed, dy: 0)
            }
        } else {
            if random.nextBool() {
                let x = size.width * CGFloat(random.nextUniform()) + player.position.x - screenCenter.x
                let y = size.height +  2 * enemyRadius + player.position.y - screenCenter.y
                enemy.position = CGPoint(x: x, y: y)
                enemy.physicsBody?.velocity = CGVector.init(dx: 0, dy: -enemySpeed)
            } else {
                let x = size.width * CGFloat(random.nextUniform()) + player.position.x - screenCenter.x
                let y = -2 * enemyRadius + player.position.y - screenCenter.y
                enemy.position = CGPoint(x: x, y: y)
                enemy.physicsBody?.velocity = CGVector.init(dx: 0, dy: enemySpeed)
            }
        }
        addChild(enemy)
    }
    func enemyAimVector(from enemy: SKShapeNode) -> CGVector {
        let dx = player.position.x - enemy.position.x
        let dy = player.position.y - enemy.position.y
        let distance = distanceToPlayer(from: enemy)
        let aimDx = enemyBulletSpeed * dx / distance
        let aimDy = enemyBulletSpeed * dy / distance
        return CGVector.init(dx: aimDx, dy: aimDy)
    }
    func addEnemyBullet(enemy: SKShapeNode) {
        let enemyBullet = buildEnemyBullet()
        enemyBullet.position = enemy.position
        let velocity = enemyAimVector(from: enemy)
        enemyBullet.physicsBody?.velocity = velocity
        enemyBullet.zRotation = angle(vector: velocity)
        addChild(enemyBullet)
    }
    func buildEnemyBullet() -> SKShapeNode {
        let width = 0.0533 * size.width
        let height = 0.0267 * size.width
        let enemyBullet = SKShapeNode.init(rectOf: CGSize(width: width, height: height), cornerRadius: 0.008 * size.width)
        enemyBullet.name = enemyBulletName
        enemyBullet.fillColor = enemyBulletColor
        enemyBullet.strokeColor = enemyBulletColor
        enemyBullet.zPosition = enemyBulletZPosition
        enemyBullet.physicsBody = SKPhysicsBody(circleOfRadius: height / 2)
        enemyBullet.physicsBody?.linearDamping = 0
        enemyBullet.physicsBody?.fieldBitMask = 0
        enemyBullet.physicsBody?.categoryBitMask = enemyBulletCategory
        enemyBullet.physicsBody?.contactTestBitMask = playerCategory
        enemyBullet.physicsBody?.collisionBitMask = 0
        return enemyBullet
    }
    func addStar() {
        let star = SKShapeNode.init(rectOf: CGSize(width: 0.005 * size.width, height: 0.005 * size.width))
        star.name = starName
        star.fillColor = .white
        star.strokeColor = .white
        var x = 2 * maxDistanceFromPlayer * CGFloat(random.nextUniform()) - (maxDistanceFromPlayer - size.width / 2)
        var y = 2 * maxDistanceFromPlayer * CGFloat(random.nextUniform()) - (maxDistanceFromPlayer - size.height / 2)
        star.position = CGPoint(x: x, y: y)
        while distanceToPlayer(from: star) > maxDistanceFromPlayer {
            x = 2 * maxDistanceFromPlayer * CGFloat(random.nextUniform()) - (maxDistanceFromPlayer - size.width / 2)
            y = 2 * maxDistanceFromPlayer * CGFloat(random.nextUniform()) - (maxDistanceFromPlayer - size.height / 2)
            star.position = CGPoint(x: x, y: y)
        }
        star.zPosition = starZPosition
        addChild(star)
    }
    func moveStar(star: SKShapeNode) {
        let newX = 2 * player.position.x - star.position.x
        let newY = 2 * player.position.y - star.position.y
        star.position = CGPoint(x: newX, y: newY)
    }
    
    func endGame(killerBullet: SKShapeNode) {
        let reveal = SKTransition.doorsOpenVertical(withDuration: 0)
        let gameOverScene = GameOverScene(size: self.size)
        let bulletPositionX = killerBullet.position.x - player.position.x + screenCenter.x
        let bulletPositionY = killerBullet.position.y - player.position.y + screenCenter.y
        let bulletPosition = CGPoint(x: bulletPositionX, y: bulletPositionY)
        gameOverScene.configure(numKills: numKills, killerBulletPosition: bulletPosition, killerBulletAngle: killerBullet.zRotation)
        self.view?.presentScene(gameOverScene, transition: reveal)
    }
    func pauseGame() {
        isPaused = true
        guard let cameraNode = camera else { return }
        cameraNode.addChild(pausedBanner)
        cameraNode.addChild(menuButton)
        cameraNode.addChild(resumeInstruction)
    }
    func resumeGame() {
        pausedBanner.removeFromParent()
        menuButton.removeFromParent()
        resumeInstruction.removeFromParent()
        isPaused = false
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isPaused {
            return
        }
        let touch = touches.first
        guard let firstTouch = touch else { return }
        guard let cameraNode = camera else { return }
        let touchLocation = firstTouch.location(in: cameraNode)
        
        if !pauseButton.contains(touchLocation) {
            shootEnemy()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        guard let firstTouch = touch else { return }
        guard let cameraNode = camera else { return }
        let touchLocation = firstTouch.location(in: cameraNode)
        if isPaused {
            if menuButton.contains(touchLocation) {
                let reveal = SKTransition.doorsOpenVertical(withDuration: 0.2)
                let menuScene = MenuScene(size: self.size)
                self.view?.presentScene(menuScene, transition: reveal)
            } else {
                resumeGame()
            }
        } else {
            if pauseButton.contains(touchLocation) {
                pauseGame()
            } else {
                playerIsVulnerable = false
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        playerIsVulnerable = false
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        enumerateChildNodes(withName: enemyName) { (enemy, stop) in
            if self.distanceToPlayer(from: enemy) > self.maxDistanceFromPlayer {
                enemy.removeFromParent()
                self.addEnemy()
            }
        }
        enumerateChildNodes(withName: enemyBulletName) { (enemyBullet, stop) in
            if self.distanceToPlayer(from: enemyBullet) > self.maxDistanceFromPlayer {
                enemyBullet.removeFromParent()
            }
        }
        enumerateChildNodes(withName: playerBulletName) { (playerBullet, stop) in
            if self.distanceToPlayer(from: playerBullet) > self.maxDistanceFromPlayer {
                playerBullet.removeFromParent()
            }
        }
        enumerateChildNodes(withName: starName) { (star, stop) in
            if self.distanceToPlayer(from: star) > self.maxDistanceFromPlayer {
                if let starToMove = star as? SKShapeNode {
                    self.moveStar(star: starToMove)
                }
            }
        }
    }
    func playerAimVector(enemy: SKShapeNode) -> CGVector {
        let dx = enemy.position.x - player.position.x
        let dy = enemy.position.y - player.position.y
        let distance = distanceToPlayer(from: enemy)
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
    func distanceToPlayer(from node: SKNode) -> CGFloat {
        let dx = node.position.x - player.position.x
        let dy = node.position.y - player.position.y
        return sqrt(dx * dx + dy * dy)
    }
    func angle(vector: CGVector) -> CGFloat {
        return atan2(vector.dy, vector.dx)
    }
    func newPlayerTrailEmitter() -> SKEmitterNode? {
        return SKEmitterNode(fileNamed: "PlayerTrail.sks")
    }
    func newEnemyDeathEmitter() -> SKEmitterNode? {
        return SKEmitterNode(fileNamed: "EnemyDeath.sks")
    }
}
