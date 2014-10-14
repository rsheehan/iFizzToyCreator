class SceneConfigPopoverViewController < UIViewController

  attr_writer :delegate

  TOP=0
  BOTTOM=1
  LEFT=2
  RIGHT=3
  SWITCH_ON=1
  SWITCH_OFF=0

  SMALL_CELL_HEIGHT = 40
  IMAGE_CELL_HEIGHT = 140

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

    # Background images
    @backgroundImages = []    
    dirContents = NSFileManager.defaultManager.directoryContentsAtPath(Constants::BUNDLE_ROOT)
    dirContents.each do |fileName|
      if fileName.hasSuffix("bground.png") || fileName.hasSuffix("bground.jpg")
        puts "image  = #{fileName}"
        @backgroundImages << fileName
      end
    end

    @image_picker = UIImagePickerController.alloc.init
    @image_picker.delegate = self
  end

  def viewDidDisappear(animated)
    @delegate.save_scene
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
    @table_view.reloadData
    #puts "Section: #{indexPath.section}, Cell: #{indexPath.row} is #selected"
  end

  def tableView(tableView, commitEditingStyle:editingStyle, forRowAtIndexPath:indexPath)
    if indexPath.section == 0
      if (editingStyle == UITableViewCellEditingStyleDelete)
        if (indexPath.row < 100)
          #first remove this object from source

          indexToRemove = indexPath.row - 8
          
          pathToRemove = Constants::BUNDLE_ROOT + "/" + @backgroundImages[indexToRemove]
          p "need to remove #{pathToRemove}"
          File.delete(pathToRemove)

          @backgroundImages.removeObjectAtIndex(indexToRemove)

          # Then remove associated cell from table view
          tableView.deleteRowsAtIndexPaths(NSArray.arrayWithObject(indexPath), withRowAnimation:UITableViewRowAnimationLeft)
        end
      end
    end
  end

  # Sets the number of rows in each section
  def tableView(tableView, numberOfRowsInSection:section)
    result = 0
    if(tableView == @table_view)
      result = 8 + @backgroundImages.size 
    end
    result
  end

  def tableView(tableView, heightForRowAtIndexPath:index_path)
    position = index_path.row
    if position >=2 and position <=5
      return 0
    elsif(position == 6 or position >=8)
      return IMAGE_CELL_HEIGHT
    else
      return SMALL_CELL_HEIGHT
    end
  end

  def tableView(tableView,  canEditRowAtIndexPath: index_path)
    if index_path.row > 7
      return true
    else
      return false
    end
  end

  def tableView(tableView,  editingStyleForRowAtIndexPath: index)
    UITableViewCellEditingStyleDelete    
  end

  # Modifies each cell
  def tableView (tableView, cellForRowAtIndexPath:index_path)
    if index_path.section == 0
      cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier: "default")
      #puts "Cell: " + cell.to_s
      cell.font = UIFont.systemFontOfSize(16)
      position = index_path.row
      case position
        when 0
          cell.text = Language::GRAVITY     
          @gravitySlider = UISlider.alloc.initWithFrame([[0, 0], [150.0, 23.0]])
          @gravitySlider.minimumValue = 0
          @gravitySlider.maximumValue = +5.0
          @gravitySlider.continuous = false
          #gravity is negative
          @gravitySlider.value = -1*@scene.gravity.dy

          gravityView = UIView.alloc.initWithFrame([[0,0],[200,23]])

          @gravity_label_view = UILabel.alloc.initWithFrame([[150, 0], [50.0, 23.0]])
          @gravity_label_view.setTextAlignment(UITextAlignmentCenter)
          @gravity_label_view.text = (-1*@scene.gravity.dy).to_s

          gravityView.addSubview(@gravitySlider)
          gravityView.addSubview(@gravity_label_view)

          cell.accessoryView = gravityView
          @gravitySlider.addTarget(self,action:'gravitySliderChanged', forControlEvents:UIControlEventValueChanged)

        when 1
          cell.text = Language::WIND #<< @scene.gravity.dx
          @windSlider = UISlider.alloc.initWithFrame([[0, 0], [150.0, 23.0]])
          @windSlider.minimumValue = -5.0
          @windSlider.maximumValue = +5.0
          @windSlider.continuous = false
          @windSlider.value = @scene.gravity.dx

          @wind_label_view = UILabel.alloc.initWithFrame([[150, 0], [50.0, 23.0]])
          @wind_label_view.setTextAlignment(UITextAlignmentCenter)
          @wind_label_view.text = @scene.gravity.dx.to_s

          windView = UIView.alloc.initWithFrame([[0,0],[200,23]])

          windView.addSubview(@windSlider)
          windView.addSubview(@wind_label_view)

          cell.accessoryView = windView
          @windSlider.addTarget(self,action:'windSliderChanged', forControlEvents:UIControlEventValueChanged)

        when 2
          cell.text = Language::TOP_BOUNDARY
          @top_switch = UISwitch.alloc.initWithFrame([[95, 95], [0, 0]])
          @top_switch.on = @scene.boundaries[TOP]==SWITCH_ON
          cell.accessoryView = @top_switch
          @top_switch.addTarget(self,action:'top_switch_changed', forControlEvents:UIControlEventValueChanged)
          cell.hidden = true

        when 3
          cell.text = Language::BOTTOM_BOUNDARY
          @bottom_switch = UISwitch.alloc.initWithFrame([[95, 95], [0, 0]])
          @bottom_switch.on = @scene.boundaries[BOTTOM]==SWITCH_ON
          cell.accessoryView = @bottom_switch
          @bottom_switch.addTarget(self,action:'bottom_switch_changed', forControlEvents:UIControlEventValueChanged)
          cell.hidden = true

        when 4
          cell.text = Language::LEFT_BOUNDARY
          @left_switch = UISwitch.alloc.initWithFrame([[95, 95], [0, 0]])
          @left_switch.on = @scene.boundaries[LEFT]==SWITCH_ON
          cell.accessoryView = @left_switch
          @left_switch.addTarget(self,action:'left_switch_changed', forControlEvents:UIControlEventValueChanged)
          cell.hidden = true

        when 5
          cell.text = Language::RIGHT_BOUNDARY
          @right_switch = UISwitch.alloc.initWithFrame([[95, 95], [0, 0]])
          @right_switch.on = @scene.boundaries[RIGHT]==SWITCH_ON
          cell.accessoryView = @right_switch
          @right_switch.addTarget(self,action:'right_switch_changed', forControlEvents:UIControlEventValueChanged)
          cell.hidden = true

        when 6
          cell.text = :Boundary   
          boundaryWidth = 1.5*IMAGE_CELL_HEIGHT
          boundaryHeight = IMAGE_CELL_HEIGHT
          boundaryThickness = 35
          @boundaryOnColour = UIColor.redColor
          @boundaryOffColour = UIColor.clearColor

          @topBoundaryButton = UIButton.buttonWithType(UIButtonTypeRoundedRect)
          @topBoundaryButton.frame = [[0, 0], [boundaryWidth, boundaryThickness]]
          if @scene.boundaries[TOP]==SWITCH_ON
            @topBoundaryButton.backgroundColor = @boundaryOnColour
          else
            @topBoundaryButton.backgroundColor = @boundaryOffColour
          end              

          @bottomBoundaryButton = UIButton.buttonWithType(UIButtonTypeRoundedRect)
          @bottomBoundaryButton.frame = [[0, boundaryHeight - boundaryThickness], [boundaryWidth, boundaryThickness]]
          if @scene.boundaries[BOTTOM]==SWITCH_ON
            @bottomBoundaryButton.backgroundColor = @boundaryOnColour
          else
            @bottomBoundaryButton.backgroundColor = @boundaryOffColour
          end

          @leftBoundaryButton = UIButton.buttonWithType(UIButtonTypeRoundedRect)
          @leftBoundaryButton.frame = [[0, 0], [boundaryThickness, boundaryHeight]]
          if @scene.boundaries[LEFT]==SWITCH_ON
            @leftBoundaryButton.backgroundColor = @boundaryOnColour
          else
            @leftBoundaryButton.backgroundColor = @boundaryOffColour
          end

          @rightBoundaryButton = UIButton.buttonWithType(UIButtonTypeRoundedRect)
          @rightBoundaryButton.frame = [[boundaryWidth - boundaryThickness, 0], [boundaryThickness, boundaryHeight]]
          if @scene.boundaries[RIGHT]==SWITCH_ON
            @rightBoundaryButton.backgroundColor = @boundaryOnColour
          else
            @rightBoundaryButton.backgroundColor = @boundaryOffColour
          end

          # add four buttons to control boundary
          buttonBoundaryView = UIView.alloc.initWithFrame([[0,0],[boundaryWidth, boundaryHeight]]) 
          buttonBoundaryView.backgroundColor = SceneCreatorView::DEFAULT_SCENE_COLOUR

          @topBoundaryButton.addTarget(self,action:'topBorderClicked', forControlEvents:UIControlEventTouchUpInside)
          @bottomBoundaryButton.addTarget(self,action:'bottomBorderClicked', forControlEvents:UIControlEventTouchUpInside)
          @leftBoundaryButton.addTarget(self,action:'leftBorderClicked', forControlEvents:UIControlEventTouchUpInside)
          @rightBoundaryButton.addTarget(self,action:'rightBorderClicked', forControlEvents:UIControlEventTouchUpInside)

          buttonBoundaryView.addSubview(@topBoundaryButton)
          buttonBoundaryView.addSubview(@bottomBoundaryButton)
          buttonBoundaryView.addSubview(@leftBoundaryButton)
          buttonBoundaryView.addSubview(@rightBoundaryButton)

          cell.accessoryView = buttonBoundaryView

        when 7
          cell.text = Language::BACK_GROUND_IMAGE

          @cameraButton = UIButton.buttonWithType(UIButtonTypeRoundedRect)
          @cameraButton.frame = [[0, 0], [100, 37]]
          @cameraButton.setTitle("Camera", forState:UIControlStateNormal)

          @clearButton = UIButton.buttonWithType(UIButtonTypeRoundedRect)
          @clearButton.frame = [[100, 0], [100, 37]]
          @clearButton.setTitle("Clear", forState:UIControlStateNormal)

          # add two button to the same cell
          buttonView = UIView.alloc.initWithFrame([[0,0],[160,37]])       
          buttonView.addSubview(@cameraButton)
          buttonView.addSubview(@clearButton)
          cell.accessoryView = buttonView
         
          @cameraButton.addTarget(self,action:'cameraButtonClicked', forControlEvents:UIControlEventTouchUpInside)
          @clearButton.addTarget(self,action:'clearButtonClicked', forControlEvents:UIControlEventTouchUpInside)        
      end

      if position >= 8
        cell.text = "Camera \##{position-7}"
        imageNameAndLocation = Constants::BUNDLE_ROOT+"/"+@backgroundImages[position-8]
        @imageBackgroundButton = UIButton.buttonWithType(UIButtonTypeCustom)
        @imageBackgroundButton.setImage(UIImage.imageNamed(imageNameAndLocation), forState: UIControlStateNormal)
        @imageBackgroundButton.sizeToFit
        @imageBackgroundButton.frame = [ [0, 0], [IMAGE_CELL_HEIGHT, 0.8*IMAGE_CELL_HEIGHT]]
        @imageBackgroundButton.accessibilityLabel = imageNameAndLocation
        @imageBackgroundButton.addTarget(self, action: 'imageButtonClick:', forControlEvents: UIControlEventTouchUpInside)
        cell.accessoryView = @imageBackgroundButton

      end
      cell
    end
  end

  def imageButtonClick(sender)
    imageNameAndLocation = sender.accessibilityLabel
    the_image = UIImage.imageNamed(imageNameAndLocation)
    @delegate.setBackground(the_image) 
  end

  def topBorderClicked
    if @scene.boundaries[TOP]==SWITCH_ON
      @scene.boundaries[TOP]=SWITCH_OFF
    else
      @scene.boundaries[TOP]=SWITCH_ON
    end    
    @table_view.reloadData
    @delegate.setBoundaries(@scene.boundaries)
  end

  def bottomBorderClicked
    if @scene.boundaries[BOTTOM]==SWITCH_ON
      @scene.boundaries[BOTTOM]=SWITCH_OFF
    else
      @scene.boundaries[BOTTOM]=SWITCH_ON
    end    
    @table_view.reloadData
    @delegate.setBoundaries(@scene.boundaries)
  end

  def leftBorderClicked
    if @scene.boundaries[LEFT]==SWITCH_ON
      @scene.boundaries[LEFT]=SWITCH_OFF
    else
      @scene.boundaries[LEFT]=SWITCH_ON
    end    
    @table_view.reloadData
    @delegate.setBoundaries(@scene.boundaries)
  end

  def rightBorderClicked
    if @scene.boundaries[RIGHT]==SWITCH_ON
      @scene.boundaries[RIGHT]=SWITCH_OFF
    else
      @scene.boundaries[RIGHT]=SWITCH_ON
    end    
    @table_view.reloadData
    @delegate.setBoundaries(@scene.boundaries)
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

      timeStamp = Time.now.to_s.gsub! ' ', '_'
      file_name = Constants::BUNDLE_ROOT + "/" + timeStamp + "_bground.png"
      
      puts "Writing image to #{file_name}"
      writeData = UIImagePNGRepresentation(the_image)
      writeData.writeToFile(file_name, atomically: true)
      @backgroundImages = []    
      dirContents = NSFileManager.defaultManager.directoryContentsAtPath(Constants::BUNDLE_ROOT)
      dirContents.each do |fileName|
        if fileName.hasSuffix("bground.png") || fileName.hasSuffix("bground.jpg")
          puts "image  = #{fileName}"
          @backgroundImages << fileName
        end
      end
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
    @scene.gravity.dy = @gravitySlider.value.to_i * -1
    @delegate.setGravity(@gravitySlider.value.to_i * -1)
    @table_view.reloadData
  end

  # change value of wind
  def windSliderChanged
    @scene.gravity.dx = @windSlider.value.to_i
    @delegate.setWind(@windSlider.value.to_i)
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