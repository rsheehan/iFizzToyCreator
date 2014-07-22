class ButtonSelectPopoverViewController < UIViewController

  attr_writer :delegate

  def loadView
    super
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
    @title.setText('Choose button')

    @title.setBackgroundColor(UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0))
    @title.setFont(UIFont.boldSystemFontOfSize(16))
    view.addSubview(@title)

    self.preferredContentSize = CGSizeMake(@width,30)
  end

  def back(sender)
    @delegate.action_flow_back
  end

end