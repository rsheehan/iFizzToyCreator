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

    #back button
    @back_button = UIButton.buttonWithType(UIButtonTypeCustom)
    @back_button.setImage(UIImage.imageNamed(:back_arrow), forState: UIControlStateNormal)
    @back_button.frame = [[5, 5], [20,20]]
    @back_button.addTarget(self, action: 'back:', forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(@back_button)

    @margin = @back_button.frame.size.width

    #title
    @title = UILabel.alloc.initWithFrame([[@margin+5,5],[@width-@margin-5,20]])
    @title.setText('Timer Trigger')
    @title.setBackgroundColor(UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0))
    @title.setFont(UIFont.boldSystemFontOfSize(16))
    view.addSubview(@title)

    #title separator
    separator = CALayer.layer
    separator.frame = CGRectMake(5, 29.0, @width, 1.0)
    separator.backgroundColor = UIColor.colorWithWhite(0.8, alpha:1.0).CGColor
    self.view.layer.addSublayer(separator)

    #picker for time
    picker_view = UIPickerView.alloc.initWithFrame([[0,35],[@width,150]])
    picker_view.dataSource = self
    picker_view.delegate = self
    picker_view.selectRow(30001, inComponent: 0, animated: false)
    view.addSubview(picker_view)

    #textview
    text_view = UILabel.alloc.initWithFrame([[0,picker_view.frame.origin.y+picker_view.frame.size.height/2-13],[@width/2-20,26]])
    text_view.setFont(UIFont.systemFontOfSize(20))
    text_view.text = 'Repeat every'
    text_view.backgroundColor = UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
    text_view.textAlignment = NSTextAlignmentCenter
    view.addSubview(text_view)

    #sec label
    sec_label = UILabel.alloc.initWithFrame([[@width/2,picker_view.frame.origin.y+picker_view.frame.size.height/2-10],[@width/2,20]])
    sec_label.text = 'Seconds'
    sec_label.textAlignment = UITextAlignmentCenter
    sec_label.setFont(UIFont.systemFontOfSize(20))
    view.addSubview(sec_label)

    #buttons to cancel and done
    done_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    done_button.setTitle('Continue', forState: UIControlStateNormal)
    done_button.frame = [[0,picker_view.frame.origin.y+picker_view.frame.size.height+5],[@width,20]]
    done_button.addTarget(self, action: 'done', forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(done_button)

    @selected_secs = 1

    self.preferredContentSize = [@width, done_button.frame.origin.y+done_button.frame.size.height+5]
  end

  # Back to the action adder to make a new one.
  def done
    puts('repeat every '+ @selected_secs.to_s+' s')
    @delegate.submit_number(@selected_secs)
  end

  # Back to the action adder to make a new one.
  def back(sender)
    puts('Cancel')
    @delegate.action_flow_back
  end

  def pickerView(pickerView, numberOfRowsInComponent:component)
    return 1000000
  end

  def numberOfComponentsInPickerView(pickerView)
    return 1
  end

  def pickerView(pickerView, titleForRow:row, forComponent:component)
    return (row % 300).to_s
  end

  def pickerView(pickerView, didSelectRow:row, inComponent:component)
      @selected_secs = row % 300
  end

end