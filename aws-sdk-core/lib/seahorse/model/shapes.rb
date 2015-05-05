require 'set'

module Seahorse
  module Model
    module Shapes

      class ShapeRef

        def initialize
          @metadata = {}
        end

        # @return [Shape]
        attr_accessor :shape

        # @return [String, nil]
        attr_accessor :location

        # @return [String, nil]
        attr_accessor :location_name

        # Gets metadata for the given `key`.
        def [](key)
          if @metadata.key?(key)
            @metadata[key]
          else
            @shape[key]
          end
        end

        # Sets metadata for the given `key`.
        def []=(key, value)
          @metadata[key] = value
        end

      end

      class Shape

        def initialize
          @metadata = {}
        end

        # @return [String]
        attr_accessor :name

        # @return [String, nil]
        attr_accessor :documentation

        # Gets metadata for the given `key`.
        def [](key)
          @metadata[key]
        end

        # Sets metadata for the given `key`.
        def []=(key, value)
          @metadata[key] = value
        end

      end

      class BlobShape < Shape; end

      class BooleanShape < Shape; end

      class FloatShape < Shape; end

      class IntegerShape < Shape

        # @return [Integer, nil]
        attr_accessor :min

        # @return [Integer, nil]
        attr_accessor :max

      end

      class ListShape < Shape

        def initialize
          @flattened = false
          super
        end

        # @return [ShapeRef]
        attr_accessor :member

        # @return [Integer, nil]
        attr_accessor :min

        # @return [Integer, nil]
        attr_accessor :max

        # @return [Boolean]
        attr_accessor :flattened

      end

      class MapShape < Shape

        def initialize
          @flattened = false
          super
        end

        # @return [ShapeRef]
        attr_accessor :key

        # @return [ShapeRef]
        attr_accessor :value

        # @return [Integer, nil]
        attr_accessor :min

        # @return [Integer, nil]
        attr_accessor :max

        # @return [Boolean]
        attr_accessor :flattened

      end

      class StringShape < Shape

        # @return [Set<String>, nil]
        attr_accessor :enum

        # @return [Integer, nil]
        attr_accessor :min

        # @return [Integer, nil]
        attr_accessor :max

      end

      class StructureShape < Shape

        def initialize(options = {})
          @members = {}
          @members_by_location_name = {}
          @required = Set.new
          super()
        end

        # @return [Set<Symbol>]
        attr_accessor :required

        # @param [Symbol] name
        # @param [ShapeRef] shape_ref
        # @option options [Boolean] :required (false)
        def add_member(name, shape_ref, options = {})
          @required << name if options[:required]
          @members_by_location_name[shape_ref.location_name] = [name, shape_ref]
          @members[name] = shape_ref
        end

        # @return [Array<Symbol>]
        def member_names
          @members.keys
        end

        # @param [Symbol] member_name
        # @return [Boolean] Returns `true` if there exists a member with
        #   the given name.
        def member?(member_name)
          @members.key?(member_name)
        end

        # @return [Enumerator<[Symbol,ShapeRef]>]
        def members
          @members.to_enum
        end

        # @param [Symbol] name
        # @return [ShapeRef]
        def member(name)
          if @members.key?(name)
            @members[name]
          else
            raise ArgumentError, "no such member #{name.inspect}"
          end
        end

        # @api private
        def member_by_location_name(location_name)
          @members_by_location_name[location_name]
        end

      end

      class TimestampShape < Shape; end

    end
  end
end
