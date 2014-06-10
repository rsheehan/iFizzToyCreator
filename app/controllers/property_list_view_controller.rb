class PropertyListViewController < UIViewController

  attr_writer :delegate, :selected, :scene_creator_view_controller

  PROPERTIES = {Can_Rotate: 'boolean', Stuck: 'boolean'}

  LITTLE_GAP = 10
  BIG_GAP = 40
  WIDTH = 500

  def loadView
    # Do not call super.
    self.view = UIView.alloc.initWithFrame([[0, 0], [WIDTH, WIDTH]])
    view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
    setup_button(:back, [LITTLE_GAP, LITTLE_GAP])

    #make table view filled with all actions that have selected as the toy
    @table_view = UITableView.alloc.initWithFrame([[@current_xpos, 0], [WIDTH - @current_xpos, WIDTH+95]])
    @table_view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
    @table_view.dataSource = self
    @table_view.delegate = self
    @table_view.rowHeight = 95
    view.addSubview(@table_view)

    @rotate_switch = nil
    @stuck_switch = nil

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
    @delegate.close_modal_view(true)
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

        end
    end

    cell
  end

  def tableView(tableView, titleForHeaderInSection:section)
    return "Properties"
  end

  def stuck_switch_changed
    #set template property
    @selected.template.stuck = @stuck_switch.on?
  end

  def rotate_switch_changed
    @selected.template.can_rotate = @rotate_switch.on?
  end

end