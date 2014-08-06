class StringInputPopOverViewController < UIViewController

  attr_reader :text
  attr_writer :delegate

  LITTLE_GAP = 10
  BIG_GAP = 40
  MAX_HEIGHT = 500

  def loadView
    super
    @width = 300
    # Do not call super.
    self.view = UIView.alloc.initWithFrame([[0, 0], [@width, 40]])
    view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)

    #close button
    @close_button = UIButton.buttonWithType(UIButtonTypeCustom)
    @close_button.setImage(UIImage.imageNamed(:cross2), forState: UIControlStateNormal)
    @close_button.frame = [[5, 5], [20,20]]
    @close_button.addTarget(self, action: 'close_view:', forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(@close_button)

    @margin = @close_button.frame.size.width

    #title
    @title = UITextView.alloc.initWithFrame([[@margin+5,5],[@width-@margin-5,@close_button.frame.size.height]])
    if @title_text
      @title.setText(@title_text)
    else
      @title.setText('Title Goes Here')
    end
    @title.setBackgroundColor(UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0))
    @title.editable = false
    @title.scrollEnabled = false
    @title.textAlignment = NSTextAlignmentCenter
    view.addSubview(@title)

    #string input
    @string_input = UITextField.alloc.initWithFrame([[@width/4, 10+@title.frame.size.height],[@width/2,30]])
    @string_input.textAlignment = NSTextAlignmentCenter
    @string_input.delegate = self
    @string_input.keyboardType = UIKeyboardTypeASCIICapable
    @string_input.setBackgroundColor(UIColor.whiteColor)
    @string_input.setText('')
    view.addSubview(@string_input)

    #continue button
    @cont_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    @cont_button.setTitle('Continue', forState: UIControlStateNormal)
    @cont_button.frame = [[5, @string_input.frame.origin.y+@string_input.frame.size.height+5], [@width-10,30]]
    @cont_button.addTarget(self, action: 'continue:', forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(@cont_button)

    resizeViews
  end

  def textField(textField, shouldChangeCharactersInRange:range, replacementString:string)
    legalCharSet = NSMutableCharacterSet.characterSetWithCharactersInString(' ')
    legalCharSet.formUnionWithCharacterSet(NSCharacterSet.alphanumericCharacterSet)
    legalCharSet.formUnionWithCharacterSet(NSCharacterSet.punctuationCharacterSet)
    trimmedString = string.stringByTrimmingCharactersInSet(legalCharSet.invert)
    stringEmpty = string == ''
    return ((trimmedString.length > 0) or stringEmpty)
  end

  def setTitle(text)
    @title_text = text
    #resize frames
    if @title
      resizeViews
    end
  end

  def setWidth(width)
    @width = width
    #reload views
    if @title
      resizeViews
    end
  end

  def close_view(sender)
    if @delegate
      @delegate.close_popover
    end
  end

  def continue(sender)
    if @delegate
      text = @string_input.text
      if text.length > 0
        @delegate.submit_text(@string_input.text)
      end
    end
  end

  def resizeViews
    text_size = @title_text.sizeWithFont(UIFont.systemFontOfSize(14),
                                         constrainedToSize:CGSizeMake(@width-@margin-10, MAX_HEIGHT),
                                         lineBreakMode:UILineBreakModeWordWrap)
    @title.setText(@title_text)
    @title.setFont(UIFont.systemFontOfSize(14))
    @title.setFrame([[@margin+5, 5],[@width-@margin-5, text_size.height+10]])

    @string_input.setFrame([[@width/4, 10+@title.frame.size.height],[@width/2,30]])

    @cont_button.setFrame([[5, @string_input.frame.origin.y+@string_input.frame.size.height+5], [@width-10,30]])

    self.preferredContentSize = [@width, @cont_button.frame.origin.y+@cont_button.frame.size.height+5]
    self.view.setNeedsLayout
    self.view.setNeedsDisplay
  end

end