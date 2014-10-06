class PlayPopoverViewController < UIViewController

  attr_writer :delegate

  def loadView
    super
    @width = 300
    # Do not call super.
    self.view = UIView.alloc.initWithFrame([[0, 0], [@width, 40]])
    view.backgroundColor =  Constants::LIGHT_BLUE_GRAY

    #back button
    @back_button = UIButton.buttonWithType(UIButtonTypeCustom)
    @back_button.setImage(UIImage.imageNamed(:back_arrow), forState: UIControlStateNormal)
    @back_button.frame = [[5, 5], [20,20]]
    @back_button.addTarget(self, action: 'back:', forControlEvents: UIControlEventTouchUpInside)

    @margin = @back_button.frame.size.width

    #text instruction
    @instruction = UITextView.alloc.initWithFrame([[5,30],[@width-10,0]])
    if @instr_text
      @instruction.setText(@instr_text)
    end
    @instruction.setBackgroundColor(Constants::LIGHT_BLUE_GRAY)
    @instruction.setFont(UIFont.systemFontOfSize(Constants::ICON_LABEL_FONT_SIZE))
    @instruction.textAlignment = NSTextAlignmentCenter
    view.addSubview(@instruction)

    self.preferredContentSize = CGSizeMake(@width,@instruction.frame.size.height+@instruction.frame.origin.y+5)
    resizeViews
  end

  def setInstruction(text)
    @instr_text = text
    #resize frames
    if @instruction
      @instruction.setText(@instr_text)
      resizeViews
    end
  end

  def getInstruction
    @instr_text
  end

  def resizeViews
    #frame = @instruction.frame
    #frame.size.height = @instruction.contentSize.height
    #@instruction.frame = frame
    puts 'resize'
    if @instr_text.nil?
      self.preferredContentSize = CGSizeMake(@width,29)
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