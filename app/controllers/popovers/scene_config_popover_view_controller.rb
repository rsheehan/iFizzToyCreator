class SceneConfigPopoverViewController < UIViewController

  attr_writer :delegate

  TOP=0
  BOTTOM=1
  LEFT=2
  RIGHT=3
  SWITCH_ON=1
  SWITCH_OFF=0

  def loadView
    super
    @width = 400
    @height = 400
    margin = 20
    buttonWidth = 160
    buttonHeight = 40
    # Do not call super.
    self.view = UIView.alloc.initWithFrame([[0, 0], [@width, @height]])
    view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 0.7)
    self.contentSizeForViewInPopover = CGSizeMake(@width, @height)

    #title*
    @title = UILabel.alloc.initWithFrame([[0,5],[@width-10,buttonHeight]])
    if @title_text
      @title.setText(@title_text)
    else
      @title.setText(Language::EXPLOSION)
    end
    @title.setBackgroundColor(Constants::LIGHT_BLUE_GRAY)
    @title.setFont(UIFont.boldSystemFontOfSize(18))
    @title.textAlignment = NSTextAlignmentCenter
    view.addSubview(@title)

    @table_view = UITableView.alloc.initWithFrame([[0, buttonHeight], [@width, @height - buttonHeight - margin]])
    @table_view.backgroundColor = Constants::LIGHT_GRAY
    @table_view.dataSource = self
    @table_view.delegate = self
    @table_view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight
    view.addSubview(@table_view)

    @image_picker = UIImagePickerController.alloc.init
    @image_picker.delegate = self
  end

  def setTitle(text)
    @title_text = text
    #resize frames
    if @title
      @title.setText(@title_text)
    end
  end

  def viewDidUnload
    @table_view = nil
  end

  # Required for TableView datasource protocol
  # Sets the number of sections for the tableView
  def numberOfSectionsInTableView(tableView)
    result = 0
    if (tableView == @table_view)
      result = 1
    end
    result
  end

  # responding to user interaction
  def tableView(tableView, didSelectRowAtIndexPath:indexPath)
    puts "Section: #{indexPath.section}, Cell: #{indexPath.row} is selected"
  end

  # Sets the number of rows in each section
  def tableView(tableView, numberOfRowsInSection:section)
    result = 0
    if(tableView == @table_view)
      result = 7
    end
    result
  end

  # Modifies each cell
  def tableView(tableView, cellForRowAtIndexPath:index_path)
    if index_path.section == 0
      cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier: "default")
      #puts "Cell: " + cell.to_s
      cell.font = UIFont.systemFontOfSize(16)
      position = index_path.row

      case position
        when 0
          cell.text = Language::GRAVITY
          @gravitySlider = UISlider.alloc.initWithFrame([[95, 95], [200.0, 23.0]])
          @gravitySlider.minimumValue = 0
          @gravitySlider.maximumValue = +5.0
          @gravitySlider.continuous = false
          #gravity is negative
          @gravitySlider.value = -1*@scene.gravity.dy
          cell.accessoryView = @gravitySlider
          @gravitySlider.addTarget(self,action:'gravitySliderChanged', forControlEvents:UIControlEventValueChanged)

        when 1
          cell.text = Language::WIND
          @windSlider = UISlider.alloc.initWithFrame([[95, 95], [200.0, 23.0]])
          @windSlider.minimumValue = -5.0
          @windSlider.maximumValue = +5.0
          @windSlider.continuous = false
          @windSlider.value = @scene.gravity.dx
          cell.accessoryView = @windSlider
          @windSlider.addTarget(self,action:'windSliderChanged', forControlEvents:UIControlEventValueChanged)

        when 2
          cell.text = Language::TOP_BOUNDARY
          @top_switch = UISwitch.alloc.initWithFrame([[95, 95], [0, 0]])
          @top_switch.on = @scene.boundaries[TOP]==SWITCH_ON
          cell.accessoryView = @top_switch
          @top_switch.addTarget(self,action:'top_switch_changed', forControlEvents:UIControlEventValueChanged)

        when 3
          cell.text = Language::BOTTOM_BOUNDARY
          @bottom_switch = UISwitch.alloc.initWithFrame([[95, 95], [0, 0]])
          @bottom_switch.on = @scene.boundaries[BOTTOM]==SWITCH_ON
          cell.accessoryView = @bottom_switch
          @bottom_switch.addTarget(self,action:'bottom_switch_changed', forControlEvents:UIControlEventValueChanged)

        when 4
          cell.text = Language::LEFT_BOUNDARY
          @left_switch = UISwitch.alloc.initWithFrame([[95, 95], [0, 0]])
          @left_switch.on = @scene.boundaries[LEFT]==SWITCH_ON
          cell.accessoryView = @left_switch
          @left_switch.addTarget(self,action:'left_switch_changed', forControlEvents:UIControlEventValueChanged)

        when 5
          cell.text = Language::RIGHT_BOUNDARY
          @right_switch = UISwitch.alloc.initWithFrame([[95, 95], [0, 0]])
          @right_switch.on = @scene.boundaries[RIGHT]==SWITCH_ON
          cell.accessoryView = @right_switch
          @right_switch.addTarget(self,action:'right_switch_changed', forControlEvents:UIControlEventValueChanged)

        when 6
          cell.text = Language::BACK_GROUND_IMAGE

          @browseButton = UIButton.buttonWithType(UIButtonTypeRoundedRect)
          @browseButton.frame = [[0, 0], [100, 37]]
          @browseButton.setTitle("Gallery", forState:UIControlStateNormal)

          @cameraButton = UIButton.buttonWithType(UIButtonTypeRoundedRect)
          @cameraButton.frame = [[70, 0], [100, 37]]
          @cameraButton.setTitle("Camera", forState:UIControlStateNormal)

          @clearButton = UIButton.buttonWithType(UIButtonTypeRoundedRect)
          @clearButton.frame = [[140, 0], [100, 37]]
          @clearButton.setTitle("Clear", forState:UIControlStateNormal)


          # add two button to the same cell
          buttonView = UIView.alloc.initWithFrame([[0,0],[200,37]])
          buttonView.addSubview(@browseButton)
          buttonView.addSubview(@cameraButton)
          buttonView.addSubview(@clearButton)
          cell.accessoryView = buttonView
          #cell.selectionStyle = UITableViewCellSelectionStyleNone
          #cell.userInteractionEnabled = false
          #cell.backgroundColor = UIColor.grayColor
          @browseButton.addTarget(self,action:'browseButtonClicked', forControlEvents:UIControlEventTouchUpInside)
          @cameraButton.addTarget(self,action:'cameraButtonClicked', forControlEvents:UIControlEventTouchUpInside)
          @clearButton.addTarget(self,action:'clearButtonClicked', forControlEvents:UIControlEventTouchUpInside)
      end
      cell
    end
  end

  def browseButtonClicked
    @image_picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary
    presentModalViewController(@image_picker, animated: true)
  end

  def cameraButtonClicked
    @image_picker.sourceType = UIImagePickerControllerSourceTypeCamera
    presentModalViewController(@image_picker, animated: true)
  end

  def clearButtonClicked
    @delegate.setBackground(nil)
  end

  # UIImagePickerController Delegate Methods
  def imagePickerController(picker, didFinishPickingMediaWithInfo:info)
    mediaType = info.objectForKey(UIImagePickerControllerMediaType)
    if mediaType.isEqualToString(KUTTypeImage)
      the_image = info.objectForKey(UIImagePickerControllerOriginalImage)
      @table_view.reloadData
      @delegate.setBackground(the_image)
    end

    # shared app status bar hidden
    UIApplication.sharedApplication.setStatusBarHidden(true)
    picker.dismissModalViewControllerAnimated(true)
  end

  def imagePickerControllerDidCancel(picker)
    # shared app status bar hidden
    UIApplication.sharedApplication.setStatusBarHidden(true)
    picker.dismissModalViewControllerAnimated(true)
  end

  # change value of gravity
  def gravitySliderChanged
    @scene.gravity.dy = @gravitySlider.value * -1
    @table_view.reloadData
  end

  # change value of wind
  def windSliderChanged
    @scene.gravity.dx = @windSlider.value
    @table_view.reloadData
  end

  # change values of switches for boundaries
  def left_switch_changed
    if @left_switch.isOn
      @scene.boundaries[LEFT]=SWITCH_ON
    else
      @scene.boundaries[LEFT]=SWITCH_OFF
    end
    @table_view.reloadData
    @delegate.setBoundaries(@scene.boundaries)
  end
  def right_switch_changed
    if @right_switch.isOn
      @scene.boundaries[RIGHT]=SWITCH_ON
    else
      @scene.boundaries[RIGHT]=SWITCH_OFF
    end
    @table_view.reloadData
    @delegate.setBoundaries(@scene.boundaries)
  end
  def top_switch_changed
    #puts "top_switch_changed: #{@top_switch.isOn}"
    if @top_switch.isOn
      @scene.boundaries[TOP]=SWITCH_ON
    else
      @scene.boundaries[TOP]=SWITCH_OFF
    end
    @table_view.reloadData
    @delegate.setBoundaries(@scene.boundaries)
  end
  def bottom_switch_changed
    #puts "update play scene: #{@scene}"
    if @bottom_switch.isOn
      @scene.boundaries[BOTTOM]=SWITCH_ON
    else
      @scene.boundaries[BOTTOM]=SWITCH_OFF
    end
    @table_view.reloadData
    @delegate.setBoundaries(@scene.boundaries)
  end

  # We need this to gain access to the scene.
  def enterState(state)
    #puts "enter state"
    @state = state
    if @state.scenes.size > 0
      @scene = @state.scenes[@state.currentscene]
    end
  end

end