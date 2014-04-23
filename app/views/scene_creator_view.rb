class SceneCreatorView < CreatorView
# This now does double duty - to create scenes and to add actions.
# These have different capabilities - when adding actions there are fewer allowed modifications.
# The @mode determines the characteristics.

# TODO: add a true background mode which is blurred to indicate no physics

# @truly_selected is a stroke/toy which is currently being touched by the user
# @selected is a stroke/toy which was touched and is now hilighted
  attr_writer :selected

  DEFAULT_SCENE_COLOUR = UIColor.colorWithRed(0.5, green: 0.5, blue: 0.9, alpha: 1.0)

  # MODES for interaction  :scene, :toys_only, :force, :none

  def initWithFrame(frame)
    super
    self.mode = :scene
    @line_size = ToyTemplate::TOY_LINE_SIZE * ToyTemplate::IMAGE_SCALE
    @current_tool = :grab # was :line
    @toys_in_scene = []
    @actions = []
    self.backgroundColor = DEFAULT_SCENE_COLOUR
    pinch_recognizer = UIPinchGestureRecognizer.alloc.initWithTarget(self, action: 'zoom_selected:')
    pinch_recognizer.delegate = self
    addGestureRecognizer(pinch_recognizer)
    self
  end

  # The different modes this view can represent.
  # scene - the scene construction mode
  # toys_only - toys can be selected, moved, resized but not strokes
  # toy_selected - a toy in toys_only mode has been selected
  # force - a force arrow can be shown for the selected toy (nothing movable)
  def mode=(mode)
    #puts @delegate
    #puts "current mode: #@mode - mode requested #{mode}"
    #puts @selected

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
        setNeedsDisplay
      when :toy_selected
        @delegate.selected_toy = @selected
      when :force
        @current_point = nil
      # @truly_selected has been set in ActionAdderViewController
      when :collision
        @current_tool = :grab
        @delegate.selected_toy = @selected
        setNeedsDisplay
    end

    @mode = mode
  end

  ## So we can keep convenient track of the label at the top of the view
  #def addSubview(label)
  #  super
  #  @label = label
  #end

  def change_label_text_to(name)
    @label.text = name
  end

  # Add an action to this scene.
  def add_action(action)
    @actions << action
  end

  # Similar to gathering the toy info in ToyCreatorView but the scale is 1.
  def gather_scene_info
    id = rand(2**60).to_s
    SceneTemplate.new(@toys_in_scene, edges, @actions, id)
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

  def add_toy(toy)
    undoManager.registerUndoWithTarget(self, selector: 'remove_toy:', object: toy)
    @toys_in_scene << toy
    unredo
    @selected = toy
    @trash_button.enabled = true
    setNeedsDisplay
  end

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

  def touchesBegan(touches, withEvent: event)
    touch = touches.anyObject
    point = touch.locationInView(self)
    return unless valid_touch_location?(point)
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
          when :force

          when :collision
            touch_begin_collision
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

  # A touch in toys only mode
  def touch_begin_toys_only
    @truly_selected = close_toy(@current_point)
    if @truly_selected
      @selected = @truly_selected
      self.mode = :toy_selected
    else
      self.mode = :toys_only
    end
  end

  # A touch in collision mode
  def touch_begin_collision
    @colliding_selected = close_toy(@current_point)
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

  def touchesMoved(touches, withEvent: event)
    return unless @valid_start_location
    touch = touches.anyObject
    point = touch.locationInView(self)
    case @current_tool
      when :squiggle
        a = @points[-1]
        b = point
        if (b - a).magnitude > 10.0
          @points << point
          setNeedsDisplay
        end
      when :grab
        case @mode
          when :toys_only, :scene, :toy_selected
            touch_move_scene(point)
          when :force
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

  def touchesEnded(touches, withEvent: event)
    return unless @valid_start_location
    case @current_tool
      when :squiggle, :line
        add_stroke(LineStroke.new(@points, @current_colour, @line_size))
        @points = nil
        setNeedsDisplay
      when :grab
        case @mode
          when :toys_only, :scene
            touch_end_scene
          when :force
            touch_end_force
          when :collision
            touch_end_collision
        end
      when :circle
        centre = @points[0]
        edge = @points.size < 2 ? centre : @points[1]
        radius = (edge - centre).magnitude
        add_stroke(CircleStroke.new(centre, radius, @current_colour, @line_size))
        @points = nil
        setNeedsDisplay
    end
  end

  # Called when the touch ends for a scene.
  def touch_end_scene
    if @truly_selected
      change_position_of(@truly_selected, to: @truly_selected.position)
      if @truly_selected.is_a?(ToyInScene)
        @toys_in_scene.delete(@truly_selected)
        @toys_in_scene << @truly_selected
      else
        @strokes.delete(@truly_selected)
        @strokes << @truly_selected
      end
      @truly_selected = nil
      setNeedsDisplay
    end
  end

  # Called when the touch ends for a force drag.
  def touch_end_force
    vector = @current_point - @selected.position
    vector.y = -vector.y  # convert to SpriteKit coordinates
    @delegate.force = vector
    @delegate.close_modal_view
  end

  # Called when the touch ends for a collision toy selection.
  def touch_end_collision
    if @colliding_selected
      @delegate.colliding_toy = @colliding_selected
      #@delegate.close_modal_view
    end
  end

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

  def draw_force_arrow(context, start, finish)
    #CGContextSetLineWidth(context, 10)
    length = Math.hypot(finish.x - start.x, finish.y - start.y)
    arrow_points = []
    arrow_points << CGPointMake(0, -5) << CGPointMake(length - 50, -5) << CGPointMake(length - 50, -40)
    arrow_points << CGPointMake(length, 0)
    arrow_points << CGPointMake(length - 50, 40) << CGPointMake(length - 50, 5) << CGPointMake(0, 5)

    cosine = (finish.x - start.x) / length
    sine = (finish.y - start.y) / length

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

  def drawRect(rect)
    #super
    context = UIGraphicsGetCurrentContext()
    # now draw the added toys
    @toys_in_scene.each { |toy| toy.draw(context) if toy != @selected }
    @strokes.each { |stroke| stroke.draw(context) if stroke != @selected }
    if @selected
      CGContextBeginTransparencyLayer(context, nil)
      setup_context(context, true)
      @selected.draw(context)
      CGContextEndTransparencyLayer(context)
    end
    if @points
      CGContextBeginTransparencyLayer(context, nil)
      setup_context(context)
      draw_partial_thing(context)
      CGContextEndTransparencyLayer(context)
    end
    if @mode == :force && @current_point && @selected
      draw_force_arrow(context, @selected.position, @current_point)

    end
  end

end