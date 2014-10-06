class RepeatActionViewController < UIViewController

  attr_writer :delegate

  LITTLE_GAP = 10
  BIG_GAP = 40
  MAX_HEIGHT = 800

  @textLabel = 'Repeat every'

  def loadView
    @width = 300
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
    @title.setText(Language::CHOOSE_TIMER)
    @title.setBackgroundColor(Constants::LIGHT_BLUE_GRAY)
    @title.setFont(UIFont.boldSystemFontOfSize(18))
    view.addSubview(@title)

    #title separator
    separator = CALayer.layer
    separator.frame = CGRectMake(5, 39.0, @width, 1.0)
    separator.backgroundColor = UIColor.colorWithWhite(0.8, alpha:1.0).CGColor
    self.view.layer.addSublayer(separator)

    #picker for time
    picker_view = UIPickerView.alloc.initWithFrame([[0,45],[@width,150]])
    picker_view.dataSource = self
    picker_view.delegate = self
    picker_view.selectRow(304, inComponent: 0, animated: false) # initialised at 4
    view.addSubview(picker_view)

    #textview
    text_view = UILabel.alloc.initWithFrame([[0,picker_view.frame.origin.y+picker_view.frame.size.height/2-13],[@width/2-20,26]])
    text_view.setFont(UIFont.systemFontOfSize(20))
    text_view.text = @textLabel
    text_view.backgroundColor = Constants::LIGHT_BLUE_GRAY
    text_view.textAlignment = NSTextAlignmentCenter
    view.addSubview(text_view)

    #sec label
    sec_label = UILabel.alloc.initWithFrame([[@width/2,picker_view.frame.origin.y+picker_view.frame.size.height/2-10],[@width/2,25]])
    sec_label.text = 'Seconds'
    sec_label.textAlignment = UITextAlignmentCenter
    sec_label.setFont(UIFont.systemFontOfSize(20))
    view.addSubview(sec_label)

    ran_label = UILabel.alloc.initWithFrame([[0, picker_view.frame.origin.y+picker_view.frame.size.height+5],[@width/2,25]])
    ran_label.text = 'Random Interval:'
    ran_label.textAlignment = UITextAlignmentCenter
    ran_label.setFont(UIFont.systemFontOfSize(20))
    view.addSubview(ran_label)

    @random_switch = UISwitch.alloc.initWithFrame([[3*@width/4,picker_view.frame.origin.y+picker_view.frame.size.height],[@width/4,20]])
    @random_switch.on = true
    @random_switch.addTarget(self,action:'random_switch_changed', forControlEvents:UIControlEventValueChanged)
    view.addSubview(@random_switch)

    #buttons to cancel and done
    done_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    done_button.setTitle('Continue', forState: UIControlStateNormal)
    done_button.frame = [[0,picker_view.frame.origin.y+picker_view.frame.size.height+65],[@width,20]]
    done_button.addTarget(self, action: 'done', forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(done_button)

    #@selected_secs = 1
    @selected_secs = picker_view.selectedRowInComponent(0) % 300 + 1

    self.preferredContentSize = [@width, done_button.frame.origin.y+done_button.frame.size.height+50]
  end

  def setLabel(newLabel)
    @textLabel = newLabel
  end

  def random_switch_changed
    # for simplicity,
    # if @selected_secs is negative, say -5, it is randomly executed with average of about 5 seconds
    # if @selected_secs is positive, say +5, it will run exactly every 5 seconds
    if @random_switch.isOn
      p "click on"
    else
      p "click off"
    end


  end

  # Back to the action adder to make a new one.
  def done
    if @random_switch.isOn
      @delegate.submit_number(-1*@selected_secs)
    else
      @delegate.submit_number(@selected_secs)
    end

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
    return (row % 300 + 1).to_s
  end

  def pickerView(pickerView, didSelectRow:row, inComponent:component)
      @selected_secs = row % 300 + 1
  end

end