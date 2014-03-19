class ToyButton < UICollectionViewCell

  #attr_accessor :toy
  attr_reader :toy_image_view

  def initWithFrame(frame)
    super
    @toy_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("toy.png"))
    addSubview(@toy_image_view)
  end

  def toy=(toy)
    @toy_image_view.image = toy.image
    @toy_image_view.sizeToFit
  end

end