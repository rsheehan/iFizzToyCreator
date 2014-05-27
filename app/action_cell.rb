class ActionCell < UITableViewCell

  attr_accessor :action_image_view, :object_image_view, :effect_image_view

  def initWithStyle(style, reuseIdentifier: reuseIdentifier)
    super
    size = self.contentView.frame.size
    self.contentView.backgroundColor =  UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
    self.backgroundView = UIView.alloc.init
    self.backgroundView.backgroundColor = UIColor.colorWithRed(0.9, green: 0.9, blue: 0.95, alpha: 1.0)
    @action_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("touch.png"))
    @object_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("toy.png"))
    @effect_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("apply_force.png"))
    @action_image_view.sizeToFit
    @object_image_view.sizeToFit
    @effect_image_view.sizeToFit
    @action_image_view.contentMode = @object_image_view.contentMode = @effect_image_view.contentMode = UIViewContentModeScaleAspectFit
    self.contentView.addSubview(@action_image_view)
    self.contentView.addSubview(@object_image_view)
    self.contentView.addSubview(@effect_image_view)
    self
  end

  #TODO: Make sure image is less than cell height after fitting - showing toy images
  def action_image=(image)
    @action_image_view.image = image
    @action_image_view.sizeToFit
  end

  def object_image=(image)
    @object_image_view.image = image
    @object_image_view.sizeToFit
  end
  def effect_image=(image)
    @effect_image_view.image = image
    @effect_image_view.sizeToFit
  end

  def layoutSubviews
    super

    contentRect = self.contentView.bounds
    boundsX = contentRect.origin.x
    boundsY = contentRect.origin.y
    width = contentRect.size.width
    height = contentRect.size.height
    @action_image_view.frame = CGRectMake(boundsX+10,boundsY+10,height-20, height-20)
    @object_image_view.frame = CGRectMake(boundsX+(width/2) - (height-20)/2,boundsY+10,height-20, height-20)
    @effect_image_view.frame = CGRectMake(boundsX+width-10-(height-20),boundsY+10,height-20, height-20)

  end


end