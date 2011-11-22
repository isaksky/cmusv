class StudentsInfoFile < ActiveRecord::Base
  belongs_to :course

  has_attached_file :attachment,
                    :storage => :s3,
                    :s3_credentials => "#{Rails.root}/config/amazon_s3.yml",
                    :path => "students_info_file/:id/:filename"
end
