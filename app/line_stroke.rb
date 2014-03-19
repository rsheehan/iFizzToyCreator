# A LineStroke is a single image stroke of a Toy.
class LineStroke < Stroke
  #include Stroke

  CLOSE_DISTANCE = 20

  attr_accessor :angle # can be changed by the view when being rotated
  attr_reader :old_angle
  attr_reader :points

  def initialize(points, colour, line_size)
    @points = points #points.map { |pt| Vector.from_pt(pt) }
    @colour = colour
    @line_size = line_size
    @old_angle = @angle = 0.0
    make_points_relative
    @old_position = @position # I know this is inconsistent with the way I do the angle.
    @original_points = @points.dup
    generate_image
  end

  #def angle=(angle)
  #  @angle = angle
  #  # now have to recreate the point data?
  #  rotated_points
  #end

  # Called when a rotate in the UI is completed.
  def change_angle(angle)
    @old_angle = @angle = angle
    rotated_points
  end

  # Finds the centre point of the image and makes the points relative to this.
  def make_points_relative
    # find the bounding box
    first = @points[0]
    left, right, top, bottom = first.x, first.x, first.y, first.y
    @points[1..-1].each do |p|
      left = p.x if p.x < left
      right = p.x if p.x > right
      top = p.y if p.y > top
      bottom = p.y if p.y < bottom
    end

    centre_x = (left + right) / 2
    centre_y = (bottom + top) / 2
    @position = CGPoint.new(centre_x, centre_y) #Vector[centre_x, centre_y] # the centre point of the stroke

    # change points relative to the centre
    @points.map! { |point| point - @position } #CGPointMake(p.x - centre_x, p.y - centre_y) }

    # width and height for the image
    width = right - left + @line_size
    height = top - bottom + @line_size
    @image_size = CGPoint.new(width, height) #Vector[width, height]
  end

  # Takes the original points and rotates them to the new orientation.
  def rotated_points
    @original_points.each_with_index do |p, i|
      x = p.x * Math.cos(@angle) - p.y * Math.sin(@angle)
      y = p.x * Math.sin(@angle) + p.y * Math.cos(@angle)
      @points[i] = CGPoint.new(x, y) #Vector[x, y]
    end
  end

  ## Rotates the stroke about its centre by the given angle.
  #def rotate(angle)
  #  @angle = angle
  #end

  def minimum_distance(vpoint, p0, p1)
    v0 = p0 #Vector.from_pt(p0)
    v1 = p1 #Vector.from_pt(p1)
    segment_length = distance(v0, v1)
    length_squared = segment_length * segment_length
    if length_squared < 10.0 # not long
      return distance(v0, vpoint)
    end
    t = (vpoint - v0).inner_product(v1 - v0) / length_squared
    return distance(v0, vpoint) if t < 0
    return distance(v1, vpoint) if t > 1
    projection = v0 + ((v1 - v0) * t) # does the t need to be on the other side?
    distance(projection, vpoint)
  end

  def distance(v0, v1)
    (v1 - v0).magnitude
  end

  # Returns true iff the point is close to one of the edges.
  def close_to?(point)
    # change the point to this stroke's position
    check_point = point - @position #Vector.from_pt(point) - @position
    # if only one point check the distance
    if @points.length == 1
      return check_point.magnitude < CLOSE_DISTANCE
    else
      # else some line segments
      prev_pt = @points[0]
      @points[1..-1].each do |next_pt|
        return true if minimum_distance(check_point, prev_pt, next_pt) < CLOSE_DISTANCE
        prev_pt = next_pt
      end
    end
    false
  end

  # Returns the extreme position values in each of the four directions.
  def extremes
    point = @points[0]
    left = right = @position.x + point.x
    top = bottom = @position.y + point.y
    @points[1..-1].each do |point|
      x, y = (@position + point).to_a
      left = x if x < left
      right = x if x > right
      top = y if y < top
      bottom = y if y > bottom
    end
    [left, right, top, bottom]
  end

  def draw_sole_point(context)
    sole_point = @original_points[0]
    CGContextFillEllipseInRect(context, CGRectMake(sole_point.x, sole_point.y, @line_size, @line_size))
  end

  def draw_path_of_points(context)
    first = true
    @original_points.each do |point|
      image_pt = point + @image_size/2
      if first
        first = false
        CGContextMoveToPoint(context, *image_pt)
      else
        CGContextAddLineToPoint(context, *image_pt)
      end
    end
    CGContextStrokePath(context)
  end

  def setup_context(context)
    CGContextSetLineWidth(context, @line_size)
    CGContextSetLineCap(context, KCGLineCapRound)
    CGContextSetLineJoin(context, KCGLineJoinRound)
  end

  # Generates an image of the stroke.
  def generate_image
    UIGraphicsBeginImageContextWithOptions(@image_size.to_a, false, 0.0)
    context = UIGraphicsGetCurrentContext()
    setup_context(context)
    @colour.set
    if @original_points.length == 1
      draw_sole_point(context)
    else
      draw_path_of_points(context)
    end
    @image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
  end

  def draw(context)
    CGContextSaveGState(context)
    CGContextTranslateCTM(context, *@position)
    CGContextRotateCTM(context, @angle)
    @image.drawInRect(CGRectMake(*(@image_size/-2.0), *@image_size))
    CGContextRestoreGState(context)
  end

end