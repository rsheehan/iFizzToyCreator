# A CircleStroke is just a circle part of a Toy.
class CircleStroke < Stroke
  #include Stroke

  attr_reader :radius

  def initialize(centre, radius, colour, line_size)
    #@centre = centre
    @radius = radius + line_size/2 # because of the fatness of the lines
    @colour = colour
    @old_position = @position = centre #Vector.from_pt(centre)
    @image_size = CGPoint.new(@radius*2, @radius*2) #Vector[@radius*2, @radius*2]
    generate_image
  end

  ## Rotates the stroke about its centre by the given angle.
  #def rotate(angle)
  #  #puts "circles don't rotate"
  #end

  # Returns true iff the point is close to the circle.
  # Currently this requires the point to be inside the circle
  def close_to?(point)
    # needs the radius for this
    vec_pt = point #Vector.from_pt(point)
    distance = (vec_pt - @position).magnitude
    distance <= @radius
  end

  # Returns the extreme position values in each of the four directions.
  def extremes
    left = @position.x - @radius
    right = @position.x + @radius
    top = @position.y - @radius
    bottom = @position.y + @radius
    [left, right, top, bottom]
  end

  # Generates an image of the circle.
  def generate_image
    UIGraphicsBeginImageContextWithOptions(@image_size.to_a, false, 0.0)
    context = UIGraphicsGetCurrentContext()
    #setup_context(context)
    @colour.set
    CGContextFillEllipseInRect(context, CGRectMake(0.0, 0.0, @image_size.x, @image_size.y))
    @image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
  end

  def draw(context)
    CGContextSaveGState(context)
    CGContextTranslateCTM(context, *@position)
    @image.drawInRect(CGRectMake(*(@image_size/-2.0), *@image_size))
    CGContextRestoreGState(context)
  end

end