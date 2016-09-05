class ActiveOperation::Input
  include SmartProperties

  property :type, accepts: [:positional, :keyword], required: true
  property :property, accepts: SmartProperties::Property, required: true

  def positional?
    type == :positional
  end

  def keyword?
    type == :keyword
  end

  def name
    property.name
  end
end
