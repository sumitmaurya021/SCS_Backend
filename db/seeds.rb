require 'faker'
admin_role = Role.find_or_create_by!(name: 'admin')
user_role = Role.find_or_create_by!(name: 'customer')

User.create!(email: 'admin@gmail.com', username: 'adminscs123', password: 'password', role: admin_role, student_name: 'admin123', mobile_number: 1234567890, college_name: 'scs', enrollment_number: 123456789, branch: 'CSE', semester: 1, course: 'CSE', status: 'Approved', reference_number: 123456789, issue_date_of_letter: Date.today, internship_start_date: Date.today, internship_end_date: Date.today, internship_type: 'Internship', internship_area: 'internship_area')

200.times do
  User.create!(
    email: Faker::Internet.unique.email,
    username: Faker::Internet.unique.username(specifier: 8),
    password: 'password',
    role: user_role,
    student_name: Faker::Name.name.truncate(20),
    mobile_number: Faker::Number.number(digits: 10),
    college_name: Faker::Educator.university,
    enrollment_number: Faker::Number.unique.number(digits: 9),
    branch: ['CSE', 'ECE', 'IT', 'ME', 'CE'].sample,
    semester: rand(1..8),
    course: ['Degree', 'Diploma', 'BCA', 'MCA', 'BSC.IT', 'MSC.IT'].sample,
    status: 'Approved',
    reference_number: Faker::Number.unique.number(digits: 9),
    issue_date_of_letter: Date.today,
    internship_start_date: Date.today - rand(1..30).days,
    internship_end_date: Date.today + rand(30..90).days,
    internship_type: ['Summer', 'Winter'].sample,
    internship_area: Faker::Job.field
  )
end