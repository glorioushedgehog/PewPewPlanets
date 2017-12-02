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

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    // enemy spawns: either timer or constant number of alive enemies
    // enemy bullet spawns: per-enemy timer with SKAction.run
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
    
    private let playerBulletSpeed: CGFloat = 500
    private let enemyBulletSpeed: CGFloat = 200
    
    private let screenCenter: CGPoint
    
    private var playerVelocity: CGVector
    private var velocityMap: [SKShapeNode: CGVector]
    override init(size: CGSize) {
//        let player = SKShapeNode.init(rectOf: CGSize.init(width: 10, height: 10), cornerRadius: 3)
//        player.fillColor = .gray
//        player.strokeColor = .gray
//        player.zRotation = CGFloat.pi/4
//        player.zPosition = 1
        
        self.random = GKMersenneTwisterRandomSource()
        self.player = SKShapeNode.init(circleOfRadius: 30)
        self.playerVelocity = CGVector.zero
        self.enemies = Set([])
        self.velocityMap = [SKShapeNode: CGVector]()
        self.screenCenter = CGPoint(x: size.width/2, y: size.height/2)
        super.init(size: size)
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector.zero
        //physicsWorld.speed = 0.5
        
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
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: 30)
        //player.physicsBody?.isDynamic = false
        
        player.physicsBody?.fieldBitMask = enemyGravityCategory
        
        player.physicsBody?.categoryBitMask = 0
        player.physicsBody?.contactTestBitMask = 0
        player.physicsBody?.collisionBitMask = 0
        
        //player.physicsBody?.allowsRotation = false
        //player.physicsBody?.fieldBitMask = 0
        addChild(player)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func didMove(to view: SKView) {
//        shield.region = SKRegion(radius: 100)
//        shield.falloff = 4
        
        let playerTrailEmitter = newPlayerTrailEmitter()
        if let playerTrail = playerTrailEmitter {
            playerTrail.zPosition = 1
            playerTrail.targetNode = self
            player.addChild(playerTrail)
        }
        
        addEnemy()
        
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
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
        } else {
            return
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
        }
    }
    
    func touchDown(atPoint pos : CGPoint) {
        
        addEnemy()
        
        addEnemyBullets()
        
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
        playerBullet.fillColor = .orange
        playerBullet.strokeColor = .orange
        playerBullet.position = player.position
        //playerBullet.zRotation = angle(vector: player.position.aimVector(point: closestEnemy.position))
        //playerBullet.physicsBody = SKPhysicsBody(rectangleOf: CGSize.init(width: 10, height: 10))
        playerBullet.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        playerBullet.physicsBody?.velocity = player.position.aimVector(point: (closestEnemy?.position)!, speed: playerBulletSpeed)
        playerBullet.physicsBody?.fieldBitMask = 0

        playerBullet.physicsBody?.categoryBitMask = playerBulletCategory
        //playerBullet.physicsBody?.contactTestBitMask = 0
        playerBullet.physicsBody?.collisionBitMask = 0
        //playerBullet.physicsBody?.usesPreciseCollisionDetection = true
        
        addChild(playerBullet)
        
    }
    func addEnemy() {
        let enemy = SKShapeNode.init(circleOfRadius: 20)
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
        enemy.physicsBody?.fieldBitMask = playerGravityCategory
        
        enemy.physicsBody?.isDynamic = true
        enemy.physicsBody?.categoryBitMask = enemyCategory
        enemy.physicsBody?.contactTestBitMask = playerBulletCategory
        enemy.physicsBody?.collisionBitMask = 0
        
        let enemyGravity = SKFieldNode.radialGravityField()
        enemyGravity.strength = 0.5
        enemyGravity.falloff = 1
        enemyGravity.minimumRadius = 50
        enemyGravity.categoryBitMask = enemyGravityCategory
        
        enemy.addChild(enemyGravity)
        enemies.insert(enemy)
        addChild(enemy)
    }
    
    func addEnemyBullets() {
        for enemy in enemies {
            let enemyBullet = SKShapeNode.init(rectOf: CGSize(width: 10, height: 10))
            enemyBullet.fillColor = .red
            enemyBullet.strokeColor = .red
            enemyBullet.position = enemy.position
            enemyBullet.physicsBody = SKPhysicsBody(circleOfRadius: 5)
            enemyBullet.physicsBody?.velocity = enemy.position.aimVector(point: player.position, speed: enemyBulletSpeed)
            enemyBullet.physicsBody?.fieldBitMask = 0
            enemyBullet.physicsBody?.categoryBitMask = 0
            //playerBullet.physicsBody?.contactTestBitMask = 0
            enemyBullet.physicsBody?.collisionBitMask = 0
            //playerBullet.physicsBody?.usesPreciseCollisionDetection = true
            
            addChild(enemyBullet)
        }
    }
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
            //player.position = pos
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        player.physicsBody?.velocity = playerVelocity
        player.physicsBody?.fieldBitMask = enemyGravityCategory
        for enemy in enemies {
            if let velocity = velocityMap[enemy] {
                enemy.physicsBody?.velocity = velocity
            }
            enemy.physicsBody?.fieldBitMask = playerGravityCategory
        }
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
    }
    func angle(vector: CGVector) -> CGFloat {
        return atan(vector.dy/vector.dx)
    }
    func newPlayerTrailEmitter() -> SKEmitterNode? {
        return SKEmitterNode(fileNamed: "PlayerTrail.sks")
    }
    func newEnemyDeathEmitter() -> SKEmitterNode? {
        return SKEmitterNode(fileNamed: "EnemyDeath.sks")
    }
}

extension CGPoint {
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
