require 'test_helper'

module ActiveModel
  class Serializer
    class ShowHiddenAssociationsWithIncludeTest < Minitest::Test
      def setup
        @association = LightPostSerializer._associations[:comments]
        @old_association = @association.dup
        @post = Post.new({ title: 'Title 1', body: 'Body 1', date: '1/1/2000' })
        @post_serializer = LightPostSerializer.new(@post, include: :comments)
        @post_serializer.instance_eval do
          def linked_section; true; end
        end
      end

      def teardown
        LightPostSerializer._associations[:comments] = @old_association
      end

      def test_show_hidden_association_with_include
        puts "po: #{@post_serializer.linked_section}"
        assert_equal({
          'light_post' => { title: 'Title 1' },
          'linked' => { :comments => [{:content=>"C1"}, {:content=>"C2"}] }
        }, @post_serializer.as_json)
      end
    end
  end
end
