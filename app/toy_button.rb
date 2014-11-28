class ToyButton < UICollectionViewCell
  attr_reader :toy_image_view
  def initWithFrame(frame)
    super
    @toy_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("toy.png"))
    addSubview(@toy_image_view)
  end

  # Used to get image from toy template
  def toy=(toy)
    @toy_image_view.image = toy.image
    @toy_image_view.sizeToFit
  end

end

