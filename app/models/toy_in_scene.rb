class ToyInScene

  # The information we need to save is:
  # position, angle and zoom - along with the template stuff of course

  attr_reader :old_position, :position, :old_angle, :old_zoom, :template
  attr_accessor :angle, :zoom
  attr_reader :image  # for the PlayScene

  def initialize(toy_template, zoom = 1.0)
    @template = toy_template
    @old_position = @position = CGPointMake((1024 - 190)/2, (768 - 56)/2)
    @old_angle = @angle = 0
    @image = @template.image
    @old_zoom = @zoom = zoom
  end

  # Turns the ToyInScene into json compatible data.
  def to_json_compatible
    json_toy_in_scene = {}
    json_toy_in_scene[:toy_id] = @template.identifier
    json_toy_in_scene[:position] = { x: int_x(@position.x), y: int_x(@position.y) }
    json_toy_in_scene[:angle] = @angle
    json_toy_in_scene[:zoom] = @zoom
    json_toy_in_scene
  end

  # Returns true iff the point is "close" to the toy.
  # "close" at the moment is within 40 points of the centre.
  def close_enough(point)
    (@position - point).magnitude < 40
  end

  # Called when the toy is being moved in the scene creator.
  def move(vpoint)
    @position += vpoint
  end

  # Called when a move in the UI is completed.
  def change_position(position)
    @old_position = @position = position
  end

  # Called when a rotate in the UI is completed.
  def change_angle(angle)
    @old_angle = @angle = angle
  end

  def centre_parts
    left, right, top, bottom = @template.extreme_points
    centre_point = CGPointMake((right+left)/2, (bottom+top)/2)
    @position = @position + (centre_point * @zoom)
    parts = []
    i = 0
    while i < @template.parts.length
      case @template.parts[i]
        when CirclePart
          parts << CirclePart.new(CGPointMake(0, 0), @template.parts[i].radius, @template.parts[i].colour)
          #puts "CirclePart-  X: " + @template.parts[i].position.x.to_s + ", Y: " + @template.parts[i].position.y.to_s
        when PointsPart
          points = []
          j = 0
          while j < @template.parts[i].points.length
            points << @template.parts[i].points[j] - centre_point
            j += 1
          end
          parts << PointsPart.new(points, @template.parts[i].colour)
      end
      i += 1
    end
    @template = ToyTemplate.new(parts, @template.identifier)
    @image = @template.create_image(@zoom)
    centre_point
  end

  # Called when a zoom in the UI is completed.
  def change_zoom(zoom)
    width_new = @image.size.width / @old_zoom * zoom
    height_new = @image.size.height / @old_zoom * zoom
    frame_width = 824
    frame_height = 700
    size_min = 25
    if(width_new > frame_width || height_new > frame_height)
      dx = width_new / frame_width
      dy = height_new / frame_height
      if (dx > dy)
        @zoom = frame_width / (@image.size.width / @old_zoom)
      else
        @zoom = frame_height / (@image.size.height / @old_zoom)
      end

    elsif(width_new < size_min && height_new < size_min )
      if(width_new < height_new)
        @zoom = size_min / (@image.size.height / @old_zoom)
      else
        @zoom = size_min / (@image.size.width / @old_zoom)
      end
    end
    @image = @template.create_image(@zoom)
    @old_zoom = @zoom
  end

  Wheel = Struct.new(:position, :radius)

  def add_wheels_in_scene(scene)
  # see PlayScene for more debugging info
    pos_in_scene = scene.view.convertPoint(position, toScene: scene)
    transform = CGAffineTransformMakeTranslation(*pos_in_scene)
    transform = CGAffineTransformScale(transform, @zoom, -@zoom)
    transform = CGAffineTransformRotate(transform, @angle)

    physics_wheels = []
    @template.parts.each do |part|
      if part.is_a? CirclePart
        x0 = part.position.x
        y0 = part.position.y
        transformed_pt = CGPointApplyAffineTransform(CGPointMake(x0,y0), transform)
        wheel = Wheel.new(transformed_pt, part.radius * zoom) #CGPointMake(x, y), part.radius * zoom)
        physics_wheels << wheel
      end
    end
    physics_wheels
  end

  def draw(context)
    CGContextSaveGState(context)
    CGContextTranslateCTM(context, *@position)
    CGContextRotateCTM(context, @angle)
    CGContextScaleCTM(context, @zoom/@old_zoom, @zoom/@old_zoom) #if @zoom != @old_zoom
    image_size = CGPointMake(@image.size.width, @image.size.height)
    @image.drawInRect(CGRectMake(*(image_size / -2.0), *image_size))
    CGContextRestoreGState(context)
  end

end