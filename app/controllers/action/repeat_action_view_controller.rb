class RepeatActionViewController < UIViewController

  attr_writer :delegate

  LITTLE_GAP = 10
  BIG_GAP = 40
  MAX_HEIGHT = 800

  def loadView
    @width = 300
    # Do not call super.
    self.view = UIView.alloc.initWithFrame([[0, 0], [@width, 40]])

    view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)

    @close_button = UIButton.buttonWithType(UIButtonTypeCustom)
    @close_button.setImage(UIImage.imageNamed(:cross2), forState: UIControlStateNormal)
    @close_button.frame = [[5, 5], [20,20]]
    @close_button.addTarget(self, action: 'cancel', forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(@close_button)

    @margin = @close_button.frame.size.width
   #text view with instructions and labels
    text_size = 'Please choose how often you would like the effect to repeat'.sizeWithFont(UIFont.systemFontOfSize(16),
                                         constrainedToSize:CGSizeMake(@width-@margin-10, MAX_HEIGHT),
                                         lineBreakMode:UILineBreakModeWordWrap)

    text_view = UITextView.alloc.initWithFrame([[5+@margin,0],[@width-@margin-5,text_size.height+10]])
    text_view.setFont(UIFont.systemFontOfSize(16))
    text_view.editable = false
    text_view.text = 'Please choose how often you would like the effect to repeat'
    text_view.backgroundColor = UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
    text_view.textAlignment = NSTextAlignmentCenter

    #min and sec labels
    min_label = UILabel.alloc.initWithFrame([[0,text_view.frame.size.height+5],[@width/2,20]])
    sec_label = UILabel.alloc.initWithFrame([[@width/2,text_view.frame.size.height+5],[@width/2,20]])
    min_label.text = 'Minutes'
    sec_label.text = 'Seconds'
    min_label.textAlignment = UITextAlignmentCenter
    sec_label.textAlignment = UITextAlignmentCenter
    min_label.setFont(UIFont.systemFontOfSize(14))
    sec_label.setFont(UIFont.systemFontOfSize(14))

    #picker for time
    picker_view = UIPickerView.alloc.initWithFrame([[0,min_label.frame.origin.y+min_label.frame.size.height+5],[@width,216]])
    picker_view.dataSource = self
    picker_view.delegate = self
    picker_view.selectRow(10020, inComponent: 0, animated: false)
    picker_view.selectRow(10021, inComponent: 1, animated: false)
    view.addSubview(text_view)
    view.addSubview(min_label)
    view.addSubview(sec_label)
    view.addSubview(picker_view)

    #buttons to cancel and done
    done_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    done_button.setTitle('Continue', forState: UIControlStateNormal)
    done_button.frame = [[0,picker_view.frame.origin.y+picker_view.frame.size.height+5],[@width,20]]
    done_button.addTarget(self, action: 'done', forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(done_button)

    # cancel_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    # cancel_button.setTitle('Cancel', forState: UIControlStateNormal)
    # cancel_button.frame = [[0,picker_view.frame.origin.y+picker_view.frame.size.height+5],[@width/2,20]]
    # cancel_button.addTarget(self, action: 'cancel', forControlEvents: UIControlEventTouchUpInside)
    # view.addSubview(cancel_button)
    @selected_mins = 0;
    @selected_secs = 1;

    self.preferredContentSize = [@width, done_button.frame.origin.y+done_button.frame.size.height+5]
  end

  def setup_button(image_name, position)
    button = UIButton.buttonWithType(UIButtonTypeCustom)
    button.setImage(UIImage.imageNamed(image_name), forState: UIControlStateNormal)
    button.sizeToFit
    button.frame = [position, button.frame.size]
    button.addTarget(self, action: image_name, forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(button)
    frame = button.frame
    @current_xpos = @left_margin = frame.origin.x + frame.size.width + BIG_GAP
    @right_margin = WIDTH - LITTLE_GAP
    @next_ypos = @current_ypos = LITTLE_GAP
  end

  # Back to the action adder to make a new one.
  def done
    puts('DOne')
    puts(@selected_mins,@selected_secs)
    @delegate.submit_number([@selected_mins,@selected_secs])
  end

  # Back to the action adder to make a new one.
  def cancel
    puts('Cancel')
    @delegate.close_popover
  end

  def pickerView(pickerView, numberOfRowsInComponent:component)
    return 1000000
  end

  def numberOfComponentsInPickerView(pickerView)
    return 2
  end

  def pickerView(pickerView, titleForRow:row, forComponent:component)
    return (row % 60).to_s
  end

  def pickerView(pickerView, didSelectRow:row, inComponent:component)
    if component == 0
      @selected_mins = row % 60
    else
      @selected_secs = row % 60
    end
  end

end