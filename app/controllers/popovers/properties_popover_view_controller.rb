class PropertiesPopoverViewController < UIViewController

    attr_writer :delegate, :selected, :scene_creator_view_controller

    PROPERTIES = {Can_Rotate: 'boolean', Stuck: 'boolean', Always_Travels_Forward:'boolean', Front: 'other'}

    LITTLE_GAP = 10
    BIG_GAP = 40
    WIDTH = 300
    MAX_HEIGHT = 500

    def loadView
      # Do not call super.
      self.view = UIView.alloc.initWithFrame([[0, 0], [WIDTH, 40]])
      view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)

      #back button
      @back_button = UIButton.buttonWithType(UIButtonTypeCustom)
      @back_button.setImage(UIImage.imageNamed(:back_arrow), forState: UIControlStateNormal)
      @back_button.frame = [[5, 5], [20,20]]
      @back_button.addTarget(self, action: 'back:', forControlEvents: UIControlEventTouchUpInside)
      view.addSubview(@back_button)

      @margin = @back_button.frame.size.width

      #title
      @title = UILabel.alloc.initWithFrame([[@margin+5,5],[WIDTH-@margin-5,20]])
      @title.setText('Properties')
      @title.setBackgroundColor(UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0))
      @title.setFont(UIFont.boldSystemFontOfSize(16))
      view.addSubview(@title)

      #title separator
      separator = CALayer.layer
      separator.frame = CGRectMake(5, 29.0, WIDTH, 1.0)
      separator.backgroundColor = UIColor.colorWithWhite(0.8, alpha:1.0).CGColor
      self.view.layer.addSublayer(separator)



      #make table view filled with all actions that have selected as the toy
      if PROPERTIES.size > 3
        tvHeight = 280
      else
        tvHeight = 80 * PROPERTIES.size
      end

      @table_view = UITableView.alloc.initWithFrame([[0, 45], [WIDTH, tvHeight]])
      @table_view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
      @table_view.dataSource = self
      @table_view.delegate = self
      @table_view.rowHeight = 80

      view.addSubview(@table_view)

      self.preferredContentSize = [WIDTH, @table_view.frame.origin.y+@table_view.frame.size.height+5]

    end

    # We need this to gain access to the toys.
    def state=(state)
      @state = state
    end

    # Back to the Select toy screen.
    def back(sender)
      @state.save
      @delegate.action_flow_back
    end

    # The methods to implement the UICollectionViewDataSource protocol.

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
end