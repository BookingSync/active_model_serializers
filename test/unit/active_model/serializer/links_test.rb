require 'test_helper'

module ActiveModel
  class Serializer
    class LinksTest < Minitest::Test
      def setup
        @post = Post.new({ title: 'Title 1', body: 'Body 1', date: '1/1/2000' })
      end

      def test_add_links_when_present
        serializer = LightPostSerializer.new(@post)
        serializer.instance_eval do
          def _links
            {"comments" => [1, 2]}
          end
        end

        assert_equal({
          "links" => {"light_posts.comments"=>"http://example.com/comments/{posts.comments}"},
          "light_post" => {"links" => {"comments" => [1, 2]}, :title => "Title 1"}},
          serializer.as_json)
      end

      def test_dont_add_links_when_empty
        serializer = LightPostSerializer.new(@post)
        assert_equal({
          "links" => {"light_posts.comments"=>"http://example.com/comments/{posts.comments}"},
          "light_post" => {:title => "Title 1"}},
          serializer.as_json)

        serializer.instance_eval do
          def _links
            {}
          end
        end

        assert_equal({
          "links" => {"light_posts.comments"=>"http://example.com/comments/{posts.comments}"},
          "light_post" => {:title => "Title 1"}},
          serializer.as_json)
      end
    end
  end
end
