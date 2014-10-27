# Holds the information on the scene.
# This includes toys, edges and backgrounds (eventually)

# TODO: separate the edge and background stuff into BackgroundTemplate
class SceneTemplate

  attr_reader :toys, :edges, :actions, :identifier, :image, :gravityX, :gravityY, :background, :boundaries
  attr_writer :identifier, :bounds, :gravityX, :gravityY, :background, :boundaries

  WIDTH = 834
  HEIGHT = 712
  TOY_LINE_SIZE = 20.0
  IMAGE_SCALE = 0.25 # this is the scale factor when a toy image is first created.
  ACCURACY = 100.0   # the rounding factor for the data

  TOP=0
  BOTTOM=1
  LEFT=2
  RIGHT=3
  SWITCH_ON=1
  SWITCH_OFF=0

  def initialize(toys, edges, actions, identifier, bounds, gravity=nil, boundaries=nil, background=nil)
    @identifier = identifier
    @toys = toys    # each of type ToyInScene
    @edges = edges  # each of type ToyPart - either Circle or Points
    @actions = actions   # each a Hash
    p "scene action = #{@actions}"
    @bounds = bounds

    @background = background

    if boundaries!=nil
      *@boundaries = *boundaries
    else
      @boundaries = [1,1,1,1]
    end

    # possibly create an image of the scene for the scene box view, the small version
    @image = create_image(Constants::SMALLER_SIZED_SAVED_SCENE)

    @gravity = gravity
    if @gravity == nil
      @gravity = CGVectorMake(Constants::DEFAULT_GRAVITY_X, Constants::DEFAULT_GRAVITY_Y)
    end
    @gravityX = @gravity.dx
    @gravityY = @gravity.dy
  end

  def add_actions(actions)
    @actions = []
    if actions.kind_of?(Array)
      actions.each do |action|
        if !@actions.include?(action)
          @actions << action
        end
      end
    else
      if !@actions.include?(actions)
        @actions << actions
      end
    end
    @actions.flatten!
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
    json_scene[:gravity] = @gravity.dy
    json_scene[:wind] = @gravity.dx
    json_scene[:boundaries] = @boundaries

    #change background image to JSON
    if @background != nil
      backgroundImageData = UIImageJPEGRepresentation(@background, 0.9)
      encodedData = [backgroundImageData].pack("m")
      json_scene[:background] = encodedData
    end

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
    # create small image
    @image = create_image(0.35)
  end

  def image_bitmap(size, scale)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    context = UIGraphicsGetCurrentContext()
    setup_context(context, scale)

    colour = SceneCreatorView::DEFAULT_SCENE_COLOUR
    colour.set

    p @background
    if @background != nil
      rectangle = CGRectMake(Constants::SMALL_GAP, Constants::SMALL_GAP, size.width - 2*Constants::SMALL_GAP, size.height - 2*Constants::SMALL_GAP)

      @background.drawInRect(rectangle)
    else
      CGContextFillRect(context, CGRectMake(Constants::SMALL_GAP, Constants::SMALL_GAP, size.width - 2*Constants::SMALL_GAP, size.height - 2*Constants::SMALL_GAP))
    end

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
      if toy and toy.ghost == false
        draw_toy(context,toy,scale)
      end
    end

    font = UIFont.fontWithName("Courier", size: 14.0)
    fontHeight = font.pointSize
    text = "Gravity = " << @gravityY.to_s << ", wind = " << @gravityX.to_s
    UIColor.blackColor.set
    text.drawAtPoint(CGPointMake(10, 10), withFont:font)

    # draw the boundaries
    colour = UIColor.redColor
    colour.set
    #left
    if @boundaries[LEFT]==SWITCH_ON
      CGContextFillRect(context, CGRectMake(0, 0, Constants::SMALL_GAP, size.height))
    end
    #top
    if @boundaries[TOP]==SWITCH_ON
      CGContextFillRect(context, CGRectMake(0, 0, size.width, Constants::SMALL_GAP))
    end
    #bottom
    if @boundaries[BOTTOM]==SWITCH_ON
      CGContextFillRect(context, CGRectMake(0, size.height-Constants::SMALL_GAP, size.width, Constants::SMALL_GAP))
    end
    #right
    if @boundaries[RIGHT]==SWITCH_ON
      CGContextFillRect(context, CGRectMake(size.width-Constants::SMALL_GAP, 0, Constants::SMALL_GAP, size.height))
    end

    image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    image
  end

  def toyInPlayScene
    realToyInScene = []
    @toys.each do |toy|
      if toy.ghost == false
        realToyInScene << toy
      end
    end
    realToyInScene
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