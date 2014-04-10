class DeleteToyButton < UICollectionViewCell

    #attr_accessor :toy
    attr_reader :toy_image_view

    def initWithFrame(frame)
      super
      @toy_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("toy.png"))
      @cross_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("cross.png"))
      addSubview(@toy_image_view)
      addSubview(@cross_view)

      # the points we're going to animate to
      # @points = [frame.origin, frame.origin+5, frame.origin, frame.origin-5, frame.origin]
      # @current_index = 0

    end

    # def animate_to_next_point
    #   @current_index += 1
    #
    #   # keep current_index in the range [0,3]
    #   @current_index = @current_index % @points.count
    #
    #   # UIView.animateWithDuration(2,
    #   #                            animations: lambda {
    #   #                              self.contentView.frame = [@points[@current_index], self.contentView.frame.size]
    #   #                            },
    #   #                            completion:lambda {|finished|
    #   #                              self.animate_to_next_point
    #   #                            }
    #   # )
    # end

    def toy=(toy)
      @toy_image_view.image = toy.image
      @toy_image_view.sizeToFit
    end

end