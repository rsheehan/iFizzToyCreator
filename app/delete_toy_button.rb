class DeleteToyButton < UICollectionViewCell

    attr_accessor :rotating
    attr_reader :toy_image_view

    def initWithFrame(frame)
      super
      @toy_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("toy.png"))
      @cross_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("cross.png"))
      addSubview(@toy_image_view)
      addSubview(@cross_view)

    end

    def toy=(toy)
      @toy_image_view.image = toy.image
      @toy_image_view.sizeToFit
    end

end