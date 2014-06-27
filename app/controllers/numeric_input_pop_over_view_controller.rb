class NumericInputPopOverViewController < UIViewController

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
    view.addSubview(@title)

    #number input
    @number_input = UITextField.alloc.initWithFrame([[@width/4, 10+@title.frame.size.height],[@width/2,30]])
    @number_input.delegate = self
    @number_input.keyboardType = UIKeyboardTypeNumberPad
    @number_input.setBackgroundColor(UIColor.whiteColor)
    view.addSubview(@number_input)

    #continue button
    @cont_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    @cont_button.setTitle('Continue', forState: UIControlStateNormal)
    @cont_button.frame = [[5, @number_input.frame.origin.y+@number_input.frame.size.height+5], [@width-10,30]]
    @cont_button.addTarget(self, action: 'continue:', forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(@cont_button)

    resizeViews
  end

  def textField(textField, shouldChangeCharactersInRange:range, replacementString:string)
    nonNumberSet = NSCharacterSet.decimalDigitCharacterSet.invertedSet
    return ((string.stringByTrimmingCharactersInSet(nonNumberSet).length > 0) or string == '')
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
      @delegate.submit_number(@number_input.text)
    end
  end

  def resizeViews
    text_size = @title_text.sizeWithFont(UIFont.systemFontOfSize(14),
                                             constrainedToSize:CGSizeMake(@width-@margin-10, MAX_HEIGHT),
                                             lineBreakMode:UILineBreakModeWordWrap)
    @title.setText(@title_text)
    @title.setFont(UIFont.systemFontOfSize(14))
    @title.setFrame([[@margin+5, 5],[@width-@margin-5, text_size.height+10]])

    @number_input.setFrame([[@width/4, 10+@title.frame.size.height],[@width/2,30]])

    @cont_button.setFrame([[5, @number_input.frame.origin.y+@number_input.frame.size.height+5], [@width-10,30]])

    self.preferredContentSize = [@width, @cont_button.frame.origin.y+@cont_button.frame.size.height+5]
    self.view.setNeedsLayout
    self.view.setNeedsDisplay
  end

end