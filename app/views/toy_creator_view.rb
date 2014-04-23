class ToyCreatorView < CreatorView

  def initWithFrame(frame)
    super
    @line_size = ToyTemplate::TOY_LINE_SIZE
    @current_tool = :squiggle
    self.backgroundColor = UIColor.colorWithRed(0.8, green: 0.8, blue: 0.85, alpha: 1.0)
    self
  end

  # Transfers the required toy information for the physics world
  # and also produces the toy image.
  # The points are a fraction of the size of the original drawing (as is the image).
  def gather_toy_info
    return nil if @strokes.size == 0
    # get the info
    left, right, top, bottom = extreme_points #.map { |value| value / 2.0 }
    #p [left, right, top, bottom]
    width = (right - left)/2 + @line_size
    height = (bottom - top)/2 + @line_size
    @centre_in_view = CGPointMake((left + right)/2, (top + bottom)/2)
    # now make all points in all parts relative to the centre, the centre becomes the origin
    parts = []
    @strokes.each do |stroke|
      position = stroke.position - @centre_in_view
      colour = stroke.colour
      case stroke
        when CircleStroke
          radius = stroke.radius * ToyTemplate::IMAGE_SCALE
          #radius = (radius*ToyTemplate::ACCURACY).to_i / ToyTemplate::ACCURACY
          part = CirclePart.new(position * ToyTemplate::IMAGE_SCALE, radius, colour)
        #puts part
        when LineStroke
          points = stroke.points.map { |p| (p + position) * ToyTemplate::IMAGE_SCALE }
          #points.each { |p| puts "(#{p.x}, #{p.y})" }
          part = PointsPart.new(points, colour) # position/ToyTemplate::IMAGE_SCALE, .map { |p| p/ToyTemplate::IMAGE_SCALE },
      end
      parts << part
    end
    ## get random identifier
    #id = rand(2**63)
    #ToyTemplate.new(parts, id) #, image)
    parts
    # save the ToyTemplate
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

  def draw_convex_hull(path)
    context = UIGraphicsGetCurrentContext()
    UIColor.redColor.set
    CGContextSetLineWidth(context, 1)
    first = true
    hold_first = nil
    path.each do |point|
      point = point * 4 + @centre_in_view
      #puts "x: #{point.x}, y: #{point.y}"
      if first
        hold_first = point
        first = false
        CGContextMoveToPoint(context, point.x, point.y)
      else
        CGContextAddLineToPoint(context, point.x, point.y)
      end
    end
    CGContextAddLineToPoint(context, hold_first.x, hold_first.y)
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

  def drawRect(rect)
    super
    toy_parts = gather_toy_info
    unless toy_parts.nil?
      toy = ToyPhysicsBody.new(toy_parts)
      if toy.points_in_paths > 0
        hull = toy.convex_hull
        draw_convex_hull(hull) if hull.length > 2
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

  def clear
    undoManager.registerUndoWithTarget(self, selector: 'unclear:', object: @strokes)
    @strokes = []
    @points = nil
    @selected = nil
    @truly_selected = nil
    setNeedsDisplay
  end

  def unclear(strokes)
    strokes.each do |stroke|
      add_stroke(stroke)
    end
  end

end