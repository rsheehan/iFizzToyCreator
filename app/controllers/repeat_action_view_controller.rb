class RepeatActionViewController < UIViewController

  attr_writer :delegate

  LITTLE_GAP = 10
  BIG_GAP = 40
  WIDTH = 384

  def loadView
    # Do not call super.
    self.view = UIView.alloc.init() #WithFrame([[0, 0], [320, 216]])
    view.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
   #text view with instructions and labels
    text_view = UITextView.alloc.initWithFrame([[100,0],[320,100]])
    text_view.editable = false
    text_view.text = 'Please choose how often you would like the effect to repeat'
    text_view.backgroundColor = UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
    text_view.font = UIFont.fontWithName('Helvetica', size: 25)
    #min and sec labels
    min_label = UILabel.alloc.initWithFrame([[100,120],[160,20]])
    sec_label = UILabel.alloc.initWithFrame([[260,120],[160,20]])
    min_label.text = 'Minutes'
    sec_label.text = 'Seconds'
    min_label.textAlignment = UITextAlignmentCenter
    sec_label.textAlignment = UITextAlignmentCenter
    #picker for time
    picker_view = UIPickerView.alloc.initWithFrame([[100,140],[320,216]])
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
    done_button.setTitle('Done', forState: UIControlStateNormal)
    done_button.frame = [[260,370],[160,20]]
    done_button.addTarget(self, action: 'done', forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(done_button)

    cancel_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    cancel_button.setTitle('Cancel', forState: UIControlStateNormal)
    cancel_button.frame = [[100,370],[160,20]]
    cancel_button.addTarget(self, action: 'cancel', forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(cancel_button)
    @selected_mins = 0;
    @selected_secs = 0;
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
    @delegate.repeat_time(@selected_mins,@selected_secs)
    @delegate.close_touch_view_controller
  end

  # Back to the action adder to make a new one.
  def cancel
    puts('Cancel')
    @delegate.close_modal_view
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