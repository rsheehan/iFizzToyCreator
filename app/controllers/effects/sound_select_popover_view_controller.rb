class SoundSelectPopoverViewController < UIViewController
  attr_writer :delegate

  LITTLE_GAP = 10
  BIG_GAP = 40
  MAX_HEIGHT = 800

  def loadView
    @width = 300
    @height = 300
    # Do not call super.
    self.view = UIView.alloc.initWithFrame([[0, 0], [@width, 40]])
    view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)

    @close_button = UIButton.buttonWithType(UIButtonTypeCustom)
    @close_button.setImage(UIImage.imageNamed(:cross2), forState: UIControlStateNormal)
    @close_button.frame = [[5, 5], [20,20]]
    @close_button.addTarget(self, action: 'cancel', forControlEvents: UIControlEventTouchUpInside)

    @margin = @close_button.frame.size.width

    #title view
    title_view = UILabel.alloc.initWithFrame([[@margin+10,0],[@width-@margin-5,25]])
    title_view.setFont(UIFont.systemFontOfSize(20))
    title_view.text = 'Choose Sound'
    title_view.backgroundColor = UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
    title_view.textAlignment = NSTextAlignmentLeft
    view.addSubview(title_view)

    #table view for sound
    @table_view = UITableView.alloc.initWithFrame([[0, title_view.frame.size.height+title_view.frame.origin.y+5],
                                                   [@width, @height-(title_view.frame.size.height+title_view.frame.origin.y+5)]])
    @table_view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
    @table_view.dataSource = self
    @table_view.delegate = self
    @table_view.rowHeight = 45
    view.addSubview(@table_view)
    view.addSubview(@close_button)

    self.preferredContentSize = [@width, @height]
  end

  def select_sound(sender)
    @player = nil
    @delegate.set_sound(sender.view.text)
  end

  def play_sound(sender)
    buttonPosition = sender.convertPoint(CGPointZero, toView:@table_view);
    indexPath = @table_view.indexPathForRowAtPoint(buttonPosition)
    if indexPath != nil
      name = Constants::SOUND_NAMES[indexPath.row]
      puts('play sound - '+name)

      local_file = NSURL.fileURLWithPath(File.join(NSBundle.mainBundle.resourcePath, name))
      @player = AVAudioPlayer.alloc.initWithContentsOfURL(local_file, error:nil)
      @player.numberOfLoops = 1
      @player.prepareToPlay
      @player.play
    end

  end

  # Back to the action adder to make a new one.
  def cancel
    @player = nil
    @delegate.close_popover
  end

  def tableView(tv, numberOfRowsInSection: section)
    Constants::SOUND_NAMES.length
  end

  def tableView(tv, cellForRowAtIndexPath: index_path)
    index = index_path.row # ignore section as only one

    cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier: "default")

    name = Constants::SOUND_NAMES[index].gsub('_',' ').gsub('.wav','').gsub('.mp3','')

    cell.textLabel.text = name
    cell.textLabel.userInteractionEnabled = true
    tapGesture = UITapGestureRecognizer.alloc.initWithTarget(self, action:'select_sound:')
    cell.textLabel.addGestureRecognizer(tapGesture)

    button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    button.setFrame([[3*@width/4, 5], [@width/4,35]])
    button.setTitle('Play', forState: UIControlStateNormal)
    button.addTarget(self,action:'play_sound:', forControlEvents:UIControlEventTouchUpInside)
    cell.accessoryView = button

    cell
  end

end