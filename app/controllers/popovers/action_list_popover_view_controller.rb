class ActionListPopoverViewController < UIViewController

  attr_writer :delegate, :selected, :scene_creator_view_controller

  LITTLE_GAP = 10
  BIG_GAP = 40
  WIDTH = 300
  MAX_HEIGHT = 500

  def loadView
    # Do not call super.
    self.view = UIView.alloc.initWithFrame([[0, 0], [WIDTH, 40]])
    view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)

    #make array of actions that relate to the selected toy
    @toy_actions = []
    @state.scenes[@state.currentscene].actions.each do |action|
      if action[:toy] == @selected.template.identifier
        @toy_actions << action
      end
    end

    #back button
    @back_button = UIButton.buttonWithType(UIButtonTypeCustom)
    @back_button.setImage(UIImage.imageNamed(:back_arrow), forState: UIControlStateNormal)
    @back_button.frame = [[5, 5], [20,20]]
    @back_button.addTarget(self, action: 'back:', forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(@back_button)

    @margin = @back_button.frame.size.width

    #title
    @title = UILabel.alloc.initWithFrame([[@margin+5,5],[WIDTH-@margin-5,20]])
    @title.setText('Actions')
    @title.setBackgroundColor(UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0))
    @title.setFont(UIFont.boldSystemFontOfSize(16))
    view.addSubview(@title)

    #title separator
    separator = CALayer.layer
    separator.frame = CGRectMake(5, 29.0, WIDTH, 1.0)
    separator.backgroundColor = UIColor.colorWithWhite(0.8, alpha:1.0).CGColor
    self.view.layer.addSublayer(separator)

    #make table view filled with all actions that have selected as the toy
    if @toy_actions.size > 3
      tvHeight = 280
    else
      tvHeight = 80 * @toy_actions.size
    end

    @table_view = UITableView.alloc.initWithFrame([[0, 35], [WIDTH, tvHeight]])
    @table_view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
    @table_view.dataSource = self
    @table_view.delegate = self
    @table_view.rowHeight = 80

    view.addSubview(@table_view)

    #setup new action button
    @action_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    @action_button.frame = [ [0, @table_view.frame.size.height+40], [WIDTH/2,20]]
    @action_button.setTitle("New Action", forState: UIControlStateNormal)
    @action_button.addTarget(self, action: 'new_action:', forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(@action_button)

    #setup edit button
    @edit_mode = false
    @edit_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    @edit_button.frame = CGRectMake(WIDTH/2,@table_view.frame.size.height+40, WIDTH/2,20)
    @edit_button.setTitle("Edit", forState: UIControlStateNormal)
    @edit_button.addTarget(self, action: 'edit:', forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(@edit_button)

    self.preferredContentSize = [WIDTH, @edit_button.frame.origin.y+@edit_button.frame.size.height+5]

  end

  def viewWillAppear(animated)
    #reload actions and resize?
    if @state and @selected and @toy_actions
      @toy_actions = @selected.template.actions
      # @state.scenes[@state.currentscene].actions.each do |action|
      #   if action[:toy] == @selected.template.identifier
      #     @toy_actions << action
      #   end
      # end
    end
    @table_view.reloadData
    resizeTV
  end

  def resizeTV
    if @table_view and @toy_actions
      if @toy_actions.size > 3
        tvHeight = 280
      else
        tvHeight = 80 * @toy_actions.size
      end

      @table_view.setFrame([[0, 35], [WIDTH, tvHeight]])
      @action_button.setFrame([ [0, @table_view.frame.size.height+40], [WIDTH/2,20]])
      @edit_button.setFrame(CGRectMake(WIDTH/2,@table_view.frame.size.height+40, WIDTH/2,20))
      self.preferredContentSize = [WIDTH, @edit_button.frame.origin.y+@edit_button.frame.size.height+5]
    end
  end

  # We need this to gain access to the toys.
  def state=(state)
    @state = state
    if @toy_actions and @selected and @state.scenes.size > 0
      @toy_actions = []
      @state.scenes[@state.currentscene].actions.each do |action|
        if action[:toy] == @selected.template.identifier
          @toy_actions << action
        end
      end
      @table_view.reloadData
      resizeTV
    end
  end

  # Back to the Select toy screen.
  def back(sender)
    @state.save
    @delegate.action_flow_back
  end

  def new_action(sender)
    puts "new action"
    @state.save
    @delegate.new_action
  end

  #activate edit mode
  def edit(sender)
    if @table_view.isEditing
      @table_view.setEditing(false, animated: true)
      @edit_button.setTitle("Edit", forState: UIControlStateNormal)
    else
      @table_view.setEditing(true, animated: true)
      @edit_button.setTitle("Done", forState: UIControlStateNormal)
      @state.save
    end
  end

  # The methods to implement the UICollectionViewDataSource protocol.

  def tableView(tv, commitEditingStyle: style, forRowAtIndexPath: index_path)
    tv.beginUpdates
    tv.deleteRowsAtIndexPaths([index_path], withRowAnimation: UITableViewRowAnimationAutomatic)
    #delete action
    item = index_path.row
    #remove from scene
    @state.scenes[@state.currentscene].actions.delete_if { |action|
      action == @toy_actions.at(item)
    }
    #remove from toy
    @selected.template.actions.delete_if { |action|
      action == @toy_actions.at(item)
    }
    @toy_actions.delete_at(item)
    tv.endUpdates
    #resize?
    resizeTV
  end

  def tableView(tv, numberOfRowsInSection: section)
    @toy_actions.length
  end

  def drawText(text, inImage:image)
    font = UIFont.fontWithName('Courier New', size: 20)
    UIGraphicsBeginImageContext(image.size)
    image.drawInRect(CGRectMake(0,0,image.size.width,image.size.height))
    rect = CGRectMake(image.size.width/9, image.size.height/2.75, image.size.width, image.size.height)
    UIColor.blackColor.set
    text.drawInRect(CGRectIntegral(rect), withFont:font)
    newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    newImage
  end





  def tableView(tv, cellForRowAtIndexPath: index_path)
    item = index_path.row # ignore section as only one

    @reuseIdentifier ||= "cell"
    action_cell = @table_view.dequeueReusableCellWithIdentifier(@reuseIdentifier)
    action_cell ||= ActionCell.alloc.initWithStyle(UITableViewCellStyleValue1, reuseIdentifier: @reuseIdentifier)

    action_cell.selectionStyle = UITableViewCellSelectionStyleNone
    action = @toy_actions[item]

    action_cell.action_text = action[:action_type].gsub('_', ' ')
    #action image
    case action[:action_type]
      when :collision
        action_cell.action_image = UIImage.imageNamed("collision.png")
        #set object to be the toy image of the identifier in actionparam
        @state.toys.each do |toy|
          if toy.identifier == action[:action_param]
            action_cell.object_image = toy.image
            break
          end
        end

      when :timer
        action_cell.action_image = UIImage.imageNamed("timer.png")
        # action_cell.action_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("touch.png"))
        #show how often in object view
        textImage = drawText(action[:action_param][0].to_s.rjust(2, "0") + ':' + action[:action_param][1].to_s.rjust(2, "0"), inImage:UIImage.imageNamed("empty.png") )
        action_cell.object_image = textImage
      when :button
        action_cell.action_image = UIImage.imageNamed("touch.png")
        action_cell.action_text = 'tap'
        action_cell.object_image = UIImage.imageNamed(action[:action_param]+ ".png")
      when :score_reaches
        action_cell.action_image = UIImage.imageNamed(action[:action_type]+".png")
        textImage = drawText(action[:action_param][0].to_s, inImage:UIImage.imageNamed("empty.png") )
        action_cell.object_image = textImage
      when :shake, :when_created, :loud_noise, :toy_touch
        action_cell.action_image = UIImage.imageNamed(action[:action_type]+".png")
      else
    end

    action_cell.effect_image = UIImage.imageNamed(action[:effect_type]+".png")
    action_cell.effect_text = action[:effect_type].gsub('_',' ')

    case action[:effect_type]
      when :apply_force
        #draw arrow in direction
        forceImage = drawForce(action[:effect_param], inImage:UIImage.imageNamed("empty.png") )
        action_cell.param_image = forceImage
      when :explosion
        #draw circle with size
        expImage = drawExplosion(action[:effect_param], inImage:UIImage.imageNamed("empty.png") )
        action_cell.param_image = expImage
      when :apply_torque
        #draw arrow with direction in circle
        rotImage = drawRotation(action[:effect_param], inImage:UIImage.imageNamed("empty.png") )
        action_cell.param_image = rotImage
      when :create_new_toy
        #draw toy
        #set object to be the toy image of the identifier in actionparam
        @state.toys.each do |toy|
          if toy.identifier == action[:effect_param][:id]
            action_cell.param_image = toy.image
            break
          end
        end
      when :delete_effect
        #nothing
      when :score_adder
        #show how score is changed
        textImage = drawText(action[:action_param][0].to_s, inImage:UIImage.imageNamed("empty.png") )
        action_cell.object_image = textImage
      when :play_sound
        #show sound name? button to play sound?
      else
    end

    action_cell

  end

  def tableView(tv, didSelectRowAtIndexPath: index_path)
    item = index_path.row
    puts "Selected row "
  end

  def drawForce(vector, inImage:image)
    UIGraphicsBeginImageContext(image.size)
    image.drawInRect(CGRectMake(0,0,image.size.width,image.size.height))
    context = UIGraphicsGetCurrentContext()

    # max  x and y 500?
    draw_force_arrow(context,CGPointMake(((-vector.x+500*250)/250000)*image.size.width, ((vector.y+500*250)/250000)*image.size.height),CGPointMake(((vector.x+500*250)/250000)*image.size.width, ((-vector.y+500*250)/250000)*image.size.height))

    puts "img= "+image.size.width.to_s+", "+image.size.height.to_s
    puts "vector= "+vector.x.to_s+', '+vector.y.to_s
    puts "point= "+(((vector.x+500)/1000)*image.size.width).to_s+','+ (((vector.y+500)/1000)*image.size.height).to_s
    newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    newImage
  end

  def drawExplosion(magnitude, inImage:image)
    UIGraphicsBeginImageContext(image.size)
    image.drawInRect(CGRectMake(0,0,image.size.width,image.size.height))
    context = UIGraphicsGetCurrentContext()

    # max  x and y 500?
    draw_force_circle(context,CGPointMake(image.size.width/2, image.size.height/2),(magnitude/52000)*image.size.width/2)

    puts "mag= "+magnitude.to_s

    newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    newImage
  end

  def drawRotation(radians, inImage:image)
    #radians between -2pi and +2pi, -ve = clockwise
    UIGraphicsBeginImageContext(image.size)
    image.drawInRect(CGRectMake(0,0,image.size.width,image.size.height))

    context = UIGraphicsGetCurrentContext()
    radius = image.size.width/4

    UIColor.redColor.set
    if(radians > 0)
      CGContextAddArc(context, image.size.width/2, image.size.height/2, radius, Math::PI, radians+Math::PI, 0)
    else
      CGContextAddArc(context, image.size.width/2, image.size.height/2, radius, Math::PI, radians+Math::PI, 1)
    end
    CGContextSetLineWidth(context, 8)
    CGContextStrokePath(context)

    draw_rotate_circle_arrow(context, CGPointMake(image.size.width/2,image.size.height/2), radius, radians-Math::PI, radians > 0)

    newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    newImage

  end

  def draw_rotate_circle_arrow(context,center, length, angle, clockwise)

    arrow_points = []
    if not clockwise
      arrow_points << CGPointMake(- 15, 0) << CGPointMake(0, -18.75)
      arrow_points << CGPointMake(15, 0)
    else
      arrow_points << CGPointMake(- 15, 0) << CGPointMake(0, 18.75)
      arrow_points << CGPointMake(15, 0)
    end

    arrow_transform_pointer = Pointer.new(CGAffineTransform.type)
    arrow_transform_pointer[0] = CGAffineTransformMakeTranslation( center.x, center.y)
    arrow_transform_pointer[0] = CGAffineTransformRotate(arrow_transform_pointer[0], angle)
    arrow_transform_pointer[0] = CGAffineTransformTranslate(arrow_transform_pointer[0],length, 0)

    path = CGPathCreateMutable()
    CGPathMoveToPoint(path, arrow_transform_pointer, length, 0)

    arrow_points.each do |point|
      CGPathAddLineToPoint(path, arrow_transform_pointer, point.x, point.y)
    end
    CGContextAddPath(context, path)
    CGContextSetFillColorWithColor(context, UIColor.redColor.CGColor)
    CGContextDrawPath(context, KCGPathFill)
  end

  def draw_force_arrow(context, start, finish)
    CGContextSetLineWidth(context, 8)
    arrow_size = 15

    dx = finish.x - start.x
    dy = finish.y - start.y
    combined = dx.abs + dy.abs
    length = Math.hypot(dx, dy)
    if length < arrow_size
      length = arrow_size
      dx = length * (dx/combined)
      dy = length * (dy/combined)
    end
    arrow_points = []
    arrow_points << CGPointMake(0, -5) << CGPointMake(length - arrow_size, -5) << CGPointMake(length - arrow_size, -12)
    arrow_points << CGPointMake(length, 0)
    arrow_points << CGPointMake(length - arrow_size, 12) << CGPointMake(length - arrow_size, 5) << CGPointMake(0, 5)

    cosine = dx / length
    sine = dy / length

    arrow_transform_pointer = Pointer.new(CGAffineTransform.type)
    arrow_transform_pointer[0] = CGAffineTransform.new(cosine, sine, -sine, cosine, start.x, start.y)

    path = CGPathCreateMutable()
    CGPathMoveToPoint(path, arrow_transform_pointer, 0, 0)
    arrow_points.each do |point|
      CGPathAddLineToPoint(path, arrow_transform_pointer, point.x, point.y)
    end
    CGContextAddPath(context, path)
    CGContextSetFillColorWithColor(context, UIColor.redColor.CGColor)
    CGContextDrawPath(context, KCGPathFill)
  end

  def draw_force_circle(context, center, radius)
    rectangle = CGRectMake(center.x - radius, center.y - radius, radius*2, radius*2)
    CGContextSetStrokeColorWithColor(context,UIColor.redColor.CGColor)
    CGContextSetFillColorWithColor(context,UIColor.redColor.CGColor)
    CGContextSetLineWidth(context, 5)
    CGContextAddEllipseInRect(context, rectangle)
    CGContextFillPath(context)
  end

end