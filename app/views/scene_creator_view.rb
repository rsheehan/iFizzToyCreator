class SceneCreatorView < CreatorView
# This now does double duty - to create scenes and to add actions.
# These have different capabilities - when adding actions there are fewer allowed modifications.
# The @mode determines the characteristics.

# TODO: add a true background mode which is blurred to indicate no physics

# @truly_selected is a stroke/toy which is currently being touched by the user
# @selected is a stroke/toy which was touched and is now hilighted
# @secondary_selected is used for create_new_toy file positioning the toy
# @alpha_view is used to set the alpha for everything but @selected and @secondary_selected

  attr_writer :selected, :secondary_selected, :show_action_controller
  attr_reader :actions, :delegate
  attr_accessor :alpha_view

  #DEFAULT_SCENE_COLOUR = UIColor.colorWithRed(0.5, green: 0.5, blue: 0.9, alpha: 1.0)
  DEFAULT_SCENE_COLOUR = Constants::BACKGROUND_COLOUR_LIST[0]
      THRESHOLD = 50
  NUM_SEGMENTS = 10
  MAX_DIAGONAL_DRAG = 660


  # MODES for standard views :scene, (:toys_only, :toy_selected {Only ACTION ADDER modes})
  # MODES for action/effects :force, :explosion, :rotation, :create_new_toy

  def initWithFrame(frame)
    super
    self.mode = :scene
    @line_size = ToyTemplate::TOY_LINE_SIZE * ToyTemplate::IMAGE_SCALE
    @current_tool = :grab # was :line
    @toys_in_scene = []
    @actions = []
    @boundaries = [1,1,1,1]
    @gravity = CGVectorMake(0, 0)
    self.backgroundColor = Constants::BACKGROUND_COLOUR_LIST[rand(100)%Constants::BACKGROUND_COLOUR_LIST.size]
    pinch_recognizer = UIPinchGestureRecognizer.alloc.initWithTarget(self, action: 'zoom_selected:')
    pinch_recognizer.delegate = self
    addGestureRecognizer(pinch_recognizer)
    @alpha_view = 1.0

    @gravityLabel = UILabel.alloc.initWithFrame(CGRectMake(0, 0, 800, 50))
    @gravityLabel.setTextAlignment(UITextAlignmentRight)
    @gravityLabel.text = ""
    self.addSubview(@gravityLabel)

    self
  end

  #set gravity from the config
  def setGravity(gravity)
    @gravity.dy = gravity
  end

  def setWind(wind)
    @gravity.dx = wind
  end

  #set boundaries from the config
  def setBoundaries(boundaries)
    @boundaries = boundaries
  end

  #set background image from the config popup
  def setBackground(backgroundImage)
    if backgroundImage != nil
      @backgroundImage = backgroundImage
      self.backgroundColor = UIColor.colorWithPatternImage(@backgroundImage)
    else
      @backgroundImage = nil
      self.backgroundColor = DEFAULT_SCENE_COLOUR
    end
  end

  # The different modes this view can represent.
  # scene - the scene construction mode
  # toys_only - toys can be selected, moved, resized but not strokes
  # toy_selected - a toy in toys_only mode has been selected
  # force - a force arrow can be shown for the selected toy (nothing movable)
  def mode=(mode)
    case mode
      when :scene
      when :toys_only
        @current_tool = :grab
        if @selected.is_a?(ToyInScene)
          mode = :toy_selected
        else
          @selected = nil
        end
        #@truly_selected = @selected = nil
        @delegate.selected_toy = @selected
        # if @delegate.is_a?(ActionAdderViewController)
        #   @delegate.start_action_flow
        # end
        setNeedsDisplay
      when :toy_selected
        @delegate.selected_toy = @selected
        if @mode.nil?
          @delegate.start_action_flow
        end
      else
        @current_point = nil
    end

    @mode = mode
  end

  # Changes name for label located at top of the screen
  def change_label_text_to(name)
    @label.text = name
  end

  # Add an action to this scene.
  def add_action(action)
    if !@actions.include?(action)
      @actions << action
      @actions.flatten!
    end
  end

  # Similar to gathering the toy info in ToyCreatorView but the scale is 1.
  def gather_scene_info
    id = rand(2**60).to_s
    SceneTemplate.new(@toys_in_scene, edges, @actions, id, self.bounds, @gravity, @boundaries, @backgroundImage)
  end

  # Turns the strokes making up the edges (including circles) into Parts.
  # And returns the list of parts.
  def edges
    temp = []
    @strokes.each do |stroke|
      position = stroke.position
      colour = stroke.colour
      case stroke
        when CircleStroke
          radius = stroke.radius
          part = CirclePart.new(position, radius, colour)
        when LineStroke
          points = stroke.points.map { |p| p + position }
          part = PointsPart.new(points, colour)
      end
      temp << part
    end
    temp
  end

  # Inserts toys to scene from scene loading or drop from toy box
  def add_toy(toy)
    undoManager.registerUndoWithTarget(self, selector: 'remove_toy:', object: toy)
    @toys_in_scene << toy
    unredo
    @selected = toy
    @trash_button.enabled = true
    setNeedsDisplay
  end

  # Removes toys from scene
  def remove_toy(toy)
    undoManager.registerUndoWithTarget(self, selector: 'add_toy:', object: toy)
    @toys_in_scene.delete(toy)
    unredo
    @selected = nil #@current_tool == :grab ? @strokes.most_recent : nil
    @trash_button.enabled = false
    setNeedsDisplay
  end

  # Deletes the selected stroke or toy.
  def remove_selected
    case @selected
      when Stroke
        remove_stroke(@selected)
      when ToyInScene
        remove_toy(@selected)
    end
  end

  # So we can start lines from off the edge of the view.
  def touch_began_from_edge(point)
    case @current_tool
      when :squiggle, :line
        @current_point = point
        @points = [@current_point]
        setNeedsDisplay
    end
  end

  # touches, NSSet of UITouch Events
  # Called when clicked on view
  def touchesBegan(touches, withEvent: event)

    #Get Touch coordinates
    touch = touches.anyObject
    point = touch.locationInView(self)

    #Check for Validity
    return unless valid_touch_location?(point)

    # Act Dependent on mode
    @current_point = point
    case @current_tool
      when :squiggle, :line, :circle
        @points = [@current_point]

      when :grab
        case @mode
          when :toys_only, :toy_selected
            touch_begin_toys_only
          when :scene
            touch_begin_scene
          when :create_new_toy
            if @selected.close_enough(@current_point)
              @drag = true
            end
        end
    end
    setNeedsDisplay
  end

  # A touch in scene mode
  def touch_begin_scene
    # Check to see if the touch is near a toy
    @truly_selected = close_toy(@current_point)

    # Check to see if the touch is near a LineStroke
    unless @truly_selected
      @truly_selected = @strokes.reverse.detect { |stroke| stroke.close_to?(@current_point) }
    end
    if @truly_selected
      @selected = @truly_selected
      @trash_button.enabled = true
    end
  end

  # A touch in toys only mode - (used for action adder)
  def touch_begin_toys_only
    @truly_selected = close_toy(@current_point)
    if @truly_selected
      @selected = @truly_selected
      self.mode = :toy_selected
    else
      self.mode = :toys_only
    end
  end

  # So we can start lines from off the edge of the view.
  def touch_moved_from_edge(point)
    case @current_tool
      when :squiggle
        a = @points[-1]
        b = point
        if (b - a).magnitude > 10.0
          @points << point
          setNeedsDisplay
        end
      when :line
        @points[1] = point
        setNeedsDisplay
    end
  end

  # Touch point moved on view without releasing
  def touchesMoved(touches, withEvent: event)
    return unless @valid_start_location
    touch = touches.anyObject
    point = touch.locationInView(self)
    case @current_tool
      when :squiggle
        a = @points[-1]
        b = point
        if (b - a).magnitude > Constants::MAGNITUDE_DISTANCE_BETWEEN_POINTS
          @points << point
          setNeedsDisplay
        end
      when :grab
        case @mode
          when :toys_only, :scene, :toy_selected
            if @delegate.is_a?(ActionAdderViewController)
              @drag = true
              @delegate.close_popover
            end
            touch_move_scene(point)
          else
            @current_point = point
        end
        setNeedsDisplay
      when :line, :circle
        @points[1] = point
        setNeedsDisplay
    end
  end

  # Called when moving an object either toy or stroke.
  def touch_move_scene(point)
    if @truly_selected
      @truly_selected.move(point - @current_point)
      @current_point = point
    end
  end

  # Returns a toy if it is near the point.
  def close_toy(point)
    @toys_in_scene.reverse.detect { |toy| toy.close_enough(point) }
  end

  # So we can start lines from off the edge of the view.
  def touch_ended_from_edge
    case @current_tool
      when :squiggle, :line
        # should only do this if at least one of the points is on the screen
        # it is possible that they are all "invisible"
        invisible = true
        @points.each do |point|
          invisible = false if point.x > 0 and point.x < bounds.size.width
        end
        add_stroke(LineStroke.new(@points, @current_colour, @line_size)) unless invisible
        @points = nil
        setNeedsDisplay
    end
  end

  # Touch lifted off view
  def touchesEnded(touches, withEvent: event)

    # Get point on view
    touch = touches.anyObject
    point = touch.locationInView(self)

    #Ensures valid location
    return unless @valid_start_location


    case @current_tool
      # Adds line to background
      # Adds line to background
      when :squiggle

        # To reduce the points making the scene
        while @points.size > Constants::MAX_CONTROLLED_POINTS_FOR_A_CURVE
          @points = removeHalfPoints(@points)
        end

        # Do B-spline curve here
        # Make sure that curve start at first point and more than 5 points available
        @points.unshift(@points.at(0))
        @points.unshift(@points.at(0))
        @points << @points.at(@points.size - 1)
        @points << @points.at(@points.size - 1)

        newPoints = []
        smallStep = 5
        # Define B-spline curve
        (2...@points.size-1).each do |i|
          (1..smallStep).each do |j|
            qPoint = p_spline(i, 1.0*j/smallStep)
            newPoints << CGPoint.new(qPoint.at(0), qPoint.at(1))
          end
        end
        @points = newPoints
        add_stroke(LineStroke.new(@points, @current_colour, @line_size))
        @points = nil
        setNeedsDisplay

      when :line
        add_stroke(LineStroke.new(@points, @current_colour, @line_size))
        @points = nil
        setNeedsDisplay

      when :grab
        case @mode
          when :toys_only, :scene
            touch_end_scene
            if @delegate.is_a?(ActionAdderViewController) and not @drag and @selected and @selected.close_enough(point)
              @delegate.reopen_action_flow
            end
            @drag = false
          when :force
            touch_end_force
          when :rotation
            touch_end_rotation
          when :explosion
            touch_end_explosion
          when :collision
            touch_end_collision
          when :create_new_toy
            @drag = false
          when :toy_selected
            if @delegate.is_a?(ActionAdderViewController) and not @drag
              if @selected.close_enough(point)
                p "***** other touch open: #{@current_tool} and #{@mode}"
                  @delegate.start_action_flow
              else
                p "***** other touch close: #{@current_tool} and #{@mode}"
                @delegate.close_popover
                @delegate.moveToSceneBar
              end
            end
            @drag = false
        end
      # Adds circle to background
      when :circle
        centre = @points[0]
        edge = @points.size < 2 ? centre : @points[1]
        radius = (edge - centre).magnitude
        add_stroke(CircleStroke.new(centre, radius, @current_colour, @line_size))
        @points = nil
        setNeedsDisplay
    end

    #p "***** other touch: #{@current_tool} and #{@mode}"
  end

  # Called when the touch ends for a scene.
  def touch_end_scene
    
    if @truly_selected
      justSelectedAToy = @truly_selected.old_position == @truly_selected.position
      change_position_of(@truly_selected, to: @truly_selected.position)
      if @truly_selected.is_a?(ToyInScene)
        @toys_in_scene.delete(@truly_selected)
        @toys_in_scene << @truly_selected
        #p "touch toy"
      else
        justSelectedAToy = false
        @strokes.delete(@truly_selected)
        @strokes << @truly_selected
        #p "touch scene"
      end
      @truly_selected = nil
      setNeedsDisplay
    else
      #p "other touch"
    end

    #p "Just selected = #{justSelectedAToy}"
    if justSelectedAToy      
      delegate.moveToActionBar
    end
  end

  # Called when the touch ends for a force drag.
  def touch_end_force
    vector = @current_point - @selected.position
    radians = @selected.angle * Math::PI / 180
    ratio = Math.cos(radians)
    vector = vector * ratio
    vector.y = -vector.y  # convert to SpriteKit coordinates
    @delegate.force = vector
    @delegate.close_modal_view
  end

  # Returns explosion strength to delegate
  def touch_end_explosion
    vector = @current_point - @selected.position
    magnitude = Math.sqrt(vector.x**2 + vector.y**2)
    @delegate.explosion = magnitude
    @delegate.close_modal_view
  end

  # Returns Rotation strength to delegate
  def touch_end_rotation
    vector = @current_point - @selected.position
    radians = (Math::PI - (Math.atan2(vector.y,vector.x)*-1))

    radians = round_radians(radians)

    if radians > Math::PI
      radians = (Math::PI*2 - radians)
    else
      radians *= -1
    end
    
    @delegate.rotation = radians
    @delegate.close_modal_view
  end

  # [ID, Displacement.x, displacement.y, zoom, angle]
  # When create toy
  def end_create_toy (random = false)
    results = {}
    results[:id] = @selected.template.identifier
    disp = @secondary_selected.position - @selected.position

    newToy = ToyInScene.new(@selected.template, 1.0, true)
    newToy.position = @selected.position

    # to handle randomly created toy
    if random
      results[:x] = Constants::RANDOM_HASH_KEY
      results[:y] = Constants::RANDOM_HASH_KEY
      puts "* new toy is create randomly at (#{results[:x]},#{results[:y]})"
    else
      results[:x] = disp.x
      results[:y] = disp.y
    end

    results[:zoom] = @selected.zoom
    results[:angle] = @selected.angle
    @selected = @secondary_selected

    @secondary_selected = nil

    @delegate.selected_toy = @selected
    @delegate.create_new_toy = results
    @delegate.close_modal_view


    add_toy(newToy)

  end

  # Called when the touch ends for a collision toy selection.
  def touch_end_collision
    if @secondary_selected
      @delegate.colliding_toy = @secondary_selected
    end
  end

  # Required
  def touchesCancelled(touches, withEvent: event)
  end

  # Needed to allow both the pinch and rotate gesture recognizers to both work (individually).
  def gestureRecognizer(recognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer: other)
    recognizer.is_a?(UIPinchGestureRecognizer) && other.is_a?(UIRotationGestureRecognizer)
  end

  # Zooms the selected toy.
  def zoom_selected(recognizer)
    if @selected.is_a?(ToyInScene) # we don't rotate circles
      case recognizer.state
        when UIGestureRecognizerStateBegan
          @starting_zoom = @selected.zoom
        when UIGestureRecognizerStateChanged
          @selected.zoom = recognizer.scale * @starting_zoom
          setNeedsDisplay
        when UIGestureRecognizerStateEnded
          change_zoom_on(@selected, to: @selected.zoom)
          @starting_zoom = nil
      end
    end
  end

  # Use to provide undos of zooming.
  def change_zoom_on(toy, to: zoom)
    old_zoom = toy.old_zoom
    return if zoom == old_zoom
    undoManager.prepareWithInvocationTarget(self).change_zoom_on(toy, to: old_zoom)
    toy.change_zoom(zoom)
    unredo
    setNeedsDisplay
  end

  # Draws arrow for force size of "Force" effect
  def draw_force_arrow(context, start, finish)
    arrow_size = 50

    # Get vector
    dx = finish.x - start.x
    dy = finish.y - start.y

    combined = dx.abs + dy.abs
    length = Math.hypot(dx, dy)
    if length < arrow_size
      length = arrow_size
      dx = length * (dx/combined)
      dy = length * (dy/combined)
    end

    # Creates points for arrow
    arrow_points = []
    arrow_points << CGPointMake(0, -5) << CGPointMake(length - arrow_size, -5) << CGPointMake(length - arrow_size, -40)
    arrow_points << CGPointMake(length, 0)
    arrow_points << CGPointMake(length - arrow_size, 40) << CGPointMake(length - arrow_size, 5) << CGPointMake(0, 5)

    cosine = dx / length
    sine = dy / length

    arrow_transform_pointer = Pointer.new(CGAffineTransform.type)
    arrow_transform_pointer[0] = CGAffineTransform.new(cosine, sine, -sine, cosine, start.x, start.y)

    path = CGPathCreateMutable()
    CGPathMoveToPoint(path, arrow_transform_pointer, 0, 0)
    arrow_points.each do |point|
      CGPathAddLineToPoint(path, arrow_transform_pointer, point.x, point.y)
    end
    CGContextAddPath(context, path)
    CGContextSetFillColorWithColor(context, UIColor.redColor.CGColor)
    CGContextDrawPath(context, KCGPathFill)
  end

  # Circle used for explosion effect
  def draw_force_circle(context, center, radius)
    rectangle = CGRectMake(center.x - radius, center.y - radius, radius*2, radius*2)
    CGContextSetStrokeColorWithColor(context,UIColor.redColor.CGColor)
    CGContextSetLineWidth(context, 5)
    CGContextAddEllipseInRect(context, rectangle)
    CGContextStrokePath(context)
  end

  # Rotation arrow used for rotation effect
  def draw_rotate_circle(context, center, point)
    radius = 200

    #get Vector
    dpoint = point - center

    # Find angle
    radians = (Math::PI - (Math.atan2(dpoint.y,dpoint.x)*-1))

    clockwise = true

    # Round to sections
    radians = round_radians(radians)

    CGContextSetStrokeColorWithColor(context,UIColor.redColor.CGColor)
    if(radians > 0 and radians < Math::PI)
      CGContextAddArc(context, center.x, center.y, radius, Math::PI, radians+Math::PI, 0)
    else
      CGContextAddArc(context, center.x, center.y, radius, Math::PI, radians+Math::PI, 1)
      clockwise = false
    end
    CGContextSetLineWidth(context, 10)
    CGContextStrokePath(context)

    draw_rotate_circle_arrow(context, center, radius, radians-Math::PI, clockwise)
  end

  # Draw end arrow for circle
  def draw_rotate_circle_arrow(context,center, length, angle, clockwise)

    arrow_points = []
    if not clockwise
      arrow_points << CGPointMake(- 40, 0) << CGPointMake(0, -50)
      arrow_points << CGPointMake(40, 0)
    else
      arrow_points << CGPointMake(- 40, 0) << CGPointMake(0, 50)
      arrow_points << CGPointMake(40, 0)
    end

    arrow_transform_pointer = Pointer.new(CGAffineTransform.type)
    arrow_transform_pointer[0] = CGAffineTransformMakeTranslation( center.x, center.y)
    arrow_transform_pointer[0] = CGAffineTransformRotate(arrow_transform_pointer[0], angle)
    arrow_transform_pointer[0] = CGAffineTransformTranslate(arrow_transform_pointer[0],length, 0)

    path = CGPathCreateMutable()
    CGPathMoveToPoint(path, arrow_transform_pointer, length, 0)

    arrow_points.each do |point|
      CGPathAddLineToPoint(path, arrow_transform_pointer, point.x, point.y)
    end
    CGContextAddPath(context, path)
    CGContextSetFillColorWithColor(context, UIColor.redColor.CGColor)
    CGContextDrawPath(context, KCGPathFill)
  end

  # Visual Display of rotation before user interaction
  def draw_static_rotate_circle(context, center)
    radius = 200
    upper_angle = Math::PI + Math::PI/8
    lower_angle = Math::PI - Math::PI/8

    CGContextSetStrokeColorWithColor(context,UIColor.redColor.CGColor)
    CGContextAddArc(context, center.x, center.y, radius, lower_angle, upper_angle, 0)
    CGContextSetLineWidth(context, 10)
    CGContextStrokePath(context)

    draw_rotate_circle_arrow(context, center, radius, upper_angle, true)
    draw_rotate_circle_arrow(context, center, radius, lower_angle, false)

  end

  # Draws non-iOS UI Elements
  def drawRect(rect)
    context = UIGraphicsGetCurrentContext()

    # Change Alpha of background if it hasnt been set
    if @alpha_view
      CGContextSetAlpha(context, @alpha_view)
    end

    # now draw the added toys
    CGContextBeginTransparencyLayer(context, nil)
    @toys_in_scene.each { |toy| toy.draw(context) if toy != @selected }
    # Drawing Edges
    @strokes.each { |stroke| stroke.draw(context) if stroke != @selected }
    CGContextEndTransparencyLayer(context)

    # Restores Alpha
    if @alpha_view
      CGContextSetAlpha(context, 1.0)
    end

    if @secondary_selected
      CGContextBeginTransparencyLayer(context, nil)
      setup_context(context, true)
      @secondary_selected.draw(context)
      CGContextEndTransparencyLayer(context)
    end

    # Draws what is selected on top
    if @selected
      CGContextBeginTransparencyLayer(context, nil)
      setup_context(context, true)
      @selected.draw(context)
      CGContextEndTransparencyLayer(context)
    end

    # Item currently being drawn
    if @points
      CGContextBeginTransparencyLayer(context, nil)
      setup_context(context)
      draw_partial_thing(context)
      CGContextEndTransparencyLayer(context)
    end

    # If an effect needs a visual representation when applying, perform that here
    case @mode

      # Displays an arrow from selected to touched position
      when :force
        if @current_point && @selected
          @current_point = round_coordinates(@current_point, @selected.position)
          @current_point = snap_to_45(@current_point, @selected.position)
          draw_force_arrow(context, @selected.position, @current_point)
        end

      # Explosion size with radius between selected and finger
      when :explosion
        if @current_point && @selected
          @current_point = round_coordinates(@current_point, @selected.position)
          #draw_force_arrow(context, @selected.position, @current_point)
          length = Math.hypot(@selected.position.x - @current_point.x, @selected.position.y - @current_point.y)
          draw_force_circle(context, @selected.position, length)
        end

      # Rotation starting from left side, top implies clockwise, bottom anti-clockwise
      when :rotation
        if @current_point && @selected
           draw_rotate_circle(context, @selected.position, @current_point)
        else
          draw_static_rotate_circle(context, @selected.position)
        end

      when :create_new_toy
        if @current_point and @drag
          @selected.position = @current_point
        end
    end
  end

  # If close enough, locks vector to a 45 degree, otherwise leaves it alone
  def snap_to_45(point, selected_point)
    delta = point - selected_point
    magnitude = Math.hypot(*delta)
    angle = Math.atan2(delta.y, delta.x)
    angle /= (Math::PI/4)
    angle = angle.round(0)
    angle *= (Math::PI/4)
    x = magnitude * Math.cos(angle)
    y = magnitude * Math.sin(angle)
    new_point = CGPointMake(x, y)
    new_point = new_point + selected_point
    change_mag = Math.hypot(*(new_point-point))
    if change_mag > THRESHOLD
      return point
    end
    new_point
  end

  # Rounds the magnitude of the vector to nearest segment
  def round_coordinates(point, selected_point)
    displacement = point - selected_point
    length =  Math.hypot(*displacement)
    angle = Math.atan2(displacement.y, displacement.x)
    puts "Length: " + length.to_s

    length = (length/(MAX_DIAGONAL_DRAG/NUM_SEGMENTS)).round(0) * (MAX_DIAGONAL_DRAG/NUM_SEGMENTS)
    if length == 0
      length = (MAX_DIAGONAL_DRAG/NUM_SEGMENTS)
    end

    x = length * Math.cos(angle)
    y = length * Math.sin(angle)

    rounded_displacement = CGPointMake(x, y)
    rounded_point = rounded_displacement + selected_point
    rounded_point
  end

  # Rounds radians to nearest Segment
  def round_radians(rads)
    new_num = (rads/(Math::PI/NUM_SEGMENTS)).round(0)*(Math::PI/NUM_SEGMENTS)
    diff = (new_num - Math::PI).abs
    diff_2_pi =(new_num - Math::PI*2).abs
    if diff < 0.0001 and rads > Math::PI
      new_num = Math::PI + Math::PI/180
    elsif new_num == 0 or diff_2_pi < 0.0001
      if rads < 1
        new_num = (Math::PI/NUM_SEGMENTS)
      else
        new_num = Math::PI*2 - (Math::PI/NUM_SEGMENTS)
      end
    end
    #puts "PIE: " + Math::PI.to_s
    puts "Radians rounded: " + new_num.to_s
    new_num
  end

  # remove everything from screen without saving
  def clear
    undoManager.registerUndoWithTarget(self, selector: 'unclear:', object: [@toys_in_scene, @strokes])

    @strokes = []
    @toys_in_scene = []
    @actions = []
    @points = nil
    @selected = nil
    @truly_selected = nil
    setNeedsDisplay
  end

  # Have the ability to undo clear just in case
  def unclear(object)
    toys = object[0]
    toys.each do |toy|
      add_toy(toy)
    end
    strokes = object[1]
    strokes.each do |stroke|
      add_stroke(stroke)
    end
  end

end