class MessagePopOverViewController < UIViewController

  attr_reader :text
  attr_writer :delegate

  LITTLE_GAP = 10
  BIG_GAP = 40
  MAX_HEIGHT = 500
  @typeAction = "effect"

  def loadView
    super
    @width = 300
    # Do not call super.
    self.view = UIView.alloc.initWithFrame([[0, 0], [@width, 40]])
    view.backgroundColor =  Constants::LIGHT_BLUE_GRAY
    #back button
    @back_button = UIButton.buttonWithType(UIButtonTypeCustom)
    @back_button.setImage(UIImage.imageNamed(:back_arrow), forState: UIControlStateNormal)
    @back_button.frame = [[5, 5], [30,30]]
    @back_button.addTarget(self, action: 'back:', forControlEvents: UIControlEventTouchUpInside)

    @margin = @back_button.frame.size.width

    #title
    @title = UILabel.alloc.initWithFrame([[5,5],[@width-10,30]])
    @title.setText(Language::MESSAGE_SEND)
    @title.setBackgroundColor(Constants::LIGHT_BLUE_GRAY)
    @title.setFont(UIFont.boldSystemFontOfSize(18))
    @title.textAlignment = NSTextAlignmentCenter
    view.addSubview(@title)
    view.addSubview(@back_button)

    #title separator
    separator = CALayer.layer
    separator.frame = CGRectMake(5, 40.0, @width, 1.0)
    separator.backgroundColor = UIColor.colorWithWhite(0.8, alpha:1.0).CGColor
    self.view.layer.addSublayer(separator)

    @selected_secs = 0

        #picker for time
    @picker_view = UIPickerView.alloc.initWithFrame([[@width/4, 15+@title.frame.size.height],[@width/2,30]])
    @picker_view.dataSource = self
    @picker_view.delegate = self
    @picker_view.selectRow(0, inComponent: 0, animated: false) # initialised at 4
    view.addSubview(@picker_view)

    #continue button
    @cont_button = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    @cont_button.setTitle('Continue', forState: UIControlStateNormal)
    @cont_button.frame = [[5, @picker_view.frame.origin.y+@picker_view.frame.size.height+5], [@width-10,30]]
    @cont_button.addTarget(self, action: 'continue:', forControlEvents: UIControlEventTouchUpInside)
    view.addSubview(@cont_button)

    resizeViews
  end

  def setActionType(type)
    @typeAction = type
  end

  def pickerView(pickerView, numberOfRowsInComponent:component)
    return Constants::MESSAGE_COLOURS.size
  end

  def numberOfComponentsInPickerView(pickerView)
    return 1
  end

  #def pickerView(pickerView, titleForRow:row, forComponent:component)
  #  return Constants::MESSAGE_COLOURS[row].to_s
  #end

  def pickerView(pickerView, viewForRow:row, forComponent:component, reusingView:view)
    imageView = UIImageView.alloc.initWithFrame(CGRectMake(0,0,200,25))
    imageView.image = drawColorRectangle(Constants::MESSAGE_COLOURS[row].to_s)

    tmpView = UIView.alloc.initWithFrame(CGRectMake(0,0,200,25))
    tmpView.insertSubview(imageView, atIndex: 0)
    return tmpView
  end

  def drawColorRectangle(message="clear")
    UIGraphicsBeginImageContext(CGSizeMake(200,25))

    context = UIGraphicsGetCurrentContext()
    CGContextSetLineWidth(context, 8)
    path = CGPathCreateMutable()
    CGPathMoveToPoint(path, nil, 0, 0)
    CGPathAddLineToPoint(path, nil, 0, 0)
    CGPathAddLineToPoint(path, nil, 0, 200)
    CGPathAddLineToPoint(path, nil, 200, 200)
    CGPathAddLineToPoint(path, nil, 200, 0)

    CGContextAddPath(context, path)

    if message == "black"
      label_colour = UIColor.blackColor
    elsif message == "red"
      label_colour = UIColor.redColor
    elsif message ==  "blue"
      label_colour = UIColor.blueColor
    elsif message == "green"
      label_colour = UIColor.greenColor
    elsif message ==  "cyan"
      label_colour = UIColor.cyanColor
    elsif message ==  "yellow"
      label_colour = UIColor.yellowColor
    elsif message ==  "orange"
      label_colour = UIColor.orangeColor
    elsif message ==  "purple"
      label_colour = UIColor.purpleColor
    elsif message ==  "brown"
      label_colour = UIColor.brownColor
    elsif message ==  "clear"
      label_colour = UIColor.clearColor
    elsif message ==  "white"
      label_colour = UIColor.whiteColor
    end

    CGContextSetFillColorWithColor(context, label_colour.CGColor)
    CGContextDrawPath(context, KCGPathFill)

    newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    newImage
  end

  def pickerView(pickerView, didSelectRow:row, inComponent:component)
    @selected_secs = row
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

  def back(sender)
    puts 'back'
    @delegate.action_flow_back
  end

  def continue(sender)
    if @delegate
      text = Constants::MESSAGE_COLOURS[@selected_secs].to_s
      if text.length > 0
        p "type action = #{@typeAction.to_s}"
        if @typeAction == "action"
          p "action type"
          @delegate.submit_receive_message(text)
        else
          @delegate.submit_message(text)
        end
      end
    end
  end

  def resizeViews
    @picker_view.setFrame([[@width/4, 15+@title.frame.size.height],[@width/2,30]])
    @cont_button.setFrame([[5, @picker_view.frame.origin.y+@picker_view.frame.size.height+5], [@width-10,30]])

    self.preferredContentSize = [@width, @cont_button.frame.origin.y+@cont_button.frame.size.height+5]
    self.view.setNeedsLayout
    self.view.setNeedsDisplay
  end
end