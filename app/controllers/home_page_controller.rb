class HomePageViewController < UIViewController
  attr_writer :state
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
    content = SaveGamePopoverViewController.alloc.initWithNibName(nil, bundle: nil)
    content.delegate = self
    show_popover(content)
  end
  def load
    # load internet game
    content = LoadGamePopoverViewController.alloc.initWithNibName(nil, bundle: nil)
    content.delegate = self
    show_popover(content)
  end

  def resume
    @introScene.view.paused = false
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