require 'test_helper'

module ActiveModel
  class Serializer
    class AssociationsTest < Minitest::Test
      def test_associations_inheritance
        inherited_serializer_klass = Class.new(PostSerializer) do
          has_many :users
        end
        another_inherited_serializer_klass = Class.new(PostSerializer)

        assert_equal([:comments, :users],
                     inherited_serializer_klass._associations.keys)
        assert_equal([:comments],
                     another_inherited_serializer_klass._associations.keys)
      end
    end

    class HiddenAssociationsTest < Minitest::Test
      def setup
        @association = LightPostSerializer._associations[:comments]
        @old_association = @association.dup
        @post = Post.new({ title: 'Title 1', body: 'Body 1', date: '1/1/2000' })
        @post_serializer = LightPostSerializer.new(@post)
        @post_serializer.class_eval do
          def _links_templates; {}; end
        end
      end

      def teardown
        LightPostSerializer._associations[:comments] = @old_association
      end

      def test_hidden_association
        assert_equal({
          'light_post' => { title: 'Title 1' }
        }, @post_serializer.as_json)
      end
    end

    class ShowHiddenAssociationsWithIncludeTest < Minitest::Test
      def setup
        @association = LightPostSerializer._associations[:comments]
        @old_association = @association.dup
        @post = Post.new({ title: 'Title 1', body: 'Body 1', date: '1/1/2000' })
        @post_serializer = LightPostSerializer.new(@post, include: :comments)
        @post_serializer.class_eval do
          def _links_templates; {}; end
        end
      end

      def teardown
        LightPostSerializer._associations[:comments] = @old_association
      end

      def test_show_hidden_association_with_include
        assert_equal({
          'light_post' => { title: 'Title 1', :comments => [{:content=>"C1"}, {:content=>"C2"}] }
        }, @post_serializer.as_json)
      end
    end
  end
end
