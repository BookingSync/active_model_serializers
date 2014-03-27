require 'test_helper'

module ActiveModel
  class Serializer
    class LinksTemplatesTest < Minitest::Test
      def setup
        @post = Post.new({ title: 'Title 1', body: 'Body 1', date: '1/1/2000' })
      end

      def test_links_templates_for_array
        serializer = ArraySerializer.new([@post, @post],
          each_serializer: LightPostSerializer, root: "light_posts")
        assert_equal({
          "light_posts" => [{:title => "Title 1"}, {:title => "Title 1"}],
            "links" => {
              "light_posts.comments" => "http://example.com/comments/{posts.comments}"
            }
        }, serializer.as_json)
      end

      def test_links_templates_for_a_signle_object
        serializer = LightPostSerializer.new(@post)
        assert_equal({
          "links" => {"light_posts.comments"=>"http://example.com/comments/{posts.comments}"},
          "light_post" => {:title=>"Title 1"}},
          serializer.as_json)
      end
    end
  end
end
