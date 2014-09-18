# The super class of both the toy and scene creators.
# Another sort of abstract class.
class CreatorView < UIView
  # Multiple touches are disabled by default.
  # In order to receive multiple touch events you must set the multipleTouchEnabled property of
  # the corresponding view instance to YES (true).

  attr_writer :trash_button, :label

  def initWithFrame(frame)
    super
    setup_for_new
    rotation_recognizer = UIRotationGestureRecognizer.alloc.initWithTarget(self, action: 'rotate_selected:')
    rotation_recognizer.delegate = self
    addGestureRecognizer(rotation_recognizer)
    self
  end

  def setup_for_new
    @strokes = []
    @points = nil
    @selected = nil
    @truly_selected = nil
    reset_undo if undoManager # has the undoManager been set up yet?
    setNeedsDisplay
  end

  def add_delegate(delegate)
    @delegate = WeakRef.new(delegate) # so we don't get memory leaks
  end

  def current_colour=(colour)
    @current_colour = colour
    change_colour_of(@selected, to: colour) if @selected.is_a?(Stroke)
    setNeedsDisplay
  end

  def current_tool=(tool)
    @current_tool = tool
    @selected = nil #tool == :grab ? @strokes.most_recent : nil
    @trash_button.enabled = false
    setNeedsDisplay
  end

  def valid_touch_location?(point)
    @valid_start_location = true
    #if [:squiggle, :line].include?(@current_tool)
    #  puts "was valid touch"
    #  return @valid_start_location
    #end
    subviews.each do |view|
      if CGRectContainsPoint(view.frame, point)
        @valid_start_location = false
        break
      end
    end
    @valid_start_location
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
        # Check to see if the touch is near a LineStroke
        @truly_selected = @strokes.reverse.detect { |stroke| stroke.close_to?(@current_point) }
        # @strokes.stroke_close_to(@current_point)
        if @truly_selected
          @selected = @truly_selected
          @trash_button.enabled = true
        end
    end
    setNeedsDisplay
  end

  def touchesMoved(touches, withEvent: event)
    return unless @valid_start_location
    touch = touches.anyObject
    point = touch.locationInView(self)
    case @current_tool
      when :squiggle
        a = @points[-1]
        b = point
        if (b - a).magnitude > 20.0
          @points << point
          setNeedsDisplay
        end
      when :grab
        if @truly_selected
          @truly_selected.move(point - @current_point)
          @current_point = point
          setNeedsDisplay
        end
      when :line, :circle
        @points[1] = point
        setNeedsDisplay
    end
  end

  def touchesEnded(touches, withEvent: event)
    return unless @valid_start_location
    case @current_tool
      when :squiggle
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
        #@current_colour = @current_colour.colorWithAlphaComponent(rand(1000)/1000.0)
        add_stroke(LineStroke.new(@points, @current_colour, @line_size))
        @points = nil
        setNeedsDisplay

      when :line
        add_stroke(LineStroke.new(@points, @current_colour, @line_size))
        @points = nil
        setNeedsDisplay

      when :grab
        if @truly_selected
          change_position_of(@truly_selected, to: @truly_selected.position)
          #@strokes.move_to_top(@truly_selected)
          @strokes.delete(@truly_selected)
          @strokes << @truly_selected
          @truly_selected = nil
          setNeedsDisplay
        end
      when :circle
        centre = @points[0] #Vector.from_pt(@points[0])
        edge = @points.size < 2 ? centre : @points[1] #Vector.from_pt(@points[1])
        radius = (edge - centre).magnitude
        add_stroke(CircleStroke.new(centre, radius, @current_colour, @line_size))
        @points = nil
        setNeedsDisplay
    end
  end

  def touchesCancelled(touches, withEvent: event)
  end

  def reset_undo
    undoManager.removeAllActions unless undoManager.nil?
    if @delegate
      @delegate.can_undo(false)
      @delegate.can_redo(false)
    end
  end

  def undo
    undoManager.undo
    unredo
    @selected = nil # don't want objects showing shadows incorrectly
    @trash_button.enabled = false
    setNeedsDisplay
  end

  def unredo
    @delegate.can_undo(undoManager.canUndo)
    @delegate.can_redo(undoManager.canRedo)
  end

  def redo
    undoManager.redo
    unredo
    @selected = nil # don't want objects showing shadows incorrectly
    @trash_button.enabled = false
    setNeedsDisplay
  end

  def add_stroke(stroke)
    undoManager.registerUndoWithTarget(self, selector: 'remove_stroke:', object: stroke)
    #undoManager.setActionName('')
    @strokes << stroke
    unredo
  end

  def remove_stroke(stroke)
    undoManager.registerUndoWithTarget(self, selector: 'add_stroke:', object: stroke)
    @strokes.delete(stroke)
    unredo
    @selected = nil #= @current_tool == :grab ? @strokes.most_recent : nil
    @trash_button.enabled = false
    setNeedsDisplay
  end

  # Deletes the selected stroke.
  def remove_selected
    if @selected
      remove_stroke(@selected)
      #@selected = nil
    end
  end

  # Rotates the selected screen object.
  def rotate_selected(recognizer)
    if @selected.is_a?(LineStroke) || @selected.is_a?(ToyInScene) # we don't rotate circles
      case recognizer.state
        when UIGestureRecognizerStateBegan
          @starting_angle = @selected.angle
        when UIGestureRecognizerStateChanged
          @selected.angle = (recognizer.rotation + @starting_angle) % (Math::PI * 2)
          setNeedsDisplay
        when UIGestureRecognizerStateEnded
          # add to the undo list
          #undoManager.registerUndoWithTarget(@selected, selector: 'angle=:', object: @starting_angle)
          change_angle_on(@selected, to: @selected.angle)
          #@delegate.can_undo(undoManager.canUndo)
          @starting_angle = nil
      end
    end
  end

  # Use to provide undos of changing angles.
  def change_angle_on(screen_object, to: angle)
    old_angle = screen_object.old_angle
    return if angle == old_angle
    undoManager.prepareWithInvocationTarget(self).change_angle_on(screen_object, to: old_angle)
    screen_object.change_angle(angle)
    unredo
  end

  # Used to provide undos of changing positions.
  def change_position_of(screen_object, to: position)
    old_position = screen_object.old_position
    return if position == old_position
    undoManager.prepareWithInvocationTarget(self).change_position_of(screen_object, to: old_position)
    screen_object.change_position(position)
    unredo
  end

  # Used to provide undos of changing colours.
  def change_colour_of(stroke, to: colour)
    old_colour = stroke.colour
    return if colour == old_colour
    undoManager.prepareWithInvocationTarget(self).change_colour_of(stroke, to: old_colour)
    #puts stroke.class
    stroke.change_colour(colour)
    unredo
  end

  # TODO: The scene creator version would use thinner lines.
  def draw_sole_point(context)
    sole_point = @points[-1]
    CGContextFillEllipseInRect(context, CGRectMake(sole_point.x - @line_size/2, sole_point.y - @line_size/2,
                                                   @line_size, @line_size))
  end

  def draw_path_of_points(context)
    first = true
    @points.each do |point|
      if first
        first = false
        CGContextMoveToPoint(context, point.x, point.y)
      else
        CGContextAddLineToPoint(context, point.x, point.y)
      end
    end
    CGContextStrokePath(context)
  end

  def draw_circle(context)
    centre = @points[0]
    edge = @points[1]
    radius = (edge - centre).magnitude
    CGContextFillEllipseInRect(context, CGRectMake(centre.x - radius - @line_size/2, centre.y - radius - @line_size/2,
                                                   radius*2 + @line_size, radius*2 + @line_size))
  end

  def draw_partial_thing(context)
    @current_colour.set
    if @points.length == 1
      draw_sole_point(context)
    else
      case @current_tool
        when :squiggle, :line
          draw_path_of_points(context)
        when :circle
          draw_circle(context)
      end
    end
  end

  # Only draws the shadow if requested
  def setup_context(context, shadow = false)
    CGContextSetLineWidth(context, @line_size)
    CGContextSetLineCap(context, KCGLineCapRound)
    CGContextSetLineJoin(context, KCGLineJoinRound)
    CGContextSetShadow(context, CGSizeMake(8, -5), 5) if shadow
  end

  def drawRect(rect)
    context = UIGraphicsGetCurrentContext()
    @strokes.each do |stroke|
      if stroke == @selected
        CGContextBeginTransparencyLayer(context, nil)
        setup_context(context, true)
        @selected.draw(context)
        CGContextEndTransparencyLayer(context)
      else
        stroke.draw(context) if stroke != @selected
      end
    end
    if @points
      CGContextBeginTransparencyLayer(context, nil)
      setup_context(context)
      draw_partial_thing(context)
      CGContextEndTransparencyLayer(context)
    end
  end

  def b_spline(i, t)
    case i
      when -2
        return (((-t+3)*t-3)*t+1)/6.0
      when -1
        return (((3*t-6)*t)*t+4)/6.0
      when 0
        return (((-3*t+3)*t+3)*t+1)/6.0
      when 1
        return (t*t*t)/6.0
      else
        return 0.0
    end
  end

  def p_spline(i, t)
    px = 0
    py = 0
    # go for -2 -1 0 1
    (-2..1).each do |j|
      #puts "bspline at (#{j}, #{t}) is #{b_spline(j, t)}"
      px = px + b_spline(j, t) * @points.at(i + j).x
      py = py + b_spline(j, t) * @points.at(i + j).y
    end
    #puts "x = #{px} and y = #{py}"
    return [px, py]
  end

end