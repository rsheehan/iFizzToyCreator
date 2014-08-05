class NumericInputPopOverViewController < UIViewController

  attr_reader :text
  attr_writer :delegate

  LITTLE_GAP = 10
  BIG_GAP = 40
  MAX_HEIGHT = 500

  def loadView
    super
    @width = 350
    # Do not call super.
    self.view = UIView.alloc.initWithFrame([[0, 0], [@width, 40]])
    view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)

    #back button
    @back_button = UIButton.buttonWithType(UIButtonTypeCustom)
    @back_button.setImage(UIImage.imageNamed(:back_arrow), forState: UIControlStateNormal)
    @back_button.frame = [[5, 5], [30,30]]
    @back_button.addTarget(self, action: 'back:', forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(@back_button)

    @margin = @back_button.frame.size.width

    #title
    @title = UILabel.alloc.initWithFrame([[@margin+5,5],[@width-@margin-5,30]])
    if @title_text
      @title.setText(@title_text)
    else
      @title.setText(Language::SCORE_TRIGGER)
    end
    @title.setBackgroundColor(UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0))
    @title.setFont(UIFont.boldSystemFontOfSize(18))
    view.addSubview(@title)

    #title separator
    separator = CALayer.layer
    separator.frame = CGRectMake(5, 35.0, @width, 1.0)
    separator.backgroundColor = UIColor.colorWithWhite(0.8, alpha:1.0).CGColor
    self.view.layer.addSublayer(separator)

    #number input
    @number_input = UITextField.alloc.initWithFrame([[@width/4, 40],[@width/2,30]])
    @number_input.textAlignment = NSTextAlignmentCenter
    @number_input.delegate = self
    @number_input.keyboardType = UIKeyboardTypeNumberPad
    @number_input.setBackgroundColor(UIColor.whiteColor)
    @number_input.setText('1')
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
    newLength = textField.text.length + string.length - range.length
    if newLength > 3
        return false
    end
    return ((string.stringByTrimmingCharactersInSet(nonNumberSet).length > 0) or string == '')
  end

  def setTitle(text)
    @title_text = text
    #resize frames
    if @title
      @title.setText(@title_text)
    end
  end

  def setWidth(width)
    @width = width
    #reload views
    if @title
      resizeViews
    end
  end

  def back(sender)
    puts 'back'
    @delegate.action_flow_back
  end

  def continue(sender)
    if @delegate
      number = @number_input.text.to_i
      if number > 0
        @delegate.submit_number(number)
      end
    end
  end

  def resizeViews

    @number_input.setFrame([[@width/4, 10+@title.frame.size.height],[@width/2,30]])
    @cont_button.setFrame([[5, @number_input.frame.origin.y+@number_input.frame.size.height+5], [@width-10,30]])

    self.preferredContentSize = [@width, @cont_button.frame.origin.y+@cont_button.frame.size.height+5]
    self.view.setNeedsLayout
    self.view.setNeedsDisplay
  end

end