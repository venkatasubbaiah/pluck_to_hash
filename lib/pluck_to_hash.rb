require_relative "./pluck_to_hash/version"

module PluckToHash
  extend ActiveSupport::Concern

  module ClassMethods
    def pluck_to_hash(*keys)
      hash_type = keys[-1].is_a?(Hash) ? keys.pop.fetch(:hash_type,HashWithIndifferentAccess) : HashWithIndifferentAccess
      block_given = block_given?
      keys, formatted_keys = format_keys(keys)
      keys_one = keys.size == 1

      pluck(*keys).map do |row|
        value = hash_type[formatted_keys.zip(keys_one ? [row] : row)]
        block_given ? yield(value) : value
      end
    end

    def pluck(*args)
      args_count = args.count
      raise ArgumentError, 'wrong number of arguments (given 0, expected at least 1)' if args_count.zero?
      args_count == 1 ? map(&args.first) : map { |element| args.map { |arg| element.send(arg) } }
    end


    def pluck_to_struct(*keys)
      struct_type = keys[-1].is_a?(Hash) ? keys.pop.fetch(:struct_type,Struct) : Struct
      block_given = block_given?
      keys, formatted_keys = format_keys(keys)
      keys_one = keys.size == 1

      struct = struct_type.new(*formatted_keys)
      pluck(*keys).map do |row|
        value = keys_one ? struct.new(*[row]) : struct.new(*row)
        block_given ? yield(value) : value
      end
    end

    def format_keys(keys)
      if keys.blank?
        [column_names, column_names]
      else
        [
          keys,
          keys.map do |k|
            case k
            when String
              k.split(/\bas\b/i)[-1].strip.to_sym
            when Symbol
              k
            end
          end
        ]
      end
    end

    alias_method :pluck_h, :pluck_to_hash
    alias_method :pluck_s, :pluck_to_struct
  end
end

ActiveRecord::Base.send(:include, PluckToHash)
