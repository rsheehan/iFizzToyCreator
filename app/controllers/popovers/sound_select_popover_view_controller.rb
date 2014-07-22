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

    #back button
    @back_button = UIButton.buttonWithType(UIButtonTypeCustom)
    @back_button.setImage(UIImage.imageNamed(:back_arrow), forState: UIControlStateNormal)
    @back_button.frame = [[5, 5], [20,20]]
    @back_button.addTarget(self, action: 'back:', forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(@back_button)

    @margin = @back_button.frame.size.width

    #title
    @title = UILabel.alloc.initWithFrame([[@margin+5,5],[@width-@margin-5,20]])
    @title.setText('Choose Sound')
    @title.setBackgroundColor(UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0))
    @title.setFont(UIFont.boldSystemFontOfSize(16))
    view.addSubview(@title)

    #title separator
    separator = CALayer.layer
    separator.frame = CGRectMake(5, 29.0, @width, 1.0)
    separator.backgroundColor = UIColor.colorWithWhite(0.8, alpha:1.0).CGColor
    self.view.layer.addSublayer(separator)

    #make table view filled with all actions that have selected as the toy
    if Constants::SOUND_NAMES.length > 3
      tvHeight = 160
    else
      tvHeight = 45 * Constants::SOUND_NAMES.length
    end

    #table view for sound
    @table_view = UITableView.alloc.initWithFrame([[0, 35], [@width, tvHeight]])
    @table_view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
    @table_view.dataSource = self
    @table_view.delegate = self
    @table_view.rowHeight = 45
    view.addSubview(@table_view)
    view.addSubview(@close_button)

    self.preferredContentSize = [@width, @table_view.frame.size.height+@table_view.frame.origin.y]
  end

  def select_sound(sender)
    @player = nil
    #add extension on end
    text = sender.view.text.gsub(' ', '_')
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
      @player.numberOfLoops = 0
      @player.prepareToPlay
      @player.play
    end

  end

  # Back to the action adder to make a new one.
  def back(sender)
    @player = nil
    @delegate.action_flow_back
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