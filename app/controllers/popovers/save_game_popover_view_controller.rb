class SaveGamePopoverViewController < UIViewController
  attr_writer :delegate

  LITTLE_GAP = 10
  BIG_GAP = 40
  MAX_HEIGHT = 800

  @number = 0

  def loadView
    p "load view"
    @number = 0
    @dataList = []

    @width = 500
    @height = 300
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
    

    #table view for sound
    @table_view = UITableView.alloc.initWithFrame([[0, 45], [@width, 400]])
    @table_view.backgroundColor =  Constants::LIGHT_BLUE_GRAY
    @table_view.dataSource = self
    @table_view.delegate = self
    @table_view.rowHeight = 45
    view.addSubview(@table_view)
    view.addSubview(@close_button)

    self.preferredContentSize = [@width, @table_view.frame.size.height+@table_view.frame.origin.y]
  end

  def viewWillAppear(animated)
    p "view appear #{@connection.to_s}"
    req=NSURLRequest.requestWithURL(NSURL.URLWithString("https://www.cs.auckland.ac.nz/~mngu012/ifizz/index.php"))
    @connection = NSURLConnection.alloc.initWithRequest req, delegate: self, startImmediately: true
  end

  def viewWillDisappear(animated)
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
    @number
  end

  def tableView(tv, cellForRowAtIndexPath: index_path)
    index = index_path.row # ignore section as only one

    cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier: "default")

    name = @dataList[index]

    cell.textLabel.text = name
    cell.textLabel.userInteractionEnabled = true
    tapGesture = UITapGestureRecognizer.alloc.initWithTarget(self, action:'select_sound:')
    cell.textLabel.addGestureRecognizer(tapGesture)

    button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    button.setFrame([[3*@width/4, 5], [@width/4,35]])
    button.setTitle('Upload and share', forState: UIControlStateNormal)
    cell.accessoryView = button

    cell
  end

  def connection(connection, didFailWithError:error)
    p error
  end

  def connection(connection, didReceiveResponse:response)
    @file = NSMutableData.data
    @response = response
    @download_size = response.expectedContentLength
  end

  def connection(connection, didReceiveData:data)
    @file.appendData data
  end

  def connectionDidFinishLoading(connection)
    @dataList = []
    
    readFile = @file.inspect.to_s
    readFile.each_line { |line|
      @dataList << line.chomp
    }    
    @number = @dataList.size
    @table_view.reloadData

    @connection.cancel
  end

end