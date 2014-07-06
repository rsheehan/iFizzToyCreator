# A ToyTemplate saves the important values of a toy. Toy instances are created from it.
class ToyTemplate

  TOY_LINE_SIZE = 20.0
  IMAGE_SCALE = 0.25 # this is the scale factor when a toy image is first created.
  ACCURACY = 100.0   # the rounding factor for the data

  attr_reader :image, :parts, :identifier, :exploded
  attr_accessor :stuck, :can_rotate, :front, :always_travels_forward, :actions

  def initialize(parts, identifier) #, image)
    @identifier = identifier
    @parts = parts
    @image = create_image(1)
    @exploded = []
    @stuck = false
    @can_rotate = true
    @front = Constants::Front::Right
    @always_travels_forward = false
    @actions = []
    #ToyPhysicsBody.new(self) <--

    #@image = image
    #save
  end

  def update_image
    @image = create_image(1)
  end

  # Turns the ToyTemplate into json compatible data.
  def to_json_compatible
    json_toy = {}
    json_toy[:id] = @identifier

    #properties
    json_toy[:can_rotate] = @can_rotate
    json_toy[:stuck] = @stuck
    json_toy[:front] = @front
    json_toy[:always_travels_forward] = @always_travels_forward

    #parts
    json_parts = []
    @parts.each do |part|
      json_parts << part.to_json_compatible
    end
    json_toy[:parts] = json_parts

    #actions
    json_actions = []
    @actions.each do |action|
      if action[:effect_type] == :apply_force
        json_actions << action.each_with_object({}){|(k,v), h| if k == :effect_param
                                                                 h[k] = [v.x, v.y]
                                                               else
                                                                 h[k] = v
                                                               end }
      else
        json_actions << action
      end

    end
    json_toy[:actions] = json_actions

    json_toy
  end


  # Creates the image from the part data.
  def create_image(scale)
    # find the image size
    left, right, top, bottom = extreme_points
    #p [left, right, top, bottom]
    extra = TOY_LINE_SIZE * IMAGE_SCALE
    size = CGSizeMake((right - left + extra) * scale, (bottom - top + extra) * scale)
    # make the image bitmap and draw all of the parts
    image_bitmap(size, scale)
  end

  # Traverses the parts and determines the extreme values.
  def extreme_points
    part = @parts[0]
    left, right, top, bottom = part.extremes
    @parts[1..-1].each do |part|
      l, r, t, b = part.extremes
      left = l if l < left
      right = r if r > right
      top = t if t < top
      bottom = b if b > bottom
    end
    [left, right, top, bottom]
  end

  def center
    bound = extreme_points
    [ (bound[0] - bound[1]).abs, (bound[2] - bound[3]).abs ]
  end

  def image_bitmap(size, scale)
    centre_in_image = CGPointMake(*size) / 2
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    context = UIGraphicsGetCurrentContext()
    setup_context(context, scale)
    @parts.each do |part|
      colour = UIColor.colorWithRed(part.red, green: part.green, blue: part.blue, alpha: 1.0)
      colour.set
      case part
        when CirclePart
          radius = part.radius
          origin = CGPointMake((part.position.x - radius) * scale, (part.position.y - radius) * scale) + centre_in_image
          CGContextFillEllipseInRect(context, CGRectMake(*origin, radius*2 * scale, radius*2 * scale))
        when PointsPart
          if part.points.size  == 1
            draw_sole_point(context, centre_in_image, part.points[0], scale)
          else
            draw_path_of_points(context, centre_in_image, part.points, scale)
          end
      end
    end
    image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    #puts "ToyTemplate image: #{image.size.width}, #{image.size.height}"
    image
  end

  def draw_sole_point(context, centre, sole_point, scale)
    image_point = sole_point * scale + centre
    point_size = TOY_LINE_SIZE * IMAGE_SCALE * scale
    CGContextFillEllipseInRect(context, CGRectMake(image_point.x, image_point.y, point_size, point_size))
  end

  def draw_path_of_points(context, centre, points, scale)
    first = true
    points.each do |point|
      image_pt = point * scale + centre
      if first
        first = false
        CGContextMoveToPoint(context, *image_pt)
      else
        CGContextAddLineToPoint(context, *image_pt)
      end
    end
    CGContextStrokePath(context)
  end

  def setup_context(context, scale)
    CGContextSetLineWidth(context, TOY_LINE_SIZE * IMAGE_SCALE * scale)
    CGContextSetLineCap(context, KCGLineCapRound)
    CGContextSetLineJoin(context, KCGLineJoinRound)
  end


  def populate_exploded
    @exploded = check_parts(@parts, center)
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

end