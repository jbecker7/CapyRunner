import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //nodes
    var gameNode: SKNode!
    var groundNode: SKNode!
    var backgroundNode: SKNode!
    var treeNode: SKNode!
    var capybaraNode: SKNode!
    var snakeNode: SKNode!
    var orangeNode: SKNode!
    
    //score
    var scoreNode: SKLabelNode!
//    var resetInstructions: SKLabelNode!
    var score = 0 as Int
    
    //sound effects
    let jumpSound = SKAction.playSoundFileNamed("dino.assets/sounds/jump", waitForCompletion: false)
    let dieSound = SKAction.playSoundFileNamed("dino.assets/sounds/die", waitForCompletion: false)
    let backgroundSound = SKAction.playSoundFileNamed("dino.assets/sounds/background", waitForCompletion: false)
    
    //sprites
    var capySprite: SKSpriteNode!
    
    //spawning vars
    var spawnRate = 1.5 as Double
    var timeSinceLastSpawn = 0.0 as Double
    
    //generic vars
    var groundHeight: CGFloat?
    var capyYPosition: CGFloat?
    var groundSpeed = 500 as CGFloat
    
    //consts
    let capyHopForce = 1000 as Int
    let cloudSpeed = 50 as CGFloat
    let sunSpeed = 10 as CGFloat
    
    let background = 0 as CGFloat
    let foreground = 1 as CGFloat
    
    //collision categories
    let groundCategory = 1 << 0 as UInt32
    let capyCategory = 1 << 1 as UInt32
    let treeCategory = 1 << 2 as UInt32
    let snakeCategory = 1 << 3 as UInt32
    let orangeCategory = 1 << 4 as UInt32
    
    override func didMove(to view: SKView) {
        run(backgroundSound)

        self.backgroundColor = UIColor(hue:0.55, saturation: 0.14, brightness: 0.97, alpha:1)
        
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -9.8)
        
        //ground
        groundNode = SKNode()
        groundNode.zPosition = background
        createAndMoveGround()
        addCollisionToGround()
        
        //background elements
        backgroundNode = SKNode()
        backgroundNode.zPosition = background
        createsun()
        createClouds()
        
        //capybara
        capybaraNode = SKNode()
        capybaraNode.zPosition = foreground
        createcapybara()
        
        //trees
        treeNode = SKNode()
        treeNode.zPosition = foreground
        
        //snakes
        snakeNode = SKNode()
        snakeNode.zPosition = foreground
        
        //orange
        orangeNode = SKNode()
        orangeNode.zPosition = foreground
        
        //score
        score = 0
        scoreNode = SKLabelNode(fontNamed: "Courier")
        scoreNode.fontSize = 50
        scoreNode.zPosition = foreground
        scoreNode.text = "Score: 0"
        scoreNode.fontColor = SKColor.black
        scoreNode.position = CGPoint(x: 250, y: 600)
        
        
        //parent game node
        gameNode = SKNode()
        gameNode.addChild(groundNode)
        gameNode.addChild(backgroundNode)
        gameNode.addChild(capybaraNode)
        gameNode.addChild(treeNode)
        gameNode.addChild(snakeNode)
        gameNode.addChild(scoreNode)
        gameNode.addChild(orangeNode)
//        gameNode.addChild(resetInstructions)
        self.addChild(gameNode)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(gameNode.speed <= 0.0){
            resetGame()
            return
        }
        
        for _ in touches {
            if let groundPosition = capyYPosition {
                if capySprite.position.y <= groundPosition && gameNode.speed > 0 {
                    capySprite.physicsBody?.applyImpulse(CGVector(dx: 0, dy: capyHopForce))
                    run(jumpSound)
                }
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if(gameNode.speed > 0){
            groundSpeed += 0.2
            
            score += 1
            scoreNode.text = "Score: \(score/5)"
            
            if(currentTime - timeSinceLastSpawn > spawnRate){
                timeSinceLastSpawn = currentTime
                spawnRate = Double.random(in: 1.0 ..< 3.5)
                
                if(Int.random(in: 0...10) < 8){
                    spawntree()
                }
                    else {
                        if(Int.random(in: 0...10) < 7){
                            spawnsnake()
                        } else{
                            spawnOrange()
                        }
                        
                    
                }
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if hitOrange(contact) {

            score = score + 1000
            scoreNode.text = "Score: \(score)"
        }
        if(hittree(contact) || hitsnake(contact)){
            run(dieSound)
            gameOver()
        }
    }
    
    func hittree(_ contact: SKPhysicsContact) -> Bool {
        return contact.bodyA.categoryBitMask & treeCategory == treeCategory ||
        contact.bodyB.categoryBitMask & treeCategory == treeCategory
    }
    
    func hitsnake(_ contact: SKPhysicsContact) -> Bool {
        return contact.bodyA.categoryBitMask & snakeCategory == snakeCategory ||
        contact.bodyB.categoryBitMask & snakeCategory == snakeCategory
    }
    
    func hitOrange(_ contact: SKPhysicsContact) -> Bool {
        return contact.bodyA.categoryBitMask & orangeCategory == orangeCategory ||
        contact.bodyB.categoryBitMask & orangeCategory == orangeCategory
        
    }
        
    
    func resetGame() {
        gameNode.speed = 1.0
        timeSinceLastSpawn = 0.0
        groundSpeed = 500
        score = 0
        
        treeNode.removeAllChildren()
        snakeNode.removeAllChildren()
        
//        resetInstructions.fontColor = SKColor.white
        
        let capyTexture1 = SKTexture(imageNamed: "dino.assets/capybaras/capyRight")
        let capyTexture2 = SKTexture(imageNamed: "dino.assets/capybaras/capyLeft")
        capyTexture1.filteringMode = .nearest
        capyTexture2.filteringMode = .nearest
        
        let runningAnimation = SKAction.animate(with: [capyTexture1, capyTexture2], timePerFrame: 0.12)
        
        capySprite.position = CGPoint(x: self.frame.size.width * 0.15, y: capyYPosition!)
        capySprite.run(SKAction.repeatForever(runningAnimation))
    }
    
    func gameOver() {
        gameNode.speed = 0.0
        
//        resetInstructions.fontColor = SKColor.gray
        
        let deadcapyTexture = SKTexture(imageNamed: "dino.assets/capybaras/capyDead")
        deadcapyTexture.filteringMode = .nearest
        
        capySprite.removeAllActions()
        capySprite.texture = deadcapyTexture
    }
    
    func createAndMoveGround() {
        let screenWidth = self.frame.size.width
        
        //ground texture
        let groundTexture = SKTexture(imageNamed: "dino.assets/landscape/ground")
        groundTexture.filteringMode = .nearest
        
        let homeButtonPadding = 50.0 as CGFloat
        groundHeight = groundTexture.size().height - 5
        
        //ground actions
        let moveGroundLeft = SKAction.moveBy(x: -groundTexture.size().width,
                                             y: 0.0, duration: TimeInterval(screenWidth / groundSpeed))
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0.0, duration: 0.0)
        let groundLoop = SKAction.sequence([moveGroundLeft, resetGround])
        
        //ground nodes
        let numberOfGroundNodes = 1 + Int(ceil(screenWidth / groundTexture.size().width))
        
        for i in 0 ..< numberOfGroundNodes {
            let node = SKSpriteNode(texture: groundTexture)
            node.anchorPoint = CGPoint(x: 0.0, y: 0.0)
            node.position = CGPoint(x: CGFloat(i) * groundTexture.size().width, y: groundHeight!)
            groundNode.addChild(node)
            node.run(SKAction.repeatForever(groundLoop))
        }
    }
    
    func addCollisionToGround() {
        let groundContactNode = SKNode()
        groundContactNode.position = CGPoint(x: 0, y: groundHeight! - 30)
        groundContactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width * 3,
                                                                          height: groundHeight!))
        groundContactNode.physicsBody?.friction = 0.0
        groundContactNode.physicsBody?.isDynamic = false
        groundContactNode.physicsBody?.categoryBitMask = groundCategory
        
        groundNode.addChild(groundContactNode)
    }
    
    func createsun() {
        //texture
        let sunTexture = SKTexture(imageNamed: "dino.assets/landscape/sun")
        let sunScale = 3.0 as CGFloat
        sunTexture.filteringMode = .nearest
        
        //sun sprite
        let sunSprite = SKSpriteNode(texture: sunTexture)
        sunSprite.setScale(sunScale)
        //add to scene
        backgroundNode.addChild(sunSprite)
        
        //animate the sun
        animatesun(sprite: sunSprite, textureWidth: sunTexture.size().width * sunScale)
    }
    
    func animatesun(sprite: SKSpriteNode, textureWidth: CGFloat) {
        let screenWidth = self.frame.size.width
        let screenHeight = self.frame.size.height
        
        let distanceOffscreen = 50.0 as CGFloat // want to start the sun offscreen
        let distanceBelowTop = 150 as CGFloat
        
        //sun actions
        let movesun = SKAction.moveBy(x: -screenWidth - textureWidth - distanceOffscreen,
                                       y: 0.0, duration: TimeInterval(screenWidth / sunSpeed))
        let resetsun = SKAction.moveBy(x: screenWidth + distanceOffscreen, y: 0.0, duration: 0)
        let sunLoop = SKAction.sequence([movesun, resetsun])
        
        sprite.position = CGPoint(x: screenWidth + distanceOffscreen, y: screenHeight - distanceBelowTop)
        sprite.run(SKAction.repeatForever(sunLoop))
    }
    
    func createClouds() {
        //texture
        let cloudTexture = SKTexture(imageNamed: "dino.assets/landscape/cloud")
        let cloudScale = 3.0 as CGFloat
        cloudTexture.filteringMode = .nearest
        
        //clouds
        let numClouds = 3
        for i in 0 ..< numClouds {
            //create sprite
            let cloudSprite = SKSpriteNode(texture: cloudTexture)
            cloudSprite.setScale(cloudScale)
            //add to scene
            backgroundNode.addChild(cloudSprite)
            
            //animate the cloud
            animateCloud(cloudSprite, cloudIndex: i, textureWidth: cloudTexture.size().width * cloudScale)
        }
    }
    
    func animateCloud(_ sprite: SKSpriteNode, cloudIndex i: Int, textureWidth: CGFloat) {
        let screenWidth = self.frame.size.width
        let screenHeight = self.frame.size.height
        
        let cloudOffscreenDistance = (screenWidth / 3.0) * CGFloat(i) + 100 as CGFloat
        let cloudYPadding = 50 as CGFloat
        let cloudYPosition = screenHeight - (CGFloat(i) * cloudYPadding) - 200
        
        let distanceToMove = screenWidth + cloudOffscreenDistance + textureWidth
        
        //actions
        let moveCloud = SKAction.moveBy(x: -distanceToMove, y: 0.0, duration: TimeInterval(distanceToMove / cloudSpeed))
        let resetCloud = SKAction.moveBy(x: distanceToMove, y: 0.0, duration: 0.0)
        let cloudLoop = SKAction.sequence([moveCloud, resetCloud])
        
        sprite.position = CGPoint(x: screenWidth + cloudOffscreenDistance, y: cloudYPosition)
        sprite.run(SKAction.repeatForever(cloudLoop))
    }
    
    func createcapybara() {
        let screenWidth = self.frame.size.width
        let capyScale = 4.0 as CGFloat
        
        //textures
        let capyTexture1 = SKTexture(imageNamed: "dino.assets/capybaras/capyRight")
        let capyTexture2 = SKTexture(imageNamed: "dino.assets/capybaras/capyLeft")
        capyTexture1.filteringMode = .nearest
        capyTexture2.filteringMode = .nearest
        
        let runningAnimation = SKAction.animate(with: [capyTexture1, capyTexture2], timePerFrame: 0.12)
        
        capySprite = SKSpriteNode()
        capySprite.size = capyTexture1.size()
        capySprite.setScale(capyScale)
        capybaraNode.addChild(capySprite)
        
        let physicsBox = CGSize(width: capyTexture1.size().width * capyScale,
                                height: capyTexture1.size().height * capyScale)
        
        capySprite.physicsBody = SKPhysicsBody(rectangleOf: physicsBox)
        capySprite.physicsBody?.isDynamic = true
        capySprite.physicsBody?.mass = 1.0
        capySprite.physicsBody?.categoryBitMask = capyCategory
        capySprite.physicsBody?.contactTestBitMask = snakeCategory | treeCategory
        capySprite.physicsBody?.collisionBitMask = groundCategory
        
        capyYPosition = getGroundHeight() + capyTexture1.size().height * capyScale
        capySprite.position = CGPoint(x: screenWidth * 0.15, y: capyYPosition!)
        capySprite.run(SKAction.repeatForever(runningAnimation))
    }
    
    func spawntree() {
        let treeTextures = ["tree1", "tree2", "tree3", "doubletreelon", "tripletree"]
        let treeScale = 6.0 as CGFloat
        
        //texture
        let treeTexture = SKTexture(imageNamed: "dino.assets/trees/" + treeTextures.randomElement()!)
        treeTexture.filteringMode = .nearest
        
        //sprite
        let treeSprite = SKSpriteNode(texture: treeTexture)
        treeSprite.setScale(treeScale)
        
        //physics
        let contactBox = CGSize(width: treeTexture.size().width * treeScale,
                                height: treeTexture.size().height * treeScale)
        treeSprite.physicsBody = SKPhysicsBody(rectangleOf: contactBox)
        treeSprite.physicsBody?.isDynamic = true
        treeSprite.physicsBody?.mass = 1.0
        treeSprite.physicsBody?.categoryBitMask = treeCategory
        treeSprite.physicsBody?.contactTestBitMask = capyCategory
        treeSprite.physicsBody?.collisionBitMask = groundCategory
        
        //add to scene
        treeNode.addChild(treeSprite)
        //animate
        animatetree(sprite: treeSprite, texture: treeTexture)
    }
    
    func animatetree(sprite: SKSpriteNode, texture: SKTexture) {
        let screenWidth = self.frame.size.width
        let distanceOffscreen = 50.0 as CGFloat
        let distanceToMove = screenWidth + distanceOffscreen + texture.size().width
        
        //actions
        let movetree = SKAction.moveBy(x: -distanceToMove, y: 0.0, duration: TimeInterval(screenWidth / groundSpeed))
        let removetree = SKAction.removeFromParent()
        let moveAndRemove = SKAction.sequence([movetree, removetree])
        
        sprite.position = CGPoint(x: distanceToMove, y: getGroundHeight()  + texture.size().height)
        sprite.run(moveAndRemove)
    }
    
    func spawnsnake() {
        //textures
        let snakeTexture1 = SKTexture(imageNamed: "dino.assets/capybaras/snake1")
        let snakeTexture2 = SKTexture(imageNamed: "dino.assets/capybaras/snake2")
        let snakeScale = 5.0 as CGFloat
        snakeTexture1.filteringMode = .nearest
        snakeTexture2.filteringMode = .nearest
        
        //animation
        let screenWidth = self.frame.size.width
        let distanceOffscreen = 50.0 as CGFloat
        let distanceToMove = screenWidth + distanceOffscreen + snakeTexture1.size().width * snakeScale
        
        let flapAnimation = SKAction.animate(with: [snakeTexture1, snakeTexture2], timePerFrame: 0.5)
        let movesnake = SKAction.moveBy(x: -distanceToMove, y: 0.0, duration: TimeInterval(screenWidth / groundSpeed))
        let removesnake = SKAction.removeFromParent()
        let moveAndRemove = SKAction.sequence([movesnake, removesnake])
        
        //sprite
        let snakeSprite = SKSpriteNode()
        snakeSprite.size = snakeTexture1.size()
        snakeSprite.setScale(snakeScale)
        
        //physics
        let snakeContact = CGSize(width: snakeTexture1.size().width * snakeScale,
                                 height: snakeTexture1.size().height * snakeScale)
        snakeSprite.physicsBody = SKPhysicsBody(rectangleOf: snakeContact)
        snakeSprite.physicsBody?.isDynamic = false
        snakeSprite.physicsBody?.mass = 1.0
        snakeSprite.physicsBody?.categoryBitMask = snakeCategory
        snakeSprite.physicsBody?.contactTestBitMask = capyCategory
        
        snakeSprite.position = CGPoint(x: distanceToMove,
                                      y: getGroundHeight() + snakeTexture1.size().height * snakeScale + 20)
        snakeSprite.run(SKAction.group([moveAndRemove, SKAction.repeatForever(flapAnimation)]))
        
        //add to scene
        snakeNode.addChild(snakeSprite)
    }
    
    func spawnOrange() {
        //textures
        let orangeTexture = SKTexture(imageNamed: "dino.assets/orange/orange")
        let orangeScale = 5.0 as CGFloat
        orangeTexture.filteringMode = .nearest
        
        
        //animation
        let screenWidth = self.frame.size.width
        let distanceOffscreen = 50.0 as CGFloat
        let distanceToMove = screenWidth + distanceOffscreen + orangeTexture.size().width * orangeScale
        
        let flapAnimation = SKAction.animate(with: [orangeTexture, orangeTexture], timePerFrame: 0.5)
        let moveOrange = SKAction.moveBy(x: -distanceToMove, y: 0.0, duration: TimeInterval(screenWidth / groundSpeed))
        let removeOrange = SKAction.removeFromParent()
        let moveAndRemove = SKAction.sequence([moveOrange, removeOrange])
        
        //sprite
        let orangeSprite = SKSpriteNode()
        orangeSprite.size = orangeTexture.size()
        orangeSprite.setScale(orangeScale)
        
        //physics
        let orangeContact = CGSize(width: orangeTexture.size().width * orangeScale,
                                 height: 5 + orangeTexture.size().height * orangeScale)
        orangeSprite.physicsBody = SKPhysicsBody(rectangleOf: orangeContact)
        orangeSprite.physicsBody?.isDynamic = false
        orangeSprite.physicsBody?.mass = 1.0
        orangeSprite.physicsBody?.categoryBitMask = orangeCategory
        orangeSprite.physicsBody?.contactTestBitMask = capyCategory
        
        orangeSprite.position = CGPoint(x: distanceToMove,
                                      y: getGroundHeight() + orangeTexture.size().height * orangeScale + 20)
        orangeSprite.run(SKAction.group([moveAndRemove, SKAction.repeatForever(flapAnimation)]))
        
        //add to scene
        orangeNode.addChild(orangeSprite)
    }
    
    func getGroundHeight() -> CGFloat {
        if let gHeight = groundHeight {
            return gHeight
        } else {
            print("Ground size wasn't previously calculated")
            exit(0)
        }
    }
    
}

