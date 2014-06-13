# The scene where it all works.
#require 'thread'

class PlayScene < SKScene

  attr_accessor :toys # ToyInScene objects
  attr_accessor :edges # ToyParts - either CirclePart or PointsPart
  attr_reader :loaded_toys # ToyInScene not put into play straight away
  attr_reader :mutex

  DEBUG_EXPLOSIONS = false

  def didMoveToView(view)
    @actions_to_fire = []
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
    add_edges
    add_toys
  end

  # Actions are added here to be fired at the update
  def add_actions_for_update(actions)
    @actions_to_fire += actions
  end

  # This is called once per frame.
  # Most screen logic goes here.
  def update(current_time)
    @actions_to_fire.each do |action|
      toy_id = action[:toy]
      toys = @toy_hash[toy_id] # all toys of the correct type
      if toys.nil?     # If the toy gets deleted after an action is added
        next
      end
      #if collision - remove all toys that are same but not collided
      if action[:action_type] == :collision
        new_toys = []
        toys.each do |toy|
          if toy.userData[:uniqueID] == action[:action_param][1]
            new_toys << toy
          end
        end
        toys = new_toys
      end
      toys.delete_if do |toy| # toys here are SKSpriteNodes
        if toy.physicsBody == nil
          delete = true
        else
          effect = action[:effect_type]
          param = action[:effect_param]
          delete = false
          send = false
          case effect
            when :apply_force
              # make force relative to the toy
              rotation = CGAffineTransformMakeRotation(toy.zRotation)
              param = CGPointApplyAffineTransform(param, rotation)
              send = true
              effect = "applyForce"
            when :explosion
              #puts "Velocity Toy(B4 Dele): X: " + toy.physicsBody.velocity.dx.to_s + ",  Y: " + toy.physicsBody.velocity.dy.to_s
              @mutex.synchronize do
                if toy.physicsBody != nil
                  explode_toy(toy, param)
                  removeChildrenInArray([toy])
                  toy.physicsBody = nil
                end
              end
              delete = true
            when :apply_torque
              param *= toy.size.width/2
              effect = "applyTorque"
              send = true
            when :create_new_toy # TODO Adjust to angle of toy
              toy_in_scene = @loaded_toys[action[:effect_param][:id]].select {|s| s.uid == action[:uid]}.first
              toy_in_scene.position = CGPointMake(action[:effect_param][:x], action[:effect_param][:y]) + view.convertPoint(toy.position, fromScene: self)
              new_toy = new_toy(toy_in_scene)
              #new_toy.position = CGPointApplyAffineTransform(new_toy.position,)
              #puts "SpwanerPos X: " + toy.position.x.to_s + ", Y: " + toy.position.y.to_s
              #puts "DispPos X: " + toy_in_scene.position.x.to_s + ", Y: " + toy_in_scene.position.y.to_s
              #new_toy.position = toy.position + toy_in_scene.position
              #puts "ChildPos X: " + new_toy.position.x.to_s + ", Y: " + new_toy.position.y.to_s
              new_toy.userData[:templateID] = toy_in_scene.uid
              new_toy.userData[:uniqueID] = rand(2**60).to_s
              @toy_hash[action[:effect_param][:id]] << new_toy
          end
          if send
            param = scale_force_mass(param, toy.physicsBody.mass)
            toy.physicsBody.send(effect, param)
          end
        end
        delete
      end
    end
    @actions_to_fire = []
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
    partsArray = check_parts(toy_in_scene.template.parts,toy_in_scene.template.center)
    force = scale_force_mass(force, toy.physicsBody.mass)
    partsArray.each do |part|
      #position = centre_part(part, toy.position)
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
        #puts "Toy Position X: " + new_toy.position.x.to_s + " Y: " +  new_toy.position.y.to_s #+ " , " + new_toy.position.
        physics_points = ToyPhysicsBody.new(new_toy.template.parts).convex_hull_for_physics(new_toy.zoom)
        if physics_points.length == 0
          new_sprite_toy.physicsBody = SKPhysicsBody.bodyWithCircleOfRadius(1)
        else
          path = CGPathCreateMutable()
          CGPathMoveToPoint(path, nil, *physics_points[0])
          physics_points[1..-1].each { |p| CGPathAddLineToPoint(path, nil, *p) }
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
        #puts "Wheel Pos, X: " + new_toy.position.x.to_s + ", Y: " + new_toy.position.y.to_s
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
      #puts "Velocity Toy: X: " + toy.physicsBody.velocity.dx.to_s + ",  Y: " + toy.physicsBody.velocity.dy.to_s
      #puts "Velocity Before: X: " + new_sprite_toy.physicsBody.velocity.dx.to_s + ",  Y: " + new_sprite_toy.physicsBody.velocity.dy.to_s
      new_sprite_toy.physicsBody.velocity = toy.physicsBody.velocity
      #puts "Velocity After: X: " + new_sprite_toy.physicsBody.velocity.dx.to_s + ",  Y: " + new_sprite_toy.physicsBody.velocity.dy.to_s
      new_sprite_toy.name = new_name
      addChild(new_sprite_toy)
      #puts "Mag: " + force.to_s
      #puts "Force X: " + (force/displacement.x/20).to_s + ", Y: " + (-force/displacement.y/20).to_s
      new_sprite_toy.physicsBody.send(:applyForce, CGPointMake(force/displacement.x , force/displacement.y))
      @toy_hash[new_name] << new_sprite_toy
      fadeOut = SKAction.fadeOutWithDuration(5.0)
      remove = SKAction.removeFromParent()
      seq = SKAction.sequence([fadeOut, remove])
      if not DEBUG_EXPLOSIONS
        new_sprite_toy.runAction(seq)
      end
    end
    new_name
  end


  # Used to break a parts array into multiple parts (Even if there is only one Part!(PointsPart Only))

  def check_parts(parts,center)
    circle_parts = parts.select {|x| x.is_a? (CirclePart) }
    point_parts = parts.select {|x| x.is_a? (PointsPart) }
    if point_parts.length == 0
      return parts
    end
    point_parts.sort_by { |x| x.points.length * -1 }

    #ensure there is at least 4 parts
    point_parts.each do |part|
      if point_parts.length + circle_parts.length > 4
        break
      end
      new_points = []
      if part.points.length == 2
        average_point = (part.points[0] + part.points[1]) /2
        new_points << [part.points[0], average_point]
        new_points << [average_point, part.points[1]]
      else
        half = part.points.length / 2
        new_points << part.points[0..half]
        if part.points.length % 2 == 1
          left_point = (part.points[half] + part.points[half+1]) /2
          right_point = (part.points[half+1] + part.points[half+2]) /2
          new_points << part.points[half..part.points.length]
          new_points[0].push(left_point)
          new_points[1].insert(0, right_point)
        else
          new_points << part.points[half+1..part.points.length]
        end
      end
      point_parts << PointsPart.new(new_points[0], part.colour)
      point_parts << PointsPart.new(new_points[1], part.colour)
      point_parts.delete(part)
    end

    #split if center is close to toy center
    point_parts.each do |part|
      #if center of part is close to center of toy split it
      if (part.center[0]-center[0]).abs < 1 and (part.center[1]-center[1]).abs < 1
        new_points = []
        if part.points.length == 2
          average_point = (part.points[0] + part.points[1]) /2
          new_points << [part.points[0], average_point]
          new_points << [average_point, part.points[1]]
        else
          half = part.points.length / 2
          new_points << part.points[0..half]
          if part.points.length % 2 == 1
            left_point = (part.points[half] + part.points[half+1]) /2
            right_point = (part.points[half+1] + part.points[half+2]) /2
            new_points << part.points[half..part.points.length]
            new_points[0].push(left_point)
            new_points[1].insert(0, right_point)
          else
            new_points << part.points[half+1..part.points.length]
          end
        end
        point_parts << PointsPart.new(new_points[0], part.colour)
        point_parts << PointsPart.new(new_points[1], part.colour)
        point_parts.delete(part)
      end
    end

    return point_parts + circle_parts
  end

  def draw_sole_point(context, sole_point)
    sole_point = @points[-1]

  end

  def draw_path_of_points(context, points)
    screen_scale = UIScreen.mainScreen.scale # still the nasty hack
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
    create_image
    # then do the static physics stuff for the edges
    # first I currently use a frame around the outside
    #walls = CGRectMake(*frame.origin, frame.size.width, frame.size.height - AppDelegate::TAB_HEIGHT)
    self.physicsBody = SKPhysicsBody.bodyWithEdgeLoopFromRect(frame)
    self.physicsBody.contactTestBitMask = 1
    @edges.each do |edge|
      case edge
        when CirclePart
          puts "PlayScene - don't add circles yet"
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
  def create_image
    #left_bottom = CGPointMake(frame.size.width, frame.size.height)
    #p left_bottom
    #left_bottom = convertPointFromView(left_bottom)
    #p CGPointMake(left_bottom.x, left_bottom.y)
    screen_scale = UIScreen.mainScreen.scale
    #return toy_in_scene.image if screen == 1.0
    ##puts "rescaling"
    #return toy_in_scene.template.create_image(toy_in_scene.zoom / screen)
    frame_size = CGSizeMake(frame.size.width / screen_scale, frame.size.height / screen_scale)
    UIGraphicsBeginImageContextWithOptions(frame_size, true, 0.0) #frame.size, true, 0.0)
    context = UIGraphicsGetCurrentContext()
    setup_context(context)
    SceneCreatorView::DEFAULT_SCENE_COLOUR.set
    CGContextFillRect(context, CGRectMake(0, 0, frame_size.width, frame_size.height)) #size.width-100, size.height-100))
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
    end
  end

  def get_image(toy_in_scene) # this is largely a hack because retina mode seems to get it wrong
    screen = UIScreen.mainScreen.scale
    return toy_in_scene.image if screen == 1.0
    #puts "rescaling"
    return toy_in_scene.template.create_image(toy_in_scene.zoom / screen)
  end

  def new_toy(toy_in_scene)
    image = get_image(toy_in_scene)
    toy = SKSpriteNode.spriteNodeWithTexture(SKTexture.textureWithImage(image))
    toy.name = toy_in_scene.template.identifier # TODO: this needs to be unique
    toy.position = view.convertPoint(toy_in_scene.position, toScene: self) #CGPointMake(toy_in_scene.position.x, size.height-toy_in_scene.position.y)
    toy.zRotation = -toy_in_scene.angle
    toy.userData = {uniqueID: toy_in_scene.uid}
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

    # now any wheels
    toy_in_scene.add_wheels_in_scene(self).each do |wheel|
      # first the node
      wheel_node = SKNode.node
      wheel_node.hidden = true
      wheel_node.position = wheel.position
      #give the wheel the same name and id as the toy
      wheel_node.name = toy_in_scene.template.identifier
      wheel_node.userData = toy.userData
      # then the body
      body = SKPhysicsBody.bodyWithCircleOfRadius(wheel.radius)
      body.contactTestBitMask = 1
      wheel_node.physicsBody = body
      addChild(wheel_node)
      # then the joint
      axle = SKPhysicsJointPin.jointWithBodyA(toy.physicsBody, bodyB: wheel_node.physicsBody, anchor: wheel.position)
      physicsWorld.addJoint(axle)
    end
    toy
  end

  # Called from Play View Controller in able to preprocess exploded
  def add_explode_ref(explode_id)
    # @toy_hash[explode_id].each do |toy|
    #   #create_explode_toy(toy)
    # end
  end

  # Places exploded parts at toy.userData in @toy_hash
  def create_explode_toy(toy)
    toy_in_scene = @toys.select {|s| s.template.identifier == toy.name and s.uid == toy.userData[:uniqueID]}.first
    templates = []
    new_name = toy.userData[:uniqueID]
    @toy_hash[new_name] = []
    partsArray = check_parts(toy_in_scene.template.parts,toy_in_scene.template.center)
    partsArray.each do |part|
      #position = centre_part(part, toy.position)
      templates << ToyTemplate.new([part], new_name)
      new_toy = ToyInScene.new(templates.last, toy_in_scene.zoom)
      #new_toy.change_position(view.convertPoint(toy.position, fromScene: self))
      #displacement = new_toy.centre_parts
      #new_toy.change_angle(toy_in_scene.angle)
      new_sprite_toy = SKSpriteNode.spriteNodeWithTexture(SKTexture.textureWithImage(new_toy.image))
      if part.is_a? PointsPart
        #new_sprite_toy.zRotation = toy.zRotation
        new_sprite_toy.position = view.convertPoint(new_toy.position, toScene: self)

        physics_points = ToyPhysicsBody.new(new_toy.template.parts).convex_hull_for_physics(new_toy.zoom)
        if physics_points.length == 0
          new_sprite_toy.physicsBody = SKPhysicsBody.bodyWithCircleOfRadius(1)
        else
          path = CGPathCreateMutable()
          CGPathMoveToPoint(path, nil, *physics_points[0])
          physics_points[1..-1].each { |p| CGPathAddLineToPoint(path, nil, *p) }
          new_sprite_toy.physicsBody = SKPhysicsBody.bodyWithPolygonFromPath(path)
        end

      elsif part.is_a? CirclePart
        wheel = new_toy.add_wheels_in_scene(self)[0]
        new_sprite_toy.hidden = false

        new_sprite_toy.position = view.convertPoint(new_toy.position, toScene: self)
        body = SKPhysicsBody.bodyWithCircleOfRadius(wheel.radius)
        new_sprite_toy.physicsBody = body
      end

      # new_sprite_toy.physicsBody.velocity = toy.physicsBody.velocity

      new_sprite_toy.name = new_name
      # addChild(new_sprite_toy)

      # new_sprite_toy.physicsBody.send(:apply_force, CGPointMake(force/displacement.x , force/displacement.y))
      @toy_hash[new_name] << new_sprite_toy
      # fadeOut = SKAction.fadeOutWithDuration(5.0)
      # remove = SKAction.removeFromParent()
      # seq = SKAction.sequence([fadeOut, remove])
      # new_sprite_toy.runAction(seq)
    end
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

end