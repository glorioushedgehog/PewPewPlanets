//
//  TutorialScene2.swift
//  PewPewPlanets
//
//  Created by Paul Devlin on 12/9/17.
//  Copyright © 2017 Paul Devlin. All rights reserved.
//

import SpriteKit
import GameplayKit
// show the player shooting enemies and tell the user
// how to shoot enemies and that they are vulnerable
// when they shoot enemies
class TutorialScene2: SKScene, SKPhysicsContactDelegate {
    // used for choosing locations for stars in the
    // background and where enemies spawn and where
    // they go
    private let random: GKMersenneTwisterRandomSource
    // the button the user will press to play the game
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
    // used for playButton and all text
    private let uiZPosition: CGFloat = 5
    private let playerColor = UIColor(red: 0.4, green: 0.8, blue: 1, alpha: 1)
    private let enemyColor = UIColor(red: 1, green: 1, blue: 0.8, alpha: 1)
    private let enemyBulletColor = UIColor(red: 1, green: 0.2, blue: 0.2, alpha: 1)
    // the name that will be given to enemies so
    // they can be found with enumerateChildNodes()
    private let enemyName = "enemy"
    // categories will be applied to enemies and player bullets
    // so collisions between them can be detected
    private let playerBulletCategory: UInt32 = 0x1 << 0
    private let enemyCategory: UInt32 = 0x1 << 1
    // this constructor is required for SKScene's
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // the player, the enemies they player will automatically shoot,
    // the tutorial text, and the play button
    override init(size: CGSize) {
        self.random = GKMersenneTwisterRandomSource()
        self.playButton = SKShapeNode.init(rectOf: CGSize(width: 0.8 * size.width, height: 0.213 * size.width), cornerRadius: 0.008 * size.width)
        self.playerPosition = CGPoint(x: size.width/2, y: 5 * size.height / 8)
        self.playerBulletSpeed = 2.67 * size.width
        self.enemySpeed = 0.533 * size.width
        self.enemyRadius = 0.0533 * size.width
        super.init(size: size)
        // prepare to detect collisions of physics bodies
        physicsWorld.contactDelegate = self
        // turn off the default downward gravity
        physicsWorld.gravity = CGVector.zero
        backgroundColor = SKColor.black
        // define and add the player
        let player = SKShapeNode.init(circleOfRadius: 0.0267 * size.width)
        player.position = playerPosition
        player.zPosition = playerZPosition
        player.fillColor = playerColor
        player.strokeColor = playerColor
        addChild(player)
        // add stars in random locations
        for _ in 0...20 {
            addStar()
        }
        // add some enemies to start.
        // most enemies will be added by the
        // timer started in startTimers()
        for _ in 0...5 {
            addEnemy()
        }
        // spawn enemies and player bullets
        // on intervals
        startTimers()
        // tell the player how to shoot enemies and that
        // they are vulnerable while shooting enemeis
        drawText(toDraw: "Tap the screen to pew pew back!", atHeight: 18 * size.height / 20)
        drawText(toDraw: "(it doesn't matter where you tap)", atHeight: 17 * size.height / 20)
        drawText(toDraw: "Be careful:", atHeight: 6 * size.height / 20)
        drawText(toDraw: "when pew pewing, you ARE", atHeight: 5 * size.height / 20)
        drawText(toDraw: "VULNERABLE!", atHeight: 4 * size.height / 20)
        // add backgrounds to the text to ensure its legibility
        buildTextBackgrounds()
        // add the play button to the scene
        buildPlayButton()
    }
    // add black rectangles behind the tutorial text so they
    // are not obscured when enemies pass beneath them
    func buildTextBackgrounds() {
        // this goes behind the first two lines
        // of text to make sure they are legible
        let background1 = SKShapeNode.init(rectOf: CGSize(width: 0.9 * size.width, height: 0.2 * size.width), cornerRadius: 0.008 * size.width)
        background1.zPosition = uiZPosition
        background1.position = CGPoint(x: size.width / 2, y: 7.1 * size.height / 8)
        background1.fillColor = .black
        background1.strokeColor = .black
        addChild(background1)
        // this goes behind the last three lines
        // of text to make sure they are legible
        let background2 = SKShapeNode.init(rectOf: CGSize(width: 0.8 * size.width, height: 0.3 * size.width), cornerRadius: 0.008 * size.width)
        background2.zPosition = uiZPosition
        background2.position = CGPoint(x: size.width / 2, y: 0.27 * size.height)
        background2.fillColor = .black
        background2.strokeColor = .black
        addChild(background2)
    }
    // define and add the play button
    func buildPlayButton() {
        let playButtonText = SKLabelNode()
        playButtonText.fontColor = SKColor.white
        playButtonText.text = "play"
        playButtonText.fontSize = 0.08 * size.width
        playButtonText.fontName = "Avenir-Black"
        // make the text centered vertically in the button
        playButtonText.verticalAlignmentMode = .center
        playButton.addChild(playButtonText)
        playButton.fillColor = .black
        playButton.zPosition = uiZPosition
        playButton.position = CGPoint(x: size.width / 2, y: size.height / 8)
        addChild(playButton)
    }
    // make enemies and player bullets spawn on intervals
    func startTimers() {
        // spawn an enemy every 0.1 seconds
        let enemySpawnSequence = [SKAction.run({ self.addEnemy() }),
                                  SKAction.wait(forDuration: 0.1)]
        run(SKAction.repeatForever(SKAction.sequence(enemySpawnSequence)))
        // spawn a player bullet every 0.2 seconds
        let firePlayerBulletSequence = [SKAction.run({ self.addPlayerBullet() }),
                                        SKAction.wait(forDuration: 0.2)]
        run(SKAction.repeatForever(SKAction.sequence(firePlayerBulletSequence)))
    }
    // add a player bullet which will be directed
    // towards the enemy that is closest to the player
    func addPlayerBullet() {
        // find the enemy that is closest to the player
        var shortestDistance = CGFloat.infinity
        var closestEnemy: SKShapeNode?
        enumerateChildNodes(withName: enemyName) { (enemy, stop) in
            let thisDistance = self.distanceFromPlayer(enemy: enemy)
            if thisDistance < shortestDistance {
                shortestDistance = thisDistance
                closestEnemy = enemy as? SKShapeNode
            }
        }
        // if there are no enemies to shoot, there is no
        // need to spawn a player bullet
        guard let enemyToShoot = closestEnemy else { return }
        let playerBullet = SKShapeNode.init(circleOfRadius: 0.0267 * size.width)
        playerBullet.fillColor = playerColor
        playerBullet.strokeColor = playerColor
        playerBullet.position = playerPosition
        playerBullet.zPosition = playerBulletZPosition
        playerBullet.physicsBody = SKPhysicsBody(circleOfRadius: 0.0267 * size.width)
        // find the velocity that will send the bullet towards enemyToShoot
        // at the spped playerBulletSpeed
        playerBullet.physicsBody?.velocity = playerAimVector(enemy: enemyToShoot)
        // keep player bullets from slowing down over time
        playerBullet.physicsBody?.linearDamping = 0
        // keep player bullets from being affected by any field nodes
        playerBullet.physicsBody?.fieldBitMask = 0
        // prepare to detect collisions between player bullets
        // and enemies
        playerBullet.physicsBody?.categoryBitMask = playerBulletCategory
        // allow player bullets to pass through other bodies in
        // the physics simulation
        playerBullet.physicsBody?.collisionBitMask = 0
        // delete the player bullet after some time in case
        // it missed the enemy it was aimed at
        let timeOutSequence = [SKAction.wait(forDuration: 5),
                               SKAction.removeFromParent()]
        playerBullet.run(SKAction.sequence(timeOutSequence))
        addChild(playerBullet)
    }
    // find the vector that will direct a bullet towards
    // the given enemy and whose magnitude is
    // playerBulletSpeed
    func playerAimVector(enemy: SKShapeNode) -> CGVector {
        let dx = enemy.position.x - playerPosition.x
        let dy = enemy.position.y - playerPosition.y
        let distance = distanceFromPlayer(enemy: enemy)
        // normalize the vector and multiply it by
        // playerBulletSpeed to make it have a magnitude of
        // playerBulletSpeed
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
    // return the distance between the given enemy
    // and the player
    func distanceFromPlayer(enemy: SKNode) -> CGFloat {
        let dx = enemy.position.x - playerPosition.x
        let dy = enemy.position.y - playerPosition.y
        return sqrt(dx * dx + dy * dy)
    }
    // pick a starting position and velocity for
    // an enemy randomly, then define and add the enemy
    func addEnemy() {
        let enemy = SKShapeNode.init(circleOfRadius: enemyRadius)
        let x: CGFloat
        let y: CGFloat
        let velocity: CGVector
        if random.nextBool() {
            // the enemy will either be going from the left
            // side of the screen to the right or from the
            // right side of the screen to the left, so pick
            // a random y coordinate for it to be spawned at
            y = size.height * CGFloat(random.nextUniform())
            if random.nextBool() {
                // this enemy will spawn on the left side of the
                // screen, so pick a random vector going to the right
                // whose magnitude is enemySpeed
                x = -2 * enemyRadius
                let dx = enemySpeed * CGFloat(random.nextUniform())
                let dy = sqrt(enemySpeed * enemySpeed - dx * dx)
                velocity = CGVector(dx: dx, dy: dy)
            } else {
                // this enemy will spawn on the right side of the
                // screen, so pick a random vector going to the left
                // whose magnitude is enemySpeed
                x = size.width + 2 * enemyRadius
                let dx = -enemySpeed * CGFloat(random.nextUniform())
                let dy = sqrt(enemySpeed * enemySpeed - dx * dx)
                velocity = CGVector(dx: dx, dy: dy)
            }
        } else {
            // the enemy will either be going from the bottom
            // of the screen to the top or from the
            // top of the screen to the bottom, so pick
            // a random x coordinate for it to be spawned at
            x = size.height * CGFloat(random.nextUniform())
            if random.nextBool() {
                // this enemy will spawn on the top of the
                // screen, so pick a random vector going down
                // whose magnitude is enemySpeed
                y = size.height + 2 * enemyRadius
                let dy = -enemySpeed * CGFloat(random.nextUniform())
                let dx = sqrt(enemySpeed * enemySpeed - dy * dy)
                velocity = CGVector(dx: dx, dy: dy)
            } else {
                // this enemy will spawn on the bottom of the
                // screen, so pick a random vector going up
                // whose magnitude is enemySpeed
                y = -2 * enemyRadius
                let dy = enemySpeed * CGFloat(random.nextUniform())
                let dx = sqrt(enemySpeed * enemySpeed - dy * dy)
                velocity = CGVector(dx: dx, dy: dy)
            }
        }
        enemy.position = CGPoint(x: x, y: y)
        enemy.zPosition = enemyZPosition
        // name the enemy so it can be found
        // by enumerateChildNodes()
        enemy.name = enemyName
        enemy.fillColor = enemyColor
        enemy.strokeColor = enemyColor
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemyRadius)
        enemy.physicsBody?.velocity = velocity
        // prevent the enemies from slowing down
        // over time
        enemy.physicsBody?.linearDamping = 0
        // make the enemy detectable in didBegin()
        enemy.physicsBody?.categoryBitMask = enemyCategory
        // make collision between enemies and player bullets get
        // passed to didBegin()
        enemy.physicsBody?.contactTestBitMask = playerBulletCategory
        // allow enemies to pass through other bodies in the
        // physics simulation
        enemy.physicsBody?.collisionBitMask = 0
        // remove enemies after some time in case the player did
        // not shoot them
        let timeOutSequence = [SKAction.wait(forDuration: 5),
                               SKAction.removeFromParent()]
        enemy.run(SKAction.sequence(timeOutSequence))
        addChild(enemy)
    }
    // detect collisions between enemies and player bullets
    func didBegin(_ contact: SKPhysicsContact) {
        // if either body has already been removed, we should
        // not do anything
        if contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil {
            return
        }
        // since the order in which the nodes are given is not
        // guarenteed, use arrays to make finding the correct order
        // easier
        var nodes = [contact.bodyA.node, contact.bodyB.node]
        let nodeCategories = [contact.bodyA.categoryBitMask, contact.bodyB.categoryBitMask]
        // this detects if this is a enemy-playerBullet collisison, regardless of the order
        // in which the nodes are given
        if nodeCategories.contains(enemyCategory) && nodeCategories.contains(playerBulletCategory) {
            // put the array in the desired order:
            // enemy first, playerBullet second
            if nodeCategories[0] == playerBulletCategory {
                nodes = nodes.reversed()
            }
            let enemy = nodes[0] as? SKShapeNode
            let playerBullet = nodes[1] as? SKShapeNode
            guard let deadEnemy = enemy else { return }
            guard let usedPlayerBullet = playerBullet else { return }
            // delete the enemy and the player bullet
            // and put an explosion animation at the location
            // of the enemy
            usedPlayerBullet.removeFromParent()
            deadEnemy.removeFromParent()
            addExplosion(at: deadEnemy.position)
        }
    }
    // add an explosion animation at the location
    // of an enemy that the player killed
    func addExplosion(at position: CGPoint) {
        // the explosion is just a particle emitter that
        // is turned off shortly after being turned on
        let deadEnemyEmitter = newEnemyDeathEmitter()
        guard let deadEnemyExplosion = deadEnemyEmitter else { return }
        deadEnemyExplosion.position = position
        deadEnemyExplosion.zPosition = particleZPosition
        // turn the particle emitter off after it has emitted some
        // particles, then remove it once the particles die out
        let sequence = [SKAction.wait(forDuration: 0.1),
                        SKAction.run { deadEnemyExplosion.particleBirthRate = 0; },
                        SKAction.wait(forDuration: 2),
                        SKAction.removeFromParent()]
        deadEnemyExplosion.run(SKAction.sequence(sequence))
        addChild(deadEnemyExplosion)
    }
    // draw the given string centered horizontally at the given height
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
    // place a star at a random location in the screen
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
    // get the particle emitter that will be used
    // to animate an explosion when an enemy is killed
    // by the player
    func newEnemyDeathEmitter() -> SKEmitterNode? {
        return SKEmitterNode(fileNamed: "EnemyDeath.sks")
    }
    // detect the player touching up in the play button
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // only consider the first touch
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
