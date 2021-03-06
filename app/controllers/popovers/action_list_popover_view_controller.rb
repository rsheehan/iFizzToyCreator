class ActionListPopoverViewController < UIViewController

  attr_writer :delegate, :selected, :scene_creator_view_controller

  LITTLE_GAP = 10
  BIG_GAP = 40
  WIDTH = 350
  MAX_HEIGHT = 500

  EMPTY_ICON_TEXT_INSET_X = UIScreen.mainScreen.scale != 1.0 ? 10 : 5
  EMPTY_ICON_TEXT_INSET_Y = UIScreen.mainScreen.scale != 1.0 ? 35 : 17.5
  EMPTY_ICON_INSET = UIScreen.mainScreen.scale != 1.0 ? 20 : 10

  def loadView
    # Do not call super.
    self.view = UIView.alloc.initWithFrame([[0, 0], [WIDTH, 40]])
    view.backgroundColor = Constants::LIGHT_GRAY

    #make array of actions that relate to the selected toy
    @toy_actions = @selected.template.actions

    @table_view = UITableView.alloc.initWithFrame([[0, 5], [WIDTH, MAX_HEIGHT]])
    @table_view.backgroundColor = Constants::LIGHT_GRAY
    @table_view.dataSource = self
    @table_view.delegate = self

    view.addSubview(@table_view)

    #setup new action button
    @action_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    @action_button.frame = [ [0, @table_view.frame.size.height+@table_view.frame.origin.y+15], [WIDTH/2,20]]
    @action_button.setTitle("New Action", forState: UIControlStateNormal)
    @action_button.addTarget(self, action: 'new_action:', forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(@action_button)

    #setup edit button

    @edit_mode = false
    @edit_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    @edit_button.frame = CGRectMake(WIDTH/2,@table_view.frame.size.height+@table_view.frame.origin.y+15, WIDTH/2,20)
    @edit_button.setTitle("Remove", forState: UIControlStateNormal)
    @edit_button.addTarget(self, action: 'delete:', forControlEvents: UIControlEventTouchUpInside)

    if @selected.template.identifier != Constants::SCENE_TOY_IDENTIFIER
      view.addSubview(@edit_button)
    end

  end

  def viewWillAppear(animated)
    #reload actions and resize?
    if @state and @selected and @toy_actions
      #p "id = #{@selected.template.identifier}"
      @toy_actions = @selected.template.actions

      if @selected.template.identifier == Constants::SCENE_TOY_IDENTIFIER
        @toy_actions = []
        @selected.template.actions.each do |action|
           if action[:scene] == @delegate.main_view.scene_drop_id.to_s
            @toy_actions << action
           end
        end
      end
    end
    @table_view.reloadData
    resizeTV
    @table_view.cellForRowAtIndexPath(NSIndexPath.indexPathForRow(0, inSection:0)).hidden = @stuck_switch.on?
    @table_view.cellForRowAtIndexPath(NSIndexPath.indexPathForRow(3, inSection:0)).hidden = (not @travel_switch.on?)
  end

  def viewWillDisappear(animated)
    @state.save
  end

  def resizeTV
    p "resize"
    if @table_view and @toy_actions
      extra = 330
      if @selected.template.identifier == Constants::SCENE_TOY_IDENTIFIER
        tvHeight = 80 * @toy_actions.size + 80
      else
        if @toy_actions.size > 2
          tvHeight = 200 + extra
        else
          tvHeight = 80 * @toy_actions.size + extra
        end
      end

      @table_view.setFrame([[0, 5], [WIDTH, tvHeight]])
      @action_button.setFrame([ [0, @table_view.frame.size.height+@table_view.frame.origin.y+5], [WIDTH/2,20]])
      @edit_button.setFrame(CGRectMake(WIDTH/2,@table_view.frame.size.height+@table_view.frame.origin.y+5, WIDTH/2,20))
      self.preferredContentSize = [WIDTH, @edit_button.frame.origin.y+@edit_button.frame.size.height + Constants::SMALL_MARGIN]

    end


  end

  # We need this to gain access to the toys.
  def state=(state)
    @state = state
    if @toy_actions and @selected and @state.scenes.size > 0
      #p "<<<<<< set here"
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

  def new_action(sender)
    #puts "new action"
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

  #delete toy from scene
  def delete(sender)
    #p "selected is #{@selected}"
    @delegate.remove_selected(@selected)
    @state.save
  end

  # The methods to implement the UICollectionViewDataSource protocol.
  def tableView(tv, commitEditingStyle: style, forRowAtIndexPath: index_path)
    tv.beginUpdates
    tv.deleteRowsAtIndexPaths([index_path], withRowAnimation: UITableViewRowAnimationAutomatic)
    item = index_path.row
    #remove from toy

    if @selected.template.identifier == Constants::SCENE_TOY_IDENTIFIER
      @selected.template.actions.delete(@toy_actions[item])
    end
    @toy_actions.delete_at(item)

    @delegate.show_sides
    tv.endUpdates
    resizeTV
  end

  def tableView(tv, numberOfRowsInSection: section)
    if section == 0
      5
    else
      @toy_actions.length
    end
  end

  def tableView(tv, heightForRowAtIndexPath: indexPath)
    if indexPath.section == 0
      if indexPath.row == 0 and @selected.template.stuck
        0
      elsif indexPath.row == 3 and not @selected.template.always_travels_forward
        0
      elsif @selected.template.identifier == Constants::SCENE_TOY_IDENTIFIER
        0
      else
        40
      end
    else
      90
    end
  end

  def drawText(text, inImage:image, withFontName:fontname, fontsize = 26)
    UIGraphicsBeginImageContext(image.size)
    image.drawInRect(CGRectMake(0, 0,image.size.width,image.size.height))
    #fontsize = 26
    font = UIFont.fontWithName(fontname, size: fontsize)
    UIColor.blackColor.set
    #center text in rect
    fontHeight = font.pointSize
    yOffset = (image.size.height - 2*EMPTY_ICON_TEXT_INSET_Y - fontHeight) / 2.0

    if fontname == 'DBLCDTempBlack'
      yOffset = 1.5*yOffset
    end

    if fontsize < 26
      yOffset = -1.5*yOffset
    end

    rect = CGRectMake(EMPTY_ICON_TEXT_INSET_X, EMPTY_ICON_TEXT_INSET_Y+yOffset, image.size.width-2*EMPTY_ICON_TEXT_INSET_X, fontHeight)

    text.drawInRect(CGRectIntegral(rect), withFont:font, lineBreakMode: UILineBreakModeClip, alignment: UITextAlignmentCenter)
    newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    newImage
  end


  def drawToy(toy)
    image = UIImage.imageNamed('empty.png')
    UIGraphicsBeginImageContext(image.size)
    image.drawInRect(CGRectMake(0, 0,image.size.width,image.size.height))

    rect = CGRectMake(EMPTY_ICON_INSET,EMPTY_ICON_INSET,image.size.width-2*EMPTY_ICON_INSET,image.size.height-2*EMPTY_ICON_INSET)
    aspect = toy.image.size.width / toy.image.size.height
    if (rect.size.width / aspect <= rect.size.height)
      rect.size = CGSizeMake(rect.size.width, rect.size.width/aspect)
    else
      rect.size = CGSizeMake(rect.size.height * aspect, rect.size.height)
    end
    toy.image.drawInRect(rect)
    newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    newImage
  end

  def tableView(tv, cellForRowAtIndexPath: index_path)
    if index_path.section == 0
      cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier: "default")
      #puts "Cell: " + cell.to_s
      cell.font = UIFont.systemFontOfSize(16)
      position = index_path.row
      case position
        when 0
          cell.text = Language::CAN_ROTATE
          #check toy property and set init val
          @rotate_switch = UISwitch.alloc.initWithFrame([[95, 95], [0, 0]])
          @rotate_switch.on = @selected.template.can_rotate
          cell.accessoryView = @rotate_switch
          @rotate_switch.addTarget(self,action:'rotate_switch_changed', forControlEvents:UIControlEventValueChanged)
          if @selected.template.stuck
            cell.hidden = true
          end

          if @selected.template.identifier == Constants::SCENE_TOY_IDENTIFIER
            cell.hidden = true
          end

        when 1
          cell.text = Language::STUCK
          @stuck_switch = UISwitch.alloc.initWithFrame([[95, 95], [0, 0]])
          @stuck_switch.on = @selected.template.stuck
          cell.accessoryView = @stuck_switch
          @stuck_switch.addTarget(self,action:'stuck_switch_changed', forControlEvents:UIControlEventValueChanged)

          if @selected.template.identifier == Constants::SCENE_TOY_IDENTIFIER
            cell.hidden = true
          end

        when 2
          cell.text = Language::ALWAYS_TRAVELS_FORWARD
          @travel_switch = UISwitch.alloc.initWithFrame([[95, 95], [0, 0]])
          @travel_switch.on = @selected.template.always_travels_forward
          cell.accessoryView = @travel_switch
          @travel_switch.addTarget(self,action:'travel_switch_changed', forControlEvents:UIControlEventValueChanged)

          if @selected.template.identifier == Constants::SCENE_TOY_IDENTIFIER
            cell.hidden = true
          end

        when 3
          #show 4 way switch for direction
          cell.text = Language::FRONT
          cell.accessoryView = frontDirectionControl(CGRectMake(0,0,0,0))
          if not @selected.template.always_travels_forward
            cell.hidden = true
          end

          if @selected.template.identifier == Constants::SCENE_TOY_IDENTIFIER
            cell.hidden = true
          end

        when 4
          cell.text = 'Affected by Gravity'
          @gravity_switch = UISwitch.alloc.initWithFrame([[95, 95], [0, 0]])
          @gravity_switch.on = @selected.template.gravity
          cell.accessoryView = @gravity_switch
          @gravity_switch.addTarget(self,action:'gravity_switch_changed', forControlEvents:UIControlEventValueChanged)

          if @selected.template.identifier == Constants::SCENE_TOY_IDENTIFIER
            cell.hidden = true
          end

      end
      cell

    else
      item = index_path.row
      @reuseIdentifier ||= "cell"
      action_cell = @table_view.dequeueReusableCellWithIdentifier(@reuseIdentifier)
      action_cell ||= ActionCell.alloc.initWithStyle(UITableViewCellStyleValue1, reuseIdentifier: @reuseIdentifier)

      action_cell.selectionStyle = UITableViewCellSelectionStyleNone
      action = @toy_actions[item]

      #p "action = #{action.to_s}"

      #action image
      case action[:action_type]
        when :collision
          action_cell.action_text = Language::COLLISION
          action_cell.action_image = UIImage.imageNamed("collision.png")
          #set object to be the toy image of the identifier in actionparam
          @state.toys.each do |toy|
            if toy.identifier == action[:action_param]
              action_cell.action_image = drawToy(toy)
              break
            end
          end

        when :timer
          action_cell.action_text = Language::REPEAT
          action_cell.action_image = drawText(action[:action_param][0].to_s.rjust(2, "0") + 's' , inImage:UIImage.imageNamed("empty.png"), withFontName:'Helvetica' )
        when :button
          action_cell.action_text = Language::TOUCH
          action_cell.action_image = UIImage.imageNamed(action[:action_param]+ ".png")
        when :score_reaches
          action_cell.action_text = Language::SCORE_REACHES
          action_cell.action_image = drawText(action[:action_param][0].to_s.rjust(2, "0"), inImage:UIImage.imageNamed("empty.png"), withFontName:'Helvetica' )
        when :shake
          action_cell.action_text = Language::SHAKE
          action_cell.action_image = UIImage.imageNamed(action[:action_type]+".png")
        when :when_created
          action_cell.action_text = Language::WHEN_CREATED
          action_cell.action_image = drawText(action[:action_param][0].to_s.rjust(2, "0") + 's' , inImage:UIImage.imageNamed(action[:action_type]+".png"), withFontName:'Helvetica', 15 )
        when :loud_noise
          action_cell.action_text = Language::LOUD_NOISE
          action_cell.action_image = UIImage.imageNamed(action[:action_type]+".png")
        when :toy_touch
          action_cell.action_text = Language::TOY_TOUCH
          action_cell.action_image = UIImage.imageNamed(action[:action_type]+".png")
        when :receive_message
          action_cell.action_text = Language::RECEIVE_MESSAGE
          action_cell.action_image = drawMessageSendDirection(CGPointMake(0, -75000), inImage:UIImage.imageNamed(action[:action_type]+".png"), action[:action_param].to_s)

          #action_cell.action_image = UIImage.imageNamed(action[:action_type]+".png")
        else
          action_cell.action_text = :unknown
      end
      action_cell.effect_image = UIImage.imageNamed(action[:effect_type]+".png")
      action_cell.sound_button = nil

      case action[:effect_type]
        when :apply_force
          #draw arrow in direction
          action_cell.effect_text = Language::FORCE
          forceImage = drawForce(action[:effect_param], inImage:UIImage.imageNamed("empty.png") )
          action_cell.effect_image = forceImage
        when :explosion
          #draw circle with size
          action_cell.effect_text = Language::EXPLOSION
          expImage = drawExplosion(action[:effect_param], inImage:UIImage.imageNamed("empty.png") )
          action_cell.effect_image = expImage
        when :apply_torque
          #draw arrow with direction in circle
          action_cell.effect_text = Language::ROTATION
          rotImage = drawRotation(action[:effect_param], inImage:UIImage.imageNamed("empty.png") )
          action_cell.effect_image = rotImage
        when :create_new_toy
          #draw toy
          action_cell.effect_text = Language::CREATE_NEW_TOY
          #set object to be the toy image of the identifier in actionparam
          @state.toys.each do |toy|
            if toy.identifier == action[:effect_param][:id]
              action_cell.effect_image = drawToy(toy)
              break
            end
          end

        when :delete_effect
          action_cell.effect_text = Language::DELETE
          #nothing
        when :score_adder
          #show how score is changed
          action_cell.effect_text = Language::SCORE_ADDER
          text = action[:effect_param][0].to_s.rjust(2, "0")
          case action[:effect_param][1]
            when 'set'
              text.insert(0,'=')
            when 'add'
              text.insert(0,'+')
            when 'subtract'
              text.insert(0,'-')
            else
          end
          action_cell.effect_image = drawText(text, inImage:UIImage.imageNamed("empty.png"), withFontName:'Helvetica')
        when :play_sound
          action_cell.effect_text = Language::PLAY_SOUND
          #show sound name? button to play sound?
          button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
          button.setFrame((action_cell.effect_image_view.frame))
          #button.setTitle('Play', forState: UIControlStateNormal)
          button.addTarget(self,action:'play_sound_file:', forControlEvents:UIControlEventTouchUpInside)
          action_cell.sound_button = button

        when :text_bubble
          action_cell.effect_text = Language::TEXT_BUBBLE
          button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
          button.setFrame((action_cell.effect_image_view.frame))
          button.addTarget(self,action:'showParameter:', forControlEvents:UIControlEventTouchUpInside)
          action_cell.sound_button = button

        when :send_message
          action_cell.effect_text = Language::SEND_MESSAGE
          #button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
          #button.setFrame((action_cell.effect_image_view.frame))
          #button.addTarget(self,action:'showParameter:', forControlEvents:UIControlEventTouchUpInside)
          #action_cell.sound_button = button
          action_cell.effect_image = drawMessageSendDirection(CGPointMake(0, 75000), inImage:UIImage.imageNamed(action[:effect_type]+".png"), action[:effect_param].to_s)
        when :scene_shift
          action_cell.effect_text = Language::SCENE_SHIFT
          @state.scenes.each do |scene|
            if scene.identifier == action[:effect_param]
              action_cell.effect_image = scene.image
              break
            end
          end
        when :move_towards
          action_cell.effect_text = Language::MOVE_TOWARDS_OTHERS
          @state.toys.each do |toy|
            if toy.identifier == action[:effect_param]
              action_cell.effect_image = drawToy(toy)
              break
            end
          end
        when :move_away
          action_cell.effect_text = Language::MOVE_AWAY_OTHERS
          @state.toys.each do |toy|
            if toy.identifier == action[:effect_param]
              action_cell.effect_image = drawToy(toy)
              break
            end
          end
        else
          action_cell.action_text = :unknown
      end
      action_cell
    end
  end

  def select
    p "select toy to edit now"
    @delegate.edit_selected(@selected)
  end

  def showParameter(sender)
    #p "show text bubble"
    buttonPosition = sender.convertPoint(CGPointZero, toView:@table_view)
    indexPath = @table_view.indexPathForRowAtPoint(buttonPosition)
    if indexPath != nil
      text = @toy_actions[indexPath.row][:effect_param]
      #puts('show text - ' + text)
      alert = UIAlertView.alloc.initWithTitle("Parameter: ", message:text, delegate:self, cancelButtonTitle: "OK", otherButtonTitles: nil)
      alert.show
    end
  end

  def play_sound_file(sender)
    buttonPosition = sender.convertPoint(CGPointZero, toView:@table_view)
    indexPath = @table_view.indexPathForRowAtPoint(buttonPosition)
    if indexPath != nil
      name = @toy_actions[indexPath.row][:effect_param]
      puts('play sound - '+name)

      local_file = NSURL.fileURLWithPath(File.join(NSBundle.mainBundle.resourcePath, name))
      @player = AVPlayer.alloc.initWithURL(local_file)
      @player.play
    end

  end

  def numberOfSectionsInTableView(tv)
    2
  end

  # to draw force applied on the toys.
  def drawMessageSendDirection(vector, inImage:image, message = "clear")

    if message == "black"
      label_colour = UIColor.blackColor
    elsif message == "red"
      label_colour = UIColor.redColor
    elsif message ==  "blue"
      label_colour = UIColor.blueColor
    elsif message == "green"
      label_colour = UIColor.greenColor
    elsif message ==  "cyan"
      label_colour = UIColor.cyanColor
    elsif message ==  "yellow"
      label_colour = UIColor.yellowColor
    elsif message ==  "orange"
      label_colour = UIColor.orangeColor
    elsif message ==  "purple"
      label_colour = UIColor.purpleColor
    elsif message ==  "brown"
      label_colour = UIColor.brownColor
    elsif message ==  "clear"
      label_colour = UIColor.clearColor
    elsif message ==  "white"
      label_colour = UIColor.whiteColor
    end

    UIGraphicsBeginImageContext(image.size)
    image.drawInRect(CGRectMake(0,0,image.size.width,image.size.height))
    context = UIGraphicsGetCurrentContext()
    draw_force_arrow(context,CGPointMake(((-vector.x+500*250)/250000)*image.size.width, ((vector.y+500*250)/250000)*image.size.height),CGPointMake(((vector.x+500*250)/250000)*image.size.width, ((-vector.y+500*250)/250000)*image.size.height), label_colour)
    newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    newImage
  end

  # to draw force applied on the toys.
  def drawForce(vector, inImage:image)
    UIGraphicsBeginImageContext(image.size)
    image.drawInRect(CGRectMake(0,0,image.size.width,image.size.height))
    context = UIGraphicsGetCurrentContext()

    # max  x and y 500?
    # Minh comments: vector magnitude is found to be very large, say 250000
    # why?

    if vector.x.abs > 0 || vector.y.abs > 0
      p "vector #{vector.x}, #{vector.y}"
      draw_force_arrow(context,CGPointMake(((-vector.x+500*250)/250000)*image.size.width, ((vector.y+500*250)/250000)*image.size.height),CGPointMake(((vector.x+500*250)/250000)*image.size.width, ((-vector.y+500*250)/250000)*image.size.height))
    else
      p "random #{vector.x}, #{vector.y}"
      # draw a random force
      (-1..1).each do |i|
        (-1..1).each do |j|
          if (i == j || i == -j) && (i != 0)
            vector = CGPointMake(100000*i, 100000*j)
            #puts "draw vector #{vector}"
            draw_force_arrow(context,CGPointMake(image.size.width/2, image.size.height/2),CGPointMake(((vector.x+500*250)/250000)*image.size.width, ((-vector.y+500*250)/250000)*image.size.height))
          end
        end
      end
    end


    newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    newImage
  end

  # draw red circle for explosion
  def drawExplosion(magnitude, inImage:image)
    UIGraphicsBeginImageContext(image.size)
    image.drawInRect(CGRectMake(0,0,image.size.width,image.size.height))

    # Minh, redraw explosion for a better representation
    ratio = magnitude/30000
    if ratio < 0.4
      ratio = 0.4
    elsif ratio > 1
      ratio = 1
    end
    explosionImage = UIImage.imageNamed("fire_explosion.png")
    explosionImage.drawInRect(CGRectMake(image.size.width*(1.0-ratio)/2.0,image.size.height*(1.0-ratio)/2.0,image.size.width*ratio,image.size.height*ratio))

    context = UIGraphicsGetCurrentContext()

    # max  x and y 500?
    #(1..100).each do |i|

    #end
    #draw_force_circle(context,CGPointMake(image.size.width/2, image.size.height/2),(magnitude/52000)*image.size.width/2)

    newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    newImage
  end

  # draw arrow for rotation
  def drawRotation(radians, inImage:image)

    p "radian = #{radians}"
    if radians == Constants::RANDOM_HASH_KEY
      p "random added"
      radians = rand(Math::PI) - (Math::PI / 2.0)
    end
    #puts "rotation draw = #{radians}"

    #radians between -2pi and +2pi, -ve = clockwise
    UIGraphicsBeginImageContext(image.size)
    image.drawInRect(CGRectMake(0,0,image.size.width,image.size.height))

    context = UIGraphicsGetCurrentContext()
    radius = image.size.width/4

    UIColor.redColor.set
    if(radians < 0)
      CGContextAddArc(context, image.size.width/2, image.size.height/2, radius, Math::PI, Math::PI-2*radians/3, 0)
    else
      CGContextAddArc(context, image.size.width/2, image.size.height/2, radius, Math::PI, Math::PI-2*radians/3, 1)
    end
    CGContextSetLineWidth(context, 8)
    CGContextStrokePath(context)

    draw_rotate_circle_arrow(context, CGPointMake(image.size.width/2,image.size.height/2), radius, +1*(Math::PI-2*radians/3), radians < 0)

    newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    newImage

  end

  def draw_rotate_circle_arrow(context, center, length, angle, clockwise)

    p "length = #{length}, angle = #{angle}, clockwise = #{clockwise}"

    #angle = 0

    arrow_points = []
    if clockwise
      arrow_points << CGPointMake(- 15, 0) << CGPointMake(0, 18.75)
      arrow_points << CGPointMake(15, 0)
    else
      arrow_points << CGPointMake(- 15, 0) << CGPointMake(0, -18.75)
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

  def draw_force_arrow(context, start, finish, colour = UIColor.redColor)

    CGContextSetLineWidth(context, 8)
    arrow_size = 9

    dx = finish.x - start.x
    dy = finish.y - start.y
    combined = dx.abs + dy.abs

    # Just to make the arrow shown nicely when the force is too small, we dont want just a simple triangle.
    if combined < 15.0
      dx = dx * 15.0/combined
      dy = dy * 15.0/combined
    end

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
    CGContextSetFillColorWithColor(context, colour.CGColor)
    #CGContextDrawPath(context, KCGPathStroke) #KCGPathFill
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

  def frontDirectionControl(frame)
    @frontDirectionControl = UISegmentedControl.alloc.initWithFrame(frame)
    @frontDirectionControl.segmentedControlStyle = UISegmentedControlStyleBar
    @frontDirectionControl.insertSegmentWithTitle('Left', atIndex: 0, animated: false)
    @frontDirectionControl.insertSegmentWithTitle('Up', atIndex: 1, animated: false)
    @frontDirectionControl.insertSegmentWithTitle('Right', atIndex: 2, animated: false)
    @frontDirectionControl.insertSegmentWithTitle('Down', atIndex: 3, animated: false)
    @frontDirectionControl.sizeToFit
    @frontDirectionControl.selectedSegmentIndex = @selected.template.front
    @frontDirectionControl.addTarget(self, action: 'front_direction_changed', forControlEvents: UIControlEventValueChanged)
    @frontDirectionControl
  end

  def front_direction_changed
    @selected.template.front = @frontDirectionControl.selectedSegmentIndex
  end

  def stuck_switch_changed
    @selected.template.stuck = @stuck_switch.on?
    @table_view.beginUpdates
    @table_view.endUpdates
    @table_view.cellForRowAtIndexPath(NSIndexPath.indexPathForRow(0, inSection:0)).hidden = @stuck_switch.on?
  end

  def gravity_switch_changed
    @selected.template.gravity = @gravity_switch.on?
    @table_view.beginUpdates
    @table_view.endUpdates
  end

  def rotate_switch_changed
    @selected.template.can_rotate = @rotate_switch.on?
  end

  def travel_switch_changed
    @selected.template.always_travels_forward = @travel_switch.on?
    @table_view.beginUpdates
    @table_view.endUpdates
    @table_view.cellForRowAtIndexPath(NSIndexPath.indexPathForRow(3, inSection:0)).hidden = (not @travel_switch.on?)
  end

  def tableView(tv,  editingStyleForRowAtIndexPath: index)
    if index.section == 0
      UITableViewCellEditingStyleNone
    else
      UITableViewCellEditingStyleDelete
    end
  end

  def tableView(tv, shouldIndentWhileEditingRowAtIndexPath: index)
    if index.section == 0
      false
    else
      true
    end
  end

  def tableView(tv, viewForHeaderInSection:section)
    if section == 0
      h_view = UIView.alloc.initWithFrame(CGRectMake(0, 0, tv.frame.size.width, 55))
      h_view.backgroundColor = Constants::LIGHT_GRAY
      #title
      @p_title = UILabel.alloc.initWithFrame([[80,5],[WIDTH-5,50]])

      if @selected.template.identifier != Constants::SCENE_TOY_IDENTIFIER
        @p_title.setText("<<<< Touch toy to edit")
        #@p_title.setText("ID: "+@selected.template.identifier)
      else
        @p_title.setText("")
      end

      # p "image = #{@selected.template.image}"
      # imageView = UIImageView.alloc.initWithFrame(CGRectMake(10,0,50,50))
      # imageView.image = @selected.template.image

      imageViewButton = UIButton.buttonWithType(UIButtonTypeCustom)
      imageViewButton.setImage(@selected.template.image, forState: UIControlStateNormal)

      imageViewButton.sizeToFit
      imageViewButton.frame = CGRectMake(10,0,70,50)
      imageViewButton.addTarget(self, action: 'select', forControlEvents: UIControlEventTouchUpInside)
      #super_view.addSubview(button)


      #@p_title.addSubview(@selected.template.image)


      @p_title.setFont(UIFont.boldSystemFontOfSize(18))

      if @selected.template.identifier != Constants::SCENE_TOY_IDENTIFIER
        h_view.addSubview(imageViewButton)
        h_view.addSubview(@p_title)
      end



      #title separator
      separator = CALayer.layer
      separator.frame = CGRectMake(5, 55, WIDTH, 1.0)
      separator.backgroundColor = UIColor.colorWithWhite(0.8, alpha:1.0).CGColor
      h_view.layer.addSublayer(separator)

      h_view
    else
      h_view = UIView.alloc.initWithFrame(CGRectMake(0, 0, tv.frame.size.width, 50))
      h_view.backgroundColor = Constants::LIGHT_GRAY

      #title
      @a_title = UILabel.alloc.initWithFrame([[10,5],[WIDTH-5,20]])
      @a_title.setText(Language::ACTIONS)
      @a_title.setFont(UIFont.boldSystemFontOfSize(18))
      h_view.addSubview(@a_title)

      #title separator
      separator = CALayer.layer
      separator.frame = CGRectMake(5, 30, WIDTH, 1.0)
      separator.backgroundColor = UIColor.colorWithWhite(0.8, alpha:1.0).CGColor
      h_view.layer.addSublayer(separator)

      #labels
      @trigger_label = UILabel.alloc.initWithFrame([[0,30],[WIDTH/2,20]])
      @trigger_label.setText(Language::TRIGGER)
      @trigger_label.setFont(UIFont.boldSystemFontOfSize(16))
      @trigger_label.textAlignment = UITextAlignmentCenter
      h_view.addSubview(@trigger_label)
      #effect label
      @effect_label = UILabel.alloc.initWithFrame([[WIDTH/2,30],[WIDTH/2,20]])
      @effect_label.setText(Language::EFFECT)
      @effect_label.setFont(UIFont.boldSystemFontOfSize(16))
      @effect_label.textAlignment = UITextAlignmentCenter
      h_view.addSubview(@effect_label)

      h_view
    end
  end

  def tableView(tv, heightForHeaderInSection:section)
    if section == 0
      if @selected.template.identifier != Constants::SCENE_TOY_IDENTIFIER
        55
      else
        1
      end
    else
      60
    end
  end
end