class HomePageViewController < UIViewController
  attr_accessor :state, :tab_bar
  MODES = [:help, :game, :load]

  def viewDidLoad
    p "view did load"
    super
    self.view = SKView.alloc.init
    self.view.showsFPS = true
    setup_mode_buttons(MODES)
  end

  def viewWillAppear(animated)
    p "view will appear"
    @introScene = IntroScene.alloc.initWithSize(@bounds.size)
    self.view.presentScene @introScene
  end

  def viewWillDisappear(animated)
    self.view.presentScene(nil)
  end

  def bounds_for_view=(bounds)
    @bounds = bounds
  end

  # Add the mode buttons
  def setup_mode_buttons(modes)
    @mode_view = UIView.alloc.initWithFrame(
        CGRectMake(0, 0, 95 * modes.length, 95)) # @bounds.size.width - 95 - 85, @bounds.size.height - 95, 190, 95))
    position = [10, 10]
    modes.each do |mode_name|
      button = setup_button(mode_name, position, @mode_view, mode_name)
      position[0] += CGRectGetWidth(button.frame) + 10
    end
    p "add Sub view"
    self.view.addSubview(@mode_view)
  end

  def setup_button(image_name, position, super_view, label = '')
    button = UIButton.buttonWithType(UIButtonTypeCustom)
    button.accessibilityLabel = image_name
    button.setImage(UIImage.imageNamed(image_name), forState: UIControlStateNormal)
    button.setImage(UIImage.imageNamed(image_name + '_selected'), forState: UIControlStateSelected) rescue puts 'rescued'
    button.sizeToFit
    button.frame = [position, button.frame.size]
    button.addTarget(self, action: image_name, forControlEvents: UIControlEventTouchUpInside)
    super_view.addSubview(button)
    if label != ''
      labelView = UILabel.alloc.initWithFrame(CGRectMake(button.frame.origin.x-10, button.frame.origin.y+button.frame.size.height, button.frame.size.width+20, 20))
      labelView.text=name_for_label(label)
      labelView.textAlignment=UITextAlignmentCenter
      labelView.setFont(UIFont.systemFontOfSize(Constants::ICON_LABEL_FONT_SIZE))
      super_view.addSubview(labelView)
    end
    button
  end

  def name_for_label(label)
    case label
      when :help
        return "instructions"
      when :game
        return "my games"
      when :load
        return "download"
    end
  end

  def help
    string = Constants::IFIZZ_INTRODUCTION_TEXT
    textpopover = HelpPopoverViewController.alloc.initWithNibName(nil, bundle: nil)
    textpopover.delegate = self
    textpopover.setInstruction(string)
    @label = UIPopoverController.alloc.initWithContentViewController(textpopover)
    @label.delegate = self
    @label.presentPopoverFromRect(CGRectMake(0,0,95,95) , inView: self.view, permittedArrowDirections: UIPopoverArrowDirectionDown, animated:true)

  end
  def game
    @popover = SaveGamePopoverViewController.alloc.initWithNibName(nil, bundle: nil)
    @popover.delegate = self
    show_popover(@popover)
    p "loaded game name: #{state.game_info.name}"
  end
  def load
    # load internet game
    content = LoadGamePopoverViewController.alloc.initWithNibName(nil, bundle: nil)
    content.delegate = self
    show_popover(content)
  end

  def close_popover
    if not @popover.nil?
      @popover.dismissPopoverAnimated(true)
    end
  end

  def shareState
    url_string = Constants::WEB_URL+"index.php"
    fileNameGame = @state.game_info.name.tr(" ", "_")
    dataPost = @state.getStringState
    post_body = "name="+fileNameGame+"&data="+dataPost
    url = NSURL.URLWithString(url_string)
    request = NSMutableURLRequest.requestWithURL(url)
    request.timeoutInterval = 30
    request.HTTPMethod = "POST"
    request.HTTPBody = post_body.dataUsingEncoding(NSUTF8StringEncoding)
    queue = NSOperationQueue.alloc.init
    NSURLConnection.sendAsynchronousRequest(request,
                                            queue: queue,
                                            completionHandler: lambda do |response, data, error|

                                              if error != nil
                                                p "error = #{error}"
                                              else
                                                if(data.length > 0 && error.nil?)
                                                  html = NSString.alloc.initWithData(data, encoding: NSUTF8StringEncoding)
                                                elsif( data.length == 0 && error.nil? )
                                                  p "Nothing was downloaded"
                                                elsif(!error.nil?)
                                                  p "Error: #{error}"
                                                end
                                              end
                                            end
    )

  end

  def state
    @state
  end

  def resume
    @introScene.view.paused = false
  end

  def loadGame(gameURL)
    file_path = Constants::WEB_URL+"upload/"+gameURL
    url = NSURL.URLWithString(file_path)
    request = NSURLRequest.requestWithURL(url)
    res = nil
    err = nil
    data = NSURLConnection.sendSynchronousRequest(request, returningResponse: res, error: err)
    @state.loadFromData(data.to_s)
    #reset all views
    resetViews
    NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "game", userInfo: nil, repeats: false)
  end

  def resetViews
    tab_bar.resetViews
  end

  def show_popover(content)
    @introScene.view.paused = true
    #if already showing, change rather than create new?
    @popover = UIPopoverController.alloc.initWithContentViewController(content)
    @popover.delegate = self
    viewy = self.view
    frame = CGRectMake(0,0,95,95)
    @popover.presentPopoverFromRect(frame , inView: viewy, permittedArrowDirections: UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight, animated:true)
  end
end