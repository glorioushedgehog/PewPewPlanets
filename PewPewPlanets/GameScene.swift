//
//  GameScene.swift
//  PewPewPlanets
//
//  Created by Paul Devlin on 11/29/17.
//  Copyright © 2017 Paul Devlin. All rights reserved.
//

import SpriteKit
import GameplayKit

// operator overrides should be in different class
func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    // maybe get rid of player gravity?
    // reuse enemies
    // need to be able to tell when enemies are about to shoot
    // more enemy bullets
    // slower enemy bullets
    // add stars
    // enemy spawn locations: chosen to give the player movement perpendicular to all enemies
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    private let random: GKMersenneTwisterRandomSource
    private var player: SKShapeNode
    private var enemies: Set<SKShapeNode>
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
    
    private let playerBulletSpeed: CGFloat = 500
    private let enemyBulletSpeed: CGFloat = 200
    private let maxDistanceFromPlayer: CGFloat
    private let screenCenter: CGPoint
    
    private var playerIsVulnerable: Bool
    private var playerVelocity: CGVector
    private var velocityMap: [SKShapeNode: CGVector]
    override init(size: CGSize) {
//        let player = SKShapeNode.init(rectOf: CGSize.init(width: 10, height: 10), cornerRadius: 3)
//        player.fillColor = .gray
//        player.strokeColor = .gray
//        player.zRotation = CGFloat.pi/4
//        player.zPosition = 1
        
        self.random = GKMersenneTwisterRandomSource()
        self.player = SKShapeNode.init(circleOfRadius: 10)
        self.playerVelocity = CGVector.zero
        self.enemies = Set([])
        self.playerIsVulnerable = false
        self.velocityMap = [SKShapeNode: CGVector]()
        self.screenCenter = CGPoint(x: size.width/2, y: size.height/2)
        self.maxDistanceFromPlayer = max(size.width, size.height)*1.2
        super.init(size: size)
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector.zero
        //physicsWorld.speed = 0.5
        backgroundColor = .black
        
        let cameraNode = SKCameraNode()
        player.position = screenCenter
        player.addChild(cameraNode)
        camera = cameraNode
        
        
        player.fillColor = .orange
        player.strokeColor = .orange
        player.zPosition = 2
        
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
            playerTrail.zPosition = 1
            playerTrail.targetNode = self
            player.addChild(playerTrail)
        }
        //player.physicsBody?.allowsRotation = false
        //player.physicsBody?.fieldBitMask = 0
        addChild(player)
        
        for _ in 0...170 {
            addStar()
        }
        
        for _ in 0...5 {
            addEnemy()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func didMove(to view: SKView) {
//        shield.region = SKRegion(radius: 100)
//        shield.falloff = 4
    }
    func didBegin(_ contact: SKPhysicsContact) {
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
                deadEnemyExplosion.zPosition = 1
                deadEnemyExplosion.targetNode = self
                deadEnemyExplosion.run(SKAction.sequence([SKAction.wait(forDuration: 0.1),
                                                          SKAction.run {
                                                            deadEnemyExplosion.particleBirthRate = 0;
                    },
                                                          SKAction.wait(forDuration: 2),
                                                          SKAction.removeFromParent()]))
                addChild(deadEnemyExplosion)
            }
            enemies.remove(deadEnemy)
            addEnemy()
        }
    }
    func touchDown(atPoint pos : CGPoint) {
        for body in (player.physicsBody?.allContactedBodies())! {
            // check if one of these is an enemy bullet, end game if it is
        }
        playerIsVulnerable = true
        if let currentPlayerVelocity = player.physicsBody?.velocity {
            playerVelocity = currentPlayerVelocity
        }
        player.physicsBody?.velocity = CGVector.zero
        player.physicsBody?.fieldBitMask = 0
        for enemy in enemies {
            velocityMap[enemy] = enemy.physicsBody?.velocity
            enemy.physicsBody?.velocity = CGVector.init(dx: 0, dy: 0)
            enemy.physicsBody?.fieldBitMask = 0
        }
        var shortestDistance = CGFloat.infinity
        var closestEnemy = enemies.first
        for enemy in enemies {
            let thisDistance = enemy.position.distance(point: player.position)
            if thisDistance < shortestDistance {
                shortestDistance = thisDistance
                closestEnemy = enemy
            }
        }
        //let playerBullet = SKShapeNode.init(rect: CGRect.init(x: player.position.x, y: player.position.y, width: 10, height: 10))
        let playerBullet = SKShapeNode.init(circleOfRadius: 10)
        playerBullet.name = playerBulletName
        playerBullet.fillColor = .orange
        playerBullet.strokeColor = .orange
        playerBullet.position = player.position
        //playerBullet.zRotation = angle(vector: player.position.aimVector(point: closestEnemy.position))
        //playerBullet.physicsBody = SKPhysicsBody(rectangleOf: CGSize.init(width: 10, height: 10))
        playerBullet.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        playerBullet.physicsBody?.velocity = player.position.aimVector(point: (closestEnemy?.position)!, speed: playerBulletSpeed)
        playerBullet.physicsBody?.linearDamping = 0
        playerBullet.physicsBody?.fieldBitMask = 0

        playerBullet.physicsBody?.categoryBitMask = playerBulletCategory
        //playerBullet.physicsBody?.contactTestBitMask = 0
        playerBullet.physicsBody?.collisionBitMask = 0
        //playerBullet.physicsBody?.usesPreciseCollisionDetection = true
        
        addChild(playerBullet)
    }
    func addEnemy() {
        let enemy = SKShapeNode.init(circleOfRadius: 20)
        enemy.name = enemyName
        enemy.fillColor = .yellow
        enemy.strokeColor = .yellow
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        //enemy.physicsBody?.velocity = (player.physicsBody?.velocity)!
        if random.nextBool() {
            if random.nextBool() {
                // left side
                enemy.position = CGPoint(x: 0, y: size.height*CGFloat(random.nextUniform())) + player.position - screenCenter
                enemy.physicsBody?.velocity = CGVector.init(dx: 100, dy: 0)
            } else {
                // right side
                enemy.position = CGPoint(x: size.width, y: size.height*CGFloat(random.nextUniform())) + player.position - screenCenter
                enemy.physicsBody?.velocity = CGVector.init(dx: -100, dy: 0)
            }
        } else {
            if random.nextBool() {
                // top
                enemy.position = CGPoint(x: size.width*CGFloat(random.nextUniform()), y: size.height) + player.position - screenCenter
                enemy.physicsBody?.velocity = CGVector.init(dx: 0, dy: -100)
            } else {
                // bottom
                enemy.position = CGPoint(x: size.width*CGFloat(random.nextUniform()), y: 0) + player.position - screenCenter
                enemy.physicsBody?.velocity = CGVector.init(dx: 0, dy: 100)
            }
        }
        enemy.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                                            SKAction.run {
                                                                self.addEnemyBullet(enemy: enemy)
            }])))
        enemy.physicsBody?.fieldBitMask = playerGravityCategory
        
        enemy.physicsBody?.isDynamic = true
        enemy.physicsBody?.categoryBitMask = enemyCategory
        enemy.physicsBody?.contactTestBitMask = playerBulletCategory
        enemy.physicsBody?.collisionBitMask = 0
        
        let enemyGravity = SKFieldNode.radialGravityField()
        enemyGravity.strength = 1
        enemyGravity.falloff = 2
        enemyGravity.minimumRadius = 50
        enemyGravity.categoryBitMask = enemyGravityCategory
        
        enemy.addChild(enemyGravity)
        enemies.insert(enemy)
        addChild(enemy)
    }
    
    func addEnemyBullet(enemy: SKShapeNode) {
        let enemyBullet = SKShapeNode.init(rectOf: CGSize(width: 20, height: 10), cornerRadius: 3)
        enemyBullet.name = enemyBulletName
        enemyBullet.fillColor = .red
        enemyBullet.strokeColor = .red
        enemyBullet.position = enemy.position
        enemyBullet.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        enemyBullet.physicsBody?.velocity = enemy.position.aimVector(point: player.position, speed: enemyBulletSpeed)
        enemyBullet.zRotation = angle(vector: enemy.position.aimVector(point: player.position, speed: enemyBulletSpeed))
        enemyBullet.physicsBody?.linearDamping = 0
        enemyBullet.physicsBody?.fieldBitMask = 0
        enemyBullet.physicsBody?.categoryBitMask = enemyBulletCategory
        enemyBullet.physicsBody?.contactTestBitMask = playerCategory
        enemyBullet.physicsBody?.collisionBitMask = 0
        //playerBullet.physicsBody?.usesPreciseCollisionDetection = true
        addChild(enemyBullet)
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
        addChild(star)
    }
    func moveStar(star: SKShapeNode) { // this does not work: stars move into camera
        let newX = 1.9*player.position.x - star.position.x
        let newY = 1.9*player.position.y - star.position.y
        star.position = CGPoint(x: newX, y: newY)
    }
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        for body in (player.physicsBody?.allContactedBodies())! {
            // check if one of these is an enemy bullet, end game if it is
        }
        playerIsVulnerable = false
        player.physicsBody?.velocity = playerVelocity
        player.physicsBody?.fieldBitMask = enemyGravityCategory
        for enemy in enemies {
            if let velocity = velocityMap[enemy] {
                enemy.physicsBody?.velocity = velocity
            }
            enemy.physicsBody?.fieldBitMask = playerGravityCategory
        }
    }
    func endGame() {
        let reveal = SKTransition.doorsOpenVertical(withDuration: 0.5)
        let menuScene = MenuScene(size: self.size)
        self.view?.presentScene(menuScene, transition: reveal)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        enumerateChildNodes(withName: enemyName) { (enemy, stop) in
            if enemy.position.distance(point: self.player.position) > self.maxDistanceFromPlayer {
                enemy.removeFromParent()
                self.enemies.remove(enemy as! SKShapeNode)
                self.addEnemy()
            }
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
                self.moveStar(star: star as! SKShapeNode)
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
