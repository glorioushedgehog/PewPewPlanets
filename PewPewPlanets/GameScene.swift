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
    
    private let random: GKMersenneTwisterRandomSource
    private var player: SKShapeNode
    private var enemies: Set<SKShapeNode>
    private let playerGravityCategory: UInt32 = 0x1 << 0
    private let enemyGravityCategory: UInt32 = 0x1 << 1
    private let playerBulletCategory: UInt32 = 0x1 << 2
    private let enemyCategory: UInt32 = 0x1 << 3
    
    private var velocityMap: [SKShapeNode: CGVector]
    override init(size: CGSize) {
//        self.random = GKMersenneTwisterRandomSource()
//        self.playerX = CGFloat(size.width)/2
//        self.playerY = CGFloat(size.height)/2
//        let player = SKShapeNode.init(rectOf: CGSize.init(width: 10, height: 10), cornerRadius: 3)
//        player.fillColor = .gray
//        player.strokeColor = .gray
//        player.zRotation = CGFloat.pi/4
//        player.zPosition = 1
        
        self.random = GKMersenneTwisterRandomSource()
        self.player = SKShapeNode.init(circleOfRadius: 30)
        self.enemies = Set([])
        self.velocityMap = [SKShapeNode: CGVector]()
        super.init(size: size)
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector.zero
        //physicsWorld.speed = 0.5
        
        let screenCenter = CGPoint(x: size.width/2, y: size.height/2)
        let cameraNode = SKCameraNode()
        player.position = screenCenter
        player.addChild(cameraNode)
        camera = cameraNode
        
        let playerGravity = SKFieldNode.radialGravityField()
        playerGravity.strength = 1
        playerGravity.falloff = 2
        playerGravity.categoryBitMask = playerGravityCategory
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: 30)
        player.physicsBody?.isDynamic = false
        
        player.physicsBody?.categoryBitMask = 0
        player.physicsBody?.contactTestBitMask = 0
        player.physicsBody?.collisionBitMask = 0
        
        //player.physicsBody?.allowsRotation = false
        //player.physicsBody?.fieldBitMask = enemyGravityCategory
        //player.physicsBody?.fieldBitMask = 0
        player.addChild(playerGravity)
        addChild(player)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func didMove(to view: SKView) {
//        let gravityCategory: UInt32 = 0x1 << 0
//        let shieldCategory: UInt32 = 0x1 << 1
//        let gravity = SKFieldNode.radialGravityField()
//        gravity.strength = 0.1
//        gravity.categoryBitMask = gravityCategory
//
//        let planet = SKShapeNode.init(circleOfRadius: 50)
//        planet.position = screenCenter
//        planet.physicsBody = SKPhysicsBody(circleOfRadius: 50)
//
//        let ship = SKShapeNode.init(circleOfRadius: 20)
//        ship.position = CGPoint(x: size.width/2+100, y: size.height/2+100)
//        ship.physicsBody = SKPhysicsBody(circleOfRadius: 20)
//
//        let missile = SKShapeNode.init(circleOfRadius: 10)
//        missile.position = screenCenter
//        missile.physicsBody = SKPhysicsBody.init(circleOfRadius: 10)
//
//        planet.addChild(gravity)
//
//        ship.physicsBody?.fieldBitMask = gravityCategory
//        missile.physicsBody?.fieldBitMask = shieldCategory
//        let shield = SKFieldNode.radialGravityField()
//        shield.strength = 0
//        shield.categoryBitMask = shieldCategory
//        shield.region = SKRegion(radius: 100)
//        shield.falloff = 4
//        shield.run(SKAction.sequence([
//            SKAction.strength(to: 0, duration: 2.0),
//            SKAction.removeFromParent()
//            ]))
//        ship.addChild(shield)
        //let enemy = SKShapeNode.init(circleOfRadius: 20)
        //enemy.position = CGPoint.init(x: 100, y: 100)
        //enemy.run(SKAction.move(by: CGVector.init(dx: 100, dy: 100), duration: 5))
        //enemy.run(SKAction.sequence([SKAction.move(by: CGVector.init(dx: 100, dy: 100), duration: 5),
        //                             SKAction.removeFromParent()]))
        //enemy.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        //enemy.physicsBody?.velocity = (player.physicsBody?.velocity)!
        //enemy.physicsBody?.velocity = CGVector.init(dx: 100, dy: 100)
        //enemy.physicsBody?.fieldBitMask = playerGravityCategory
        
//        let enemyGravity = SKFieldNode.radialGravityField()
//        enemyGravity.strength = 1
//        enemyGravity.falloff = 2
//        enemyGravity.categoryBitMask = enemyGravityCategory

//        enemy.addChild(enemyGravity)
        //enemies.insert(enemy)
        //addChild(enemy)
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
        contact.bodyA.node?.removeFromParent()
        contact.bodyB.node?.removeFromParent()
        let enemy: SKShapeNode?
        //let playerBullet: SKShapeNode?
        if contact.bodyA.categoryBitMask == enemyCategory && contact.bodyB.categoryBitMask == playerBulletCategory {
            enemy = contact.bodyA.node as? SKShapeNode
            //playerBullet = contact.bodyB.node as? SKShapeNode
        } else if contact.bodyA.categoryBitMask == playerBulletCategory && contact.bodyB.categoryBitMask == enemyCategory {
            //playerBullet = contact.bodyA.node as? SKShapeNode
            enemy = contact.bodyB.node as? SKShapeNode
        } else {
            return
        }
        if enemy != nil {
            enemies.remove(enemy!)  // what is right way of doing this?
        }
    }
    
    func touchDown(atPoint pos : CGPoint) {
        
        addEnemy()
        
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
        playerBullet.position = player.position
        //playerBullet.zRotation = angle(vector: player.position.aimVector(point: closestEnemy.position))
        //playerBullet.physicsBody = SKPhysicsBody(rectangleOf: CGSize.init(width: 10, height: 10))
        playerBullet.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        playerBullet.physicsBody?.velocity = player.position.aimVector(point: (closestEnemy?.position)!)
        playerBullet.physicsBody?.fieldBitMask = 0
        
        playerBullet.physicsBody?.isDynamic = true
        playerBullet.physicsBody?.categoryBitMask = playerBulletCategory
        //playerBullet.physicsBody?.contactTestBitMask = 0
        playerBullet.physicsBody?.collisionBitMask = 0
        //playerBullet.physicsBody?.usesPreciseCollisionDetection = true
        
        addChild(playerBullet)
        
    }
    func addEnemy() {
        let enemy = SKShapeNode.init(circleOfRadius: 20)
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        //enemy.physicsBody?.velocity = (player.physicsBody?.velocity)!
        if random.nextBool() {
            if random.nextBool() {
                // left side
                enemy.position = CGPoint(x: 0, y: size.height*CGFloat(random.nextUniform()))
                enemy.physicsBody?.velocity = CGVector.init(dx: 100, dy: 0)
            } else {
                // right side
                enemy.position = CGPoint(x: size.width, y: size.height*CGFloat(random.nextUniform()))
                enemy.physicsBody?.velocity = CGVector.init(dx: -100, dy: 0)
            }
        } else {
            if random.nextBool() {
                // top
                enemy.position = CGPoint(x: size.width*CGFloat(random.nextUniform()), y: size.height)
                enemy.physicsBody?.velocity = CGVector.init(dx: 0, dy: -100)
            } else {
                // bottom
                enemy.position = CGPoint(x: size.width*CGFloat(random.nextUniform()), y: 0)
                enemy.physicsBody?.velocity = CGVector.init(dx: 0, dy: 100)
            }
        }
        enemy.physicsBody?.fieldBitMask = playerGravityCategory
        
        enemy.physicsBody?.isDynamic = true
        enemy.physicsBody?.categoryBitMask = enemyCategory
        enemy.physicsBody?.contactTestBitMask = playerBulletCategory
        enemy.physicsBody?.collisionBitMask = 0
        
        let enemyGravity = SKFieldNode.radialGravityField()
        enemyGravity.strength = 1
        enemyGravity.falloff = 2
        enemyGravity.categoryBitMask = enemyGravityCategory
        
        enemy.addChild(enemyGravity)
        enemies.insert(enemy)
        addChild(enemy)
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
    func aimVector(point: CGPoint) -> CGVector {
        let dx = point.x - self.x
        let dy = point.y - self.y
        let distance = self.distance(point: point)
        return CGVector.init(dx: 500*dx / distance, dy: 500*dy / distance)
    }
}
