
# A ToyPart is either a circle or a list of joined points and associated characteristics
# such as colour and position relative to the centre of its Toy.
# Parts are different from Strokes in that a stroke also draws its image and handles
# close_to? queries. Whereas a Part is more abstract and deals with saving and restoring.
# They could be amalgamated but not yet :).

class ToyPart

  attr_reader :red, :green, :blue, :colour # :position,

  # position - relative to the center of the Toy
  def initialize(colour) #position, colour)
    #@position = position
    @colour = colour
    red = Pointer.new(:float)
    green = Pointer.new(:float)
    blue = Pointer.new(:float)
    alpha = Pointer.new(:float)
    colour.getRed(red, green: green, blue: blue, alpha: alpha)
    @red = red[0]
    @green = green[0]
    @blue = blue[0]
  end

  #def to_s
  #  "position: #{@position.x}, #{@position.y}"
  #end

  # The json versions are integers 100 times the original values
  def to_json_compatible
    {
      colour: { red: int_x(@red), green: int_x(@green), blue: int_x(@blue) }
    }
  end

  def int_x(number)
    (number * ToyTemplate::ACCURACY + (number > 0 ? 0.5 : -0.5)).to_i
  end

end

# A CirclePart.
class CirclePart < ToyPart

  attr_reader :position, :radius

  # position - relative to the center of the Toy
  def initialize(position, radius, colour)
    super(colour) #position, colour)
    @position = position
    @radius = radius
  end

  def to_json_compatible
    json_hash = super
    json_hash[:position] = { x: int_x(@position.x), y: int_x(@position.y) }
    json_hash[:radius] = int_x(@radius)
    json_hash
  end

  # Returns the extreme position values in each of the four directions.
  def extremes
    left = @position.x - @radius
    right = @position.x + @radius
    top = @position.y - @radius
    bottom = @position.y + @radius
    [left, right, top, bottom]
  end

  def center
    bound = extremes
    [ (bound[0] - bound[1]).abs, (bound[2] - bound[3]).abs ]
  end

  def left
    @position.x - @radius
  end

  def top
    @position.y - @radius
  end

end

# A PointsPart - sequences of connected points.
class PointsPart < ToyPart

  attr_reader :points

  # position - relative to the center of the Toy
  # points are also relative to the centre of the Toy
  def initialize(points, colour) #position, points, colour)
    super(colour) #position, colour)
    @points = points
    #puts "PointsPart"
    #@points.each { |p| puts "(#{p.x}, #{p.y})" }
  end

  def to_json_compatible
    json_hash = super
    json_hash[:points] = @points.map { |point| { x: int_x(point.x), y: int_x(point.y) } }
    json_hash
  end

  # Returns the extreme position values in each of the four directions.
  def extremes
    point = @points[0]
    #puts "next"
    #p [point.x, point.y]
    left = right = point.x # @position.x + point.x
    top = bottom = point.y # @position.y + point.y
    @points[1..-1].each do |point|
      #p [point.x, point.y]
      x, y = point.to_a # (@position + point).to_a
      left = x if x < left
      right = x if x > right
      top = y if y < top
      bottom = y if y > bottom
    end
    #p [left, right, top, bottom]
    [left, right, top, bottom]
  end

  def center
    bound = extremes
    [ (bound[0] - bound[1]).abs, (bound[2] - bound[3]).abs ]
  end

  def points_for_scene_background(scene_size)
    @points.map do |pt|
      #offset = CGPointMake(scene_size.width / 2, scene_size.height / 2)
      #CGPointMake(pt.x - offset.x, offset.y - pt.y)
      CGPointMake(pt.x, scene_size.height - pt.y)
    end
  end

end