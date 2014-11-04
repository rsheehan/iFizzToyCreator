class LoadGamePopoverViewController < UIViewController
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
    @title.setText('Load a game from the Internet')
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
    req=NSURLRequest.requestWithURL(NSURL.URLWithString(Constants::WEB_URL + "index.php?"+rand(100000).to_s), cachePolicy:NSURLRequestReloadIgnoringCacheData, timeoutInterval:1.0)
    @connection = NSURLConnection.alloc.initWithRequest req, delegate: self, startImmediately: true
  end

  def viewWillDisappear(animated)
    @delegate.resume
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

    button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    button.setFrame([[3*@width/4, 5], [@width/4,35]])
    button.setTitle('Download', forState: UIControlStateNormal)
    button.addTarget(self,action:'Download:', forControlEvents:UIControlEventTouchUpInside)


    button.accessibilityLabel = name.split(" ")[0]

    cell.accessoryView = button

    cell
  end

  def connection(connection, didFailWithError:error)
    p error
    @delegate.close_popover
    alert = UIAlertView.alloc.initWithTitle("Alert", message:"No Internet connection, is the WIFI on?", delegate:self, cancelButtonTitle: "OK", otherButtonTitles: nil)
    alert.show
    #NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: "OpenLoad", userInfo: nil, repeats: false)
  end

  def OpenLoad
    @delegate.load
  end

  def Download(sender)
    @delegate.loadGame(sender.accessibilityLabel)
    @delegate.close_popover
  end

  def connection(connection, didReceiveResponse:response)
    @file = NSMutableData.data
    @response = response
    @download_size = response.expectedContentLength
  end

  def connection(connection, didReceiveData:data)
    @file.appendData data
  end

  def connection(connection, willCacheResponse:cachedResponse)
    nil
  end

  def connectionDidFinishLoading(connection)
    @dataList = []
    
    readFile = @file.inspect.to_s
    readFile.each_line { |line|
      if(line.chomp != "")
        @dataList << line.chomp
      end

    }    
    @number = @dataList.size
    @table_view.reloadData

    @connection.cancel
  end

end