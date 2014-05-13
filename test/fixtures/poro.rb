class Model
  def initialize(hash={})
    @attributes = hash
  end

  def read_attribute_for_serialization(name)
    if name == :id || name == 'id'
      object_id
    else
      @attributes[name]
    end
  end
end


###
## Models
###
class User < Model
  def profile
    @profile ||= Profile.new(name: 'N1', description: 'D1')
  end
end

class Profile < Model
end

class Post < Model
  def comments
    @comments ||= [Comment.new(content: 'C1'),
                   Comment.new(content: 'C2')]
  end
end

class Comment < Model
end

class Category < Model
  def posts
    @posts ||= [Post.new(title: 'First', body: 'Post 1'),
                Post.new(title: 'Second', body: 'Post 2')]
  end
end

###
## Serializers
###
class UserSerializer < ActiveModel::Serializer
  attributes :name, :email

  has_one :profile
end

class ProfileSerializer < ActiveModel::Serializer
  def description
    description = object.read_attribute_for_serialization(:description)
    scope ? "#{description} - #{scope}" : description
  end

  attributes :name, :description
end

class PostSerializer < ActiveModel::Serializer
  attributes :title, :body

  has_many :comments
end

class CommentWithAuthorSerializer < ActiveModel::Serializer
  attributes :content

  has_one :user, embed: :object, visible: false, serializer: UserSerializer

  def _links_templates
    {"comments.user" => "http://example.com/users/{comments.user}"}
  end
end

class LightPostSerializer < ActiveModel::Serializer
  attributes :title

  has_many :comments, visible: false, serializer: CommentWithAuthorSerializer

  def _links_templates
    {"light_posts.comments" => "http://example.com/comments/{posts.comments}"}
  end
end

class HypermediaPostSerializer < PostSerializer
  attributes :title, :body, :link

  def link
    post_url
  end
end

class CommentSerializer < ActiveModel::Serializer
  attributes :content
end

class CategorySerializer < ActiveModel::Serializer
  attributes :name

  has_many :posts, serializer: HypermediaPostSerializer
end
