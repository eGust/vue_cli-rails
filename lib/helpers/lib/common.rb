unless Object.instance_methods.include?(:blank?)
  class Object
    def blank?
      respond_to?(:empty?) ? !!empty? : !self
    end

    def presence
      blank? ? nil : self
    end

    def present?
      !blank?
    end
  end
end
