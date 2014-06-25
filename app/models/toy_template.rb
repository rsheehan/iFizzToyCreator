# A ToyTemplate saves the important values of a toy. Toy instances are created from it.
class ToyTemplate

  TOY_LINE_SIZE = 20.0
  IMAGE_SCALE = 0.25 # this is the scale factor when a toy image is first created.
  ACCURACY = 100.0   # the rounding factor for the data

  attr_reader :image, :parts, :identifier
  attr_accessor :stuck, :can_rotate, :actions

  def initialize(parts, identifier) #, image)
    @identifier = identifier
    @parts = parts
    @image = create_image(1)

    @stuck = false
    @can_rotate = true
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

end