class PropertyListViewController < UIViewController

  attr_writer :delegate, :selected, :scene_creator_view_controller

  PROPERTIES = {Can_Rotate: 'boolean', Stuck: 'boolean', Always_Travels_Forward:'boolean', Front: 'other'}

  LITTLE_GAP = 10
  BIG_GAP = 40
  WIDTH = 500

  def loadView
    # Do not call super.
    self.view = UIView.alloc.initWithFrame([[0, 0], [WIDTH, WIDTH]])
    view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
    # add toy view at top

    @selected.update_image
    toy_image = UIImageView.alloc.initWithImage(@selected.image)
    toy_image.frame = CGRectMake(WIDTH-200-75,LITTLE_GAP,200,100)
    toy_image.sizeToFit
    view.addSubview(toy_image)

    label = UILabel.alloc.initWithFrame([[toy_image.frame.origin.x-150, LITTLE_GAP],[150,95]])
    label.text = 'Properties of '
    label.textAlignment = UITextAlignmentRight
    view.addSubview(label)

    setup_button(:back, [LITTLE_GAP, LITTLE_GAP+100])

    #make table view filled with all actions that have selected as the toy
    @table_view = UITableView.alloc.initWithFrame([[@current_xpos, 120], [WIDTH - @current_xpos, WIDTH]])
    @table_view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
    @table_view.dataSource = self
    @table_view.delegate = self
    @table_view.rowHeight = 95
    view.addSubview(@table_view)

    @rotate_switch = nil
    @stuck_switch = nil


  end

  def viewDidAppear(animated)

    #add gesture recognizer to close window on tap outside
    @recognizer = UITapGestureRecognizer.alloc.initWithTarget(self, action: 'handleTapOutside:')
    @recognizer.cancelsTouchesInView = false
    @recognizer.numberOfTapsRequired = 1
    view.window.addGestureRecognizer(@recognizer)
  end

  def setup_button(image_name, position)
    button = UIButton.buttonWithType(UIButtonTypeCustom)
    button.setImage(UIImage.imageNamed(image_name), forState: UIControlStateNormal)
    button.sizeToFit
    button.frame = [position, button.frame.size]
    button.addTarget(self, action: image_name, forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(button)
    frame = button.frame
    @current_xpos = @left_margin = frame.origin.x + frame.size.width + BIG_GAP
    @right_margin = WIDTH - LITTLE_GAP
    @next_ypos = @current_ypos = LITTLE_GAP
  end

  # We need this to gain access to the toys.
  def state=(state)
    @state = state
  end

  # Back to the Select toy screen.
  def back
    self.view.window.removeGestureRecognizer(@recognizer)
    # self.view.window.removeGestureRecognizer(sender)
    @delegate.close_modal_view
  end

  def tableView(tv, numberOfRowsInSection: section)
    PROPERTIES.length
  end

  def tableView(tv, cellForRowAtIndexPath: index_path)
    index = index_path.row # ignore section as only one

    cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier: "default")

    type = PROPERTIES.values[index]
    name = PROPERTIES.keys[index]

    case type
      when 'boolean'
        switch = UISwitch.alloc.initWithFrame([[95, 95], [0, 0]])
        cell.accessoryView = switch
        case name
          when :Can_Rotate
            cell.text = 'Can Rotate'
            #check toy property and set init val
            switch.on = @selected.template.can_rotate
            @rotate_switch = switch
            @rotate_switch.addTarget(self,action:'rotate_switch_changed', forControlEvents:UIControlEventValueChanged)
          when :Stuck
            cell.text = 'Stuck'
            switch.on = @selected.template.stuck
            @stuck_switch = switch
            @stuck_switch.addTarget(self,action:'stuck_switch_changed', forControlEvents:UIControlEventValueChanged)
          when :Always_Travels_Forward
            cell.text = 'Always travels forward'
            switch.on = @selected.template.always_travels_forward
            @travel_switch = switch
            @travel_switch.addTarget(self,action:'travel_switch_changed', forControlEvents:UIControlEventValueChanged)

        end
      when 'other'
        case name
          when :Front
            #show 4 way switch for direction
            cell.text = 'Front Direction'
            cell.accessoryView = frontDirectionControl
        end
    end

    cell
  end

  def frontDirectionControl
      @frontDirectionControl = UISegmentedControl.alloc.initWithFrame( CGRectZero)
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

  def tableView(tableView, titleForHeaderInSection:section)
    return "Properties"
  end

  def front_direction_changed
    @selected.template.front = @frontDirectionControl.selectedSegmentIndex
  end

  def stuck_switch_changed
    #set template property
    @selected.template.stuck = @stuck_switch.on?
  end

  def rotate_switch_changed
    @selected.template.can_rotate = @rotate_switch.on?
  end

  def travel_switch_changed
    @selected.template.always_travels_forward = @travel_switch.on?
  end

  def handleTapOutside(sender)
    if (sender.state == UIGestureRecognizerStateEnded)
      location = sender.locationInView(nil) #Passing nil gives us coordinates in the window
      #Then we convert the tap's location into the local view's coordinate system, and test to see if it's in or outside. If outside, dismiss the view.
      if (!self.view.pointInside(self.view.convertPoint(location, fromView:self.view.window), withEvent:nil))
        # Remove the recognizer first so it's view.window is valid.
        self.view.window.removeGestureRecognizer(sender)
        self.dismissModalViewControllerAnimated(true)
      end
    end
  end
end