require 'calendar_date_select'

class EffortReportsController < ApplicationController

  layout 'cmu_sv', :only => [:index, :show, :semester_view, :campus_view, :course_view]

  before_filter :require_user
#  before_filter :login_required

#    helper Ziya::Helper

      class PanelState 
        attr_accessor :year, :week_number, :course_id, :date
      end
      class SemesterPanel
        attr_accessor :program, :graduation_year, :is_part_time, :person_id, :course_id, :semester, :year

        def generate_sql
         sql_statement = "select el.week_number, e.sum student_effort, course_id,el.person_id
      from effort_log_line_items e,effort_logs el,
      courses c, users u
      where e.sum>0 and e.course_id=c.id and e.effort_log_id=el.id and el.person_id= u.id"
         sql_statement = sql_statement + " AND el.year=#{self.year}"
         sql_statement = sql_statement + " and e.course_id=#{self.course_id}" if !self.course_id.eql?("All") && !self.course_id.blank?
         sql_statement = sql_statement + " and c.semester='#{self.semester}'"
         sql_statement = sql_statement + " and el.person_id=#{self.person_id}" if !self.person_id.eql?("All") && !self.person_id.blank?
         sql_statement = sql_statement + " order by el.week_number;"
        end
      end

       def get_semester_data(panel)
        
         boxreports = EffortLog.find_by_sql(panel.generate_sql())
         task_sums=[]
      #   last_course_name = ""
          if boxreports.size != 0 then
            first_week_number = boxreports.first.week_number
            last_week_number = boxreports.last.week_number

            weeks_in_semester = 15
            weeks_in_report = [weeks_in_semester, (last_week_number - first_week_number + 1)].max

            weeks_in_report.times do |i|
              task_sums[i] = []
            end

            boxreports.each do |report|
              task_sums[report.week_number - first_week_number] << report.student_effort.to_f
            end


           puts "first_week_number is #{first_week_number}"

#       puts "float!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
#       puts task_sums
            minimums = {}
            maximums = {}
            lower25 = {}
            upper25 = {}
            medians = {}

            max_value = -1
            labels = []


            task_sums.each_index do |key|  #here key is week_number
            labels << key + 1

              values = task_sums[key].sort()

              minimums[key] = values.min()
              maximums[key] = values.max()
              medians[key] = values[values.length/2]
              lower25[key] = values[values.length/4]
              upper25[key] = values[3 * values.length/4]
    
              if !values.empty? 
              tmp_max_value = [0.0, minimums[key], maximums[key], medians[key], lower25[key], upper25[key]].max()
              if tmp_max_value>max_value
                max_value = tmp_max_value # maximum among all
              end
              end
            end
            return [minimums, lower25, medians, upper25, maximums, labels, max_value]
          end
          return nil
       end

       def get_campus_data(year, week_number)

         boxreports = EffortLog.find_by_sql("select course_id, c.name, e.sum student_effort from effort_log_line_items e, effort_logs el, courses c
   where e.sum>0 and e.course_id=c.id and e.effort_log_id=el.id AND el.year=#{year} and el.week_number=#{week_number} order by course_id;")

         task_sums={}
      #   last_course_name = ""
          if boxreports.size != 0 then

            boxreports.each do |report|
              if !task_sums.has_key?(report.course_id)
                task_sums[report.course_id] = []
              end
              task_sums[report.course_id] << report.student_effort.to_f
            end
#       puts "float!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
#       puts task_sums
            minimums = {}
            maximums = {}
            lower25 = {}
            upper25 = {}
            medians = {}

            max_value = -1
            labels = []
            task_sums.keys.each do |key|
              course = Course.find(key)
              if(!course.short_name.blank?)
                 labels << course.short_name
              else
                labels << course.name
              end

              values = task_sums[key].sort()

              minimums[key] = values.min()
              maximums[key] = values.max()
              medians[key] = values[values.length/2]
              lower25[key] = values[values.length/4]
              upper25[key] = values[3 * values.length/4]
              tmp_max_value = [minimums[key], maximums[key], medians[key], lower25[key], upper25[key]].max()
              if tmp_max_value>max_value
                max_value = tmp_max_value # maximum among all
              end
            end
            return [minimums, lower25, medians, upper25, maximums, labels, max_value]
          end
          return nil
    end


       def get_course_data(year, week_number, course_id)
         boxreports = EffortLog.find_by_sql("select task_type_id, t.name, e.sum student_effort from effort_log_line_items e,effort_logs el,task_types t
where e.sum>0 and e.task_type_id=t.id and e.effort_log_id=el.id AND el.year=#{year} and el.week_number=#{week_number} AND e.course_id=#{course_id} order by task_type_id;")

      task_sums={}
      if boxreports.size != 0 then

        boxreports.each do |report|
          if !task_sums.has_key?(report.task_type_id)
            task_sums[report.task_type_id] = []
          end
          task_sums[report.task_type_id] << report.student_effort.to_f
        end

        minimums = {}
        maximums = {}
        lower25 = {}
        upper25 = {}
        medians = {}

        max_value = -1
        labels = []
     #  puts "testing!!!!!!!!!!!!!!!!!!!!"
        task_sums.keys.each do |key|
          values = task_sums[key].sort()

          minimums[key] = values.min()
          maximums[key] = values.max()
          medians[key] = values[values.length/2]
          lower25[key] = values[values.length/4]
          upper25[key] = values[3 * values.length/4]

#          labels << Course.find(key).short_name
          labels << TaskType.find(key).name

#          puts "Array " + key + ": " + values.join(",")
#          puts "min    " + key + ":" + minimums[key].to_s
#          puts "lower  " + key + ":" + lower25[key].to_s
#          puts "median " + key + ":" + medians[key].to_s
#          puts "upper25" + key + ":" + upper25[key].to_s
#          puts "max    " + key + ":" + maximums[key].to_s

          tmp_max_value = [minimums[key], maximums[key], medians[key], lower25[key], upper25[key]].max()
          if tmp_max_value>max_value
            max_value = tmp_max_value # maximum among all
          end
        end
        return [minimums, lower25, medians, upper25, maximums, labels, max_value]
      end
      return nil
    end


       def box_chart_helper(values, multiplier)
        return "-1,"+ values.map{|v| (v ? "%.2f" % (v*multiplier):0)}.join(",") + ",-1"
#        return "-1,"+ values.map{|v| (v ?  (v*multiplier):0)}.join(",") + ",-1"
       end

   def generate_google_box_chart(title, reports)     
      title_str = title.gsub(' ', '+')
      
      if reports
        max_value = reports[6]
     puts "max_value is !!!!!!!!!!!!!!!!!!!!!!!!"
     puts max_value
        if max_value!=0
          multiplier = 100.0/(max_value)
        else
          multiplier = 1
        end
      puts "multiplier !!!!!!!!!!!!!"
      puts reports[0].values
      if !reports[0].values.empty?
        minimums_str = box_chart_helper(reports[0].values, multiplier)
      else
        minimums_str = 0
      end

             puts "multiplier1 !!!!!!!!!!!!!"
             puts reports[1].values
      if !reports[1].values.empty?
        lower25_str = box_chart_helper(reports[1].values, multiplier)
     #   "-1,"+ reports[1].values.map{|v| (v ?  (v*multiplier):0)}.join(",") + ",-1"
      end

      if !reports[2].values.empty?
        medians_str = box_chart_helper(reports[2].values, multiplier)
     #   "-1,"+ reports[2].values.map{|v| (v ? (v*multiplier):0)}.join(",") + ",-1"
      end

      if !reports[3].values.empty?
        upper25_str = box_chart_helper(reports[3].values, multiplier)
     #   "-1,"+ reports[3].values.map{|v| (v ? (v*multiplier):0)}.join(",") + ",-1"
      end

      if !reports[4].values.empty?
        maximums_str = box_chart_helper(reports[4].values, multiplier)
      #  "-1,"+ reports[4].values.map{|v| (v ? (v*multiplier):0)}.join(",") + ",-1"
      end

       
#        minimums_str = "-1,"+ reports[0].values.join(",") + ",-1"
#        lower25_str = "-1,"+ reports[1].values.join(",") + ",-1"
#        medians_str = "-1,"+ reports[2].values.join(",") + ",-1"
#        upper25_str = "-1,"+ reports[3].values.join(",") + ",-1"
#        maximums_str = "-1,"+ reports[4].values.join(",") + ",-1"

        puts "data!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        puts  multiplier
        puts  max_value
        puts  minimums_str
        puts  lower25_str
        puts  medians_str
        puts  upper25_str
        puts  maximums_str

       labels_str ="|"+ reports[5].join("|")+"|"

        url = "http://chart.apis.google.com/chart?chtt="+title_str+"&chxt=x,y&chs=700x400&cht=lc&chd=t0:"
        url = url + minimums_str + "|" + lower25_str + "|" + upper25_str + "|" + maximums_str + "|" + medians_str
#        url = url +"&chl=labels|3|7|"  get course_id and course_name from DB
        url = url +"&chl=" + labels_str  #get course_id and course_name from DB
        url = url + "&chm=F,FF9900,0,-1,25|H,0CBF0B,0,-1,1:10|H,000000,4,-1,1:25|H,0000FF,3,-1,1:10"
        url = url + "&chxr=1,0," + (max_value).to_s
        return url
      end
        return "http://chart.apis.google.com/chart?chtt="+ title_str+ "&chxt=x,y&chs=700x400&cht=lc&chd=t0:-1,0,0,0,-1|-1,0,0,0,-1|-1,0,0,0,-1|-1,0,0,0,-1|-1,0,0,0,-1&chm=F,FF9900,0,-1,25|H,0CBF0B,0,-1,1:10|H,000000,4,-1,1:25|H,0000FF,3,-1,1:10&chxr=1,0,15"
       
   end

   def determine_panel_state
    if params[:panel_state]
        @panel_state = PanelState.new
        @panel_state.year = params[:panel_state][:year]
        @panel_state.week_number = params[:panel_state][:week_number]
        @panel_state.date = params[:panel_state][:date]
        logger.debug(params[:panel_state][:date])
        if !@panel_state.date.blank?
          panel_date = Date.parse(@panel_state.date)
          @panel_state.year = panel_date.cwyear
          @panel_state.week_number = panel_date.cweek
        end
      else
        @panel_state = PanelState.new
        @panel_state.year = Date.today.cwyear
        @panel_state.week_number = Date.today.cweek - 1
      end
   end

   def semester_view
    if params[:semester_panel]
        @semester_panel = SemesterPanel.new
        @semester_panel.program = params[:semester_panel][:program]
        @semester_panel.graduation_year = params[:semester_panel][:graduation_year]
        @semester_panel.is_part_time = params[:semester_panel][:is_part_time]
        @semester_panel.person_id = params[:semester_panel][:person_id]
        @semester_panel.course_id = params[:semester_panel][:course_id]
        @semester_panel.semester = params[:semester_panel][:semester]
        @semester_panel.year = params[:semester_panel][:year]
      else
        @semester_panel = SemesterPanel.new
        @semester_panel.program = "All"
        @semester_panel.graduation_year = ""
        @semester_panel.is_part_time = "Both"
        @semester_panel.person_id = "All"
        @semester_panel.course_id = "All"
        @semester_panel.semester = ApplicationController.current_semester
        @semester_panel.year = Date.today.cwyear
      end

      @students = Person.find(:all, :conditions => ['is_student IS TRUE'], :order => "first_name ASC, last_name ASC")
      @courses = Course.find(:all, :conditions => ["semester = ? and year = ?", @semester_panel.semester, @semester_panel.year], :order =>"name ASC")
      @programs = []
      ActiveRecord::Base.connection.execute("SELECT distinct masters_program FROM cmu_education_development.people p;").each do |result| @programs << result end
      @tracks = []
      ActiveRecord::Base.connection.execute("SELECT distinct masters_track FROM cmu_education_development.people p;").each do |result| @programs << result end

     title = "Semester View - " + @semester_panel.semester + " " + @semester_panel.year.to_s
     reports=get_semester_data(@semester_panel)
    # @chart_url = generate_semester_chart(@panel_state.year, @panel_state.week_number, @panel_state.course_id)
     @chart_url=generate_google_box_chart(title, reports)
   end





  def campus_view
      determine_panel_state()
      puts "PAREMETERS: #{@panel_state.year}, #{@panel_state.week_number}, #{params[:id]}"
      title = "Campus View"
      reports = get_campus_data(@panel_state.year, @panel_state.week_number)
      @chart_url = generate_google_box_chart(title, reports)
    end



    def course_view
      determine_panel_state()
      if params[:panel_state]
        @panel_state.course_id = params[:panel_state][:course_id]
      else
       # @panel_state.course_id = params[:course_id]
       @panel_state.course_id = 7
      end

      puts "PAREMETERS: #{@panel_state.year}, #{@panel_state.week_number}, #{params[:course_id]}"
      #@chart_url = generate_chart_url(2008, 35, 7)
      @chart_url = generate_course_chart(@panel_state.year, @panel_state.week_number, @panel_state.course_id)

    end


   def generate_course_chart(year, week_number, course_id)
      title = "Course View"
      reports = get_course_data(year, week_number, course_id)
      return generate_google_box_chart(title, reports)
   end
    




#      if params[:date]
#        @e_date_str = params[:date]
#        e_date = Date.parse(@e_date_str)
#        @week_number = e_date.cweek-0
#        @year = e_date.year
#      else
#        if params[:year] and params[:week]
#          @week_number = params[:week].to_i
#          @year = params[:year].to_i
#        else
#          @week_number = Date.today.cweek
#          @year = Date.today.cwyear
#        end
#      end
#
#      if @week_number <= 0 then @week_number = 1 end
#      if @week_number >52 then @week_number = @week_number - 52 end
#
#      @week_number = params[:week].to_i
#      @next_week_number = @week_number + 1
#      @prev_week_number = @week_number - 1



    def index
    end
    
    def show_week

      if params[:date]
        @e_date_str = params[:date]
        e_date = Date.parse(@e_date_str)
        @week_number = e_date.cweek-0
        @year_number = e_date.year
      else
        if params[:year] and params[:week]
          @week_number = params[:week].to_i
          @year_number = params[:year].to_i
        else
          @week_number = 1
          @year_number = 2010
        end
      end

      if @week_number <= 0 then @week_number = 1 end
      if @week_number >52 then @week_number = @week_number - 52 end
      
      #@week_number = params[:week].to_i
      @next_week_number = @week_number + 1
      @prev_week_number = @week_number - 1
    end

    def show
      if params[:week] then 
        @week_number = params[:week].to_i
      else
        @week_number = (Date.today.cweek - 0) 
      end
      @next_week_number = @week_number + 1
      @this_week_number = @week_number
      @prev_week_number = @week_number - 1
    end

  
#    def load_google_chart
#      puts "test google place !!!!!!!!!!!!!!!!!!!!!!!!!!"
#      GoogleChart::BoxChart.new('800x200', "Box Chart") do |bc|
##      GoogleChart::FinancialLineChart.new('800x200', "Box Chart") do |bc|
#        bc.data "course1", [-1,5,10,7,12,-1]
#        bc.data "course2", [-1,25,30,27,24,-1]
#        bc.data "course3", [-1,40,45,47,39,-1]
#        bc.data "course4", [-1,55,63,59,80,-1]
#        bc.data "course5", [-1,30,40,35,30,-1]
#        bc.data "course6", [-1,-1,5,70,90,-1]
#        @chart = bc.to_url
#     end
#    end



    ########## To be removed ############
    def load_ziya_chart
      puts "test ziya place !!!!!!!!!!!!!!!!!!!!!!!!"
          # Create a bar chart with 2 series composed of 3 data points each.
          # Chart will be rendered using the default look and feel
         #chart = Ziya::Charts::CandleStick.new
         chart = Ziya::Charts::CandleStick.new
          #chart.add( :axis_category_text, %w[2006 2007 2008 2009] )
          chart.add( :series, "student1", [10,20,30,50,60] )
          chart.add( :series, "student2", [5,15,25,40,50] )
          respond_to do |fmt|
            fmt.xml { render :xml => chart.to_xml }
          end
    end

    #####################################
    def load_google_chart
      puts "test google place !!!!!!!!!!!!!!!!!!!!!!!!!!"

#      GoogleChart::BarChart.new('800x200', "Box Chart", :vertical, false) do |bc|
      GoogleChart::BoxChart.new('800x200', "Box Chart") do |bc|
        bc.data "s1",[-1,5,10,7,12,-1]
        bc.data "s2",[-1,25,30,27,24,-1]
        bc.data "s3",[-1,40,45,47,39,-1]
        bc.data "s4",[-1,55,63,59,80,-1]
        bc.data "s5",[-1,30,40,35,30,-1]
        bc.data "s6",[-1,-1,5,70,90,-1]
        bc.data "s7",[-1,-1,-1,80,5,-1]
        bc.data_encoding = :text
        @chart = bc.to_url(:chm => "F,FF9900,0,1:4,40|H,0CBF0B,0,1:4,1:20|H,000000,4,1:4,1:40|H,0000FF,3,1:4,1:20|o,FF0000,5,-1,7|o,FF0000,6,-1,7")
         end

 
 end
  


    def load_weekly_chart
      puts "Another places!!!!!!!!!!"

      if params[:date]
        @e_date_str = params[:date]
        e_date = Date.parse(@e_date_str)
        @week_number = e_date.cweek-0
      else
        @week_number = params[:week].to_i
#      if params[:week] then
#        @week_number = params[:week].to_i
#      else
#        @week_number = (Date.today.cweek - 0)
#      end
      end

      if @week_number <= 0 then @week_number = 1 end
      if @week_number >52 then @week_number = @week_number - 52 end
      
      logger.debug "load weekly chart called"
      @date_range_start = Date.commercial(Date.today.cwyear, @week_number, 1).strftime "%m/%d/%y"  # 1/19/09 (Monday)
      @date_range_end = Date.commercial(Date.today.cwyear, @week_number, 7).strftime "%m/%d/%y" # 1/25/09 (Sunday)
    
      reports = EffortLog.find_by_sql(["SELECT task_types.name, users.human_name, effort_log_line_items.sum FROM effort_log_line_items inner join effort_logs on effort_log_line_items.effort_log_id = effort_logs.id inner join users on users.id = person_id inner join task_types on task_type_id = task_types.id where course_id = ? and effort_logs.week_number = ? order by name, human_name", params[:id], @week_number])

      @labels_array = []
      labels_index_hash = {}
      
      reports.each do |line| 
        l_human_name = line.human_name
        if !labels_index_hash.has_key?(l_human_name)
          @labels_array << l_human_name
          labels_index_hash[l_human_name] = @labels_array.size
        end        
      end

      #if the user is a student, move them to be the first column of data
      if current_user && (!current_user.is_staff? && !current_user.is_admin?) then
        @labels_array.each_index do |i|
          if @labels_array[i] == current_user.human_name then
            labels_index_hash[@labels_array[0]] = i+1
            labels_index_hash[current_user.human_name] = 1
            @labels_array[i] = @labels_array[0]
            @labels_array[0] = current_user.human_name
          end
        end
        @labels_array.each_index do |i|
          if @labels_array[i] != current_user.human_name then
            @labels_array[i] = 'anonymous'
          end
        end
      end
 
      if request.env["Anonymous"] then
        @labels_array.each_index do |i|
           @labels_array[i] = 'anonymous'
          end
      end
      
      row_width = @labels_array.size + 1  #Plus one is the for an additional first column, the "type" label.
      current_task = ""
      current_task_chart_data_row = Array.new(row_width) {|i| "0.0" }
      @chart_data = []
      reports.each do |line|
        if line.name == current_task 
          current_task_chart_data_row[labels_index_hash[line.human_name]] = line.sum          
        else
          if current_task != "" then
            @chart_data << current_task_chart_data_row
            current_task_chart_data_row = Array.new(row_width) {|i| "0.0" }
          end
          current_task = line.name
          current_task_chart_data_row[0] = line.name 
          current_task_chart_data_row[labels_index_hash[line.human_name]] = line.sum
        end
      end
      @chart_data << current_task_chart_data_row
      
      
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :layout => false  }
      end
    end

    
    # Callback from the flash movie to get the chart's data
    def load_chart
#    if !(current_user.is_admin? || current_user.is_staff?)
#      flash[:error] = 'You don''t have permissions to view this data.'
#      redirect_to(effort_reports_url)
#      return
#    end
      chart = Ziya::Charts::Line.new
      chart.add( :theme, "simple" )

      weeks_array = [35, 36, 37, 38, 39, 40, 41, 42]

#      reports = EffortLog.find_by_sql("SELECT effort_logs.week_number, users.human_name, sum(effort_log_line_items.sum), effort_log_line_items.course_id FROM effort_log_line_items inner join effort_logs on effort_log_line_items.effort_log_id = effort_logs.id inner join users on users.id = person_id inner join task_types on task_type_id = task_types.id where course_id = '7' group by week_number, human_name, course_id")
      reports = EffortLog.find_by_sql("SELECT effort_logs.week_number, users.human_name, task_types.name, effort_log_line_items.sum, effort_log_line_items.course_id FROM effort_log_line_items inner join effort_logs on effort_log_line_items.effort_log_id = effort_logs.id inner join users on users.id = person_id inner join task_types on task_type_id = task_types.id where course_id = '7'  order by week_number ")

      if reports.size != 0 then

        first_week = reports.first.week_number.to_i
        last_week = reports.last.week_number.to_i
        weeks_array = []
        (first_week..last_week).each do |week| weeks_array.push week end

  #      data is a hash of person -> week -> effort

        data = {}
        anonymous_counter = 1
        reports.each do |report|
          r_human_name = report.human_name
          r_week_number = report.week_number.to_i
          r_sum = report.sum.to_i
          if data.has_key?(r_human_name) then
            time_hash = data[r_human_name]
          else
            time_hash = {}
          end
          if time_hash.has_key?(r_week_number) then
            time_hash[r_week_number] = time_hash[r_week_number] + r_sum
          else
            time_hash[r_week_number] = r_sum
          end
          data[r_human_name] = time_hash
        end
  #    chart.add( :axis_category_text, %w[2006 2007 2009] )


        chart.add( :axis_category_text, weeks_array )
        data.each do |human_name, time_hash|
          effort_array = []
          (first_week..last_week).each do |week| 
            if time_hash.has_key?(week) then
              effort_array.push(time_hash[week])
            else
              effort_array.push(0)
            end
          end
         if current_user && (!current_user.is_staff? && !current_user.is_admin?) then
            if human_name != current_user.human_name then
              human_name = "anonymous " + anonymous_counter.to_s
              anonymous_counter = anonymous_counter + 1
            end
          end         
          chart.add( :series, human_name, effort_array)
        end
      end
        
        #      data.each { |key,value| chart.add( :series, key, value)  }
#      chart.add( :series, "Dogs2", [10,20,30] )
#      chart.add( :series, "Cats", [5,15,25] )
      respond_to do |fmt|
        fmt.xml { render :xml => chart.to_xml }
      end
      
    end

   
  
  # GET /effort_reports
  # GET /effort_reports.xml
#  def index
#    authorize
#    @effort_logs = EffortLog.find(:all, :conditions => "person_id = '#{current_user.id}'", :order => "id DESC")
#
#    if @effort_logs.empty?
#       @show_new_link = true
#    else
#      if @effort_logs[0].year == Date.today.cwyear && @effort_logs[0].week_number == Date.today.cweek
#        @show_new_link = false
#      else
#        @show_new_link = true
#      end
#    end
#
#    
#    
#    respond_to do |format|
#      format.html # index.html.erb
#      format.xml  { render :xml => @effort_logs }
#    end
#  end

  
  # GET /effort_reports/1
  # GET /effort_reports/1.xml
  def raw_data
    if !(current_user.is_admin? || current_user.is_staff?)          
      flash[:error] = 'You don''t have permissions to view this data.'
      redirect_to(effort_reports_url)
      return
    end
    @report_lines = EffortLog.find_by_sql(["SELECT effort_logs.year, effort_logs.week_number, users.human_name, task_types.name, effort_log_line_items.sum, effort_log_line_items.course_id FROM effort_log_line_items inner join effort_logs on effort_log_line_items.effort_log_id = effort_logs.id inner join users on users.id = person_id inner join task_types on task_type_id = task_types.id where course_id = ?  order by week_number ", params[:id]])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @effort_log }
    end
  end

  
  
  def course_table
    if !(current_user.is_admin? || current_user.is_staff?)          
      flash[:error] = 'You don''t have permissions to view this data.'
      redirect_to(effort_reports_url)
      return
    end
    @course = Course.find(params[:id])

    #given the course id, determine the start week and the end week of the semester
 
    @report_header = ["Team", "Person"]
    (1..@course.semester_length).each do |week| @report_header << "Wk #{week} "  end
#    @course.semester_length.times do @report_header << "Wk  "  end
     
    @report_lines = []

    blank_line = Array.new(@course.semester_length, "-")
    min_effort = Array.new(@course.semester_length, 100)
    max_effort = Array.new(@course.semester_length, 0)
    total_effort = Array.new(@course.semester_length, 0)
    count_effort = Array.new(@course.semester_length, 0)
    average_effort = Array.new(@course.semester_length, 0)

    
    @course.teams.each do |team| 
       team.people.each do |person|
          person_result =  report_person_effort_for_course(person, @course)
          @report_lines << { :team_name => team.name, :person_name => person.human_name, :effort => person_result }                 
          min_effort = update_min(min_effort, person_result)
          max_effort = update_max(max_effort, person_result)
          total_effort = update_total(total_effort, person_result)
          count_effort = update_count(count_effort, person_result)
      end
    end
    update_average(average_effort, total_effort, count_effort)
    @report_lines << { :team_name => "", :person_name => "", :effort => blank_line }                 
    @report_lines << { :team_name => "Summary", :person_name => "Min", :effort => min_effort }                 
    @report_lines << { :team_name => "Summary", :person_name => "Avg", :effort => average_effort }                 
    @report_lines << { :team_name => "Summary", :person_name => "Max", :effort => max_effort }                 
    @report_lines << { :team_name => "", :person_name => "", :effort => blank_line }                 
    @report_lines << { :team_name => "Summary", :person_name => "Total", :effort => total_effort }                 
    @report_lines << { :team_name => "Summary", :person_name => "Count", :effort => count_effort }                 
    
  end
  
  # helper method for course_table
  def update_max(max_effort, person_result)
    max_effort.each_index {|i| max_effort[i] = person_result[i] if person_result[i] > max_effort[i]}
  end 
  def update_min(min_effort, person_result)
    min_effort.each_index {|i| min_effort[i] = person_result[i] if person_result[i] < min_effort[i] && person_result[i] > 0}
  end 
  def update_total(total_effort, person_result)
    total_effort.each_index {|i| total_effort[i] += person_result[i] }
  end 
  def update_count(count_effort, person_result)
    count_effort.each_index {|i| count_effort[i] += 1 if person_result[i] != 0 }
  end 
  def update_average(average_effort, total_effort, count_effort)
    average_effort.each_index {|i| average_effort[i] = total_effort[i] / count_effort[i] unless count_effort[i] == 0 }
  end 

  
  # helper method for course_table
  def report_person_effort_for_course(person, course)
    person_effort_log_lines = EffortLog.find_by_sql(["SELECT effort_logs.week_number, effort_log_line_items.sum  FROM effort_log_line_items inner join effort_logs on effort_log_line_items.effort_log_id = effort_logs.id where effort_log_line_items.course_id = ? and effort_logs.person_id = ? order by effort_logs.week_number", course.id, person.id])
    
    person_result = []
    @course.semester_length.times do person_result << 0 end
    if !person_effort_log_lines.nil? && person_effort_log_lines.size != 0 then
      person_effort_log_lines.each do |line|
        week = line.week_number.to_i 
        if week >= @course.semester_start && week <= @course.semester_end then
          person_result[week - @course.semester_start + 0] += line.sum.to_i  #add two to skip the team and person label at the front of the array
        end
        
      end

    end
    return person_result
  end


end
