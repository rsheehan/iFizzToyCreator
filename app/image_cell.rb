class ImageCell < UICollectionViewCell

  # Images used to represent individual buttons in the popover view for toys
  # Used for actions, effects and toy representations

  #attr_accessor :toy
  attr_reader :image_view

  def initWithFrame(frame)
    super

    # Set image
    @image_view = UIImageView.alloc.initWithFrame(CGRectMake(0,0,frame.size.width,frame.size.height-15))
    @image_view.contentMode = UIViewContentModeScaleAspectFit
    @image_view.clipsToBounds = true
    addSubview(@image_view)

    # Set Text
    @text_view = UILabel.alloc.initWithFrame(CGRectMake(0,frame.size.height-15,frame.size.width, 15))
    @text_view.setTextAlignment(UITextAlignmentCenter)
    @text_view.setFont(UIFont.systemFontOfSize(14))
    addSubview(@text_view)
  end

  # Image defined for button in collection view
  def image=(img)
    @image_view.image = img
    #@image_view.sizeToFit
  end

  # Optional Call
  def text=(text)
    @text_view.setText(text)
  end
end