class Api::V1::BatchesController < ApplicationController
  before_action :authenticate_admin!, only: [:create]
  skip_before_action :doorkeeper_authorize!, only: [:export_attendance]

  def create
    available_users = User.where(status: 'Approved', internship_type: batch_params[:internship_type])
                          .where.not(id: BatchUser.select(:user_id))
                          .limit(batch_params[:number_of_students])

    if available_users.count < batch_params[:number_of_students]
      render json: { 
        error: "Not enough available students to create the batch" 
      }, status: :unprocessable_entity
      return
    end
    batch = Batch.new(batch_params)
    if batch.save
      batch.assign_users(available_users.pluck(:id))
      render json: { 
        message: "Batch created and users assigned successfully", 
        batch: batch, 
        users: available_users 
      }, status: :created
    else
      render json: { error: batch.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def export_attendance
    batch = Batch.find(params[:id])
    users = batch.users
    xlsx_package = Axlsx::Package.new
    workbook = xlsx_package.workbook
    header_style = workbook.styles.add_style(
      alignment: { horizontal: :center, vertical: :center },
      bg_color: 'FFDDC1',
      fg_color: '000000',
      b: true, # Bold text
      sz: 12
    )
    content_style = workbook.styles.add_style(
      alignment: { horizontal: :center, vertical: :center },
      fg_color: '000000',
      sz: 10
    )
    batch_detail_style = workbook.styles.add_style(
      alignment: { horizontal: :center, vertical: :center },
      b: true,
      sz: 12,
      fg_color: '000000',
      bg_color: 'FFFF99'
    )
    today = Date.today
    total_days = (batch.end_date - today).to_i + 1
    attendance_dates = (0...total_days).map { |i| today + i }.reject(&:sunday?)
    workbook.add_worksheet(name: "Attendance Sheet") do |sheet|
      sheet.add_row ["Batch Name", "Internship Type", "Start Date", "End Date", "Time"], style: header_style
      sheet.add_row [batch.name, batch.internship_type, batch.start_date.strftime('%B %d, %Y'), batch.end_date.strftime('%B %d, %Y'), ""], style: batch_detail_style
      sheet.add_row []
      headers = ["S.No", "Name", "Contact Number", "Email", "Status"] + attendance_dates.map { |date| date.strftime('%B %d, %Y') }
      sheet.add_row headers, style: header_style
      users.each_with_index do |user, index|
        row_data = [
          index + 1,
          user.student_name,
          user.mobile_number,
          user.email,
          user.status
        ]
        row_data += Array.new(attendance_dates.size, nil)
        sheet.add_row row_data, style: content_style
      end
    end
    filename = "#{batch.name.parameterize}-attendance.xlsx"
    send_data xlsx_package.to_stream.read, filename: filename, type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end
  
  private

  def batch_params
    params.require(:batch).permit(:name, :internship_type, :start_date, :end_date, :number_of_students)
  end

  def authenticate_admin!
    unless current_user.is_admin?
      render json: { error: "Not authorized" }, status: :unauthorized
    end
  end
end