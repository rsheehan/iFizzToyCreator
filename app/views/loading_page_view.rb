class LoadingScene < SKScene
  attr_accessor :contentCreated, :game_name, :game_description
  def didMoveToView(view)
    game_name = "Untitled"
    game_description = "No description"
    unless contentCreated      
      createSceneContents
      @contentCreated = true
      physicsWorld.gravity = CGVectorMake(rand(5)-2.5, rand(5)-2.5)
      @counter = 1
    end
  end

  def createSceneContents
    self.backgroundColor = UIColor.blackColor
    self.scaleMode = SKSceneScaleModeAspectFill
    self.addChild loadingNode("LOADING...", CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame) + 100), 100)

    if game_name == Constants::GAME_DEFAULT_NAME
      game_name = ""
    end

    self.addChild loadingNode(game_name, CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame)), 60)

    if game_description != Constants::GAME_DEFAULT_DESCRIPTION
      descriptions = game_description.split(" ")
      margin = 0
      while descriptions.size > 0
        arraySmall = descriptions.take(6)
        descriptions = descriptions.drop(6)
        line = ""
        arraySmall.each { |a| line = line + " " + a}
        #p "array = #{line}"
        self.addChild loadingNode(line, CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame) - 100 - margin), 30)
        margin = margin + 50
      end
      # #descriptions = game_description.split("\n")
      # margin = 0
      # descriptions.each do |description|

      # end
    end
  end

  def loadingNode(string, position, size = 100)
    loadingNode = SKLabelNode.labelNodeWithFontNamed "Chalkduster"
    loadingNode.name = "loadingNode"
    loadingNode.text = string
    loadingNode.fontColor = UIColor.whiteColor
    loadingNode.fontSize = size
    loadingNode.position = position

    fadeIn1 = SKAction.fadeAlphaTo(0.5, duration: 0.5)
    fadeIn2 = SKAction.fadeAlphaTo(1.0, duration: 0.5)
    seq = SKAction.sequence([fadeIn1,fadeIn2])
    foreverAction = SKAction.repeatActionForever(seq)
    loadingNode.runAction(foreverAction)
    loadingNode
  end

end
