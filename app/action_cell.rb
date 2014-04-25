class ActionCell < UITableViewCell

  attr_accessor :action_image_view, :object_image_view, :effect_image_view

  def initWithStyle(style, reuseIdentifier: reuseIdentifier)
    super
    size = self.contentView.frame.size
    @action_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("touch.png"))
    @object_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("toy.png"))
    @effect_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("apply_force.png"))
    @action_image_view.sizeToFit
    @object_image_view.sizeToFit
    @effect_image_view.sizeToFit
    self.contentView.addSubview(@action_image_view)
    self.contentView.addSubview(@object_image_view)
    self.contentView.addSubview(@effect_image_view)
    self
  end

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
    @action_image_view.frame = CGRectMake(boundsX+10,boundsY+10,@action_image_view.frame.size.width, @action_image_view.frame.size.height)
    @object_image_view.frame = CGRectMake(boundsX+(width/2) - @object_image_view.frame.size.width/2,boundsY+10,@object_image_view.frame.size.width, @object_image_view.frame.size.height)
    @effect_image_view.frame = CGRectMake(boundsX+width-10-@effect_image_view.frame.size.width,boundsY+10,@effect_image_view.frame.size.width, @effect_image_view.frame.size.height)

  end


end