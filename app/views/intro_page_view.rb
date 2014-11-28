class IntroScene < SKScene
  attr_accessor :contentCreated
  def didMoveToView(view)
    unless contentCreated
      @texts = [
          "a programming game for children",
          "start by 'Make toys' at the bottom",
          "then 'Make scenes' and add toys to scene",
          "you can 'Add actions' to toys",
          "finally, 'Play' your own game",
          "created by the University of Auckland",
          "thanks and enjoy!!!"
      ]

      @textColors = [
          UIColor.redColor,
          UIColor.orangeColor,
          UIColor.yellowColor,
          UIColor.greenColor,
          UIColor.blueColor,
          UIColor.magentaColor,
          UIColor.purpleColor
      ]
      @demos = [
          "demo_ifizz.png",
          "demo_toy.png",
          "demo_scene.png",
          "demo_action.png",
          "demo_play.png",
          "demo_au.png",
          "demo_thanks.png"
      ]
      @totalText = @texts.size
      @totalDemos = @demos.size
      @currentNumber = 0
      #currentDemoNumber = 0
      createSceneContents
      @contentCreated = true
      physicsWorld.gravity = CGVectorMake(rand(5)-2.5, rand(5)-2.5)
      @counter = 1
    end
  end

  def update(current_time)
    @counter = @counter + 1
    if @counter % 350 == 0
      @currentNumber = (@currentNumber + 1) % @totalText
      changeDemo
      changeText
    end
  end

  def createSceneContents
    #self.backgroundColor = UIColor.redColor
    self.scaleMode = SKSceneScaleModeAspectFill
    # Image from www.emptycache.com/photographylxft/free-bible-clipart-kids
    randomVal = rand(Constants::BACKGROUND_IMAGE_LIST.size)
    texture = SKTexture.textureWithImageNamed(Constants::BACKGROUND_IMAGE_LIST[randomVal])
    background = SKSpriteNode.spriteNodeWithTexture(texture)
    background.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
    self.addChild background
    #makeRocks = SKAction.sequence([SKAction.performSelector("addRain", onTarget: self), SKAction.waitForDuration(0.1, withRange: 0.15)])
    #self.runAction(SKAction.repeatActionForever(makeRocks))
    self.addChild iFizzNode
    self.addChild demoPix
    self.addChild newWelcomeNode
  end

  def iFizzNode
    iFizzNode = SKLabelNode.labelNodeWithFontNamed "Chalkduster"
    iFizzNode.name = "iFizzNode"
    iFizzNode.text = "iFizz"
    iFizzNode.fontColor = UIColor.redColor
    iFizzNode.fontSize = 100
    iFizzNode.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame)+200)
    iFizzNode
  end

  def newWelcomeNode
    welcomeNode = SKLabelNode.labelNodeWithFontNamed "Chalkduster"
    welcomeNode.name = "welcomeNode"
    welcomeNode.text = @texts[@currentNumber]    
    welcomeNode.fontColor = UIColor.redColor
    welcomeNode.fontSize = 38
    welcomeNode.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame)+130)
    welcomeNode
  end

  def demoPix
    imageURL = @demos[@currentNumber]
    textureDemo = SKTexture.textureWithImageNamed(imageURL)
    demoScreen = SKSpriteNode.spriteNodeWithTexture(textureDemo)
    demoScreen.name = "demoNode"
    demoScreen.size = CGSizeMake(1.2*400,1.2*300)
    positionX = CGRectGetMidX(self.frame)
    positionY = CGRectGetMidY(self.frame)-110
    demoScreen.position = CGPointMake(rand(1000), -100)

    fadeIn = SKAction.fadeAlphaTo(0.8, duration: 0.0)
    
    followTrack1 = SKAction.moveTo(CGPointMake(positionX + rand(100) - 50, positionY + rand(100) - 50), duration:1.0)
    followTrack2 = SKAction.moveTo(CGPointMake(positionX + rand(100) - 50, positionY + rand(100) - 50), duration:5.0)
    followTrack3 = SKAction.moveTo(CGPointMake(positionX + rand(100) - 50, positionY + rand(100) - 50), duration:5.0)
    followTrack4 = SKAction.moveTo(CGPointMake(positionX + rand(100) - 50, positionY + rand(100) - 50), duration:5.0)

    seq = SKAction.sequence([fadeIn,followTrack1,followTrack2,followTrack3,followTrack4])
    foreverAction = SKAction.repeatActionForever(seq)
    demoScreen.runAction(foreverAction)
    demoScreen
  end

  def touchesBegan(touches, withEvent: event)
    @currentNumber = (@currentNumber + 1) % @totalText
    changeDemo
    changeText
    @counter = 1
  end

  def changeText
    physicsWorld.gravity = CGVectorMake(rand(5)-2.5, rand(5)-2.5)
    welcomeNode = self.childNodeWithName("welcomeNode")
    unless welcomeNode.nil?
      welcomeNode.name = nil
      zoom = SKAction.scaleTo(0.1, duration: 0.25)
      moveDown = SKAction.moveByX(0.0, y: -500.0, duration: 0.5)
      pause = SKAction.waitForDuration(0.1)
      fadeAway = SKAction.fadeOutWithDuration(0.25)
      remove = SKAction.removeFromParent
      moveSequence = SKAction.sequence [zoom, moveDown, pause, fadeAway, remove]

      welcomeNode.runAction(moveSequence, completion: lambda do
        self.addChild newWelcomeNode
        self.view.presentScene(self)
      end)
    end
  end

  def changeDemo
    welcomeNode = self.childNodeWithName("demoNode")
    unless welcomeNode.nil?
      welcomeNode.name = nil
      fadeAway = SKAction.fadeOutWithDuration(0.25)
      remove = SKAction.removeFromParent
      moveSequence = SKAction.sequence [fadeAway, remove]

      welcomeNode.runAction(moveSequence, completion: lambda do
        self.addChild demoPix
        self.view.presentScene(self)
      end)
    end
  end

  def skRand(low, high)
    random = Random.new
    random.rand(low..high)
  end

  def didSimulatePhysics
    self.enumerateChildNodesWithName "rain", usingBlock: lambda { |node, stop| node.removeFromParent if node.position.y < 0 }
  end

  def addRain
    randomColour = UIColor.colorWithHue(rand(256) % 256 / 256.0, saturation: rand(256) % 128 / 256.0 + 0.5, brightness: rand(256) % 128 / 256.0 + 0.5, alpha: 0.5)
    rain = SKSpriteNode.alloc.initWithColor(randomColour, size: CGSizeMake(3,9))
    rain.position = CGPointMake(skRand(0, self.size.width), skRand(0, self.size.height))
    rain.name = "rain"
    rain.physicsBody = SKPhysicsBody.bodyWithRectangleOfSize(rain.size)
    rain.physicsBody.usesPreciseCollisionDetection = true
    self.addChild rain
  end

end
