//
//  GameScene.swift
//  SwiftNinja
//
//  Created by jhampac on 2/2/16.
//  Copyright (c) 2016 jhampac. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene
{
    var gameScore: SKLabelNode!
    var score: Int = 0 {
        didSet {
            gameScore.text = "How Many Fucks: \(score)"
        }
    }
    
    var livesImages = [SKSpriteNode]()
    var lives = 3
    var activeSliceBG: SKShapeNode!
    var activeSliceFG: SKShapeNode!
    var activeSlicePoints = [CGPoint]()
    var swooshSoundActive = false
    var bombSoundEffect: AVAudioPlayer!
    var activeEnemies = [SKSpriteNode]()
    
    // enemy sequnce variables
    var popupTime = 0.9
    var sequence: [SequenceType]!
    var sequencePosition = 0
    var chainDelay = 3.0
    var nextSequenceQueued = true
    
    override func didMoveToView(view: SKView)
    {
        let background = SKSpriteNode(imageNamed: "sliceBackground")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .Replace
        background.zPosition = -1
        addChild(background)
        
        physicsWorld.gravity = CGVectorMake(0, -6)
        physicsWorld.speed = 0.85
        createScore()
        createLives()
        createSlices()
        
        sequence = [.OneNoBomb, .OneNoBomb, .TwoWithOneBomb, .TwoWithOneBomb, .Three, .One, .Chain]
        
        for _ in 0...1000
        {
            let nextSequence = SequenceType(rawValue: RandomInt(min: 2, max: 7))!
            sequence.append(nextSequence)
        }
        
        // this fires of the sequence we just built
        RunAfterDelay(2) {
            [unowned self] in
            self.tossEnemies()
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        activeSlicePoints.removeAll(keepCapacity: true)
        
        if let touch = touches.first
        {
            let location = touch.locationInNode(self)
            activeSlicePoints.append(location)
            
            redrawActiveSlice()
            
            activeSliceBG.removeAllActions()
            activeSliceFG.removeAllActions()
            
            activeSliceBG.alpha = 1
            activeSliceFG.alpha = 1
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        guard let touch = touches.first else { return }
        
        let location = touch.locationInNode(self)
        
        activeSlicePoints.append(location)
        redrawActiveSlice()
        
        // if swoosh bool is false run code bracket
        if !swooshSoundActive
        {
            playSwooshSound()
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        activeSliceBG.runAction(SKAction.fadeOutWithDuration(0.25))
        activeSliceFG.runAction(SKAction.fadeOutWithDuration(0.25))
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?)
    {
        if let touches = touches
        {
            touchesEnded(touches, withEvent: event)
        }
    }
    
    override func update(currentTime: NSTimeInterval)
    {
        var bombCount = 0
        
        for node in activeEnemies
        {
            if node.name == "bombContainer"
            {
                bombCount += 1
                break
            }
        }
        
        if bombCount == 0
        {
            if bombSoundEffect != nil
            {
                bombSoundEffect.stop()
                bombSoundEffect = nil
            }
        }
        
        if activeEnemies.count > 0
        {
            for node in activeEnemies
            {
                if node.position.y < -140
                {
                    node.removeFromParent()
                    
                    if let index = activeEnemies.indexOf(node){
                        activeEnemies.removeAtIndex(index)
                    }
                }
            }
        }
        else
        {
            if !nextSequenceQueued
            {
                RunAfterDelay(popupTime) { [unowned self] in
                    self.tossEnemies()
                }
            }
            
            nextSequenceQueued = true
        }
    }
    
    func redrawActiveSlice()
    {
        if activeSlicePoints.count < 2
        {
            activeSliceBG.path = nil
            activeSliceFG.path = nil
            return
        }
        
        while activeSlicePoints.count > 12
        {
            activeSlicePoints.removeAtIndex(0)
        }
        
        let path = UIBezierPath()
        path.moveToPoint(activeSlicePoints[0])
        
        for i in 1..<activeSlicePoints.count
        {
            path.addLineToPoint(activeSlicePoints[i])
        }
        
        activeSliceBG.path = path.CGPath
        activeSliceFG.path = path.CGPath
    }
    
    func playSwooshSound()
    {
        swooshSoundActive = true
        
        let randomNumber = RandomInt(min: 1, max: 3)
        let soundName = "swoosh\(randomNumber).caf"
        
        let swooshSound = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        
        runAction(swooshSound) { [unowned self] in
            self.swooshSoundActive = false
        }
    }
    
    func createScore()
    {
        gameScore = SKLabelNode(fontNamed: "Chalkduster")
        gameScore.text = "How Many Fucks: 0"
        gameScore.horizontalAlignmentMode = .Left
        gameScore.fontSize = 48
        
        addChild(gameScore)
        
        gameScore.position = CGPoint(x: 8, y: 8)
    }
    
    func createLives()
    {
        for i in 0..<3
        {
            let spriteNode = SKSpriteNode(imageNamed: "sliceLife")
            
            // y will be the same; multiplying x value with i to place images side by side; 0 * 70, 1 * 70, 2 * 70 ...
            spriteNode.position = CGPoint(x: CGFloat(834 + (i * 70)), y: 720)
            addChild(spriteNode)
            
            livesImages.append(spriteNode)
        }
    }
    
    func createSlices()
    {
        activeSliceBG = SKShapeNode()
        activeSliceBG.zPosition = 2
        
        activeSliceFG = SKShapeNode()
        activeSliceFG.zPosition = 2
        
        activeSliceBG.strokeColor = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1)
        activeSliceBG.lineWidth = 9
        
        activeSliceFG.strokeColor = UIColor.whiteColor()
        activeSliceFG.lineWidth = 5
        
        addChild(activeSliceBG)
        addChild(activeSliceFG)
    }
    
    func createEnemy(forceBomb forceBomb: ForceBomb = .Default)
    {
        var enemy: SKSpriteNode
        var enemyType = RandomInt(min: 0, max: 6)
        
        // Setting enemyType according to Enum
        if forceBomb == .Never
        {
            enemyType = 1
        }
        else if forceBomb == .Always
        {
            enemyType == 0
        }
        
        // Create which enemy
        if enemyType == 0
        {
            enemy = SKSpriteNode()
            enemy.zPosition = 1
            enemy.name = "bombContainer"
            
            let bombImage = SKSpriteNode(imageNamed: "sliceBomb")
            bombImage.name = "bomb"
            enemy.addChild(bombImage)
            
            if bombSoundEffect != nil
            {
                bombSoundEffect.stop()
                bombSoundEffect = nil
            }
            
            let path = NSBundle.mainBundle().pathForResource("sliceBombFuse.caf", ofType: nil)!
            let url = NSURL(fileURLWithPath: path)
            let sound = try! AVAudioPlayer(contentsOfURL: url)
            bombSoundEffect = sound
            sound.play()
            
            let emitter = SKEmitterNode(fileNamed: "sliceFuse.sks")!
            emitter.position = CGPoint(x: 76, y: 64)
            enemy.addChild(emitter)
        }
        else
        {
            enemy = SKSpriteNode(imageNamed: "penguin")
            runAction(SKAction.playSoundFileNamed("launch.caf", waitForCompletion: false))
            enemy.name = "enemy"
        }
        
        // Positioning the enemy
        let randomPosition = CGPoint(x: RandomInt(min: 64, max: 960), y: -128)
        enemy.position = randomPosition
        
        let randomAngularVelocity = CGFloat(RandomInt(min: -6, max: 6)) / 2.0
        var randomXVelocity = 0
        
        if randomPosition.x < 256
        {
            randomXVelocity = RandomInt(min: 8, max: 15)
        }
        else if randomPosition.x < 512
        {
            randomXVelocity = RandomInt(min: 3, max: 5)
        }
        else if randomPosition.x < 768
        {
            randomXVelocity = -RandomInt(min: 3, max: 5)
        }
        else
        {
            randomXVelocity = -RandomInt(min: 8, max: 15)
        }
        
        let randomYVelocity = RandomInt(min: 24, max: 32)
        
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: 64)
        enemy.physicsBody!.velocity = CGVectorMake(CGFloat(randomXVelocity * 40), CGFloat(randomYVelocity * 40))
        enemy.physicsBody!.angularVelocity = randomAngularVelocity
        enemy.physicsBody!.collisionBitMask = 0
        
        addChild(enemy)
        activeEnemies.append(enemy)
    }
    
    func tossEnemies() {
        popupTime *= 0.991
        chainDelay *= 0.99
        physicsWorld.speed *= 1.02
        
        let sequenceType = sequence[sequencePosition]
        
        switch sequenceType {
        case .OneNoBomb:
            createEnemy(forceBomb: .Never)
            
        case .One:
            createEnemy()
            
        case .TwoWithOneBomb:
            createEnemy(forceBomb: .Never)
            createEnemy(forceBomb: .Always)
            
        case .Two:
            createEnemy()
            createEnemy()
            
        case .Three:
            createEnemy()
            createEnemy()
            createEnemy()
            
        case .Four:
            createEnemy()
            createEnemy()
            createEnemy()
            createEnemy()
            
        case .Chain:
            createEnemy()
            
            RunAfterDelay(chainDelay / 5.0) { [unowned self] in self.createEnemy() }
            RunAfterDelay(chainDelay / 5.0 * 2) { [unowned self] in self.createEnemy() }
            RunAfterDelay(chainDelay / 5.0 * 3) { [unowned self] in self.createEnemy() }
            RunAfterDelay(chainDelay / 5.0 * 4) { [unowned self] in self.createEnemy() }
            
        case .FastChain:
            createEnemy()
            
            RunAfterDelay(chainDelay / 10.0) { [unowned self] in self.createEnemy() }
            RunAfterDelay(chainDelay / 10.0 * 2) { [unowned self] in self.createEnemy() }
            RunAfterDelay(chainDelay / 10.0 * 3) { [unowned self] in self.createEnemy() }
            RunAfterDelay(chainDelay / 10.0 * 4) { [unowned self] in self.createEnemy() }
        }
        
        
        sequencePosition += 1
        
        nextSequenceQueued = false
    }
}
