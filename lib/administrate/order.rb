module Administrate
  class Order
    def initialize(attribute = nil, direction = nil)
      @attribute = attribute
      @direction = direction || :asc
    end

    def apply(relation)
      return relation if attribute.nil?

      case
      when relation.columns_hash.key?(attribute.to_s)
        relation.order(attribute => direction)
      when relation.acting_as? && relation.acting_as_model.columns_hash.key?(attribute.to_s)
        relation.order("#{relation.acting_as_model.table_name}.#{attribute} #{direction}")
      else
        raise "Don't know how to sort by #{attribute}."
      end
    end

    def ordered_by?(attr)
      attr.to_s == attribute.to_s
    end

    def order_params_for(attr)
      {
        order: attr,
        direction: reversed_direction_param_for(attr)
      }
    end

    attr_reader :direction

    private

    attr_reader :attribute

    def reversed_direction_param_for(attr)
      if ordered_by?(attr)
        opposite_direction
      else
        :asc
      end
    end

    def opposite_direction
      direction.to_sym == :asc ? :desc : :asc
    end
  end
end
