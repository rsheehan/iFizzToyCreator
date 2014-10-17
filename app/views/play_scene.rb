# The scene where it all works.
#require 'thread'

class PlayScene < SKScene

  attr_accessor :toys # ToyInScene objects
  attr_accessor :edges # ToyParts - either CirclePart or PointsPart
  attr_reader :loaded_toys # ToyInScene not put into play straight away
  attr_reader :mutex
  attr_writer :scores, :delegate
  attr_writer :backgroundImage

  TIMER_SCALE = 0.00006
  DEBUG_EXPLOSIONS = false


  MAX_CREATES = 10

  TOP=0
  BOTTOM=1
  LEFT=2
  RIGHT=3
  SWITCH_ON=1
  SWITCH_OFF=0

  def didMoveToView(view)
    p 'start play scene'
    @actions_to_fire = []
    if not @create_actions
      @create_actions = []
    end

    if not @score_actions
      @score_actions = []
    end

    if not @toy_touch_actions
      @toy_touch_actions = []
    end

    unless @content_created
      create_scene_contents
      @content_created = true
    end

  end

  def create_scene_contents
    #removeAllChildren
    #self.backgroundColor = SceneCreatorView::DEFAULT_SCENE_COLOUR # no longer necessary, see create_image
    self.scaleMode = SKSceneScaleModeAspectFill

    self.physicsWorld.contactDelegate = self
    @paused = true
    @mutex = Mutex.new
    @scores = {}
    @toys_count = {}
    add_edges
    add_toys
  end



  # Set gravity of the scene
  def setGravity(gravity)
    physicsWorld.gravity = gravity
  end

  # Det boundaries of the scene
  def setBoundaries(boundaries)
    #puts "boundaries: #{boundaries}"
    # top edge
    if(boundaries[TOP]==SWITCH_ON)
      body = SKPhysicsBody.bodyWithEdgeFromPoint([frame.origin.x,frame.size.height], toPoint: [frame.size.width, frame.size.height])
      body.contactTestBitMask = 1
      node = SKNode.node
      node.hidden = true
      node.physicsBody = body
      addChild(node)
    end

    # bottom edge
    if(boundaries[BOTTOM]==SWITCH_ON)
      body = SKPhysicsBody.bodyWithEdgeFromPoint([frame.origin.x,frame.origin.y], toPoint: [frame.size.width,frame.origin.y])
      body.contactTestBitMask = 1
      node = SKNode.node
      node.hidden = true
      node.physicsBody = body
      addChild(node)
    end

    # left edge
    if(boundaries[LEFT]==SWITCH_ON)
      body = SKPhysicsBody.bodyWithEdgeFromPoint([frame.origin.x,frame.origin.y], toPoint: [frame.origin.x,frame.size.height])
      body.contactTestBitMask = 1
      node = SKNode.node
      node.hidden = true
      node.physicsBody = body
      addChild(node)
    end

    # right edge
    if(boundaries[RIGHT]==SWITCH_ON)
      body = SKPhysicsBody.bodyWithEdgeFromPoint([frame.size.width,frame.origin.y], toPoint: [frame.size.width,frame.size.height])
      body.contactTestBitMask = 1
      node = SKNode.node
      node.hidden = true
      node.physicsBody = body
      addChild(node)
    end
  end

  # Actions are added here to be fired at the update
  def add_actions_for_update(actions, delay = 0)
    if delay != 0
      if delay < 0
        delay = rand(-delay) + (-delay/2)
      end
      NSTimer.scheduledTimerWithTimeInterval(delay.to_i, target: self, selector: "perform_action:", userInfo: actions, repeats: false)
    else
      @actions_to_fire += actions
    end

  end

  # Minh add to allow action to be perform after a certain time of delay
  def perform_action(timer)
    @actions_to_fire += timer.userInfo
    #puts "delay after 1 second"
  end

  def add_create_action(action)
    #puts "add create action #{action}"
    if @create_actions
      @create_actions << action
    else
      @create_actions = [action]
    end
  end

  def add_score_action(action)
    action[:used] = []
    if @score_actions
      @score_actions << action
    else
      @score_actions = [action]
    end
  end

  def get_toy_in_scene(node)
    return @toys.select{|toy| toy.uid == node.userData[:uniqueID] and toy.template.identifier == node.name}.first
  end

  def add_toy_touch_action(action)
    if @toy_touch_actions
      @toy_touch_actions << action
    else
      @toy_touch_actions = [action]
    end
  end

  def touchesBegan(touches, withEvent:event)
    touch = touches.anyObject
    location = touch.locationInNode(self)
    node = self.nodeAtPoint(location)

    @toy_touch_actions.each do |touch_action|
      #if touched toy with touch action - trigger action
      if (node.name == touch_action[:toy])
        #trigger action on this node
        new_action = touch_action.inject({}) { |h, (k, v)| k != :action_param ? h[k] = v : h[k] = [nil,node.userData[:uniqueID]]; h }
        add_actions_for_update([new_action])
      end
    end

  end


  def checkFront
    # #after simulating physics see if need to flip node?
    @toy_hash.values.each do |toyArray| # toys here are SKSpriteNodes
      toyArray.each do |toy|
        if toy.userData != nil and toy.userData[:uniqueID] != -1
          if toy.userData[:front] and toy.physicsBody != nil and not toy.physicsBody.isResting
            case toy.userData[:front]
              when Constants::Front::Right
                #unflip if going in front direction
                if toy.userData[:flipped] and toy.userData[:flipped_toy].physicsBody.velocity.dx > 0.1
                  unflipToy(toy)
                #flip toy if it is traveling away from front and not already flipped
                elsif not toy.userData[:flipped] and toy.physicsBody.velocity.dx < 0.1
                  flipToy(toy)
                end
              when Constants::Front::Left
                #unflip if going in front direction
                if toy.userData[:flipped] and toy.userData[:flipped_toy].physicsBody.velocity.dx < 0.1
                  unflipToy(toy)
                  #flip toy if it is traveling away from front and not already flipped
                elsif not toy.userData[:flipped] and toy.physicsBody.velocity.dx > 0.1
                  flipToy(toy)
                end
              when Constants::Front::Up
                #unflip if going in front direction
                if toy.userData[:flipped] and toy.userData[:flipped_toy].physicsBody.velocity.dy > 1
                  unflipToy(toy)
                  #flip toy if it is traveling away from front and not already flipped
                elsif not toy.userData[:flipped] and toy.physicsBody.velocity.dy < 1
                  flipToy(toy)
                end
              when Constants::Front::Bottom
                #unflip if going in front direction
                if toy.userData[:flipped] and toy.userData[:flipped_toy].physicsBody.velocity.dy < 1
                  unflipToy(toy)
                  #flip toy if it is traveling away from front and not already flipped
                elsif not toy.userData[:flipped] and toy.physicsBody.velocity.dy > 1
                  flipToy(toy)
                end
            end
          end

          # remove toys if toys fall out of the frame
          if toy.position.y > 2*frame.size.height || toy.position.y < frame.origin.y - frame.size.height || toy.position.x > 2*frame.size.width || toy.position.x < frame.origin.x - frame.size.width            
            remove = SKAction.removeFromParent()
            apply_action_to_toy(toy, remove)
            toy.userData[:uniqueID] = -1
            self.paused = true
          end
        end
      end
    end
  end

  def unflipToy(toy)
    #remove all toy wheels and joints from scene
    toy.userData[:flippedWheels].each do |wheel|
      wheel.runAction(SKAction.removeFromParent())
    end
    toy.userData[:flippedJoints].each do |joint|
      physicsWorld.removeJoint(joint)
    end
    toy.userData[:flippedJoints] = []

    toy.physicsBody.velocity = toy.userData[:flipped_toy].physicsBody.velocity
    toy.position = toy.userData[:flipped_toy].position
    if toy.userData[:flipped_toy].physicsBody.allowsRotation
      toy.zRotation = toy.userData[:flipped_toy].zRotation
    end
    toy.userData[:flipped_toy].removeFromParent
    addChild(toy)
    #add wheels and joints
    toy.userData[:wheels].each do |wheel|
      wheel.position = CGPointMake(toy.position.x+wheel.userData[:xPos],toy.position.y+wheel.userData[:yPos])
      if toy.userData[:flipped_toy].physicsBody.allowsRotation
        translateTransform = CGAffineTransformMakeTranslation(toy.position.x, toy.position.y)
        toyinscene = get_toy_in_scene(toy)
        rotationTransform = CGAffineTransformMakeRotation(toy.userData[:flipped_toy].zRotation + (toyinscene.angle))
        customRotation = CGAffineTransformConcat(CGAffineTransformConcat( CGAffineTransformInvert(translateTransform), rotationTransform), translateTransform)
        wheel.position = CGPointApplyAffineTransform(wheel.position, customRotation)
      end
      addChild(wheel)
      axle = SKPhysicsJointPin.jointWithBodyA(toy.physicsBody, bodyB: wheel.physicsBody, anchor: wheel.position)
      physicsWorld.addJoint(axle)
      toy.userData[:joints] << axle
    end
    toy.userData[:flipped] = false
  end

  def flipToy(toy)
    #remove all toy wheels and joints from scene
    toy.userData[:wheels].each do |wheel|
      wheel.runAction(SKAction.removeFromParent())
    end
    toy.userData[:joints].each do |joint|
      physicsWorld.removeJoint(joint)
    end
    toy.userData[:joints] = []

    new_toy = toy.userData[:flipped_toy]
    new_toy.physicsBody.velocity = toy.physicsBody.velocity
    new_toy.position = toy.position
    if toy.physicsBody.allowsRotation
      new_toy.zRotation = toy.zRotation
    end
    toy.removeFromParent
    addChild(new_toy)

    #add new wheels and joints
    toy.userData[:flippedWheels].each do |wheel|
      wheel.position = CGPointMake(toy.position.x+wheel.userData[:xPos],toy.position.y+wheel.userData[:yPos])
      if toy.physicsBody.allowsRotation
        translateTransform = CGAffineTransformMakeTranslation(toy.position.x, toy.position.y)
        toyinscene = get_toy_in_scene(toy)
        rotationTransform = CGAffineTransformMakeRotation(toy.zRotation + toyinscene.angle)
        customRotation = CGAffineTransformConcat(CGAffineTransformConcat( CGAffineTransformInvert(translateTransform), rotationTransform), translateTransform)
        wheel.position = CGPointApplyAffineTransform(wheel.position, customRotation)
      end
      addChild(wheel)
      axle = SKPhysicsJointPin.jointWithBodyA(new_toy.physicsBody, bodyB: wheel.physicsBody, anchor: wheel.position)
      physicsWorld.addJoint(axle)
      toy.userData[:flippedJoints] << axle
    end
    toy.userData[:flipped] = true
  end

# This is called once per frame.
# Most screen logic goes here.
  def update(current_time)
    # check everything before a scene is drawn
    checkFront

    # Places sound actions at the front
    sound_actions = @actions_to_fire.reject { |action| action[:effect_type] != :play_sound }
    @actions_to_fire.reject! { |action| action[:action_type] == :play_sound }
    sound_actions << @actions_to_fire
    @actions_to_fire = sound_actions.flatten

    # Debugging purposes
    if @check
      puts @toy_hash[@check].last.physicsBody.to_s
    end

    @actions_to_fire.each do |action|

      # minh comment: all toys with the same type
      toy_id = action[:toy]

      toys = @toy_hash[toy_id] # all toys of the correct type
      #puts "toy hash id = #{toy_id}"
      if toys.nil?     # If the toy gets deleted after an action is added
        next
      end
      #if collision - remove all toys that are same but not collided
      #if action[:action_type] == :collision or action[:action_type] == :when_created or action[:action_type] == :score_reaches or action[:action_type] == :toy_touch

      # What is this below code doing????
      if action[:action_type] == :collision or action[:action_type] == :when_created or action[:action_type] == :score_reaches or action[:action_type] == :toy_touch
        new_toys = []
        toys.each do |toy|
          if toy.userData[:uniqueID] == action[:action_param][1]
            new_toys << toy
          end
        end
        toys = new_toys
      end

      #puts "action to fire: #{action}"

      ### Apply effects on toys for each action
      toys.delete_if do |toy| # toys here are SKSpriteNodes
        if toy.userData[:uniqueID] == -1
          delete = true
        else
          effect = action[:effect_type]
          param = action[:effect_param]
          #puts "effect #{effect}, param #{param}"
          delete = false
          send = false
          #puts "Value param: #{param}"
          case effect
            when :apply_force
              # make force relative to the toy
              rotation = CGAffineTransformMakeRotation(toy.zRotation)
              if(param.x.to_i == 0 && param.y.to_i == 0)
                # random force applied
                ranX = rand(Constants::GENERAL_TOY_FORCE) - Constants::GENERAL_TOY_FORCE / 2
                ranY = rand(Constants::GENERAL_TOY_FORCE) - Constants::GENERAL_TOY_FORCE / 2
                param = CGPointApplyAffineTransform(CGPointMake(ranX,ranY), rotation)
              else
                param = CGPointApplyAffineTransform(param, rotation)
              end
              #puts "apply force at #{param}: (#{param.x},#{param.y})"

              send = true
              effect = "applyForce"

            when :explosion
              #
              @mutex.synchronize do
                if toy.userData[:uniqueID] != -1
                  explode_toy(toy, param)
                  toy.userData[:uniqueID] = -1
                end
              end
              delete = true

            when :apply_torque
              if param != Constants::RANDOM_HASH_KEY
                param *= toy.size.width/2  # Scale by opposing torque on toy
              else
                #param = Constants::RANDOM_HASH_KEY.to_i % 4 - rand(2.0)
                param = (rand(20.0) - 10)*toy.size.width/2 # Scale by opposing torque on toy
              end

              effect = "applyTorque"
              send = true

            when :delete_effect
              fadeOut = SKAction.fadeOutWithDuration(param)
              remove = SKAction.removeFromParent()
              sequence = SKAction.sequence([fadeOut, remove])
              #toy.runAction(sequence)
              apply_action_to_toy(toy, sequence)
              toy.userData[:uniqueID] = -1
              delete = true

            when :play_sound
              sound = SKAction.playSoundFileNamed(param, waitForCompletion: false)
              toy.runAction(sound)

            when :move_towards
              theOtherToy = nil
              otherToys = @toy_hash[param] # all toys of the correct type
              if otherToys != nil
                otherToys.each do |otherToy|
                  theOtherToy = otherToy
                end
              end
              if theOtherToy != nil
                xDirection = theOtherToy.position.x - toy.position.x
                yDirection = theOtherToy.position.y - toy.position.y
                length = Math.sqrt(xDirection*xDirection + yDirection*yDirection)
                velocity = CGVectorMake(Constants::MOVE_TOWARDS_AND_AWAY_SPEED*xDirection/length, Constants::MOVE_TOWARDS_AND_AWAY_SPEED*yDirection/length)
                toy.physicsBody.velocity = velocity
              end

            when :move_away
              theOtherToy = nil
              otherToys = @toy_hash[param] # all toys of the correct type
              if otherToys != nil
                otherToys.each do |otherToy|
                  theOtherToy = otherToy
                end
              end
              if theOtherToy != nil
                xDirection = toy.position.x - theOtherToy.position.x
                yDirection = toy.position.y - theOtherToy.position.y
                length = Math.sqrt(xDirection*xDirection + yDirection*yDirection)
                velocity = CGVectorMake(Constants::MOVE_TOWARDS_AND_AWAY_SPEED*xDirection/length, Constants::MOVE_TOWARDS_AND_AWAY_SPEED*yDirection/length)
                toy.physicsBody.velocity = velocity
              end

            when :scene_shift
              @delegate.scene_shift(param)
              p "scene shift"

            when :text_bubble
              position = view.convertPoint(toy.position, fromScene: self)
              position -= CGPointMake(-20, 20)
              frame = CGRectMake(*position, 40, 40)
              @delegate.create_label(param, frame)
              if @label
                @label.removeFromParent
              end

              @label = SKShapeNode.alloc.init
              num = Pointer.new(:float, 2)
              num[0] = 5
              bezier = UIBezierPath.bezierPathWithRoundedRect(CGRectMake(-20, -20, 40, 40), cornerRadius: num[0])
              @label.path = bezier.CGPath
              @label.fillColor = Constants::LIGHT_BLUE_GRAY
              @label.position = toy.position
              addChild(@label)

            when :score_adder

              # Initial set of score
              if not toy.userData[:score]
                toy.userData[:score] = 0
              end

              label_colour = nil
              # Performs action and assigns colour corresponding to type of score adder made
              case param[1]
                when "add"
                  toy.userData[:score] += param[0]
                  label_colour = UIColor.greenColor
                when "subtract"
                  toy.userData[:score] -= param[0]
                  label_colour = UIColor.redColor
                when "set"
                  toy.userData[:score] = param[0]
                  label_colour = UIColor.yellowColor
              end

              # Creates label to appear at toys position
              label = SKLabelNode.labelNodeWithFontNamed(UIFont.systemFontOfSize(14).fontDescriptor.postscriptName)
              label.position = toy.position + CGPointMake(-30, 0)
              label.fontSize = 18
              label.text = toy.userData[:score].to_s
              label.fontColor = label_colour

              addChild(label)

              # Creates Fade and sclae effect before removing
              action_duration = 1.0
              groupActions = []
              groupActions << SKAction.moveByX(10, y: 0, duration: action_duration)
              groupActions << SKAction.scaleBy(7, duration: action_duration)
              groupActions << SKAction.fadeOutWithDuration(action_duration)

              actions = SKAction.group(groupActions)
              actions = SKAction.sequence([actions, SKAction.removeFromParent])

              label.runAction(actions)

              # Checks for actions to fire if a score is reached or passed
              #puts "Toy Score: " + toy.userData[:score].to_s
              @score_actions.each do |score_action|
                # Checks toy identifier, score being reached or passed, and that the action has not been fired previously
                if score_action[:toy] == toy.name and score_action[:action_param][0] <= toy.userData[:score] and not score_action[:used].include?(toy.userData[:uniqueID])

                  # Clone the hash so its not overwritten
                  score_action = score_action.select {|k, v| true }
                  # Places identifier in hash
                  score_action[:action_param] =  [score_action[:action_param][0], toy.userData[:uniqueID]]

                  # Places uid in score action so it doesnt get fired again
                  if not score_action[:used]
                    score_action[:used] = []
                  end
                  score_action[:used] << toy.userData[:uniqueID]

                  # Puts action in array for future use
                  if @actions_to_be_fired
                    @actions_to_be_fired << score_action
                  else
                    @actions_to_be_fired = [score_action]
                  end
                  #puts "score action "+ score_action.to_s
                end
              end

            when :create_new_toy
              #puts "create_new_toy"
              id = action[:effect_param][:id]
              rotation = CGAffineTransformMakeRotation(toy.zRotation)
              # Gets toy in scene from loaded toys
              toy_in_scene = @loaded_toys[id].select {|s| s.uid == action[:uid]}.first
              displacement = CGPointMake(action[:effect_param][:x], action[:effect_param][:y])

              # if this is to be randomly created, put the position to be random on the screen
              if displacement.x.to_i == Constants::RANDOM_HASH_KEY && displacement.y.to_i == Constants::RANDOM_HASH_KEY
                toy_in_scene.position = CGPointMake(rand(self.size.width.to_i), rand(self.size.height.to_i))
              else
                displacement = CGPointApplyAffineTransform(displacement, rotation)
                displacement = CGPointMake(displacement.x, displacement.y)
                toy_in_scene.position = view.convertPoint(toy.position, fromScene: self) - displacement
              end
              new_toy = new_toy(toy_in_scene, true)
              new_toy.color = UIColor.grayColor
              new_toy.zRotation = (new_toy.zRotation + toy.zRotation)
              new_toy.userData[:id] = rand(2**60).to_s
              new_toy.userData[:templateID] = toy_in_scene.uid
              new_toy.userData[:uniqueID] = rand(2**60).to_s

              #trigger any create actions
              @create_actions.each do |create_action|
                if create_action[:toy] == new_toy.name
                  #trigger event
                  create_action = create_action.clone
                  timeDelay = create_action[:action_param][0]
                  create_action[:action_param] = [nil, new_toy.userData[:uniqueID]]
                  add_actions_for_update([create_action],timeDelay)

                  # create_action[:action_param] = [nil, new_toy.userData[:uniqueID]]
                  # #create_action[:action_param][1] = new_toy.userData[:uniqueID]
                  # if @actions_to_be_fired
                  #   @actions_to_be_fired << create_action
                  # else
                  #   @actions_to_be_fired = [create_action]
                  # end
                  # puts "create action "+ create_action.to_s

                end
              end
              @toy_hash[id] << new_toy
              @toys_count[id] = 0 unless @toys_count[id]
              @toy_hash[id].delete_if do |check_toy|
                bool = check_toy.userData[:uniqueID] == -1
                #puts "UniqueID: " + check_toy.userData[:uniqueID].to_s
                #puts "Is dead?: " + bool.to_s
                bool
              end

              # remove toys when it reaches to some particular MAX_CREATES value
              while @toy_hash[id].length - @toys_count[id] > MAX_CREATES
                to_remove = @toy_hash[id].delete_at(@toys_count[id])
                fadeOut = SKAction.fadeOutWithDuration(0.7)
                remove = SKAction.removeFromParent()
                sequence = SKAction.sequence([fadeOut, remove])
                apply_action_to_toy(to_remove, sequence)
              end
          end
          if send
            #puts "mass "+toy.userData[:mass].to_s
            param = scale_force_mass(param, toy.userData[:mass])
            toy.physicsBody.send(effect, param)
          end
        end
        #puts "Deleted: " + delete.to_s
        delete
      end
    end
    @actions_to_fire = []
    if @actions_to_be_fired
      @actions_to_fire += @actions_to_be_fired
    end
    @actions_to_be_fired = []
  end

  def scale_force_mass(param, mass)
    #puts "Mass: " + mass.to_s
    scale = mass

    param = param * scale

    param
  end

  def explode_toy(toy, force)

    toy_in_scene = @toys.select {|s| s.template.identifier == toy.name and s.uid == toy.userData[:uniqueID]}.first
    if toy_in_scene.nil?
      toy_in_scene = loaded_toys[toy.name].select {|s| s.uid == toy.userData[:templateID]}.first
    end

    templates = []
    new_name = toy.userData[:uniqueID]
    @toy_hash[new_name] = []
    partsArray = toy_in_scene.template.exploded

    if force.to_i == Constants::RANDOM_HASH_KEY.to_i
      force = rand(Constants::RANDOM_HASH_KEY)/5.0
    end

    timer = Constants::TIME_AFTER_EXPLOSION #force * TIMER_SCALE

    force = scale_force_mass(force, toy.userData[:mass])
    partsArray.each do |part|
      #
      templates << ToyTemplate.new([part], new_name)
      new_toy = ToyInScene.new(templates.last, toy_in_scene.zoom)
      new_toy.change_position(view.convertPoint(toy.position, fromScene: self))
      displacement = new_toy.centre_parts
      if displacement.x == 0
        displacement = CGPointMake(1, displacement.y)
      end
      if displacement.y == 0
        displacement = CGPointMake(displacement.x, 1)
      end

      new_toy.change_angle(toy_in_scene.angle)
      new_sprite_toy = SKSpriteNode.spriteNodeWithTexture(SKTexture.textureWithImage(get_image(new_toy)))
      if part.is_a? PointsPart
        new_sprite_toy.zRotation = toy.zRotation
        new_sprite_toy.position = view.convertPoint(new_toy.position, toScene: self)

        physics_points = ToyPhysicsBody.new(new_toy.template.parts).convex_hull_for_physics(new_toy.zoom)

        if physics_points.length == 0
          new_sprite_toy.physicsBody = SKPhysicsBody.bodyWithCircleOfRadius(1)
        else
          path = CGPathCreateMutable()
          CGPathMoveToPoint(path, nil, *physics_points[0])
          physics_points[0..-1].each do |p|
            # To fix the Assertion failed: (area > 1.19209290e-7F), function ComputeCentroid avoid crash
            if p.x.abs > 1.0 && p.y.abs > 1.0
              CGPathAddLineToPoint(path, nil, *p)
            end
          end
          new_sprite_toy.physicsBody = SKPhysicsBody.bodyWithPolygonFromPath(path)

        end


        if DEBUG_EXPLOSIONS
          new_sprite_toy.position = CGPointMake(new_sprite_toy.position.x+displacement.x*2, new_sprite_toy.position.y+displacement.y*2)
          new_sprite_toy.physicsBody.dynamic = false
          new_sprite_toy.physicsBody.affectedByGravity = false
        end
      elsif part.is_a? CirclePart
        wheel = new_toy.add_wheels_in_scene(self)[0]
        new_sprite_toy.hidden = false

        new_sprite_toy.position = view.convertPoint(new_toy.position, toScene: self)
        body = SKPhysicsBody.bodyWithCircleOfRadius(wheel.radius)
        new_sprite_toy.physicsBody = body
        if DEBUG_EXPLOSIONS
          new_sprite_toy.position.x += 10*displacement.x
          new_sprite_toy.position.y += 10*displacement.y
          new_sprite_toy.physicsBody.dynamic = false
          new_sprite_toy.physicsBody.affectedByGravity = false
        end
      end

      if new_sprite_toy.physicsBody != nil && toy.physicsBody != nil
        new_sprite_toy.physicsBody.velocity = toy.physicsBody.velocity
        new_sprite_toy.name = new_name
        addChild(new_sprite_toy)
        new_sprite_toy.physicsBody.send(:applyForce, CGPointMake(force/displacement.x , force/displacement.y))
        @toy_hash[new_name] << new_sprite_toy
        fadeOut = SKAction.fadeOutWithDuration(timer)
        remove = SKAction.removeFromParent()
        seq = SKAction.sequence([fadeOut, remove])
        if not DEBUG_EXPLOSIONS
          new_sprite_toy.runAction(seq)
        end
      end
    end
    remove = SKAction.removeFromParent()
    apply_action_to_toy(toy, remove)
    new_name
  end

  def apply_action_to_toy(toy, action)
    toy.runAction(action)
    toy.userData[:wheels].each do |wheel|
      wheel.runAction(action)
    end
  end



  def draw_sole_point(context, sole_point)
    sole_point = @points[-1]

  end

  def draw_path_of_points(context, points)
    # Minh changed, due to ios 8.0 difference
    screen_scale = 1.0 # UIScreen.mainScreen.scale
    #screen_scale = UIScreen.mainScreen.scale # still the nasty hack
    CGContextSetLineWidth(context, ToyTemplate::TOY_LINE_SIZE/4 / screen_scale)
    first = true
    points.each do |point|
      if first
        first = false
        CGContextMoveToPoint(context, point.x / screen_scale, point.y / screen_scale)
      else
        CGContextAddLineToPoint(context, point.x / screen_scale, point.y / screen_scale)
      end
    end
    CGContextStrokePath(context)
  end

  def add_edges
    create_background_image
    # then do the static physics stuff for the edges
    # first I currently use a frame around the outside
    #walls = CGRectMake(*frame.origin, frame.size.width, frame.size.height - AppDelegate::TAB_HEIGHT)
    #self.physicsBody = SKPhysicsBody.bodyWithEdgeLoopFromRect(frame)

    @edges.each do |edge|
      case edge
        when CirclePart
          #puts "PlayScene"
          body = SKPhysicsBody.bodyWithCircleOfRadius(edge.radius)
          body.dynamic = false
          body.contactTestBitMask = 1
          node = SKNode.node
          node.position = CGPointMake(edge.position[0], size.height - edge.position[1])
          node.hidden = true
          node.physicsBody = body
          addChild(node)
        when PointsPart
          points = edge.points_for_scene_background(size)
          current_pt = points[0]
          points[1..-1].each do |next_pt|
            body = SKPhysicsBody.bodyWithEdgeFromPoint(current_pt, toPoint: next_pt)
            body.contactTestBitMask = 1
            node = SKNode.node
            node.hidden = true
            node.physicsBody = body
            addChild(node)
            current_pt = next_pt
          end
      end
    end

  end

# Create an image for the whole background
  def create_background_image

    # Minh changed, due to ios 8.0 difference
    screen_scale = 1.0 # UIScreen.mainScreen.scale
    #puts "$$$ screen scale = #{screen_scale}"

    frame_size = CGSizeMake(frame.size.width / screen_scale, frame.size.height / screen_scale)
    UIGraphicsBeginImageContextWithOptions(frame_size, true, 0.0) #frame.size, true, 0.0)
    context = UIGraphicsGetCurrentContext()
    setup_context(context)
    SceneCreatorView::DEFAULT_SCENE_COLOUR.set

    if @backgroundImage != nil
      @backgroundImage.drawInRect(CGRectMake(0, 0, frame_size.width, frame_size.height))
    else
      CGContextFillRect(context, CGRectMake(0, 0, frame_size.width, frame_size.height)) #size.width-100, size.height-100))
    end

    @edges.each do |edge|
      edge.colour.set
      # circles
      case edge
        when CirclePart
          width = edge.radius * 2 / screen_scale
          CGContextFillEllipseInRect(context, CGRectMake(edge.left / screen_scale, edge.top / screen_scale, width, width))
        when PointsPart
          if edge.points.length == 1
            line_size = ToyTemplate::TOY_LINE_SIZE/4
            sole_point = edge.points[0]
            scaled_sole_point = CGPointMake(sole_point.x - line_size/2, sole_point.y - line_size/2) / screen_scale
            CGContextFillEllipseInRect(context, CGRectMake(*scaled_sole_point, #CGRectMake(sole_point.x - line_size/2, sole_point.y - line_size/2,
                                                           line_size / screen_scale, line_size / screen_scale))
          else
            draw_path_of_points(context, edge.points)
          end
      end
    end

    background = SKSpriteNode.spriteNodeWithTexture(SKTexture.textureWithImage(UIGraphicsGetImageFromCurrentImageContext()))

    #texture = SKTexture.textureWithImageNamed("bground.jpg")
    #background = SKSpriteNode.spriteNodeWithTexture(texture)
    #background.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
    #addChild(background)

    UIGraphicsEndImageContext()
    background.position = CGPointMake(size.width/2, size.height/2)
    background.blendMode = SKBlendModeReplace # background image doesn't need any alpha
    addChild(background)
  end

  def add_toys
    @toy_hash = {}
    @loaded_toys = {}
    @toys.each do |toy_in_scene|
      if loaded_toys[toy_in_scene.template.identifier].nil?
        loaded_toys[toy_in_scene.template.identifier] = []
      end
      loaded_toys[toy_in_scene.template.identifier] << toy_in_scene
      toy = new_toy(toy_in_scene)
      id = toy_in_scene.template.identifier
      @toy_hash[id] = [] unless @toy_hash[id]
      @toy_hash[id] << toy # add the toy (can be multiple toys of the same type)
      @toys_count[id] = 0 unless @toys_count[id]
      @toys_count[id] += 1
    end
  end

  def get_image(toy_in_scene) # this is largely a hack because retina mode seems to get it wrong
    #screen = UIScreen.mainScreen.scale
    # Minh changed, due to ios 8.0 difference
    screen = 1.0 # UIScreen.mainScreen.scale
    return toy_in_scene.image if screen == 1.0
    return toy_in_scene.template.create_image(toy_in_scene.zoom / screen)
  end

  def new_toy(toy_in_scene, darken = false)
    image = get_image(toy_in_scene)
    # if darken
    #   imageWidth = image.size.width
    #   image = image.darken()
    #   image = image.scale_to([imageWidth,999])
    # end
    toy = SKSpriteNode.spriteNodeWithTexture(SKTexture.textureWithImage(image))
    toy.name = toy_in_scene.template.identifier # TODO: this needs to be unique
    toy.position = view.convertPoint(toy_in_scene.position, toScene: self) #CGPointMake(toy_in_scene.position.x, size.height-toy_in_scene.position.y)
    toy.zRotation = -toy_in_scene.angle
    toy.userData = {score: 0, uniqueID: toy_in_scene.uid} #add unique id to allow for single collision
    if toy_in_scene.template.always_travels_forward
      toy.userData[:front] = toy_in_scene.template.front
    end
    addChild(toy)
    # physics body stuff
    physics_points = ToyPhysicsBody.new(toy_in_scene.template.parts).convex_hull_for_physics(toy_in_scene.zoom)
    if physics_points.length == 0
      toy.physicsBody = SKPhysicsBody.bodyWithCircleOfRadius(1)
    else
      path = CGPathCreateMutable()
      CGPathMoveToPoint(path, nil, *physics_points[0])
      physics_points[1..-1].each { |p| CGPathAddLineToPoint(path, nil, *p) }
      toy.physicsBody = SKPhysicsBody.bodyWithPolygonFromPath(path)
    end
    toy.physicsBody.contactTestBitMask = 1

    #properties
    toy.physicsBody.allowsRotation = toy_in_scene.template.can_rotate;
    toy.physicsBody.dynamic = !(toy_in_scene.template.stuck)
    toy.physicsBody.affectedByGravity = toy_in_scene.template.gravity

    toy.userData[:wheels] = []
    toy.userData[:joints] = []
    toy.userData[:flipped] = false
    #store mass in userdata as it doesn't change to get around race condition with flipping toy
    toy.userData[:mass] = toy.physicsBody.mass

    # now any wheels
    toy_in_scene.add_wheels_in_scene(self).each do |wheel|
      # first the node
      wheel_node = SKNode.node
      wheel_node.hidden = true
      wheel_node.position = wheel.position
      #puts "Wheel pos X: " + wheel.position.x.to_s + ", Y: " + wheel.position.y.to_s
      #give the wheel the same name and id as the toy
      wheel_node.name = toy_in_scene.template.identifier
      wheel_node.userData = toy.userData.clone
      wheel_node.userData[:xPos] = (wheel.position.x - toy.position.x)
      wheel_node.userData[:yPos] = (wheel.position.y - toy.position.y)
      # then the body
      body = SKPhysicsBody.bodyWithCircleOfRadius(wheel.radius)
      body.contactTestBitMask = 1
      wheel_node.physicsBody = body
      addChild(wheel_node)
      # then the joint
      axle = SKPhysicsJointPin.jointWithBodyA(toy.physicsBody, bodyB: wheel_node.physicsBody, anchor: wheel.position)
      physicsWorld.addJoint(axle)
      toy.userData[:wheels] << wheel_node
      toy.userData[:joints] << axle
    end

    #add flipped physicsbody if traveling forward
    if toy_in_scene.template.always_travels_forward
      image = get_image(toy_in_scene)
      if toy_in_scene.template.front == Constants::Front::Left or toy_in_scene.template.front == Constants::Front::Right
        flipped_image = flipImage(image,true)
      else
        flipped_image = flipImage(image,false)
      end
      flipped_toy = SKSpriteNode.spriteNodeWithTexture(SKTexture.textureWithImage(flipped_image))
      flipped_toy.name = toy_in_scene.template.identifier # TODO: this needs to be unique
      flipped_toy.userData = {score: 0, uniqueID: toy_in_scene.uid} #add unique id to allow for single collision

      #might not need to add these yet - will have to update when adding to scene
      flipped_toy.position = view.convertPoint(toy_in_scene.position, toScene: self)
      flipped_toy.zRotation = -toy_in_scene.angle

      if physics_points.length == 0
        flipped_toy.physicsBody =  SKPhysicsBody.bodyWithCircleOfRadius(1)
      else
        path = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, *physics_points[0])
        physics_points[1..-1].each { |p| CGPathAddLineToPoint(path, nil, *p) }
        if toy_in_scene.template.front == Constants::Front::Left or toy_in_scene.template.front == Constants::Front::Right
          transform = CGAffineTransformMakeScale(-1.0, 1.0)
        else
          transform = CGAffineTransformMakeScale(1.0,-1.0)
        end
        pnter = Pointer.new("{CGAffineTransform=ffffff}",6)
        pnter[0] = transform
        flipped_Path = CGPathCreateCopyByTransformingPath(path, pnter)

        flipped_toy.physicsBody = SKPhysicsBody.bodyWithPolygonFromPath(flipped_Path)
        flipped_toy.physicsBody.contactTestBitMask = 1

        #properties
        flipped_toy.physicsBody.allowsRotation = toy_in_scene.template.can_rotate
        flipped_toy.physicsBody.dynamic = !(toy_in_scene.template.stuck)

        toy.userData[:flippedWheels] = []
        toy.userData[:flippedJoints] = []

        toy_in_scene.add_flipped_wheels_in_scene(self, toy_in_scene.template.front).each do |wheel|
          # first the node
          wheel_node = SKNode.node
          wheel_node.hidden = true
          wheel_node.position = wheel.position
          #addChild(wheel_node) #TODO remove
          #give the wheel the same name and id as the toy
          wheel_node.name = toy_in_scene.template.identifier
          wheel_node.userData = toy.userData.clone

          wheel_node.userData[:xPos] = ( wheel.position.x - flipped_toy.position.x)
          wheel_node.userData[:yPos] = ( wheel.position.y - flipped_toy.position.y)
          # then the body
          body = SKPhysicsBody.bodyWithCircleOfRadius(wheel.radius)
          body.contactTestBitMask = 1
          wheel_node.physicsBody = body
          # then the joint
          axle = SKPhysicsJointPin.jointWithBodyA(toy.userData[:flippedBody], bodyB: wheel_node.physicsBody, anchor: wheel_node.position)
          #physicsWorld.addJoint(axle) #todo remove
          #add wheels and joints to user data?
          toy.userData[:flippedJoints] << axle
          toy.userData[:flippedWheels] << wheel_node
        end

        toy.userData[:flipped_toy] = flipped_toy
      end

    end

    #puts "trigger any create actions"

    #trigger any create actions
    @create_actions.each do |action|
      if action[:toy] == toy.name
        action[:action_param] = [action[:action_param][0], toy.userData[:uniqueID]]
        # apply some delays
        add_actions_for_update([action],action[:action_param][0])
      end
    end
    toy
  end

  def flipImage(image, horizontal)
    UIGraphicsBeginImageContext(image.size)
    context = UIGraphicsGetCurrentContext()

    if horizontal
      CGContextTranslateCTM(context, image.size.width, 0.0)
      CGContextScaleCTM(context, -1.0, 1.0)
    else
      CGContextTranslateCTM(context, 0.0, image.size.height)
      CGContextScaleCTM(context, 1.0, -1.0)
    end

    image.drawInRect(CGRectMake(0,0,image.size.width,image.size.height))

    new_image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    new_image
  end

# Called from Play View Controller in able to preprocess create new toys
# [ID, Displacement.x, displacement.y, zoom, angle]
  def add_create_toy_ref(toy_args, toy_template)
    # puts toy_args.to_s
    # puts toy_template.identifier
    if @toy_hash[toy_template.identifier].nil?
      @toy_hash[toy_template.identifier]= []
    end
    toy_in_scene = ToyInScene.new(toy_template, toy_args[:zoom])
    toy_in_scene.change_angle(toy_args[:angle])
    toy_in_scene.change_position(CGPointMake(toy_args[:x], toy_args[:y]))

    if @loaded_toys.nil?
      @loaded_toys = {}
    end

    if @loaded_toys[toy_template.identifier].nil?
      @loaded_toys[toy_template.identifier] = []
    end

    @loaded_toys[toy_template.identifier] << toy_in_scene
    toy_in_scene.uid
  end

  def setup_context(context)
    CGContextSetLineWidth(context, ToyTemplate::TOY_LINE_SIZE/4)
    CGContextSetLineCap(context, KCGLineCapRound)
    CGContextSetLineJoin(context, KCGLineJoinRound)
  end

  def didBeginContact(contact)
    #check each collision action - if  the 2 colliding toys have the corresponding identifiers to a collision action, add it
    if @collision_actions
      @collision_actions.each do |action|
        if contact.bodyA.node.userData == contact.bodyB.node.userData
          next
        end
        if contact.bodyA.node.name == action[:toy]
          if contact.bodyB.node.name == action[:action_param]
            #alter action param to include the specific toy that collided(unique id is stored as second param in action params array)
            new_action = action.inject({}) { |h, (k, v)| k != :action_param ? h[k] = v : h[k] = [v,contact.bodyA.node.userData[:uniqueID]]; h }
            add_actions_for_update([new_action])
            #if identifiers are the same add another action for second toy
            if action[:toy] == action[:action_param]
              new_action = action.inject({}) { |h, (k, v)| k != :action_param ? h[k] = v : h[k] = [v,contact.bodyB.node.userData[:uniqueID]]; h }
              add_actions_for_update([new_action])
            end
          end
        elsif contact.bodyB.node.name == action[:toy]
          if contact.bodyA.node.name == action[:action_param]
            #alter action param to include the specific toy that collided(unique id is stored as second param in action params array)
            new_action = action.inject({}) { |h, (k, v)| k != :action_param ? h[k] = v : h[k] = [v,contact.bodyB.node.userData[:uniqueID]]; h }
            add_actions_for_update([new_action])
            #if identifiers are the same add another action for second toy
            if action[:toy] == action[:action_param]
              new_action = action.inject({}) { |h, (k, v)| k != :action_param ? h[k] = v : h[k] = [v,contact.bodyA.node.userData[:uniqueID]]; h }
              add_actions_for_update([new_action])
            end
          end
        end
      end
    end
  end

  def didEndContact(contact)
  end

  def add_collision(action)
    if @collision_actions
      @collision_actions << action
    else
      @collision_actions = []
      @collision_actions << action
    end
  end

  def paused= (value)
    @paused = value
  end

# def delegate= (controler)
#   @delegate = controler
# end

end