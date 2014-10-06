class TextPopoverViewController < UIViewController

  attr_writer :delegate

  def loadView
    super
    puts "TextPopoverViewController"
    @width = 300
    # Do not call super.
    self.view = UIView.alloc.initWithFrame([[0, 0], [@width, 40]])
    view.backgroundColor =  Constants::LIGHT_BLUE_GRAY

    #back button
    @back_button = UIButton.buttonWithType(UIButtonTypeCustom)
    @back_button.setImage(UIImage.imageNamed(:back_arrow), forState: UIControlStateNormal)
    @back_button.frame = [[5, 5], [30,30]]
    @back_button.addTarget(self, action: 'back:', forControlEvents: UIControlEventTouchUpInside)

    @margin = @back_button.frame.size.width

    #title
    @title = UILabel.alloc.initWithFrame([[5,5],[@width-10,30]])
    if @title_text
      @title.setText(@title_text)
    else
      @title.setText(Language::EXPLOSION)
    end
    @title.setBackgroundColor(Constants::LIGHT_BLUE_GRAY)
    @title.setFont(UIFont.boldSystemFontOfSize(18))
    @title.textAlignment = NSTextAlignmentCenter
    view.addSubview(@title)
    view.addSubview(@back_button)

    #title separator
    separator = CALayer.layer
    separator.frame = CGRectMake(5, 40.0, @width, 1.0)
    separator.backgroundColor = UIColor.colorWithWhite(0.8, alpha:1.0).CGColor
    self.view.layer.addSublayer(separator)

    #text instruction
    @instruction = UITextView.alloc.initWithFrame([[5,45],[@width-10,0]])
    if @instr_text
      @instruction.setText(@instr_text)
    end
    @instruction.setBackgroundColor(Constants::LIGHT_BLUE_GRAY)
    @instruction.setFont(UIFont.systemFontOfSize(Constants::ICON_LABEL_FONT_SIZE))
    @instruction.textAlignment = NSTextAlignmentCenter
    view.addSubview(@instruction)

    random_label = UILabel.alloc.initWithFrame([[5,2*45 + 5],[@width/2-10,35]])
    random_label.textAlignment = NSTextAlignmentCenter
    random_label.text = 'Random Force:'
    view.addSubview(random_label)

    @random_switch = UISwitch.alloc.initWithFrame([[@width/2,2*45 + 5],[@width/2-10,35]])
    @random_switch.tintColor = UIColor.grayColor
    @random_switch.on = false
    @random_switch.addTarget(self,action:'random_switch_changed:', forControlEvents:UIControlEventValueChanged)
    view.addSubview(@random_switch)

    self.preferredContentSize = CGSizeMake(@width,@instruction.frame.size.height+@instruction.frame.origin.y+5)
    resizeViews
  end

  def random_switch_changed(sender)
    puts 'random_switch_changed'
    if @random_switch.isOn
      # assume when
      @delegate.addForce( CGPointMake(0,0) )

    end
  end


  def back(sender)
    puts 'back'
    @delegate.action_flow_back
  end

  def setTitle(text)
    @title_text = text
    #resize frames
    if @title
      @title.setText(@title_text)
    end
  end

  def setInstruction(text)
    @instr_text = text
    #resize frames
    if @instruction
      @instruction.setText(@instr_text)
      resizeViews
    end
  end

  def resizeViews
    #frame = @instruction.frame
    #frame.size.height = @instruction.contentSize.height
    #@instruction.frame = frame
    puts 'resize'
    if @instr_text.nil?
      self.preferredContentSize = CGSizeMake(@width,40)
      return
    end
    size = @instruction.sizeThatFits(CGSizeMake(@instruction.frame.size.width, 1000))
    frame = @instruction.frame
    frame.size.height = size.height
    @instruction.frame = frame
    #update preferred size
    self.preferredContentSize = CGSizeMake(@width,3*(@instruction.frame.size.height+10))

  end

end