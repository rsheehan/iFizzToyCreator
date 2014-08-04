class ActionCell < UITableViewCell

  attr_accessor :action_image_view, :object_image_view, :effect_image_view, :param_image_view

  def initWithStyle(style, reuseIdentifier: reuseIdentifier)
    super
    contentRect = self.contentView.frame
    boundsX = contentRect.origin.x
    boundsY = contentRect.origin.y
    width = contentRect.size.width
    height = contentRect.size.height

    img_size = [height-20, (width-30)/2].min
    x_space = (width - 2*img_size)/4
    y_space = (height-img_size-15)/2

    self.backgroundView = UIView.alloc.init
    @action_image_view = UIImageView.alloc.initWithFrame(CGRectMake(boundsX+x_space,           boundsY+y_space,img_size,img_size))
    @effect_image_view = UIImageView.alloc.initWithFrame(CGRectMake(boundsX+3*x_space+img_size,boundsY+y_space,img_size,img_size))

    @action_image_view.contentMode = UIViewContentModeScaleAspectFit
    @effect_image_view.contentMode = UIViewContentModeScaleAspectFit
    @action_image_view.clipsToBounds = true
    @effect_image_view.clipsToBounds = true

    self.contentView.addSubview(@action_image_view)
    self.contentView.addSubview(@effect_image_view)

    @action_text_view = UILabel.alloc.initWithFrame(CGRectMake(boundsX, boundsY+y_space+img_size, width/2, 15))
    @action_text_view.setTextAlignment(UITextAlignmentCenter)
    @action_text_view.setFont(UIFont.systemFontOfSize(14))
    addSubview(@action_text_view)
    @effect_text_view = UILabel.alloc.initWithFrame(CGRectMake(boundsX+width/2,boundsY+y_space+img_size,width/2, 15))
    @effect_text_view.setTextAlignment(UITextAlignmentCenter)
    @effect_text_view.setFont(UIFont.systemFontOfSize(14))
    addSubview(@effect_text_view)

    self
  end

  #TODO: Make sure image is less than cell height after fitting - showing toy images
  def action_image=(image)
    @action_image_view.image = image
  end

  def effect_image=(image)
    @effect_image_view.image = image
  end

  def action_text=(text)
    @action_text_view.setText(text)
  end

  def effect_text=(text)
    @effect_text_view.setText(text)
  end

  def sound_button=(btn)
    puts "sound Baton "

    if @sound_button
      @sound_button.removeFromSuperview
    end

    if btn
      @sound_button = btn
      addSubview(@sound_button)
    else
      @sound_button = nil
    end
  end

  def layoutSubviews
    super

    contentRect = self.contentView.bounds
    boundsX = contentRect.origin.x
    boundsY = contentRect.origin.y
    width = contentRect.size.width
    height = contentRect.size.height

    img_size = [height-20, (width-30)/2].min
    x_space = (width - 2*img_size)/4
    y_space = (height-img_size-15)/2

    @action_image_view.frame =(CGRectMake(boundsX+x_space,             boundsY+y_space,img_size,img_size))
    @effect_image_view.frame =(CGRectMake(boundsX+3*x_space+img_size,boundsY+y_space,img_size,img_size))

    @action_text_view.frame = CGRectMake(boundsX, boundsY+y_space+img_size, width/2, 15)
    @effect_text_view.frame = CGRectMake(boundsX+width/2,boundsY+y_space+img_size,width/2, 15)

    if @sound_button
      @sound_button.frame = @effect_image_view.frame
    end

  end


end