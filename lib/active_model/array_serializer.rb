require 'active_model/default_serializer'
require 'active_model/serializable'
require 'active_model/serializer'

module ActiveModel
  class ArraySerializer
    include Serializable

    class << self
      attr_accessor :_root
      alias root  _root=
      alias root= _root=
    end

    def initialize(object, options={})
      @object          = object
      @scope           = options[:scope]
      @root            = options.fetch(:root, self.class._root)
      @meta_key        = options[:meta_key] || :meta
      @meta            = options[@meta_key]
      @each_serializer = options[:each_serializer]
      @resource_name   = options[:resource_name]
      @url_options     = options[:url_options]
      @fields          = options[:fields]
      @include         = options[:include]
      @embed_association = options.fetch(:embed_association, false)
    end
    attr_accessor :object, :scope, :root, :meta_key, :meta, :fields,
      :embed_association
    attr_reader :url_options

    def json_key
      if root.nil?
        @resource_name
      else
        root
      end
    end

    def serializer_for(item)
      serializer_class = @each_serializer || Serializer.serializer_for(item) || DefaultSerializer
      serializer_class.new(item, scope: scope, fields: fields,
        include: @include, url_options: url_options,
        embed_association: embed_association)
    end

    def serializable_object
      serializers.map(&:serializable_object)
    end

    def serializers
      @object.map { |item| serializer_for(item) }
    end

    alias_method :serializable_array, :serializable_object

    def embedded_in_root_associations
      @object.each_with_object({}) do |item, hash|
        serializer_for(item).embedded_in_root_associations.each_pair do |type, objects|
          next if !objects || objects.flatten.empty?
          if hash.has_key?(type)
            hash[type].concat(objects).uniq!
          else
            hash[type] = objects
          end
        end
      end
    end

    # In our case all elements of array have the same type
    # so take _links_templates from the first one
    def associations_links_templates
      serializer = serializers.first
      serializer.respond_to?(:_links_templates) ?
        serializer._links_templates : {}
    end
  end
end
