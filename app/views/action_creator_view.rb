## The view where actions are applied to the toys.
#class ActionCreatorView < UIView
#
#  def initWithFrame(frame)
#    super
#    self.backgroundColor = SceneCreatorView::DEFAULT_SCENE_COLOUR
#    @selected = nil
#    @truly_selected = nil
#    rotation_recognizer = UIRotationGestureRecognizer.alloc.initWithTarget(self, action: 'rotate_selected:')
#    rotation_recognizer.delegate = self
#    addGestureRecognizer(rotation_recognizer)
#    pinch_recognizer = UIPinchGestureRecognizer.alloc.initWithTarget(self, action: 'zoom_selected:')
#    pinch_recognizer.delegate = self
#    addGestureRecognizer(pinch_recognizer)
#    self
#  end
#
#  def add_delegate(delegate)
#    @delegate = WeakRef.new(delegate) # so we don't get memory leaks
#  end
#
#  def state=(state)
#    @state = state
#    scene = @state.scenes[0] # only one scene at the moment
#    @toys_in_scene = scene.toys
#    @strokes = parts_from(scene.edges)
#  end
#
#  # Converts the edge parts to strokes and returns the list of strokes.
#  def parts_from(edges)
#    strokes = []
#    edges.each do |edge|
#      case edge
#        when CirclePart
#          stroke = CircleStroke.new(edge.position, edge.radius, edge.colour, ToyTemplate::TOY_LINE_SIZE * ToyTemplate::IMAGE_SCALE)
#        when PointsPart
#          stroke = LineStroke.new(edge.points, edge.colour, ToyTemplate::TOY_LINE_SIZE * ToyTemplate::IMAGE_SCALE)
#      end
#      strokes << stroke
#    end
#    strokes
#  end
#
#  def valid_touch_location?(point)
#    @valid_start_location = true
#    subviews.each do |view|
#      if CGRectContainsPoint(view.frame, point)
#        @valid_start_location = false
#        break
#      end
#    end
#    @valid_start_location
#  end
#
#  def touchesBegan(touches, withEvent: event)
#    touch = touches.anyObject
#    point = touch.locationInView(self)
#    return unless valid_touch_location?(point)
#    @current_point = point
#    # Check to see if the touch is near a toy
#    @truly_selected = close_toy(@current_point)
#    # Check to see if the touch is near a LineStroke
#    unless @truly_selected
#      @truly_selected = @strokes.reverse.detect { |stroke| stroke.close_to?(@current_point) }
#    end
#    if @truly_selected
#      @selected = @truly_selected
#      #@trash_button.enabled = true
#    end
#    setNeedsDisplay
#  end
#
#  # Returns a toy if it is near the point.
#  def close_toy(point)
#    @toys_in_scene.reverse.detect { |toy| toy.close_enough(point) }
#  end
#
#  def touchesEnded(touches, withEvent: event)
#    return unless @valid_start_location
#    if @truly_selected
#      change_position_of(@truly_selected, to: @truly_selected.position)
#      if @truly_selected.is_a?(ToyInScene)
#        @toys_in_scene.delete(@truly_selected)
#        @toys_in_scene << @truly_selected
#      else
#        #@strokes.move_to_top(@truly_selected)
#        @strokes.delete(@truly_selected)
#        @strokes << @truly_selected
#      end
#      @truly_selected = nil
#      setNeedsDisplay
#    end
#  end
#
#  def touchesCancelled(touches, withEvent: event)
#  end
#
#  # Needed to allow both the pinch and rotate gesture recognizers to both work (individually).
#  def gestureRecognizer(recognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer: other)
#    recognizer.is_a?(UIPinchGestureRecognizer) && other.is_a?(UIRotationGestureRecognizer)
#  end
#
#  # Rotates the selected screen object.
#  def rotate_selected(recognizer)
#    if @selected.is_a?(LineStroke) || @selected.is_a?(ToyInScene) # we don't rotate circles
#      case recognizer.state
#        when UIGestureRecognizerStateBegan
#          @starting_angle = @selected.angle
#        when UIGestureRecognizerStateChanged
#          @selected.angle = (recognizer.rotation + @starting_angle) % (Math::PI * 2)
#          setNeedsDisplay
#        when UIGestureRecognizerStateEnded
#          change_angle_on(@selected, to: @selected.angle)
#          @starting_angle = nil
#      end
#    end
#  end
#
#  # Zooms the selected toy.
#  def zoom_selected(recognizer)
#    if @selected.is_a?(ToyInScene) # we don't rotate circles
#      case recognizer.state
#        when UIGestureRecognizerStateBegan
#          @starting_zoom = @selected.zoom
#        when UIGestureRecognizerStateChanged
#          @selected.zoom = recognizer.scale * @starting_zoom
#          setNeedsDisplay
#        when UIGestureRecognizerStateEnded
#          change_zoom_on(@selected, to: @selected.zoom)
#          @starting_zoom = nil
#      end
#    end
#  end
#
#  # Use to provide undos of changing angles.
#  def change_angle_on(screen_object, to: angle)
#    old_angle = screen_object.old_angle
#    return if angle == old_angle
#    undoManager.prepareWithInvocationTarget(self).change_angle_on(screen_object, to: old_angle)
#    screen_object.change_angle(angle)
#    unredo
#  end
#
#  # Use to provide undos of zooming.
#  def change_zoom_on(toy, to: zoom)
#    old_zoom = toy.old_zoom
#    return if zoom == old_zoom
#    undoManager.prepareWithInvocationTarget(self).change_zoom_on(toy, to: old_zoom)
#    toy.change_zoom(zoom)
#    unredo
#    setNeedsDisplay
#  end
#
#  # Only draws the shadow if requested
#  def setup_context(context, shadow = false)
#    CGContextSetLineWidth(context, @line_size)
#    CGContextSetLineCap(context, KCGLineCapRound)
#    CGContextSetLineJoin(context, KCGLineJoinRound)
#    CGContextSetShadow(context, CGSizeMake(8, -5), 5) if shadow
#  end
#
#  def drawRect(rect)
#    #super
#    context = UIGraphicsGetCurrentContext()
#    # now draw the added toys
#    @toys_in_scene.each { |toy| toy.draw(context) if toy != @selected }
#    @strokes.each { |stroke| stroke.draw(context) if stroke != @selected }
#    if @selected
#      CGContextBeginTransparencyLayer(context, nil)
#      setup_context(context, true)
#      @selected.draw(context)
#      CGContextEndTransparencyLayer(context)
#    end
#  end
#
#end