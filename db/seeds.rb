admin_role = Role.find_or_create_by!(name: 'admin')
user_role = Role.find_or_create_by!(name: 'customer')


User.create!(email: 'admin@gmail.com', username: 'adminscs123', password: 'password', role: admin_role, student_name: 'admin123', mobile_number: 1234567890, college_name: 'scs', enrollment_number: 123456789, branch: 'CSE', semester: 1, course: 'CSE', status: 'Approved', reference_number: 123456789, issue_date_of_letter: Date.today, internship_start_date: Date.today, internship_end_date: Date.today, internship_type: 'Internship', internship_area: 'internship_area')
