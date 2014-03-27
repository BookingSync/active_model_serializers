module ActiveModel
  module Serializable
    def as_json(options={})
      object = serializable_object
      links = extract_links_templates(object)
      if root = options.fetch(:root, json_key)
        hash = {}
        if links.present?
          hash["links"] ||= {}
          hash["links"].merge!(links)
        end
        hash[root] = object
        hash.merge!(serializable_data)
        hash
      else
        object
      end

    end

    def serializable_data
      embedded_in_root_associations.tap do |hash|
        if respond_to?(:meta) && meta
          hash[meta_key] = meta
        end
        if respond_to?(:_links_templates) && _links_templates.present?
          hash["links"] ||= {}
          hash["links"].merge!(_links_templates)
        end
      end
    end

    def embedded_in_root_associations
      {}
    end

    def extract_links_templates(object)
      {}.tap do |links|
        Array([object]).flatten.each do |object|
          if object.is_a?(Hash) && object.has_key?("_links_templates")
            links.merge!(object.delete("_links_templates"))
          end
        end
      end
    end
  end
end
