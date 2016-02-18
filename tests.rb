# Basic test requires
require 'minitest/autorun'
require 'minitest/pride'

# Include both the migration and the app itself
require './migration'
require './application'

# Overwrite the development database connection with a test connection.
ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'test.sqlite3'
)

ActiveRecord::Migration.verbose = false

# Gotta run migrations before we can run tests.  Down will fail the first time,
# so we wrap it in a begin/rescue.
begin ApplicationMigration.migrate(:down); rescue; end
ApplicationMigration.migrate(:up)


# Finally!  Let's test the thing.
class ApplicationTest < Minitest::Test

  def test_truth
    assert true
  end

  def test_associate_schools_with_terms
    a = School.create(name: "Appalachian State University")
    s = Term.create(name: "Spring 2016")
    f = Term.create(name: "Fall 2016")
    a.terms = [s, f]
    assert_equal a.terms, [s, f]
  end

  def test_associate_terms_with_courses
    output = ""
    s = Term.create(name: "Spring 2016")
    a = Course.create(name: "Accounting")
    c = Course.create(name: "Communication")
    s.courses = [a, c]
    begin
      s.destroy
    rescue
      output = "Cannot destroy, term contains courses"
    end
    assert_equal "Cannot destroy, term contains courses", output
    f = Term.create(name: "Fall 2016")
    f.destroy
    begin
      f.reload
    rescue
      output = "Cannot find term"
    end
    assert_equal "Cannot find term", output
  end

  def test_associate_courses_with_course_students
    output = ""
    a = Course.create(name: "Accounting")
    g = CourseStudent.create(student_id: 1)
    j = CourseStudent.create(student_id: 2)
    a.course_students = [g, j]
    begin
      a.destroy
    rescue
      output = "Cannot destroy, course contains course students"
    end
    assert_equal "Cannot destroy, course contains course students", output
    c = Course.create(name: "Communication")
    c.destroy
    begin
      c.reload
    rescue
      output = "Cannot find course"
    end
    assert_equal "Cannot find course", output
  end

  def test_associate_assignments_with_courses
    c = Course.create(name: "Computer Programming")
    a = Assignment.create(name: "Test Driven Development")
    c.assignments << a
    c.destroy
    assert c.destroyed?
    assert a.destroyed?
  end



end
