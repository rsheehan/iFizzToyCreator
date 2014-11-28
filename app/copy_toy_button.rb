class CopyToyButton < UICollectionViewCell

  # Small 'X' on top left corner of toys within the toyboxviewcontroller when deleting is active
  # Only allows for "X" to be tapped to delete toys

  attr_accessor :rotating, :copy_toy_button
  attr_reader :toy_image_view, :id

  def initWithFrame(frame)
    super

    @toy_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("toy.png"))

    @copy_toy_button = UIButton.buttonWithType(UIButtonTypeCustom)
    @copy_toy_button.setImage(UIImage.imageNamed(:addCross), forState: UIControlStateNormal)
    @copy_toy_button.sizeToFit

    @left = frame.size.width/2 - @copy_toy_button.frame.size.width/2
    @top = frame.size.height/2 - @copy_toy_button.frame.size.height/2

    @copy_toy_button.frame = [ [@left, @top], @copy_toy_button.frame.size]


    addSubview(@toy_image_view)
    addSubview(@copy_toy_button)

  end

  # Toy Template to be represented
  def toy=(toy)
    @toy_image_view.image = toy.image
    @toy_image_view.sizeToFit
    @id = toy.identifier
    if @id == nil and toy.template != nil
      @id = toy.template.identifier
    end
    @toy_image_view.setAlpha(0.5)

    @left = @toy_image_view.frame.size.width/2 - @copy_toy_button.frame.size.width/2
    @top = @toy_image_view.frame.size.height/2 - @copy_toy_button.frame.size.height/2
    @copy_toy_button.frame = [ [@left, @top], @copy_toy_button.frame.size]
  end

end