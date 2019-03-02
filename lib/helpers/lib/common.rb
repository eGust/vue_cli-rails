unless Object.instance_methods.include?(:blank?)
  class Object
    def blank?
      respond_to?(:empty?) ? !!empty? : !self
    end
  end
end
