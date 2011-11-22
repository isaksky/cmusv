class StudentsInfoFileController < ApplicationController
  def update
    @sif = StudentsInfoFile.find(params[:id])

    if @sif.course.permission_to_upload_sif?(current_user)
      respond_to do |format|
        if @sif.update_attributes(params[:students_info_file])
          format.html { redirect_to @sif.course }
        else
          flash[:error] = 'Could not upload your file.'
          format.html { redirect_to @sif.course }
        end
      end
    else
      flash[:error] = "You don't have permission to do that."
      redirect_to @sif.course
    end

  end
end

def create
  @sif = StudentsInfoFile.new params[:students_info_file]

  if @sif.course.permission_to_upload_sif?(current_user)
    respond_to do |format|
      if @sif.attachment.present? && @sif.save
        format.html { redirect_to @sif.course }
      else
        flash[:error] = 'Could not upload your file.'
        format.html { redirect_to @sif.course }
      end
    end
  else
    flash[:error] = "You don't have permission to do that."
    redirect_to @sif.course
  end
end

def destroy
  @sif = StudentsInfoFile.find(params[:id])

  if @sif.course.permission_to_upload_sif?(current_user)
    @sif.destroy
    flash[:notice] = "SIF attachment successfully deleted."

    respond_to do |format|
      format.html { redirect_to @sif.course }
    end
  else
    flash[:error] = "You don't have permission to do that."
    redirect_to @sif.course
  end
end

