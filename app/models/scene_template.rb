# Holds the information on the scene.
# This includes toys, edges and backgrounds (eventually)

# TODO: separate the edge and background stuff into BackgroundTemplate
class SceneTemplate

  attr_reader :toys, :edges, :actions, :identifier, :image
  attr_writer :identifier, :bounds

  WIDTH = 834
  HEIGHT = 712
  TOY_LINE_SIZE = 20.0
  IMAGE_SCALE = 0.25 # this is the scale factor when a toy image is first created.
  ACCURACY = 100.0   # the rounding factor for the data

  def initialize(toys, edges, actions, identifier, bounds)
    @identifier = identifier
    @toys = toys    # each of type ToyInScene
    @edges = edges  # each of type ToyPart - either Circle or Points
    @actions = actions   # each a Hash
    puts "SceneTemplate actions"
    @bounds = bounds
    p actions
    # possibly create an image of the scene for the scene box view
    @image = create_image(0.35)
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

    #actions will go here

    json_scene
  end

  # Creates the image from the part data.
  def create_image(scale)
    # find the image size
    size = CGSizeMake(WIDTH * scale, HEIGHT * scale)
    # make the image bitmap and draw all of the parts
    image_bitmap(size, scale)
  end

  def update_image
    @image = create_image(0.35)
  end

  def image_bitmap(size, scale)
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
          origin = CGPointMake((part.position.x - radius) * scale, (part.position.y - radius) * scale)
          CGContextFillEllipseInRect(context, CGRectMake(*origin, radius*2 * scale, radius*2 * scale))
        when PointsPart
          if part.points.size  == 1
            draw_sole_point(context, part.points[0], scale)
          else
            draw_path_of_points(context, part.points, scale)
          end
      end
    end
    @toys.each do |toy|
      #draw toy image at position and scale and rotation
      if toy
        draw_toy(context,toy,scale)
      end

    end
    image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    #puts "ToyTemplate image: #{image.size.width}, #{image.size.height}"
    image
  end

  def draw_sole_point(context, sole_point, scale)
    image_point = sole_point * scale
    point_size = TOY_LINE_SIZE * IMAGE_SCALE * scale
    CGContextFillEllipseInRect(context, CGRectMake(image_point.x, image_point.y, point_size, point_size))
  end

  def draw_toy(context, toy, scale)
    angle = toy.angle
    pos = toy.position * scale

    CGContextSaveGState(context)
    CGContextTranslateCTM(context, *pos)
    CGContextRotateCTM(context, angle)
    CGContextScaleCTM(context, scale*toy.zoom/toy.old_zoom, scale*toy.zoom/toy.old_zoom) #if @zoom != @old_zoom
    image_size = CGPointMake(toy.image.size.width, toy.image.size.height)
    toy.image.drawInRect(CGRectMake(*(image_size / -2.0), *image_size))
    CGContextRestoreGState(context)
  end

  def draw_path_of_points(context, points, scale)
    first = true
    points.each do |point|
      image_pt = point * scale
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