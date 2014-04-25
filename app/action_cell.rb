class ActionCell < UITableViewCell

  def initWithStyle(style, reuseIdentifier: reuseIdentifier)
    super
    size = self.contentView.frame.size
    @action_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("touch.png"))
    @object_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("toy.png"))
    @effect_image_view = UIImageView.alloc.initWithImage(UIImage.imageNamed("apply_force.png"))
    @action_image_view.sizeToFit
    @object_image_view.sizeToFit
    @effect_image_view.sizeToFit
    addImagesToSubview
    self
  end

  def addImagesToSubview
    Motion::Layout.new do |layout|
      layout.view self.contentView
      layout.subviews "actionImage" => action_image_view, "objectImage" => object_image_view, "effectImage" => effect_image_view
      layout.vertical "|[actionImage]|"
      layout.vertical "|[objectImage]|"
      layout.vertical "|[effectImage]|"
      layout.horizontal "|-[actionImage]-[objectImage]-[effectImage]-|"
    end
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
end