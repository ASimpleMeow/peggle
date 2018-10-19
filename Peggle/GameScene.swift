import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let ballSpawnHeightRatio : CGFloat = 3.0
    let boxesToHit : Int = 3
    let ballColors = ["Blue", "Cyan", "Green", "Grey", "Purple", "Red", "Yellow"]
    var winLabel: SKLabelNode!
    
    var ballsLabel: SKLabelNode!
    var balls = 5 {
        didSet {
            ballsLabel.text = "Balls Left: \(balls)"
        }
    }
    
    var scoreLabel: SKLabelNode!
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var editLabel: SKLabelNode!
    var editingMode: Bool = false {
        didSet {
            if editingMode {
                editLabel.text = "Done"
            } else {
                editLabel.text = "Edit"
            }
        }
    }
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "background.jpg")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.contactDelegate = self
        
        makeSlot(at: CGPoint(x: 128, y: 0), isGood: true)
        makeSlot(at: CGPoint(x: 384, y: 0), isGood: false)
        makeSlot(at: CGPoint(x: 640, y: 0), isGood: true)
        makeSlot(at: CGPoint(x: 896, y: 0), isGood: false)
        
        makeBouncer(at: CGPoint(x: 0, y: 0), bit: 0b00000001)
        makeBouncer(at: CGPoint(x: 256, y: 0), bit: 0b00000010)
        makeBouncer(at: CGPoint(x: 512, y: 0), bit: 0b00000100)
        makeBouncer(at: CGPoint(x: 768, y: 0), bit: 0b00001000)
        makeBouncer(at: CGPoint(x: 1024, y: 0), bit: 0b00100000)
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: \(score)"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: 980, y: 700)
        addChild(scoreLabel)
        
        editLabel = SKLabelNode(fontNamed: "Chalkduster")
        editLabel.text = "Edit"
        editLabel.position = CGPoint(x: 80, y: 700)
        addChild(editLabel)
        
        ballsLabel = SKLabelNode(fontNamed: "Chalkduster")
        ballsLabel.text = "Balls Left: \(balls)"
        ballsLabel.horizontalAlignmentMode = .right
        ballsLabel.position = CGPoint(x: 980, y: 650)
        addChild(ballsLabel)
        
        winLabel = SKLabelNode(fontNamed: "Chalkduster")
        winLabel.text = ""
        winLabel.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        winLabel.isHidden = true
        addChild(winLabel)
        reset()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            
            let objects = nodes(at: location)
            
            if !winLabel.isHidden {
                reset()
                return
            }
            
            if objects.contains(editLabel) {
                editingMode = !editingMode
                return
            }
            
            if editingMode && location.y < self.size.height - self.size.height/ballSpawnHeightRatio{
                if objects.contains(where: { $0.name == "box" }) {
                    for box in objects where box.name == "box" { box.removeFromParent() }
                    return
                }
                addBox(at: location)
            } else if !editingMode && location.y > self.size.height - self.size.height/ballSpawnHeightRatio && balls > 0 {
                let ball = SKSpriteNode(imageNamed: "ball"+ballColors[GKRandomDistribution(lowestValue: 0, highestValue: ballColors.count-1).nextInt()])
                ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.width / 2.0)
                ball.physicsBody!.contactTestBitMask = ball.physicsBody!.collisionBitMask
                ball.physicsBody?.restitution = 0.4
                ball.position = location
                ball.name = "ball"
                ball.userData = ["boxesHit" : 0,
                                 "bit" : 0b00000000]
                addChild(ball)
                balls -= 1
            }
        }
        
    }
    
    func addBox(at location:CGPoint){
        let size = CGSize(width: GKRandomDistribution(lowestValue: 16, highestValue: 128).nextInt(), height: 16)
        let box = SKSpriteNode(color: RandomColor(), size: size)
        box.zRotation = RandomCGFloat(min: 0, max: 3)
        box.position = location
        
        box.physicsBody = SKPhysicsBody(rectangleOf: box.size)
        box.physicsBody?.isDynamic = false
        box.name = "box"
        
        addChild(box)
    }
    
    func reset(){
        winLabel.isHidden = true
        score = 0
        for n in children where n.name == "box" { n.removeFromParent() }
        editingMode = false
        balls = 5
        
        for _ in 0...GKRandomDistribution(lowestValue: 5, highestValue: 15).nextInt() {
            let x = GKRandomDistribution(lowestValue: 0, highestValue: Int(self.size.width)).nextInt()
            let y = GKRandomDistribution(lowestValue: Int(self.size.height/ballSpawnHeightRatio), highestValue: Int(self.size.height - self.size.height/ballSpawnHeightRatio)).nextInt()
            let location = CGPoint(x: x ,y: y)
            addBox(at: location)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else {return}
        guard let nodeB = contact.bodyB.node else {return}
        
        if nodeA.name == "ball" {
            collisionBetween(ball: nodeA, object: nodeB)
        } else if nodeB.name == "ball" {
            collisionBetween(ball: nodeB, object: nodeA)
        }
    }
    
    func makeBouncer(at position: CGPoint, bit: Int) {
        let bouncer = SKSpriteNode(imageNamed: "bouncer")
        bouncer.position = position
        bouncer.physicsBody = SKPhysicsBody(circleOfRadius: bouncer.size.width / 2.0)
        bouncer.physicsBody?.isDynamic = false
        bouncer.name = "rainbow"
        bouncer.userData = ["bit" : bit]
        addChild(bouncer)
    }
    
    func makeSlot(at position: CGPoint, isGood: Bool) {
        var slotBase: SKSpriteNode
        var slotGlow: SKSpriteNode
        
        if isGood {
            slotBase = SKSpriteNode(imageNamed: "slotBaseGood")
            slotGlow = SKSpriteNode(imageNamed: "slotGlowGood")
            slotBase.name = "good"
        } else {
            slotBase = SKSpriteNode(imageNamed: "slotBaseBad")
            slotGlow = SKSpriteNode(imageNamed: "slotGlowBad")
            slotBase.name = "bad"
        }
        
        slotBase.position = position
        slotGlow.position = position
        
        slotBase.physicsBody = SKPhysicsBody(rectangleOf: slotBase.size)
        slotBase.physicsBody?.isDynamic = false
        
        addChild(slotBase)
        addChild(slotGlow)
        
        let spin = SKAction.rotate(byAngle: .pi, duration: 10)
        let spinForever = SKAction.repeatForever(spin)
        slotGlow.run(spinForever)
    }
    
    func collisionBetween(ball: SKNode, object: SKNode) {
        switch object.name {
        case "good":
            destroy(ball: ball)
            if ball.userData?.value(forKey: "boxesHit") as! Int >= boxesToHit {
                score += 1
                balls += 1
            }
            
        case "bad":
            destroy(ball: ball)
            score -= 1
            
        case "box":
            object.removeFromParent()
            score += 2
            ball.userData?.setValue(ball.userData?.value(forKey: "boxesHit") as! Int + 1, forKey: "boxesHit")
            
        case "rainbow":
            let ballBitValue = ball.userData?.value(forKey: "bit") as! Int8
            let resultBitValue: Int8 = ballBitValue | (object.userData?.value(forKey: "bit") as! Int8)
            ball.userData?.setValue(resultBitValue, forKey: "bit")
            if ballBitValue > 0 && (ball.userData?.value(forKey: "bit") as! Int8) != ballBitValue{
                ball.userData?.setValue(0, forKey: "bit")
                let ballPhysicsBody = ball.physicsBody;
                let ballVelocity = ball.physicsBody!.velocity
                ball.physicsBody = nil;
                ball.position = CGPoint(x: ball.position.x, y: self.size.height)
                ball.physicsBody = ballPhysicsBody
                ball.physicsBody?.velocity = ballVelocity
            }
            
        default:
            return
        }
    }
    
    func destroy(ball: SKNode) {
        if let fireParticles = SKEmitterNode(fileNamed: "FireParticles") {
            fireParticles.position = ball.position
            addChild(fireParticles)
        }
        
        ball.removeFromParent()
        
        if (balls == 0 && children.filter({$0.name=="ball"}).count == 0) || children.filter({$0.name=="box"}).count == 0 {
            finish()
        }
    }
    
    func finish(){
        if balls > 0 { score += balls * score }
        winLabel.text = "YOU GOT A SCORE OF \(score)"
        winLabel.isHidden = false
    }
}


