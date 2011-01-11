Factory.define :course, :class => Course do |c|
  c.name 'Course'
  c.semester ApplicationController.current_semester
  c.year Date.today.year
  c.mini 'Both'
end

Factory.define :fse, :parent => :course do |c|
  c.name 'Foundations of Software Engineering'
  c.short_name 'FSE'
end

Factory.define :mfse, :parent => :course do |c|
  c.name 'Foundations of Software Engineering'
  c.short_name 'MfSE'
  c.semester ApplicationController.next_semester
  c.year ApplicationController.next_semester_year
end