class ToyCreatorView < CreatorView

  # Make toys View
  # Used for construction of toys

  def initWithFrame(frame)
    super
    @line_size = ToyTemplate::TOY_LINE_SIZE
    @current_tool = :squiggle
    self.backgroundColor = Constants::GRAY
    self
  end

  # Transfers the required toy information for the physics world
  # and also produces the toy image.
  # The points are a fraction of the size of the original drawing (as is the image).
  # Returns list of all parts orientated around center of drawing
  def gather_toy_info
    return nil if @strokes.size == 0

    # get the info
    left, right, top, bottom = extreme_points #.map { |value| value / 2.0 }
    @centre_in_view = CGPointMake((left + right)/2, (top + bottom)/2)

    # now make all points in all parts relative to the centre, the centre becomes the origin
    parts = []
    @strokes.each do |stroke|
      position = stroke.position - @centre_in_view
      colour = stroke.colour
      case stroke
        when CircleStroke
          radius = stroke.radius * ToyTemplate::IMAGE_SCALE
          part = CirclePart.new(position * ToyTemplate::IMAGE_SCALE, radius, colour)
        when LineStroke
          points = stroke.points.map { |p| (p + position) * ToyTemplate::IMAGE_SCALE }
          part = PointsPart.new(points, colour)
      end
      parts << part
    end
    parts
  end

  # Traverses the parts and determines the extreme values.
  def extreme_points
    stroke = @strokes[0]
    left, right, top, bottom = stroke.extremes
    @strokes[1..-1].each do |stroke|
      l, r, t, b = stroke.extremes
      left = l if l < left
      right = r if r > right
      top = t if t < top
      bottom = b if b > bottom
    end
    [left, right, top, bottom]
  end

  # Draws what will be the hull in SpriteKit
  # Used in DEBUG mode
  def draw_convex_hull(path)
    context = UIGraphicsGetCurrentContext()
    UIColor.redColor.set
    #CGContextSetStrokeColorWithColor(UIColor.yellowColor)
    CGContextSetLineWidth(context, 2)
    first = true
    hold_first = nil
    path.each do |point|

      CGContextSetLineWidth(context, 2)

      point = point * 4 + @centre_in_view
      #puts "x: #{point.x}, y: #{point.y}"
      if first
        hold_first = point
        first = false
        CGContextMoveToPoint(context, point.x, point.y)
      else
        CGContextAddLineToPoint(context, point.x, point.y)
        CGContextAddEllipseInRect(context, CGRectMake(point.x-5, point.y-5, 10, 10))
        CGContextAddLineToPoint(context, point.x, point.y)
      end
    end
    CGContextAddLineToPoint(context, hold_first.x, hold_first.y)
    CGContextAddEllipseInRect(context, CGRectMake(hold_first.x-5, hold_first.y-5, 10, 10))

    CGContextStrokePath(context)
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

  # Initial Call to draw non-iOS UI elements
  def drawRect(rect)
    super
    toy_parts = gather_toy_info
    unless toy_parts.nil?
      toy = ToyPhysicsBody.new(toy_parts)
      if toy.points_in_paths > 0
        if Constants::DEBUG
          hull = toy.convex_hull
          #Only in debug!!
          draw_convex_hull(hull) if hull.length > 2
        end
      end
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

  # Removes all lines from screen
  def clear
    if undoManager != nil
      undoManager.registerUndoWithTarget(self, selector: 'unclear:', object: @strokes)
    end
    @strokes = []
    @points = nil
    @selected = nil
    @truly_selected = nil
    setNeedsDisplay
  end

  # Used for undo clear
  def unclear(strokes)
    strokes.each do |stroke|
      add_stroke(stroke)
    end
  end

end