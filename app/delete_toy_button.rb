class DeleteToyButton < UICollectionViewCell

    # Small 'X' on top left corner of toys within the toyboxviewcontroller when deleting is active
    # Only allows for "X" to be tapped to delete toys

    attr_accessor :rotating, :del_toy_button
    attr_reader :toy_image_view, :id

    def initWithFrame(frame)
      super

      @toy_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("toy.png"))

      @del_toy_button = UIButton.buttonWithType(UIButtonTypeCustom)
      @del_toy_button.setImage(UIImage.imageNamed(:cross2), forState: UIControlStateNormal)
      @del_toy_button.sizeToFit
      @del_toy_button.frame = [ [-5, -5], @del_toy_button.frame.size]

      addSubview(@toy_image_view)
      addSubview(@del_toy_button)

    end

    # Toy Template to be represented
    def toy=(toy)
      @toy_image_view.image = toy.image
      @toy_image_view.sizeToFit
      @id = toy.identifier
      if @id == nil and toy.template != nil
        @id = toy.template.identifier
      end
    end

end