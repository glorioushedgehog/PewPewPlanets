//
//  GameScene.swift
//  PewPewPlanets
//
//  Created by Paul Devlin on 11/29/17.
//  Copyright © 2017 Paul Devlin. All rights reserved.
//

import SpriteKit
import GameplayKit
func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    static var shared = GameScene(size: CGSize.zero)
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    private let random: GKMersenneTwisterRandomSource
    let player = SKShapeNode.init(circleOfRadius: 10)
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
    
    private let playerBulletSpeed: CGFloat = 1000
    let enemyBulletSpeed: CGFloat = 200
    let enemySpeed: CGFloat = 200 // used to be 100
    private let maxDistanceFromPlayer: CGFloat
    private let screenCenter: CGPoint
    let enemyRadius: CGFloat = 20
    private var playerIsVulnerable: Bool
    
    private let starZPosition: CGFloat = 0
    private let particleZPosition: CGFloat = 1
    private let enemyZPosition: CGFloat = 2
    private let playerBulletZPosition: CGFloat = 3
    private let enemyBulletZPosition: CGFloat = 4
    private let playerZPosition: CGFloat = 5
    
    private let playerColor = UIColor(red: 0.4, green: 0.8, blue: 1, alpha: 1)
    private let enemyColor = UIColor(red: 1, green: 1, blue: 0.8, alpha: 1)
    private let enemyBulletColor = UIColor(red: 1, green: 0.2, blue: 0.2, alpha: 1)
    
    override init(size: CGSize) {
        self.random = GKMersenneTwisterRandomSource()
        self.playerIsVulnerable = false
        self.screenCenter = CGPoint(x: size.width/2, y: size.height/2)
        self.maxDistanceFromPlayer = max(size.width, size.height)*0.6
        super.init(size: size)
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector.zero
        buildPlayer()
    }
    override func didMove(to view: SKView) {
        //physicsWorld.speed = 0.9
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
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil {
            return
        }
        let enemy: SKShapeNode?
        let playerBullet: SKShapeNode?
        if contact.bodyA.categoryBitMask == enemyCategory && contact.bodyB.categoryBitMask == playerBulletCategory {
            enemy = contact.bodyA.node as? SKShapeNode
            playerBullet = contact.bodyB.node as? SKShapeNode
        } else if contact.bodyA.categoryBitMask == playerBulletCategory && contact.bodyB.categoryBitMask == enemyCategory {
            playerBullet = contact.bodyA.node as? SKShapeNode
            enemy = contact.bodyB.node as? SKShapeNode
        } else if contact.bodyA.categoryBitMask == playerCategory && contact.bodyB.categoryBitMask == enemyBulletCategory {
            if playerIsVulnerable {
                endGame()
            }
            enemy = nil
            playerBullet = nil
        } else if contact.bodyA.categoryBitMask == enemyBulletCategory && contact.bodyB.categoryBitMask == playerCategory {
            if playerIsVulnerable {
                endGame()
            }
            enemy = nil
            playerBullet = nil
        } else {
            enemy = nil
            playerBullet = nil
        }
        if let deadEnemy = enemy, let usedPlayerBullet = playerBullet {
            deadEnemy.removeFromParent()
            usedPlayerBullet.removeFromParent()
            let deadEnemyEmitter = newEnemyDeathEmitter()
            if let deadEnemyExplosion = deadEnemyEmitter {
                deadEnemyExplosion.position = deadEnemy.position
                deadEnemyExplosion.zPosition = particleZPosition
                deadEnemyExplosion.targetNode = self
                let sequence = [SKAction.wait(forDuration: 0.1),
                                SKAction.run { deadEnemyExplosion.particleBirthRate = 0; },
                                SKAction.wait(forDuration: 2),
                                SKAction.removeFromParent()]
                deadEnemyExplosion.run(SKAction.sequence(sequence))
                addChild(deadEnemyExplosion)
            }
            deadEnemy.removeFromParent()
            addEnemy()
        }
    }
    func touchDown(atPoint pos : CGPoint) {
        if let bodiesTouchingPlayer = player.physicsBody?.allContactedBodies() {
            for body in bodiesTouchingPlayer {
                if body.categoryBitMask == enemyBulletCategory {
                    endGame()
                }
            }
        }
        playerIsVulnerable = true
        var shortestDistance = CGFloat.infinity
        var closestEnemy: SKShapeNode?
        enumerateChildNodes(withName: enemyName) { (enemy, stop) in
            let thisDistance = enemy.position.distance(point: self.player.position)
            if thisDistance < shortestDistance {
                shortestDistance = thisDistance
                closestEnemy = enemy as? SKShapeNode
            }
        }
        guard let enemyToShoot = closestEnemy else { return }
        let playerBullet = SKShapeNode.init(circleOfRadius: 10)
        playerBullet.name = playerBulletName
        playerBullet.fillColor = playerColor
        playerBullet.strokeColor = playerColor
        playerBullet.position = player.position
        playerBullet.zPosition = playerBulletZPosition
        //playerBullet.zRotation = angle(vector: player.position.aimVector(point: closestEnemy.position))
        //playerBullet.physicsBody = SKPhysicsBody(rectangleOf: CGSize.init(width: 10, height: 10))
        playerBullet.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        playerBullet.physicsBody?.velocity = player.position.aimVector(point: enemyToShoot.position, speed: playerBulletSpeed)
        playerBullet.physicsBody?.linearDamping = 0
        playerBullet.physicsBody?.fieldBitMask = 0
        playerBullet.physicsBody?.categoryBitMask = playerBulletCategory
        //playerBullet.physicsBody?.contactTestBitMask = 0
        playerBullet.physicsBody?.collisionBitMask = 0
        //playerBullet.physicsBody?.usesPreciseCollisionDetection = true
        addChild(playerBullet)
    }
    func buildPlayer() {
        player.fillColor = playerColor
        player.strokeColor = playerColor
        player.zPosition = playerZPosition
        
        let playerGravity = SKFieldNode.radialGravityField()
        playerGravity.strength = 1
        playerGravity.falloff = 2
        playerGravity.categoryBitMask = playerGravityCategory
        playerGravity.minimumRadius = 50
        player.addChild(playerGravity)
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        
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
        //player.physicsBody?.allowsRotation = false
        //player.physicsBody?.fieldBitMask = 0
    }
    func buildEnemy() -> SKShapeNode {
        let enemy = SKShapeNode.init(circleOfRadius: enemyRadius)
        enemy.name = enemyName
        enemy.fillColor = enemyColor
        enemy.strokeColor = enemyColor
        enemy.zPosition = enemyZPosition
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemyRadius)
        //enemy.physicsBody?.velocity = (player.physicsBody?.velocity)!
        let sequence = [SKAction.wait(forDuration: 0.5),
                        SKAction.run {
                            self.addEnemyBullet(enemy: enemy)}]
        enemy.run(SKAction.repeatForever(SKAction.sequence(sequence)))
        enemy.physicsBody?.fieldBitMask = playerGravityCategory
        enemy.physicsBody?.linearDamping = 0
        enemy.physicsBody?.categoryBitMask = enemyCategory
        enemy.physicsBody?.contactTestBitMask = playerBulletCategory
        enemy.physicsBody?.collisionBitMask = 0//enemyCategory
        let enemyGravity = SKFieldNode.radialGravityField()
        enemyGravity.strength = 1
        enemyGravity.falloff = 2
        enemyGravity.minimumRadius = 50
        enemyGravity.categoryBitMask = enemyGravityCategory
        enemy.addChild(enemyGravity)
        return enemy
    }
    func addEnemy() {
        let enemy = buildEnemy()
        if random.nextBool() {
            if random.nextBool() {
                let x = -2 * enemyRadius
                let y = size.height * CGFloat(random.nextUniform())
                enemy.position = CGPoint(x: x, y: y) + player.position - screenCenter
                enemy.physicsBody?.velocity = CGVector.init(dx: enemySpeed, dy: 0)
            } else {
                let x = size.width + 2 * enemyRadius
                let y = size.height*CGFloat(random.nextUniform())
                enemy.position = CGPoint(x: x, y: y) + player.position - screenCenter
                enemy.physicsBody?.velocity = CGVector.init(dx: -enemySpeed, dy: 0)
            }
        } else {
            if random.nextBool() {
                let x = size.width * CGFloat(random.nextUniform())
                let y = size.height +  2 * enemyRadius
                enemy.position = CGPoint(x: x, y: y) + player.position - screenCenter
                enemy.physicsBody?.velocity = CGVector.init(dx: 0, dy: -enemySpeed)
            } else {
                let x = size.width * CGFloat(random.nextUniform())
                let y = -2 * enemyRadius
                enemy.position = CGPoint(x: x, y: y) + player.position - screenCenter
                enemy.physicsBody?.velocity = CGVector.init(dx: 0, dy: enemySpeed)
            }
        }
        addChild(enemy)
    }
    func addEnemyBullet(enemy: SKShapeNode) {
        let enemyBullet = buildEnemyBullet()
        enemyBullet.position = enemy.position
        enemyBullet.physicsBody?.velocity = enemy.position.aimVector(point: player.position, speed: enemyBulletSpeed)
        enemyBullet.zRotation = angle(vector: enemy.position.aimVector(point: player.position, speed: enemyBulletSpeed))
        addChild(enemyBullet)
    }
    func buildEnemyBullet() -> SKShapeNode {
        let enemyBullet = SKShapeNode.init(rectOf: CGSize(width: 20, height: 10), cornerRadius: 3)
        enemyBullet.name = enemyBulletName
        enemyBullet.fillColor = enemyBulletColor
        enemyBullet.strokeColor = enemyBulletColor
        enemyBullet.zPosition = enemyBulletZPosition
        enemyBullet.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: 10))
        //enemyBullet.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        enemyBullet.physicsBody?.linearDamping = 0
        enemyBullet.physicsBody?.fieldBitMask = 0
        enemyBullet.physicsBody?.categoryBitMask = enemyBulletCategory
        enemyBullet.physicsBody?.contactTestBitMask = playerCategory
        enemyBullet.physicsBody?.collisionBitMask = 0
        //playerBullet.physicsBody?.usesPreciseCollisionDetection = true
        return enemyBullet
    }
    func addStar() {
        let star = SKShapeNode.init(rectOf: CGSize(width: 3, height: 3))
        star.name = starName
        star.fillColor = .white
        star.strokeColor = .white
        var x = 2*maxDistanceFromPlayer*CGFloat(random.nextUniform()) - (maxDistanceFromPlayer - size.width/2)
        var y = 2*maxDistanceFromPlayer*CGFloat(random.nextUniform()) - (maxDistanceFromPlayer - size.height/2)
        var pos = CGPoint(x: x, y: y)
        while pos.distance(point: player.position) > maxDistanceFromPlayer {
            x = 2*maxDistanceFromPlayer*CGFloat(random.nextUniform()) - (maxDistanceFromPlayer - size.width/2)
            y = 2*maxDistanceFromPlayer*CGFloat(random.nextUniform()) - (maxDistanceFromPlayer - size.height/2)
            pos = CGPoint(x: x, y: y)
        }
        star.position = pos
        star.zPosition = starZPosition
        addChild(star)
    }
    func moveStar(star: SKShapeNode) {
        let newX = 2*player.position.x - star.position.x
        let newY = 2*player.position.y - star.position.y
        star.position = CGPoint(x: newX, y: newY)
    }
    
    func touchUp(atPoint pos : CGPoint) {
        playerIsVulnerable = false
    }
    func endGame() {
        //let s = view?.texture(from: self)
        //view?.isPaused = true
        let reveal = SKTransition.doorsOpenVertical(withDuration: 0.2)
        let menuScene = MenuScene(size: self.size)
        self.view?.presentScene(menuScene, transition: reveal)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        var count = 0
        enumerateChildNodes(withName: enemyName) { (enemy, stop) in
            count += 1
            if enemy.position.distance(point: self.player.position) > self.maxDistanceFromPlayer {
                enemy.removeFromParent()
                self.addEnemy()
            }
        }
        if count > 6 {
            print("too many enemies")
        }
        enumerateChildNodes(withName: enemyBulletName) { (enemyBullet, stop) in
            if enemyBullet.position.distance(point: self.player.position) > self.maxDistanceFromPlayer {
                enemyBullet.removeFromParent()
            }
        }
        enumerateChildNodes(withName: playerBulletName) { (playerBullet, stop) in
            if playerBullet.position.distance(point: self.player.position) > self.maxDistanceFromPlayer {
                playerBullet.removeFromParent()
            }
        }
        enumerateChildNodes(withName: starName) { (star, stop) in
            if star.position.distance(point: self.player.position) > self.maxDistanceFromPlayer {
                if let starToMove = star as? SKShapeNode {
                    self.moveStar(star: starToMove)
                }
            }
        }
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

extension CGPoint { // should be in different class
    func difference(point: CGPoint) -> CGPoint {
        let dx = self.x - point.x
        let dy = self.y - point.y
        return CGPoint.init(x: dx, y: dy)
    }
    func distance(point: CGPoint) -> CGFloat {
        let dx = self.x - point.x
        let dy = self.y - point.y
        return sqrt(dx * dx + dy * dy)
    }
    func aimVector(point: CGPoint, speed: CGFloat) -> CGVector {
        let dx = point.x - self.x
        let dy = point.y - self.y
        let distance = self.distance(point: point)
        return CGVector.init(dx: speed * dx / distance, dy: speed * dy / distance)
    }
}
