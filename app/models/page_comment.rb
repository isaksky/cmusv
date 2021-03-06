class PageComment < ActiveRecord::Base
  belongs_to :user
  belongs_to :type, :class_name=>"PageCommentType", :foreign_key=>"curriculum_comment_type_id"
  belongs_to :page

  validates_presence_of :comment

  def editable?(current_user)
    if (current_user && current_user.is_admin?)
      return true
    end
    if (current_user && current_user.id == user_id)
      return true
    end
    return false

  end

  def notify_us()
#todo add current
    curriculum_comments = PageComment.find(:all, :conditions => ["url = ? and notify_me = true and user_id is not null", self.url])
    email_addresses = []
    curriculum_comments.each { |comment| email_addesses << curriculum_commments.user.email_address }
    return email_addresses
  end

end