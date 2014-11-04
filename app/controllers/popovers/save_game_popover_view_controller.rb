class SaveGamePopoverViewController < UIViewController
  attr_writer :delegate

  LITTLE_GAP = 10
  BIG_GAP = 40
  MAX_HEIGHT = 800

  def loadView
    p "load view"    

    @sceneIndex = 0
    @width = 450
    @height = 600
    @dataList = []
    # Do not call super.
    self.view = UIView.alloc.initWithFrame([[0, 0], [@width, 40]])
    view.backgroundColor =  Constants::LIGHT_BLUE_GRAY

    #back button
    @back_button = UIButton.buttonWithType(UIButtonTypeCustom)
    @back_button.setImage(UIImage.imageNamed(:back_arrow), forState: UIControlStateNormal)
    @back_button.frame = [[5, 5], [30,30]]
    view.addSubview(@back_button)

    @margin = @back_button.frame.size.width

    #title
    @title = UILabel.alloc.initWithFrame([[@margin+5,5],[@width-@margin-5,30]])
    @title.setText('My games')
    @title.setBackgroundColor(Constants::LIGHT_BLUE_GRAY)
    @title.setFont(UIFont.boldSystemFontOfSize(18))
    view.addSubview(@title)

    #title separator
    separator = CALayer.layer
    separator.frame = CGRectMake(5, 39.0, @width, 1.0)
    separator.backgroundColor = UIColor.colorWithWhite(0.8, alpha:1.0).CGColor
    self.view.layer.addSublayer(separator)
    

    @table_view = UITableView.alloc.initWithFrame([[0, 45], [@width, @height]])
    @table_view.backgroundColor =  Constants::LIGHT_BLUE_GRAY
    @table_view.dataSource = self
    @table_view.delegate = self
    @table_view.rowHeight = 45
    view.addSubview(@table_view)
    view.addSubview(@close_button)

    self.preferredContentSize = [@width, @table_view.frame.size.height+@table_view.frame.origin.y]
  end

  def viewWillAppear(animated)
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)
    @documents_path = paths.objectAtIndex(0) # Get the docs directory

    dirContents = NSFileManager.defaultManager.directoryContentsAtPath(@documents_path)
    dirContents.each do |fileName|
      if fileName.hasSuffix(".ifizz")
        @dataList << fileName
      end
    end    
  end

  def viewWillDisappear(animated)
    #@delegate.state.save
    @delegate.resume
  end

  def select_sound(sender)
    @player = nil
    #add extension on end
    text = sender.view.text.gsub(' ', '_')
    Constants::SOUND_NAMES.each do |sound|
      if sound.include? text
        @delegate.set_sound(sound)
      end
    end
  end

  def play_sound(sender)
    buttonPosition = sender.convertPoint(CGPointZero, toView:@table_view)
    indexPath = @table_view.indexPathForRowAtPoint(buttonPosition)
    if indexPath != nil
      name = Constants::SOUND_NAMES[indexPath.row]
      puts('play sound - '+name)

      local_file = NSURL.fileURLWithPath(File.join(NSBundle.mainBundle.resourcePath, name))
      @player = AVPlayer.alloc.initWithURL(local_file)
      @player.play
    end
  end

  # Back to the action adder to make a new one.
  def back(sender)
    @player = nil
    @delegate.action_flow_back
  end

  def tableView(tv, numberOfRowsInSection: section)
    if section == 0
      5
    else
      @dataList.size
    end    
  end

  def numberOfSectionsInTableView(tv)
    2
  end

  def tableView(tv, heightForHeaderInSection:section)
    if section == 0
      30
    else
      30
    end
  end

  def tableView(tableView, heightForRowAtIndexPath:index_path)
    if index_path.section == 0
      position = index_path.row
      if position == 1
        return 80
      elsif position == 2
          return 140
      else
        return 40
      end
    else
      return 40
    end
  end

  def tableView(tv,  editingStyleForRowAtIndexPath: index)
    if index.section == 0
      UITableViewCellEditingStyleNone
    else
      UITableViewCellEditingStyleDelete
    end
  end

  # The methods to implement the UICollectionViewDataSource protocol.
  def tableView(tv, commitEditingStyle: style, forRowAtIndexPath: index_path)
    #if index_path.section != 0
    tv.beginUpdates
      tv.deleteRowsAtIndexPaths([index_path], withRowAnimation: UITableViewRowAnimationAutomatic)
      item = index_path.row
      File.delete(@documents_path.stringByAppendingPathComponent(@dataList[item].to_s))
      @dataList.delete_at(item)     
      p "delete #{item}"    
      tv.endUpdates  
    #end
  end


  def tableView(tv, viewForHeaderInSection:section)
    if section == 0
      h_view = UIView.alloc.initWithFrame(CGRectMake(0, 0, tv.frame.size.width, 30))
      h_view.backgroundColor = Constants::LIGHT_GRAY
      #title
      @p_title = UILabel.alloc.initWithFrame([[10,5],[@width-5,20]])

      @p_title.setText("Current game:")

      @p_title.setFont(UIFont.boldSystemFontOfSize(18))
      
      h_view.addSubview(@p_title)


      #title separator
      separator = CALayer.layer
      separator.frame = CGRectMake(5, 30, @width, 1.0)
      separator.backgroundColor = UIColor.colorWithWhite(0.8, alpha:1.0).CGColor
      h_view.layer.addSublayer(separator)

      h_view
    else
      h_view = UIView.alloc.initWithFrame(CGRectMake(0, 0, tv.frame.size.width, 50))
      h_view.backgroundColor = Constants::LIGHT_GRAY

      #title
      @a_title = UILabel.alloc.initWithFrame([[10,5],[@width-5,20]])
      @a_title.setText("My saved games:")
      @a_title.setFont(UIFont.boldSystemFontOfSize(18))
      h_view.addSubview(@a_title)

      #title separator
      separator = CALayer.layer
      separator.frame = CGRectMake(5, 30, @width, 1.0)
      separator.backgroundColor = UIColor.colorWithWhite(0.8, alpha:1.0).CGColor
      h_view.layer.addSublayer(separator)      

      h_view
    end
  end

  def changeScene(sender)
    @sceneIndex = (@sceneIndex + 1) % @delegate.state.scenes.size
    @table_view.reloadData
    p "change scene"
  end

  def tableView(tv, cellForRowAtIndexPath: index_path)
    if index_path.section == 0
      position = index_path.row
      case position
        when 0
          cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier: "default")
          name = "Name:"
          cell.textLabel.text = name

          @my_text_field = UITextField.alloc.initWithFrame([[0,0],[200.0,31.0]])
          @my_text_field.borderStyle = UITextBorderStyleRoundedRect
          @my_text_field.textAlignment = UITextAlignmentLeft
          @my_text_field.text = @delegate.state.game_info.name
          cell.accessoryView = @my_text_field
        when 1
          cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier: "default")
          name = "Description:"
          cell.textLabel.text = name

          @my_text_view = UITextView.alloc.initWithFrame([[0,0],[200.0,75.0]])
          #@my_text_view.borderStyle = UITextBorderStyleRoundedRect
          @my_text_view.text = @delegate.state.game_info.description
          @my_text_view.font = UIFont.systemFontOfSize(16)
          cell.accessoryView = @my_text_view

        when 2
          cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier: "default")
          name = "Scenes (tap to change):"
          cell.textLabel.text = name

          tapGesture = UITapGestureRecognizer.alloc.initWithTarget(self, action:'changeScene:')
          cell.addGestureRecognizer(tapGesture)

          scenes = @delegate.state.scenes
          scenes_size = scenes.size
          if scenes_size > 0
            randomSceneIndex = @sceneIndex #rand(scenes_size).to_i
            scenes[randomSceneIndex].update_image
            @my_image_view = UIImageView.alloc.initWithFrame([[0,0],[200.0,140.0]])
            @my_image_view.contentMode = UIViewContentModeScaleAspectFit
            @my_image_view.image = scenes[randomSceneIndex].image
            @my_image_view.center = self.view.center
            cell.accessoryView = @my_image_view
          end

        # when 3
        #   cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier: "default")
        #   name = "Toy 1:"
        #   cell.textLabel.text = name

        #   toys = @delegate.state.toys
        #   toys_size = toys.size
        #   if toys_size > 0
        #     randomToyIndex = 0#rand(toys_size).to_i
        #     toys[randomToyIndex].update_image
        #     @toy_image_view = UIImageView.alloc.initWithFrame([[0,0],[200.0,140.0]])
        #     @toy_image_view.contentMode = UIViewContentModeScaleAspectFit
        #     @toy_image_view.image = toys[randomToyIndex].image
        #     @toy_image_view.center = self.view.center
        #     cell.accessoryView = @toy_image_view
        #   end

        when 3
          cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier: "default")
          name = "Apply changes:"
          cell.textLabel.text = name
          cell.textLabel.userInteractionEnabled = true

          saveButton = UIButton.buttonWithType(UIButtonTypeRoundedRect)
          saveButton.setFrame([[50, 0], [50,35]])
          saveButton.setTitle('Save', forState: UIControlStateNormal)

          shareButton = UIButton.buttonWithType(UIButtonTypeRoundedRect)
          shareButton.setFrame([[130, 0], [70,35]])
          shareButton.setTitle('New', forState: UIControlStateNormal)

          buttonView = UIView.alloc.initWithFrame([[0,0],[200,35]]) 
          buttonView.addSubview(saveButton)
          buttonView.addSubview(shareButton)

          saveButton.addTarget(self,action:'Save', forControlEvents:UIControlEventTouchUpInside)
          shareButton.addTarget(self,action:'New', forControlEvents:UIControlEventTouchUpInside)

          cell.accessoryView = buttonView
        when 4
          cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier: "default")
          name = "Upload to the Internet:"
          cell.textLabel.text = name
          shareButton = UIButton.buttonWithType(UIButtonTypeRoundedRect)
          shareButton.setFrame([[130, 0], [70,35]])
          shareButton.setTitle('Share', forState: UIControlStateNormal)

          buttonView = UIView.alloc.initWithFrame([[0,0],[200,35]]) 
          
          buttonView.addSubview(shareButton)
         
          shareButton.addTarget(self,action:'Share', forControlEvents:UIControlEventTouchUpInside)

          cell.accessoryView = buttonView
      end
    else
      index = index_path.row 

      cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier: "default")

      name = @dataList[index]

      cell.textLabel.text = name

      cell.textLabel.userInteractionEnabled = true
      tapGesture = UITapGestureRecognizer.alloc.initWithTarget(self, action:'select_sound:')
      cell.textLabel.addGestureRecognizer(tapGesture)

      loadButton = UIButton.buttonWithType(UIButtonTypeRoundedRect)
      loadButton.setFrame([[130, 0], [70,35]])
      loadButton.setTitle('Load', forState: UIControlStateNormal)

      deleteButton = UIButton.buttonWithType(UIButtonTypeRoundedRect)
      deleteButton.setFrame([[50, 0], [50,35]])
      deleteButton.setTitle('Delete', forState: UIControlStateNormal)

      buttonView = UIView.alloc.initWithFrame([[0,0],[200,35]])
      buttonView.addSubview(loadButton)
      #buttonView.addSubview(deleteButton)

      loadButton.addTarget(self,action:'Load:', forControlEvents:UIControlEventTouchUpInside)
      deleteButton.addTarget(self,action:'Delete', forControlEvents:UIControlEventTouchUpInside)
      loadButton.accessibilityLabel = name

      cell.accessoryView = buttonView
    end

    cell
  end

  def Load(sender)
    #text = sender.view.text
    @delegate.state.load(sender.accessibilityLabel.to_s)
    @delegate.close_popover
    p "seder = #{sender.accessibilityLabel.to_s}"
    NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "ReOpen", userInfo: nil, repeats: false)
    @delegate.state.save
    #reset views
    @delegate.resetViews
  end

  def Save
    @delegate.state.game_info.name = @my_text_field.text
    @delegate.state.game_info.description = @my_text_view.text
    @delegate.state.save
    p "save button is pressed"
    @delegate.close_popover
    #NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: "ReOpen", userInfo: nil, repeats: false)
  end

  def New
    @delegate.state.clearState
    p "save button is pressed"
    @delegate.close_popover
    NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "ReOpen", userInfo: nil, repeats: false)
  end

  def ReOpen
    @delegate.game
  end

  def OpenLoad
    @delegate.load
  end

  def Share
    p "internet? = no"
    @delegate.shareState
    @delegate.close_popover
    NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: "OpenLoad", userInfo: nil, repeats: false)
  end

end