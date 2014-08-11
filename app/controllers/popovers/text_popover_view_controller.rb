class TextPopoverViewController < UIViewController

  attr_writer :delegate

  def loadView
    super
    @width = 300
    # Do not call super.
    self.view = UIView.alloc.initWithFrame([[0, 0], [@width, 40]])
    view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)

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
    @title.setBackgroundColor(UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0))
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
    @instruction.setBackgroundColor(UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0))
    @instruction.setFont(UIFont.systemFontOfSize(14))
    @instruction.textAlignment = NSTextAlignmentCenter
    view.addSubview(@instruction)

    self.preferredContentSize = CGSizeMake(@width,@instruction.frame.size.height+@instruction.frame.origin.y+5)
    resizeViews
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
    self.preferredContentSize = CGSizeMake(@width,@instruction.frame.size.height+@instruction.frame.origin.y+5)
    puts 'done ' + size.height.to_s
  end

end