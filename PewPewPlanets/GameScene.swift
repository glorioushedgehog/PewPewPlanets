//
//  GameScene.swift
//  PewPewPlanets
//
//  Created by Paul Devlin on 11/29/17.
//  Copyright © 2017 Paul Devlin. All rights reserved.
//

import SpriteKit
import GameplayKit

// run the game as an SKPhysicsWorld
class GameScene: SKScene, SKPhysicsContactDelegate {
    // the blue circle in the middle of the screen.
    // the camera follows the player
    private let player: SKShapeNode
    // used for placing stars on the scene and
    // choosing where to spawn enemies
    private let random: GKMersenneTwisterRandomSource
    // the player's radial gravity node, which attracts
    // enemies
    private let playerGravityCategory: UInt32 = 0x1 << 0
    // each enemy as a radial gravity node, which attracts
    // the player
    private let enemyGravityCategory: UInt32 = 0x1 << 1
    // the bullets fired by the player when the user taps
    // the screen
    private let playerBulletCategory: UInt32 = 0x1 << 2
    private let enemyCategory: UInt32 = 0x1 << 3
    // enemies fire bullets constantly while they are alive
    private let enemyBulletCategory: UInt32 = 0x1 << 4
    private let playerCategory: UInt32 = 0x1 << 5
    
    // names used to enumerate nodes with
    // enumerateChildNodes(withName: , using: )
    private let enemyName = "enemy"
    private let enemyBulletName = "enemyBullet"
    private let playerBulletName = "playerBullet"
    private let starName = "star"
    
    // this is not exactly the speed at which
    // the player's bullets will move: the velocity
    // of the enemy the player is shooting will be
    // added to "lead" the target
    private let playerBulletSpeed: CGFloat
    // enemy bullets always travel at this speed
    private let enemyBulletSpeed: CGFloat
    // the initial speed of enemies. their
    // actual speed is always changing due to the
    // player's gravity
    private let enemySpeed: CGFloat
    // if a star, enemy, or bullet is farther than
    // this distance from the player, it will be
    // deleted (except stars: they are moved to the
    // other side of the player)
    private let maxDistanceFromPlayer: CGFloat
    // the coordinates of the center of the screen
    private let screenCenter: CGPoint
    // this needs to be remembered because enemies
    // should not be visible when they are spawned,
    // so they have to be spawned at enemyRadius away
    // from the edge of the screen
    private let enemyRadius: CGFloat
    // this is set to true when the player is touching
    // the screen and false when they are not.
    // it determines if the player dies when in contact
    // with an enemy bullet
    private var playerIsVulnerable: Bool
    // define the order in which nodes are drawn
    private let starZPosition: CGFloat = 0
    private let particleZPosition: CGFloat = 1
    private let enemyZPosition: CGFloat = 2
    private let playerBulletZPosition: CGFloat = 3
    private let enemyBulletZPosition: CGFloat = 4
    private let playerZPosition: CGFloat = 5
    // this is applied to the pause button, menu button,
    // resumeInstruction, pausedBanner, and killCounter
    private let uiZPosition: CGFloat = 6
    // the colors of the SKShapeNodes
    private let playerColor = UIColor(red: 0.4, green: 0.8, blue: 1, alpha: 1)
    private let enemyColor = UIColor(red: 1, green: 1, blue: 0.8, alpha: 1)
    private let enemyBulletColor = UIColor(red: 1, green: 0.2, blue: 0.2, alpha: 1)
    // the pause button will be in the top left of
    // the screen
    private let pauseButton: SKShapeNode
    // only appears when game is paused, takes
    // player back to menu
    private let menuButton: SKShapeNode
    // tells the player how to resuem the game when
    // it is paused
    private let resumeInstruction: SKShapeNode
    // tells the player the game is paused
    private let pausedBanner: SKShapeNode
    // in the top right corner of the screen,
    // indicates how many planets the player
    // has killed in this play of the game
    private let killCounter: SKLabelNode
    // keep track of the number of kills as
    // an Int to avoid converting Strings to Ints
    private var numKills = 0
    // subclasses of SKScene need this
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // define dimensions based on dimensions and screen
    // and initialize nodes
    override init(size: CGSize) {
        self.player = SKShapeNode.init(circleOfRadius: 0.0267 * size.width)
        self.random = GKMersenneTwisterRandomSource()
        self.playerIsVulnerable = false
        self.screenCenter = CGPoint(x: size.width / 2, y: size.height / 2)
        // the circle defined by maxDistanceFromPlayer should
        // be entirely outside the screen, or nodes would be deleted
        // while they are on screen. To guarantee that they are not,
        // we find the maximum screen dimension and multiply by 0.5
        // to get a radius for the circle. However, the radius is
        // greater at the corner of the screen, and it would be greatest
        // if the screen was square. In this case, we would need to multiply
        // by sqrt(2). 0.71 is greater than 0.5 * sqrt(2), so it guarantees
        // that the the circle contains the screen
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
        // prepare to detect collisions of player and
        // enemy bullets or enemies and player bullets
        physicsWorld.contactDelegate = self
        // turn off the gravity that would pull everything
        // to the bottom of the screen
        physicsWorld.gravity = CGVector.zero
        // define the player's appearance and physical
        // characteristics
        buildPlayer()
    }
    // draw the initial game scene
    override func didMove(to view: SKView) {
        backgroundColor = .black
        // the camera is added to player
        // so that the player will always be
        // in the screen center, regardless of
        // how he moves
        let cameraNode = SKCameraNode()
        player.position = screenCenter
        player.addChild(cameraNode)
        camera = cameraNode
        addChild(player)
        // add all the stars, which will be
        // moved around as the player moves
        for _ in 0...50 {
            addStar()
        }
        // add some enemies
        for _ in 0...5 {
            addEnemy()
        }
        // prepare the pause menu modes
        buildUI()
    }
    // prepare to show the pause menu
    func buildUI() {
        // give the player the option to return to
        // the menu from the pause screen
        menuButton.zPosition = uiZPosition
        menuButton.position = CGPoint(x: 0, y: -size.height / 4)
        menuButton.fillColor = .black
        let menuButtonText = buildTextNode(text: "quit", fontSize: 0.053 * size.width)
        menuButton.addChild(menuButtonText)
        // tell the player how to resume the game when it
        // is paused
        resumeInstruction.zPosition = uiZPosition
        resumeInstruction.position = CGPoint(x: 0, y: -size.height / 2.5)
        resumeInstruction.fillColor = .black
        resumeInstruction.strokeColor = .black
        let resumeInstructionText = buildTextNode(text: "tap screen to resume", fontSize: 0.053 * size.width)
        resumeInstruction.addChild(resumeInstructionText)
        // tell the player that the game is paused
        pausedBanner.zPosition = uiZPosition
        pausedBanner.position = CGPoint(x: 0, y: size.height / 4)
        pausedBanner.fillColor = .black
        pausedBanner.strokeColor = .black
        let pausedBannerText = buildTextNode(text: "paused", fontSize: 0.107 * size.width)
        pausedBanner.addChild(pausedBannerText)
        // ensure that there is a camera node
        guard let cameraNode = camera else { return }
        // if there is a camera node, add the pausebutton
        // and killCounter to it so that they remain in the
        // same places on the screen even thought the camera
        // is moving
        buildPauseButton()
        cameraNode.addChild(pauseButton)
        buildKillCounter()
        cameraNode.addChild(killCounter)
    }
    // let the player pause the game
    func buildPauseButton() {
        // bars are the two vertical bars that make up
        // a typical pause symbol
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
    // tell the player how many planets
    // they have killed in this play
    func buildKillCounter() {
        killCounter.text = String(numKills)
        killCounter.zPosition = uiZPosition
        killCounter.fontColor = SKColor.white
        killCounter.fontSize = 0.133 * size.width
        killCounter.fontName = "Avenir-Black"
        // setting the alignment mdoe to top right
        // ensures that even as the number displayed
        // increases, the labelNode will still be entierly
        // visible in the top right corner of the screen
        killCounter.horizontalAlignmentMode = .right
        killCounter.verticalAlignmentMode = .top
        killCounter.position = CGPoint(x: size.width / 2 - 0.08 * size.width, y: size.height / 2 - 0.08 * size.width)
    }
    // used to add text to the component of the pause menu UI
    func buildTextNode(text: String, fontSize: CGFloat) -> SKLabelNode {
        let labelNode = SKLabelNode()
        labelNode.text = text
        labelNode.fontColor = SKColor.white
        labelNode.fontSize = fontSize
        labelNode.fontName = "Avenir-Black"
        labelNode.zPosition = uiZPosition
        // the text should be centered vertically wherever
        // it is placed
        labelNode.verticalAlignmentMode = .center
        return labelNode
    }
    // detect collisions between enemies and player bullets
    // or the player and enemy bullets
    func didBegin(_ contact: SKPhysicsContact) {
        // this will be true if two nodes touch a third node at the same time:
        // the third node would be removed because of the first collision and
        // then it would have no parent now. In that case, we should not do anything
        if contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil {
            return
        }
        // since the order in which the nodes are given is not
        // guarenteed, a list we will used to store them to make
        // figuring out the correct order easier
        var nodes = [contact.bodyA.node, contact.bodyB.node]
        let nodeCategories = [contact.bodyA.categoryBitMask, contact.bodyB.categoryBitMask]
        // this detects if this is a enemy-playerBullet collisison, regardless of the order
        // in which the nodes are given
        if nodeCategories.contains(enemyCategory) && nodeCategories.contains(playerBulletCategory) {
            // put the list in the order we want it to be in:
            // enemy first, then playerBullet
            if nodeCategories[0] == playerBulletCategory {
                nodes = nodes.reversed()
            }
            let enemy = nodes[0] as? SKShapeNode
            let playerBullet = nodes[1] as? SKShapeNode
            guard let deadEnemy = enemy else { return }
            guard let usedPlayerBullet = playerBullet else { return }
            usedPlayerBullet.removeFromParent()
            deadEnemy.removeFromParent()
            // the same number of enemies
            // is maintained constantly, so
            // whenever an enemy is deleted, another is added
            addEnemy()
            // explosions are particle emitters
            // that are quickly deleted
            addExplosion(at: deadEnemy.position)
            // update the kill counter because the
            // player has killed a planet
            numKills += 1
            killCounter.text = String(numKills)
        // this detects if this is a player-enemyBullet collisison, regardless of the order
        // in which the nodes are given
        } else if nodeCategories.contains(playerCategory) && nodeCategories.contains(enemyBulletCategory) {
            // player-enemyBullet collisions
            // only matter if the user is tapping
            // the screen, in which case playerIsVulnerable
            // would be set to true
            if playerIsVulnerable {
                // put the list in the order we want it to be in:
                // enemyBullet first, then player
                if nodeCategories[0] == playerCategory {
                    nodes = nodes.reversed()
                }
                let enemyBullet = nodes[0] as? SKShapeNode
                guard let killerBullet = enemyBullet else { return }
                // the GameOverScene needs to know the position and
                // zRotation of the bullet that killed the player
                // so it can draw it. For this reason, we pass the
                // bullet along to endGame(), which will present the
                // GameOverScene
                endGame(killerBullet: killerBullet)
            }
        }
    }
    // add a particle emitter which will be soon removed,
    // looking like an explosion. These are added whenever
    // an enemy is killed by the player at the location where
    // the enemy died
    func addExplosion(at position: CGPoint) {
        let deadEnemyEmitter = newEnemyDeathEmitter()
        guard let deadEnemyExplosion = deadEnemyEmitter else { return }
        deadEnemyExplosion.position = position
        deadEnemyExplosion.zPosition = particleZPosition
        // let the emitter make some particles, then stop
        // all particle emmission, then wait until the particles
        // have died out before removing the emmiter completely
        let sequence = [SKAction.wait(forDuration: 0.1),
                        SKAction.run { deadEnemyExplosion.particleBirthRate = 0; },
                        SKAction.wait(forDuration: 2),
                        SKAction.removeFromParent()]
        deadEnemyExplosion.run(SKAction.sequence(sequence))
        addChild(deadEnemyExplosion)
    }
    // called whenever the player touches the screen outside
    // of the pause button.
    // checks if the player is touching an enemy bullet
    // and fires a player bullet
    func playerTouchedScreen() {
        if let bodiesTouchingPlayer = player.physicsBody?.allContactedBodies() {
            for body in bodiesTouchingPlayer {
                if body.categoryBitMask == enemyBulletCategory {
                    // the bullet that killed the player needs to be passed
                    // to endGame so it can pass the position and zRotation of
                    // the bullet to GameOverScene, which draws the bullet
                    guard let killerBullet = body.node as? SKShapeNode else { return }
                    endGame(killerBullet: killerBullet)
                }
            }
        }
        // mark they player as being vulnerable to enemy
        // bullets
        playerIsVulnerable = true
        // add a player bullet shooting the enemy
        // that is closest to the player
        addPlayerBullet()
    }
    // add a player bullet that aims for the enemy
    // that is closest to the player
    func addPlayerBullet() {
        // determine which enemy is closest to
        // the player
        var shortestDistance = CGFloat.infinity
        var closestEnemy: SKShapeNode?
        // stop would be used to stop the eneumeration,
        // but we want to look at all the enemies, so it
        // is never used
        enumerateChildNodes(withName: enemyName) { (enemy, stop) in
            let thisDistance = self.distanceToPlayer(from: enemy)
            if thisDistance < shortestDistance {
                shortestDistance = thisDistance
                closestEnemy = enemy as? SKShapeNode
            }
        }
        // if there are no enemies, there is no need
        // to create a player bullet
        guard let enemyToShoot = closestEnemy else { return }
        let playerBullet = SKShapeNode.init(circleOfRadius: 0.0267 * size.width)
        playerBullet.name = playerBulletName
        playerBullet.fillColor = playerColor
        playerBullet.strokeColor = playerColor
        playerBullet.position = player.position
        playerBullet.zPosition = playerBulletZPosition
        playerBullet.physicsBody = SKPhysicsBody(circleOfRadius: 0.0267 * size.width)
        // give the bullet a velocity that will send it
        // towards the enemy, compensating for the enemy's movement
        playerBullet.physicsBody?.velocity = playerAimVector(enemy: enemyToShoot)
        // player bullets should not slow down over time
        playerBullet.physicsBody?.linearDamping = 0
        // player bullets should not be affected by the player's
        // gravity or enemy gravity
        playerBullet.physicsBody?.fieldBitMask = 0
        // the category must be set for detecting collisions
        playerBullet.physicsBody?.categoryBitMask = playerBulletCategory
        // player bullets should pass through all other bodies
        // in the physics simulation
        playerBullet.physicsBody?.collisionBitMask = 0
        addChild(playerBullet)
    }
    // define the player's appearcance and physical
    // characteristics
    func buildPlayer() {
        player.fillColor = playerColor
        player.strokeColor = playerColor
        player.zPosition = playerZPosition
        // give the player gravity, which will draw the
        // enemies towards him
        let playerGravity = SKFieldNode.radialGravityField()
        // the strength of the gravity must be related to the
        // square of the screen size because the falloff of the
        // gravity is related to the square of the distance between
        // the bodies. Thus, for different screen sizes, these changes
        // cancel each other out, making the physics simulation run
        // the same on screens of any size.
        playerGravity.strength = Float(0.00000711 * size.width * size.width)
        // make the strength of the gravity related to
        // the square of the distance betweent the player and
        // the enemy
        playerGravity.falloff = 2
        // a category must be set so enemies can be given
        // a fieldBitMask of playerGravityCategory, making them
        // affected by playerGravity
        playerGravity.categoryBitMask = playerGravityCategory
        // the minimum distance which an enemy must be from
        // the player for the player's gravity to have an effect
        // on them. This is critical for preventing application
        // of extreme force on enemies that are very close to
        // the player.
        playerGravity.minimumRadius = Float(0.133 * size.width)
        player.addChild(playerGravity)
        // make the player's physics body match the size of his
        // SKShapeNode
        player.physicsBody = SKPhysicsBody(circleOfRadius: 0.0267 * size.width)
        // make the player be affected by enemy gravity
        player.physicsBody?.fieldBitMask = enemyGravityCategory
        // mark the player with his category for collision detection
        player.physicsBody?.categoryBitMask = playerCategory
        // enemy bullets have contact test bit masks of playerCategory,
        // so the player does not need to have a contact test bit mask
        player.physicsBody?.contactTestBitMask = 0
        // the player should pass through all bodies in the
        // physics simualtion
        player.physicsBody?.collisionBitMask = 0
        // give the player a particle emitter which
        // shows the path he has followed
        let playerTrailEmitter = newPlayerTrailEmitter()
        if let playerTrail = playerTrailEmitter {
            playerTrail.zPosition = particleZPosition
            // since the trail emitter is being added
            // to the player, its targetNode must be
            // changed to the scene so that the particles
            // do not stay under the player as he moves around
            playerTrail.targetNode = self
            player.addChild(playerTrail)
        }
    }
    // define the appearance and physical characteristics of enemies
    func buildEnemy() -> SKShapeNode {
        let enemy = SKShapeNode.init(circleOfRadius: enemyRadius)
        enemy.name = enemyName
        enemy.fillColor = enemyColor
        enemy.strokeColor = enemyColor
        enemy.zPosition = enemyZPosition
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemyRadius)
        // make the enemies shoot at the player every 0.5 seconds
        let sequence = [SKAction.wait(forDuration: 0.5),
                        SKAction.run {
                            self.addEnemyBullet(enemy: enemy)}]
        enemy.run(SKAction.repeatForever(SKAction.sequence(sequence)))
        // make the enemies be affected by the player's gravity
        enemy.physicsBody?.fieldBitMask = playerGravityCategory
        // the enemies should not lose speed as time passes
        enemy.physicsBody?.linearDamping = 0
        // mark the enemies for collision detection
        enemy.physicsBody?.categoryBitMask = enemyCategory
        // make collisions between playerBullets and enemies be
        // passed to didBegin()
        enemy.physicsBody?.contactTestBitMask = playerBulletCategory
        // enemies should pass through all bodies in the
        // physics simulation
        enemy.physicsBody?.collisionBitMask = 0
        // give the enemy gravity, which will only attract the player
        let enemyGravity = SKFieldNode.radialGravityField()
        // the strength of the gravity must be related to the
        // square of the screen size because the falloff of the
        // gravity is related to the square of the distance between
        // the bodies. Thus, for different screen sizes, these changes
        // cancel each other out, making the physics simulation run
        // the same on screens of any size.
        enemyGravity.strength = Float(0.00000711 * size.width * size.width)
        // make the strength of the enemy gravity proportional to
        // the square of the distance betweent the player and the
        // enemy
        enemyGravity.falloff = 2
        // the minimum distance which the player must be from
        // the enemy for the enemy's gravity to have an effect
        // on the player. This is critical for preventing application
        // of extreme force on the player when the enemy is very close
        // to the player.
        enemyGravity.minimumRadius = Float(0.133 * size.width)
        // mark the gravity so that the player's fieldBitMask
        // of enemyGravityCategory will make the player affected
        // by enemy gravity
        enemyGravity.categoryBitMask = enemyGravityCategory
        enemy.addChild(enemyGravity)
        return enemy
    }
    // spawn a new enemy on a random edge of the
    // screen
    func addEnemy() {
        let enemy = buildEnemy()
        if random.nextBool() {
            if random.nextBool() {
                // spawn the enemy on the 
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
            playerTouchedScreen()
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
