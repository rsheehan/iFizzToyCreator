class SceneButton < UICollectionViewCell
  attr_accessor :start_switch
  attr_reader :toy_image_view
  def initWithFrame(frame)
    super
    @toy_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("toy.png"))
    addSubview(@toy_image_view)

    labelView = UILabel.alloc.initWithFrame(CGRectMake(10, 205, 130, 30))
    labelView.text="Start scene:"
    labelView.textAlignment=UITextAlignmentLeft
    labelView.setFont(UIFont.systemFontOfSize(20))
    addSubview(labelView)

    @start_switch = UISwitch.alloc.initWithFrame([[130, 205], [50, 30]])
    @start_switch.on = false
    addSubview(@start_switch)

  end

  # Used to get image from toy template
  def toy=(toy)
    @toy_image_view.image = toy.image
    @toy_image_view.sizeToFit
  end

end