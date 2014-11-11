class ScoreAdderActionViewController < UIViewController

  attr_reader :text
  attr_writer :delegate

  LITTLE_GAP = 10
  BIG_GAP = 40
  MAX_HEIGHT = 500

  def loadView
    super
    @width = 300
    @selected = 0
    # Do not call super.
    self.view = UIView.alloc.initWithFrame([[0, 0], [@width, 40]])
    view.backgroundColor =  Constants::LIGHT_BLUE_GRAY

    #back button
    @back_button = UIButton.buttonWithType(UIButtonTypeCustom)
    @back_button.setImage(UIImage.imageNamed(:back_arrow), forState: UIControlStateNormal)
    @back_button.frame = [[5, 5], [30,30]]
    @back_button.addTarget(self, action: 'back:', forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(@back_button)

    @margin = @back_button.frame.size.width

    #title
    @title = UILabel.alloc.initWithFrame([[@margin+5,5],[@width-@margin-5,30]])
    @title.setText(Language::CHOOSE_SCORE)
    @title.setBackgroundColor(Constants::LIGHT_BLUE_GRAY)
    @title.setFont(UIFont.boldSystemFontOfSize(18))
    view.addSubview(@title)

    #title separator
    separator = CALayer.layer
    separator.frame = CGRectMake(5, 39.0, @width, 1.0)
    separator.backgroundColor = UIColor.colorWithWhite(0.8, alpha:1.0).CGColor
    self.view.layer.addSublayer(separator)

    sc = segment_controls
    view.addSubview(sc)

    #number input
    @number_input = UITextField.alloc.initWithFrame([[@width/4, 10+@title.frame.size.height],[@width/2,30]])
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
      resizeViews
    end
  end

  def setWidth(width)
    @width = width
    if @title
      resizeViews
    end
  end

  # Back to the action adder to make a new one.
  def back(sender)
    puts('Cancel')
    @delegate.action_flow_back
  end

  def continue(sender)
    if @delegate
      text = @number_input.text
      if text.to_i > 0
        puts "Selected: " + @selected.to_s
        case @selected
          when 0
            @delegate.submit_score_adder(@number_input.text, "add")
          when 1
            @delegate.submit_score_adder(@number_input.text, "subtract")
          when 2
            @delegate.submit_score_adder(@number_input.text, "set")
        end
      end
    end
  end

  def segment_controls
    @segment_control = UISegmentedControl.alloc.initWithFrame( CGRectZero)
    @segment_control.segmentedControlStyle = UISegmentedControlStyleBar
    @segment_control.insertSegmentWithTitle('Add', atIndex: 0, animated: false)
    @segment_control.insertSegmentWithTitle('Subtract', atIndex: 1, animated: false)
    @segment_control.insertSegmentWithTitle('Set', atIndex: 2, animated: false)
    @segment_control.sizeToFit
    @segment_control.selectedSegmentIndex = @selected
    @segment_control.addTarget(self, action: 'segment_change', forControlEvents: UIControlEventValueChanged)
    @segment_control
  end

  def segment_change
    @selected = @segment_control.selectedSegmentIndex
  end

  def resizeViews

    @segment_control.setFrame([[@width/6, 15+@title.frame.size.height], [@width*2/3, 30]])

    @number_input.setFrame([[@width/4, 15+@title.frame.size.height + @segment_control.frame.size.height + 10],[@width/2,30]])

    @cont_button.setFrame([[5, @number_input.frame.origin.y+@number_input.frame.size.height+5], [@width-10,30]])

    self.preferredContentSize = [@width, @cont_button.frame.origin.y+@cont_button.frame.size.height+5]
    self.view.setNeedsLayout
    self.view.setNeedsDisplay
  end

end