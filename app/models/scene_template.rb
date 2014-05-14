# Holds the information on the scene.
# This includes toys, edges and backgrounds (eventually)

# TODO: separate the edge and background stuff into BackgroundTemplate
class SceneTemplate

  attr_reader :toys, :edges, :actions, :identifier, :image

  WIDTH = 768
  TOY_LINE_SIZE = 20.0
  IMAGE_SCALE = 0.25 # this is the scale factor when a toy image is first created.
  ACCURACY = 100.0   # the rounding factor for the data

  def initialize(toys, edges, actions, identifier)
    @identifier = identifier
    @toys = toys    # each of type ToyInScene
    @edges = edges  # each of type ToyPart - either Circle or Points
    @actions = actions   # each a Hash
    puts "SceneTemplate actions"
    p actions
    # possibly create an image of the scene for the scene box view
    @image = create_image(1)
  end

  # Turns the SceneTemplate into json compatible data.
  def to_json_compatible
    json_scene = {}
    json_scene[:id] = @identifier
    # the toys are represented by their identifiers
    json_toys = []
    @toys.each do |toy|
      json_toys << toy.to_json_compatible
    end
    json_scene[:toys] = json_toys
    json_edges = []
    @edges.each do |edge_part|
      json_edges << edge_part.to_json_compatible
    end
    json_scene[:edges] = json_edges
    json_scene
  end

  # Creates the image from the part data.
  def create_image(scale)
    # find the image size
    left = 0
    right = WIDTH
    top = 0
    bottom = WIDTH

    extra = TOY_LINE_SIZE * IMAGE_SCALE
    size = CGSizeMake((right - left + extra) * scale, (bottom - top + extra) * scale)
    # make the image bitmap and draw all of the parts
    image_bitmap(size, scale)
  end

  def image_bitmap(size, scale)
    centre_in_image = CGPointMake(*size) / 2
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    context = UIGraphicsGetCurrentContext()
    setup_context(context, scale)
    colour = SceneCreatorView::DEFAULT_SCENE_COLOUR
    colour.set
    CGContextFillRect(context, CGRectMake(0,0, *size))
    @edges.each do |part|
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