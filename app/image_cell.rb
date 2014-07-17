class ImageCell < UICollectionViewCell

  #attr_accessor :toy
  attr_reader :image_view

  def initWithFrame(frame)
    super
    @image_view = UIImageView.alloc.initWithFrame(CGRectMake(0,0,frame.size.width,frame.size.height-15))
    @image_view.contentMode = UIViewContentModeScaleAspectFit
    @image_view.clipsToBounds = true
    addSubview(@image_view)
    @text_view = UILabel.alloc.initWithFrame(CGRectMake(0,frame.size.height-15,frame.size.width, 15))
    @text_view.setTextAlignment(UITextAlignmentCenter)
    @text_view.setFont(UIFont.systemFontOfSize(14))
    addSubview(@text_view)
  end

  def image=(img)
    @image_view.image = img
    #@image_view.sizeToFit
  end

  def text=(text)
    @text_view.setText(text)
  end
end